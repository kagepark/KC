KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_os_help() {
   echo "
$(basename $0) <opt>

  --help : help
  -p     : print current OS's information
  default is export current OS's information (OS_NAME OS_VERNAME OS_RELEASE)
"
   exit
}

_k_os() {
   local cmd rcmd opts
   opts=("${@}")
   if [ "${opt[*]}" ]; then
       _k_opt --help 0 0 "${opts[@]}" && _k_os_help 
       if _k_opt -p 0 0 "${opts[@]}"; then
            _k_os_print && return 0 || return 1
       fi
   else
       _k_os_find
   fi
}


# base stopping sample
#_k_<func>_close() {
##_k_unload $(_k_abc_list)
## code here
#}

# cmd sample
_k_os_find() {
  if [ -f /etc/redhat-release ]; then
    if cat /etc/redhat-release  |grep "^CentOS" > /dev/null 2>&1 ; then
      OS_NAME=centos
      OS_VERNAME=CentOS
      OS_RELEASE=$(cat /etc/redhat-release | awk '{print $3}')
    else
      OS_NAME=rhel
      OS_VERNAME="Red Hat "
      OS_RELEASE=$(cat /etc/redhat-release | awk '{print $7}')
    fi
  elif [ -f /etc/SuSE-release ]; then
    OS_NAME=sles
    OS_VERNAME="SuSE Linux "
    OS_PATCH=$(cat /etc/SuSE-release | grep PATCHLEVEL | awk '{print $3}')
    [ -n "$OS_PATCH" ] && OS_RELEASE=$(cat /etc/SuSE-release | grep VERSION | awk '{print $3}').$OS_PATCH || OS_RELEASE=$(cat /etc/SuSE-release | grep VERSION | awk '{print $3}')
  elif [ "$(uname -s)" == "Darwin" ]; then
    OS_NAME=osx
    OS_VERNAME=$(sw_vers -productName)
    OS_RELEASE=$(sw_vers -productVersion)
  elif [ -f /system/bin/am -a -f /system/bin/pm ]; then
    OS_NAME=android
#    OS_VERNAME=$(sw_vers -productName)
#    OS_RELEASE=$(sw_vers -productVersion)
    OS_VERNAME=
    OS_RELEASE=
  elif [ -f /etc/issue ]; then
    OS_NAME=ubuntu
    OS_VERNAME=$(cat /etc/issue | awk '{print $1;}')
    OS_RELEASE=$(cat /etc/issue | awk '{print $2;}')
  else
    echo "UnknownOS"
    return 1
  fi
  export OS_NAME OS_VERNAME OS_RELEASE
}

_k_os_print() {
  _k_os_find
  echo "$OS_NAME $OS_VERNAME $OS_RELEASE"
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "os.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "${@}" || exit $?
fi
