KTAG=".k"
#$version$:0.1.4
# _k_  : Kage function
# _kv_  : Kage variable

#include k.k
#include dev.k

_k_help() {
  echo "
  $(_k_version $0)

  $(basename $0) <opt> <string>

  return int value
  --help : help
  -f <dest dir> : force unmount
  -df or -fd  <device>  : force umount the device's mount point
  <dest dir>    : same as normal unmount command
  "
  exit
}

_k_snap_dev() {
   local dev dminfo_arr
   dev=$1
   dminfo_arr=($(dmsetup table $(basename "$dev") 2>/dev/null)) || return 1
   dm_img=/dev/loop$(echo ${dminfo_arr[4]} | awk -F: '{print $2}')
   dm_snap=/dev/loop$(echo ${dminfo_arr[5]} | awk -F: '{print $2}')
   echo "$dm_img $dm_snap"
}

# base starting sample
_k_umount() {
   local cmd rcmd
   if [ -n "$*" ]; then 
       cmd=$1
       if [ "$cmd" == "-h" -o "$cmd" == "--help" ]; then
           _k_help
           exit 0
       elif [ "$cmd" == "-f" ]; then
           cmd=mnt_force
           shift 1
       elif [ "$cmd" == "-df" -o "$cmd" == "-fd" ]; then
           cmd=dev_force
           shift 1
       else 
           cmd=mnt_normal
       fi

       if rcmd=$(_k_bin ${FUNCNAME} $cmd); then
          $rcmd "$@" 
          return $?
       else
          echo "ERR: $rcmd"
          return 1
       fi
   fi
}

# cmd sample
_k_umount_dev_force() {
    local dev mountp dmdev
    [ -f /proc/mounts ] || return 1
    for dev in "$@"; do
        fuser -m "$dev" >/dev/null 2>&1 && fuser -km "$dev"
        for mountp in $(awk -v adev="$dev" '{if($1==adev) print $2}' /proc/mounts); do
            [ "$mountp" == "/" -o "$mountp" == "." ] && continue
            umount "$mountp" || umount -l "$mountp"
        done

        # if the device is dm device then remove the dm device
        if dmsetup info "$dev" >& /dev/null; then
            dmdev=($(_k_snap_dev "$dev"))
            dmsetup remove "$(basename "$dev")"
            for ((ii=0;ii<${dmdev[*]};ii++)); do
                losetup -d "${dmdev[$ii]}"
            done
        fi
    done
}

_k_umount_mnt_force() {
    local dev mountp mnt
    [ -f /proc/mounts ] || return 1
    for mnt in "$@"; do
        dev=$(awk -v adev="$mnt" '{if($2==adev) print $1}' /proc/mounts)
        _k_umount_dev_force "$dev"
    done
}

_k_umount_mnt_normal() {
    umount "${@}"
}


# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "umount.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi
