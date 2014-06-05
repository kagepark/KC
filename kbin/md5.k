########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.1
# Description :
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_md5_help() {
  echo "$(basename $0) [<opt> [<input>] ]

  --help : help
  "
  exit
}

# base starting sample
_k_md5() {
   local cmd rcmd opt
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F _k_${name}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help "${opt[@]}" >/dev/null; then
       _k_md5_help
       exit 0
   fi

   _k_md5_cmd=$(_k_md5_cmd)
   $_k_md5_cmd "${@:1:1}" | awk '{print $1;}'
}

_k_md5_cmd() {
   if _k_os_check osx; then
       _k_md5_cmd="/sbin/md5 -q"
   else
      _k_md5_cmd=/usr/bin/md5sum
   fi
   echo $_k_md5_cmd
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "md5.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
