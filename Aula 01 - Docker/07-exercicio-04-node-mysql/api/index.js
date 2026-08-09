// =============================================================================
// API Node.js de exemplo — conecta em um banco MySQL rodando em outro
// container, orquestrados juntos pelo docker-compose.yml desta pasta.
// =============================================================================

const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
const PORT = process.env.PORT || 3000;

// -----------------------------------------------------------------------------
// Configuração de conexão com o MySQL.
//
// Repare que os valores vêm de VARIÁVEIS DE AMBIENTE, definidas lá no
// docker-compose.yml (seção "environment" do serviço "api"). Isso evita
// deixar senha e configuração de banco "hardcoded" no código.
//
// O detalhe mais importante: DB_HOST = "db". Esse NÃO é um endereço de
// rede comum — é o NOME DO SERVIÇO do MySQL no docker-compose.yml. O
// Docker Compose cria automaticamente uma rede interna onde cada
// serviço enxerga os outros pelo próprio nome, como se fosse um DNS.
// Ou seja: "db" resolve para o IP interno do container do MySQL.
// -----------------------------------------------------------------------------
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'root',
  database: process.env.DB_NAME || 'aula_docker',
};

// Rota simples só para confirmar que a API está de pé.
app.get('/', (req, res) => {
  res.json({ mensagem: 'API Node.js rodando em container 🐳' });
});

// Rota que efetivamente consulta o MySQL e devolve os dados.
// A tabela "usuarios" é criada e populada automaticamente pelo script
// db/init.sql na primeira vez que o container do MySQL sobe (veja o
// README para entender como isso é configurado no docker-compose.yml).
app.get('/usuarios', async (req, res) => {
  let connection;
  try {
    connection = await mysql.createConnection(dbConfig);
    const [linhas] = await connection.execute('SELECT * FROM usuarios');
    res.json(linhas);
  } catch (erro) {
    console.error('Erro ao consultar usuarios:', erro.message);
    res.status(500).json({ erro: 'Erro ao conectar ao banco de dados' });
  } finally {
    if (connection) await connection.end();
  }
});

app.listen(PORT, () => {
  console.log(`API rodando na porta ${PORT}`);
});
