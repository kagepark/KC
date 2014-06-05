KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_version() {
   local cmd rcmd
   if [ -n "$*" ]; then 
       cmd=$1
       shift 1
       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd "$@"
          return $?
       else
          echo "ERR: $rcmd"
          return 1
       fi
   fi
}


# cmd sample
_k_version_higher() {
   local src dest order
   (( $# == 2 )) || return 1
   src=($(echo $1 | sed "s/\./ /g"))
   dest=($(echo $2 | sed "s/\./ /g"))
   ((${#src[*]} > ${#dest[*]})) && order=${#src[*]} || order=${#dest[*]}
   for ((ii=0; ii<$order; ii++)); do
        [ -n "${src[$ii]}" ] || src[$ii]=0
        [ -n "${dest[$ii]}" ] || dest[$ii]=0
        ((${src[$ii]} < ${dest[$ii]})) && return 1
   done
   return 0
}

_k_version_lower() {
   local src dest order
   (( $# == 2 )) || return 1
   src=($(echo $1 | sed "s/\./ /g"))
   dest=($(echo $2 | sed "s/\./ /g"))
   ((${#src[*]} > ${#dest[*]})) && order=${#src[*]} || order=${#dest[*]}
   for ((ii=0; ii<$order; ii++)); do
        [ -n "${src[$ii]}" ] || src[$ii]=0
        [ -n "${dest[$ii]}" ] || dest[$ii]=0
        ((${src[$ii]} < ${dest[$ii]})) && return 0
   done
   return 1
}

_k_version_version() {
   local src dest order
   (( $# == 2 )) || return 1
   src=($(echo $1 | sed "s/\./ /g"))
   dest=($(echo $2 | sed "s/\./ /g"))
   ((${#src[*]} > ${#dest[*]})) && order=${#src[*]} || order=${#dest[*]}
   for ((ii=0; ii<$order; ii++)); do
        [ -n "${src[$ii]}" ] || src[$ii]=0
        [ -n "${dest[$ii]}" ] || dest[$ii]=0
        ((${src[$ii]} == ${dest[$ii]})) && continue
        ((${src[$ii]} < ${dest[$ii]})) && return 2
        ((${src[$ii]} > ${dest[$ii]})) && return 0
   done
   return 1
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "version.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
