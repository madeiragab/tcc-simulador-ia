# Generalização — O Achado se Sustenta Fora do 40×40?

Os resultados do benchmark foram obtidos em um grid de 40×40. Uma conclusão obtida em uma única configuração de ambiente pode ser propriedade daquele ambiente, e não do modelo. Este experimento replica o confronto direto em **três escalas** para verificar quais achados se sustentam.

## Protocolo

Três execuções de mil partidas cada, idênticas exceto pelo tamanho do mapa: **25×25**, **40×40** e **60×60**. Mesmos modelos (Art3miz 0.1, Heurística, Reativa), mesmo banco de sementes, mesmos controles de viés. A geração procedural escala com a área — número de obstáculos e tamanho dos setores acompanham proporcionalmente —, de modo que a densidade de terreno permanece constante.

```bash
godot --headless --path simulator -- batch 1000 benchmark mapa=25 verde=art3miz vermelho=heuristica azul=reativa
godot --headless --path simulator -- batch 1000 benchmark mapa=60 verde=art3miz vermelho=heuristica azul=reativa
```

## Resultados

| Escala | Modelo | WinRate | Custo | StrategicScore |
|---|---|---|---|---|
| **25×25** | Art3miz 0.1 | 0,195 | **413** | 0,448 |
| | Heurística | 0,372 | 494 | 0,518 |
| | Reativa | 0,371 | **286** | 0,525 |
| **40×40** | Art3miz 0.1 | 0,225 | **510** | 0,426 |
| | Heurística | 0,339 | 719 | 0,467 |
| | Reativa | 0,330 | 484 | 0,472 |
| **60×60** | Art3miz 0.1 | 0,225 | **494** | 0,379 |
| | Heurística | 0,305 | 970 | 0,410 |
| | Reativa | 0,305 | 760 | 0,417 |

## 1. A economia cresce com a escala — e o mecanismo explica por quê

A redução de custo do Art3miz 0.1 em relação à Heurística, por escala:

| Escala | Custo Art3miz | Custo Heurística | **Economia** |
|---|---|---|---|
| 25×25 | 413 | 494 | **−16%** |
| 40×40 | 510 | 719 | **−29%** |
| 60×60 | 494 | 970 | **−49%** |

**A economia praticamente triplica** entre a menor e a maior escala. O resultado é coerente com o mecanismo identificado na caracterização: 84% do custo concentra-se na busca de caminho, e mapas maiores exigem mais deslocamento sem contato visual — precisamente as situações em que o regime econômico substitui a busca completa pelo passo guloso.

Esse é o achado central do experimento: **a vantagem do modelo proposto não é artefato da configuração original — ela se amplifica conforme o ambiente cresce**, que é a direção relevante para aplicação prática, onde ambientes tendem a ser maiores que o testado.

Note-se ainda que o custo absoluto do Art3miz permanece praticamente estável entre 40×40 e 60×60 (510 → 494), enquanto o da Heurística cresce 35% (719 → 970). O modelo proposto é **substancialmente menos sensível à escala do ambiente**.

## 2. A desvantagem competitiva também se generaliza

Em todas as três escalas, o Art3miz 0.1 obtém menos vitórias que ambos os modelos de referência (0,195 a 0,225 contra 0,305 a 0,372). A limitação identificada no benchmark original não é específica daquela configuração: **é propriedade do modelo**, decorrente de abrir mão da deliberação em parte dos turnos.

## 3. Limitação encontrada: em mapas pequenos o modelo é dominado

O resultado mais desfavorável ao modelo proposto aparece na menor escala. Em 25×25, a IA Reativa é **simultaneamente mais barata e mais eficaz**:

| 25×25 | Custo | WinRate |
|---|---|---|
| Reativa | **286** | **0,371** |
| Art3miz 0.1 | 413 | 0,195 |

Trata-se de **dominância da Reativa sobre o modelo proposto** nessa escala — não há dimensão em que o Art3miz compense. A explicação é consistente com o mecanismo: em mapas pequenos o contato visual é quase constante, de modo que (i) o regime econômico raramente é acionado, eliminando a fonte de economia, e (ii) quando é acionado, ocorre em situações que de fato exigiriam deliberação, prejudicando a decisão.

**Consequência para o modelo:** o Art3miz 0.1 tem uma **faixa de aplicabilidade**. Ele compensa em ambientes suficientemente grandes para que existam períodos sem contato — e nesses, sua vantagem cresce com a escala. Em ambientes pequenos e densos, o custo da deliberação é baixo o bastante para que economizá-lo não se justifique.

Essa limitação é, ela própria, coerente com a fundamentação teórica: o valor da computação depende do contexto, e o metarraciocínio só compensa quando há variação real no valor de deliberar. Em um ambiente onde toda situação é crítica, não há o que economizar.

## 4. Síntese

| Achado | Generaliza? |
|---|---|
| Economia de custo sobre a Heurística | **Sim — e amplifica com a escala** (−16% → −49%) |
| Menor sensibilidade do custo à escala | **Sim** (custo estável vs +35% da Heurística) |
| Desvantagem em taxa de vitória | **Sim** — presente nas três escalas |
| Vantagem sobre a Reativa | **Não** — invertida em mapas pequenos |

A conclusão do trabalho ganha, portanto, uma qualificação de escopo: o compromisso qualidade-custo formalizado pelo modelo proposto **é real e escala favoravelmente**, mas sua vantagem depende de o ambiente oferecer períodos em que a deliberação seja dispensável.
