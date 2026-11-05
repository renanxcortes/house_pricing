# 1. Contexto e setup ----

# AULA: Quanto vale este imóvel? (MAT02053 - UFRGS)
# Somos a equipe de dados de uma imobiliária e vamos construir uma
# calculadora de preço de casas. Rode o script bloco a bloco (Ctrl + Enter).
# Este arquivo é gerado a partir de aula_housing.qmd (veja o HTML com as explicações).

# Criando um objeto chamado "precos" com quatro valores
precos <- c(100, 250, 300, 150)

# Aplicando uma função ao objeto: a média dos preços
mean(precos)

# O mesmo cálculo usando o pipe: "pegue precos E ENTÃO calcule a média"
precos |> mean()

# Pipes podem ser encadeados: média e então arredondamento com 1 casa
precos |> mean() |> round(1)

# Lista de pacotes usados na aula
pacotes <- c("tidyverse",   # manipulação (dplyr) e gráficos (ggplot2)
             "tidymodels",  # framework de modelagem
             "glmnet",      # regressão regularizada (LASSO)
             "rpart",       # árvore de decisão
             "ranger",      # random forest
             "xgboost")     # gradient boosting

# Quais ainda não estão instalados?
faltando <- pacotes[!sapply(pacotes, requireNamespace, quietly = TRUE)]

# Instala só os que faltam (se não faltar nenhum, não faz nada)
if (length(faltando) > 0) install.packages(faltando)

# Carrega os dois "pacotes-guarda-chuva" (eles carregam os demais por baixo)
library(tidyverse)
library(tidymodels)

# Evita conflitos de nomes de funções iguais em pacotes diferentes
tidymodels_prefer()

# Conferindo se estamos na pasta certa antes de ler os dados
if (!file.exists("archive.zip")) {
  stop("Não encontrei o arquivo archive.zip. ",
       "Feche o RStudio e abra o arquivo housing_pricing.Rproj ",
       "(ou use o menu Session > Set Working Directory > Choose Directory ",
       "e escolha a pasta housing_pricing).")
}

# unz() abre um arquivo de dentro do zip; read_csv() lê o CSV
housing_bruto <- read_csv(unz("archive.zip", "Housing.csv"))

# Primeira olhada: quantas linhas e colunas, e o tipo de cada coluna
glimpse(housing_bruto)

# Colunas do tipo sim/não
colunas_sim_nao <- c("mainroad", "guestroom", "basement",
                     "hotwaterheating", "airconditioning", "prefarea")

housing <- housing_bruto |>
  # across() aplica a mesma transformação em várias colunas de uma vez.
  # \(x) cria uma mini-função: "para cada coluna x, transforme x em fator"
  mutate(across(all_of(colunas_sim_nao), \(x) factor(x, levels = c("no", "yes")))) |>
  mutate(furnishingstatus = factor(furnishingstatus,
                                   levels = c("unfurnished", "semi-furnished", "furnished")))

# Conferindo o resultado: as colunas agora são <fct>
glimpse(housing)

# 2. Análise exploratória ----

# Resumo de cada coluna: mínimo, quartis, média, máximo (numéricas)
# e contagem por categoria (fatores)
summary(housing)

