KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_rm() {
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
_k_rm_inode() {
   local inum
   for inum in $*; do
       aa=$(find . -inum $inum -maxdepth 1 -print -delete)
       [ -n "$aa" ] && echo "Delete $aa"
   done
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "rm.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") $* || exit $?
fi
