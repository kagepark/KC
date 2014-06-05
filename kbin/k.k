#################################################################
# Copyright CEP (License : GPL)
# Kage New Shell Command/Library
# 03/28/2014 initial version for test
# 03/31/2014 upgrade function for using old library 
#$version$:0.2.43
#################################################################
# "${@}"    : put arrary
# ${#@}     : total array num
# ${@:#}    : all values after shift # to the array
# ${@:#:1}  : 1'th values after shift # to the array
# ${@:#:f#} : 1 ~ f#'s values after shift # to the array

#export PATH=${_K_BIN}:${PATH}

KTAG=".k"
# _k_   : Kage function
# _kv_  : Kage variable

error_exit() {
   echo "$*"
   exit 1
}

# output local shell's functions list
_k_k_list() {
    declare -F | while read line; do
        ff=($line)
        echo "${ff[${#ff[*]}-1]} "
    done
}

_k_version() {
  local file
  file=${@:1:1}
  echo "Version: $(awk -F: '{if($1=="#$version$") print $2}' $file)"
}

# function finding sample
_k_bin() {
   local func cmd fcmd
   func=${@:1:1}
   cmd=${@:2:1}
   if [ ! -n "$func" -o ! -n "$cmd" ]; then
       echo "No input command"
       exit 1
   fi

   if declare -F ${func}_$cmd >&/dev/null; then
      echo ${func}_$cmd
   elif declare -F _k_$cmd >&/dev/null; then
      echo _k_$cmd
   elif declare -F $cmd >&/dev/null; then
      echo $cmd
   else
      if echo $cmd | grep "^/" >& /dev/null; then
          [ -f $cmd ] && echo $cmd
      elif fcmd=$(_k_find_file $(basename "${cmd}${KTAG}") $_K_BIN $_K_LIB) ; then
          echo $fcmd
      elif fcmd=$(_k_find_file $cmd $PATH); then
          echo $fcmd
	  else
          echo "$cmd not found"
          exit 1
      fi
   fi
   return 0
}

# load to shell
_k_load() {
    local name
    name=${@:1:1}
    [ -n "$name" ] || return 1
    [ -f $name ] && source $name
    unset name
}