# Histograma: divide os preços em faixas e conta quantas casas há em cada faixa
ggplot(housing, aes(x = price)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  scale_x_continuous(labels = scales::label_comma()) +   # números sem notação científica
  labs(title = "Distribuição dos preços",
       x = "Preço (rúpias)", y = "Número de casas")

# Mesmo histograma, agora com o log do preço
ggplot(housing, aes(x = log(price))) +
  geom_histogram(bins = 30, fill = "darkorange", color = "white") +
  labs(title = "Distribuição do log do preço",
       x = "log(Preço)", y = "Número de casas")

# Gráfico de dispersão: cada ponto é uma casa
ggplot(housing, aes(x = area, y = price)) +
  geom_point(alpha = 0.5) +                          # alpha = transparência
  geom_smooth(method = "lm", color = "red") +        # reta de tendência
  scale_y_continuous(labels = scales::label_comma()) +
  labs(title = "Preço vs. área",
       x = "Área (pés²)", y = "Preço (rúpias)")

# Boxplot do preço para casas com e sem ar-condicionado
ggplot(housing, aes(x = airconditioning, y = price, fill = airconditioning)) +
  geom_boxplot(show.legend = FALSE) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(title = "Preço por presença de ar-condicionado",
       x = "Tem ar-condicionado?", y = "Preço (rúpias)")

# Boxplots do preço para TODAS as variáveis sim/não, um painel para cada
housing |>
  # Empilha as 6 colunas sim/não em duas: "variavel" (o nome) e "resposta" (yes/no)
  pivot_longer(cols = all_of(colunas_sim_nao),
               names_to = "variavel", values_to = "resposta") |>
  ggplot(aes(x = resposta, y = price, fill = resposta)) +
  geom_boxplot(show.legend = FALSE) +
  facet_wrap(~ variavel, nrow = 2) +                  # um painel por variável
  scale_y_continuous(labels = scales::label_comma()) +
  labs(title = "Preço por característica (sim/não)",
       x = NULL, y = "Preço (rúpias)")

# Quantas casas têm cada comodidade? (ajuda a ler o gráfico anterior)
housing |>
  pivot_longer(cols = all_of(colunas_sim_nao),
               names_to = "variavel", values_to = "resposta") |>
  count(variavel, resposta) |>
  pivot_wider(names_from = resposta, values_from = n)

# Boxplot do preço por tipo de mobília
ggplot(housing, aes(x = furnishingstatus, y = price, fill = furnishingstatus)) +
  geom_boxplot(show.legend = FALSE) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(title = "Preço por mobília",
       x = "Mobília", y = "Preço (rúpias)")

# Boxplots do preço por quantidade de quartos, banheiros, andares e vagas
housing |>
  # Empilha as variáveis de contagem para fazer um painel de cada
  pivot_longer(cols = c(bedrooms, bathrooms, stories, parking),
               names_to = "variavel", values_to = "quantidade") |>
  ggplot(aes(x = factor(quantidade), y = price)) +    # factor(): trata a contagem como categoria
  geom_boxplot(fill = "lightgreen") +
  facet_wrap(~ variavel, scales = "free_x") +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(title = "Preço por quantidade de cômodos, andares e vagas",
       x = "Quantidade", y = "Preço (rúpias)")

# Matriz de correlação entre as variáveis numéricas
matriz_cor <- housing |>
  select(where(is.numeric)) |>
  cor()

round(matriz_cor, 2)

# A mesma matriz em forma de "mapa de calor"
matriz_cor |>
  as_tibble(rownames = "var1") |>
  pivot_longer(-var1, names_to = "var2", values_to = "correlacao") |>
  ggplot(aes(x = var1, y = var2, fill = correlacao)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(correlacao, 2)), size = 3.5) +
  scale_fill_gradient2(low = "firebrick", mid = "white", high = "steelblue",
                       limits = c(-1, 1)) +
  labs(title = "Correlação entre variáveis numéricas", x = NULL, y = NULL) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 3. Criação de features ----

# Uma função recebe "dados" e devolve os dados com as colunas novas
criar_features <- function(dados) {
  dados |>
    mutate(
      log_price     = log(price),
      log_area      = log(area),
      total_comodos = bedrooms + bathrooms,
      # rowSums() soma, linha a linha, quantas colunas sim/não são iguais a "yes"
      n_comodidades = rowSums(across(all_of(colunas_sim_nao), \(x) x == "yes")),
      preco_pe2     = price / area
    )
}

housing_feat <- criar_features(housing)

# Olhando só as colunas novas das primeiras casas
housing_feat |>
  select(price, area, log_price, log_area, total_comodos, n_comodidades, preco_pe2) |>
  head()

# A feature nova faz sentido? Preço por número de comodidades
ggplot(housing_feat, aes(x = factor(n_comodidades), y = price)) +
  geom_boxplot(fill = "plum") +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(title = "Preço por número de comodidades",
       x = "Número de comodidades (0 a 6)", y = "Preço (rúpias)")

# Preço por pé² (só para explorar: NÃO pode entrar no modelo, pois usa o preço!)
ggplot(housing_feat, aes(x = prefarea, y = preco_pe2, fill = prefarea)) +
  geom_boxplot(show.legend = FALSE) +
  labs(title = "Preço por pé² dentro e fora da área nobre",
       x = "Área nobre?", y = "Preço por pé² (rúpias)")

