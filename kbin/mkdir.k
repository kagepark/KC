KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_mkdir() {
   local cmd rcmd opt dest_path file
   opt=("$@")
   for ((ii=0; ii<${#opt[*]};ii++)); do
       if echo ${opt[$ii]} | grep "^-bp" >& /dev/null; then
           opt[$ii]=""
           ii=$(($ii+1))
           _K_BASE_PATH=${opt[$ii]}
           opt[$ii]=""
       elif echo ${opt[$ii]} | grep "^-dp" >& /dev/null; then
           opt[$ii]=""
           ii=$(($ii+1))
           _K_DEST_PATH=${opt[$ii]}
           opt[$ii]=""
       elif echo ${opt[$ii]} | grep "^-bw" >& /dev/null; then
           opt[$ii]=""
           backward=1
       fi
   done

   file=("${opt[@]}")
   if [ -n "$_K_DEST_PATH" ]; then
       [ -n "$_K_BASE_PATH" ] && dest_path="$_K_DEST_PATH/$(echo $(pwd)/ | sed "s#$_K_BASE_PATH/##g")${file[0]}" || dest_path="$_K_DEST_PATH/${file[0]}"
       
   else
       ((${#file[*]} <1 )) && exit 1
       dest_path=${file[1]}
   fi

   if [ "$backward" == "1" ]; then
       [ -d $(dirname "${file[0]}") ] || mkdir -p $(dirname "${file[0]}")
   else
       [ -d $(dirname "$dest_path") ] || mkdir -p $(dirname "$dest_path")
   fi
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "mkdir.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
