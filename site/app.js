/* Página de demonstração do simulador.
   - dados/resultados.json  agregados dos lotes oficiais (site/gerar_dados.py)
   - dados/replays.json     partidas gravadas (tools/replay_dump.gd)
   Nenhum número é calculado aqui: a página desenha o que os arquivos trazem. */

const CORES = ['#4ade80', '#f87171', '#60a5fa'];
const NOMES_JOGADOR = ['verde', 'vermelho', 'azul'];

const NOMES_MODELO = {
  pt: { 'art3miz_0.1': 'Art3miz 0.1', heuristica: 'Heurística', reativa: 'Reativa', aleatoria: 'Aleatória' },
  en: { 'art3miz_0.1': 'Art3miz 0.1', heuristica: 'Heuristic', reativa: 'Reactive', aleatoria: 'Random' },
};

let idioma = 'pt';
let resultados = null;
let replays = null;

/* ============ idioma ============ */

function t(chave) {
  return (TEXTOS[idioma] && TEXTOS[idioma][chave]) || TEXTOS.pt[chave] || chave;
}

/* verde/vermelho/azul sao os nomes dos jogadores no simulador, e aparecem
   crus no vencedor e no log de combate. Em ingles eles tambem traduzem. */
function nomeJogador(bruto) {
  return t(`jogador.${bruto}`) || bruto;
}

function nomeModelo(bruto) {
  const tabela = NOMES_MODELO[idioma] || NOMES_MODELO.pt;
  return tabela[bruto] || bruto;
}

function num(valor, casas) {
  return valor.toLocaleString(idioma === 'pt' ? 'pt-BR' : 'en-US', {
    minimumFractionDigits: casas,
    maximumFractionDigits: casas,
  });
}

function aplicarIdioma() {
  document.documentElement.lang = t('meta.lang');
  document.title = t('titulo');
  document.querySelectorAll('[data-t]').forEach((el) => {
    el.textContent = t(el.dataset.t);
  });
  document.querySelectorAll('[data-t-html]').forEach((el) => {
    el.innerHTML = t(el.dataset.tHtml);
  });
  document.querySelectorAll('.idioma').forEach((b) => {
    b.classList.toggle('ativo', b.dataset.idioma === idioma);
  });
  renderTudo();
}

document.querySelectorAll('.idioma').forEach((botao) => {
  botao.addEventListener('click', () => {
    idioma = botao.dataset.idioma;
    aplicarIdioma();
  });
});

/* ============ tabelas ============ */

function tabela(alvo, colunas, linhas) {
  const cabeca = colunas.map((c) => `<th>${c.titulo}</th>`).join('');
  const corpo = linhas
    .map((linha) => {
      const celulas = colunas
        .map((c) => `<td class="${linha.classes?.[c.chave] || ''}">${linha[c.chave]}</td>`)
        .join('');
      return `<tr>${celulas}</tr>`;
    })
    .join('');
  alvo.innerHTML = `<thead><tr>${cabeca}</tr></thead><tbody>${corpo}</tbody>`;
}

/* Marca a melhor célula de cada coluna. "Melhor" nem sempre é o maior:
   custo e turnos para vitória são melhores quando menores. */
function marcarMelhores(linhas, campos) {
  for (const [campo, menorEhMelhor] of Object.entries(campos)) {
    const valores = linhas.map((l) => l.bruto[campo]);
    const alvo = menorEhMelhor ? Math.min(...valores) : Math.max(...valores);
    linhas.forEach((l) => {
      if (l.bruto[campo] === alvo) l.classes[campo] = 'melhor';
    });
  }
}

function renderAutoconfronto() {
  const linhas = resultados.autoconfronto.map((a) => ({
    bruto: a,
    classes: {},
    modelo: nomeModelo(a.modelo),
    win_rate: num(a.win_rate, 3),
    damage_ratio: num(a.damage_ratio, 2),
    cover_usage: num(a.cover_usage, 3),
    turnos_para_vitoria: num(a.turnos_para_vitoria, 1),
    custo: num(a.custo, 0),
    strategic_score: num(a.strategic_score, 3),
  }));

  // A aleatória não vence nenhuma partida: incluí-la no "melhor" de turnos
  // para vitória premiaria quem simplesmente nunca decidiu a partida.
  const funcionais = linhas.filter((l) => l.bruto.win_rate > 0);
  marcarMelhores(funcionais, {
    win_rate: false,
    cover_usage: false,
    turnos_para_vitoria: true,
    custo: true,
    strategic_score: false,
  });

  tabela(document.getElementById('tabelaAuto'), [
    { chave: 'modelo', titulo: t('col.modelo') },
    { chave: 'win_rate', titulo: t('col.winrate') },
    { chave: 'damage_ratio', titulo: t('col.dano') },
    { chave: 'cover_usage', titulo: t('col.cobertura') },
    { chave: 'turnos_para_vitoria', titulo: t('col.turnos') },
    { chave: 'custo', titulo: t('col.custo') },
    { chave: 'strategic_score', titulo: t('col.score') },
  ], linhas);
}

