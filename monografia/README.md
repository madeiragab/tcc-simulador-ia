# Monografia (Projeto de TCC)

`Monografia_TCC_Gabriel_Madeira.docx` — Projeto de TCC no **modelo institucional do IFSULDEMINAS** (estrutura do exemplo `docs/monograma/Mod1_LucasMatthes_ProfaAline.pdf`), reescrito em 21/07/2026 respondendo todos os apontamentos da banca (mapa item a item no Apêndice B do documento).

Estrutura: capa institucional → Informações Gerais (com tabela de membros) → 1. Antecedentes/Problema/Justificativa → 2. Referencial Teórico → 3. Objetivos → 4. Metodologia e Estratégia de Ação → 5. Resultados e Impactos Esperados (com resultados parciais reais) → 6. Cronograma → 7. Orçamento → 8. Disseminação → 9. Referências → Apêndices A e B.

## Antes de entregar

1. **Preencher os campos em amarelo**: brasão da República na capa (copiar do modelo institucional), e-mails/Lattes/titulações do orientador e coorientador, confirmação da cidade (assumi Muzambinho – MG pelo modelo).
2. **Renderizar as fórmulas**: abra no Google Docs e rode a extensão **Auto-LaTeX Equations** — as 6 fórmulas estão no formato `$$...$$` e serão convertidas em imagens de alta qualidade.
3. Conferir o cronograma (meses marcados) com o orientador.

## Regeneração

Gerado programaticamente por `simulator/tools/monografia_gen.gd` (o Godot monta o OOXML):

```bash
godot --headless --path simulator --script res://tools/monografia_gen.gd
```

Edite o conteúdo no script e regenere — nunca edite o .docx e o script em paralelo; escolha um fluxo.