# Separando 80% das casas para treino e 20% para teste
# set.seed() fixa o sorteio: todos obtêm a mesma divisão
set.seed(2026)

# strata = price: garante casas baratas e caras em proporções parecidas nas duas partes
split_housing <- initial_split(housing_feat, prop = 0.8, strata = price)

treino <- training(split_housing)
teste  <- testing(split_housing)

# Quantas casas ficaram em cada parte?
nrow(treino)
nrow(teste)

# Validação cruzada: divide o treino em 5 pedaços (folds)
set.seed(2026)
folds <- vfold_cv(treino, v = 5, strata = price)
folds

receita <- recipe(log_price ~ ., data = treino) |>   # prever log_price com todas as outras colunas...
  step_rm(price, preco_pe2) |>                        # ...exceto price e preco_pe2 (vazamento!)
  step_dummy(all_nominal_predictors()) |>             # categorias viram colunas 0/1 (dummies)
  step_normalize(all_numeric_predictors())            # numéricas com média 0 e desvio-padrão 1

# Imprimir a receita mostra a lista de passos
receita

# Só para olhar o resultado da receita (o tidymodels faz isso sozinho ao modelar)
receita |>
  prep() |>                   # aprende os passos usando o treino
  bake(new_data = NULL) |>    # aplica nos próprios dados de treino
  glimpse()

# 4. Modelagem ----

# Modelo 1: Regressão linear
modelo_linear <- linear_reg() |>
  set_engine("lm")

# Modelo 2: LASSO: a "penalty" (quanto encolher) será escolhida por tuning logo abaixo
modelo_lasso <- linear_reg(penalty = tune(), mixture = 1) |>   # mixture = 1 significa LASSO
  set_engine("glmnet")

# Modelo 3: Árvore de decisão com no máximo 5 níveis de perguntas
modelo_arvore <- decision_tree(tree_depth = 5) |>
  set_engine("rpart") |>
  set_mode("regression")

# Modelo 4: Random forest com 500 árvores
modelo_rf <- rand_forest(trees = 500, min_n = 5) |>
  set_engine("ranger", seed = 2026, num.threads = 1) |>   # seed e 1 thread: resultado reprodutível
  set_mode("regression")

# Modelo 5: XGBoost com 300 árvores pequenas e aprendizado lento
modelo_xgb <- boost_tree(trees = 300, learn_rate = 0.05, tree_depth = 3) |>
  set_engine("xgboost", nthread = 1) |>
  set_mode("regression")

# Tuning: testa 10 valores de penalidade do LASSO na validação cruzada
set.seed(2026)
tuning_lasso <- workflow() |>
  add_recipe(receita) |>
  add_model(modelo_lasso) |>
  tune_grid(resamples = folds, grid = 10)   # 10 valores de penalidade

# Os melhores valores de penalidade segundo o RMSE (em escala log)
show_best(tuning_lasso, metric = "rmse", n = 3)

# Fixando a melhor penalidade no modelo LASSO
melhor_penalidade <- select_best(tuning_lasso, metric = "rmse")
modelo_lasso_final <- finalize_model(modelo_lasso, melhor_penalidade)
modelo_lasso_final

# Junta a receita com os 5 modelos num único "conjunto de workflows"
modelos_wf <- workflow_set(
  preproc = list(receita = receita),
  models  = list(linear = modelo_linear,
                 lasso  = modelo_lasso_final,
                 arvore = modelo_arvore,
                 rf     = modelo_rf,
                 xgb    = modelo_xgb)
)

# Roda a validação cruzada para os 5 modelos (guardando as previsões)
modelos_wf <- modelos_wf |>
  workflow_map("fit_resamples",
               resamples = folds,
               control = control_resamples(save_pred = TRUE),
               seed = 2026)

# Uma linha por modelo, com os resultados dentro
modelos_wf

# Previsões de cada modelo em cada fold, de volta para rúpias
previsoes_cv <- modelos_wf |>
  collect_predictions(summarize = FALSE) |>
  mutate(preco_real     = exp(log_price),   # exp() desfaz o log
         preco_previsto = exp(.pred))

