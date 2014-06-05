KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include path.k
_k_svn_help() {
    echo "
$(basename $0) <cmd>

<cmd> 
  add  <dir>  : add not membered svn file to svn
  compare -bp <base path> -dp <dest path> [ -bw (backward) ] <path from <base path>>
  log <logfile name> <user id> : find log of <user id> from log file
  log -svn <user id>           : find log of <user id> from svn
  log -s <log file>            : svn log from svn to log file

ex) k svn compare -bp \$(pwd) -dp /home/kage/work/ace.branch/ace-2.0-2574.netapp.1 tools
"

    exit
}

# base starting sample
_k_svn() {
   local cmd rcmd
   if [ -n "$*" ]; then
       cmd=$1
       [ "$cmd" == "--help" -o "$cmd" == "help" ] && _k_svn_help

       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd "${@:2}"
          return $?
       else
          echo "ERR: $rcmd"
          return 1
       fi
   fi
}

_k_svn_add() {
    local src
    src=$1
    [ -n "$src" ] || return 1
    [ -d "$src" ] || return 1
    svn info "$src" >& /dev/null || return 1

    for ii in $(find "$src" | grep -v -e "/.svn" -e "\.$" | sed "s#^\./##g"); do
        echo "[ $ii ]"
        if ! svn info "$ii" >& /dev/null; then
            echo -n "add $ii to svn (yes|del|no) ? "
            read ay
            if [ "$ay" == "yes" -o "$ay" == "Yes" -o "$ay" == "YES" -o "$ay" == "y" -o "$ay" == "Y" ]; then
                svn add "$ii"
            elif [ "$ay" == "del" -o "$ay" == "Del" -o "$ay" == "DEL" -o "$ay" == "d" -o "$ay" == "D" ]; then
                rm -f "$ii"
            fi
        fi
    done | tee -a /tmp/svn_add.log
}

_k_svn_compare() {
   local cmd rcmd opt dest_path file chk_path log find_dest_path
   opt=("${@}")
   for ((ii=0; ii<${#opt[*]};ii++)); do
       if echo ${opt[$ii]} | grep "^-bp" >& /dev/null; then
           unset opt[$ii]
           ii=$(($ii+1))
           _K_BASE_PATH=${opt[$ii]}
           unset opt[$ii]
       elif echo ${opt[$ii]} | grep "^-dp" >& /dev/null; then
           unset opt[$ii]
           ii=$(($ii+1))
           _K_DEST_PATH=${opt[$ii]}
           unset opt[$ii]
       elif echo ${opt[$ii]} | grep "^-bw" >& /dev/null; then
           unset opt[$ii]
           backward=1
       fi
   done

   echo "Compare from $_K_BASE_PATH to $_K_DEST_PATH"
   sleep 3

   chk_path=("${opt[@]}")
   for ii in $(find "${chk_path[0]}" | grep -v -e "/.svn" -e "\.$" | sed "s#^\./##g" ); do
       [ -d "$ii" ] && continue
       [ -f "$ii" ] || continue
       echo -n "[ $ii ]"
       #if log=$(k diff -dp $_K_DEST_PATH -bp $_K_BASE_PATH $ii) ;then
       if [ -n "$_K_BASE_PATH" ]; then
           find_dest_path=$(_k_path_convert -c -dp "$_K_DEST_PATH" -bp "$_K_BASE_PATH" "$ii")  || return 1
       else
           find_dest_path=$(_k_path_convert -c -dp "$_K_DEST_PATH" "$ii")  || return 1
       fi
       [ -n "$find_dest_path" ] || return 1
       if log=$([ -f "$find_dest_path" ] && diff -up "$ii" "$find_dest_path") ;then
           echo "  ==> Same"
       else
           #if k is file $ii $_K_BASE_PATH $_K_DEST_PATH; then
           if [ -f "$find_dest_path" ] ; then
               echo
               echo "$log"
               echo
               echo
               echo -n "copy $ii to $find_dest_path (y|[n])? "
               read ay
               [ "$ay" == "y" ] && cp -a "$ii" "$find_dest_path"
           #elif k is directory $ii; then
           elif [ -d "$find_dest_path" ]; then
               continue
           else
               echo
               echo -n "copy $ii to $find_dest_path (y|[n])? "
               read ay
               if [ "$ay" == "y" ]; then
                   [ -d "$(dirname "$find_dest_path")" ] || mkdir -p "$(dirname "$find_dest_path")"
                   cp -a "$ii" "$(dirname "$find_dest_path")"
               fi
           fi
       fi
       echo
    done | tee -a /tmp/compare.log
}

_k_svn_log() {
    logfile=$1
    id=$2
    [ -n "$logfile" ] || error_exit "Can not found $logfile"
    [ -n "$id" ] || error_exit "Required ID"

    if [ "$logfile" == "-svn" ]; then
      logfile=$(mktemp /tmp/svn.XXXXXXXX)
      svn info | grep "^Last Changed Rev"
      svn log  > $logfile
    elif [ "$logfile" == "-s" ]; then
      svn log  > $id
      exit 0
    fi

    found=0
    cat $logfile | while read line ; do
      [ -n "$(echo $line | grep "| $id |")" ] && found=1
      [ $found -eq 1 ] &&  printf "%s\n" "$line"
      if [ "$line" == "------------------------------------------------------------------------" ] ; then found=0; fi
    done

    [ "$logfile" == "-svn" ] && rm -f $logfile
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "svn.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0
    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
