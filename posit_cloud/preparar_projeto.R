# Preparação do projeto da aula no Posit Cloud
#
# Rode UMA VEZ, como professor, dentro do projeto no Posit Cloud
# (no Console, com o projeto aberto):
#
#   source("posit_cloud/preparar_projeto.R")
#
# O que este script faz:
#   1. Confere se você está na pasta certa do projeto.
#   2. No Linux (Posit Cloud), aponta o R para pacotes já compilados do
#      Posit Package Manager. Isso deixa a instalação muito mais rápida.
#      Também grava um .Rprofile no projeto, para que a configuração valha
#      nas cópias dos alunos (rede de segurança, caso eles precisem instalar).
#   3. Instala só os pacotes da aula que ainda faltam.
#   4. Roda a aula inteira (aula_housing.R) e diz se deu tudo certo.
#
# No Windows/macOS ele também funciona (para testar localmente): não grava
# .Rprofile e não reinstala pacotes que você já tem.

# Os mesmos pacotes do bloco de setup de aula_housing.R
pacotes_aula <- c("tidyverse", "tidymodels", "glmnet", "rpart", "ranger", "xgboost")

# URL dos binários do Posit Package Manager para esta distribuição Linux.
# Devolve NULL fora do Linux ou se não der para descobrir a distribuição.
repo_binario <- function(sistema = Sys.info()[["sysname"]],
                         os_release = "/etc/os-release") {
  if (!identical(sistema, "Linux") || !file.exists(os_release)) return(NULL)
  linhas <- readLines(os_release, warn = FALSE)
  linha <- grep("^VERSION_CODENAME=", linhas, value = TRUE)
  if (length(linha) == 0) return(NULL)
  codinome <- gsub('"', "", sub("^VERSION_CODENAME=", "", linha[1]))
  if (!nzchar(codinome)) return(NULL)
  paste0("https://packagemanager.posit.co/cran/__linux__/", codinome, "/latest")
}

# Quais pacotes ainda não estão instalados?
pacotes_faltando <- function(pacotes) {
  pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
}

# Grava (ou atualiza) no .Rprofile um bloco que aponta para o repositório.
# Preserva o que já existir no arquivo e não duplica o bloco.
gravar_rprofile <- function(repo, caminho = ".Rprofile") {
  inicio <- "# >>> posit_cloud"
  fim <- "# <<< posit_cloud"
  atual <- if (file.exists(caminho)) readLines(caminho, warn = FALSE) else character()
  i <- match(inicio, atual)
  j <- match(fim, atual)
  if (!is.na(i) && !is.na(j) && j > i) atual <- atual[-(i:j)]
  bloco <- c(inicio,
             "# Pacotes já compilados (gravado por posit_cloud/preparar_projeto.R)",
             sprintf('options(repos = c(CRAN = "%s"))', repo),
             fim)
  writeLines(c(atual, bloco), caminho)
  invisible(caminho)
}

if (!isTRUE(getOption("preparar.testando"))) local({
  if (!file.exists("archive.zip") || !file.exists("aula_housing.R")) {
    stop("Não encontrei archive.zip e aula_housing.R nesta pasta. ",
         "Abra o projeto da aula (a pasta house_pricing) e rode de novo.")
  }

  repo <- repo_binario()
  if (!is.null(repo)) {
    options(repos = c(CRAN = repo))
    gravar_rprofile(repo)
    message("Usando pacotes compilados de: ", repo)
  }

  faltando <- pacotes_faltando(pacotes_aula)
  if (length(faltando) > 0) {
    message("Instalando: ", paste(faltando, collapse = ", "))
    install.packages(faltando)
  } else {
    message("Todos os pacotes da aula já estão instalados.")
  }
  ainda_faltando <- pacotes_faltando(pacotes_aula)
  if (length(ainda_faltando) > 0) {
    stop("ERRO: não consegui instalar: ", paste(ainda_faltando, collapse = ", "))
  }

  message("Rodando a aula inteira para conferir (leva cerca de 1 minuto)...")
  inicio <- Sys.time()
  erro <- tryCatch({
    # Gráficos vão para um arquivo temporário, sem abrir janelas
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    capture.output(source("aula_housing.R", local = new.env(), encoding = "UTF-8"))
    NULL
  }, error = function(e) conditionMessage(e))
  segundos <- round(as.numeric(difftime(Sys.time(), inicio, units = "secs")))

  if (is.null(erro)) {
    message("\nPRONTO: a aula rodou do começo ao fim em ", segundos, " s.")
  } else {
    message("\nERRO ao rodar a aula: ", erro)
  }
})
