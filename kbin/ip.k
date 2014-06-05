########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.10
# Description : fix bug
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include is.k

_k_ip_help() {
  echo "$(basename $0) [<opt> [<input>] ]

  --help : help
  -n <ip> : convert IP to number
  -i <num> : convert number to IP
  -a <ip> <num> : add number to IP
  -d <ip> <num> : take away the number from IP
  -m <ip> <netmask> : make a network using netmask(ex:255.255.0.0)
  -b <netmask>  : convert netmask to bit
  "
  exit
}

# base starting sample
_k_ip() {
   local cmd rcmd opt ip
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F _k_${name}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_ip_help
       exit 0
   elif ip=$(_k_opt -n 1 0 "${opt[@]}"); then
      _k_ip_num2ip $ip || return 1
   elif ip=$(_k_opt -i 1 0 "${opt[@]}"); then
      _k_ip_ip2num $ip || return 1
   elif ip=$(_k_opt -a 1 0 "${opt[@]}"); then
      _k_ip_add $ip || return 1
   elif ip=$(_k_opt -d 1 0 "${opt[@]}"); then
      _k_ip_del $ip || return 1
   elif ip=$(_k_opt -m 1 0 "${opt[@]}"); then
      _k_ip_network $ip || return 1
   elif ip=$(_k_opt -b 1 0 "${opt[@]}"); then
      _k_ip_netmask2bit $ip || return 1
   else
      #<command> $opt
      echo "Unknown option"
      exit 1
   fi
}

_k_ip_ip2num() {
    local ip
    _k_is_ip $1 || return 1
    ip=( $(echo $1 | sed 's/\./ /g') )
    echo $(( $((256*256*256*${ip[0]})) + $((256*256*${ip[1]})) + $((256*${ip[2]})) +${ip[3]} ))
}

_k_ip_num2ip() {
    local num
    num=$1
    _k_is_int $num || return 1
    echo $(( $(( $num/(256*256*256) ))% 256)).$(( $(($num/(256*256) ))%256)).$(( $(($num/256)) % 256)).$(($num%256))
}

_k_ip_add() {
    local ip num
    ip=$1
    num=$2
    _k_is_ip $ip || return 1
    _k_is_int $num || return 1
    _k_num2ip $(( $(_k_ip_ip2num $ip) + $num )) || return 1
}

_k_ip_del() {
    local ip num
    ip=$1
    num=$2
    _k_is_ip $ip || return 1
    _k_is_int $num || return 1
    _k_num2ip $(( $(_k_ip_ip2num $ip) - $num )) || return 1
}

_k_ip_network() {
    local netmask ip network_arr
    ip=$1
    netmask=$2
    _k_is_ip $ip || return 1
    _k_is_ip $netmask || return 1

    bit_count=$(echo $netmask  | sed -e "s/\./ /g" -e "s/0//g" | wc -w)
    network_arr=($(echo $ip| sed "s/\./ /g"))
    network=$( for ((ii=0; ii<4; ii++)); do
        (($ii<$bit_count)) && echo -n "${network_arr[$ii]}" || echo -n 0
        (($ii<3)) && echo -n "."
    done)
    echo $network
}

_k_ip_netmask2bit() {
    local netmask ip network_arr
    netmask=$1
    [ -n "$netmask" ] || return 1
    _k_is_ip $netmask || return 1
    bit_count=$(echo $netmask  | sed -e "s/\./ /g" -e "s/0//g" | wc -w)
    echo $(($bit_count * 8 ))
    return 0
}

#_k_ip_make_temp () {
#}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "ip.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
