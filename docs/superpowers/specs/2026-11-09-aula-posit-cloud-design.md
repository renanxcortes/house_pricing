# Design: opção da aula no Posit Cloud

Data: 2026-11-09

## Intenção e porquê

A aula "Quanto vale este imóvel?" (MAT02053, UFRGS) depende de pacotes R (tidyverse, tidymodels, glmnet, rpart, ranger, xgboost) que **não podem ser instalados nos computadores do laboratório antes da aula**. Instalar ~150 pacotes com 18 alunos ao mesmo tempo durante a aula é lento e arriscado.

A solução é oferecer uma **opção adicional** de rodar a mesma aula no **Posit Cloud** (RStudio no navegador). O professor prepara uma vez um projeto com os pacotes já instalados; cada aluno faz uma cópia na própria conta gratuita e roda o script normalmente.

## Objetivos

- A aula em si **não muda**: mesmo conteúdo, mesmo script `aula_housing.R`, mesmo ritmo bloco a bloco.
- O professor, partindo do zero (sem conta no Posit Cloud), consegue montar tudo seguindo um guia.
- Os alunos começam a rodar o script em poucos minutos, sem instalar nada.
- Nenhum custo para o professor nem para os alunos (plano gratuito).

## Não-objetivos

- Não reescrever nem adaptar o conteúdo da aula.
- Não criar espaço compartilhado da turma nem usar planos pagos para professor.
- Não automatizar a criação de contas ou projetos no Posit Cloud (é feito à mão pelo navegador).

## Anti-objetivos (seria um fracasso mesmo que funcionasse)

- **Alterar qualquer arquivo existente** do repositório (`aula_housing.qmd/.R/.html`, `README.md`, `tests/`, `tools/`, etc.). Tudo que for novo fica numa pasta separada.
- Consumir as horas do professor com o uso dos alunos (estourar o plano gratuito durante a aula).
- Alunos tendo que instalar pacotes na aula.

## Restrições e fatos levantados

- Até **18 alunos**.
- **Decisão do professor:** cada aluno usa a **própria conta gratuita** do Posit Cloud.
- Motivo: segundo a documentação do Posit Cloud, o uso dentro de um espaço compartilhado é cobrado da conta de quem criou o espaço. Compute hours = (RAM GB + CPUs) / 2 × horas; um projeto de 1 GB / 1 CPU gasta ~1 hora por hora. 18 alunos × 2 h ≈ 36 h, acima do limite provável do plano gratuito (~25 h/mês, número não confirmado).
- Projetos do plano gratuito têm pouca RAM e 1 CPU. O script já é sequencial (`num.threads = 1`, `nthread = 1`), a base tem 545 linhas, e localmente roda em ~30 s.
- O repositório é público no GitHub: `https://github.com/renanxcortes/house_pricing`. Isso permite criar o projeto no Posit Cloud direto pelo Git.
- O Posit Cloud roda Linux. Instalar pacotes do CRAN a partir do código-fonte é lento e pode estourar a RAM (xgboost). Por isso, a preparação deve usar **binários do Posit Public Package Manager**.

**A verificar pelo professor (o guia deve ter um passo de teste):**

1. Os limites atuais do plano gratuito (horas/mês, RAM, nº de projetos).
2. Se a cópia que o aluno faz a partir do link compartilhado leva junto os pacotes instalados.
3. Se as horas dessa cópia contam na conta do aluno.

## O que será construído

Uma nova pasta `posit_cloud/` na raiz do repositório com:

1. **`posit_cloud/README.md`: guia do professor**, em português, passo a passo:
   - criar a conta gratuita;
   - criar um projeto a partir do repositório do GitHub (New Project → From Git Repository);
   - rodar o script de preparação;
   - (opcional) limpar arquivos que os alunos não precisam no projeto-modelo (`tools/`, `tests/`, `historico_conversa.md`, `aula_housing.qmd`, `docs/`). Isso é feito só dentro do Posit Cloud, sem mudar o repositório;
   - configurar o acesso do projeto para "qualquer pessoa com o link" e obter o link;
   - **testar antes da aula** com uma segunda conta: abrir o link, salvar cópia permanente, conferir que os pacotes estão lá (o bloco de instalação não deve instalar nada) e que o uso aparece na conta da cópia;
   - checklist do dia da aula e plano B (o `aula_housing.html` no navegador; dupla com colega).
2. **`posit_cloud/preparar_projeto.R`: script de preparação**, rodado uma vez pelo professor dentro do projeto no Posit Cloud:
   - aponta o repositório para os binários Linux do Posit Public Package Manager, detectando a distribuição; em Windows/macOS, usa o CRAN padrão;
   - instala os mesmos pacotes do bloco de setup da aula;
   - roda `aula_housing.R` do início ao fim (via `source()`), medindo o tempo, e imprime um resumo claro de "pronto" ou do erro encontrado.
   - *(decisão do Claude)* instala **só os pacotes que faltam**. Num projeto novo na nuvem, isso significa instalar todos; rodado localmente, não mexe na biblioteca R do professor.
   - *(decisão do Claude)* na nuvem, grava um `.Rprofile` na raiz do projeto do Posit Cloud (não no repositório) que aponta para os binários do Posit Package Manager. Isso é a rede de segurança: se a cópia do aluno não levar os pacotes, o bloco de instalação da própria aula instala binários em vez de compilar. O `.Rprofile` é um arquivo do projeto e vai junto na cópia.
3. **`posit_cloud/roteiro_alunos.md`: roteiro curto para os alunos**, para projetar no início da aula ou enviar antes:
   - criar conta gratuita (com Google ou e-mail);
   - abrir o link do professor;
   - clicar em salvar cópia permanente;
   - abrir `aula_housing.R` e rodar bloco a bloco.
   - O roteiro inclui um espaço marcado para o professor colar o link.

O script da aula (`aula_housing.R`) é usado **como está**. O bloco de instalação não faz nada quando os pacotes já existem. O diretório de trabalho do projeto é a raiz do repositório, então `archive.zip` é encontrado.

## Deixado para quem constrói

- Redação e formatação dos guias (tom: direto, para quem nunca usou o Posit Cloud).
- Detalhes do `preparar_projeto.R` (mensagens, como detectar a distribuição Linux), desde que funcione também localmente no Windows para teste.
- Os nomes exatos dos botões do Posit Cloud podem mudar. Os guias devem descrever a ação de forma que sobreviva a pequenas mudanças de interface.

## Verificação

- Rodar `posit_cloud/preparar_projeto.R` localmente (Windows), com os pacotes já instalados, deve terminar com sucesso.
- `git status` deve mostrar só arquivos novos, nenhum arquivo existente modificado.
- O teste no Posit Cloud de verdade é feito pelo professor, seguindo o passo de teste do guia.
