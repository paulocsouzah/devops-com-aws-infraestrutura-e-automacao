-- =============================================================================
-- Script de inicialização do banco de dados.
--
-- Este arquivo é montado dentro do container do MySQL na pasta especial
-- /docker-entrypoint-initdb.d/ (veja o volume no docker-compose.yml).
-- A imagem oficial do MySQL executa automaticamente, uma única vez —
-- somente na PRIMEIRA inicialização de um volume de dados vazio — todo
-- arquivo .sql encontrado nessa pasta. É assim que criamos e populamos
-- a tabela "usuarios" sem precisar rodar nada manualmente.
-- =============================================================================

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL
);

INSERT INTO usuarios (nome, email) VALUES
  ('Ana Silva', 'ana@exemplo.com'),
  ('Bruno Costa', 'bruno@exemplo.com'),
  ('Carla Souza', 'carla@exemplo.com');
