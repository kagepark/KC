#/bin/sh
########################################################################
# Copyright (c) CEP Research Institude,All rights reserved. Since 2008
#    Kage Park <kage@cep.kr>
#$version$:0.2.10
# Description : manage file revision
########################################################################
PATH=/usr/bin:/bin:/usr/sbin:/sbin:${HOME}/bin
_version=$(grep "^#\$version\$:" $0 | awk -F: '{print $2}')


error_exit() {
  printf "\033[22;31m %s \033[22;30m \n" "$*"
  exit
}

revcp() {
  echo $filename $filename.${1}.${2}.${3}
  old_ver=$( grep "^#\$version\$:" $filename | awk -F: '{print $2}')
  [ -n "$old_ver" ] || old_ver=${1}.${2}.$(expr ${3} - 1)
  new_ver=${1}.${2}.${3}
  cp -a ${filename} ${filename}.${1}.${2}.${3}
#  sed -i -e s/\#\$version\$\:${old_ver}/\#\$version\$\:${new_ver}/g ${filename}.${1}.${2}.${3}
  cat ${filename} | sed -e s/\#\$version\$\:${old_ver}/\#\$version\$\:${new_ver}/g > ${filename}.${1}.${2}.${3}
#  chmod 755 $filename.${1}.${2}.${3}
#  ln -sf $filename.${1}.${2}.${3} $filename
  cp -f $filename.${1}.${2}.${3} $filename
  exit
}

help() {
   echo "
   $(basename $0) <file name> [<version level(2,1,0)>]
       version level : default 0 level)
         <filename>.f.m.l

         2: f level
         1: m level
         0: l level
        -v : $_version
"
   exit
}

if [ $# -gt 3 ]; then
  help
elif [ $# -lt 1 ]; then
  help
fi
filename=$1
version=$2
chk=0
[ -n "$version" ] || version=0

old_ver=$( grep "^#\$version\$:" $filename | awk -F: '{print $2}')
[ -n "$old_ver" ] && ( [ -f ${filename}.${old_ver} ] || (cp ${filename} ${filename}.${old_ver})) || (cp ${filename} ${filename}.0.0.1)
#[ -n "$old_ver" ] && ( [ -f ${filename}.${old_ver} ] || (cp ${filename} ${filename}.${old_ver}; ln -sf ${filename}.${old_ver} $filename)) || (cp ${filename} ${filename}.0.0.1 ; ln -sf ${filename}.0.0.1 $filename)


startver="0.0.1"
startver2="0.0.2"
if [ $version -gt 2 ];then
  help
fi

[ -f $filename ] || error_exit "File not found ($filename)"

chk_file=false
chk_file=$(ls ${filename}.*.*.* > /dev/null 2>&1 || echo true)
if [ $chk_file ]; then
  echo $filename ${filename}.${startver2}
  cp ${filename} ${filename}.${startver}
  cp ${filename} ${filename}.${startver2}
#  ln -sf ${filename}.${startver2} $filename
else
  version=$(expr $version + 1)
  f=0
  m=0
  l=0

  if [ 3 -eq $version ] ; then
     f=$(for i in `ls ${filename}.*.*.*`; do gg=( $(ls $i|sed -e 's/\./ /g') ); echo ${gg[$(expr ${#gg[*]} - 3)]}; done | sort -n | uniq | tail -n 1)
     f=$(expr $f + 1 )
     revcp ${f} ${m} ${l}
  else
     f=$(for i in `ls ${filename}.*.*.*`; do gg=( $(ls $i|sed -e 's/\./ /g') ); echo ${gg[$(expr ${#gg[*]} - 3)]}; done | sort -n | uniq | tail -n 1)
  fi

  if [ 2 -eq $version ] ; then
    m=$(for i in `ls ${filename}.$f.*.*`; do gg=( $(ls $i|sed -e 's/\./ /g') ); echo ${gg[$(expr ${#gg[*]} - 2)]}; done | sort -n | uniq | tail -n 1)
    m=$(expr $m + 1)
    if [ $m -gt 99 ]; then
       f=$(expr $f + 1)
       m=0
    fi
    revcp ${f} ${m} ${l}
  else
    m=$(for i in `ls ${filename}.$f.*.*`; do gg=( $(ls $i|sed -e 's/\./ /g') ); echo ${gg[$(expr ${#gg[*]} - 2)]}; done | sort -n | uniq | tail -n 1)
  fi

  l=$(for i in `ls ${filename}.$f.$m.*`; do gg=( $(ls $i|sed -e 's/\./ /g') ); echo ${gg[$(expr ${#gg[*]} - 1)]}; done | sort -n | uniq | tail -n 1)
  l=$(expr $l + 1)
  if [ $l -gt 99 ]; then
     m=$(expr $m + 1)
     if [ $m -gt 99 ]; then
       f=$(expr $f + 1)
       m=0
     fi
     l=0
  fi

  revcp ${f} ${m} ${l}
fi

