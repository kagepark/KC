########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.8
# Created at Sun Jun  1 11:20:51 CDT 2014
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include fp.k

_k_photo_help() {
  echo "photo - v$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')

$(basename $0) [<opt> [<input>] ]

  --help : help
  --cur_dp_init : Initial data on current directory with duplication check
  --cur_init    : Initial data on current directory
  --cur_rm      : delete current file when found in DB
  --cleanup     : cleanup if found duplication

  * it working with pre-defined directory 
  "
  exit 1
}

# example for cmd is sample
_k_photo() {
   local cmd rcmd opt get_val
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F ${FUNCNAME}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_photo_help
#   elif get_val=$(_k_opt -t 1 0 "${opt[@]}"); then
#      _k_photo_sample $get_val || return 1
#or
   elif _k_opt --cur_dp_init 0 0 "${opt[@]}" >& /dev/null; then
       cur_dp_init=1
   elif _k_opt --cur_init 0 0 "${opt[@]}" >& /dev/null; then
       cur_init=1
   elif _k_opt --cleanup 0 0 "${opt[@]}" >& /dev/null; then
       cleanup=1
   elif _k_opt --cur_rm 0 0 "${opt[@]}" >& /dev/null; then
       rm_file=1
   else
      # <command> "${opt[@]}"
      # or
      echo "Unknown option"
      exit 1
   fi

   if [ "$cur_init" == "1" ]; then
       _k_photo_cur_init "$cleanup"
   elif [ "$cur_init" == "1" ]; then
       _k_photo_cur_dp_init "$cleanup"
   elif [ "$rm_file" == "1" ]; then
       _k_photo_cur_rm "$cleanup"
   fi
   return 0
}

_k_photo_cur_rm () {
  local opts
  cleanup="$1"
  find $(pwd) -type f | while read line; do
      echo "$line" | grep -e "/.cedata/" -e "/.cedata$" -e "/.ceid" -e ".DS_Store$" -e "/.DS_Store" -e ".log$" -e ".txt$" -e "/.k_md5" -e "/.k_md5_files" -e "\.db$" -e "\.THM$" -e "/_SYNCAPP" -e "/.com.apple." >& /dev/null && continue

      found=$(_k_fp dp_md5 "$line" ~/.k_md5/ "" "rm -f")
      echo "$found"
      if [ "$cleanup" == "1" ]; then
          [ "$(echo $found | awk -F: '{if($1=="Found") print $2}')" == "1" ] || \
          _k_fp cleanup "$line" ~/.k_md5/ "/Volumes/cep/photo/photostream/Videos|/Volumes/cep/photo/photostream/Photos|/Volumes/cep/photo/photostream|/Volumes/cep/고미영/|/Volumes/cep/박광기/kage/photo/wedding|/Volumes/cep/박광기/kage/photo|/Volumes/cep/박광>기/kage:/Volumes/cep/photo/usb_photo|/Volumes/cep/photo/temp|/Volumes/cep/photo/photo_sync"
      fi
done
}

_k_photo_cur_dp_init () {
  local opts
#  opts=("$@")
  cleanup="$1"
  find $(pwd) -type f | while read line; do
      echo "$line" | grep -e "/.cedata/" -e "/.cedata$" -e "/.ceid" -e ".DS_Store$" -e "/.DS_Store" -e ".log$" -e ".txt$" -e "/.k_md5" -e "/.k_md5_files" -e "\.db$" -e "\.THM$" -e "/_SYNCAPP" -e "/.com.apple." >& /dev/null && continue

      found=$(_k_fp dp_md5 "$line" ~/.k_md5/ "" "check")
      echo "$found"
      if [ "$cleanup" == "1" ]; then
          [ "$(echo $found | awk -F: '{if($1=="Found") print $2}')" == "1" ] || \
          _k_fp cleanup "$line" ~/.k_md5/ "/Volumes/cep/photo/photostream/Videos|/Volumes/cep/photo/photostream/Photos|/Volumes/cep/photo/photostream|/Volumes/cep/고미영/|/Volumes/cep/박광기/kage/photo/wedding|/Volumes/cep/박광기/kage/photo|/Volumes/cep/박광>기/kage:/Volumes/cep/photo/usb_photo|/Volumes/cep/photo/temp|/Volumes/cep/photo/photo_sync"
      fi
done 
}

