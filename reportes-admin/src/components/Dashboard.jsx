import { useCallback, useEffect, useMemo, useState } from 'react';
import { api } from '../api.js';
import { calcularEstadisticas } from '../utils/estadisticas.js';
import Estadisticas from './Estadisticas.jsx';
import ListaReportes from './ListaReportes.jsx';

/**
 * Vista única del panel: carga los reportes y muestra
 * las estadísticas y la lista.
 */
export default function Dashboard({ onLogout, onSesionExpirada }) {
  const [estado, setEstado] = useState('cargando'); // cargando | ok | error
  const [reportes, setReportes] = useState([]);
  const [mensajeError, setMensajeError] = useState('');

  const cargarReportes = useCallback(async () => {
    setEstado('cargando');

    try {
      setReportes(await api.listarReportes());
      setEstado('ok');
    } catch (e) {
      if (e.status === 401) {
        onSesionExpirada();
        return;
      }
      setMensajeError(e.message);
      setEstado('error');
    }
  }, [onSesionExpirada]);

  useEffect(() => {
    cargarReportes();
  }, [cargarReportes]);

  const estadisticas = useMemo(() => calcularEstadisticas(reportes), [reportes]);

  return (
    <div className="pagina">
      <header className="encabezado">
        <div>
          <h1>Panel de reportes</h1>
          <p className="texto-suave">Reportes enviados desde la app</p>
        </div>
        <div className="acciones">
          <button className="boton boton-secundario" onClick={cargarReportes}>
            Actualizar
          </button>
          <button className="boton boton-secundario" onClick={onLogout}>
            Cerrar sesión
          </button>
        </div>
      </header>

      {estado === 'cargando' && <p className="mensaje-centro">Cargando reportes...</p>}

      {estado === 'error' && (
        <div className="mensaje-centro">
          <p className="error">{mensajeError}</p>
          <button className="boton" onClick={cargarReportes}>
            Reintentar
          </button>
        </div>
      )}

      {estado === 'ok' && (
        <>
          <Estadisticas estadisticas={estadisticas} />
          <ListaReportes reportes={reportes} />
        </>
      )}
    </div>
  );
}
