KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_fsck() {
   if [ -n "$*" ]; then 
      local FILE_SYSTEM DEVICE
      DEVICE=$1
      FILE_SYSTEM=$2
      [ -n "$DEVICE" ] || return 1
      if [ "$FILE_SYSTEM" == "xfs" ]; then
         xfs_check "$DEVICE" || xfs_repair -l "$DEVICE"
      else
         [ -n "$FILE_SYSTEM" ] && fsck.$FILE_SYSTEM "$DEVICE" || fsck "$DEVICE"
      fi
   else
      return 1
   fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "fsck.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
