# Quanto vale este imóvel? — Precificação de imóveis com R e tidymodels

Material de uma aula prática, **100% guiada**, da disciplina **MAT02053 – Estatística Aplicada a Negócios (UFRGS)**. A aula foi pensada para alunos de graduação em Estatística que sabem **pouco ou nada de R**: eles rodam o código junto com o professor, bloco a bloco.

## O enredo

Somos a **equipe de dados de uma imobiliária** e precisamos construir uma **calculadora de preço de imóveis**, no estilo do "quanto vale meu imóvel?" do QuintoAndar. O proprietário informa as características da casa, e o modelo estima o preço de venda.

## O que os alunos aprendem

1. **Análise exploratória e visualização** (ggplot2): distribuição do preço e motivação do log, preço vs. área, boxplots por comodidade e por mobília, matriz de correlação. Cada gráfico responde a uma pergunta de negócio.
2. **Criação de features**: log da área, total de cômodos, índice de comodidades e preço por pé². Este último serve para discutir **vazamento de dados**. Depois, a **recipe** do tidymodels (dummies e normalização) mostra por que a preparação deve ser aprendida só no treino.
3. **Modelagem com tidymodels**: divisão treino/teste, validação cruzada com 5 *folds* e **cinco modelos** comparados num `workflow_set`:
   - regressão linear;
   - LASSO, com um tuning leve da penalidade;
   - árvore de decisão;
   - random forest;
   - XGBoost.
4. **Comparação por métrica**: RMSE, MAE, MAPE e R², calculados **em rúpias** depois de desfazer o log. A aula discute como o "melhor modelo" depende da métrica escolhida e da variação entre os *folds*.
5. **Fechamento**:
   - avaliação no conjunto de teste;
   - importância das variáveis por permutação;
   - a **calculadora de preço**, com o tamanho típico do erro e seus limites.

## Os dados

`archive.zip` contém o `Housing.csv`, do Kaggle ([Housing Prices Dataset](https://www.kaggle.com/datasets/yasserh/housing-prices-dataset)). São **545 casas vendidas na Índia**, com 13 colunas e sem dados faltantes. As unidades originais foram mantidas: o **preço** está em **rúpias** e a **área** em **pés²**. O script lê o CSV direto de dentro do zip, sem precisar descompactar.

| Variável | Significado |
|---|---|
| `price` | preço de venda (rúpias). É a variável a prever |
| `area` | área (pés²) |
| `bedrooms`, `bathrooms`, `stories`, `parking` | quartos, banheiros, andares, vagas |
| `mainroad`, `guestroom`, `basement`, `hotwaterheating`, `airconditioning`, `prefarea` | comodidades (yes/no) |
| `furnishingstatus` | mobília: unfurnished, semi-furnished, furnished |

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `aula_housing.R` | **Script da aula**, que os alunos rodam bloco a bloco (Ctrl + Enter). As seções aparecem no índice do RStudio |
| `aula_housing.html` | **Material de estudo**: o mesmo código com explicações e gráficos. Abre em qualquer navegador |
| `aula_housing.qmd` | **Fonte única** do material (Quarto). O `.R` e o `.html` são gerados a partir dele |
| `archive.zip` | Os dados |
| `tools/build.R` | Gera o `.R` (via `knitr::purl`) e o `.html` (via Quarto) a partir do `.qmd` |
| `tests/test_aula.R` | Testes automáticos do material |

## Como rodar (alunos)

1. Abra o arquivo `housing_pricing.Rproj` no RStudio. Se você baixou a pasta sem o `.Rproj`, use **Session > Set Working Directory > Choose Directory** e escolha a pasta `housing_pricing`.
2. Abra `aula_housing.R` e rode bloco a bloco.
3. O primeiro bloco **instala automaticamente** os pacotes que estiverem faltando: tidyverse, tidymodels, glmnet, rpart, ranger e xgboost.

Requisitos: R ≥ 4.5. O script completo roda em cerca de 30 segundos.

> **Dica para o professor:** rode o bloco de instalação de pacotes nos computadores do laboratório **antes da aula**. Instalar tudo do zero pode demorar.

## Como editar o material (professor)

O `.qmd` é a fonte. **Não edite `aula_housing.R` à mão**, porque ele é sobrescrito pelo build. Depois de alterar o `.qmd`, rode a partir desta pasta:

```bash
Rscript tools/build.R                              # gera aula_housing.R e aula_housing.html
Rscript -e 'testthat::test_file("tests/test_aula.R")'  # roda os testes
```

O build usa o Quarto do PATH. Se ele não estiver no PATH, usa o Quarto que vem com o RStudio.

Os testes verificam, entre outras coisas:
- a leitura dos dados e a mensagem de erro quando o aluno está na pasta errada;
- as features e a receita, incluindo a ausência de vazamento;
- os 5 modelos com métricas na escala de rúpias;
- a reprodutibilidade, ou seja, que duas execuções dão números idênticos;
- a calculadora, inclusive o aviso quando uma característica é digitada errado;
- que o script roda em menos de 2 minutos;
- que o `.R` está sincronizado com o `.qmd`.

## Principais resultados

- O **LASSO** ficou em primeiro nas quatro métricas da validação cruzada, em **empate técnico** com a regressão linear. Random forest e XGBoost ficaram atrás. Com poucos dados e uma relação aproximadamente linear com o log do preço, modelos simples vencem.
- Olhando **fold a fold**, o vencedor muda conforme a métrica, o que mostra que escolher a métrica é uma decisão de negócio.
- No teste, o modelo final erra em média cerca de **16%** do preço (MAPE). Área, banheiros, ar-condicionado, andares e área nobre são as características mais importantes.

Os números exatos podem variar levemente com versões diferentes dos pacotes.
