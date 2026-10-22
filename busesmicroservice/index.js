import 'dotenv/config';
import { parseArgs } from 'node:util';
import { performance } from 'node:perf_hooks';
import { setTimeout as sleep } from 'node:timers/promises';
import { createClient } from '@supabase/supabase-js';
import { buildBuses, createRandom } from './simulation.js';

const { values: args } = parseArgs({
  options: {
    hz: { type: 'string', default: '1' }, // publicaciones por segundo (broadcast)
    steps: { type: 'string' },
    once: { type: 'boolean', default: false },
    'dry-run': { type: 'boolean', default: false },
    seed: { type: 'string' },
    'bus-id': { type: 'string', multiple: true },
    channel: { type: 'string', default: 'seguimiento-buses' },
    event: { type: 'string', default: 'posicion_bus' },
    'persist-every': { type: 'string', default: '30' }, // segundos entre snapshots a Postgres
    'per-bus': { type: 'boolean', default: false }, // 1 mensaje por bus en vez de 1 por tick
    verbose: { type: 'boolean', default: false },
  },
});

const hz = Number(args.hz) > 0 ? Number(args.hz) : 1;
const intervalMs = Math.max(1000 / hz, 10);
const persistMs = Math.max(Number(args['persist-every']) * 1000, 1000);
const steps = args.once ? 1 : args.steps ? Number(args.steps) : null;
const dryRun = args['dry-run'];

function demoRows() {
  return {
    busRows: [{ id: 1, placa: 'SIM-001', capacidad_maxima: 40, id_ruta: 1 }],
    routeRows: [
      { id: 1, nombre: 'Ruta demo', encoded_polyline: '_p~iF~ps|U_ulLnnqC_mqNvxq@', duracion_segundos: 120 },
    ],
  };
}

// ---------- Supabase ----------
let supabase = null;
let channel = null;

async function connect() {
  const url = process.env.SUPABASE_URL;
  // Para escribir en Postgres desde el servidor usa la service role.
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.servicerole ||
    process.env.SUPABASE_KEY ||
    process.env.SUPABASE_ANON_KEY;
  if (!url || !key) {
    console.error('Faltan SUPABASE_URL y una clave Supabase en el entorno o .env');
    process.exit(1);
  }

  supabase = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
    // Por defecto el cliente limita a 10 eventos/seg: subelo si usas --per-bus.
    realtime: { params: { eventsPerSecond: 100 } },
  });

  channel = supabase.channel(args.channel, {
    config: { broadcast: { ack: false, self: false } },
  });

  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Timeout suscribiendo al canal')), 15000);
    channel.subscribe((status, err) => {
      if (status === 'SUBSCRIBED') {
        clearTimeout(timer);
        resolve();
      } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
        clearTimeout(timer);
        reject(err ?? new Error(`Canal: ${status}`));
      }
    });
  });
  console.log(`Canal Realtime listo: "${args.channel}"`);
}

async function loadRows() {
  const [buses, routes] = await Promise.all([
    supabase.from('buses').select('*'),
    supabase.from('rutas').select('*'),
  ]);
  if (buses.error) throw buses.error;
  if (routes.error) throw routes.error;
  return { busRows: buses.data, routeRows: routes.data };
}

/** Tiempo real, en memoria: no toca Postgres. */
function broadcast(reports, timestamp) {
  const toPayload = (r) => ({
    id_bus: r.bus_id,
    placa: r.placa,
    id_ruta: r.id_ruta,
    latitud: r.latitud,
    longitud: r.longitud,
    ocupantes: r.ocupantes,
    nivel_ocupacion: r.nivel_ocupacion,
    timestamp,
  });

  const send = (payload) =>
    channel
      .send({ type: 'broadcast', event: args.event, payload })
      .then((status) => {
        if (status !== 'ok') console.warn(`Broadcast: ${status}`);
      })
      .catch((e) => console.warn('Broadcast error:', e.message));

  if (args['per-bus']) {
    // payload = { id_bus, latitud, ... }  (igual que tu ejemplo de Flutter)
    reports.forEach((r) => send(toPayload(r)));
  } else {
    // payload = { buses: [ {...}, {...} ] }  (1 mensaje por tick, mucho mas barato)
    send({ buses: reports.map(toPayload) });
  }
}

