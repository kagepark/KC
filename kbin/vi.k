########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.3
# Description : 
########################################################################
KTAG=".k"
KTMP=".k_tmp"
# _k_  : Kage function
# _kv_  : Kage variable
#include k.k

_k_vi_help() {
  echo "
  $(_k_version $0)

  $(basename $0) [<opt> [<input>] ] <filename>

  --help : help
  -svn <filename> : vi <filename> to .k_tmp directory
  -s <filename>   : vi <filename> and backup to .k_tmp (default)
  -m <filename>   : editing same as vim
  "
  exit
}

# base starting sample
_k_vi() {
   local cmd rcmd opt file file_dir file_name nfile
   echo $1 | grep "^-" >& /dev/null && opt=("${@}") || cmd="$1"
   if declare -F _k_${name}_${cmd} >& /dev/null; then
       [ -n "${opt[*]}" ] || opt=("${@:2}")
   fi

   file="$1"
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_vi_help
       exit 0
   elif nfile=$(_k_opt -svn 1 0 "${opt[@]}"); then
       _k_vi_svn "$nfile"
   elif nfile=$(_k_opt -s 1 0 "${opt[@]}"); then
       _k_vi_safe "$nfile"
   elif nfile=$(_k_opt -m 1 0 "${opt[@]}"); then
       vim "$nfile"
   else
      _k_vi_safe "$file"
   fi
}

_k_vi_safe () {
      local file_dir file file_name
      file=$1
      file_dir=$(dirname "$file")
      file_name=$(basename "$file")
      [ -d "$file_dir/$KTMP" ] || mkdir "$file_dir/$KTMP"
      [ -f "$file" ] && cp -a "$file" "$file_dir/$KTMP"

      vi "$file_dir/$KTMP/$file_name"

      [ -f "$file_dir/$KTMP/$file_name" ] || return 0
      if cmp "$file" "$file_dir/$KTMP/$file_name" >& /dev/null; then
           rm -f "$file_dir/$KTMP/$file_name"
      else
           tmp=$(ls "$file_dir/$KTMP/${file_name}"* | sort -n | tail -n1)
           if [ "$file_name" != "$(basename "$tmp")" ]; then
               cmp "$file_dir/$KTMP/$file_name" "$tmp" >& /dev/null && return 0
           fi
           REV_BIN=$(_k_find_file rev.k)
           $REV_BIN "$file_dir/$KTMP/$file_name"
           cp -a "$file_dir/$KTMP/$file_name" "$file" && rm -f "$file_dir/$KTMP/$file_name"
      fi
}

_k_vi_svn () {
    local file_dir file file_name
    file=$1
      file_dir=$(dirname "$file")
      file_name=$(basename "$file")
      [ -d "$file_dir/$KTMP" ] || mkdir "$file_dir/$KTMP"
      if [ -f "$file" ]; then
          [ -f "$file_dir/$KTMP/$file_name" ] || cp -a "$file $file_dir/$KTMP"
      fi

      vi "$file_dir/$KTMP/$file_name"

      [ -f "$file_dir/$KTMP/$file_name" ] || return 0
      if cmp "$file" "$file_dir/$KTMP/$file_name" >& /dev/null; then
           rm -f "$file_dir/$KTMP/$file_name"
      else
           tmp=$(ls "$file_dir/$KTMP/${file_name}"* | sort -n | tail -n1)
           if [ "$file_name" != "$(basename "$tmp")" ]; then
               cmp "$file_dir/$KTMP/$file_name" "$tmp" >& /dev/null && return 0
           fi
           REV_BIN=$(_k_find_file rev.k)
           $REV_BIN "$file_dir/$KTMP/$file_name"
      fi
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "vi.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
