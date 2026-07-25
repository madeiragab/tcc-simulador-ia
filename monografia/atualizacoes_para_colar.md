# Atualizações para colar no Google Docs

O documento no Google Docs é a fonte da verdade (tem as fórmulas renderizadas e o brasão). Este arquivo traz os textos novos para você colar nas seções indicadas, sem precisar regenerar o .docx e perder as imagens.

---

## ▸ SUBSTITUIR o parágrafo do modelo híbrido na Seção 4.6

*(o parágrafo que hoje começa em "O modelo híbrido proposto — contribuição central da pesquisa — estende a avaliação heurística...")*

O modelo híbrido proposto — contribuição central da pesquisa — parte da formulação de compromisso entre valor estratégico e custo computacional:

$$\text{ScoreAção} = \text{ValorEstratégico} - \lambda \cdot \text{CustoComputacional}$$

A implementação inicial aplicou essa expressão no nível das ações: cada posição candidata teria descontado o custo, em operações contadas, de avaliá-la. Os experimentos de calibração mostraram que essa aplicação é inócua neste domínio, por duas razões mensuradas. Primeiro, a decomposição do custo revelou que o loop de avaliação posicional responde por apenas 16% do consumo total do agente heurístico, enquanto 84% concentra-se na busca de caminho executada a cada turno — de modo que nenhum valor de λ poderia economizar mais que a fração minoritária atingida. Segundo, e mais fundamental: como avaliar qualquer posição custa praticamente o mesmo, o termo subtraído torna-se uma constante idêntica para todas as candidatas e, portanto, não altera qual delas apresenta o maior score. Formalmente, sendo o custo aproximadamente uniforme e igual a k, tem-se que o argumento máximo de (Valor − λk) coincide com o argumento máximo de Valor. Esse resultado negativo delimita a condição de aplicabilidade da formulação: a penalização por ação só discrimina quando as ações diferem entre si em custo.

A partir dessa constatação, o modelo foi reformulado aplicando o mesmo compromisso um nível acima, na decisão sobre o próprio procedimento de decisão. O agente delibera — isto é, executa a avaliação posicional completa — se, e somente se, o valor estratégico em jogo compensar o custo previsto da análise:

$$\text{ValorEmJogo} - \lambda \cdot \text{CustoEstimado} > 0$$

O ValorEmJogo é estimado por n × (Proximidade + Vulnerabilidade), onde n é o número de inimigos visíveis, Proximidade é o inverso da distância ao mais próximo e Vulnerabilidade é a fração de vida já perdida — grandezas que crescem justamente nas situações em que decidir bem tem maior consequência. O CustoEstimado é o produto do número de posições candidatas pelo custo unitário de avaliação. Quando não há inimigos à vista, o valor em jogo é nulo e a análise nunca se justifica.

Essa formulação confere ao parâmetro λ o comportamento de espectro previsto na fundamentação teórica: com λ igual a zero o agente delibera sempre, reproduzindo a IA Heurística pura; com λ suficientemente alto nunca delibera, aproximando-se da IA Reativa; e valores intermediários percorrem o compromisso entre ambos.

Quando a deliberação não se justifica, o agente opera em regime econômico: desloca-se por passo guloso na direção do objetivo, verificando apenas as células do próprio caminho — três a seis operações — em vez de expandir toda a vizinhança alcançável, o que exige cerca de vinte e cinco. Caso o caminho guloso seja bloqueado por um obstáculo que a busca completa contornaria, o agente recorre à busca, reservando o gasto elevado às situações em que a alternativa barata falha. A economia é efetivamente medida, e não presumida: cada verificação do passo guloso é contabilizada pelo mesmo instrumento que mede as demais operações, e o caminho traçado é validado em tempo constante por passo, sem repetição da busca.

---

## ▸ ACRESCENTAR ao final da Seção 4.8 (Protocolo experimental)

A calibração do modelo híbrido foi conduzida exclusivamente sobre o banco de 200 sementes reservado a esse fim, com varredura do parâmetro λ nos valores 0; 0,002; 0,005; 0,01 e 0,02. O valor adotado, λ = 0,005, corresponde ao joelho da curva de compromisso: preserva a eficácia máxima observada no modelo enquanto reduz o consumo em quinze por cento relativamente à deliberação irrestrita. Um mecanismo adicional de poda — limitar o número de candidatas avaliadas por turno — foi testado e descartado por reduzir a eficácia sem economia correspondente; permanece implementado, porém desativado por padrão, e o resultado está registrado.

---

## ▸ Seção 5 (Resultados) — aguardando benchmark final

O texto desta seção será entregue quando as três execuções de benchmark (1000 partidas cada) terminarem.