# Olhando algumas previsões
previsoes_cv |>
  select(wflow_id, id, preco_real, preco_previsto) |>
  head()

# Conjunto das 4 métricas
metricas <- metric_set(rmse, mae, mape, rsq)

metricas_cv <- previsoes_cv |>
  group_by(wflow_id, id) |>                                   # para cada modelo e cada fold...
  metricas(truth = preco_real, estimate = preco_previsto) |>  # ...calcula as 4 métricas
  group_by(wflow_id, .metric) |>                              # e então, para cada modelo e métrica...
  summarise(mean    = mean(.estimate),                        # ...a média nos 5 folds
            std_err = sd(.estimate) / sqrt(n()),              # ...e o erro-padrão dessa média
            .groups = "drop")

# Tabela comparativa: uma linha por modelo, uma coluna por métrica
metricas_cv |>
  select(-std_err) |>
  pivot_wider(names_from = .metric, values_from = mean) |>
  arrange(rmse)

# Gráfico de comparação: ponto = média nos folds; barra = ± 1 erro-padrão
metricas_cv |>
  mutate(modelo = str_remove(wflow_id, "receita_")) |>
  ggplot(aes(x = mean, y = reorder(modelo, mean))) +
  geom_point(size = 3, color = "steelblue") +
  geom_errorbar(aes(xmin = mean - std_err, xmax = mean + std_err), width = 0.2) +
  facet_wrap(~ .metric, scales = "free_x") +
  scale_x_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +  # 1.2M = 1,2 milhão
  labs(title = "Comparação dos modelos na validação cruzada",
       subtitle = "RMSE, MAE e MAPE: menor é melhor  |  R²: maior é melhor",
       x = "Valor médio nos 5 folds", y = NULL)

# O melhor modelo em cada métrica (média dos 5 folds)
vencedor_por_metrica <- metricas_cv |>
  group_by(.metric) |>
  # para rsq o melhor é o MAIOR; para as outras, o MENOR
  slice_min(if_else(.metric == "rsq", -mean, mean), n = 1) |>
  ungroup() |>
  select(.metric, wflow_id, mean)

vencedor_por_metrica

# Quantos folds cada modelo venceu, em cada métrica?
vencedores_por_fold <- previsoes_cv |>
  group_by(wflow_id, id) |>
  metricas(truth = preco_real, estimate = preco_previsto) |>
  group_by(id, .metric) |>                                         # para cada fold e métrica...
  slice_min(if_else(.metric == "rsq", -.estimate, .estimate), n = 1) |>  # ...o melhor modelo
  ungroup() |>
  count(.metric, wflow_id, name = "folds_vencidos")

vencedores_por_fold |>
  pivot_wider(names_from = .metric, values_from = folds_vencidos, values_fill = 0)

# 5. Fechamento ----

# Nome do modelo vencedor no RMSE
vencedor_rmse <- vencedor_por_metrica |>
  filter(.metric == "rmse") |>
  pull(wflow_id)

vencedor_rmse

# Ajuste final: treina no treino completo e avalia no teste
ajuste_final <- modelos_wf |>
  extract_workflow(vencedor_rmse) |>
  last_fit(split_housing)

# Previsões no teste, de volta para rúpias
previsoes_teste <- ajuste_final |>
  collect_predictions() |>
  mutate(preco_real     = exp(log_price),
         preco_previsto = exp(.pred))

# As mesmas 4 métricas, agora no teste
metricas_teste <- previsoes_teste |>
  metricas(truth = preco_real, estimate = preco_previsto)

metricas_teste

