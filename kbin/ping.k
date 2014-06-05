#!/bin/sh
error_exit() {
   echo "$*"
   exit
}

argv=( "$@" )

dest=$(_k_opt_end 1 "${argv[@]}")
unset argv[$((${#argv[@]}-1))]
argv=("${argv[@]}")

#include knet.so
host_name=$(k net_host "$dest") || host_name="$dest"

ping ${argv[@]} "$host_name"
