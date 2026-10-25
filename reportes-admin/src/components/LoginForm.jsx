import { useState } from 'react';

/**
 * Formulario de acceso del administrador.
 * No sabe cómo se valida: llama a onLogin y muestra el error si falla.
 */
export default function LoginForm({ onLogin }) {
  const [usuario, setUsuario] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [enviando, setEnviando] = useState(false);

  async function manejarEnvio(evento) {
    evento.preventDefault();
    setError('');
    setEnviando(true);

    try {
      await onLogin(usuario.trim(), password);
    } catch (e) {
      setError(e.message);
      setEnviando(false);
    }
  }

  const puedeEnviar = usuario.trim() !== '' && password !== '' && !enviando;

  return (
    <main className="login">
      <form className="tarjeta login-formulario" onSubmit={manejarEnvio}>
        <h1>Panel de reportes</h1>
        <p className="texto-suave">Ingresa con tu cuenta de administrador.</p>

        <label>
          Usuario
          <input
            type="text"
            value={usuario}
            onChange={(e) => setUsuario(e.target.value)}
            autoComplete="username"
            autoFocus
          />
        </label>

        <label>
          Contraseña
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
          />
        </label>

        {error && <p className="error">{error}</p>}

        <button type="submit" className="boton" disabled={!puedeEnviar}>
          {enviando ? 'Entrando...' : 'Entrar'}
        </button>
      </form>
    </main>
  );
}
