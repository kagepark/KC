#!/bin/sh
########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.2.28
# Description :
########################################################################
error_exit() {
   echo "$*"
   exit
}

[ -n "$_K_LIB" ] || error_exit "_K_LIB not found"
#include ktunnel.so
#include knet.so

ssh_opt="-o StrictHostKeychecking=no -o CheckHostIP=no -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null "

#####################################################
# load k.k when run this script
# if run this script by k.k then ignore loading k.k
#####################################################
if ! declare -F _k_k >& /dev/null; then
    source ./k.k
    _k_load_include $0
fi
#####################################################

_k_ssh_help() {
    echo "
$(basename $0) [ -go <dir> ] [<ssh opt>] id@host [<command>]

  -go <dir> : login to id@host and change directory to <dir>
    "
    exit
}

argv=""
argv=( "${@}" )

if [ "${argv[0]}" == "-go" ]; then
    if [ ! -n "${argv[1]}" ]; then
        echo "Need directory name (-cd <dir>)"
        exit
    fi
    change_dir="-t cd \"${argv[1]}\"; bash --login"
    unset argv[0]
    unset argv[1]
    argv=("${argv[@]}")
    if ! echo "${argv[$((${#argv[*]}-1))]}" | grep "@" >& /dev/null; then
         echo "
  ERR: -go option not support extra command"
         _k_ssh_help
    fi
elif [ "${argv[0]}" == "--help" -o "${argv[0]}" == "help" ]; then
    _k_ssh_help
fi

for ((ii=0; ii<${#argv[*]}; ii++)); do
    if echo ${argv[$ii]} | grep "@" >/dev/null; then
       break
    elif echo ${argv[$ii]} | grep "^-" >/dev/null; then
       continue
    fi
    break
done
host_id=$ii


if echo ${argv[$host_id]} | grep "@" >/dev/null; then
    id=$(echo ${argv[$host_id]} | awk -F@ '{print $1}')
    dest=$(echo ${argv[$host_id]} | awk -F@ '{print $2}')
else
    id=$(id -un)
    dest=${argv[$host_id]}
fi


if _k_tunnel_list $dest >/dev/null; then
    _k_tunnel_ssh $*
else
    host_name=$(_k_net_host $dest) || host_name=$dest
    argv[$host_id]="${id}@${host_name}"
    if ssh_key_file=$(_k_find_file ${dest} $_K_ETC/.ssh); then
        ssh_key="-i $ssh_key_file"
    fi
    ssh $ssh_key $ssh_opt ${argv[*]} $change_dir 2>/dev/null || echo "ssh timeout to ${host_name}"
fi