/** Snapshot a Postgres: ultima posicion + historial (insert en bloque). */
async function persist(reports, timestamp) {
  const CHUNK = 25;
  for (let i = 0; i < reports.length; i += CHUNK) {
    const slice = reports.slice(i, i + CHUNK);
    const results = await Promise.all(
      slice.map((r) =>
        supabase
          .from('buses')
          .update({
            latitud_actual: r.latitud,
            longitud_actual: r.longitud,
            nivel_ocupacion: r.nivel_ocupacion,
            ultima_actualizacion_gps: timestamp,
          })
          .eq('id', r.bus_id),
      ),
    );
    results.forEach((res, idx) => {
      if (res.error) console.warn(`UPDATE bus ${slice[idx].bus_id}:`, res.error.message);
    });
  }

  const { error } = await supabase.from('telemetria_gps_logs').insert(
    reports.map((r) => ({
      id_bus: r.bus_id,
      coordenadas: { latitud: r.latitud, longitud: r.longitud },
      timestamp,
    })),
  );
  if (error) console.warn('INSERT telemetria_gps_logs:', error.message);
}

// ---------- Main ----------
async function main() {
  const random = createRandom(args.seed !== undefined ? Number(args.seed) : undefined);

  let rows;
  if (dryRun) {
    rows = demoRows();
  } else {
    await connect();
    rows = await loadRows();
  }

  let { busRows } = rows;
  if (args['bus-id']?.length) {
    const wanted = new Set(args['bus-id'].map(Number));
    busRows = busRows.filter((r) => wanted.has(Number(r.id)));
  }

  const { buses, warnings } = buildBuses(busRows, rows.routeRows, random);
  warnings.forEach((w) => console.log(`Aviso: ${w}`));
  if (!buses.length) {
    console.error('No hay buses simulables: revisa id_ruta y encoded_polyline');
    process.exit(1);
  }
  console.log(`Simulando ${buses.length} buses a ${hz} Hz, snapshot a BD cada ${persistMs / 1000}s`);

  let running = true;
  let persisting = false;
  let lastPersist = 0; // fuerza snapshot en el primer tick
  const lastPersistedLevel = new Map();

  const shutdown = async (signal) => {
    if (!running) return;
    running = false;
    console.log(`\n${signal}: cerrando...`);
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));

  let completed = 0;
  let last = performance.now();
  let nextTick = last;
  let lastReports = [];

  while (running && (steps === null || completed < steps)) {
    const now = performance.now();
    const realElapsed = (now - last) / 1000;
    last = now;

    const timestamp = new Date().toISOString();
    const reports = buses.map((bus) => bus.advance(realElapsed, random));
    lastReports = reports;

    if (args.verbose) {
      reports.forEach((r) =>
        console.log(
          `[${timestamp}] bus=${r.bus_id} placa=${r.placa} ruta=${r.id_ruta} ` +
            `lat=${r.latitud} lon=${r.longitud} ocupantes=${r.ocupantes} nivel=${r.nivel_ocupacion}`,
        ),
      );
    } else {
      console.log(`[${timestamp}] tick #${completed + 1}: ${reports.length} buses`);
    }

    if (!dryRun) {
      broadcast(reports, timestamp);

      // Persistir cada N segundos o cuando un bus cambia de nivel de ocupacion.
      const levelChanged = reports.some(
        (r) => lastPersistedLevel.has(r.bus_id) && lastPersistedLevel.get(r.bus_id) !== r.nivel_ocupacion,
      );
      const due = now - lastPersist >= persistMs;
      if ((due || levelChanged) && !persisting) {
        persisting = true;
        lastPersist = now;
        reports.forEach((r) => lastPersistedLevel.set(r.bus_id, r.nivel_ocupacion));
        persist(reports, timestamp)
          .catch((e) => console.warn('persist fallo:', e.message))
          .finally(() => {
            persisting = false;
          });
      }
    }

    completed++;
    if (steps !== null && completed >= steps) break;

    // Temporizador sin deriva
    nextTick += intervalMs;
    const wait = nextTick - performance.now();
    if (wait > 0) await sleep(wait);
    else nextTick = performance.now();
  }

  // Snapshot final y cierre limpio
  if (!dryRun) {
    while (persisting) await sleep(50);
    if (lastReports.length && running === false) {
      await persist(lastReports, new Date().toISOString()).catch(() => {});
    }
    await supabase.removeChannel(channel);
  }
  console.log('Listo.');
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
