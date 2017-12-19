#!/bin/bash
# -------------------------------------------------------------------------------------------------
# Proposito:    Realizar a leitura do arquivo de configuração
#               - Durante a execução irá efetuar carregar os valores
# Utilização:   ./script.sh PARM1
# Exemplo:      ./read_cfg.sh migra_mongo.cfg
# script:	      read_cfg.sh
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
# INÍCIO
# -------------------------------------------------------------------------------------------------

log_div "D:"
log_msg "I: INÍCIO - ${SCRIPT_NAME}"
log_div "D:"

log_msg "I: Verificar parametrôs que foram informados:"
log_msg "I: Imprimir parametro: `echo $*`"

QTD_PARM=`echo $* | tr ' ' '\n' | wc -l`
log_msg "I: A quantidade de parametros é igual a: `echo $QTD_PARM`"

if [ $QTD_PARM -eq 1 ]; then
   log_msg "I: Quantidade de parametros de acordo com o esperado - OK"
else
   log_msg "E: Quantidade de parametros diferente do esperado, verificar LOG acima."
    exit 1
fi

log_div "D:"

# -------------------------------------------------------------------------------------------------
# LER ARQUIVO DE ENTRADA E CARREGAR
# -------------------------------------------------------------------------------------------------

log_msg "I: Ler arquivo de entrada: $1"

CHAVES=`cat  ${WORKSPACE}/${1} | egrep --color ^"\[|\]"$ | sed 's/\[//;s/\]//' | tr '\n' ' '`
log_msg "I: As chaves encontradas no arquivo de configuração: $CHAVES"

rm -f ${DIR_TMP}/${1}.tmp
cat -e ${WORKSPACE}/${1} | cut -f1 -d';' | awk -F'=' '{print $1,$2}' | while read R; do
   echo $R | awk '{print $1"=\""$2"\""}' | \
   sed 's/\[//;s/]$=""//g' | grep -v ^"=" | \
   sed 's/$=""/%/g' | tr '\n' ' ' | tr '%' '\n'
done | egrep `echo $CHAVES | tr ' ' '|'`  | sed 's/^ //g' > ${DIR_TMP}/${1}.tmp

rm -f ${DIR_TMP}/${1}.cfg
while read R;
   do ARRAY=(${R})
   COUNT=1
   FIM=`echo ${#ARRAY[@]}`
   log_msg "I: - Chave: ${ARRAY[0]} - Quantidade de elementos: $FIM"
   log_msg "I: -- Valores: ${ARRAY[@]}"
   while [ $COUNT -lt $FIM ]; do
      eval export ${ARRAY[0]}_${ARRAY[${COUNT}]}
      echo export ${ARRAY[0]}_${ARRAY[${COUNT}]} >> ${DIR_TMP}/${1}.cfg
      let COUNT=$COUNT+1
   done
done < ${DIR_TMP}/${1}.tmp

log_msg "I: Efetuado o carregamento das valores as chaves as variaveis"
log_div "D:"

# -------------------------------------------------------------------------------------------------
# CHECK OPERACAO DE CARGA
# -------------------------------------------------------------------------------------------------

log_msg "I: Efetuar a validação do carregamento dos valores nas variaveis correspondentes"

while read R;
   do ARRAY=(${R})
   COUNT=1
   FIM=`echo ${#ARRAY[@]}`
   log_msg "I: ${ARRAY[0]}"
   while [ $COUNT -lt $FIM ]; do
      CHECK=`echo ${ARRAY[0]}_${ARRAY[${COUNT}]} | cut -f1 -d'='`
      RESULTADO=$(eval echo Variavel declarada: $CHECK - Valor: $`echo $CHECK`)
      log_msg "I: - $RESULTADO"
      let COUNT=$COUNT+1
   done
done < ${DIR_TMP}/${1}.tmp

log_msg "I: Efetuado a validação do carregamento"
log_div "D:"

# -------------------------------------------------------------------------------------------------
# FIM
# -------------------------------------------------------------------------------------------------
log_msg "I: FIM - ${SCRIPT_NAME}"
exit 0
