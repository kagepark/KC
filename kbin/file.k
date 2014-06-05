########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.18
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_file_help() {
  echo "file - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --new <file> : print new filename
  -e <file> : print extition
  -n <file> : print name
  -s <file> : print file size
  -ppd <file> : print photo <dir> format (YYYY/MM)
  -ppf <file> : print photo <file> format (YYYYMMDD_HHMMSS)
  -ppt <file> : print photo <dir>/<file> format
  -jd <file>  : print date in jpg file
  -jdd <file> : print date <dir> format with -jd output
  -cbj <file> : check bad jpeg file or not
  "
  exit
}

_k_file() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && opt=( "${@:2}" ) || opt=( "${@}" )

   if _k_opt --help 0 0 "${opt[@]}"; then
       _k_file_help
       exit 0
   elif file=$(_k_opt --new 1 0 "${opt[@]}"); then
      for ((ii=0;ii<100;ii++)); do
          [ -f "$file" ] && \
          file=$(echo "$file" | sed "s/\.$(echo "$file" | awk -F. 'NF>0{print $NF}')$//g")._k_D_$(mktemp -u XXXXXX).$(echo "$file" | awk -F. 'NF>0{print $NF}')  || \
          break
      done
      echo "$file"
      return 0
   elif file=$(_k_opt -e 1 0 "${opt[@]}"); then
      _k_file_ext "$file"
      return $?
   elif file=$(_k_opt -ppd 1 0 "${opt[@]}"); then
      _k_file_dir_format_date "$file"
      return $?
   elif file=$(_k_opt -jd 1 0 "${opt[@]}"); then
      _k_file_jpg_date "$file"
      return $?
   elif file=$(_k_opt -cbj 1 0 "${opt[@]}"); then
      _k_file_jpg_check "$file"
      return $?
   elif file=$(_k_opt -jdd 1 0 "${opt[@]}"); then
      _k_file_jpg_date_dir "$file"
      return $?
   elif file=$(_k_opt -ppf 1 0 "${opt[@]}"); then
      _k_file_format_date "$file"
      return $?
   elif file=$(_k_opt -ppt 1 0 "${opt[@]}"); then
      [ -f "$file" ] || return 1
      new_file=$(_file_dir_format_date "$file")/$(_k_file_name "$file")_$(_k_file_format_date "$file").$(_k_file_ext "$file")
      [ -f "$new_file" ] && \
      new_file=$(_file_dir_format_date "$file")/$(_k_file_name "$file")_$(_k_file_format_date "$file")._k_D_$(mktemp -u XXXXXX).$(_k_file_ext "$file")
      echo "$new_file"
      return 0
   elif file=$(_k_opt -n 1 0 "${opt[@]}"); then
      _k_file_name "$file"
      return $?
   elif file=$(_k_opt -s 1 0 "${opt[@]}"); then
      stat -f "%z" "$file"
      return 0
   else
      # <command> "${opt[@]}"
      # or
      echo "Unknown option"
      exit 1
   fi
}

_k_file_name() {
    [ -n "$1" ] || return 1
    echo "$1" | sed "s/\.$(echo "$1" | awk -F. 'NF>0{print $NF}')$//g"
    return 0
}
_k_file_ext() {
   [ -n "$1" ] || return 1
   echo "$1" | awk -F. 'NF>0{print $NF}'
   return 0 
}
_k_file_dir_format_date() {
   [ -f "$1" ] || return 1
   #echo $(date -j -f "%b %d %T %Y" "$(stat -f "%Sm" "$1")" "+%Y/%m")
   echo $(stat -f "%Sm" -t "%Y/%m" "$1")
   return 0
}
_k_file_format_date() {
   [ -f "$1" ] || return 1
   echo $(date -j -f "%b %d %T %Y" "$(stat -f "%Sm" "$1")" "+%Y%m%d_%H%M%S")
   return 0
}

_k_file_jpg_date() {
    [ -f "$1" ] || return 1
    jhead "$1" 2>/dev/null | grep "^Date" || return 1
    return 0
}

_k_file_jpg_date_dir() {
    [ -f "$1" ] || return 1
    date_dir_arr=($(_k_file_jpg_date "$1" | awk '{print $3}' | sed -e "s/:/ /g" -e "s/-/ /g"))
    (( ${#date_dir_arr[*]} == 0 )) && return 1
    echo "${date_dir_arr[0]}/${date_dir_arr[1]}"
    return 0
}
_k_file_jpg_check() {
    [ -f "$1" ] || return 1
    file "$1" | grep JPEG >& /dev/null || return 0
    if jpeginfo -cv "$1" | grep "ERROR" >/dev/null; then
        echo "Find Bad file($1)"
        return 1
    fi
    return 0
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "file.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