function renderConfrontoDireto() {
  const linhas = resultados.lotes.confronto_triplo.linhas.map((l) => ({
    bruto: l,
    classes: {},
    modelo: nomeModelo(l.modelo_ia),
    win_rate: num(l.win_rate, 3),
    damage_ratio_media: num(l.damage_ratio_media, 2),
    cover_usage_media: num(l.cover_usage_media, 3),
    turns_to_victory_media: num(l.turns_to_victory_media, 1),
    custo_medio: num(l.custo_medio, 0),
    efficiency: num(l.efficiency, 3),
    strategic_score: num(l.strategic_score, 3),
  }));

  marcarMelhores(linhas, {
    win_rate: false,
    cover_usage_media: false,
    turns_to_victory_media: true,
    custo_medio: true,
    efficiency: false,
    strategic_score: false,
  });

  tabela(document.getElementById('tabelaDireto'), [
    { chave: 'modelo', titulo: t('col.modelo') },
    { chave: 'win_rate', titulo: t('col.winrate') },
    { chave: 'damage_ratio_media', titulo: t('col.dano') },
    { chave: 'cover_usage_media', titulo: t('col.cobertura') },
    { chave: 'turns_to_victory_media', titulo: t('col.turnos') },
    { chave: 'custo_medio', titulo: t('col.custo') },
    { chave: 'efficiency', titulo: t('col.eficiencia') },
    { chave: 'strategic_score', titulo: t('col.score') },
  ], linhas);
}

function renderSignificancia() {
  const linhas = ['l1', 'l2', 'l3', 'l4', 'l5', 'l6'].map((id) => ({
    classes: { resultado: id === 'l4' || id === 'l6' ? 'nao' : 'sim' },
    comparacao: t(`sig.${id}.c`),
    teste: t(`sig.${id}.t`),
    resultado: t(`sig.${id}.r`),
  }));

  tabela(document.getElementById('tabelaSig'), [
    { chave: 'comparacao', titulo: t('col.comparacao') },
    { chave: 'teste', titulo: t('col.teste') },
    { chave: 'resultado', titulo: t('col.resultado') },
  ], linhas);
}

function renderNeutralidade() {
  const dados = resultados.neutralidade;
  const maximo = 0.5;
  const alvo = (1 / 3 / maximo) * 100;

  document.getElementById('neutralidade').innerHTML = dados.win_rates
    .map((w, i) => `
      <div class="faixa-wr">
        <span class="rotulo">${w.jogador}</span>
        <span class="trilho">
          <i style="width:${(w.win_rate / maximo) * 100}%;background:${CORES[i]}"></i>
          <span class="terco" style="left:${alvo}%" title="${t('neutro.terco')}"></span>
        </span>
        <span class="valor">${num(w.win_rate, 3)}</span>
      </div>`)
    .join('');
}

/* ============ replay ============ */

const canvas = document.getElementById('tabuleiro');
const ctx = canvas.getContext('2d');

const estado = { partida: 0, quadro: 0, tocando: false, ultimo: 0 };

const PINTURA = { '#': '--parede', l: '--leve', H: '--pesada' };

function corVar(nome) {
  return getComputedStyle(document.documentElement).getPropertyValue(nome).trim();
}

function desenhar() {
  const partida = replays.partidas[estado.partida];
  const mapa = partida.mapa;
  const lado = canvas.width / mapa.largura;

  ctx.fillStyle = corVar('--carta');
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  for (let y = 0; y < mapa.altura; y++) {
    for (let x = 0; x < mapa.largura; x++) {
      const variavel = PINTURA[mapa.celulas[y][x]];
      if (!variavel) continue;
      ctx.fillStyle = corVar(variavel);
      ctx.fillRect(x * lado, y * lado, lado, lado);
    }
  }

  const quadro = partida.quadros[estado.quadro];
  desenharRastro(quadro, lado);
  desenharTiros(quadro, lado);

  quadro.agentes.forEach((agente, i) => {
    if (!agente.vivo) return;
    const cx = (agente.x + 0.5) * lado;
    const cy = (agente.y + 0.5) * lado;
    const raio = lado * 0.42;

    // Anel de HP: o arco cobre a fração de vida restante.
    ctx.beginPath();
    ctx.arc(cx, cy, raio + 2.5, -Math.PI / 2, -Math.PI / 2 + (agente.hp / 100) * Math.PI * 2);
    ctx.strokeStyle = CORES[i];
    ctx.globalAlpha = 0.45;
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.globalAlpha = 1;

    ctx.beginPath();
    ctx.arc(cx, cy, raio, 0, Math.PI * 2);
    ctx.fillStyle = CORES[i];
    ctx.fill();

    if (quadro.vez === i) {
      ctx.beginPath();
      ctx.arc(cx, cy, raio + 5, 0, Math.PI * 2);
      // Branco, e nao o acento: o acento tambem pinta a cobertura pesada, e
      // no mapa os dois viravam a mesma marca.
      ctx.strokeStyle = corVar('--texto');
      ctx.lineWidth = 1.5;
      ctx.stroke();
    }
  });

  renderPainel(partida, quadro);
}

