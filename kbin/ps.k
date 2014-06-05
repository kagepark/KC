KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_ps() {
   local cmd rcmd
   [ -d /proc ] || return 1
   if [ -n "$*" ]; then 
       cmd=$1
       shift 1
       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd "$@" 
       else
          echo "ERR: $rcmd"
          return 1
       fi
   fi
}


# cmd sample
_k_ps_check() {
   local name pid
   [ -n "$1" ] || return 1
   pid=$(awk -v name="$1" '{if($1=="Name:" && $2==name) print FILENAME}' /proc/*/status | awk -F/ '{print $3}')
   [ -n "$pid" ] && echo $pid || return 1
   return 0
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "ps.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
