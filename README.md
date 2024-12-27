# Bash para Atualizar Arquivos nos Diretórios do Servidor (Hostinger)

Este projeto contém um script Bash que automatiza o processo de atualização de arquivos em diretórios específicos nos servidores da Hostinger, como os arquivos `filter.php`, `video_stream.php` e um arquivo de credenciais AWS. O script percorre vários servidores e faz as atualizações automaticamente.

## Estrutura e Funcionalidades do Script

O script realiza uma série de operações para configurar e atualizar os servidores:

1. **Upload e Extração de Arquivos**:
   - Faz upload dos pacotes `aws.zip` e `composer-vendor.zip` para o diretório remoto e descompacta no servidor, substituindo o conteúdo antigo.

2. **Remoção de Arquivos Antigos**:
   - Remove `composer.lock`, `composer.json` e a pasta `vendor` para garantir que o ambiente Composer no servidor seja atualizado corretamente.

3. **Processamento de Diretórios Específicos**:
   - Verifica a existência do diretório `ead`; caso ele não exista, processa o diretório `public_html`.

4. **Upload e Configuração de Arquivos PHP**:
   - Substitui arquivos específicos nos diretórios correspondentes, conforme definido na variável `FILES_AND_PATHS`, que inclui arquivos críticos para o ambiente Moodle, como `process.php`, `moodlelib.php` e outros.

5. **Execução Remota de Script**:
   - Executa remotamente o script `update_label.php` no servidor para aplicar atualizações no ambiente Moodle.

6. **Relatório de Sucesso e Falha**:
   - Monitora e exibe um relatório indicando quais domínios foram processados com sucesso e quais falharam.

## Arquivos Manipulados

Aqui estão os principais arquivos manipulados pelo script e seus diretórios no servidor:

- **Arquivos de Configuração e Integração de Mídia**:
  - `filter.php` e `video_stream.php`: Arquivos de configuração de mídia que são substituídos no servidor para garantir que as integrações de vídeo estejam corretas.

- **Credenciais AWS**:
  - `credenciais_aws.txt`: Arquivo que contém as credenciais AWS, anexado ao `config.php` do servidor.

- **Scripts de Atualização e Listas de IDs**:
  - `update_label.php` e `lista.txt`: Script PHP e lista de IDs para atualização de etiquetas, enviados e executados no servidor para atualizações de conteúdo.

- **Pacotes Composer e AWS**:
  - `composer-vendor.zip`: Arquivo com dependências do Composer para o ambiente PHP.
  - `aws.zip`: Pacote de integração AWS, atualizado no servidor.

- **Arquivos Moodle para Métricas e Configuração**:
  - Abaixo estão os arquivos manipulados para o Moodle, definidos na variável `FILES_AND_PATHS` do script:
    - `process.php`: Localizado em `admin/tool/uploaduser/classes`
    - `moodlelib.php`: Localizado em `lib`
    - `editadvanced.php`: Localizado em `user`
    - `externallib.php`: Localizado em `user`
    - `lib.php`: Localizado em `user`
    - `index.php`: Localizado em `login`
    - `locallib.php`: Localizado em `mod/simplecertificate`
    - `enrollib.php`: Localizado em `lib`

Esses arquivos precisam estar no diretório local definido na variável `LOCAL_DIR` do script.

## Pré-requisitos

Antes de rodar o script Bash, é necessário configurar o acesso SSH para cada servidor da Hostinger. Abaixo estão os passos detalhados para configurar o SSH, adicionar sua chave pública aos servidores e preparar o ambiente para rodar o script.

## Passo a Passo

### 1. Gerando as Chaves SSH

Se você ainda não tem uma chave SSH gerada, siga os passos abaixo para criar uma:

