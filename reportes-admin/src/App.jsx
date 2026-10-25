import { useCallback, useEffect, useState } from 'react';
import { api } from './api.js';
import LoginForm from './components/LoginForm.jsx';
import Dashboard from './components/Dashboard.jsx';

/**
 * Decide qué pantalla mostrar: verificando sesión, login o panel.
 */
export default function App() {
  const [vista, setVista] = useState('verificando');

  useEffect(() => {
    api
      .sesionActiva()
      .then((activa) => setVista(activa ? 'panel' : 'login'))
      .catch(() => setVista('login'));
  }, []);

  async function iniciarSesion(usuario, password) {
    await api.login(usuario, password);
    setVista('panel');
  }

  async function cerrarSesion() {
    try {
      await api.logout();
    } finally {
      setVista('login');
    }
  }

  const sesionExpirada = useCallback(() => setVista('login'), []);

  if (vista === 'verificando') {
    return <p className="mensaje-centro">Cargando...</p>;
  }

  if (vista === 'login') {
    return <LoginForm onLogin={iniciarSesion} />;
  }

  return <Dashboard onLogout={cerrarSesion} onSesionExpirada={sesionExpirada} />;
}
