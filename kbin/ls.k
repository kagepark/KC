KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_ls() {
   local cmd rcmd opt dest_path file
   opt=("$@")
   for ((ii=0; ii<${#opt[*]};ii++)); do
       if echo ${opt[$ii]} | grep "^-bp" >& /dev/null; then
           unset opt[$ii]
           ii=$(($ii+1))
           _K_BASE_PATH="${opt[$ii]}"
           unset opt[$ii]
       elif echo ${opt[$ii]} | grep "^-dp" >& /dev/null; then
           unset opt[$ii]
           ii=$(($ii+1))
           _K_DEST_PATH="${opt[$ii]}"
           unset opt[$ii]
       elif echo ${opt[$ii]} | grep "^-bw" >& /dev/null; then
           unset opt[$ii]
           backward=1
       fi
   done
   file=("${opt[@]}")
   file_num=$((${#file[@]}-1))
   if [ -n "$_K_DEST_PATH" ]; then
       [ -n "$_K_BASE_PATH" ] && dest_path="$_K_DEST_PATH/$(echo $(pwd)/ | sed "s#$_K_BASE_PATH/##g")${file[$file_num]}" || dest_path="$_K_DEST_PATH/${file[$file_num]}"
       file[$file_num]="$dest_path"
#       ls "$dest_path"
#   else
#       ls "${file[$file_num]}"
   fi
   ls "${file[@]}"
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$0" != "-bash" ]; then
    #####################################################
    # load k.k when run this script
    # if run this script by k.k then ignore loading k.k
    #####################################################
    if ! declare -F _k_k >& /dev/null; then
        source ./k.k
	    _k_load_include $0
	fi
    #####################################################

	# Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi

