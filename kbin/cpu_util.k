########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.3
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_cpu_util_help() {
  echo "$(basename $0) [<opt> [<input>] ]

  --help : help
  -h <hostname> : check <hostname>'s cpu util
  <none>        : local computer
  "
  exit
}

# base starting sample
# _k_opt <define option> "<input option>" [<special>] [<ro>]
#   all      : get whole value between option (start -)
#   #        : get values of # after finded option (default 1)
#   -#       : get whole values without last -#
#  ro=0      : return <value> (default)
#  ro=1      : return <remained opt>
#  ro=2      : return <value>|<remained opt>

_k_cpu_util() {
   local cmd rcmd opt
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F _k_${name}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_cpu_util_help
       exit 0
   elif _hosts=$(_k_opt -h all 0 "${opt[@]}"); then
      _k_cpu_util_ssh $_hosts || return 1
   else
printf "%10s %5s %5s %5s %5s %5s %10s %10s %10s %10s %10s %10s\n" hostname user sys nice idle Run used\(M\) free\(M\) shared\(M\) buffers\(M\) cached\(M\) total\(M\)
printf "%10s:" "$(hostname)"
fcpul=( $(cat /proc/stat) )
sleep 0.2
lcpul=( $(cat /proc/stat) )
user=`expr ${lcpul[1]} - ${fcpul[1]}`
nice=`expr ${lcpul[2]} - ${fcpul[2]}`
system=`expr ${lcpul[3]} - ${fcpul[3]}`
idle=`expr ${lcpul[4]} - ${fcpul[4]}`
iowait=`expr ${lcpul[5]} - ${fcpul[5]}`
irq=`expr ${lcpul[6]} - ${fcpul[6]}`
softirq=`expr ${lcpul[7]} - ${fcpul[7]}`
steal=`expr ${lcpul[8]} - ${fcpul[8]}`

total=`expr $user + $nice + $system + $idle + $iowait + $irq + $softirq + $steal`
aa=100
r_idle=`echo "$idle * $aa / $total" | bc`
r_sys=`echo "$system * $aa / $total" | bc`
r_nice=`echo "$nice * $aa / $total" | bc`
r_user=`echo "$user * $aa / $total" | bc`

mem=( $(free|grep Mem) )
run=( $(cat /proc/stat |grep procs_running) )

(printf "%5s %5s %5s %5s %5s %10s %10s %10s %10s %10s %10s\n" $r_user $r_sys $r_nice $r_idle ${run[1]} `expr ${mem[2]} / 1024 `  `expr ${mem[3]} / 1024` `expr ${mem[4]} / 1024` `expr ${mem[5]} / 1024` `expr ${mem[6]} / 1024` `expr ${mem[1]} / 1024` )
   fi
}

_k_cpu_util_ssh () {
printf "%10s %5s %5s %5s %5s %5s %10s %10s %10s %10s %10s %10s\n" hostname user sys nice idle Run used\(M\) free\(M\) shared\(M\) buffers\(M\) cached\(M\) total\(M\)
for node in ${_hosts}; do
        printf "%10s" "$node:"
        ssh $node '(
fcpul=( $(cat /proc/stat) )
sleep 0.2
lcpul=( $(cat /proc/stat) )
user=`expr ${lcpul[1]} - ${fcpul[1]}`
nice=`expr ${lcpul[2]} - ${fcpul[2]}`
system=`expr ${lcpul[3]} - ${fcpul[3]}`
idle=`expr ${lcpul[4]} - ${fcpul[4]}`
iowait=`expr ${lcpul[5]} - ${fcpul[5]}`
irq=`expr ${lcpul[6]} - ${fcpul[6]}`
softirq=`expr ${lcpul[7]} - ${fcpul[7]}`
steal=`expr ${lcpul[8]} - ${fcpul[8]}`

total=`expr $user + $nice + $system + $idle + $iowait + $irq + $softirq + $steal`
aa=100
r_idle=`echo "$idle * $aa / $total" | bc`
r_sys=`echo "$system * $aa / $total" | bc`
r_nice=`echo "$nice * $aa / $total" | bc`
r_user=`echo "$user * $aa / $total" | bc`

mem=( $(free|grep Mem) )
run=( $(cat /proc/stat |grep procs_running) )

(printf "%5s %5s %5s %5s %5s %10s %10s %10s %10s %10s %10s\n" $r_user $r_sys $r_nice $r_idle ${run[1]} `expr ${mem[2]} / 1024 `  `expr ${mem[3]} / 1024` `expr ${mem[4]} / 1024` `expr ${mem[5]} / 1024` `expr ${mem[6]} / 1024` `expr ${mem[1]} / 1024` )
)'
done
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "cpu_util.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
