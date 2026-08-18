// Dashboard ao vivo — gera carga contra /api/stress e, ao mesmo tempo,
// mostra em tempo real:
//   1. Quantas respostas vieram de CADA instancia (task) diferente —
//      prova visual do Load Balancer distribuindo o trafego.
//   2. O desiredCount/runningCount dos Services do ECS — prova visual
//      do Auto Scaling reagindo a carga.
//   3. A metrica de CPU/memoria mais recente do CloudWatch.
//
// Uso:
//   node dashboard.js <alb_dns_name> <cluster_name> <api_service_name>
//
// Ctrl+C para parar a qualquer momento — a carga para junto.

const http = require('http');
const { execSync } = require('child_process');

const [, , HOST, CLUSTER, SERVICE] = process.argv;
if (!HOST || !CLUSTER || !SERVICE) {
  console.error('Uso: node dashboard.js <alb_dns_name> <cluster_name> <api_service_name>');
  process.exit(1);
}

const CONCURRENCIA = 40; // requisicoes de stress simultaneas
const DURACAO_STRESS_MS = 4000; // cada requisicao de stress dura 4s

const contagemInstancias = {}; // { "hostname-da-task": numero_de_respostas }
let totalRespostas = 0;
let erros = 0;
let ativo = true;

const agent = new http.Agent({ keepAlive: true, maxSockets: CONCURRENCIA + 2 });

function dispararStress() {
  if (!ativo) return;
  const req = http.get(
    { host: HOST, path: `/api/stress?duracao_ms=${DURACAO_STRESS_MS}`, agent, timeout: 15000 },
    (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const dados = JSON.parse(body);
          contagemInstancias[dados.instancia] = (contagemInstancias[dados.instancia] || 0) + 1;
          totalRespostas++;
        } catch {
          erros++;
        }
        dispararStress();
      });
    },
  );
  req.on('error', () => {
    erros++;
    setTimeout(dispararStress, 500);
  });
}

for (let i = 0; i < CONCURRENCIA; i++) dispararStress();

// Consulta o AWS CLI para pegar o estado real do ECS e do CloudWatch.
// execSync e sincrono de proposito: e so uma vez a cada poucos
// segundos, simplicidade importa mais que performance aqui.
function consultarEcs() {
  try {
    const saida = execSync(
      `aws ecs describe-services --cluster ${CLUSTER} --services aula04-frontend ${SERVICE} ` +
        `--query "services[].{nome:serviceName,desejado:desiredCount,rodando:runningCount}" --output json`,
      { encoding: 'utf-8' },
    );
    return JSON.parse(saida);
  } catch {
    return null;
  }
}

function consultarMetrica(nomeMetrica) {
  try {
    const fim = new Date().toISOString().slice(0, 19);
    const inicio = new Date(Date.now() - 5 * 60 * 1000).toISOString().slice(0, 19);
    const saida = execSync(
      `aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name ${nomeMetrica} ` +
        `--dimensions Name=ClusterName,Value=${CLUSTER} Name=ServiceName,Value=${SERVICE} ` +
        `--start-time ${inicio} --end-time ${fim} --period 60 --statistics Average ` +
        `--query "sort_by(Datapoints, &Timestamp)[-1].Average" --output text`,
      { encoding: 'utf-8' },
    ).trim();
    return saida === 'None' || saida === '' ? null : Number(saida).toFixed(1);
  } catch {
    return null;
  }
}

function desenharDashboard() {
  console.clear();
  console.log('═══════════════════════════════════════════════════════════');
  console.log('  DASHBOARD AO VIVO — Load Balancing + Auto Scaling (Aula 04)');
  console.log('═══════════════════════════════════════════════════════════');
  console.log();

  console.log(`Requisicoes de stress concluidas: ${totalRespostas}  |  erros: ${erros}`);
  console.log();

  console.log('📊 Respostas por instancia (prova o Load Balancer distribuindo):');
  const instancias = Object.keys(contagemInstancias);
  if (instancias.length === 0) {
    console.log('   (aguardando as primeiras respostas...)');
  } else if (instancias.length === 1) {
    console.log(`   ${instancias[0]}: ${contagemInstancias[instancias[0]]} respostas`);
    console.log('   ⚠️  Só uma instância até agora — normal se o Auto Scaling');
    console.log('       ainda não escalou. Espere o desiredCount subir.');
  } else {
    for (const inst of instancias) {
      const barra = '█'.repeat(Math.min(contagemInstancias[inst], 50));
      console.log(`   ${inst}: ${contagemInstancias[inst]}  ${barra}`);
    }
  }
  console.log();

  const servicos = consultarEcs();
  console.log('⚙️  ECS Services (desiredCount / runningCount):');
  if (servicos) {
    for (const s of servicos) {
      console.log(`   ${s.nome}: ${s.desejado} / ${s.rodando}`);
    }
  } else {
    console.log('   (não consegui consultar — aws cli configurado?)');
  }
  console.log();

  const cpu = consultarMetrica('CPUUtilization');
  const memoria = consultarMetrica('MemoryUtilization');
  console.log('📈 Última métrica da api no CloudWatch:');
  console.log(`   CPU: ${cpu !== null ? cpu + '%' : 'sem dado ainda'}`);
  console.log(`   Memória: ${memoria !== null ? memoria + '%' : 'sem dado ainda'}`);
  console.log();
  console.log('Ctrl+C para parar.');
}

const intervalo = setInterval(desenharDashboard, 5000);
desenharDashboard();

process.on('SIGINT', () => {
  ativo = false;
  clearInterval(intervalo);
  console.log('\nParando... (as tasks extras, se houver, somem sozinhas após o scale-in)');
  process.exit(0);
});
