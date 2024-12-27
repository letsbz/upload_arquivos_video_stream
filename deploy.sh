#!/bin/bash

PORT="65002"
LOCAL_DIR="/c/dev/Github/upload_arquivos_video_stream/upload_videos_s3_files"
FILTER_PHP="filter.php"
VIDEO_STREAM_PHP="video_stream.php"
AWS_CREDENTIALS_FILE="credenciais_aws.txt"
UPLOAD_LABEL="update_label.php"
LIST_FILE="lista.txt"
COMPOSER_ZIP="composer-vendor.zip"
AWS_ZIP="aws.zip"

# # Mapeamento de arquivos e seus diretórios específicos para implementar as métricas
# declare -A FILES_AND_PATHS
# FILES_AND_PATHS=(
#   ["process.php"]="admin/tool/uploaduser/classes"
#   ["moodlelib.php"]="lib"
#   ["editadvanced.php"]="user"
#   ["externallib.php"]="user"
#   ["lib.php"]="user"
#   ["index.php"]="login"
#   ["locallib.php"]="mod/simplecertificate"
#   ["enrollib.php"]="lib"
# )

# Lista de servidores e usuários
SERVERS=(
  ["u_SERVER@SER.VER.IP"]="u_SERVER"  # Servidor X
)

DOMAINS=("url.com.br")
failed_domains=()

# # Função para processar arquivos específicos em seus diretórios específicos
# process_file() {
#   local REMOTE_BASE_DIR=$1
#   local USER=$2
#   local SERVER=$3
#   local FILE_NAME=$4
#   local FILE_PATH=$5
#   local REMOTE_SPECIFIC_DIR="${REMOTE_BASE_DIR}/${FILE_PATH}"

#   # Verificar se o arquivo local existe antes de prosseguir
#   if [[ -f "${LOCAL_DIR}/${FILE_NAME}" ]]; then
#     # Excluir o arquivo no servidor se existir
#     echo "Excluindo ${FILE_NAME} do servidor ${SERVER} no diretório ${REMOTE_SPECIFIC_DIR}..."
#     ssh -p ${PORT} ${USER}@${SERVER} "
#       rm -f ${REMOTE_SPECIFIC_DIR}/${FILE_NAME}
#     "

#     # Fazer upload do arquivo para o diretório específico
#     echo "Substituindo ${FILE_NAME} no servidor ${SERVER} no diretório ${REMOTE_SPECIFIC_DIR}..."
#     scp -P ${PORT} "${LOCAL_DIR}/${FILE_NAME}" "${USER}@${SERVER}:${REMOTE_SPECIFIC_DIR}/"
#   else
#     echo "Arquivo ${FILE_NAME} não encontrado localmente. Nenhuma ação será realizada."
#   fi
# }

