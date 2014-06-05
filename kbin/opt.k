KTAG=".k"
# _k_   : Kage function
# _kv_  : Kage variable
error_exit() {
    echo "$*"
    exit
}

_k_opt_help() {
   echo "Option library"
}

_k_opt() {
   local cmd rcmd opt dest_path file find get
   find=$1
   shift 1
   opt="$*"
   #if get=$(_k_opt_opt "$opt" $find); then 
   if get=$(_k_opt2 "$opt" $find); then 
       [ -n "$get" ] && echo "$get"
       return 0
   else
       return 1
   fi
}

_k_opt_opt() {
  local z opts find num n z 
  opts=( $1 )
  find=$2
  num=$3
  [ $# -lt 2 ] && error_return "_k_opt <src> <find> [<output num>]"
  [ -n "$num" ] || num=1
  for z in $(seq 0 $(( ${#opts[*]} - 1)) ); do
    if [ "$find" == "${opts[$z]}" ]; then
      for n in $(seq 1 $num); do
        echo "${opts[$(($z + $n))]}"
      done
      return 0
      break
    fi
  done
  return 1
}

_k_opt_num() {
  local z opts find n
  opts=( $1 )
  find=$2
  [ $# -lt 2 ] && error_return "_k_opt <src> <find>"
  for z in $(seq 0 $(( ${#opts[*]} - 1)) ); do
    if [ "$find" == "${opts[$z]}" ]; then
      for n in $(seq $(( $z+1))  $(( ${#opts[*]} - 1)) ); do
        if echo ${opts[$n]} | grep "^-" > /dev/null ; then
           echo $(( $n-$z -1))
           return 0
           break
        fi
      done
      echo $(( $n-$z ))
      return 0
      break
    fi
  done
  return 1
}

_k_opt_find() {
  local z opts find n
  opts=( $1 )
  find=$2
  [ $# -lt 2 ] && error_return "_k_opt <src> <find>"
  for z in $(seq 0 $(( ${#opts[*]} - 1)) ); do
    if [ "$find" == "${opts[$z]}" ]; then
      echo $z
      return 0
      break
    fi
  done
  return 1
}

_k_opt_end() {
   local opts
   opts=( $* )
   echo ${opts[$(( ${#opts[*]}-1 ))]}
}

_k_opt2() {
    local input find ss num_input
    input=($1)
    find=$2

    num_input=${#input[*]}
    for ((i=0;i<$num_input;i++)); do
        if [ "$find" == "${input[$i]}" ]; then
            ss=$(($i+1))
            for ((j=$ss; j<$num_input; j++)); do
                echo ${input[$j]} | grep "^-" >/dev/null && break
                (($j==$ss)) || printf " "
                printf "%s" "${input[$j]}"
            done
            return 0
        fi
    done
    return 1
}

_k_opt_default() {
    local input find ss num_input
    input=($*)

    num_input=${#input[*]}
    find=""
    for ((i=0;i<$num_input;i++)); do
          echo ${input[$i]} | grep "^-" >/dev/null && break
          find="$find ${input[$i]}"
    done
    [ -n "$find" ] || return 1
    echo $find
    return 0
}

_k_opt_test() {
  opt="-k 1 -h -c -n kage"
  if _k_opt_opt "$opt" -h >/dev/null ; then
    echo "hhhhh"
  fi
  if _K=$(_k_opt_opt "$opt" -k);  then
    echo $_K 
  fi
  echo aaa
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "opt.k" ]; then
    declare -F _k_k >& /dev/null ||  source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") $* || exit $?
fi
