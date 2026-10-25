import { reporteDesdeJson } from './modelos/reporte.js';

// Toda la comunicación con el servidor está aquí, en un solo lugar.

async function pedir(url, opciones = {}) {
  const respuesta = await fetch(url, {
    credentials: 'same-origin',
    headers: { 'Content-Type': 'application/json' },
    ...opciones,
  });

  const datos = await respuesta.json().catch(() => ({}));

  if (!respuesta.ok) {
    const error = new Error(datos.error ?? 'Error de petición');
    error.status = respuesta.status;
    throw error;
  }

  return datos;
}

export const api = {
  async sesionActiva() {
    const { autenticado } = await pedir('/api/sesion');
    return autenticado;
  },

  login(usuario, password) {
    return pedir('/api/login', {
      method: 'POST',
      body: JSON.stringify({ usuario, password }),
    });
  },

  logout() {
    return pedir('/api/logout', { method: 'POST' });
  },

  async listarReportes() {
    const filas = await pedir('/api/reportes');
    return filas.map(reporteDesdeJson);
  },
};
