# Banca 4 — Passo 01: Continuidade do Desenvolvimento

**Roteiro de apresentação** · Simulador Tático para Avaliação de IA
Gabriel Madeira · Orientador: Ricardo Martins · Coorientador: Diego Penha

> **Identidade visual**: manter o template da Banca 3 (tema tabletop/fantasia,
> tons bege e verde-oliva, silhuetas). Continuidade visual ajuda a banca a
> perceber o trabalho como um percurso, não como peças soltas.

> **Mensagem central**: o Passo 01 prometido na Banca 3 está concluído — modelos
> de decisão, logger, métricas e pipeline automatizado. E o instrumento foi
> *provado* neutro antes de qualquer comparação.

---

## Slide 1 — Capa

Mesmo título da Banca 3:
**Avaliação Experimental de um Modelo Híbrido para Decisão Estratégica em
Simulações de Combate Baseadas em Turnos**

Subtítulo desta etapa: *Passo 01 — Framework Experimental Concluído*

---

## Slide 2 — Onde paramos

Na Banca 3, o protótipo tinha grid, obstáculos e dois agentes com movimentação
inicial. E foram declarados três passos:

| Passo | Compromisso | Status |
|---|---|---|
| **01** | Modelos de decisão, Logger, pipeline de benchmark | **Esta apresentação** |
| 02 | Executar benchmark, coletar métricas, análise estatística | Próxima |
| 03 | Consolidar resultados, validar modelo híbrido, monografia | Final |

*Fala*: abrir retomando o compromisso. Mostra que a apresentação responde ao que
foi prometido, e não a uma agenda nova.

---

## Slide 3 — Evolução do desenho experimental

Duas decisões mudaram desde a Banca 3, ambas para **fortalecer o controle de
viés**:

| Banca 3 | Agora | Por quê |
|---|---|---|
| Combates 3 × 3 em times | **3 agentes independentes** (todos contra todos) | Elimina a variável "coordenação de equipe", que confundiria a medição do modelo individual |
| Mapa simétrico | **4 setores, nascimento sorteado** | Simetria perfeita é frágil: basta um obstáculo assimétrico para enviesar. O sorteio dilui a vantagem de terreno estatisticamente |
| 500 partidas iniciando por cada IA | **Rotação: partida *i* inicia pelo jogador *i* mod 3** | Com três agentes, a divisão em terços exatos é mais limpa que metades |

*Fala*: apresentar como amadurecimento metodológico, não como correção de erro.
Cada mudança tem uma justificativa de controle experimental.

---

## Slide 4 — O ambiente completo

- Grid **40x40**, três agentes, limite de **100 turnos**
- **Movimento**: até 3 células, caminho validado por busca em largura
- **Combate determinístico**: dano 30, sem qualquer sorteio
- **Cobertura direcional**: protege apenas na direção do atacante
- **Tiro em linha reta**: horizontal, vertical ou diagonal perfeita

*Fala*: destacar a interdependência das duas últimas regras — sem o tiro reto,
ângulos arbitrários contornariam qualquer cobertura, e a defesa perderia sentido.
Foi uma correção identificada durante o desenvolvimento.

---

## Slide 5 — Percepção limitada

Agentes **não são oniscientes**. Quatro camadas:

1. **Cone de visão de 120°**, alcance 8, bloqueado por paredes
2. **Memória tática**: guarda a última posição onde viu cada inimigo
3. **Revelação por dano**: levar tiro revela o atirador, mesmo fora do cone
4. **Sensor de proximidade**: direção aproximada e faixa de distância do inimigo
   mais próximo — nunca a posição exata (inspirado no detector de movimento de
   *Alien Isolation*)

*Fala*: a observabilidade parcial é decisiva. Agentes oniscientes convergem para
comportamentos degenerados que não transferem para problemas reais. Sob visão
completa, a diferença entre modelos praticamente desaparece — foi medido.

---

## Slide 6 — Geração procedural por sementes

`semente → gerador determinístico → setores → nascimentos → obstáculos → validação`

- Mapa dividido em **4 setores**; cada agente nasce em um setor distinto sorteado
- Obstáculos com zona de segurança ao redor dos nascimentos
- **Validação por busca em largura**: mapa que isole um agente é descartado e
  regenerado

**A mesma semente reproduz sempre a mesma partida.**

Bancos congelados e disjuntos: **200 sementes para calibração**, **1000 para
avaliação** — a separação previne sobreajuste.

---

