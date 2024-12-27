#!/bin/bash

PORT="65002"
LOCAL_DIR="/c/dev/Github/dev-tools/upload_arquivos_video_stream/upload_videos_s3_files"
UPDATE_SCRIPT="update_label.php"
LIST_FILE="lista.txt"

# Lista de servidores e usuários
declare -A SERVERS
SERVERS=(
  ["u_SERVER@SER.VER.IP"]="u_SERVER"  # Servidor X
)

DOMAINS=("url.com.br")

failed_domains=()

# Lista de domínios que não foram processados com sucesso em nenhum servidor
failed_domains=()

# Função para processar um diretório (ead ou public_html)
process_directory() {
  local REMOTE_DIR=$1
  local USER=$2
  local SERVER=$3

  # Verificar se os arquivos locais existem antes de prosseguir
  if [[ -f "${LOCAL_DIR}/${UPDATE_SCRIPT}" && -f "${LOCAL_DIR}/${LIST_FILE}" ]]; then

    # Excluir arquivos no servidor se existirem
    echo "Excluindo ${UPDATE_SCRIPT} e ${LIST_FILE} do servidor ${SERVER}..."
    ssh -p ${PORT} ${USER}@${SERVER} "
      rm -f ${REMOTE_DIR}/${UPDATE_SCRIPT} ${REMOTE_DIR}/${LIST_FILE}
    "

    # Fazer upload dos arquivos
    echo "Substituindo ${UPDATE_SCRIPT} e ${LIST_FILE} no servidor ${SERVER}..."
    scp -P ${PORT} ${LOCAL_DIR}/${UPDATE_SCRIPT} ${USER}@${SERVER}:${REMOTE_DIR}/
    scp -P ${PORT} ${LOCAL_DIR}/${LIST_FILE} ${USER}@${SERVER}:${REMOTE_DIR}/

    # Executar o script update_label.php
    echo "Executando ${UPDATE_SCRIPT} no servidor ${SERVER}..."
    ssh -p ${PORT} ${USER}@${SERVER} "php ${REMOTE_DIR}/${UPDATE_SCRIPT}"

  else
    echo "Arquivos ${UPDATE_SCRIPT} e/ou ${LIST_FILE} não encontrados localmente. Nenhuma ação será realizada."
  fi
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