/* De onde o agente da vez saiu ate onde parou. Sem isso o unico sinal de
   movimento e um circulo teleportando entre dois quadros. */
function desenharRastro(quadro, lado) {
  const time = quadro.vez;
  if (time < 0 || !quadro.saiu_de) return;
  const [ox, oy] = quadro.saiu_de;
  if (ox < 0) return;
  const agente = quadro.agentes[time];
  if (ox === agente.x && oy === agente.y) return;

  ctx.save();
  ctx.setLineDash([3, 3]);
  ctx.strokeStyle = CORES[time];
  ctx.globalAlpha = 0.5;
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo((ox + 0.5) * lado, (oy + 0.5) * lado);
  ctx.lineTo((agente.x + 0.5) * lado, (agente.y + 0.5) * lado);
  ctx.stroke();
  ctx.restore();
}

/* O tiro que acertou neste turno: linha do atirador ao alvo, mais um alvo
   marcado no ponto de impacto. So chega aqui tiro que causou dano. */
function desenharTiros(quadro, lado) {
  for (const tiro of quadro.tiros || []) {
    const de = { x: (tiro.de[0] + 0.5) * lado, y: (tiro.de[1] + 0.5) * lado };
    const para = { x: (tiro.para[0] + 0.5) * lado, y: (tiro.para[1] + 0.5) * lado };

    ctx.save();
    ctx.strokeStyle = CORES[tiro.time];
    ctx.lineCap = 'round';

    ctx.globalAlpha = 0.22;
    ctx.lineWidth = 7;
    ctx.beginPath();
    ctx.moveTo(de.x, de.y);
    ctx.lineTo(para.x, para.y);
    ctx.stroke();

    ctx.globalAlpha = 1;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(de.x, de.y);
    ctx.lineTo(para.x, para.y);
    ctx.stroke();

    const r = lado * 0.55;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.arc(para.x, para.y, r, 0, Math.PI * 2);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(para.x - r * 1.4, para.y);
    ctx.lineTo(para.x + r * 1.4, para.y);
    ctx.moveTo(para.x, para.y - r * 1.4);
    ctx.lineTo(para.x, para.y + r * 1.4);
    ctx.stroke();
    ctx.restore();
  }
}

/* A frase de combate do turno, montada a partir da perda de HP entre este
   quadro e o anterior. O simulador tambem escreve uma, mas em portugues e em
   prosa: reaproveitar aquela deixaria metade da frase sem traduzir na versao
   em ingles, e reescreve-la no navegador seria adivinhar. O dano medido esta
   nos proprios dados. */
function frase(partida, indiceQuadro) {
  if (indiceQuadro === 0) return '';
  const quadro = partida.quadros[indiceQuadro];
  const antes = partida.quadros[indiceQuadro - 1];
  const partes = [];

  quadro.agentes.forEach((agente, i) => {
    const dano = antes.agentes[i].hp - agente.hp;
    if (dano <= 0) return;
    const alvo = nomeJogador(NOMES_JOGADOR[i]);
    if (agente.hp === 0) {
      const autor = quadro.vez >= 0 ? nomeJogador(NOMES_JOGADOR[quadro.vez]) : '';
      partes.push(t('evento.eliminado')
        .replace('{alvo}', alvo).replace('{dano}', dano).replace('{autor}', autor));
    } else {
      partes.push(t('evento.dano')
        .replace('{alvo}', alvo).replace('{dano}', dano).replace('{hp}', agente.hp));
    }
  });

  return partes.join(' · ');
}

