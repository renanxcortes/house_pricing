# Testes do script de preparação do Posit Cloud.
# Rodar a partir da raiz do projeto:
#   Rscript -e "testthat::test_file('posit_cloud/tests/test_preparar_projeto.R')"

library(testthat)

raiz <- normalizePath(file.path(testthat::test_path(), "..", ".."))
options(preparar.testando = TRUE)
source(file.path(raiz, "posit_cloud", "preparar_projeto.R"), local = TRUE)

escrever_temp <- function(linhas) {
  f <- tempfile()
  writeLines(linhas, f)
  f
}

test_that("pacotes da aula são os mesmos do script da aula", {
  expect_equal(pacotes_aula,
               c("tidyverse", "tidymodels", "glmnet", "rpart", "ranger", "xgboost"))
  script <- readLines(file.path(raiz, "aula_housing.R"), encoding = "UTF-8")
  for (p in pacotes_aula) expect_true(any(grepl(paste0('"', p, '"'), script)))
})

test_that("repo_binario monta a URL do Package Manager no Linux", {
  f <- escrever_temp(c('NAME="Ubuntu"', "VERSION_CODENAME=jammy", "ID=ubuntu"))
  expect_equal(repo_binario("Linux", f),
               "https://packagemanager.posit.co/cran/__linux__/jammy/latest")
})

test_that("repo_binario aceita codename entre aspas", {
  f <- escrever_temp('VERSION_CODENAME="noble"')
  expect_equal(repo_binario("Linux", f),
               "https://packagemanager.posit.co/cran/__linux__/noble/latest")
})

test_that("repo_binario devolve NULL quando não dá para saber a distribuição", {
  expect_null(repo_binario("Linux", escrever_temp('NAME="Algo"')))
  expect_null(repo_binario("Linux", file.path(tempdir(), "nao_existe")))
  expect_null(repo_binario("Windows"))
  expect_null(repo_binario("Darwin"))
})

test_that("pacotes_faltando lista só os que não estão instalados", {
  expect_equal(pacotes_faltando(c("stats", "pacoteQueNaoExiste123")),
               "pacoteQueNaoExiste123")
  expect_length(pacotes_faltando("stats"), 0)
})

test_that("gravar_rprofile preserva o conteúdo e não duplica o bloco", {
  f <- escrever_temp("x <- 1")
  gravar_rprofile("https://repo-um", f)
  gravar_rprofile("https://repo-dois", f)
  conteudo <- readLines(f)
  expect_true("x <- 1" %in% conteudo)
  expect_equal(sum(conteudo == "# >>> posit_cloud"), 1)
  expect_equal(sum(conteudo == "# <<< posit_cloud"), 1)
  expect_false(any(grepl("repo-um", conteudo)))
  expect_true(any(grepl("repo-dois", conteudo)))
})

test_that("gravar_rprofile cria o arquivo se ele não existe", {
  f <- file.path(tempdir(), "Rprofile_novo")
  unlink(f)
  gravar_rprofile("https://repo", f)
  expect_true(file.exists(f))
  expect_true(any(grepl('options\\(repos = c\\(CRAN = "https://repo"\\)\\)', readLines(f))))
})
