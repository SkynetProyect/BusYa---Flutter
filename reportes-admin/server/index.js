import 'dotenv/config';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';
import session from 'express-session';
import { createClient } from '@supabase/supabase-js';

// ---------- Configuración ----------
const VARIABLES_OBLIGATORIAS = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'ADMIN_USER',
  'ADMIN_PASSWORD',
  'SESSION_SECRET',
];

const faltantes = VARIABLES_OBLIGATORIAS.filter((nombre) => !process.env[nombre]);
if (faltantes.length > 0) {
  console.error(`Faltan variables en el .env: ${faltantes.join(', ')}`);
  process.exit(1);
}

const {
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  ADMIN_USER,
  ADMIN_PASSWORD,
  SESSION_SECRET,
} = process.env;
const PORT = process.env.PORT || 3001;

// La service role key vive SOLO aquí, en el servidor.
// Nunca se envía al navegador.
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

// ---------- Validación del administrador ----------
function hash(texto) {
  return crypto.createHash('sha256').update(String(texto ?? '')).digest();
}

// Comparación en tiempo constante (evita adivinar la clave midiendo tiempos).
function credencialesValidas(usuario, password) {
  const usuarioOk = crypto.timingSafeEqual(hash(usuario), hash(ADMIN_USER));
  const passwordOk = crypto.timingSafeEqual(hash(password), hash(ADMIN_PASSWORD));
  return usuarioOk && passwordOk;
}

// ---------- Límite de intentos fallidos (por IP) ----------
const MAX_INTENTOS = 5;
const BLOQUEO_MS = 15 * 60 * 1000;
const intentosPorIp = new Map(); // ip -> { cantidad, bloqueadoHasta }

function estaBloqueada(ip) {
  const registro = intentosPorIp.get(ip);
  return Boolean(registro && registro.bloqueadoHasta > Date.now());
}

function registrarFallo(ip) {
  const registro = intentosPorIp.get(ip) ?? { cantidad: 0, bloqueadoHasta: 0 };
  registro.cantidad += 1;
  if (registro.cantidad >= MAX_INTENTOS) {
    registro.cantidad = 0;
    registro.bloqueadoHasta = Date.now() + BLOQUEO_MS;
  }
  intentosPorIp.set(ip, registro);
}

// ---------- Datos ----------
// Supabase devuelve máximo 1000 filas por consulta, así que se pide por páginas.
async function obtenerTodosLosReportes() {
  const tamanoPagina = 1000;
  const reportes = [];
  let desde = 0;

  while (true) {
    const { data, error } = await supabase
      .from('reportes')
      .select('id, id_usuario, texto')
      .order('id', { ascending: false })
      .range(desde, desde + tamanoPagina - 1);

    if (error) throw error;

    reportes.push(...data);
    if (data.length < tamanoPagina) break;
    desde += tamanoPagina;
  }

  return reportes;
}

// ---------- Aplicación ----------
const app = express();

if (process.env.TRUST_PROXY === '1') {
  app.set('trust proxy', 1);
}

app.use(express.json({ limit: '10kb' }));
app.use(
  session({
    secret: SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      sameSite: 'lax',
      secure: 'auto', // solo marca la cookie como segura si la conexión es HTTPS
      maxAge: 8 * 60 * 60 * 1000, // 8 horas
    },
  }),
);

function requerirAdmin(req, res, next) {
  if (req.session.esAdmin) return next();
  res.status(401).json({ error: 'Sesión no válida' });
}

app.get('/api/sesion', (req, res) => {
  res.json({ autenticado: Boolean(req.session.esAdmin) });
});

app.post('/api/login', (req, res) => {
  if (estaBloqueada(req.ip)) {
    return res
      .status(429)
      .json({ error: 'Demasiados intentos. Inténtalo en unos minutos.' });
  }

  const { usuario, password } = req.body ?? {};

  if (!credencialesValidas(usuario, password)) {
    registrarFallo(req.ip);
    return res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
  }

  intentosPorIp.delete(req.ip);
  req.session.regenerate((error) => {
    if (error) {
      return res.status(500).json({ error: 'No se pudo iniciar sesión' });
    }
    req.session.esAdmin = true;
    res.json({ ok: true });
  });
});

app.post('/api/logout', (req, res) => {
  req.session.destroy(() => {
    res.clearCookie('connect.sid');
    res.json({ ok: true });
  });
});

app.get('/api/reportes', requerirAdmin, async (req, res) => {
  try {
    res.json(await obtenerTodosLosReportes());
  } catch (error) {
    console.error('Error al leer los reportes:', error);
    res.status(500).json({ error: 'No se pudieron cargar los reportes' });
  }
});

// Si ya existe la carpeta "dist" (después de `npm run build`), se sirve la web.
const carpetaDist = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'dist',
);
if (fs.existsSync(carpetaDist)) {
  app.use(express.static(carpetaDist));
}

app.listen(PORT, () => {
  console.log(`Servidor listo en http://localhost:${PORT}`);
});
