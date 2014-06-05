#$version$:0.1.24
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_is() {
   local cmd rcmd opts
   if [ -n "$*" ]; then 
       [ "${#@}" == "2" ] || return 1
       cmd=$1
       opts=("${@:2}")
       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd "${opts[@]}"
          return $?
       else
          echo "ERR: $rcmd"
          return 1
       fi
   fi
   return 1
}


# cmd sample
_k_is_int() {
   [ -n "$*" ] || return 1
   printf "%d" $* >& /dev/null && return 0 || return 1
}

_k_is_float() {
   [ -n "$*" ] || return 1
   printf "%f" $* >& /dev/null && return 0 || return 1
}

_k_is_block() {
   [ -b "$1" ]  && return 0 || return 1
}

_k_is_word() {
   local num
   num=$(echo $*  | sed "s/[0-9]//g" | wc -w)
   (( $num == 0 )) && return 1 || echo $num
   return 0
}

_k_is_ip() {
    [ "$(echo $1 | awk -F\. '{print NF}')" == "4" ] || return 1
    _k_is_int "$(echo $1 | sed "s/\.//g")" || return 1
    for ii in $(echo $1 | sed "s/\./ /g"); do
        (( $ii >=0 && $ii <= 255 )) || return 1
    done
    return 0
}

_k_is_file() {
    local file src dest dest_path
    file=$1
    src=$2
    dest=$3
    [ -n "$file" ] || return 1
    if [ -n "$dest" ]; then
       [ -n "$src" ] && dest_path="$dest/$(echo $(pwd)/ | sed "s#$src/##g")$file" || dest_path="$dest/$file"
    else
       dest_path="$file"
    fi
    [ -f" $dest_path" ] && return 0 || return 1
}

_k_is_directory() {
    local file src dest dest_path
    file=$1
    src=$2
    dest=$3
    [ -n "$file" ] || return 1
    if [ -n "$dest" ]; then
       [ -n "$src" ] && dest_path="$dest/$(echo $(pwd)/ | sed "s#$src/##g")$file" || dest_path="$dest/$file"
    else
       dest_path="$file"
    fi
    [ -d "$dest_path" ] && return 0 || return 1
}

_k_is_what() {
    local file chk
    file=$1 
    chk=$2
    [ -n "$file" ] || return 1
    if [ -L "$file" -a "$chk" != "1" ]; then
       echo "$(_k_is_what $file 1) link" ; return 0
    elif [ -b "$file" ]; then
       echo "block" ; return 0
    elif [ -c "$file" ]; then
       echo "char" ; return 0
    elif [ -d "$file" ]; then
       echo "dir" ; return 0
    elif [ -f "$file" ]; then
       if file "$file" | grep "ISO 9660" >& /dev/null; then
           echo iso ; return 0
       elif file "$file" | grep -i -e video -e movie >& /dev/null; then
           echo mov ; return 0
       elif file "$file" | grep -i image >& /dev/null; then
           echo jpg ; return 0
       elif file "$file" | grep "filesystem data" >& /dev/null; then
           echo img ; return 0
       elif file "$file" | grep "LVM Snapshot" >& /dev/null; then
           echo snap ; return 0
       elif file "$file" | grep "POSIX shell" >& /dev/null; then
           echo shell ; return 0
       elif file "$file" | grep "64-bit LSB executable" >& /dev/null; then
           echo "bin(64)" ; return 0
       elif file "$file" | grep "LSB executable" >& /dev/null; then
           echo "bin(32)" ; return 0
       elif file "$file" | grep "64-bit LSB relocatable" >& /dev/null; then
           modinfo "$file" >& /dev/null && echo "kmod(64)" || \
           echo "obj(64)" ; return 0
       elif file "$file" | grep "LSB relocatable" >& /dev/null; then
           modinfo "$file" >& /dev/null && echo "kmod(32)" || \
           echo "obj(32)" ; return 0
       elif file "$file" | grep "64-bit LSB shared object" >& /dev/null; then
           echo "sharedlib(64)" ; return 0
       elif file "$file" | grep "LSB shared object" >& /dev/null; then
           echo "sharedlib(32)" ; return 0
       elif file "$file" | grep "current ar archive" >& /dev/null; then
           echo staticlib ; return 0
       else
           echo file ; return 0
       fi
    elif _k_is_int "$file" >& /dev/null; then
       echo int ; return 0
    elif _k_is_float "$file" >& /dev/null; then
       echo float ; return 0
    elif _k_is_word "$file" >& /dev/null; then
       echo word ; return 0
    else
         echo unknown
         return 1
    fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "is.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
