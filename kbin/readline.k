########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.1.20
# Description : 
########################################################################
KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

_k_readline_help() {
  echo "$(basename $0) [<opt> [<input>] ]

  --help : help
  -n # : read # line
  -p   : Print line number
  -f <dir> : find file in the <dir>
  -fn  : print file name
  -hn # : read head line #
  -tn # : read tail line #
  "
  exit
}

# base starting sample
_k_readline() {
   local cmd rcmd opt src line_num find_dir fnprint headn tailn
   echo $1 | grep "^-" >& /dev/null || cmd=$1
   declare -F _k_${name}_${cmd} >& /dev/null && shift 1

   opt=("$@")
   if _k_opt --help 0 0 "${opt[@]}" >/dev/null; then
       _k_readline_help
       exit 0
   fi
#_k_opt <find> <num> <ro> <opts>
   line_num=$(_k_opt -n 1 0 "${opt[@]}")
   find_dir=$(_k_opt -f 1 0 "${opt[@]}")
   headn=$(_k_opt -hn 1 0 "${opt[@]}")
   tailn=$(_k_opt -tn 1 0 "${opt[@]}")
   _k_opt -p 0 0 "${opt[@]}" >& /dev/null && nprint=1
   _k_opt -fn 0 0 "${opt[@]}" >& /dev/null && fnprint=1
   src_arr=("${opt[@]}")
   src=${src_arr[$((${#src_arr[*]}-1))]}
   echo "$src" | grep "^-" >& /dev/null && src=""
   if [ -n "$find_dir" ]; then
       [ -d $find_dir ] || return 1
       _k_readline_find "$find_dir" "$src" "$line_num" "$nprint" "$fnprint" "$headn" "$tailn"
   else
       [ -n "$src" ] || return 1
       [ ! -f "$src" -a ! -d "$src"  -a -L "$src" ] && return 1
       _k_readline_line "$src" "$line_num" "$nprint" "$fnprint" "$headn" "$tailn"
   fi
}

_k_readline_line () {
    local line_num src num nprint find_dir fnprint headn tailn
    src=$1
    line_num=$2
    nprint=$3
    fnprint=$4
    headn=$5
    tailn=$6
    num=1
    if [ -d $src ]; then
        cmd="find"
    elif [ -f $src ]; then
        if [ -n "$headn" ]; then
            cmd="head -n $headn"
        elif [ -n "$tailn" ]; then
            total_num=$(cat $src | wc -l)
            num=$(($total_num - $tailn))
            cmd="tail -n $tailn"
        else
            cmd="cat"
        fi
    else
        echo $src not found
        return 1
    fi
    $cmd $src | while read line; do
        if [ -n "$line_num" ]; then
           if [ "$num" == "$line_num" ]; then
               [ "$fnprint" == "1" ] && echo -n "$src : "
               [ "$nprint" == "1" ] && echo -n "${num} : "
               echo "$line"
               return 0
           fi
        else
           [ "$fnprint" == "1" ] && echo -n "$src : "
           [ "$nprint" == "1" ] && echo -n "${num} : "
           echo "$line"
        fi
        num=$(($num+1))
    done
}

_k_readline_find() {
    local find_dir src line_num nprint opt fnprint headn tailn
    find_dir=$1
    src=$2
    line_num=$3
    nprint=$4
    fnprint=$5
    headn=$6
    tailn=$7
    if [ -n "$src" ]; then
        opt=" -name $src"
    fi
    find $find_dir $opt | while read line; do
        [ -d $line ] && continue
        _k_readline_line "$line"  "$line_num" "$nprint" "$fnprint" "$headn" "$tailn"
    done
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "readline.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
