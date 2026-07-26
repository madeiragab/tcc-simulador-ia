# Bancos de Seeds

Bancos congelados de *seeds* usados nos experimentos (ver `docs/metodologia.md`).

- **seeds_tuning.txt** — 200 seeds exclusivas para calibração de pesos e λ (*tuning*). Nunca usadas no benchmark.
- **seeds_benchmark.txt** — 1000 seeds reservadas para o benchmark oficial, idênticas para todos os modelos.

## Geração (auditável e reproduzível)

Gerados uma única vez com o LCG de Park–Miller (`x = x * 48271 mod 2147483647`),
meta-seed inicial `20260719`. Os primeiros 200 valores formam o banco de tuning
e os 1000 seguintes o de benchmark — conjuntos disjuntos por construção
(o gerador é uma permutação sem repetição no período).

Estes arquivos são **imutáveis**: regenerá-los ou editá-los invalida a
comparabilidade de qualquer resultado já coletado.
