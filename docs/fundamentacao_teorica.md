> 🇧🇷 **Português** · 🇬🇧 [English](en/theoretical_foundation.md)

# Fundamentação Teórica — Racionalidade Limitada e Metarraciocínio

Este documento situa o modelo proposto na literatura que o antecede. A formulação desenvolvida neste trabalho — decidir se vale a pena deliberar antes de deliberar — corresponde ao problema clássico do **metarraciocínio racional**, formalizado por Russell e Wefald (1991). O reconhecimento dessa filiação é importante em dois sentidos: fornece ancoragem teórica ao modelo e, como se verá, **explica o resultado negativo obtido na formulação inicial**.

## 1. Racionalidade limitada

O ponto de partida é a crítica de Simon (1955, 1957) à racionalidade perfeita. Agentes reais decidem sob restrições de tempo, informação e capacidade de processamento; a escolha ótima é frequentemente inacessível, e o agente racional é aquele que decide bem *dado o que pode computar*. Simon propõe o *satisficing* — buscar uma solução suficientemente boa em vez da ótima — como resposta a essas restrições.

Russell (1997) formaliza a ideia como **otimalidade limitada** (*bounded optimality*): o agente ótimo não é o que escolhe a melhor ação, e sim aquele cujo *programa* produz o melhor comportamento possível dentro dos recursos computacionais disponíveis. A qualidade passa a ser propriedade da arquitetura de decisão, não apenas da decisão isolada.

Essa é exatamente a premissa do presente trabalho: um agente que gasta processamento excessivo para decidir pode ser inviável na prática, ainda que suas decisões isoladas sejam boas.

## 2. Metarraciocínio e o valor da computação

Russell e Wefald (1991) formalizam o problema de **decidir se deliberar**. Tratam computações como ações — com custos e benefícios próprios — e definem o **valor da computação** (*value of computation*, VOC): o ganho esperado de utilidade que uma computação produz, descontado o custo de executá-la (tempo, energia, oportunidade).

O ponto central da formulação, e o mais relevante aqui, é a origem do benefício:

> Uma computação só tem valor na medida em que **altera a ação externa** que o agente executaria.

Uma deliberação que produz muita informação, mas termina recomendando a mesma ação que seria escolhida sem ela, tem valor **nulo** — por mais custosa que tenha sido. A regra de parada decorre disso: delibera-se enquanto o valor esperado da próxima computação superar seu custo; quando deixa de superar, age-se.

Zilberstein (1996) estende o tratamento aos **algoritmos anytime**, que produzem soluções de qualidade crescente com o tempo e podem ser interrompidos a qualquer momento, permitindo trocar deliberação por qualidade de forma explícita e controlável. Horvitz (1988) trata do raciocínio sob restrições de recursos variáveis e incertas, e Gershman, Horvitz e Tenenbaum (2015) consolidam a agenda sob o rótulo de **racionalidade computacional**, articulando a formulação em ciência cognitiva e inteligência artificial.

## 3. Onde o modelo proposto se encaixa

O Art3miz 0.1 implementa uma aproximação míope da regra de parada do metarraciocínio. Antes de executar a avaliação posicional completa, o agente estima o valor em jogo na situação e o compara ao custo previsto da análise:

**ValorEmJogo − λ × CustoEstimado > 0 → delibera**

A correspondência com a formulação clássica é direta:

| Metarraciocínio (Russell & Wefald, 1991) | Art3miz 0.1 |
|---|---|
| Valor da computação | ValorEmJogo — proxy do quanto a análise pode alterar a ação escolhida |
| Custo da computação | CustoEstimado, em operações contadas |
| Regra de parada (VOC ≤ 0 → agir) | Regime econômico quando a desigualdade não se satisfaz |
| Aproximação míope (avalia um passo) | Estimativa por situação, sem projeção de múltiplos turnos |

O parâmetro λ desempenha o papel da **taxa de conversão entre utilidade de domínio e custo computacional** — a grandeza que, na formulação original, torna comparáveis o benefício da deliberação e o preço de obtê-la.

