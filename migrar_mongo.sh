#!/bin/bash
# -------------------------------------------------------------------------------------------------
# Proposito:    Realizar a leitura de uma base de dados mongo,
#                criar um container dokcer e realizar a migraç˜o
#
# Utilização:   ./script.sh PARM1
# Exemplo:      ./migrar_mongo.sh migra_mongo.cfg
# script:	      migrar_mongo.sh
# autor:        William Santos
# data:         2017-12-15
# -------------------------------------------------------------------------------------------------
# VARIAVEIS DE AMBIENTE
# -------------------------------------------------------------------------------------------------

DT_LOG=`date '+%Y%m%d%H%M%S'`
SCRIPT_NAME=`basename $0`
WORKSPACE=`pwd`
DIR_DMP="${WORKSPACE}/DMP"
DIR_LOG="${WORKSPACE}/LOG"
DIR_TMP="${WORKSPACE}/TMP"
mkdir -p $DIR_DMP $DIR_LOG $DIR_TMP
LOGFILE=${WORKSPACE}/LOG/${DT_LOG}_${SCRIPT_NAME%.sh}.log
SERVER=`uname -a | cut -d' ' -f2 | cut -f1 -d'.'`
DIA=`date '+%Y%m%d'`
DATE=`date '+%Y%m%d%H%M%S'`

# -------------------------------------------------------------------------------------------------
# CARREGAR FUNÇÕES
# -------------------------------------------------------------------------------------------------

source ${WORKSPACE}/function.sh

# -------------------------------------------------------------------------------------------------
# INICIO
# -------------------------------------------------------------------------------------------------

log_div "D:"
log_msg "I: INÍCIO - ${SCRIPT_NAME}"
log_msg "I: Utilizar o script: read_cfg.sh - para carregar aquivo cfg"

bash ${WORKSPACE}/read_cfg.sh ${1}
source ${DIR_TMP}/${1}.cfg

# -------------------------------------------------------------------------------------------------
# VERIFICAR SE CONTAINER ESTA EM EXECUÇÃO - SE ESTIVER REMOVER
# -------------------------------------------------------------------------------------------------

log_div "D:"
CONTAINER_NAME=`cat ${WORKSPACE}/mongo.yml | grep container_name | cut -f2 -d':'`
QTD_CONTAINER_PID=`docker ps | egrep --color "mongo_clone"$ | awk '{print $1}' | wc -l`
if [ $QTD_CONTAINER_PID -eq 1 ]; then
   {
     CONTAINER_PID=`docker ps | egrep --color "mongo_clone"$ | awk '{print $1}'`
     log_msg "I: Container: $CONTAINER_NAME existente e será finalizado"

     rm -f ${DIR_TMP}/arquivo.tmp
     docker stop $CONTAINER_PID > ${DIR_TMP}/arquivo.tmp 2> ${DIR_TMP}/arquivo.tmp
     cat ${DIR_TMP}/arquivo.tmp | while read LIN; do log_msg "I: - stop id: $LIN" ; done

     rm -f ${DIR_TMP}/arquivo.tmp
     docker rm $CONTAINER_PID > ${DIR_TMP}/arquivo.tmp 2> ${DIR_TMP}/arquivo.tmp
     cat ${DIR_TMP}/arquivo.tmp | while read LIN; do log_msg "I: - rm id: $LIN" ; done

     log_msg "I: Efetuada a remoção"
     log_div "D:"
   }
fi

# -------------------------------------------------------------------------------------------------
# LIMPAR DIRETÓRIO QUE SERÁ UTILIZADO PARA MAPEAR VOLUME DO CONTAINER
# -------------------------------------------------------------------------------------------------

log_msg "I: Será definido um novo diretório para receber volume do container que será montado"
rm -rf ${WORKSPACE}/DB
mkdir -p ${WORKSPACE}/DB
log_msg "I: Definido diretório local: ${WORKSPACE}/DB"
log_div "D:"

# -------------------------------------------------------------------------------------------------
# PROVISIONAR CONTAINER
# -------------------------------------------------------------------------------------------------

log_msg "I: Provisionar Container:"
rm -f ${DIR_TMP}/arquivo.tmp
docker-compose -f ${WORKSPACE}/mongo.yml up -d > ${DIR_TMP}/arquivo.tmp 2> ${DIR_TMP}/arquivo.tmp
cat ${DIR_TMP}/arquivo.tmp | while read LIN; do log_msg "I: - $LIN" ; done

QTD_CONTAINER_PID=`docker ps | egrep --color "mongo_clone"$ | awk '{print $1}' | wc -l`
if [ $QTD_CONTAINER_PID -eq 1 ]; then
   {
      log_msg "I: CMD: docker ps:"
      log_div "D:"
      docker ps | while read LIN; do log_msg "I: $LIN" ; done
      log_div "D:"
   }
