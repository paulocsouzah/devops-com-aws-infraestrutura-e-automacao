// =============================================================================
// API Node.js da Aula 03 — conecta num MySQL externo (RDS em producao, um
// container local em desenvolvimento). O host do banco vem sempre de uma
// variavel de ambiente, nunca fixo no codigo (ver README do modulo 03).
// =============================================================================

const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 4000;

const dbConfig = {
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
};

let pool;

// -----------------------------------------------------------------------------
// Conecta com retry: mesmo com a ordem de criacao correta no Terraform
// (a EC2 so sobe depois do RDS ficar "available"), e boa pratica a propria
// aplicacao tolerar uma falha temporaria de conexao, em vez de derrubar o
// processo na primeira tentativa (ver modulo 06 - boas praticas).
// -----------------------------------------------------------------------------
async function conectarComRetry(tentativas = 10, esperaMs = 3000) {
  for (let i = 1; i <= tentativas; i++) {
    try {
      const conexao = mysql.createPool(dbConfig);
      await conexao.query('SELECT 1');
      console.log('Conectado ao banco de dados em', dbConfig.host);
      return conexao;
    } catch (erro) {
      console.error(`Tentativa ${i}/${tentativas} de conexao com o banco falhou: ${erro.message}`);
      if (i === tentativas) throw erro;
      await new Promise((resolve) => setTimeout(resolve, esperaMs));
    }
  }
}

async function iniciar() {
  pool = await conectarComRetry();

  // A tabela e criada pela propria aplicacao na primeira execucao — o RDS
  // nao tem um mecanismo de "init.sql" automatico como um container MySQL.
  await pool.query(`
    CREATE TABLE IF NOT EXISTS usuarios (
      id INT AUTO_INCREMENT PRIMARY KEY,
      nome VARCHAR(255) NOT NULL,
      email VARCHAR(255) NOT NULL,
      criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  app.listen(PORT, () => {
    console.log(`API rodando na porta ${PORT}`);
  });
}

// Rota simples so para confirmar que a API esta de pe.
app.get('/', (req, res) => {
  res.json({ mensagem: 'API Node.js rodando 🚀', banco: dbConfig.host });
});

app.get('/usuarios', async (req, res) => {
  try {
    const [linhas] = await pool.query('SELECT id, nome, email FROM usuarios ORDER BY id DESC');
    res.json(linhas);
  } catch (erro) {
    console.error('Erro ao consultar usuarios:', erro.message);
    res.status(500).json({ erro: 'Erro ao consultar usuarios' });
  }
});

app.post('/usuarios', async (req, res) => {
  const { nome, email } = req.body || {};
  if (!nome || !email) {
    return res.status(400).json({ erro: 'nome e email sao obrigatorios' });
  }

  try {
    const [resultado] = await pool.query(
      'INSERT INTO usuarios (nome, email) VALUES (?, ?)',
      [nome, email],
    );
    res.status(201).json({ id: resultado.insertId, nome, email });
  } catch (erro) {
    console.error('Erro ao cadastrar usuario:', erro.message);
    res.status(500).json({ erro: 'Erro ao cadastrar usuario' });
  }
});

iniciar().catch((erro) => {
  console.error('Falha ao iniciar a API:', erro.message);
  process.exit(1);
});
