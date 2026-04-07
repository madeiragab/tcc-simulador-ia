# Documentação do Projeto

Este diretório concentra a base teórica formal, definições arquiteturais e configurações de validação metodológica para o uso do ambiente de simulações e verificação analítica dos diferentes paradigmas das lógicas artificiais adotadas pelo projeto.

## Arquivos e Guias do Sistema

### 1. Sistema e Arquitetura
- **arquitetura.md**: Estruturação geral lógica da separação entre responsabilidades dos módulos de Core, Mapa, IA e Coleta.
- **agentes.md**: Define atributos primitivos, estado basal corporativo (Vida, Posição) da entidade-núcleo nos campos lógicos do experimento.
- **movimento.md**: Consolida a mecânica paramétrica limitadora de locomoção válida no *grid* por turno.
- **regras.md**: Regras definitivas implementadas no mundo das simulações táticas perante a simetria, ações e determinismo bélico para validar o sistema sem enviesamentos.
- **turnos.md**: Regência processual da temporalidade sequencial dos agentes para executar comandos assíncronos justos durante as simulações baseadas em *ticks*.

### 2. Metodologia Científica e Analítica
- **problema.md**: Descritivo da ausência empírica das métricas completas nas avaliações modernas e fundamentação científica em cima disso.
- **contribuicao.md**: Descrição e consolidações formais pautando o cerne intelectual dessa modelagem baseada em Equilíbrio x Custos que serve de entrega final.
- **metodologia.md**: Parâmetros padronizados das regras de laboratório simulado buscando impulsionar e resguardar reprodutibilidade estrita.
- **experiments.md**: Fatores processuais em *batch*, definindo uso de múltiplas simulações repetidas (1000 iteradas), limite global e *seeds* estatisticamente idênticas.
- **coleta_dados.md**: Mecânicas e parâmetros que dão suporte para o parseamento e registro das logs e resultados em `data/` em formato `.csv`.
- **metricas.md**: Fórmulas, funções descritivas, proteção a *exploits* numéricos (Epsilon para Divisão por 0) e equações absolutas agregadas como o *Strategic Score*.

### 3. Concepção das Inteligências
- **ia.md**: Definições a respeito do paradigma reativo de Utility AI, cálculos de score puro abstrato e seleção de estado base.
- **baseline.md**: Modelos empíricos fixos de referências comparativas estáticas para servir de atrito na comparação métrica final (Aleatória, Reativa, Heurística).
- **modelo_proposto.md**: A especificação formal matemática da nova proposta, focada na híbrida decisão perante custos operacionais e viabilidade.