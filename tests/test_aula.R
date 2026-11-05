# Testes do material da aula. Rodar a partir da raiz do projeto:
#   Rscript -e 'testthat::test_file("tests/test_aula.R")'
library(testthat)

raiz <- normalizePath(if (file.exists("aula_housing.qmd")) "." else "..")

rodar_script <- function() {
  env <- new.env()
  withr::with_dir(raiz, {
    set.seed(NULL)
    sys.source("aula_housing.R", envir = env)
  })
  env
}

env <- rodar_script()

test_that("dados carregados", {
  expect_equal(dim(env$housing), c(545L, 13L))
  expect_s3_class(env$housing$airconditioning, "factor")
  expect_equal(levels(env$housing$furnishingstatus),
               c("unfurnished", "semi-furnished", "furnished"))
})

test_that("erro claro fora do projeto", {
  script <- file.path(raiz, "aula_housing.R")
  withr::with_dir(tempdir(),
    expect_error(sys.source(script, envir = new.env()), "housing_pricing.Rproj"))
})

test_that("EDA gera gráficos no HTML", {
  html <- readLines(file.path(raiz, "aula_housing.html"), warn = FALSE)
  expect_gte(sum(lengths(regmatches(html, gregexpr("<img", html)))), 6)
})

test_that("features e receita", {
  novas <- c("log_price", "log_area", "total_comodos", "n_comodidades", "preco_pe2")
  expect_true(all(novas %in% names(env$housing_feat)))
  expect_equal(env$housing_feat$n_comodidades[1], 3)  # linha 1: mainroad, airconditioning, prefarea
  expect_equal(nrow(env$treino) + nrow(env$teste), 545L)
  expect_equal(nrow(env$folds), 5L)
  baked <- recipes::bake(recipes::prep(env$receita), new_data = NULL)
  expect_false(any(c("price", "preco_pe2") %in% names(baked)))
  expect_false(anyNA(baked))
})

test_that("cinco modelos e métricas em rúpias", {
  ids <- c("receita_linear", "receita_lasso", "receita_arvore", "receita_rf", "receita_xgb")
  expect_setequal(unique(env$metricas_cv$wflow_id), ids)
  expect_setequal(unique(env$metricas_cv$.metric), c("rmse", "mae", "rsq", "mape"))
  mae <- env$metricas_cv$mean[env$metricas_cv$.metric == "mae"]
  expect_true(all(mae > 1e5 & mae < 5e6))   # escala de rúpias, não de log
  expect_equal(nrow(env$vencedor_por_metrica), 4L)
})

test_that("reprodutível", {
  env2 <- rodar_script()
  expect_equal(env$metricas_cv, env2$metricas_cv)
})

test_that("fechamento", {
  expect_setequal(env$metricas_teste$.metric, c("rmse", "mae", "rsq", "mape"))
  expect_length(env$preco_previsto, 1L)
  expect_true(is.finite(env$preco_previsto) && env$preco_previsto > 1e6 && env$preco_previsto < 2e7)
  expect_equal(nrow(env$importancia), 12L)   # uma linha por característica original
})

test_that("script roda rápido", {
  expect_lt(system.time(rodar_script())[["elapsed"]], 120)
})

test_that("script sincronizado com o qmd", {
  tmp <- tempfile(fileext = ".R")
  withr::with_dir(raiz, knitr::purl("aula_housing.qmd", tmp, documentation = 0, quiet = TRUE))
  expect_identical(readLines(tmp), readLines(file.path(raiz, "aula_housing.R")))
})

test_that("script tem as 5 seções navegáveis no RStudio", {
  linhas <- readLines(file.path(raiz, "aula_housing.R"), encoding = "UTF-8")
  expect_equal(sum(grepl("^# [1-5][.] .+ ----$", linhas)), 5L)
})

# ---- Correções da revisão final ----

test_that("erro fora do projeto ensina a alternativa sem .Rproj", {
  script <- file.path(raiz, "aula_housing.R")
  withr::with_dir(tempdir(),
    expect_error(sys.source(script, envir = new.env()), "Set Working Directory"))
})

test_that("calculadora avisa quando uma característica é digitada errado", {
  casa_ok <- env$casa_digitada
  expect_true(is.finite(env$prever_preco(casa_ok)))
  casa_errada <- casa_ok
  casa_errada$airconditioning <- "Yes"
  expect_error(env$prever_preco(casa_errada), "digitad")
  casa_errada2 <- casa_ok
  casa_errada2$furnishingstatus <- "semifurnished"
  expect_error(env$prever_preco(casa_errada2), "furnishingstatus")
})

test_that("faixa do MAPE informa a cobertura real no teste", {
  expect_true(is.numeric(env$cobertura_faixa) && env$cobertura_faixa > 0 && env$cobertura_faixa < 1)
  qmd <- readLines(file.path(raiz, "aula_housing.qmd"), encoding = "UTF-8")
  expect_false(any(grepl("Faixa provável|margem de erro honesta", qmd)))
})

test_that("texto explica a escala do R² e a mini-função", {
  qmd <- paste(readLines(file.path(raiz, "aula_housing.qmd"), encoding = "UTF-8"), collapse = "\n")
  expect_match(qmd, "R² também é calculado em rúpias")
  expect_match(qmd, "mini-função")
})