# base starting sample
_k_k() {
   local cmd rcmd libs lname tfunc dbg shiftn
   shiftn=1
#set -x
#echo ">>${@}<<"
   if (( ${#@} >= 1 )) ; then 
       cmd=${@:$shiftn:1}
       if [ "$cmd" == "-dbg" ]; then
	       dbg=1
           shiftn=$(($shiftn+1))
	       cmd=${@:$shiftn:1}
       fi

#echo "11>>>> $cmd $*"
       shiftn=$(($shiftn+1))
       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
#echo "22>>>> $rcmd $*"
           if echo $rcmd | grep "\.k$" >& /dev/null; then
               if ! declare -F _k_$(basename "$rcmd" | sed "s/\.k$//g") >& /dev/null; then
  	           _k_load_include $rcmd
                   for ii in $(declare -F | awk '{print $3}'); do
                      # make a global function
                      export -f $ii
                   done
               fi
           fi
#echo "33>>>> $rcmd $*"
           if [ "$dbg" == "1" ]; then
              logger -s "dbg> $rcmd"
              sh -x $rcmd "${@:$shiftn}"
           else
              $rcmd "${@:$shiftn}"  || return $?
           fi
       else
          echo "ERR: $rcmd"
          return 1
       fi
   fi
#set +x
}

# split for arrary
_k_k_path_split() {
    if _k_os_check osx; then
	    echo $* | sed -e $'s|:|\\\n|g' -e $'s| |\\\n|g' | sort | uniq
    else
	    echo $* |sed -e "s/:/\n/g" -e "s/ /\n/g" | sort | uniq
    fi
}

# find file's path
_k_find_file() {
	local name path shiftn
    shiftn=1
	name=${@:$shiftn:1}
	shiftn=$(($shiftn+1))
	path=( $(_k_k_path_split $(pwd):${@:shiftn}) )
#	path=( ${path[*]} $(_k_k_path_split ${PATH}) )
	for ((ii=0;ii<${#path[*]}; ii++)); do
        if [ -f ${path[$ii]}/$name ]; then
			echo ${path[$ii]}/$name
			return 0
	    fi
	done
    unset name
	return 1
}

# load include
_k_load_include() {
    local file name _kv_path kstart shiftn
    file="$1"
    [ -n "$file" -a -f "$file" ] || return 1
    for ii in $(awk '{if($1=="#include") print $2}' $file | sed -e "s/<//g" -e "s/>//g"); do
       if _kv_path=$(_k_find_file $ii $_K_BIN $_K_LIB); then
           declare -F _k_$(basename "$_kv_path" | sed "s/\.k$//g") >& /dev/null && continue
           _k_load_include "$_kv_path"
           _k_load "$_kv_path"

           # For Old library starter
           kstart=$(echo $(basename "$_kv_path")|sed -e "s/^k//g" -e "s/\.so$//g")
           if [ "$kstart" != ".k" ]; then
               declare -F _k_$kstart >& /dev/null && _k_$kstart
           fi
           unset kstart
        fi
        unset _kv_path
    done
    unset file 
    unset name
    return 0
}

# base stopping sample
#_k_k_close() {
#   _k_unload $(_k_k_list)
#}

# cmd sample
_k_os_check() {
  local osname osrelease
  osname=${@:1:1}
  #osrelease=${@:2:1}
  [ -n "$osname" ] || return 1
  if [ "$osname" == "centos" -o "$osname" == "rhel" ]; then
    [ -f /etc/redhat-release ] || return 1
    if [ "$osname" == "centos" ]; then
        cat /etc/redhat-release | grep "^CentOS" >& /dev/null && return 0 || return 1
    else
        return 0
    fi
  elif [ "$osname" == "sles" ]; then
    [ -f /etc/SuSE-release ] || return 1
    OS_PATCH=$(cat /etc/SuSE-release | grep PATCHLEVEL | awk '{print $3}')
  elif [ "$osname" == "osx" ]; then
    [ "$(uname -s)" == "Darwin" ] || return 1
  elif [ "$osname" == "android" ]; then
    [ -f /system/bin/am -a -f /system/bin/pm ] || return 1
  elif [ "$osname" == "ubuntu" ]; then
    [ -f /etc/SuSE-release -o /etc/redhat-release ] && return 1
    [ -f /etc/issue ] || return 1
  else
    echo "UnknownOS" 
    return 1
  fi
  return 0
}

_k_real_path() {
    if [ -d "$1" ]; then
        cd "$1" && pwd -P
    else 
        cd $(dirname "$1") && pwd -P
    fi
}

_k_readlink() {
    local opts
    opts=("$@")
    _k_opt -n 0 0 "${opts[@]}" && no_newline="-n"
    _k_opt -s 0 0 "${opts[@]}" && slient="-s"
    _k_opt -f 0 0 "${opts[@]}" && canonicalize="-f"
    file=$(_k_opt_end 1 "${opts[@]}")
    [ -n "$file" ] || return 1
    if _k_os_check osx; then
       if [ "$canonicalize" == "-f" ]; then
           [ "$slient" == "-s" ] && \
              echo $no_newline $(_k_real_path "$file")/$(readlink "$file" || ([ -d "$file" ] || basename "$file")) 2>/dev/null || \
              echo $no_newline $(_k_real_path "$file")/$(readlink "$file" || ([ -d "$file" ] || basename "$file"))
       else
           if [ "$slient" == "-s" ]; then
               readlink $no_newline "$file"  2>/dev/null
               return $?
           else
               readlink $no_newline "$file"
               return $?
           fi
       fi
    else
       readlink $canonicalize $no_newline $slient "$file"
       return $?
    fi
}

_k_make_temp() {
    local name fname dir
    name=$(basename "${@:1:1}" | sed "s/\.k$//g")
    dir=$(dirname "${@:1:1}")
    fname=$dir/${name}.k
    if [ -f $fname ]; then
        echo "Exist $fname"
        exit 1
    fi 

    echo "########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#\$version\$:0.1.0
# Created at $(date)
# Description : 
########################################################################
KTAG=\".k\"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_${name}_help() {
  echo \"$name - v\$(grep \"^#\\\$version\\\$:\" \$0 | awk -F: '{print \$2}')

\$(basename \$0) [<opt> [<input>] ]

  --help : help
  \"
  exit 1
}

# base starting sample
# _k_opt <find> <num> <ro> <input options>

# <num>
#   all      : get whole value between option (start -)
#   #        : get values of # after finded option (default 1)

# <ro>
#  ro=0      : return <value> (default)
#  ro=1      : return <remained opt>
#  ro=2      : return <value>|<remained opt>

# example for cmd is sample
_k_${name}() {
   local cmd rcmd opt get_val
   echo \$1 | grep \"^-\" >& /dev/null || cmd=\$1
   declare -F \${FUNCNAME}_\${cmd} >& /dev/null && shift 1

   opt=(\"\$@\")
   if _k_opt --help 0 0 \"\${opt[@]}\" >/dev/null; then
       _k_${name}_help
#   elif get_val=\$(_k_opt -t 1 0 \"\${opt[@]}\"); then
#      _k_${name}_sample \$get_val || return 1
#or
#   elif _k_opt -t 2 0 \"\${opt[@]}\" >& /dev/null; then
#      _k_${name}_sample \"\${opt_out[@]}\" || return 1
   else
      # <command> \"\${opt[@]}\"
      # or
      echo \"Unknown option\"
      exit 1
   fi
}

#_k_${name}_sample () {
#  local opts
#  opts=(\"\$@\")
#  example  for \"k ${name} sample\"
#}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ \"\$(basename \$0)\" == \"${name}.k\" ]; then
    declare -F _k_k >& /dev/null || source \$_K_BIN/k.k
    _k_load_include \$0

    # Run this script to main function
    _k_\$(basename \$0 | sed \"s/\${KTAG}\$//g\") \"\$@\" || exit \$?
fi" > $fname
    
    chmod +x $fname
}

#_k_opt_find <find> <opts>
_k_opt_find() {
  local z opts find n
  find=${@:1:1}
  opts=("${@:2}")
  [ $# -lt 2 ] && error_return "_k_opt <find> <opts>"
  for ((z=0; z<${#opts[@]}; z++)); do 
    if [ "$find" == "${opts[$z]}" ]; then
      echo "$z"
      return 0
    fi
  done
  return 1
}

#_k_opt_end <num> <opts>
_k_opt_end() {
   local opts num get total
   num=${@:1:1}
   opts=("${@:2}")
   total=$((${#opts[@]}-1))
   opt_out=()
   if [ ! -n "$num" ]; then
       echo "${opts[@]}"
       return 0
   elif [ "$num" == "all" -o "$num" == "0" ]; then
       fnum=0
   elif (($num>=1)); then
       fnum=$(($total-$num+1))
   fi
   for ((z=$total; z >= $fnum; z--)); do
       echo "${opts[$z]}" | grep "^-" >& /dev/null && break 
       [ "${get[*]}" ] && get=("${opts[$z]}" "$get") || get=("${opts[$z]}");
   done
   if [ -n "${get[*]}" ]; then
       echo "${get[*]}"
       opt_out=("${get[@]}")
       export opt_out
       return 0
   else
       return 1
   fi
}

#_k_opt <find> <num> <ro> <opts>
# <num> : print value number 
#   0 : find and return 0
#   1 : find and print one value and return 0
#   # : find and print # of values and return 0
# <ro> : return output
#   0  : print value
#   1  : print remained options
#   2  : print <value>|<remained options>

_k_opt() {
    local input find num get ro opts
    find="${@:1:1}"
    num="${@:2:1}"
    ro="${@:3:1}"
    opts=( "${@:4}" )

    opt_out=()

    [ "$find" == "--help" ] && num=0
    [ -n "$num" ] || num=1
    num_input=${#opts[@]}
    for ((i=0;i<$num_input;i++)); do
       if [ "${opts[$i]}" == "$find" ]; then
          unset opts[$i]
          if [ "$num" == "0" ]; then
             get[0]="help"
             break
          elif [ "$num" == "all" ]; then
             fnum=$(($num_input-1))
          elif (($num>0)); then
             fnum=$(($num+$i))
             (($fnum>=$num_input)) && return 1
          fi

          for ((z=$(($i+1)); z <=$fnum; z++)); do
                 if echo ${opts[$z]} | grep "^-" >/dev/null; then
                    [ "$num" == "all" ] && break || return 1
                 else
                    [ -n "${get[*]}" ] && get=("${get[@]}" "${opts[$z]}") || get=("${opts[$z]}")
                    unset opts[$z]
                 fi
          done
       fi
    done

    if [ -n "${get[*]}" ]; then
          if [ "$ro" == "1" ]; then
              opts=("${opts[@]}")
              echo "${opts[@]}"
              opt_out=("${opts[@]}")
          elif [ "$ro" == "2" ]; then
              opts=("${opts[@]}")
              echo "${get[@]}|${opts[@]}"
              opt_out=("${get[@]}" "|" "${opts[@]}")
          else
              if [ "${get[*]}" != "help" ]; then
                   echo "${get[@]}"
                   opt_out=("${get[@]}")
              fi
          fi
          export opt_out
          return 0
    else
          return 1
    fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename "$(_k_readlink -f "$0")")" == "k.k" ]; then
#!/bin/sh
    _k_k "$@" || exit $?
else
    # Loading this script like as shared library
    g_k_func="_k_load_include _k_find_file _k_bin _k_k _k_load _k_k_path_split _k_readlink _k_os_check error_exit"
    for ii in $g_k_func; do
        export -f $ii
    done
fi
