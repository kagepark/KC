#################################################################
# Copyright CEP (License : GPL)
# Kage New Shell Command/Library
#$version$:0.1.36
#################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_path_help() {
    echo "
$(basename $0) <opt> <source file|dir>

   -bp <base path>
   -dp <dest path> 

   --change    : change(swap) from <base path> to <dest path> to <source file|dir>
   --add       : add <base path> to <source file|dir>
   --del       : del <base path> to <source file|dir>

   --check     : check changed path is exit or not on disk after add, change, del from <source file|dir>
   -m          : make changed directory after add, change, del from <source file|dir>
   -d          : print changed directory of real <source file|dir>
                 * if <source file|dir> is just string then output is just changed result
   -h          : change head side of the path (only --del and --change option can use this)
   
   * default output is changed result 
"
    exit 1
}

# base starting sample
_k_path() {
   local cmd rcmd opts src_path dest_path change add del check create file new_dest
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F _k_path_${cmd} >& /dev/null && opts=( "${@:2}" ) || opts=( "${@}" )

   if [ -n "$*" ]; then
       if _k_opt --help 0 0 "${opts[@]}"; then
          _k_path_help
       elif rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd "${@:2}"
          return $?
       else
          src_path="$(_k_opt -bp 1 0 "${opts[@]}")"
          dest_path="$(_k_opt -dp 1 0 "${opts[@]}")"
          _k_opt --change 0 0 "${opts[@]}" && change=1
          _k_opt --add 0 0 "${opts[@]}" && add=1
          _k_opt --del 0 0 "${opts[@]}" && del=1
          _k_opt --check 0 0 "${opts[@]}" && check=1
          _k_opt -m 0 0 "${opts[@]}" && create=1
          _k_opt -h 0 0 "${opts[@]}" && head=1
          _k_opt -d 0 0 "${opts[@]}" && print_dir=1
          file="$(_k_opt_end 1 "${opts[@]}")"

          if [ "$change" == "1" ]; then
              new_dest=$(_k_path_change "$file" "$src_path" "$dest_path" "$head") || return 1
          elif [ "$add" == "1" ]; then
              new_dest=$(_k_path_add "$file" "$src_path") || return 1
          elif [ "$del" == "1" ]; then
              new_dest=$(_k_path_del "$file" "$src_path" "$head") || return 1
          fi
          [ -n "$new_dest" ] || return 1

          if [ "$create" == "1" ]; then
              _k_path_create "$file" "$new_dest" || return 1
          fi

          if [ "$check" == "1" ] ; then
              [ -f "$new_dest" -o -d "$new_dest" ] || return 1
          fi

          if [ "$print_dir" == "1" ]; then
              [ -f "$file" ] && new_dest="$(dirname "$new_dest")"
          fi
          echo "$new_dest"
          return 0
       fi
   fi
   _k_path_help
}

_k_path_del() {
    local file src_path head new_dest
    file="$1"
    src_path="$2"
    head=$3
    [ ! -n "$src_path" -o ! -n "$file" ] || return 1
    [ "$head" == "1" ] && \
        new_dest="$(echo ${file} | sed "s#^${src_path}/##g")" || \
        new_dest="$(echo ${file} | sed "s#${src_path}/##g")"
    echo "$new_dest"
}

_k_path_add() {
   local file src_path
   file="$1" 
   src_path="$2"

   [ ! -n "$src_path" -o ! -n "$file" ] || return 1
   echo "$src_path/$(echo $file | sed -e "s#^./##g" -e "s#^/##g")"
}

_k_path_change() {
    local file src_path dest_path head new_dest
    file="$1"
    src_path="$2"
    dest_path="$3"
    head=$4
    [ ! -n "$src_path" -o ! -n "$dest_path" ] || return 1
    [ "$head" == "1" ] && \
        new_dest="$(echo ${file} | sed "s#^${src_path}#${dest_path}#g")" ||  \
        new_dest="$(echo ${file} | sed "s#${src_path}#${dest_path}#g")"
    echo "$new_dest"
    return 0
}

_k_path_create() {
    local file new_dest
    file="$1"
    new_dest="$2"
    [ ! -n "$file" -o ! -n "$new_dest" ] || return 1
    [ -f "$file" ] && create_new_dest_dir="$(dirname "$new_dest")" || create_new_dest_dir="$new_dest"
    [ -d "$create_new_dest_dir" ] && return 0
    mkdir -p "$create_new_dest_dir" && return 0 || return 1
}

_k_path_convert() {
   local cmd rcmd opt dest_path file check tnum
   opt=("$@")
   tnum=${#opt[*]}
   for ((ii=0; ii<$tnum;ii++)); do
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
       elif echo ${opt[$ii]} | grep "^-c" >& /dev/null; then
           check=1
           unset opt[$ii]
       elif echo ${opt[$ii]} | grep "^-bw" >& /dev/null; then
           unset opt[$ii]
           backward=1
       fi
   done

   file=("${opt[@]}")
   if [ -n "$_K_DEST_PATH" ]; then
       if [ "$check" == "1" ]; then
           [ -d "$_K_DEST_PATH" ] || return 1
       fi
       if [ -n "$_K_BASE_PATH" ]; then
            if echo "$(pwd)/" | grep "^$_K_BASE_PATH/" >& /dev/null; then
                dest_path="$_K_DEST_PATH/$(echo $(pwd)/ | sed "s#$_K_BASE_PATH/##g")${file[0]}"
            else
                echo "Wrong base path(-bp). base path must current path's base path"
                echo "-bp: $_K_BASE_PATH, pwd: $(pwd)"
                exit 1
            fi
       else
            dest_path="$_K_DEST_PATH/${file[0]}"
       fi
   else
       dest_path="${file[1]}"
   fi
   [ -n "$dest_path" ] || return 1
   if [ "$check" == "1" ]; then
        if [ ! -d "$dest_path" ]; then
            [ -d "$(dirname "$dest_path")" ] || return 1
        fi
   fi
   echo "$dest_path"
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "path.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0
    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
