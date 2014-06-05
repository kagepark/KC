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

_k_mac_help() {
  echo "$(basename $0) [<opt> [<input>] ]

  --help : help
  "
  exit
}

# base starting sample
_k_mac() {
   local cmd rcmd opt
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F _k_${name}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_mac_help
       exit 0
#   elif test=$(_k_opt -t "$opt"); then
#      _k_mac_test $test || return 1
   else
      #<command> $opt
      echo "Unknown option"
      exit 1
   fi
}

#_k_mac_make_temp () {
#}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "mac.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