## Slide 7 — Logger e sistema de métricas (compromisso do Passo 01)

O *Operation Count* prometido na Banca 3 está implementado. Três contadores:

| Contador | O que conta |
|---|---|
| Linha de visão | Verificações de visibilidade |
| Nós de busca | Células expandidas no cálculo de caminho |
| Ações avaliadas | Posições pontuadas pela IA |

Medido **apenas durante a decisão** do agente da vez: mede-se o custo de decidir,
não o de executar. **Independente de hardware** — o mesmo experimento produz os
mesmos custos em qualquer máquina.

---

## Slide 8 — Pipeline de benchmark automatizado

Cada execução gera uma pasta **autodocumentada e imutável**:

- `manifest.txt` — condições completas (sementes, modelos, constantes, duração)
- `partidas.csv` — uma linha por jogador por partida, métricas brutas e derivadas
- `resumo.csv` — agregados e escore
- `aprendizado.csv` — evolução dos parâmetros ajustáveis
- `turnos.csv` — registro turno a turno (opcional)

**Mil partidas em poucos minutos**, sem renderização. Trocar o modelo de um
jogador é um argumento de linha de comando.

---

## Slide 9 — Controles de viés implementados

| Viés possível | Controle |
|---|---|
| Vantagem de terreno | Setor de nascimento sorteado pela semente |
| Vantagem de jogar primeiro | Rotação determinística de iniciativa |
| Variância de sorte | Combate determinístico, sem RNG em partida |
| Sobreajuste | Bancos de calibração e avaliação disjuntos |

---

## Slide 10 — RESULTADO: o instrumento é neutro

**O experimento zero.** Se três agentes usam a mesma IA, um ambiente justo deve
produzir taxas de vitória indistinguíveis.

**Mil partidas, três IAs Reativas idênticas:**

| Agente | Taxa de vitória |
|---|---|
| Verde | 0,306 |
| Vermelho | 0,328 |
| Azul | 0,301 |

Com N = 1000, a flutuação esperada por puro acaso é de **±1,5 ponto percentual**.
A maior diferença observada está dentro dessa faixa.

**Conclusão**: qualquer diferença observada daqui em diante é atribuível ao
modelo de IA, não ao cenário. Este resultado autoriza todas as comparações
seguintes.

*Fala*: este é o slide mais importante da apresentação. Vale gastar tempo nele.

---

## Slide 11 — Passo 01 concluído

| Compromisso da Banca 3 | Estado |
|---|---|
| Concluir implementação dos modelos de decisão | ✔ Aleatória, Reativa e Heurística implementadas |
| Integrar Logger e sistema de métricas | ✔ Operation Count e exportação CSV |
| Automatizar pipeline de benchmark | ✔ Execução headless em lote autodocumentada |

**Extra**: validação empírica da neutralidade do ambiente, que não estava
prevista e se mostrou necessária.

---

## Slide 12 — Próximo passo

**Passo 02 — Validação Experimental**: executar o benchmark sobre o banco de mil
sementes, coletar as métricas estratégicas e computacionais de todos os modelos,
e realizar a análise estatística.

A pergunta que orienta a próxima etapa: **quanto custa, em processamento, cada
nível de sofisticação estratégica?**

---

## Slide 13 — Perguntas

---

## Antecipação de perguntas da banca

**"Por que abandonou o 3×3 em times?"**
Times introduzem coordenação como variável. Como o objeto de estudo é o modelo de
decisão *individual*, isolá-lo dá medição mais limpa. Três agentes independentes
também produzem três medições por partida em vez de duas.

**"Por que o mapa deixou de ser simétrico?"**
Simetria perfeita é frágil — um único obstáculo assimétrico a quebra. O sorteio
de setores dilui a vantagem estatisticamente ao longo de mil partidas, e o slide
10 mede que funcionou.

**"O sensor de proximidade não facilita demais?"**
É mecânica do ambiente, disponível igualmente a todos os modelos, e cada consulta
é contabilizada no custo. Sem ele, os agentes vagavam ao acaso e as partidas
terminavam em empate por esgotamento.

**"Por que 40x40 e 100 turnos?"**
Ambos validados empiricamente: com alcance 8 e movimento 3, produzem partidas
longas o bastante para manobra e curtas o bastante para caber no limite. As
durações médias observadas ficam bem abaixo do teto.

**"Como sei que os resultados são reproduzíveis?"**
O mesmo comando produz os mesmos resultados byte a byte. Cada execução grava o
manifesto com todas as condições. Repositório público.
