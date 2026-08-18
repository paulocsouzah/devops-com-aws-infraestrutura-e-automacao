import { useEffect, useState } from 'react';

// Caminho relativo, nunca um host fixo — quem resolve "/api" para a API
// certa (container local, ou EC2 em producao) e o nginx que fica na
// frente da aplicacao, nao o React.
const API_URL = '/api/usuarios';
const STATUS_URL = '/api/status';

function App() {
  const [usuarios, setUsuarios] = useState([]);
  const [nome, setNome] = useState('');
  const [email, setEmail] = useState('');
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState(null);
  const [status, setStatus] = useState(null);

  // So pra deixar visivel QUAL instancia (task) respondeu — clique
  // repetido em "Consultar de novo" e observe o valor mudando quando
  // houver mais de uma task atras do Load Balancer (Aula 04, modulo 05).
  async function consultarStatus() {
    try {
      const resposta = await fetch(STATUS_URL);
      const dados = await resposta.json();
      setStatus(dados);
    } catch {
      setStatus(null);
    }
  }

  async function carregarUsuarios() {
    try {
      setCarregando(true);
      const resposta = await fetch(API_URL);
      if (!resposta.ok) throw new Error(`Erro ${resposta.status} ao buscar usuarios`);
      const dados = await resposta.json();
      setUsuarios(dados);
      setErro(null);
    } catch (e) {
      setErro(e.message);
    } finally {
      setCarregando(false);
    }
  }

  useEffect(() => {
    carregarUsuarios();
    consultarStatus();
  }, []);

  async function handleSubmit(event) {
    event.preventDefault();
    if (!nome || !email) return;

    try {
      const resposta = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nome, email }),
      });
      if (!resposta.ok) throw new Error(`Erro ${resposta.status} ao cadastrar usuario`);
      setNome('');
      setEmail('');
      await carregarUsuarios();
    } catch (e) {
      setErro(e.message);
    }
  }

  return (
    <main className="container">
      <h1>Aula 03 — React + Node + RDS</h1>
      <p className="subtitulo">
        Frontend em React, API em Node.js e banco de dados MySQL gerenciado
        pelo Amazon RDS — tudo provisionado automaticamente via Terraform e
        User Data, sem nenhum comando manual no servidor.
      </p>

      <form onSubmit={handleSubmit} className="formulario">
        <input
          type="text"
          placeholder="Nome"
          value={nome}
          onChange={(e) => setNome(e.target.value)}
          required
        />
        <input
          type="email"
          placeholder="E-mail"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <button type="submit">Cadastrar</button>
      </form>

      {erro && <p className="erro">⚠️ {erro}</p>}

      <div className="status-instancia">
        <span>
          Atendido por: <code>{status ? status.instancia : '...'}</code>
        </span>
        <button type="button" onClick={consultarStatus}>
          🔄 Consultar de novo
        </button>
      </div>

      <h2>Usuários cadastrados</h2>
      {carregando ? (
        <p>Carregando...</p>
      ) : usuarios.length === 0 ? (
        <p>Nenhum usuário cadastrado ainda.</p>
      ) : (
        <ul className="lista-usuarios">
          {usuarios.map((usuario) => (
            <li key={usuario.id}>
              <strong>{usuario.nome}</strong> — {usuario.email}
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}

export default App;