Duas simplificações deste trabalho em relação ao arcabouço original devem ser explicitadas: (i) o ValorEmJogo é uma heurística de situação, não uma esperança calculada sobre a distribuição de resultados possíveis; e (ii) a decisão é binária (deliberar ou não), enquanto a formulação geral admite escolher *qual* computação executar dentre várias. Ambas são aproximações reconhecidas na literatura como necessárias para viabilizar aplicação em tempo real.

## 4. A teoria explica o resultado negativo

O achado mais relevante deste trabalho — que a formulação inicial, aplicada à escolha entre ações, é inócua — **não é uma anomalia: é uma predição da teoria**.

A formulação inicial descontava, de cada ação candidata, o custo de avaliá-la:

Score(A) = Valor(A) − λ × Custo(A)

Mediu-se que, neste domínio, avaliar qualquer posição custa aproximadamente o mesmo. Sendo Custo(A) ≈ k para toda ação candidata, o termo subtraído é constante e não altera qual candidata apresenta o maior escore:

argmax[ Valor(A) − λk ] = argmax[ Valor(A) ]

O resultado é exatamente o que o princípio de Russell e Wefald antecipa: **uma computação cujo resultado não altera a ação escolhida tem valor nulo**. Descontar um custo uniforme de todas as alternativas não muda a ação selecionada e, portanto, não pode produzir efeito algum — nem sobre a qualidade da decisão, nem sobre o processamento consumido, já que o custo foi pago antes do desconto.

A confirmação empírica é inequívoca: as execuções com λ = 0 e λ = 0,005 produziram resultados idênticos, e a varredura completa de λ não alterou o custo medido (ver `resultados_hibrido.md` §1).

A reformulação corrige precisamente o nível de aplicação: o compromisso deixa de operar *entre ações*, onde os custos são uniformes e o termo é inerte, e passa a operar *entre procedimentos de decisão*, onde os custos diferem por ordens de grandeza — deliberar custa cerca de vinte e cinco vezes mais que o passo econômico.

## 5. Contribuição em relação à literatura

O metarraciocínio é um arcabouço consolidado, e este trabalho não propõe extensão teórica a ele. A contribuição é de outra natureza:

1. **Aplicação e avaliação empírica** do princípio em um domínio tático por turnos com percepção limitada, com protocolo controlado e 7.000 partidas.
2. **Demonstração empírica de uma condição de inaplicabilidade** da formulação por ação: quando as alternativas têm custo de avaliação uniforme, o termo de penalização é inerte. Trata-se de um corolário do princípio clássico, aqui medido e quantificado.
3. **Um instrumento de medição reprodutível** que mede custo por contagem de operações, independente de hardware, com neutralidade estatisticamente verificada — reutilizável por outras investigações.

## Referências

GERSHMAN, S. J.; HORVITZ, E. J.; TENENBAUM, J. B. **Computational rationality: A converging paradigm for intelligence in brains, minds, and machines**. Science, v. 349, n. 6245, p. 273-278, 2015.

HORVITZ, E. J. **Reasoning under varying and uncertain resource constraints**. In: NATIONAL CONFERENCE ON ARTIFICIAL INTELLIGENCE (AAAI), 7., 1988. Proceedings. Saint Paul: AAAI Press, 1988. p. 111-116.

RUSSELL, S. **Rationality and intelligence**. Artificial Intelligence, v. 94, n. 1-2, p. 57-77, 1997.

RUSSELL, S.; WEFALD, E. **Principles of metareasoning**. Artificial Intelligence, v. 49, n. 1-3, p. 361-395, 1991.

SIMON, H. A. **A behavioral model of rational choice**. The Quarterly Journal of Economics, v. 69, n. 1, p. 99-118, 1955.

SIMON, H. A. **Models of man: social and rational**. New York: John Wiley and Sons, 1957.

ZILBERSTEIN, S. **Using anytime algorithms in intelligent systems**. AI Magazine, v. 17, n. 3, p. 73-83, 1996.
