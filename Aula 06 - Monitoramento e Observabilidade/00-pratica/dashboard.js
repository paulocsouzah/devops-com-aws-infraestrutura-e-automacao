#!/usr/bin/env node
// =============================================================================
// Dashboard ao vivo — Aula 04, modulo 05 (Load Balancing + Auto Scaling).
//
// Gera carga real contra a api via GET /api/stress e, a cada 5s, redesenha
// a tela mostrando: quantas respostas vieram de cada task (Load Balancer
// distribuindo), o desiredCount/runningCount dos dois Services (Auto
// Scaling reagindo) e a ultima media de CPU/memoria da api no CloudWatch.
//
// So usa modulos nativos do Node (http, child_process) + a AWS CLI ja
// configurada no terminal — nao precisa de "npm install".
//
// Uso: node dashboard.js <ALB_DNS> <cluster> <api-service>
// Exemplo: node dashboard.js meu-alb-123.sa-east-1.elb.amazonaws.com aula04-cluster aula04-api
// =============================================================================

'use strict';

const http = require('http');
const { execFile } = require('child_process');

const [, , albDns, cluster, apiService] = process.argv;

if (!albDns || !cluster || !apiService) {
  console.error('Uso: node dashboard.js <ALB_DNS> <cluster> <api-service>');
  console.error(
    'Exemplo: node dashboard.js meu-alb-123.sa-east-1.elb.amazonaws.com aula04-cluster aula04-api',
  );
  process.exit(1);
}

// O frontend nao tem endpoint de estresse proprio (so a api tem), mas o
// dashboard mostra os dois Services — o nome do frontend segue o mesmo
// project_name do nome da api recebido (ex.: "aula04-api" -> "aula04-frontend").
const frontendService = apiService.replace(/-api$/, '-frontend');

const CONCORRENCIA = 4; // requisicoes de /api/stress em paralelo, para sustentar CPU alta
const DURACAO_STRESS_MS = 5000;
const INTERVALO_TELA_MS = 5000;

let gerandoCarga = true;
const respostasPorInstancia = new Map();
let erros = 0;
let ultimoEcs = null;
let ultimaMetrica = null;

// Primeiro Ctrl+C: para de gerar carga nova, mas deixa o dashboard vivo
// pra continuar observando o scale-in. Segundo Ctrl+C: sai de fato.
process.on('SIGINT', () => {
  if (gerandoCarga) {
    gerandoCarga = false;
    console.log('\n⏹  Carga interrompida. Observando o ECS... (Ctrl+C de novo para sair)');
  } else {
    console.log('\nSaindo.');
    process.exit(0);
  }
});

function chamarStress() {
  if (!gerandoCarga) return;

  const req = http.get(
    { host: albDns, path: `/api/stress?duracao_ms=${DURACAO_STRESS_MS}`, timeout: DURACAO_STRESS_MS + 10000 },
    (res) => {
      let corpo = '';
      res.on('data', (pedaco) => (corpo += pedaco));
      res.on('end', () => {
        try {
          const { instancia } = JSON.parse(corpo);
          respostasPorInstancia.set(instancia, (respostasPorInstancia.get(instancia) || 0) + 1);
        } catch {
          erros++;
        }
        chamarStress();
      });
    },
  );
  req.on('timeout', () => req.destroy());
  req.on('error', () => {
    erros++;
    setTimeout(chamarStress, 1000);
  });
}

function awsCliJson(args) {
  return new Promise((resolve, reject) => {
    execFile('aws', args, { maxBuffer: 1024 * 1024 }, (erro, stdout) => {
      if (erro) return reject(erro);
      try {
        resolve(JSON.parse(stdout));
      } catch (erroParse) {
        reject(erroParse);
      }
    });
  });
}

async function atualizarEcs() {
  try {
    const dados = await awsCliJson([
      'ecs', 'describe-services',
      '--cluster', cluster,
      '--services', apiService, frontendService,
      '--output', 'json',
    ]);
    ultimoEcs = dados.services.map((s) => ({
      nome: s.serviceName,
      desejado: s.desiredCount,
      rodando: s.runningCount,
    }));
  } catch {
    ultimoEcs = null;
  }
}

function ultimoDatapoint(pontos) {
  if (!pontos || pontos.length === 0) return null;
  return [...pontos].sort((a, b) => new Date(b.Timestamp) - new Date(a.Timestamp))[0].Average;
}

async function metricaCloudWatch(nomeMetrica) {
  const agora = new Date();
  const inicio = new Date(agora.getTime() - 5 * 60 * 1000);
  const dados = await awsCliJson([
    'cloudwatch', 'get-metric-statistics',
    '--namespace', 'AWS/ECS',
    '--metric-name', nomeMetrica,
    '--dimensions', `Name=ClusterName,Value=${cluster}`, `Name=ServiceName,Value=${apiService}`,
    '--start-time', inicio.toISOString(),
    '--end-time', agora.toISOString(),
    '--period', '60',
    '--statistics', 'Average',
    '--output', 'json',
  ]);
  return ultimoDatapoint(dados.Datapoints);
}

async function atualizarMetricas() {
  try {
    const [cpu, memoria] = await Promise.all([
      metricaCloudWatch('CPUUtilization'),
      metricaCloudWatch('MemoryUtilization'),
    ]);
    ultimaMetrica = { cpu, memoria };
  } catch {
    ultimaMetrica = null;
  }
}

function barra(qtd, max) {
  if (qtd <= 0) return '';
  const escala = max > 0 ? Math.round((qtd / max) * 30) : 0;
  return '█'.repeat(Math.max(escala, 1));
}

function desenhar() {
  console.clear();
  console.log('📊 Dashboard — Load Balancing + Auto Scaling (Aula 04)');
  console.log(`ALB: http://${albDns}`);
  console.log(gerandoCarga ? '🔥 Gerando carga real via /api/stress...' : '⏸  Carga parada (Ctrl+C de novo para sair)');
  console.log('');

  console.log('Respostas por instancia (task da api):');
  if (respostasPorInstancia.size === 0) {
    console.log('  (nenhuma resposta ainda...)');
  } else {
    const maxQtd = Math.max(...respostasPorInstancia.values());
    const linhas = [...respostasPorInstancia.entries()].sort((a, b) => b[1] - a[1]);
    for (const [instancia, qtd] of linhas) {
      console.log(`  ${instancia.padEnd(28)} ${barra(qtd, maxQtd).padEnd(32)} ${qtd}`);
    }
  }
  const total = [...respostasPorInstancia.values()].reduce((soma, n) => soma + n, 0);
  console.log(`  Total: ${total} respostas | erros: ${erros}`);
  console.log('');

  console.log('ECS (desiredCount / runningCount):');
  if (ultimoEcs) {
    for (const s of ultimoEcs) {
      console.log(`  ${s.nome.padEnd(20)} desejado=${s.desejado}  rodando=${s.rodando}`);
    }
  } else {
    console.log('  (nao foi possivel consultar — confira as credenciais/regiao da AWS CLI)');
  }
  console.log('');

  console.log(`CloudWatch — media dos ultimos 5 min (${apiService}):`);
  if (ultimaMetrica) {
    const cpuTxt = ultimaMetrica.cpu != null ? `${ultimaMetrica.cpu.toFixed(1)}%` : 'sem dado ainda';
    const memTxt = ultimaMetrica.memoria != null ? `${ultimaMetrica.memoria.toFixed(1)}%` : 'sem dado ainda';
    console.log(`  CPU: ${cpuTxt}   Memoria: ${memTxt}`);
  } else {
    console.log('  (sem dado ainda)');
  }
  console.log('');
  console.log(`Atualiza a cada ${INTERVALO_TELA_MS / 1000}s.`);
}

async function loopAtualizacaoTela() {
  for (;;) {
    await Promise.all([atualizarEcs(), atualizarMetricas()]);
    desenhar();
    await new Promise((resolve) => setTimeout(resolve, INTERVALO_TELA_MS));
  }
}

for (let i = 0; i < CONCORRENCIA; i++) chamarStress();
loopAtualizacaoTela();