_k_photo_cur_init () {
  local opts
  opts=("$@")
  find $(pwd) -type f | while read line; do
      echo "$line" | grep -e "/.cedata/" -e "/.cedata$" -e "/.ceid" -e ".DS_Store$" -e "/.DS_Store" -e ".log$" -e ".txt$" -e "/.k_md5" -e "/.k_md5_files" -e "\.db$" -e "\.THM$" -e "/_SYNCAPP" -e "/.com.apple." >& /dev/null && continue

      found=$(_k_fp md5 "$line" ~/.k_md5/ "" "check")
      echo "$found"
      if [ "$cleanup" == "1" ]; then
          [ "$(echo $found | awk -F: '{if($1=="Found") print $2}')" == "1" ] || \
          _k_fp cleanup "$line" ~/.k_md5/ "/Volumes/cep/photo/photostream/Videos|/Volumes/cep/photo/photostream/Photos|/Volumes/cep/photo/photostream|/Volumes/cep/고미영/|/Volumes/cep/박광기/kage/photo/wedding|/Volumes/cep/박광기/kage/photo|/Volumes/cep >박광>기/kage:/Volumes/cep/photo/usb_photo|/Volumes/cep/photo/temp|/Volumes/cep/photo/photo_sync"
      fi
  done
}

_k_photo_cur_dp_md5_mv () {
  local opts
  opts=("$@")
  find $(pwd) -type f | while read line; do
      echo "$line" | grep -e "/.cedata/" -e "/.cedata$" -e "/.ceid" -e ".DS_Store$" -e "/.DS_Store" -e ".log$" -e ".txt$" -e "/.k_md5" -e "/.k_md5_files" -e "\.db$" -e "\.THM$" -e "/_SYNCAPP" -e "/.com.apple." >& /dev/null && continue
      found=$(_k_fp dp_md5 "$line" ~/.k_md5/ "/Volumes/cep/박광기/kage/photo" "mv -f")
      echo "$found"
      if [ "$cleanup" == "1" ]; then
          [ "$(echo $found | awk -F: '{if($1=="Found") print $2}')" == "1" ] || \
          _k_fp cleanup "$line" ~/.k_md5/ "/Volumes/cep/photo/photostream/Videos|/Volumes/cep/photo/photostream/Photos|/Volumes/cep/photo/photostream|/Volumes/cep/고미영/|/Volumes/cep/박광기/kage/photo/wedding|/Volumes/cep/박광기/kage/photo|/Volumes/cep >박광>기/kage:/Volumes/cep/photo/usb_photo|/Volumes/cep/photo/temp|/Volumes/cep/photo/photo_sync"
      fi
done
}

_k_photo_cur_dp_md5_cp () {
  local opts
  opts=("$@")
  find $(pwd) -type f | while read line; do
      echo "$line" | grep -e "/.cedata/" -e "/.cedata$" -e "/.ceid" -e ".DS_Store$" -e "/.DS_Store" -e ".log$" -e ".txt$" -e "/.k_md5" -e "/.k_md5_files" -e "\.db$" -e "\.THM$" -e "/_SYNCAPP" -e "/.com.apple." >& /dev/null && continue
      found=$(_k_fp dp_md5 "$line" ~/.k_md5/ "$(k path -bp "/Volumes/UUI/COMPUTER/박광기/" -dp "/Volumes/cep/박광기/" --change -h -d "$line")" "cp -f")
      echo "$found"
      if [ "$cleanup" == "1" ]; then
          [ "$(echo $found | awk -F: '{if($1=="Found") print $2}')" == "1" ] || \
          _k_fp cleanup "$line" ~/.k_md5/ "/Volumes/cep/photo/photostream/Videos|/Volumes/cep/photo/photostream/Photos|/Volumes/cep/photo/photostream|/Volumes/cep/고미영/|/Volumes/cep/박광기/kage/photo/wedding|/Volumes/cep/박광기/kage/photo|/Volumes/cep >박광>기/kage:/Volumes/cep/photo/usb_photo|/Volumes/cep/photo/temp|/Volumes/cep/photo/photo_sync"
      fi
done
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "photo.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
