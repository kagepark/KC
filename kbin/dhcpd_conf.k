KTAG=".k"
[ -n "$_K_DHCP_TAG" ] || _K_DHCP_TAG=cep
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_dhcpd_network() {
    local netmask ip
    ip=$1
    netmask=$2

    bit_count=$(echo $netmask  | sed -e "s/\./ /g" -e "s/0//g" | wc -w)
    network_arr=($(echo $ip| sed "s/\./ /g"))
    network=$( for ((ii=0; ii<4; ii++)); do
        (($ii<$bit_count)) && echo -n "${network_arr[$ii]}" || echo -n 0
        (($ii<3)) && echo -n "."
    done)
    echo "$network"
}

_k_dhcpd_subnet() {
    local network netmask endip
    network=$1
    netmask=$2
    startip=$3
    endip=$4
    gateway=$5

    echo "
subnet $network netmask $netmask {
   range $startip $endip;
   next-server $gateway;
   option routers $gateway;
   option domain-name-servers $gateway;
   filename \"$_K_DHCP_TAG/pxelinux.0\";
}
"

}

# cmd sample
_k_dhcpd_conf() {
   #-g <gateway>
   #-s <network>:<netmask>:<start ip>:<end ip>:<gateway>
   #-h <host file>

   local opt dhcpd_conf gateway subnet hostfile ss hh
   dhcpd_conf=/etc/dhcpd.conf
   ss=0
   hh=0
   opt=($*)
   if (( ${#opt[*]} == 0 )); then
       echo "$(basename $0) -g <gateway> -s <network>:<netmask>:<start ip>:<end ip>:<gateway> -h <hostfile>"
       exit 1
   fi
   for ((ii=0;ii<${#opt[*]};ii++)); do
       if [ "${opt[$ii]}" == "-g" ]; then
          ii=$(($ii+1))
          gateway=${opt[$ii]}
       elif [ "${opt[$ii]}" == "-s" ]; then
          ii=$(($ii+1))
          subnet[$ss]=${opt[$ii]}
          ss=$(($ss+1))
       elif [ "${opt[$ii]}" == "-h" ]; then
          ii=$(($ii+1))
          hostfile[$hh]=${opt[$ii]}
          hh=$(($hh+1))
       fi
   done
   [ -n "$gateway" ] || return 1
   echo "# CEP Cluster Engine DHCP configuration file

ddns-update-style interim;
allow booting;
allow bootp;

class \"pxeclients\" {
   match if substring(option vendor-class-identifier, 0, 9) = \"PXEClient\";
   filename \"$_K_DHCP_TAG/pxelinux.0\";
   option routers $gateway;
   option domain-name-servers $gateway;
}
" 

    for ((jj=0; jj<${#subnet[*]}; jj++)); do
        _k_dhcpd_subnet $(echo ${subnet[$jj]} | sed "s/:/ /g")
    done

    for ((jj=0; jj<${#hostfile[*]}; jj++)); do
        echo "include \"${hostfile[$jj]}\";"
    done
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "dhcpd_conf.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