else
   {
      log_msg "E: Falha na ininialização do container - VERIFICAR"
      exit 1
   }
fi

log_msg "I: Comando que será executado a partir do container: $CONTAINER_NAME"
log_msg "I: CMD: mongodump --host $MONGODB_ORIGEN_HOST -d $MONGODB_ORIGEN_DBNM --port $MONGODB_ORIGEN_PORT --username $MONGODB_ORIGEN_USER --password $MONGODB_ORIGEN_PASS --out \"${MONGODB_DESTINO_DUMP}\""

docker exec -it $CONTAINER_NAME bash -c "mongodump --host $MONGODB_ORIGEN_HOST -d $MONGODB_ORIGEN_DBNM --port $MONGODB_ORIGEN_PORT --username $MONGODB_ORIGEN_USER --password $MONGODB_ORIGEN_PASS --out \"${MONGODB_DESTINO_DUMP}\"" > ${DIR_TMP}/arquivo.tmp 2> ${DIR_TMP}/arquivo.tmp

cat ${DIR_TMP}/arquivo.tmp | while read LIN; do log_msg "I: - $LIN" ; done
log_msg "I: Realizado DUMP para o diretório: \"${DIR_DMP}\" que corresponde o volume mapeadado no container, diretório: \"/data/dump\""
log_div "D:"

# -------------------------------------------------------------------------------------------------
# LISTAR SAIDA
# -------------------------------------------------------------------------------------------------

log_msg "I: Inspecionar a saída diretamente no diretório: ${DIR_DMP}:"
log_msg "I: CMD: ls -lrt \"${DIR_DMP}\""
ls -lrt ${DIR_DMP}/${MONGODB_ORIGEN_DBNM} > ${DIR_TMP}/arquivo.tmp 2> ${DIR_TMP}/arquivo.tmp
cat ${DIR_TMP}/arquivo.tmp | while read LIN; do log_msg "I: - $LIN" ; done
log_div "D:"

# -------------------------------------------------------------------------------------------------
# RESTORE
# -------------------------------------------------------------------------------------------------

log_msg "I: Comando que será executado a partir do container: $CONTAINER_NAME"
log_msg "I: CMD: docker exec $CONTAINER_NAME bach -c \"mongorestore ${MONGODB_DESTINO_DUMP}\""
#mongoimport --host ds011241.mlab.com -d p0c --port 11241 --username mongo_poc --password Mongo_123 --collection restaurants --drop --file primer-dataset.json
docker exec $CONTAINER_NAME bash -c "mongorestore ${MONGODB_DESTINO_DUMP}" > ${DIR_TMP}/arquivo.tmp 2> ${DIR_TMP}/arquivo.tmp
cat ${DIR_TMP}/arquivo.tmp | while read LIN; do log_msg "I: - $LIN" ; done
log_div "D:"

# -------------------------------------------------------------------------------------------------
# CRIAR USUÁRIO
# -------------------------------------------------------------------------------------------------

log_msg "I: Criar arquivo de configuração para criar usuário e conceder os acessos para o DB: $MONGODB_DESTINO_DBNM"
log_msg "I: Definir o arquivo JSON, contendo o acesso ao usuário do mongoDB:"
cat << EOF > ${WORKSPACE}/create_user_mongo.json
use ${MONGODB_ORIGEN_DBNM}
db.createUser(
   {
      user: "${MONGODB_DESTINO_PASS}",
      pwd: "${MONGODB_DESTINO_PASS}",
      roles: [ "readWrite", "dbAdmin" ]
   }
)
EOF
log_msg "I: Definir o arquivo JSON, contendo o acesso ao usuário do mongoDB:"
cat ${WORKSPACE}/create_user_mongo.json | while read LIN; do log_msg "I: - $LIN" ; done
log_msg "I: Realizar a ação no DB: $MONGODB_DESTINO_DBNM"

docker exec -d $CONTAINER_NAME touch /root/.dbshell
docker exec -it $CONTAINER_NAME bash -c "mongo < /data/configdb/create_user_mongo.json" > ${DIR_TMP}/arquivo.tmp 2> ${DIR_TMP}/arquivo.tmp
cat ${DIR_TMP}/arquivo.tmp | while read LIN; do log_msg "I: - $LIN" ; done
log_div "D:"

# -------------------------------------------------------------------------------------------------
# FIM
# -------------------------------------------------------------------------------------------------

log_msg "I: FIM - ${SCRIPT_NAME}"
log_div "D:"

# -------------------------------------------------------------------------------------------------
exit 0
