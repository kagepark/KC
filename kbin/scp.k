#!/bin/sh

argv=( $* )
argc=${#argv[*]}
sync_opt="-o StrictHostKeychecking=no -o CheckHostIP=no -o ConnectTimeout=3 -o UserKnownHostsFile=/dev/null"

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
    dest_path=$(echo ${argv[$host_id]} | awk -F: '{print $2}')
else
    id=$(id -un)
    dest=$(echo ${argv[$host_id]} | awk -F: '{print $1}')
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

#[ -n "$dest_path" ] || error_exit "$(basename $0) <source> <dest>,  hostname need \":\""

#comming soone
#if k tunnel_list $dest >/dev/null; then
#    k tunnel_ssh $*
#else

#include knet.so
    host_name=$(k net_host $dest)
    argv[$host_id]="${id}@${host_name}:$dest_path"
    echo "scp $sync_opt ${argv[*]}"
    if ssh_key_file=$(_k_find_file ${dest} $_K_ETC/.ssh); then
        ssh_key="-i $ssh_key_file"
    fi
    scp $ssh_key $sync_opt ${argv[*]}
    if [ "$sync_mode" == "both" ]; then
        tmp=${argv[argc-2]}
        argv[argc-2]=${argv[argc-1]}
        argv[argc-1]=$tmp
        echo "scp $sync_opt ${argv[*]}"
        scp $ssh_key $sync_opt ${argv[*]}
    fi
#fi