# Função para processar um diretório (ead ou public_html)
process_directory() {
  local REMOTE_DIR=$1
  local USER=$2
  local SERVER=$3

  REMOTE_FILTER_DIR="${REMOTE_DIR}/filter/mediaplugin"
  REMOTE_CONFIG_FILE="${REMOTE_DIR}/config.php"

  # Fazer upload do arquivo compactado aws.zip e descompactá-lo no servidor
  echo "Fazendo upload de ${AWS_ZIP} para ${REMOTE_DIR} no servidor ${SERVER}..."
  scp -P ${PORT} ${LOCAL_DIR}/${AWS_ZIP} ${USER}@${SERVER}:${REMOTE_DIR}/

  echo "Descompactando ${AWS_ZIP} no servidor ${SERVER}..."
  ssh -p ${PORT} ${USER}@${SERVER} "
    unzip -o ${REMOTE_DIR}/${AWS_ZIP} -d ${REMOTE_DIR}/
    rm -f ${REMOTE_DIR}/${AWS_ZIP}
  "

  # Remover arquivos composer.lock, composer.json e a pasta vendor no servidor
  echo "Removendo arquivos composer.lock, composer.json e a pasta vendor do diretório ${REMOTE_DIR} no servidor ${SERVER}..."
  ssh -p ${PORT} ${USER}@${SERVER} "
    rm -f ${REMOTE_DIR}/composer.lock ${REMOTE_DIR}/composer.json
    rm -rf ${REMOTE_DIR}/vendor
  "
  echo "Arquivos composer removidos de ${REMOTE_DIR} no servidor."

  # Fazer upload do arquivo compactado composer-vendor.zip e descompactá-lo no servidor
  echo "Fazendo upload de ${COMPOSER_ZIP} para ${REMOTE_DIR} no servidor ${SERVER}..."
  scp -P ${PORT} ${LOCAL_DIR}/${COMPOSER_ZIP} ${USER}@${SERVER}:${REMOTE_DIR}/
  echo "Arquivo ${COMPOSER_ZIP} enviado para ${REMOTE_DIR} no servidor."

  # Descompactar o arquivo composer-vendor.zip no servidor
  echo "Descompactando ${COMPOSER_ZIP} no servidor ${SERVER}..."
  ssh -p ${PORT} ${USER}@${SERVER} "
    unzip -o ${REMOTE_DIR}/${COMPOSER_ZIP} -d ${REMOTE_DIR}/
    rm -f ${REMOTE_DIR}/${COMPOSER_ZIP}  # Remover o arquivo zip após descompactar
  "
  echo "Arquivo ${COMPOSER_ZIP} descompactado e removido do servidor."

  # Apagar o arquivo filter.php no diretório filter/mediaplugin no servidor, se existir
  if ssh -p ${PORT} ${USER}@${SERVER} "[ -f ${REMOTE_FILTER_DIR}/${FILTER_PHP} ]"; then
    echo "Apagando ${REMOTE_FILTER_DIR}/${FILTER_PHP}..."
    ssh -p ${PORT} ${USER}@${SERVER} "rm -f ${REMOTE_FILTER_DIR}/${FILTER_PHP}"
  else
    echo "Arquivo ${REMOTE_FILTER_DIR}/${FILTER_PHP} não encontrado."
  fi

  # Fazer upload dos arquivos filter.php e video_stream.php para o subdiretório no servidor
  echo "Fazendo upload de ${FILTER_PHP} e ${VIDEO_STREAM_PHP} para ${REMOTE_FILTER_DIR} no servidor ${SERVER}..."
  scp -P ${PORT} ${LOCAL_DIR}/${FILTER_PHP} ${USER}@${SERVER}:${REMOTE_FILTER_DIR}/
  scp -P ${PORT} ${LOCAL_DIR}/${VIDEO_STREAM_PHP} ${USER}@${SERVER}:${REMOTE_FILTER_DIR}/

  echo "Arquivos enviados para ${REMOTE_FILTER_DIR} no servidor."

  # Fazer upload dos arquivos upload_label.php e lista.txt para o diretório raiz no servidor
  echo "Fazendo upload de ${UPLOAD_LABEL} e ${LIST_FILE} para o diretório raiz ${REMOTE_DIR} no servidor ${SERVER}..."
  scp -P ${PORT} ${LOCAL_DIR}/${UPLOAD_LABEL} ${USER}@${SERVER}:${REMOTE_DIR}/
  scp -P ${PORT} ${LOCAL_DIR}/${LIST_FILE} ${USER}@${SERVER}:${REMOTE_DIR}/

  echo "Arquivos enviados para o diretório raiz ${REMOTE_DIR} no servidor."

  # Fazer upload do arquivo de credenciais AWS para o servidor
  echo "Fazendo upload de ${AWS_CREDENTIALS_FILE} para o servidor..."
  scp -P ${PORT} ${LOCAL_DIR}/${AWS_CREDENTIALS_FILE} ${USER}@${SERVER}:${REMOTE_DIR}/

  # Adicionar o conteúdo do arquivo de credenciais ao config.php no servidor
  echo "Adicionando credenciais AWS ao arquivo ${REMOTE_CONFIG_FILE} no servidor..."
  ssh -p ${PORT} ${USER}@${SERVER} "cat ${REMOTE_DIR}/${AWS_CREDENTIALS_FILE} >> ${REMOTE_CONFIG_FILE}"

  echo "Credenciais AWS adicionadas ao ${REMOTE_CONFIG_FILE} no servidor."

  # Executar o script update_label.php no próprio ambiente Moodle no servidor
  echo "Executando ${UPLOAD_LABEL} no próprio ambiente Moodle do servidor ${SERVER}..."
  ssh -p ${PORT} ${USER}@${SERVER} "php ${REMOTE_DIR}/${UPLOAD_LABEL}"
  echo "Script ${UPLOAD_LABEL} executado no ambiente Moodle no servidor ${SERVER}."

  # for FILE_NAME in "${!FILES_AND_PATHS[@]}"; do
  #   FILE_PATH="${FILES_AND_PATHS[$FILE_NAME]}"
  #   echo "Processando ${FILE_NAME} no diretório ${FILE_PATH}..."
  #   process_file "${REMOTE_DIR}" "${USER}" "${SERVER}" "${FILE_NAME}" "${FILE_PATH}"
  # done
}

