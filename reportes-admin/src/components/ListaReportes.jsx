import { useMemo, useState } from 'react';

/**
 * Tabla de reportes con un buscador (por texto o por id de usuario).
 */
export default function ListaReportes({ reportes }) {
  const [busqueda, setBusqueda] = useState('');

  const filtrados = useMemo(() => {
    const termino = busqueda.trim().toLowerCase();
    if (termino === '') return reportes;

    return reportes.filter(
      (r) =>
        r.texto.toLowerCase().includes(termino) ||
        String(r.idUsuario).toLowerCase().includes(termino),
    );
  }, [reportes, busqueda]);

  return (
    <section className="tarjeta">
      <div className="lista-cabecera">
        <h2>Reportes</h2>
        <input
          type="search"
          placeholder="Buscar por texto o usuario..."
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
        />
      </div>

      <p className="texto-suave">
        Mostrando {filtrados.length} de {reportes.length}
      </p>

      {filtrados.length === 0 ? (
        <p className="mensaje-centro">No hay reportes para mostrar</p>
      ) : (
        <div className="tabla-contenedor">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Usuario</th>
                <th>Reporte</th>
              </tr>
            </thead>
            <tbody>
              {filtrados.map((r) => (
                <tr key={r.id}>
                  <td>{r.id}</td>
                  <td className="id-usuario">{r.idUsuario}</td>
                  <td className="texto-reporte">{r.texto}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
