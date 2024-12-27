#!/bin/bash

PORT="65002"
LOCAL_DIR="/c/dev/Github/dev-tools/upload_arquivos_video_stream/metricas_cloudwatch"

# Mapeamento de arquivos e seus diretórios específicos
declare -A FILES_AND_PATHS
FILES_AND_PATHS=(
  ["process.php"]="admin/tool/uploaduser/classes"
  ["moodlelib.php"]="lib"
  ["editadvanced.php"]="user"
  ["externallib.php"]="user"
  ["lib.php"]="user"
  ["index.php"]="login"
  ["locallib.php"]="mod/simplecertificate"
  ["enrollib.php"]="lib"
)

# Lista de servidores e usuários
declare -A SERVERS
SERVERS=(
  ["u_SERVER@SER.VER.IP"]="u_SERVER"  # Servidor X
)

DOMAINS=("url.com.br")

failed_domains=()

# Função para processar arquivos específicos em seus diretórios específicos
process_file() {
  local REMOTE_BASE_DIR=$1
  local USER=$2
  local SERVER=$3
  local FILE_NAME=$4
  local FILE_PATH=$5
  local REMOTE_SPECIFIC_DIR="${REMOTE_BASE_DIR}/${FILE_PATH}"

  # Verificar se o arquivo local existe antes de prosseguir
  if [[ -f "${LOCAL_DIR}/${FILE_NAME}" ]]; then
    # Excluir o arquivo no servidor se existir
    echo "Excluindo ${FILE_NAME} do servidor ${SERVER} no diretório ${REMOTE_SPECIFIC_DIR}..."
    ssh -p ${PORT} ${USER}@${SERVER} "
      rm -f ${REMOTE_SPECIFIC_DIR}/${FILE_NAME}
    "

    # Fazer upload do arquivo para o diretório específico
    echo "Substituindo ${FILE_NAME} no servidor ${SERVER} no diretório ${REMOTE_SPECIFIC_DIR}..."
    scp -P ${PORT} "${LOCAL_DIR}/${FILE_NAME}" "${USER}@${SERVER}:${REMOTE_SPECIFIC_DIR}/"
  else
    echo "Arquivo ${FILE_NAME} não encontrado localmente. Nenhuma ação será realizada."
  fi
}

# Função para iterar sobre todos os arquivos mapeados e processá-los
process_directory() {
  local REMOTE_DIR=$1
  local USER=$2
  local SERVER=$3

  for FILE_NAME in "${!FILES_AND_PATHS[@]}"; do
    FILE_PATH="${FILES_AND_PATHS[$FILE_NAME]}"
    echo "Processando ${FILE_NAME} no diretório ${FILE_PATH}..."
    process_file "${REMOTE_DIR}" "${USER}" "${SERVER}" "${FILE_NAME}" "${FILE_PATH}"
  done
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
    REMOTE_EAD="${REMOTE_PUBLIC_HTML}/cursos"

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