function renderPainel(partida, quadro) {
  document.getElementById('agentes').innerHTML = quadro.agentes
    .map((agente, i) => `
      <div class="agente ${agente.vivo ? '' : 'morto'}">
        <span class="ponto" style="background:${CORES[i]}"></span>
        <span class="nome">${nomeModelo(replays.escalacao[i])}</span>
        <span class="hp">${agente.hp}</span>
        <span class="barra"><i style="width:${agente.hp}%;background:${CORES[i]}"></i></span>
      </div>`)
    .join('');

  document.getElementById('metaSeed').textContent = partida.seed;
  document.getElementById('metaTurno').textContent =
    `${quadro.turno} / ${partida.turnos}`;

  const fim = estado.quadro === partida.quadros.length - 1;
  document.getElementById('metaVencedor').textContent = fim
    ? (partida.vencedor === 'draw' ? t('replay.empate') : nomeJogador(partida.vencedor))
    : t('replay.emCurso');

  document.getElementById('evento').textContent = frase(partida, estado.quadro);
  document.getElementById('linhaTempo').value = estado.quadro;
}

function passo(delta) {
  const total = replays.partidas[estado.partida].quadros.length;
  estado.quadro = Math.min(total - 1, Math.max(0, estado.quadro + delta));
  if (estado.quadro === total - 1) parar();
  desenhar();
}

function laco(agora) {
  if (!estado.tocando) return;

  // O controle e em turnos por segundo, nao em quadros por segundo: e o
  // turno que a pessoa esta tentando acompanhar.
  let intervalo = 1000 / Number(document.getElementById('velocidade').value);

  // Turno com tiro fica mais tempo na tela. Sem isso o unico quadro que
  // explica a partida e o que passa mais rapido.
  const atual = replays.partidas[estado.partida].quadros[estado.quadro];
  if (atual && atual.tiros && atual.tiros.length) intervalo *= 2.2;

  if (agora - estado.ultimo >= intervalo) {
    estado.ultimo = agora;
    passo(1);
  }
  requestAnimationFrame(laco);
}

function tocar() {
  const total = replays.partidas[estado.partida].quadros.length;
  if (estado.quadro >= total - 1) estado.quadro = 0;
  estado.tocando = true;
  estado.ultimo = 0;
  document.getElementById('btnTocar').textContent = t('replay.pausar');
  requestAnimationFrame(laco);
}

function parar() {
  estado.tocando = false;
  document.getElementById('btnTocar').textContent = t('replay.tocar');
}

function carregarPartida(indice) {
  parar();
  estado.partida = indice;
  estado.quadro = 0;
  document.getElementById('linhaTempo').max =
    replays.partidas[indice].quadros.length - 1;
  desenhar();
}

function rotularPartidas() {
  const seletor = document.getElementById('selPartida');
  const escolhido = seletor.value;
  seletor.innerHTML = replays.partidas
    .map((p, i) => {
      const desfecho = p.vencedor === 'draw' ? t('replay.empate') : nomeJogador(p.vencedor);
      return `<option value="${i}">#${i + 1} · seed ${p.seed} · ${desfecho} · ${p.turnos}t</option>`;
    })
    .join('');
  seletor.value = escolhido || String(estado.partida);
}

function montarReplay() {
  const seletor = document.getElementById('selPartida');
  rotularPartidas();
  seletor.addEventListener('change', () => carregarPartida(Number(seletor.value)));

  document.getElementById('btnTocar').addEventListener('click', () => {
    estado.tocando ? parar() : tocar();
  });
  document.getElementById('btnPasso').addEventListener('click', () => {
    parar();
    passo(1);
  });
  document.getElementById('btnReiniciar').addEventListener('click', () => {
    parar();
    estado.quadro = 0;
    desenhar();
  });
  document.getElementById('linhaTempo').addEventListener('input', (e) => {
    parar();
    estado.quadro = Number(e.target.value);
    desenhar();
  });

  carregarPartida(0);
  tocar();
}

/* ============ arranque ============ */

function renderTudo() {
  if (replays && replays.partidas.length) rotularPartidas();
  if (resultados) {
    renderAutoconfronto();
    renderConfrontoDireto();
    renderSignificancia();
    renderNeutralidade();
    const data = new Date(resultados.gerado_em);
    document.getElementById('carimbo').textContent =
      `${t('rodape.dados')} ${data.toLocaleDateString(idioma === 'pt' ? 'pt-BR' : 'en-US')}`;
  }
  if (replays && replays.partidas.length) desenhar();
}

async function carregar(caminho) {
  try {
    const resposta = await fetch(caminho, { cache: 'no-store' });
    return resposta.ok ? await resposta.json() : null;
  } catch {
    return null;
  }
}

(async function inicio() {
  [resultados, replays] = await Promise.all([
    carregar('dados/resultados.json'),
    carregar('dados/replays.json'),
  ]);

  if (replays && replays.partidas && replays.partidas.length) {
    montarReplay();
  } else {
    // Sem replay a página continua inteira: o resto não depende dele.
    document.querySelector('.palco').hidden = true;
    document.getElementById('semReplay').hidden = false;
  }

  aplicarIdioma();
})();
