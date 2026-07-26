> 🇧🇷 **Português** · 🇬🇧 [English](en/map_generation.md)

# Geração Procedural de Mapas (Seeds)

## 1. Objetivo

Definir como os mapas das simulações são gerados a partir de *seeds*, garantindo:

- **Reprodutibilidade**: a mesma seed sempre produz exatamente o mesmo mapa e os mesmos spawns. Isso permite que todos os modelos de IA enfrentem cenários matematicamente idênticos (requisito da metodologia).
- **Variabilidade controlada**: seeds diferentes produzem mapas diferentes, evitando que os modelos sejam avaliados em um único cenário fixo.
- **Neutralidade de terreno**: nenhum jogador nasce em posição estruturalmente vantajosa.

---

## 2. Entrada e Determinismo

- Entrada única: um número inteiro (**seed**).
- Toda a aleatoriedade da geração usa um gerador de números pseudoaleatórios inicializado com essa seed.
- Nenhuma outra fonte de aleatoriedade participa da geração — mesma seed, mesmo mapa, sempre.

---

## 3. Configuração dos Jogadores

- **3 agentes independentes** (todos contra todos): verde, vermelho e azul.
- Cada agente é uma "equipe" de um único integrante.
- Vitória: último agente vivo. Empate: limite de 100 turnos atingido com 2 ou mais vivos.

---

## 4. Divisão em Setores

O grid 40x40 é dividido em **4 setores** (quadrantes) de 20x20:

```text
+----------+----------+
| Setor 0  | Setor 1  |
| (NO)     | (NE)     |
+----------+----------+
| Setor 2  | Setor 3  |
| (SO)     | (SE)     |
+----------+----------+
```

### Sorteio de Spawn

1. Os 4 setores são embaralhados (com o RNG da seed).
2. Os 3 primeiros setores sorteados recebem um jogador cada — **nunca dois jogadores no mesmo setor**.
3. Dentro do setor, a posição exata de spawn é sorteada na região central do quadrante (afastada das bordas), evitando spawn encostado em parede de canto.

**Justificativa**: com o setor de nascimento sorteado por seed, nenhuma posição do mapa favorece sistematicamente um jogador ao longo das 1000 simulações — a vantagem ou desvantagem local de terreno se dilui estatisticamente, sem precisar de mapas espelhados.

---

## 5. Geração de Obstáculos

Com os spawns definidos, o gerador distribui os obstáculos:

| Elemento | Quantidade (sorteada) | Formato |
|---|---|---|
| Paredes | 10 a 14 blocos | segmentos retos de 3 a 7 células (horizontais ou verticais) |
| Cobertura leve | 8 a 12 blocos | 1 a 2 células |
| Cobertura pesada | 4 a 6 blocos | 1 a 2 células |

Restrições:

- **Zona de segurança de spawn**: nenhuma célula a distância ≤ 2 de um spawn recebe obstáculo (o jogador nunca nasce preso ou colado em parede).
- Obstáculos podem se sobrepor entre si (o último sorteado prevalece na célula).

---

## 6. Validação de Conectividade

Após gerar os obstáculos:

1. Executa-se uma busca em largura (BFS) a partir do spawn do primeiro jogador, considerando paredes como bloqueio.
2. O mapa é **válido** se os outros dois spawns são alcançáveis.
3. Se inválido, o mapa é regenerado (o RNG continua a partir do estado atual, mantendo o determinismo da seed).
4. Após um limite de tentativas, gera-se um mapa sem obstáculos como salvaguarda (caso extremo, estatisticamente improvável).

Isso garante que toda simulação pode terminar por eliminação — nunca por jogadores isolados em regiões separadas do mapa.

---

## 7. Regras de Visão e Tiro

- **Paredes bloqueiam visão e tiro**: um agente não vê nem ataca através de paredes (linha de visão traçada célula a célula entre atacante e alvo).
- **Cobertura não bloqueia visão nem tiro**: apenas reduz o dano recebido, e somente quando a célula de cobertura está entre o defensor e o atacante (cobertura direcional).

---

## 8. Pseudocódigo

```text
função gerar_mapa(seed):
    rng ← RNG(seed)
    para tentativa em 1..25:
        limpar_grid()
        setores ← embaralhar([0,1,2,3], rng)
        spawns ← sortear posição central em setores[0..2] (rng)
        colocar_paredes(rng, evitando zona de segurança dos spawns)
        colocar_coberturas(rng, evitando zona de segurança dos spawns)
        se conectados(spawns):        # BFS
            retornar spawns
    limpar_grid()                     # salvaguarda: mapa aberto
    retornar sortear_spawns(rng)
```
