# Aula no Posit Cloud: guia do professor

Esta pasta é uma **opção alternativa** para dar a aula *"Quanto vale este imóvel?"* quando não dá para instalar os pacotes R nos computadores do laboratório. Os alunos usam o **Posit Cloud**, que é o RStudio dentro do navegador. Eles não instalam nada: só abrem um link.

**A aula em si não muda.** O script é o mesmo `aula_housing.R`, rodado bloco a bloco. Nenhum arquivo da aula original foi alterado.

| Arquivo | Para que serve |
|---|---|
| `README.md` | Este guia, para o professor |
| `roteiro_alunos.md` | Passo a passo curto para os alunos, para projetar na aula ou enviar antes |
| `preparar_projeto.R` | Script que você roda **uma vez** no Posit Cloud para instalar os pacotes e testar a aula |
| `tests/` | Testes automáticos do script de preparação |

## Por que cada aluno usa a própria conta

No Posit Cloud, o uso de um **espaço compartilhado** (por exemplo, um espaço da turma) é cobrado de **quem criou o espaço**. O consumo é calculado em *compute hours*: (RAM em GB + nº de CPUs) ÷ 2 × horas. Um projeto de 1 GB e 1 CPU gasta cerca de 1 hora por hora de uso.

Com 18 alunos e 2 horas de aula, o consumo fica em torno de **36 horas**, acima do que o plano gratuito costuma oferecer por mês. Por isso, a ideia é outra:

1. Você monta **um projeto-modelo** na sua área pessoal, com tudo instalado.
2. Você compartilha o projeto **por link**.
3. Cada aluno abre o link e salva **uma cópia na própria conta gratuita**. Assim, cada um gasta as próprias horas.

> ⚠️ Os limites do plano gratuito mudam com o tempo. Confira em <https://posit.cloud/plans> antes da aula. Fonte sobre as horas: [Compute Hours — Posit Cloud docs](https://docs.posit.co/cloud/guide/articles/compute-hours.html).

---

## Passo a passo (faça alguns dias antes da aula)

### 1. Criar a sua conta

1. Acesse <https://posit.cloud> e clique em **Sign Up**.
2. Escolha o plano **Free** (gratuito) e entre com Google, GitHub ou e-mail.

### 2. Criar o projeto a partir do GitHub

1. Na sua área (**Your Workspace**), clique em **New Project** e depois em **New Project from Git Repository**.
2. Cole o endereço do repositório:
   ```
   https://github.com/renanxcortes/house_pricing
   ```
3. Espere o projeto abrir. Na primeira vez, pode levar um ou dois minutos.
4. Dê um nome ao projeto, clicando no título lá em cima. Por exemplo: **Aula – Quanto vale este imóvel?**

### 3. Instalar os pacotes e testar a aula

No **Console** (o painel de baixo, à esquerda), rode:

```r
source("posit_cloud/preparar_projeto.R")
```

O script:

- usa pacotes já compilados do *Posit Package Manager*, o que é bem mais rápido do que compilar;
- grava um arquivo `.Rprofile` no projeto com essa configuração. Ele vai junto nas cópias dos alunos e serve de rede de segurança;
- instala só os pacotes que faltam (tidyverse, tidymodels, glmnet, rpart, ranger e xgboost);
- roda a aula inteira para conferir.

A instalação pode levar alguns minutos. No fim, deve aparecer:

```
PRONTO: a aula rodou do começo ao fim em XX s.
```

Se aparecer `ERRO ...`, leia a mensagem. Na maioria das vezes basta rodar o comando de novo, porque a falha costuma ser uma queda de conexão durante a instalação.

> 💡 Se o R travar ou reiniciar durante a instalação, pode ter faltado memória. Abra as configurações do projeto (ícone de engrenagem ⚙️ no canto superior direito), vá em **Resources**, aumente a RAM se o seu plano permitir e rode de novo.

### 4. (Opcional) Limpar o que os alunos não precisam

Para deixar o painel **Files** mais limpo, você pode apagar **dentro do Posit Cloud** os arquivos que só servem para o professor. Isso não muda nada no GitHub.

- `tools/`, `tests/`, `docs/`, `posit_cloud/`
- `aula_housing.qmd`, `historico_conversa.md`, `link.txt`

**Não apague** `aula_housing.R`, `aula_housing.html`, `archive.zip` nem o arquivo `.Rprofile`. Ele fica oculto: para vê-lo, use **More > Show Hidden Files** no painel Files.

### 5. Compartilhar por link

1. Abra as configurações do projeto (⚙️) e vá em **Access**.
2. Em **Who can view this project**, escolha **Everyone** (qualquer pessoa com o link).
3. Copie o endereço do projeto na barra do navegador. Esse é o **link da aula**.
4. Cole o link no `roteiro_alunos.md` (ou nos seus slides) e envie para a turma.

### 6. Testar como se fosse um aluno ⚠️ importante

Use **outra conta**: um segundo e-mail, uma conta de monitor ou de um colega. Abra o link numa **janela anônima** e confira:

1. **A cópia funciona:** o projeto abre como **cópia temporária** (*Temporary Copy*) e aparece o botão **Save a Permanent Copy**. Clique nele.
2. **Os pacotes vieram junto:** rode o primeiro bloco do `aula_housing.R`. Ele **não** deve instalar nada; a linha `install.packages(...)` não deve começar a baixar pacotes.
   - Se começar a instalar, a cópia não levou os pacotes. Graças ao `.Rprofile`, a instalação usa pacotes compilados e deve levar poucos minutos, não meia hora. Nesse caso, avise os alunos para rodarem o primeiro bloco **logo no início da aula** e use esse tempo para apresentar o problema da imobiliária.
3. **As horas vão para a conta certa:** na conta de teste, abra o menu do usuário (canto superior direito) e veja **Usage**. O uso da cópia deve aparecer **lá**, e não na sua conta.
4. Rode o script todo na cópia, para garantir que termina sem erros.

---

## No dia da aula

- [ ] O link da aula está no roteiro, nos slides ou no Moodle.
- [ ] Peça aos alunos que **criem a conta antes da aula**, se possível. Isso leva uns 2 minutos.
- [ ] Projete o `roteiro_alunos.md` no início da aula.
- [ ] Lembre a turma de clicar em **Save a Permanent Copy**. Sem isso, o trabalho de cada aluno se perde ao fechar a aba.
- [ ] Projetos parados por um tempo **hibernam**. Se a tela ficar cinza, basta clicar para reconectar. Os objetos podem se perder, e aí é só rodar de novo os blocos anteriores.

## Plano B

- O **`aula_housing.html`** tem todo o código, os gráficos e os resultados, e abre em qualquer navegador, inclusive direto do GitHub. Quem tiver problema acompanha por ele.
- Alunos com problema podem fazer **dupla** com um colega cuja cópia funcionou.

## Para quem mantém este material

- Os testes do script de preparação rodam a partir da raiz do repositório:
  ```bash
  Rscript -e "testthat::test_file('posit_cloud/tests/test_preparar_projeto.R')"
  ```
- Se a lista de pacotes do bloco de setup de `aula_housing.R` mudar, atualize `pacotes_aula` em `preparar_projeto.R`. Um dos testes avisa se as duas listas divergirem.