1. **Abra o terminal Bash** (no Linux ou Mac) ou o **Git Bash** (no Windows).
2. Execute o comando para gerar uma nova chave SSH:

   ```bash
   ssh-keygen -t rsa -b 4096 -C "seu_email@example.com"
   ```

   - O parâmetro `-t rsa` especifica o tipo de chave (RSA).
   - `-b 4096` define o tamanho da chave (4096 bits).
   - `-C "seu_email@example.com"` adiciona um comentário à chave, útil para identificação.

3. Quando solicitado, forneça um nome para a chave e um diretório onde ela será armazenada (ou pressione `Enter` para aceitar o caminho padrão `~/.ssh/id_rsa`).
4. Quando perguntado, você pode deixar a senha em branco, pressionando `Enter`, ou definir uma senha para mais segurança.

Após gerar a chave, você terá dois arquivos:

- **Chave privada**: Geralmente chamada de `id_rsa`. **Não compartilhe este arquivo com ninguém.**
- **Chave pública**: Geralmente chamada de `id_rsa.pub`. Esta é a chave que você vai adicionar ao servidor.

### 2. Configuração de Permissões da Chave Privada (chmod 600)

As permissões da chave privada precisam ser configuradas corretamente para que o SSH funcione. Isso é fundamental, pois o SSH exige que apenas o dono do arquivo tenha acesso à chave privada.

#### Passos para ajustar as permissões:

1. No terminal Bash, execute o seguinte comando para definir as permissões corretas para a chave privada:

   ```bash
   chmod 600 ~/.ssh/id_rsa
   ```

   Esse comando garante que apenas o dono do arquivo tenha permissão de leitura e escrita (o que é necessário para o SSH).

### 3. Adicionar a Chave Pública ao Servidor

Agora que você configurou sua chave SSH, o próximo passo é adicionar a chave pública ao servidor onde você deseja se conectar.

#### Passos para adicionar a chave pública ao servidor:

1. **Copie a chave pública (`id_rsa.pub`) para o servidor remoto**. Para isso, use o comando `ssh-copy-id`:

   ```bash
   ssh-copy-id -i ~/.ssh/id_rsa.pub -p 65002 usuario@ip_do_servidor
   ```

   - **`-i ~/.ssh/id_rsa.pub`**: Especifica o arquivo da chave pública.
   - **`-p 65002`**: Define a porta SSH usada pelo servidor (verifique a porta correta para o seu servidor).
   - **`usuario@ip_do_servidor`**: Substitua pelo usuário e IP do servidor na Hostinger.

2. Depois de rodar este comando, a chave pública será adicionada ao servidor, permitindo o login sem senha (utilizando a chave privada).

3. Caso não funcione, basta acessar o servidor pela interface da Hostinger e adicionar a chave ssh manualmente.

### 4. Ajustes no Script Bash

1. **Verificar o Caminho dos Arquivos**:
   - Verifique se o caminho dos arquivos locais no script corresponde ao diretório onde eles estão salvos no seu computador. Ajuste a variável `LOCAL_DIR` conforme necessário.

2. **Verifique as credenciais no arquivo credenciais_aws.txt**
   - Confirme se as credenciais foram devidamente colocadas no arquivo `credenciais_aws.txt` --> para montá-lo basta criar um arquivo com esse nome tendo como base o arquivo `credenciais_aws example.txt`

### 5. Executar o Script Bash

Após configurar os servidores e ajustar o script, você pode rodar o script diretamente no terminal Bash para atualizar os arquivos nos diretórios remotos de cada servidor.

#### Para rodar o script:

1. **Navegue até o diretório onde o script Bash está salvo**, usando o terminal Bash. Por exemplo:

   ```bash
   cd /caminho/para/seu/script/
   ```

2. **Dê permissão de execução ao script** para garantir que ele possa ser executado. Execute o comando:

   ```bash
   chmod +x deploy.sh
   ```

3. **Execute o script com o seguinte comando**:

   ```bash
   bash deploy.sh
   ```

   O script percorrerá todos os servidores listados, atualizando os arquivos e adicionando as credenciais AWS aos diretórios especificados.
