#$version$:0.1.45
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include path.k
#include fp.k

# base starting sample
_k_mv_help() {
  echo "
    $(_k_version $0)

    $(basename $0) [<opt>] <src> [<dest>]

    -bp <src base path> 
    -dp <dest base path>
      --nh  : swap <src base path> <dest base path> when matched <src base path>
      * if -bp then should need -dp
      * if use base path then must remove <dest>

    --diff : diff and move (<src> should a file)
    --md5 : check fingerprint
      --md  : if not found dest dir then make dir and move
      --cdf : check duplication in fingerprint
      --fp <path> : fingerprint path (default : ~/.k_md5)
      --cleanup : cleanup fingerprint when found many duplicated file
        --keep <dir1|dir2|..> : Keep dir , split simbol is \"|\"
        --del <dir1|dir2|..>  : Del dir , split simbol is \"|\"

ex)
move /etc/hosts to /backup/etc/hosts
  $(basename $0) -bp /etc -dp /backup/etc /etc/hosts
  or
  $(basename $0) /etc/hosts /backup/etc/hosts

move /etc/sysconfig/network/ifcfg-eth0 to /etc/sysconfig/network-scripts/ifcfg-eth0
  $(basename $0) -bp /network -dp /network-scripts -nh /etc/sysconfig/network/ifcfg-eth0

  "
  exit 1
}

_k_mv() {
   local cmd rcmd opt dest_path file
   opt=("$@")
   for ((ii=0; ii<${#opt[*]};ii++)); do
       if [ "${opt[$ii]}" == "--help" ]; then
           _k_mv_help
           exit 0
       elif [ "${opt[$ii]}" == "-bp" ]; then
           unset opt[$ii]
           ii=$(($ii+1))
           _K_BASE_PATH=${opt[$ii]}
           unset opt[$ii]
       elif [ "${opt[$ii]}" == "-dp" ]; then
           unset opt[$ii]
           ii=$(($ii+1))
           _K_DEST_PATH=${opt[$ii]}
           unset opt[$ii]
       elif [ "${opt[$ii]}" == "--fp" ]; then
           unset opt[$ii]
           ii=$(($ii+1))
           _K_MD5_PATH=${opt[$ii]}
           unset opt[$ii]
       elif [ "${opt[$ii]}" == "--keep" ]; then
           unset opt[$ii]
           ii=$(($ii+1))
           cleanup_keep_path=${opt[$ii]}
           unset opt[$ii]
       elif [ "${opt[$ii]}" == "--del" ]; then
           unset opt[$ii]
           ii=$(($ii+1))
           cleanup_del_path=${opt[$ii]}
           unset opt[$ii]
       elif [ "${opt[$ii]}" == "--diff" ]; then
           unset opt[$ii]
           diff=1
       elif [ "${opt[$ii]}" == "--md" ]; then
           unset opt[$ii]
           make_dest_dir=1
       elif [ "${opt[$ii]}" == "--nh" ]; then
           unset opt[$ii]
           no_head=1
       elif [ "${opt[$ii]}" == "--cdf" ]; then
           unset opt[$ii]
           chk_duplication=1
       elif [ "${opt[$ii]}" == "--md5" ]; then
           unset opt[$ii]
           mv_md5=1
       elif [ "${opt[$ii]}" == "--cleanup" ]; then
           unset opt[$ii]
           cleanup=1
       fi
   done
   
   file=("${opt[@]}")
   if [ ! -n "$_K_DEST_PATH" -a ! -n "$_K_BASE_PATH" ]; then
       dest_path="$(_k_opt_end 1 "${file[@]}")"
       unset file[$((${#file[@]}-1))]
       file=("${file[@]}")
   fi
      
   if [ "$mv_md5" == "1" ]; then
       if [ "$make_dest_dir" == "1" ]; then
           md5_sub_cmd="mv -f"
       else
           md5_sub_cmd="mv"
       fi

       [ -n "$_K_MD5_PATH" ] || _K_MD5_PATH=~/.k_md5
       [ "$chk_duplication" == "1" ] && fp_cmd="dp_md5" || fp_cmd=md5
       find "${file[@]}" -type f | while read line; do
           echo "$line" | grep -e "/.cedata/" -e "/.cedata$" -e "/.ceid" -e ".DS_Store$" -e "/.DS_Store" -e ".log$" -e ".txt$" -e "/.k_md5" -e "/.k_md5_files" -e "\.db$" -e "\.THM$" -e "/_SYNCAPP" -e "/.com.apple." >& /dev/null && continue

           if [ -n "$_K_DEST_PATH" -a -n "$_K_BASE_PATH" ]; then
                dest_path=$(_k_path_change "$line" "$_K_BASE_PATH" "$_K_DEST_PATH" "$([ "$no_head" == "1" ] || echo 1)") || return 1
           fi
           found=$(_k_fp $fp_cmd "$line" "$_K_MD5_PATH" "$dest_path" "$md5_sub_cmd")
           echo "$found"
           if [ "$cleanup" == "1" ]; then
               [ "$(echo $found | awk -F: '{if($1=="Found") print $2}')" == "1" ] || \
                   _k_fp cleanup "$line" "$_K_MD5_PATH" "${cleanup_keep_path}:${cleanup_del_path}"
           fi
       done
       return 0
   else
       find "${file[@]}" -type f | while read line; do
           if [ -n "$_K_DEST_PATH" -a -n "$_K_BASE_PATH" ]; then
               dest_path=$(_k_path_change "${line}" "$_K_BASE_PATH" "$_K_DEST_PATH" "$([ "$no_head" == "1" ] || echo 1)") || return 1
           fi
           if [ "$diff" == "1" -a -f "$dest_path" ]; then
               if diff -up "${line}" "$dest_path"; then
                   echo "Same file"
                   continue
               fi
           fi
           $mv_cmd "${line}" "$dest_path" || return 1
       done
   fi
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "mv.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