# Previsto vs. real: quanto mais perto da linha tracejada, melhor
ggplot(previsoes_teste, aes(x = preco_real, y = preco_previsto)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_abline(linetype = "dashed", color = "red") +   # linha de 45°: previsão perfeita
  scale_x_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
  scale_y_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
  coord_equal() +
  labs(title = "Conjunto de teste: preço previsto vs. preço real",
       x = "Preço real (rúpias)", y = "Preço previsto (rúpias)")

# O modelo final já treinado
modelo_final <- extract_workflow(ajuste_final)

# Teste só com as colunas originais (as features são recalculadas depois)
teste_original <- teste |> select(all_of(names(housing)))

# Função: RMSE (em rúpias) do modelo final num conjunto de dados
rmse_rupias <- function(dados) {
  dados_feat <- criar_features(dados)
  previsto <- exp(predict(modelo_final, dados_feat)$.pred)
  rmse_vec(truth = dados$price, estimate = previsto)
}

rmse_original <- rmse_rupias(teste_original)

# Para cada característica: embaralha 10 vezes e mede o aumento médio do erro
caracteristicas <- setdiff(names(housing), "price")

set.seed(2026)
importancia <- map_dfr(caracteristicas, \(variavel) {
  aumentos <- replicate(10, {
    embaralhado <- teste_original
    embaralhado[[variavel]] <- sample(embaralhado[[variavel]])   # embaralha a coluna
    rmse_rupias(embaralhado) - rmse_original
  })
  tibble(variavel = variavel, aumento_rmse = mean(aumentos))
})

importancia |>
  ggplot(aes(x = aumento_rmse, y = reorder(variavel, aumento_rmse))) +
  geom_col(fill = "steelblue") +
  scale_x_continuous(labels = scales::label_comma()) +
  labs(title = "Importância por permutação",
       subtitle = "Quanto o RMSE (em rúpias) piora ao embaralhar cada característica",
       x = "Aumento do RMSE (rúpias)", y = NULL)

# Função da calculadora: recebe a descrição da casa e devolve o preço em rúpias
prever_preco <- function(casa) {
  # 1. Conferindo a digitação (um "Yes" com maiúscula viraria NA sem aviso!)
  for (coluna in colunas_sim_nao) {
    if (!casa[[coluna]] %in% c("yes", "no")) {
      stop("A característica '", coluna, "' foi digitada errado: use \"yes\" ou \"no\".")
    }
  }
  if (!casa$furnishingstatus %in% levels(housing$furnishingstatus)) {
    stop("A característica 'furnishingstatus' foi digitada errado: use ",
         "\"unfurnished\", \"semi-furnished\" ou \"furnished\".")
  }

  # 2. Mesmas conversões que fizemos nos dados originais
  casa_preparada <- casa |>
    mutate(across(all_of(colunas_sim_nao), \(x) factor(x, levels = c("no", "yes"))),
           furnishingstatus = factor(furnishingstatus, levels = levels(housing$furnishingstatus)),
           price = NA_real_) |>   # o preço é desconhecido: é o que queremos descobrir!
    criar_features()

  # 3. Previsão em log e então exp() para voltar a rúpias
  exp(predict(modelo_final, casa_preparada)$.pred)
}

# A casa do proprietário: preencha TODAS as características
casa_digitada <- tibble(
  area             = 6000,              # pés²
  bedrooms         = 3,
  bathrooms        = 2,
  stories          = 2,                 # andares
  parking          = 1,                 # vagas de garagem
  mainroad         = "yes",             # "yes" ou "no"
  guestroom        = "no",              # "yes" ou "no"
  basement         = "yes",             # "yes" ou "no"
  hotwaterheating  = "no",              # "yes" ou "no"
  airconditioning  = "yes",             # "yes" ou "no"
  prefarea         = "no",              # "yes" ou "no"
  furnishingstatus = "semi-furnished"   # "unfurnished", "semi-furnished" ou "furnished"
)

preco_previsto <- prever_preco(casa_digitada)

cat("Preço estimado:", scales::comma(preco_previsto), "rúpias\n")

# Faixa de ± MAPE em volta do preço estimado
mape_teste <- metricas_teste |> filter(.metric == "mape") |> pull(.estimate)

cat("Faixa de ± erro típico:",
    scales::comma(preco_previsto * (1 - mape_teste / 100)), "a",
    scales::comma(preco_previsto * (1 + mape_teste / 100)), "rúpias\n")

# Mas atenção: quantas casas do teste realmente caíram dentro de ± MAPE da sua previsão?
cobertura_faixa <- previsoes_teste |>
  summarise(dentro = mean(abs(preco_real - preco_previsto) / preco_real <= mape_teste / 100)) |>
  pull(dentro)

cat("Casas do teste dentro da faixa:", scales::percent(cobertura_faixa), "\n")
