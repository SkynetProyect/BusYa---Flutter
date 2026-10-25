/**
 * Modelo Reporte (el mismo que usa la app Flutter).
 *
 * @typedef {Object} Reporte
 * @property {number} id
 * @property {string} idUsuario
 * @property {string} texto
 */

/**
 * Convierte la fila que llega de Supabase (id_usuario) en un Reporte (idUsuario).
 * @returns {Reporte}
 */
export function reporteDesdeJson(json) {
  return {
    id: json.id,
    idUsuario: json.id_usuario,
    texto: json.texto ?? '',
  };
}
