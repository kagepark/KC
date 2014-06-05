KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_dev() {
   local cmd rcmd
   if [ -n "$*" ]; then
       cmd=$1
       shift 1
       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd $*
          return $?
       else
          echo "ERR: $rcmd"
          return 1
       fi
   fi
}

# cmd sample
_k_dev_used() {
    local dev
    dev=$1
    [ -b $dev ] || return 1
    fuser -m $dev >& /dev/null && return 0
    [ -d /sys/block/$(basename $dev) ] || return 1
    for (( ii=1; ii<$(cat /sys/block/$(basename $dev)/range); ii++)); do
        [ -b $dev$ii ] || continue
        if fuser -m $dev$ii >& /dev/null; then
           echo $ii
           return 0
        fi
    done
    return 1
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "dev.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") $* || exit $?
fi
