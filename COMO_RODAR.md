> 🇧🇷 **Manual de execução** · [voltar ao README](README.md)

# Como rodar o simulador

Este manual leva do zero até a reprodução completa dos experimentos da
monografia: instalar o que é preciso, assistir uma partida, rodar os testes,
executar lotes de partidas, refazer cada tabela do trabalho e publicar o site de
demonstração na sua máquina.

Tudo o que está aqui foi executado e conferido com o Godot 4.7.1 no Windows 11.
Os comandos valem também para Linux e macOS; onde houver diferença, ela está
indicada.

## Sumário

1. [O que você precisa](#1-o-que-você-precisa)
2. [Baixar o projeto](#2-baixar-o-projeto)
3. [Instalar o Godot 4.7.1](#3-instalar-o-godot-471)
4. [Preparar o projeto (primeira execução)](#4-preparar-o-projeto-primeira-execução)
5. [Assistir uma partida](#5-assistir-uma-partida)
6. [Rodar os testes automáticos](#6-rodar-os-testes-automáticos)
7. [Rodar um lote de partidas](#7-rodar-um-lote-de-partidas)
8. [O que cada lote grava](#8-o-que-cada-lote-grava)
9. [Reproduzir os experimentos da monografia](#9-reproduzir-os-experimentos-da-monografia)
10. [Análise estatística e sensibilidade dos pesos](#10-análise-estatística-e-sensibilidade-dos-pesos)
11. [Site de demonstração na sua máquina](#11-site-de-demonstração-na-sua-máquina)
12. [Problemas comuns](#12-problemas-comuns)
13. [Mapa do repositório](#13-mapa-do-repositório)

---

## 1. O que você precisa

| Item | Versão | Para quê | Obrigatório? |
|---|---|---|---|
| **Godot Engine** | **4.7.1** (edição padrão, *não* a .NET) | Rodar o simulador, os lotes, os testes e as análises | Sim |
| **Git** | qualquer recente | Baixar o repositório | Não (dá para baixar o ZIP) |
| **Python** | 3.9 ou superior, só a biblioteca padrão | Gerar os dados do site de demonstração | Só para o site |
| Navegador | qualquer moderno | Ver o site de demonstração | Só para o site |

- **Sistema operacional:** Windows 10/11, Linux x86_64 ou macOS.
- **Espaço em disco:** o projeto ocupa cerca de 80 MB. Cada lote de 1.000
  partidas grava de 1 a 4 MB (o maior valor é com o registro turno a turno).
- **Placa de vídeo:** não é necessária para os lotes, que rodam sem janela
  (*headless*). Para assistir uma partida, basta suporte a OpenGL 3.3, que
  praticamente qualquer computador tem.
- **Nenhuma biblioteca extra** é necessária: o simulador e os testes
  estatísticos são escritos em GDScript puro.

> **A versão do Godot importa.** O projeto declara a versão 4.7 em
> `simulator/project.godot`. Abri-lo com outra versão faz o Godot reimportar os
> recursos e pode mudar o comportamento sem aviso. Use exatamente a **4.7.1**,
> a mesma da integração contínua do repositório.

---

## 2. Baixar o projeto

Com Git:

```bash
git clone https://github.com/madeiragab/tcc-simulador-ia.git
cd tcc-simulador-ia
```

Sem Git: na página do repositório, clique em **Code → Download ZIP**, extraia o
arquivo e abra um terminal dentro da pasta extraída.

> Todos os comandos deste manual são executados a partir da **raiz do
> repositório** (a pasta que contém `README.md` e `simulator/`).

---

## 3. Instalar o Godot 4.7.1

O Godot não tem instalador: é um executável único, que você baixa e usa.

1. Abra a página da versão:
   <https://github.com/godotengine/godot/releases/tag/4.7.1-stable>
2. Baixe o arquivo do seu sistema (a edição **padrão**, sem "mono" no nome):

   | Sistema | Arquivo |
   |---|---|
   | Windows | `Godot_v4.7.1-stable_win64.exe.zip` |
   | Linux | `Godot_v4.7.1-stable_linux.x86_64.zip` |
   | macOS | `Godot_v4.7.1-stable_macos.universal.zip` |

3. Extraia o arquivo numa pasta sua, por exemplo `C:\Godot` ou `~/godot`.

### Deixar o comando `godot` disponível no terminal

Os comandos deste manual escrevem só `godot`. Para que isso funcione, faça uma
das opções abaixo, conforme o sistema.

**Windows (PowerShell).** O ZIP traz dois executáveis. Use o que termina em
`_console.exe`, porque ele mostra a saída no terminal. Crie um apelido para a
sessão:

```powershell
Set-Alias godot "C:\Godot\Godot_v4.7.1-stable_win64_console.exe"
godot --version
```

Para não precisar repetir isso a cada terminal aberto, adicione a linha
`Set-Alias` ao seu perfil do PowerShell (`notepad $PROFILE`).

**Linux:**

```bash
chmod +x ~/godot/Godot_v4.7.1-stable_linux.x86_64
sudo ln -s ~/godot/Godot_v4.7.1-stable_linux.x86_64 /usr/local/bin/godot
godot --version
```

**macOS:** arraste `Godot.app` para a pasta Aplicativos e crie o apelido:

```bash
alias godot="/Applications/Godot.app/Contents/MacOS/Godot"
godot --version
```

Em todos os casos, `godot --version` deve responder `4.7.1.stable...`.

---

## 4. Preparar o projeto (primeira execução)

Na primeira vez, o Godot precisa importar os recursos do projeto e criar a
pasta interna `simulator/.godot/`. Rode uma única vez:

```bash
godot --headless --path simulator --import
```

O comando pode terminar com uma mensagem de erro sobre a ausência de tela: isso
é normal no modo *headless*, e a importação terá funcionado mesmo assim. Se você
abrir o projeto no editor (seção 5.1), a importação acontece sozinha e este
passo pode ser pulado.

---

## 5. Assistir uma partida

### 5.1 Pelo editor do Godot

1. Abra o Godot (o executável sem `_console`, no Windows).
2. Na tela inicial, clique em **Importar**, escolha o arquivo
   `simulator/project.godot` e confirme.
3. Com o projeto aberto, pressione **F5** (ou clique no botão ▶ no canto
   superior direito).

A partida roda animada: os três agentes aparecem nas cores verde, vermelho e
azul, o turno corrente é mostrado no canto superior esquerdo e o último evento
de combate, no canto inferior. Cada execução sorteia um mapa novo.

### 5.2 Pela linha de comando

Partida animada com um mapa específico (a semente garante que o mapa e a
partida se repitam exatamente):

```bash
godot --path simulator -- 4242
```

Mesma partida, sem animação, só com o resultado no terminal:

```bash
godot --headless --path simulator -- 4242 fast
```

Saída esperada (a semente 4242 sempre produz este resultado):

```text
Resultado: verde em 20 turnos
Custo computacional: verde=464  vermelho=365  azul=150
```

> **O `--` é obrigatório.** Tudo o que vem antes dele é argumento do Godot;
> tudo o que vem depois é argumento do simulador.

> No modo visual, os três jogadores usam a IA reativa. Para escolher os
> modelos de cada jogador, use o modo de lote (seção 7).

---

## 6. Rodar os testes automáticos

O repositório tem duas baterias de testes de regressão, as mesmas que a
integração contínua executa a cada alteração:

```bash
# funções estatísticas (qui-quadrado, binomial, Holm, Wilson, t pareado...)
godot --headless --path simulator --script res://tests/test_stats.gd

# ambiente (mapa, linha de visão, cobertura direcional, alinhamento de tiro)
godot --headless --path simulator --script res://tests/test_ambiente.gd
```

Cada bateria termina com uma linha como:

```text
75 verificações, todas passaram
```

Se alguma verificação falhar, ela aparece marcada como `FALHA`, com o valor
obtido e o esperado, e a última linha informa quantas falharam.

---

## 7. Rodar um lote de partidas

O modo de lote roda muitas partidas seguidas, sem janela, e documenta tudo em
disco. É o modo usado em todos os experimentos.

```bash
godot --headless --path simulator -- batch <N> [banco] [opções] [escalação]
```

Exemplo, com 10 partidas do confronto direto oficial:

```bash
godot --headless --path simulator -- batch 10 benchmark verde=art3miz vermelho=heuristica azul=reativa
```

Ao terminar, o simulador mostra um resumo por jogador e o caminho da pasta
criada:

```text
Lote: 10 partidas do banco 'benchmark' -> .../data/runs/2026-11-23_04-14-42_benchmark_10
Lote concluído em 13.4s — documentação completa em .../data/runs/...
```

### Argumentos

| Argumento | Valores | Padrão | O que faz |
|---|---|---|---|
| `N` | número inteiro | 1000 | Quantas partidas rodar (as N primeiras sementes do banco) |
| `banco` | `benchmark` ou `tuning` | `benchmark` | Banco de sementes: 1.000 de avaliação ou 200 de calibração (`experiments/`) |
| `turnos` | — | desligado | Grava também o registro turno a turno (`turnos.csv`) |
| `lambda=` | número, ex.: `lambda=0.005` | `0.005` | Parâmetro de troca λ do Art3miz 0.1 (`0` = delibera sempre que há inimigo à vista) |
| `mapa=` | `25`, `40` ou `60` | `40` | Tamanho do mapa (generalização de escala) |
| `fix_alvo=1` | `0` ou `1` | `0` | Variante do Art3miz que escolhe o alvo a partir da posição de chegada |
| `gatilho=exposicao` | — | desligado | Variante do Art3miz que também delibera quando está exposto |
| `pesos=padrao` | — | desligado | Art3miz com os pesos-padrão da heurística, em vez dos herdados |
| `budget=` | número inteiro | `0` | Orçamento de avaliação por turno do Art3miz (`0` = sem limite; variante descartada) |

### Escalação dos jogadores

Cada jogador recebe um modelo com `cor=modelo`. As cores são `verde`, `vermelho`
e `azul`. Um jogador não escalado usa a IA reativa.

| Nome na linha de comando | Modelo |
|---|---|
| `aleatoria` | IA aleatória (piso de desempenho) |
| `reativa` | IA reativa (regras fixas) |
| `reativa_gulosa` | IA reativa com o deslocamento econômico do Art3miz (ablação) |
| `heuristica` | IA heurística (*Utility AI* com *hill-climbing*) |
| `art3miz` | Art3miz 0.1 (modelo proposto) |
| `mcts` | Monte Carlo Tree Search |

### Quanto tempo leva

Um lote de 1.000 partidas leva, num computador comum, de 10 a 20 minutos. Lotes
com o MCTS e com o registro turno a turno são os mais lentos. Comece com
`batch 10` para conferir se está tudo certo antes de rodar um lote completo.

### Determinismo

Mesma semente, mesmos modelos e mesmos parâmetros produzem **exatamente** a
mesma partida, em qualquer computador. Para conferir, rode o mesmo lote duas
vezes e compare os arquivos `partidas.csv` das duas pastas: eles são idênticos,
exceto pelo carimbo de data e hora no nome da pasta.

---

## 8. O que cada lote grava

Cada lote cria uma pasta nova em `data/runs/`, com o nome
`<data>_<hora>_<banco>_<N>`. Nada é sobrescrito.

| Arquivo | Conteúdo |
|---|---|
| `manifest.txt` | Condições completas: data, versão do motor, banco e sementes, rotação de iniciativa, modelo de cada jogador, constantes do jogo e parâmetros das IAs |
| `partidas.csv` | Uma linha por jogador por partida: semente, vencedor, pontos, turnos, dano causado e recebido, DamageRatio, CoverUsage e custo aberto por tipo de operação |
| `resumo.csv` | Agregados por jogador: WinRate, DamageRatio, CoverUsage, TurnsToVictory, custo médio e StrategicScore |
| `aprendizado.csv` | Evolução dos pesos dos modelos que aprendem, janela a janela |
| `turnos.csv` | Só com `turnos`: ação, posição, cobertura, inimigos com linha de visão, regime de decisão do Art3miz e resultado de cada disparo |

Os arquivos são CSV comuns e abrem em qualquer planilha ou em Python/R. As
definições de cada métrica estão em [`docs/metricas.md`](docs/metricas.md), e a
estrutura dos dados, em [`docs/coleta_dados.md`](docs/coleta_dados.md).

> A pasta `data/runs/` é ignorada pelo Git: seus lotes ficam só na sua máquina.
> As execuções oficiais do *benchmark* estão versionadas no repositório e não
> são afetadas.

---

## 9. Reproduzir os experimentos da monografia

Os comandos abaixo refazem cada tabela da monografia. Todos usam o banco de
avaliação (1.000 sementes), exceto a calibração de λ, que usa o banco de
calibração (200 sementes). Por causa do determinismo, os números saem iguais aos
publicados.

> Dica: para refazer só um teste rápido de cada experimento, troque
> `batch 1000` por `batch 20`.

### 9.1 Neutralidade e autoconfronto (Tabelas 2, 3 e 4)

Três instâncias do mesmo modelo por partida. Repita trocando o modelo:

```bash
godot --headless --path simulator -- batch 1000 benchmark turnos verde=art3miz vermelho=art3miz azul=art3miz
godot --headless --path simulator -- batch 1000 benchmark turnos verde=heuristica vermelho=heuristica azul=heuristica
godot --headless --path simulator -- batch 1000 benchmark turnos verde=reativa vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 1000 benchmark verde=aleatoria vermelho=aleatoria azul=aleatoria
godot --headless --path simulator -- batch 1000 benchmark verde=mcts vermelho=mcts azul=mcts
```

### 9.2 Confronto direto (Tabelas 5 e 6)

```bash
godot --headless --path simulator -- batch 1000 benchmark turnos verde=art3miz vermelho=heuristica azul=reativa
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=heuristica azul=heuristica
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=reativa azul=reativa
```

O primeiro comando, com `turnos`, também gera os dados da análise por tipo de
turno (Tabela 12).

### 9.3 Confronto com o MCTS (Tabelas 7 e 8)

```bash
godot --headless --path simulator -- batch 1000 benchmark verde=mcts vermelho=art3miz azul=heuristica
```

### 9.4 Generalização para outras escalas (Tabela 9)

```bash
godot --headless --path simulator -- batch 1000 benchmark mapa=25 verde=art3miz vermelho=heuristica azul=reativa
godot --headless --path simulator -- batch 1000 benchmark mapa=60 verde=art3miz vermelho=heuristica azul=reativa
```

### 9.5 Calibração de λ (Tabela 1 e Figura 3)

Uma execução por valor de λ, no banco de calibração, contra duas reativas:

```bash
godot --headless --path simulator -- batch 200 tuning lambda=0 verde=art3miz vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 200 tuning lambda=0.002 verde=art3miz vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 200 tuning lambda=0.005 verde=art3miz vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 200 tuning lambda=0.01 verde=art3miz vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 200 tuning lambda=0.02 verde=art3miz vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 200 tuning lambda=0.05 verde=art3miz vermelho=reativa azul=reativa
# referência: a heurística no mesmo banco
godot --headless --path simulator -- batch 200 tuning verde=heuristica vermelho=reativa azul=reativa
```

### 9.6 Ablação: de onde vem a economia (Tabela 10)

```bash
# Art3miz com λ = 0: delibera sempre que há inimigo à vista, mas mantém o deslocamento econômico
godot --headless --path simulator -- batch 1000 benchmark turnos lambda=0 verde=art3miz vermelho=art3miz azul=art3miz
godot --headless --path simulator -- batch 1000 benchmark turnos lambda=0 verde=art3miz vermelho=heuristica azul=reativa

# reativa com o deslocamento econômico
godot --headless --path simulator -- batch 1000 benchmark turnos verde=reativa_gulosa vermelho=reativa_gulosa azul=reativa_gulosa
godot --headless --path simulator -- batch 1000 benchmark turnos verde=art3miz vermelho=heuristica azul=reativa_gulosa
```

### 9.7 Variantes do Art3miz (Tabela 11)

```bash
# alvo escolhido a partir da posição de chegada
godot --headless --path simulator -- batch 1000 benchmark turnos fix_alvo=1 verde=art3miz vermelho=heuristica azul=reativa

# alvo corrigido + gatilho de exposição
godot --headless --path simulator -- batch 1000 benchmark turnos fix_alvo=1 gatilho=exposicao verde=art3miz vermelho=heuristica azul=reativa
godot --headless --path simulator -- batch 1000 benchmark turnos fix_alvo=1 gatilho=exposicao verde=art3miz vermelho=art3miz azul=art3miz
godot --headless --path simulator -- batch 1000 benchmark turnos fix_alvo=1 gatilho=exposicao verde=mcts vermelho=art3miz azul=heuristica

# pesos-padrão da heurística
godot --headless --path simulator -- batch 1000 benchmark turnos pesos=padrao verde=art3miz vermelho=heuristica azul=reativa
godot --headless --path simulator -- batch 1000 benchmark turnos pesos=padrao verde=art3miz vermelho=art3miz azul=art3miz
```

### 9.8 Conferir um resultado

Abra o `resumo.csv` da pasta criada. Por exemplo, o confronto direto oficial
(seção 9.2, primeiro comando) deve mostrar WinRate de **0,225** para o
Art3miz 0.1 (verde), **0,339** para a heurística (vermelho) e **0,330** para a
reativa (azul), os mesmos valores da Tabela 5 da monografia.

---

## 10. Análise estatística e sensibilidade dos pesos

As ferramentas abaixo leem as execuções oficiais versionadas em `data/runs/` e
regravam os relatórios em `docs/`:

```bash
# testes de significância (qui-quadrado, binomial com Holm, t pareado, IC de Wilson)
godot --headless --path simulator --script res://tools/analise_estatistica.gd
# -> docs/analise_estatistica.md

# robustez do ordenamento a ponderações alternativas do StrategicScore
godot --headless --path simulator --script res://tools/sensibilidade_pesos.gd
# -> docs/sensibilidade_pesos.md

# recalcula o resumo.csv de todas as execuções a partir do partidas.csv
godot --headless --path simulator --script res://tools/recalcular_resumos.gd
```

Os relatórios gerados saem com o mesmo conteúdo dos que estão no repositório,
o que é uma forma rápida de conferir a reprodutibilidade. A única diferença é a
linha de idioma no topo, que a ferramenta não escreve; para desfazer a
regravação, use `git checkout -- docs/`.

---

## 11. Site de demonstração na sua máquina

O site em <https://madeiragab.github.io/tcc-simulador-ia/> mostra partidas reais
rodando no navegador. Para gerá-lo localmente:

```bash
# 1. agrega os resultados dos lotes oficiais -> site/dados/resultados.json
python site/gerar_dados.py

# 2. grava partidas completas com o simulador -> site/dados/replays.json
godot --headless --path simulator --script res://tools/replay_dump.gd -- partidas=6

# 3. sobe um servidor local e abre o site
python -m http.server 8000 --directory site
```

Depois, abra <http://localhost:8000> no navegador. O servidor local é
necessário porque o navegador não carrega os dados do site se você abrir o
`index.html` direto pelo explorador de arquivos. Para encerrar, pressione
`Ctrl+C` no terminal.

No Linux e no macOS, use `python3` no lugar de `python`.

---

## 12. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `godot: command not found` / `godot não é reconhecido` | O apelido não foi criado | Refaça a seção 3 ou use o caminho completo do executável |
| No Windows, o comando roda mas não mostra nada | Foi usado o executável sem `_console` | Use `Godot_v4.7.1-stable_win64_console.exe` |
| Erro de script ao rodar uma ferramenta pela primeira vez | O projeto ainda não foi importado | Rode `godot --headless --path simulator --import` (seção 4) |
| O Godot pede para "converter" ou "atualizar" o projeto | Versão diferente da 4.7.1 | Feche sem salvar e use o Godot 4.7.1 |
| O lote ignora a escalação | Faltou o `--` antes de `batch` | O formato é `godot --headless --path simulator -- batch ...` |
| `Escalação inválida: ...` | Nome de cor ou de modelo errado | Cores: `verde`, `vermelho`, `azul`; modelos na tabela da seção 7 |
| Os números do lote não batem com a monografia | Banco, N, parâmetros ou escalação diferentes | Confira o `manifest.txt` da pasta contra o comando da seção 9 |
| O site abre vazio | `index.html` aberto direto do disco | Use o servidor local da seção 11 |
| Caminho com espaços no Windows | O PowerShell separa o argumento | Coloque o caminho entre aspas |

---

## 13. Mapa do repositório

```text
tcc-simulador-ia/
├── simulator/            projeto Godot (abra simulator/project.godot)
│   ├── core/             simulação, turnos, métricas, estatística, lote
│   ├── ai/               os seis modelos de decisão
│   ├── map/              grade e geração procedural de mapas
│   ├── agents/           agente e percepção
│   ├── tests/            testes de regressão (seção 6)
│   └── tools/            análise estatística, sensibilidade, replays (seções 10 e 11)
├── experiments/          bancos de sementes congelados (benchmark e tuning)
├── data/runs/            execuções oficiais e os lotes que você rodar
├── docs/                 documentação técnica e relatórios gerados
├── site/                 site de demonstração
├── monografia/           monografia em PDF
├── presentation/         slides das bancas
└── diagrams/             diagramas de arquitetura
```

A documentação técnica detalhada de cada parte está em [`docs/`](docs/README.md).
