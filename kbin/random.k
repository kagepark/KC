KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# cmd sample
#_k_random_src() {
#    od -An -N2 -i /dev/random
#}

_k_random() {
    local range start end
    if (( "$#" == 1)); then
        start=$(echo $1 | awk -F: '{print $1}')
        end=$(echo $1 | awk -F: '{print $2}')
    fi

    if [ -n "$start" -a -n "$end" ]; then
        echo $(( (RANDOM %= ($end-$start) ) + $start))
    elif [ -n "$start" ]; then
        echo $((RANDOM+$start))
    elif [ -n "$end" ]; then
        echo $(( RANDOM %= $end))
    else
        echo $((RANDOM))
    fi
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "random.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") $* || exit $?
fi
