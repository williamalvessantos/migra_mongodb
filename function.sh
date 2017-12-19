#!/bin/bash

# -------------------------------------------------------------------------------------------------
# FUNÇÕES
# -------------------------------------------------------------------------------------------------

# Função de escrita no log
function log_msg(){
  CURR_DT="`date +'%Y%m%d %H:%M:%S'`"
  echo "$CURR_DT - $*" | tee -a $LOGFILE 1>&2
}

# Função de marcação e divisão de escrita no log
function log_div(){
   CURR_DT="`date +'%Y%m%d %H:%M:%S'`"
   DIV=`printf "%0100d\n" | tr '0' '-'`
   echo "$CURR_DT - $*" "$DIV" | tee -a $LOGFILE 1>&2
}
