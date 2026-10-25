/**
 * Muestra las tarjetas de números y el top de usuarios.
 * Solo dibuja: los cálculos se hacen en utils/estadisticas.js.
 */
export default function Estadisticas({ estadisticas }) {
  const { total, usuariosDistintos, promedioCaracteres, topUsuarios } = estadisticas;

  const tarjetas = [
    { titulo: 'Reportes totales', valor: total },
    { titulo: 'Usuarios que reportaron', valor: usuariosDistintos },
    { titulo: 'Promedio de caracteres', valor: promedioCaracteres },
  ];

  const maximo = topUsuarios[0]?.cantidad ?? 1;

  return (
    <section>
      <div className="grid-tarjetas">
        {tarjetas.map((t) => (
          <article key={t.titulo} className="tarjeta">
            <p className="texto-suave">{t.titulo}</p>
            <p className="numero">{t.valor}</p>
          </article>
        ))}
      </div>

      {topUsuarios.length > 0 && (
        <article className="tarjeta">
          <h2>Usuarios con más reportes</h2>
          <ul className="top-usuarios">
            {topUsuarios.map((u) => (
              <li key={u.idUsuario}>
                <span className="id-usuario">{u.idUsuario}</span>
                <div className="barra-fondo">
                  <div
                    className="barra"
                    style={{ width: `${(u.cantidad / maximo) * 100}%` }}
                  />
                </div>
                <strong>{u.cantidad}</strong>
              </li>
            ))}
          </ul>
        </article>
      )}
    </section>
  );
}
