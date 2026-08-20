// =============================================================================
// API Node.js da Aula 03 — conecta num MySQL externo (RDS em producao, um
// container local em desenvolvimento). O host do banco vem sempre de uma
// variavel de ambiente, nunca fixo no codigo (ver README do modulo 03).
// =============================================================================

const os = require('os');
const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 4000;

// Identificador desta instancia: no Fargate (modo de rede awsvpc), cada
// task recebe seu proprio hostname, unico por task — util para PROVAR
// visualmente que o Load Balancer distribui requisicoes entre tasks
// diferentes (Aula 04, modulo 05). Funciona igual localmente: cada
// container do Docker tambem tem hostname proprio.
const instanceId = os.hostname();

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

// Rota simples so para confirmar que a API esta de pe. Fica em "/" (sem
// prefixo) de proposito: e essa rota que o health check do Target Group
// do ALB chama diretamente (Aula 04), sem passar por nenhum roteamento.
app.get('/', (req, res) => {
  res.json({ mensagem: 'API Node.js rodando 🚀', banco: dbConfig.host });
});

// As rotas de negocio ficam sob "/api" — tanto o nginx do frontend
// (Aula 03, proxy_pass com variavel) quanto o Application Load Balancer
// (Aula 04, listener rule "/api/*") encaminham a requisicao para a api
// SEM remover esse prefixo, entao e a propria aplicacao quem precisa
// "morar" nesse caminho, nao o proxy na frente dela.
app.get('/api/usuarios', async (req, res) => {
  try {
    const [linhas] = await pool.query('SELECT id, nome, email FROM usuarios ORDER BY id DESC');
    res.json(linhas);
  } catch (erro) {
    console.error('Erro ao consultar usuarios:', erro.message);
    res.status(500).json({ erro: 'Erro ao consultar usuarios' });
  }
});

// Identifica qual instancia (task) respondeu — chame varias vezes
// seguidas contra o ALB e observe o campo "instancia" mudando entre as
// respostas: e o Load Balancer distribuindo entre tasks diferentes.
app.get('/api/status', (req, res) => {
  res.json({
    instancia: instanceId,
    timestamp: new Date().toISOString(),
  });
});

// -----------------------------------------------------------------------------
// Endpoint de estresse — SO PARA FINS DIDATICOS (Aula 04, modulo 05).
// Gera carga real de CPU (e, opcionalmente, memoria) por um tempo
// controlado, para provocar o Auto Scaling de forma rapida e repetivel,
// sem depender de milhares de requisicoes reais de negocio.
//
// O trabalho de CPU e feito em FATIAS pequenas (setImmediate entre
// elas) de proposito: o Node.js e single-threaded, e um laco síncrono
// longo travaria o event loop inteiro — inclusive as respostas ao
// health check do ALB, o que derrubaria a task no meio da demonstracao.
// Fatiando o trabalho, o event loop sempre tem brechas para atender
// outras requisicoes (como o proprio health check) entre uma fatia e
// outra.
// -----------------------------------------------------------------------------
app.get('/api/stress', (req, res) => {
  const duracaoMs = Math.min(Math.max(Number(req.query.duracao_ms) || 5000, 100), 30000);
  const memoriaMb = Math.min(Math.max(Number(req.query.memoria_mb) || 0, 0), 100);

  // Aloca e mantem memoria referenciada durante o teste — libera no
  // final para o garbage collector poder recuperar. Cuidado ao exagerar
  // no memoria_mb: a task tem so 512MB no total (Aula 04); passar disso
  // derruba o container por falta de memoria (OOMKilled) — o que
  // tambem e uma licao real sobre limites de recursos.
  let buffers = [];
  for (let i = 0; i < memoriaMb; i++) buffers.push(Buffer.alloc(1024 * 1024));

  const fim = Date.now() + duracaoMs;
  function trabalhar() {
    const fatiaFim = Date.now() + 40;
    while (Date.now() < fatiaFim && Date.now() < fim) {
      Math.sqrt(Math.random() * Math.random());
    }
    if (Date.now() < fim) {
      setImmediate(trabalhar);
    } else {
      buffers = null;
      res.json({
        instancia: instanceId,
        duracao_ms: duracaoMs,
        memoria_mb: memoriaMb,
        mensagem: 'stress concluido',
      });
    }
  }
  trabalhar();
});

app.post('/api/usuarios', async (req, res) => {
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
