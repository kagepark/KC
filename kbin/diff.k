KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include path.k

_k_diff_help() {
   echo "
   $(basename $0) <file1> { -bp <base path> -dp <dest path> [ -nh ] }  or { <file2> }

   default : swap <base path> <dest path> from start string (/) when matched <base path> in <file1>
   -nh     : swap <base path> <dest path> when just matched <base path> in <file1>
"
   exit 1
}

# base starting sample
_k_diff() {
   local cmd rcmd opt dest_path file
   opt=("$@")
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
       elif echo ${opt[$ii]} | grep "^-nh" >& /dev/null; then
           unset opt[$ii]
           no_head=1
       fi
   done

   file=("${opt[@]}")
   if [ -n "$_K_DEST_PATH" -a -n "$_K_BASE_PATH" ]; then
       dest_path=$(_k_path_change "${file[0]}" "$_K_BASE_PATH" "$_K_DEST_PATH" "$([ "$no_head" == "1" ] || echo 1)") || return 1
   else
       ((${#file[*]} <1 )) && exit 1
       dest_path="${file[1]}"
   fi
   echo "[ diff ${file[0]} $dest_path ] "
   [ ! -f "${file[0]}" -o ! -f "$dest_path" ] && return 1
   diff -up "${file[0]}" "$dest_path"
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "diff.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi

