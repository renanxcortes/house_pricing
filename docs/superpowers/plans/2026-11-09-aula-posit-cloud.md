# Aula no Posit Cloud Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar a pasta `posit_cloud/` com o script de preparação, o guia do professor e o roteiro dos alunos, e publicá-la no GitHub.

**Architecture:** `preparar_projeto.R` define funções pequenas e testáveis (detectar repositório binário, listar pacotes faltando, gravar `.Rprofile`) e um bloco principal que só roda quando não está em teste. Os guias são Markdown.

**Tech Stack:** R ≥ 4.5, testthat, Posit Public Package Manager.

**Spec:** `docs/superpowers/specs/2026-11-09-aula-posit-cloud-design.md`

## Global Constraints

- Nenhum arquivo existente do repositório pode ser modificado; só arquivos novos em `posit_cloud/` e `docs/`.
- Pacotes: `c("tidyverse", "tidymodels", "glmnet", "rpart", "ranger", "xgboost")` — os mesmos do bloco de setup de `aula_housing.R`.
- Repositório binário Linux: `https://packagemanager.posit.co/cran/__linux__/<VERSION_CODENAME>/latest`.
- Repositório do GitHub: `https://github.com/renanxcortes/house_pricing`, branch `main`.
- Todo texto para o usuário em português.

## Review Focus

- `/etc/os-release` sem `VERSION_CODENAME` (ou arquivo inexistente): cair no CRAN padrão, sem erro.
- Rodar `preparar_projeto.R` a partir de uma pasta que não é a raiz do projeto: mensagem clara dizendo para abrir o projeto (sem `archive.zip`, parar).
- Rodar localmente no Windows: não gravar `.Rprofile` e não reinstalar pacotes já instalados.
- Rodar duas vezes na nuvem: o `.Rprofile` não deve ser duplicado nem sobrescrever conteúdo que não seja nosso.
- Erro ao rodar a aula: o resumo deve mostrar a mensagem de erro, e não "pronto".

---

### Task 1: Script de preparação

**Files:**
- Create: `posit_cloud/preparar_projeto.R`
- Test: `posit_cloud/tests/test_preparar_projeto.R`

**Interfaces:**
- Produces (em `preparar_projeto.R`):
  - `pacotes_aula` — vetor de caracteres com os 6 pacotes.
  - `repo_binario(sistema = Sys.info()[["sysname"]], os_release = "/etc/os-release")` → string com a URL do PPM se `sistema == "Linux"` e houver `VERSION_CODENAME`; caso contrário, `NULL`.
  - `pacotes_faltando(pacotes)` → subconjunto de `pacotes` sem `requireNamespace`.
  - `gravar_rprofile(repo, caminho = ".Rprofile")` → grava `options(repos = c(CRAN = "<repo>"))` entre os marcadores `# >>> posit_cloud` / `# <<< posit_cloud`; se os marcadores já existirem, substitui o bloco; preserva o restante do arquivo. Retorna `invisible(caminho)`.
  - Bloco principal, executado só se `!isTRUE(getOption("preparar.testando"))`: checa `file.exists("archive.zip")` (senão `stop()` com instrução para abrir o projeto); se `repo_binario()` não for `NULL`, aplica `options(repos=)` e chama `gravar_rprofile()`; instala `pacotes_faltando(pacotes_aula)`; roda `source("aula_housing.R", local = new.env())` dentro de `tryCatch`, medindo o tempo com `system.time`; imprime "PRONTO: a aula rodou em X s" ou "ERRO: <mensagem>".

- [ ] **Step 1: Escrever os testes**

`test_preparar_projeto.R` faz `options(preparar.testando = TRUE)` e `source()` do script; testes:
- `repo_binario("Linux", f)` com `f` contendo `VERSION_CODENAME=jammy` → `"https://packagemanager.posit.co/cran/__linux__/jammy/latest"`.
- `repo_binario("Linux", f_sem_codename)` → `NULL`; `repo_binario("Linux", "nao_existe")` → `NULL`; `repo_binario("Windows")` → `NULL`.
- `pacotes_faltando(c("stats", "pacoteQueNaoExiste123"))` → `"pacoteQueNaoExiste123"`.
- `gravar_rprofile()` num arquivo temporário com a linha `x <- 1`: depois de duas chamadas (repos diferentes), o arquivo contém `x <- 1`, exatamente um marcador de início e só o segundo repo.

- [ ] **Step 2: Rodar e ver falhar**

Run: `Rscript -e "testthat::test_file('posit_cloud/tests/test_preparar_projeto.R')"`
Expected: FAIL (arquivo do script não existe).

- [ ] **Step 3: Implementar `posit_cloud/preparar_projeto.R`** conforme as Interfaces, com comentários em português para o professor.

- [ ] **Step 4: Rodar os testes** — Expected: todos PASS.

- [ ] **Step 5: Rodar o script de verdade localmente**

Run (na raiz do repo): `Rscript posit_cloud/preparar_projeto.R`
Expected: termina com `PRONTO: a aula rodou em ... s`; nenhum `.Rprofile` criado no Windows; `git status` mostra só arquivos novos.

- [ ] **Step 6: Commit** — `git add posit_cloud/preparar_projeto.R posit_cloud/tests/` e commit.

### Task 2: Guia do professor e roteiro dos alunos

**Files:**
- Create: `posit_cloud/README.md`
- Create: `posit_cloud/roteiro_alunos.md`

- [ ] **Step 1: Escrever `posit_cloud/README.md`** com as seções da spec (item 1 de "O que será construído"): criar conta; New Project → From Git Repository com a URL do repositório; rodar `source("posit_cloud/preparar_projeto.R")`; limpeza opcional; compartilhar com "qualquer pessoa com o link"; teste com segunda conta (verificar os 3 itens "A verificar" da spec); checklist do dia; plano B. Incluir o aviso sobre horas de espaço compartilhado e por que cada aluno usa a própria conta.

- [ ] **Step 2: Escrever `posit_cloud/roteiro_alunos.md`**: 4 passos curtos, com o marcador `👉 LINK DO PROJETO: ____________` e o que fazer se algo der errado (abrir `aula_housing.html`, chamar o professor).

- [ ] **Step 3: Conferir** que todo caminho e nome de arquivo citado nos guias existe no repo (`archive.zip`, `aula_housing.R`, `aula_housing.html`, `posit_cloud/preparar_projeto.R`).

- [ ] **Step 4: Commit.**

### Task 3: Publicar

- [ ] **Step 1:** `git status` — só arquivos novos em `posit_cloud/` e `docs/`; nenhum arquivo existente modificado.
- [ ] **Step 2:** Commit dos arquivos de `docs/` (spec e plano).
- [ ] **Step 3:** `git push origin main` (autorizado pelo professor). Expected: push aceito.
- [ ] **Step 4:** Conferir no GitHub (`gh api repos/renanxcortes/house_pricing/contents/posit_cloud`) que os arquivos estão lá.
