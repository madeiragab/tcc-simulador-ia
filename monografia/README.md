# Monografia

`Monografia_TCC_Gabriel_Madeira.docx` — monografia completa em formato ABNT, reescrita do zero em 21/07/2026 incorporando as respostas a todos os apontamentos da banca de qualificação (mapa completo no Apêndice B do documento).

## Antes de entregar

1. **Preencher os campos destacados em amarelo**: nome da instituição, nome do curso, cidade e titulação (aparecem na capa e na folha de rosto).
2. **Atualizar o sumário**: no Word/Google Docs, clique com o botão direito sobre o sumário → "Atualizar campo" (ele é um campo automático; os números de página são calculados pelo editor).
3. Conferir se a instituição exige elementos adicionais (folha de aprovação, dedicatória, epígrafe, listas de figuras/tabelas) e inserir conforme o modelo institucional.

## Conteúdo

- Capítulos 1–2: introdução (problema, hipótese, objetivos, justificativa) e fundamentação teórica
- Capítulo 3: o simulador (ambiente, percepção, regras de combate, custo computacional abstrato, aprendizado, infraestrutura)
- Capítulo 4: os quatro modelos de IA (com tabela comparativa)
- Capítulo 5: métricas (individuais, pontuação de partida, StrategicScore — com limitação registrada)
- Capítulo 6: protocolo experimental (bancos de seeds, neutralização de vieses, campanha)
- Capítulo 7: resultados parciais (neutralidade validada, efeito da percepção, calibração da heurística, aprendizado)
- Capítulos 8–9: cronograma e considerações parciais
- Apêndice A: estrutura dos dados coletados
- Apêndice B: correspondência item a item com os apontamentos da banca

## Regeneração

O documento é gerado programaticamente a partir de `simulator/tools/monografia_gen.gd` (o próprio Godot monta o OOXML):

```bash
godot --headless --path simulator --script res://tools/monografia_gen.gd
```

Edite o conteúdo no script e regenere — nunca edite o .docx e o script em paralelo, escolha um fluxo.
