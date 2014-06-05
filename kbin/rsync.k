#!/bin/sh
########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.2.34
# Description :
########################################################################

argv=( $* )
argc=${#argv[*]}

for ((ii=0; ii<${#argv[*]}; ii++)); do
    if echo ${argv[$ii]} | grep "@" |grep ":" >/dev/null; then
       break
    elif echo ${argv[$ii]} | grep "^-" >/dev/null; then
       continue
    else
       echo ${argv[$ii]} | grep ":" >/dev/null && break
    fi
done
host_id=$ii


if echo ${argv[$host_id]} | grep "@" >/dev/null; then
    id=$(echo ${argv[$host_id]} | awk -F@ '{print $1}')
    dest=$(echo ${argv[$host_id]} | awk -F@ '{print $2}' | awk -F: '{print $1}')
    echo ${argv[$host_id]} | grep ":" >& /dev/null ||  error_exit "$(basename $0) <source> <dest>,  hostname need \":\""
    dest_path=$(echo ${argv[$host_id]} | awk -F: '{print $2}')
else
    id=$(id -un)
    dest=$(echo ${argv[$host_id]} | awk -F: '{print $1}')
    echo ${argv[$host_id]} | grep ":" >& /dev/null ||  error_exit "$(basename $0) <source> <dest>,  hostname need \":\""
    dest_path=$(echo ${argv[$host_id]} | awk -F: '{print $2}')
fi

if [ "$host_id" == "$(($argc-1))" ]; then
        if [ "${argv[argc-2]}" == "%same%" -o "${argv[argc-2]}" == "%both%" ]; then
              [ "${argv[argc-2]}" == "%both%" ] && sync_mode=both
              argv[argc-2]=$(pwd)/                           # source
              dest_path=$(echo $(pwd)/ | sed "s#$HOME/##g")  # dest
        fi
else
        [ "${argv[argc-1]}" == "%both%" ] && error_exit "$(basename $0) %both% id@host:"
        if [ "${argv[argc-1]}" == "%same%" ]; then
              argv[argc-1]=$(pwd)/                           # dest
              dest_path=$(echo $(pwd)/ | sed "s#$HOME/##g")  # source
        fi
fi


#comming soone
#if k _k_tunnel_list $dest >/dev/null; then
#    k _k_tunnel_ssh $*
#else

#include knet.so

    host_name=$(k net_host $dest) || host_name=$dest
    argv[$host_id]="${id}@${host_name}:$dest_path"

    sync_opt="-a --progress"
    ssh_opt="-o StrictHostKeychecking=no -o CheckHostIP=no -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null "

    if ssh_key_file=$(_k_find_file ${dest} $_K_ETC/.ssh); then
        ssh_key="-i $ssh_key_file "
    fi

    echo "rsync -e \"ssh $ssh_opt $ssh_key -p 22\" $sync_opt ${argv[*]}"
    rsync -e "ssh $ssh_opt $ssh_key -p 22" $sync_opt ${argv[*]}  2>/dev/null  
#    if [ -n "$ssh_key" ]; then
#          echo "rsync -e ssh $ssh_key -p 22 $sync_opt ${argv[*]}"
#          rsync -e "ssh $ssh_key -p 22" $sync_opt ${argv[*]}  2>/dev/null  
#    else
#          echo "rsync $sync_opt ${argv[*]}"
#          rsync $sync_opt ${argv[*]}  2>/dev/null
#    fi
    if [ "$sync_mode" == "both" ]; then
        tmp=${argv[argc-2]}
        argv[argc-2]=${argv[argc-1]}
        argv[argc-1]=$tmp
        echo "rsync -e \"ssh $ssh_opt $ssh_key -p 22\" $sync_opt ${argv[*]}"
        rsync -e "ssh $ssh_opt $ssh_key -p 22" $sync_opt ${argv[*]}  2>/dev/null  
#        if [ -n "$ssh_key" ]; then
#          echo "rsync -e ssh $ssh_key -p 22 $sync_opt ${argv[*]}"
#          rsync -e "ssh $ssh_key -p 22" $sync_opt ${argv[*]}  2>/dev/null
#        else
#          echo "rsync $sync_opt ${argv[*]}"
#          rsync $sync_opt ${argv[*]} 2>/dev/null 
#        fi
    fi
#fi
