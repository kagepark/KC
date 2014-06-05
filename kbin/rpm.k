#!/bin/sh
if _k_os_check osx; then
   #spctl --list | grep "\.app"
   ls /Applications
elif _k_os_check ubuntu; then
   if rpm_file=$(_k_opt -extract "$*" ) ; then
       dpkg -x $rpm_file
   else
       if [ "$1" == "-qa" ]; then
           opt="--list"
       elif [ "$1" == "-ql" ]; then
           opt="-L"
       elif [ "$1" == "-e" ]; then
           opt="-L"
       fi
       shift 1
       dpkg $opt $*
   fi
else
   if rpm_file=$(_k_opt -extract "$*" ) ; then
       if (( $(id -u) == 0 )); then
           rpm_ext_dir=$(_k_opt -C "$*")
           rpm2cpio $rpm_file | ( [ -n "$rpm_ext_dir" ] && (cd $rpm_ext_dir && cpio -idmv) || cpio -idmv)
           rpm_name=$(rpm -qp --queryformat '%{name}' $rpm_file 2>/dev/null)
           if [ -n "$rpm_ext_dir" ]; then
               rpm -qp --scripts $rpm_file > $rpm_ext_dir/${rpm_name}_script.sh
           else
               rpm -qp --scripts $rpm_file > ${rpm_name}_script.sh
           fi
       else
           echo "It need root account"
           exit 1
       fi
   else
       rpm $*
   fi
fi
