#!/bin/bash

PORT="65002"
LOCAL_DIR="/c/dev/Github/dev-tools/upload_arquivos_video_stream/upload_videos_s3_files"
VIDEO_STREAM_FILE="video_stream.php"

# Lista de servidores e usuários
declare -A SERVERS
SERVERS=(
  ["u_SERVER@SER.VER.IP"]="u_SERVER"  # Servidor X
)

DOMAINS=("url.com.br")

failed_domains=()

# Função para processar um diretório (ead ou public_html)
process_directory() {
  local REMOTE_DIR=$1
  local USER=$2
  local SERVER=$3

  REMOTE_FILTER_DIR="${REMOTE_DIR}/filter/mediaplugin"
  REMOTE_CONFIG_FILE="${REMOTE_DIR}/config.php"

  # Remover arquivos composer.lock, composer.json e a pasta vendor no servidor
  echo "Removendo videostream do diretório ${REMOTE_DIR} no servidor ${SERVER}..."
  ssh -p ${PORT} ${USER}@${SERVER} "rm -f ${REMOTE_FILTER_DIR}/${VIDEO_STREAM_FILE}
  "
  echo "Arquivos aws removidos de ${REMOTE_DIR} no servidor."

  # Fazer upload do arquivo compactado aws.zip e descompactá-lo no servidor
  echo "Fazendo upload de ${VIDEO_STREAM_FILE} para ${REMOTE_FILTER_DIR} no servidor ${SERVER}..."
  scp -P ${PORT} ${LOCAL_DIR}/${VIDEO_STREAM_FILE} ${USER}@${SERVER}:${REMOTE_FILTER_DIR}/
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