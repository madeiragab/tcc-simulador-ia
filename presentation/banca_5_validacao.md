# Banca 5 — Passo 02: Validação Experimental

**Roteiro de apresentação** · Simulador Tático para Avaliação de IA
Gabriel Madeira · Orientador: Ricardo Martins · Coorientador: Diego Penha

> **Identidade visual**: manter o template das bancas anteriores.

> **Mensagem central**: os modelos de referência foram caracterizados
> experimentalmente. Existe um gradiente de inteligência — e ele **custa caro**.
> A medição revela exatamente *onde* o custo mora, e essa descoberta orienta o
> desenho do Art3miz 0.1.

---

## Slide 1 — Capa

**Avaliação Experimental de um Modelo Híbrido para Decisão Estratégica em
Simulações de Combate Baseadas em Turnos**

Subtítulo: *Passo 02 — Validação Experimental e Caracterização dos Modelos*

---

## Slide 2 — Onde paramos

Passo 01 entregue: ambiente completo, logger com *Operation Count*, pipeline
automatizado e **neutralidade do instrumento validada** em mil partidas.

**Compromisso desta etapa (Passo 02)**:
- Executar o benchmark sobre o banco de mil sementes
- Coletar as métricas estratégicas e computacionais
- Realizar a análise estatística

---

## Slide 3 — Os três modelos de referência

| Modelo | Mecanismo | Papel |
|---|---|---|
| **Aleatória** | Sorteia entre as ações válidas | Piso absoluto |
| **Reativa** | Regras em cascata: atacar se há linha de tiro; senão aproximar; senão caçar | Agente funcional básico |
| **Heurística** | Avaliação multicritério de cada posição alcançável | Estratégia sem restrição de custo |

Todos implementam o **mesmo contrato**: recebem o estado, devolvem uma ação. A
simulação valida e aplica. Trocar o modelo é um argumento de linha de comando —
garantia de que todos jogam exatamente o mesmo jogo.

---

## Slide 4 — A IA Heurística em detalhe

Instância de *Utility AI* (MARK; DILL, 2010). Cada posição alcançável recebe:

**ValorEstratégico = w₁·Vida + w₂·Cobertura + w₃·Proximidade + w₄·Risco + Movimentação**

- **Vida**: proporção de pontos de vida
- **Cobertura**: proteção potencial da posição
- **Proximidade**: inverso da distância ao inimigo visível mais próximo
- **Risco**: fração de inimigos com linha de visão para a posição (peso negativo)
- **Movimentação**: incentivo fixo de deslocamento, que impede entrincheiramento

Escolhe-se a posição de maior valor (*argmax*).

---

## Slide 5 — Aprendizado entre partidas

No lote, a **mesma instância** joga todas as partidas e recebe a pontuação de
cada uma: **+3 vitória, −1 empate, −3 derrota**.

O empate é penalizado de propósito: sobreviver sem decidir a partida não
demonstra eficácia.

A heurística calibra seus pesos por **subida de encosta**: joga uma janela de 25
partidas, mede a média, adota se superou a melhor conhecida, reverte se não. Todo
o processo é semeado — **reprodutível**.

Ao fim do lote, a evolução completa é gravada e as instâncias são descartadas.

---

## Slide 6 — Protocolo da campanha

Quatro lotes de **mil partidas** cada, sobre o mesmo banco de sementes:

| Lote | Escalação | O que caracteriza |
|---|---|---|
| 1 | 3× Aleatória | Piso absoluto |
| 2 | 3× Reativa | Comportamento reativo isolado + revalidação da neutralidade |
| 3 | 3× Heurística | Comportamento estratégico isolado |
| 4 | Uma de cada | **O confronto que revela o gradiente** |

*Fala*: os autoconfrontos caracterizam o comportamento de cada modelo em
condições simétricas; o confronto misto mede eficácia relativa.

---

## Slide 7 — RESULTADO 1: o gradiente de inteligência

Confronto direto, mil partidas, uma IA de cada:

| Métrica | Aleatória | Reativa | Heurística |
|---|---|---|---|
| Taxa de vitória | 0,027 | 0,150 | **0,190** |
| Pontuação média | −1,57 | −0,83 | **−0,59** |
| Razão de dano | 0,11 | 11,17 | **13,08** |
| **Custo** | 1520 | **1358** | 1811 |

