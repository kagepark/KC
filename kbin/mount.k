KTAG=".k"
#$version$:0.1.16
# _k_  : Kage function
# _kv_  : Kage variable

#include kdev.so
#include is.k

_k_help() {
  echo "
  $(_k_version $0)

  $(basename $0) <opt> <string>

  return int value
  --help : help
  -c <dest dir> [<device>]              : check mount of <device> on <dest dir>
  -l <device>                           : check mount <device>
  -s <img file> <snap file> <dest dir>  : mount snap file
  -sc <img file> <snap file> <dest dir> : create snap file and mount
  -su <dest dir> : umount snap file ( umount command support snap device. So, use umount command )
  -ace <cluster> <revision> <dest dir>  : mount cluster image
  "
  exit 
}

# base starting sample
_k_mount() {
   local cmd rcmd opt
   opt=("$@")
   if _k_opt --help "${opt[@]}" 0 >/dev/null; then
       _k_help
       exit 
   elif cmd=$(_k_opt -c "${opt[@]}" all); then
      _k_mount_check $cmd || return 1
   elif cmd=$(_k_opt -l "${opt[@]}" all); then
      _k_mount_list $cmd || return 1
   elif cmd=$(_k_opt -s "${opt[@]}" all); then
      _k_mount_snap $cmd || return 1
   elif cmd=$(_k_opt -sc "${opt[@]}" all); then
      _k_mount_csnap $cmd || return 1
   elif cmd=$(_k_opt -su "${opt[@]}" all); then
      _k_mount_snap_umount $cmd || return 1
   elif cmd=$(_k_opt -ace "${opt[@]}" all); then
      _k_mount_ace $cmd || return 1
   else
      mount $opt
   fi
}


# cmd sample
_k_mount_check() {
  local type dev chk
  dest=$1
  dev=$2
  [ -f /proc/mounts ] || return 1
  if [ -n "$dev" -a -n "$dest" ]; then
     chk=$(awk -v dev=$dev -v dest=$dest '{if($1==dev && $2==dest) printf "mounted"}' /proc/mounts)
  elif [ -n "$dev" -a ! -n "$dest" ]; then
     chk=$(awk -v dev=$dev '{if($1==dev) printf "mounted"}' /proc/mounts)
  elif [ -n "$dest" ]; then
     chk=$(awk -v dest=$dest '{if($2==dest) printf "mounted"}' /proc/mounts)
  else
     return 1
  fi
  [ "$chk" == "mounted" ] && return 0 || return 1
}

_k_mount_list() {
  local type dev chk
  dev=$1
  [ -n "$dev" ] || return 1
  [ -f /proc/mounts ] || return 1
  if [ -n "$dev" ]; then
     awk -v dev=$dev '{if($1==dev) print $2}' /proc/mounts
  fi
}

_k_mount_snap() {
    local img cofile dev dest
    img=$1
    cofile=$2
    dest=$3
    [ "$(_k_is_what $img)" == "img" ] || return 1
    [ "$(_k_is_what $cofile)" == "snap" ] || return 1
    if [ ! -f $img -o ! -f $cofile -o ! -n "$dest" ]; then
        echo "$(basename $0) -s <img file> <snap file> <dest dir>"
        return 1
    fi
    [ -d $dest ] || return 1
    dev=$(_k_dev_load_device loop $img $cofile) || return 1
    mount $dev $dest || return 1
}

_k_mount_csnap() {
    local img cofile dev dest
    img=$1
    cofile=$2
    dest=$3
    [ "$(_k_is_what $img)" == "img" ] || return 1
    [ "$(_k_is_what $cofile)" == "snap" ] || return 1
    if [ ! -f $img -o ! -n "$dest" ]; then
        echo "$(basename $0) -s <img file> <snap file> <dest dir>"
        return 1
    fi
    if [ -f $cofile ]; then
        echo "$cofile exist"
        return 1
    fi
    [ -d $dest ] || return 1
    _k_dev_create_snapfile $img $cofile
    dev=$(_k_dev_load_device loop $img $cofile) || return 1
    mount $dev $dest || return 1
}

_k_mount_snap_umount() {
    local img cofile dev dest
    dest=$1
    if [ ! -n "$dest" ]; then
        echo "$(basename $0) -su <dest dir>"
        return 1
    fi
    [ -d $dest ] || return 1
    dev=$(awk -v md=$dest '{if($2==md) print $1}' /proc/mounts) || return 1
    [ -b $dev ] || return 1
    if ! umount $dest; then
       fuser -k $dest
       umount $dest || umount -l $dest
    fi
    _k_dev_dm_close $dev
}

_k_mount_ace() {
    local img cofile
    cluster=$1
    rev=$2
    dest=$3
    if [ ! -n "$cluster" -o ! -n "$rev" -o ! -n "$dest" ]; then
        echo "$(basename $0) -ace <cluster> <rev> <dest dir>"
        return 1
    fi
    if [ ! -d /acefs/clusters/$cluster ]; then
         echo "$cluster not found or ACE is not ready"
         exit 0
    fi
    img=/ha_cluster/storage/$(cat /acefs/clusters/$cluster/install)
    if [ ! -f $img ]; then
         echo "$img not found"
         exit 0
    fi
    oneup=$(cat /acefs/clusters/$cluster/revisions/$rev/oneup 2>/dev/null)
    [ -n "$oneup" ] && rev=${rev}.${oneup}
    _k_mount_snap $img /ha_cluster/storage/${cluster}.$rev $dest
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "mount.k" ]; then
    declare -F _k_k >& /dev/null || source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "${@}" || exit 1
fi

