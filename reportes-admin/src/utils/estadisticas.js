/**
 * Calcula las estadísticas a partir de la lista de reportes.
 * Es una función pura: recibe datos y devuelve datos, sin tocar la pantalla.
 *
 * @param {import('../modelos/reporte.js').Reporte[]} reportes
 */
export function calcularEstadisticas(reportes) {
  const total = reportes.length;
  const reportesPorUsuario = new Map();
  let totalCaracteres = 0;

  for (const reporte of reportes) {
    totalCaracteres += reporte.texto.length;
    const actual = reportesPorUsuario.get(reporte.idUsuario) ?? 0;
    reportesPorUsuario.set(reporte.idUsuario, actual + 1);
  }

  const topUsuarios = [...reportesPorUsuario.entries()]
    .map(([idUsuario, cantidad]) => ({ idUsuario, cantidad }))
    .sort((a, b) => b.cantidad - a.cantidad)
    .slice(0, 5);

  return {
    total,
    usuariosDistintos: reportesPorUsuario.size,
    promedioCaracteres: total === 0 ? 0 : Math.round(totalCaracteres / total),
    topUsuarios,
  };
}