O gradiente aparece em **todas** as métricas de eficácia, na ordem esperada.

**Mas**: a heurística vence 27% mais que a reativa **pagando 33% mais operações**.
Esse é o trade-off central da pesquisa, agora medido.

---

## Slide 8 — RESULTADO 2: a aleatória é cara

Autoconfronto de três IAs Aleatórias, mil partidas:

- **Zero vitórias.** Todas as partidas terminaram por esgotamento de turnos.
- **Maior custo de todos os modelos**: 2323 operações por partida.

Ela enumera exaustivamente todas as ações a cada turno e **descarta a
informação obtida**. Custo sem benefício.

*Fala*: é um bom slide para fixar a ideia de que gastar processamento não é o
mesmo que decidir bem — a mensagem que o trabalho inteiro persegue.

---

## Slide 9 — RESULTADO 3: onde mora o custo

Decomposição do custo da IA Heurística por tipo de operação:

| Componente | Operações/partida | Participação |
|---|---|---|
| **Busca de caminho** | **1086** | **84%** |
| Linha de visão | 109 | 8% |
| Ações avaliadas | 103 | 8% |

**A avaliação estratégica — o que diferencia a heurística — é só 16% do custo.**
O grosso é a busca de caminho, executada em *todo* turno, inclusive nos muitos
turnos sem contato visual, quando o agente apenas se desloca.

*Fala*: este é o achado mais importante da etapa. Ele muda o desenho do modelo
proposto e será retomado na próxima banca.

---

## Slide 10 — RESULTADO 4: o aprendizado funciona

Registro auditável da calibração automática dos pesos ao longo de mil partidas:

- Janela 1 (pesos iniciais): média de **−0,44** pontos
- Janela 3: configuração adotada com **+0,04**
- Janela 40: fecha adotando **+0,20** — pontuação positiva sustentada

Melhor configuração encontrada: menos peso em vida, **mais aversão a risco**.

Esses pesos alimentam o Art3miz 0.1 na etapa seguinte — a solução é derivada
dos dados, não arbitrada.

---

## Slide 11 — Síntese do Passo 02

| Compromisso da Banca 3 | Estado |
|---|---|
| Executar benchmark com as mil sementes | ✔ Quatro lotes, 4.000 partidas |
| Coletar métricas estratégicas e computacionais | ✔ 12.000 registros documentados |
| Análise estatística (média e desvio padrão) | ✔ Em todas as métricas |

**Quatro achados**: o gradiente de inteligência existe e custa caro; a aleatória
é o pior negócio possível; 84% do custo está na busca de caminho; e o aprendizado
automático melhora o desempenho de forma mensurável.

---

## Slide 12 — Próximo passo

**Passo 03 — Finalização**: construir o modelo híbrido a partir do que os dados
mostraram, calibrá-lo, e avaliá-lo contra todos os modelos de referência.

A pergunta que a próxima etapa responde: **é possível manter a qualidade
estratégica pagando menos?**

---

## Slide 13 — Perguntas

---

## Antecipação de perguntas da banca

**"Por que a heurística não venceu mais folgadamente?"**
Sob percepção limitada, a avaliação posicional só agrega valor durante o contato
visual. Em boa parte dos turnos o agente está apenas procurando o inimigo, e aí
os modelos se equivalem. Foi medido: sob onisciência a vantagem da heurística era
grande; com visão limitada, comprime.

**"O custo da aleatória não deveria ser o menor?"**
Intuitivamente sim, mas ela enumera todas as ações válidas antes de sortear — e
não reaproveita nada. Modelos com regras podem descartar opções cedo.

**"Os pesos aprendidos não são sobreajuste?"**
O aprendizado roda no banco de calibração, disjunto do banco de avaliação. E as
instâncias são descartadas ao fim de cada lote: nada atravessa de um experimento
para outro.

**"Por que penalizar empate com −1?"**
Porque um modelo que apenas sobrevive até o limite de turnos não demonstra
eficácia estratégica. Tratar empate como neutro faria a IA Aleatória — que empata
100% das vezes — parecer mediana em vez de péssima.