# Loop sobre todos os domínios
for DOMAIN in "${DOMAINS[@]}"; do
  echo "Iniciando processamento para o domínio ${DOMAIN}..."
  processed_successfully=false

  # Loop sobre todos os servidores para cada domínio
  for SERVER_USER in "${!SERVERS[@]}"; do
    USER="${SERVERS[$SERVER_USER]}"
    SERVER="${SERVER_USER#*@}"
    REMOTE_BASE_DIR="/home/${USER}/domains"
    REMOTE_PUBLIC_HTML="${REMOTE_BASE_DIR}/${DOMAIN}/public_html"
    REMOTE_EAD="${REMOTE_PUBLIC_HTML}/ead"

    echo "Conectando ao servidor ${SERVER} com o usuário ${USER} para o domínio ${DOMAIN}..."

    # Verificar se a pasta ead ou public_html existe no servidor
    if ssh -p ${PORT} ${USER}@${SERVER} "[ -d ${REMOTE_EAD} ]"; then
      echo "Pasta ead encontrada em ${REMOTE_EAD}."
      process_directory "${REMOTE_EAD}" "${USER}" "${SERVER}"
      processed_successfully=true
      break
    elif ssh -p ${PORT} ${USER}@${SERVER} "[ -d ${REMOTE_PUBLIC_HTML} ]"; then
      echo "Pasta ead não encontrada. Processando public_html em ${REMOTE_PUBLIC_HTML}..."
      process_directory "${REMOTE_PUBLIC_HTML}" "${USER}" "${SERVER}"
      processed_successfully=true
      break
    else
      echo "Domínio ${DOMAIN} não encontrado no servidor ${SERVER}. Pulando para o próximo servidor."
    fi
  done

  # Verifica se o domínio não foi processado em nenhum servidor
  if [ "$processed_successfully" = false ]; then
    echo "Domínio ${DOMAIN} não foi processado com sucesso em nenhum servidor."
    failed_domains+=("${DOMAIN}")
  else
    echo "Processamento para o domínio ${DOMAIN} concluído com sucesso em um dos servidores."
  fi
done

echo "Todas as operações foram concluídas."

# Exibir lista de domínios que falharam
if [ ${#failed_domains[@]} -gt 0 ]; then
  echo "Domínios que não foram processados com sucesso:"
  for DOMAIN in "${failed_domains[@]}"; do
    echo "- ${DOMAIN}"
  done
else
  echo "Todos os domínios foram processados com sucesso em pelo menos um servidor."
fi