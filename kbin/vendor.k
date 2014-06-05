KTAG=".k"
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k

# base starting sample
_k_vendor() {
   local cmd rcmd
   if [ -n "$*" ]; then 
       cmd=$1
       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd "${@:2}" 
       else
          echo "ERR: $rcmd"
       fi
   fi
}

_k_mod() {
    for ii in "$@"; do
         if [ ! -d "/sys/module/$(echo "$ii" | sed "s/-/_/g")" ]; then
              modprobe "$ii" || return 1
         fi
    done
    return 0
}

# cmd sample
_k_vendor_block_dev() {
    local device dev  FIND_VENDOR VENDOR_KMOD
    device=$1
    FIND_VENDOR=$2
    VENDOR_KMOD=$3

    [ -n "$VENDOR_KMOD" ] && _k_mod "$VENDOR_KMOD"
    [ -d "/sys/block" ] || return 1
    if [ "$device" == "auto" ]; then
        if [ ! -n "$FIND_VENDOR" ]; then
            echo "Attached storage's vendor name(FIND_VENDOR) not found"
            return 1
        fi
        dev=$(awk -v find="$FIND_VENDOR" '{if($1==find) print FILENAME}' /sys/block/*/device/vendor | awk -F/ '{print $4}')
        [ -n "$dev" ] && echo /dev/$dev || return 1
    else
        [ -b "$device" ] && echo $device || return 1
    fi
    return 0   
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "vendor.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi

