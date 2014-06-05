KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_kmod() {
   if [ -n "$*" ]; then 
      for ii in "$@"; do
         if [ ! -d /sys/module/$(echo "$ii" | sed "s/-/_/g") ]; then
              modprobe "$ii" || return 1
         fi
      done
      return 0
   else
      return 1
   fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "kmod.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
