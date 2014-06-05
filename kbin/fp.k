########################################################################
# Copyright (c) CEP Research Institude, All rights reserved. Since 2008
#    Kage Park <kagepark@cep.kr>
#$version$:0.4.14
# Description : Fingerprint
########################################################################
KTAG=".k"

#include k.k
#include file.k
#include md5.k

error_exit() {
    echo "$*"
    exit 1
}

_k_fprint_history() {
   local file finger_path dest cmd
   file="$1"
   finger_path="$2"
   [ -f "$file" ] || return 1
   [ -n "$finger_path" ] || finger_path=$(dirname "$file")/.k_md5
   [ -d "${finger_path}" ] || return 1

   _k_md5_cmd=$(_k_md5_cmd) || return 1
   md5=$($_k_md5_cmd "$file")
   [ -n "$md5" ] || return 1
   if [ -f "$finger_path/$md5/info.txt" ]; then
          cat "$finger_path/$md5/info.txt" | while read info_line; do
              md5_date=$(echo $info_line | awk -F\| '{print $1}')
              md5_cmd=$(echo $info_line | awk -F\| '{print $2}')
              md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
              md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
              echo "$([ -n "$md5_date" ] && date -r $md5_date) : $md5_cmd : $md5_src_file : $md5_dest_file"
          done
          return 0
   fi
   echo "Not found"
   return 1
}

_k_fprint_md5_ctl() {
   local file finger_path dest cmd md5_cmd md5path line_info
   md5_cmd="$1"
   cmd="$2"
   md5path="$3"
   file="$4"
   dest_file="$5"
   [ ! -n "$file" -a ! -n "$dest_file" ] && return 1
   [ -n "$md5path" ] || return 1
   if [ "$md5_cmd" == "add" ]; then
       [ -d "$md5path" ] || mkdir -p "$md5path"
       [ "$cmd" == "check" -o "$cmd" == "init" ] && \
       echo "$(date +%s)|init|$file|$file" >> "$md5path/info.txt" || \
       echo "$(date +%s)|$cmd|$file|$dest_file" >> "$md5path/info.txt"
       return 0
   elif [ "$md5_cmd" == "del" ]; then
       if [ -f "$md5path/info.txt" ]; then
         if [ -n "$dest_file" ]; then
               sdate=($(awk -v fn="$dest_file" -F\| '{if($4==fn) printf "%s ",$1}' "$md5path/info.txt"))
         else
               sdate=($(awk -v fn="$file" -F\| '{if($3==fn) printf "%s ",$1}' "$md5path/info.txt"))
         fi
         for ((ii=0;ii<${#sdate[*]};ii++)); do
               sed  "/^${sdate[$ii]}/d" "$md5path/info.txt" > "$md5path/info.txt~"
               mv "$md5path/info.txt~" "$md5path/info.txt"
         done
         [ "$(stat -f "%z" "$md5path/info.txt")" == "0" ] && rm -fr "$md5path"
       else
         rm -fr "$md5patah" 
       fi
       return 0
   elif [ "$md5_cmd" == "fix" ]; then
       cat "$md5path/info.txt" | while read info_line; do
           md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
           md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
           if [ ! -n "$md5_dest_file" -a -f "$md5_src_file" ]; then
                _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" "" || return 1
                _k_fprint_md5_ctl "add" "FixDB" "$md5path" "$md5_src_file" "$md5_src_file" || return 1
           elif [ ! -n "$md5_dest_file" -a ! -f "$md5_src_file" ]; then
                _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" "" || return 1
           elif [ -f "$md5_src_file" -a ! -f "$md5_dest_file" ]; then
                _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" "$md5_dest_file" || return 1
                _k_fprint_md5_ctl "add" "FixDB" "$md5path" "$md5_src_file" "$md5_src_file" || return 1
           elif [ -n "$md5_dest_file" -a ! -f "$md5_dest_file" ]; then
                _k_fprint_md5_ctl "del" "" "$md5path" "" "$md5_dest_file" || return 1
           fi
       done
       [ "$(stat -f "%z" "$md5path/info.txt")" == "0" ] && rm -fr "$md5path"
   fi
}

_k_fprint_rm() {
   local file finger_path dest cmd
   file="$1"
   finger_path="$2"
   [ -f "$file" ] || return 1
   [ -n "$finger_path" ] || finger_path=$(dirname "$file")/.k_md5
   [ -d "${finger_path}" ] || return 1

   _k_md5_cmd=$(_k_md5_cmd)
   md5=$($_k_md5_cmd "$file")
   rm -f "$file" || return 1

   if [ -d "$finger_path/$md5" ]; then 
       _k_fprint_md5_ctl "del" "" "$finger_path/$md5" "" "$file" || return 1
   fi
   return 0
}

_k_fprint_mv() {
   local file finger_path dest cmd dest_file
   file="$1"
   finger_path="$2"
   dest="$3"
   [ -f "$file" ] || return 1
   [ -n "$finger_path" ] || finger_path=$(dirname "$file")/.k_md5
   [ -d "${finger_path}" ] || return 1

   _k_md5_cmd=$(_k_md5_cmd)
   md5=$($_k_md5_cmd "$file")
   if [ -d "$dest" ]; then
      dest_file="$dest/$(basename "$file")" 
   else
      [ -d "$(dirname "$dest")" ] || return 1
      dest_file="$dest"
   fi
   mv "$file" "$dest_file" || return 1
   if [ -d "$finger_path/$md5" ]; then
       _k_fprint_md5_ctl "del" "" "$finger_path/$md5" "" "$file" || return 1
       _k_fprint_md5_ctl "add" "mv" "$finger_path/$md5" "$file" "$dest_file" || return 1
   else
       mkdir -p "$finger_path/$md5"
       _k_fprint_md5_ctl "add" "mv" "$finger_path/$md5" "$file" "$dest_file" || return 1
   fi
   return 0
}

_k_fprint_md5_found_duplication() {
    local md5_dest_file dest_file file md5_src_file cmd md5path num found_file info
    file="$1"
    dest_file="$2"
    md5path="$3"
    [ -d "$md5path" ] || return 1
    [ -f "$md5path/info.txt" ] || return 1
    [ "$(stat -f "%z" "$md5path/info.txt")" == "0" ] && return 1
    #if [ "$(dirname "$file")" == "$(dirname "$dest_file")" ]; then
    if [ "$file" == "$dest_file" ]; then
        echo "Same: $file"
        return 0
    fi
    info=$(cat "$md5path/info.txt" | while read info_line; do
        md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
        md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
        #if [ "$file" == "$md5_src_file" -o "$file" == "$md5_dest_file" ]; then
        if [ "$file" == "$md5_dest_file" ]; then
            echo "Same: $file"
            break
        elif [ -n "$md5_dest_file" -a ! -f "$md5_dest_file" ]; then
            _k_fprint_md5_ctl "del" "" "$md5path" "$md5_dest_file" ""
        elif [ -n "$md5_src_file" -a ! -f "$md5_src_file" -a ! -f "$md5_dest_file" ]; then
            _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" ""
        fi
    done)
    if [ "$([ -f "$md5path/info.txt" ] && stat -f "%z" "$md5path/info.txt" || echo 0)" == "0" ]; then
         rm -fr "$md5path"
         return 1
    fi
    found_file="$(echo $(cat "$md5path/info.txt" |awk -F\| '{if($4) printf "%s,",$4; else printf "%s,",$3;}'))"
    [ -n "$info" ] && echo "$info" || echo "Found:$(wc -l "$md5path/info.txt" | awk '{print $1}'): $file => $found_file"
    return 0
}

_k_fprint_md5_found() {
    local md5_dest_file dest_file file md5_src_file cmd md5path
    file="$1"
    dest_file="$2"
    cmd="$3"
    md5path="$4"
    [ -d "$md5path" ] || return 1
    [ -f "$md5path/info.txt" ] || return 1
    [ "$(stat -f "%z" "$md5path/info.txt")" == "0" ] && return 1

    cat "$md5path/info.txt" | while read info_line; do
        md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
        md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
        if [ -n "$md5_dest_file" -a -f "$md5_dest_file" ]; then
            if [ "$cmd" == "check" -o "$(echo $cmd|awk '{print $1}')" == "rm" ]; then
                 echo "Found: $file => $md5_dest_file"
                 return 1
            else
                 # Found same file. So, check destination directory is same or not
                 if [ -n "$dest_file" -a "$(dirname "$md5_dest_file")" == "$(dirname "$dest_file")" ]; then
                     echo "Found: $file => $md5_dest_file"
                     return 1
                 fi
            fi
        elif [ -n "$md5_dest_file" -a ! -f "$md5_dest_file" -a -n "$dest_file" -a -f "$dest_file" ]; then
            if _k_fprint_md5_ctl "del" "" "$md5path" "$file" ""; then
                 _k_fprint_md5_ctl "add" "fix" "$md5path" "$file" "$dest_file" || return 2
            fi
            echo "Found: $file => $dest_file"
            return 1
        elif [ -n "$md5_src_file" -a -f "$md5_src_file" ]; then
            if [ "$cmd" == "check" ]; then
                 echo "Found: $file => $md5_src_file"
                 return 1
            else
                 if [ -n "$dest_file" -a "$(dirname "$md5_src_file")" == "$(dirname "$dest_file")" ]; then
                     echo "Found: $file => $md5_src_file"
                     return 1
                 fi
            fi
        fi
    done
    while_return=$?
    [ "$while_return" == "0" ] && return 1
    return $(($while_return-1))
}

_k_fprint_cleanup_do() {
    local file finger_path dest keep_mod md5path mod chk_info info dest_arr dest_dir found_chk input remain
    md5path="$1"
    input="$2"
    mod="$3"
    keep_mod="$4"
#    [ -n "$input" ] || return 1
    [ -f "$md5path/info.txt" ] || return 1
    remain=$([ -f "$md5path/info.txt" ] && wc -l "$md5path/info.txt" | awk '{print $1}')
    (( $remain <= 1 )) && return 0

    IFS='|' read -a dest_arr <<< "$input"
    if [ "${#dest_arr[@]}" == "0" ]; then
        cat "$md5path/info.txt" | while read info_line; do
            (( $remain <= 1 )) && return 0
            md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
            if echo $(_k_file_ext "$(_k_file_name "$md5_dest_file")") | grep "^_k_D_">& /dev/null; then
                if [ -f "$md5_dest_file" ]; then
                    rm -f "$md5_dest_file" || return 1
                fi
                _k_fprint_md5_ctl "del" "" "$md5path" "" "$md5_dest_file"
                remain=$(($remain-1))
            fi
        done
        return $?
    fi

    for ((ii=0; ii<${#dest_arr[@]}; ii++)); do
     dest="${dest_arr[$ii]}"
     [ ! -d "$dest" ] && return 1
     if cat "$md5path/info.txt" | awk -F\| '{print $4}' | grep "^$dest" >& /dev/null; then
        cat "$md5path/info.txt" | while read info_line; do
            (( $remain <= 1 )) && return 0
            md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
            md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')

            if echo $(_k_file_ext "$(_k_file_name "$md5_dest_file")") | grep "^_k_D_">& /dev/null; then
                if [ -f "$md5_dest_file" ]; then
                    rm -f "$md5_dest_file" || return 1
                fi
                _k_fprint_md5_ctl "del" "" "$md5path" "" "$md5_dest_file"
                remain=$(($remain-1))
            fi

            if [ "$mod" == "del" ]; then
              # Find Del
              if [ -n "$(echo $md5_dest_file | grep "^$dest")" ]; then
                 if [ -n "$md5_src_file" -a -f "$md5_src_file" -a ! -n "$md5_dest_file" ]; then
                     _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" ""
                     remain=$(($remain-1))
                 elif [ -n "$md5_src_file" -a ! -f "$md5_src_file" -a ! -n "$md5_dest_file" ]; then
                     _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" ""
                     remain=$(($remain-1))
                 elif [ -n "$md5_dest_file" -a ! -f "$md5_dest_file" ]; then
                     _k_fprint_md5_ctl "del" "" "$md5path" "" "$md5_dest_file"
                     remain=$(($remain-1))
                 elif [ -n "$md5_dest_file" -a -f "$md5_dest_file" ]; then
                     rm -f "$md5_dest_file"
                     _k_fprint_md5_ctl "del" "" "$md5path" "" "$md5_dest_file"
                     remain=$(($remain-1))
                 fi
              fi
            else
              # Find Keep
              if [ -n "$(echo $md5_dest_file | grep "^$dest")" -a "$found_chk" != "1" ]; then
                 # found_chk=1 then keep only one file in the finding directory
                 # found_chk=0 then keep all file in the finding directory
                 [ "$keep_mod" == "all" ] && found_chk=0 || found_chk=1
              else
                 if [ -n "$md5_src_file" -a -f "$md5_src_file" -a ! -n "$md5_dest_file" ]; then
                     _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" ""
                     remain=$(($remain-1))
                 elif [ -n "$md5_src_file" -a ! -f "$md5_src_file" -a ! -n "$md5_dest_file" ]; then
                     _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" ""
                     remain=$(($remain-1))
                 elif [ -n "$md5_dest_file" -a ! -f "$md5_dest_file" ]; then
                     _k_fprint_md5_ctl "del" "" "$md5path" "" "$md5_dest_file"
                     remain=$(($remain-1))
                 elif [ -n "$md5_dest_file" -a -f "$md5_dest_file" ]; then
                     rm -f "$md5_dest_file"
                     _k_fprint_md5_ctl "del" "" "$md5path" "" "$md5_dest_file"
                     remain=$(($remain-1))
                 fi
              fi
            fi
        done
        [ "$?" == "1" ] && return 1
     elif cat "$md5path/info.txt" | awk -F\| '{print $3}' | grep "^$dest" >& /dev/null; then
        cat "$md5path/info.txt" | while read info_line; do
            md5_src_file=$(echo $info_line | awk -F\| '{print $3}')
            md5_dest_file=$(echo $info_line | awk -F\| '{print $4}')
            if echo $md5_src_file | grep "^$dest" >& /dev/null; then
                 _k_fprint_md5_ctl "del" "" "$md5path" "$md5_src_file" ""
                 _k_fprint_md5_ctl "add" "fix" "$md5path" "" "$md5_src_file"
                 echo "FixDB:source($md5_src_file) -> dest($md5_src_file)"
            fi
        done
     fi
    done # for ((ii=0
}

_k_fprint_cleanup() {
    local file finger_path dest cmd md5path mod chk_info info dest_arr dest_dir found_chk mod_arr
    file="$1"
    finger_path="$2"
    dest_dir="$3"
    mod="$4"
    _k_md5_cmd=$(_k_md5_cmd)
    [ ! -n "$file" -o ! -f "$file" ] && return 1
    [ ! -n "$finger_path" -o ! -d "$finger_path" ] && return 1
    [ ! -n "$dest_dir" ] && return 1
    md5path="$finger_path/$($_k_md5_cmd "$file")"

    [ -d "$md5path" ] || return 1
    if [ "$([ -f "$md5path/info.txt" ] && stat -f "%z" "$md5path/info.txt" || echo 0)" == "0" ]; then
       rm -fr "$md5path"
       return 1
    fi

    IFS=':' read -a mod_arr <<< "$dest_dir"
    _k_fprint_cleanup_do "$md5path" "${mod_arr[1]}" "del" "$mod"
    _k_fprint_cleanup_do "$md5path" "${mod_arr[0]}" "" "$mod"

    found_file="$([ -f "$md5path/info.txt" ] && echo $(cat "$md5path/info.txt" |awk -F\| '{if($4) printf "%s,",$4; else printf "%s,",$3;}'))"
    found_num=$([ -f "$md5path/info.txt" ] && wc -l "$md5path/info.txt" | awk '{print $1}')
    [ -n "$info" ] && echo "$info" || echo "Cleanup:$found_num: $file => $found_file"
    [ "$found_num" == "1" ] && return 0 || return 1
}

_k_fprint_md5() {
   local file finger_path dest cmd md5path mod chk_info info
   file="$1"
   finger_path="$2"
   dest="$3"
   cmd="$4"
   mod="$5"
   [ -n "$file" ] || return 1
   [ -f "$file" ] || return 1
   [ -n "$cmd" ] || cmd=check
   [ "$(echo $cmd|awk '{print $1}')" == "check" -o "$(echo $cmd |awk '{print $1}')" == "rm" ] && dest=""
   if [ -n "$dest" ]; then
      [ -d "$dest" ] && dest_file="$dest/$(basename "$file")" || dest_file="$dest"
   fi
   [ -n "$finger_path" ] || finger_path=$(dirname "$file")/.k_md5
   [ -d "${finger_path}" ] || return 1

   _k_md5_cmd=$(_k_md5_cmd)
   md5=$($_k_md5_cmd "$file")
   [ -n "$md5" ] || return 1
   md5path=$finger_path/$md5

   if [ "$mod" == "find" ]; then # command is find case use this section.
       if ! _k_fprint_md5_found_duplication "$file" "$dest_file" "$md5path"; then
            echo "Not found $file"
            return 1
       fi
       return 0
   fi

   if [ -d "$md5path" ]; then
       _k_fprint_md5_ctl "fix" "" "$md5path" "" ""
       [ -d "$md5path" ] || return 1

       if [ "$mod" == "duplicate" ]; then  # Check all dest files (dp_md5 case)
           info=$(_k_fprint_md5_found_duplication "$file" "$dest_file" "$md5path")
           chk_info=$?
       else  # Just check to dest dir (md5 case)
           info=$(_k_fprint_md5_found "$file" "$dest_file" "$cmd" "$md5path")
           chk_info=$?
       fi

       if [ "$chk_info" == "0" ]; then
              echo "$info"
              if [ "$(echo $cmd|awk '{print $1}')" == "rm" ]; then
                  if [ "$(awk -F\| -v dest_file="$file" '{if($4==dest_file||$4=="") printf "same"}' "$md5path/info.txt")" != "same" ]; then
                      #rm -f "$file" && echo "  $cmd : $file"
                      mv "$file" ~/.trash && echo "  $cmd : $file"
                  fi
              fi
              return 0
       else
              if [ "$cmd" == "check" ]; then
                  echo "$cmd $file $dest_file"
                  _k_fprint_md5_ctl "add" "$cmd" "$md5path" "$file" "$file" && return 0 || return 1
              elif [ "$(echo $cmd|awk '{print $1}')" == "rm" ]; then
                  echo "Skip: $file because not found in DB"
                  _k_fprint_md5_ctl "add" "init" "$md5path" "$file" "$file" && return 0 || return 1
              else
                  if [ -n "$dest_file" ]; then
                      dest_file=$(_k_file --new "$dest_file")
                      echo "$cmd $file $dest_file"
                      if [ ! -d "$(dirname "$dest_file")" ]; then
                         if [ "$(echo $cmd | awk '{print $2}')" == "-f" ]; then
                            mkdir -p "$(dirname "$dest_file")" 
                         else
                            echo "ERR: $(dirname "$dest_file") not found, Please use \"-f\" option for automatically create dir"
                            return 1
                         fi
                      fi
                      $cmd "$file" "$dest_file" || return 1
                      _k_fprint_md5_ctl "add" "$cmd" "$md5path" "$file" "$dest_file" && return 0 || return 1
                  else
                      echo "ERR: $cmd : $file : Destination not found"
                      return 1
                  fi
              fi
       fi
   fi

   # run command to file and create md5 of file when md5 dir not found
   if [ -n "$dest_file" ]; then
      if cmp "$dest_file" "$file" >& /dev/null; then
          echo "Same: $file => $dest_file"
          _k_fprint_md5_ctl "add" "$cmd" "$md5path" "$file" "$dest_file" && return 0 || return 1
      fi
      dest_file="$(_k_file --new "$dest_file")"
      echo "$cmd $file $dest_file"
      if [ ! -d "$(dirname "$dest_file")" ]; then
            if [ "$(echo $cmd | awk '{print $2}')" == "-f" ]; then
                mkdir -p "$(dirname "$dest_file")"
            else
                echo "ERR: $(dirname "$dest_file") not found, Please use \"-f\" option for automatically create dir"
                return 1
            fi
      fi
      $cmd "$file" "$dest_file" || return 1
   fi
   _k_fprint_md5_ctl "add" "$cmd" "$md5path" "$file" "$dest_file" && return 0 || return 1
}

_k_fprint_help() {
   echo "
$(basename $0) <command> <find path|file> <FP path> [ <dest> <sub cmd> ]

<FP path> : Fingerprint home path 
<sub cmd> : this command working with md5, dp_md5
   cp     : Copy source file to dest dir (-f : make a dir when not found dest dir)
   mv     : move source file to dest dir (-f : make a dir when not found dest dir)
   rsync  : sync source file to dest dir 
   check  : check or initial md5 data from source file.
   rm     : if found data then delete the source file

<command>
  : create md5 
  md5 <find path|file> <FP path> <dest dir> <sub cmd>

  : create md5 but checkup duplicated file in anywhere
  dp_md5 <find path|file> <FP path> <dest dir> <sub cmd>

  : find duplicated files
  find <find path|file> <FP path>

  : look history of the file
  history <find path|file> <FP path>

  : remove the file
  rm <find path|file> <FP path>

  : move file to different dir
  mv <find path|file> <FP path> <dest dir|file>

  : Clean up duplicated file ( only remain 1 file in <keep dir>'s directory file and delete all file in others dir) 
  : <keep dir[|dir2|dir3|..]> : finding order of checkup. finding dir will be remain
  : if not found any <keep dir> then no touch 
  : <del dir[|dir2|dir3|..]> : find delete list in <del dir>. (remain only 1 file)
  : <mod> : 'all' then keep all files in the <keep dir>, default (none) is keep only 1 file in the <keep dir>
  cleanup <find path/file> <FP path> \"<keep dir[|dir2|dir3|..]>[:<del dir[|dir2|...]>]\" [<mod>]

  help    : this screen

<finger_path> : default ( ~/.k_md5 )

* if not input <finger_path> then you can set _K_FINGER_MD5 like as...
_K_FINGER_MD5=~/.k_md5
"
   exit 
}

# Main function
_k_fp() {
    local ok find_path finger_path dest cmd mod

[ "$1" == "--help" -o "$1" == "help" -o "$1" == "-h" ] && _k_fprint_help
# check command 
ok=""
for ii in md5 rm history dp_md5 find cleanup; do
    [ "$1" == "$ii" ] && ok=1
done
[ "$ok" != "1" ] && _k_fprint_help

find_path="$2"
finger_path="$3"
dest="$4"
cmd="$5"
if [ "$1" == "dp_md5" ]; then
    fprint_cmd=_k_fprint_md5
    mod=duplicate
elif [ "$1" == "find" ]; then
    fprint_cmd=_k_fprint_md5
    mod=find
    dest=""
else
    fprint_cmd=_k_fprint_${1}
    mod=""
fi

if [ "$fprint_cmd" == "_k_fprint_md5" -a "$mod" != "find" ]; then
    # check <sub cmd>
    ok=""
    for ii in cp rsync mv check rm; do
        [ "$(echo $cmd | awk '{print $1}')" == "$ii" ] && ok=1
    done
    [ "$ok" != "1" ] && _k_fprint_help
fi

# check others
[ -n "$find_path" ] || _k_fprint_help
[ ! -f "$find_path" -a ! -d "$find_path" ] && return 1
[ -n "$finger_path" ] || finger_path="$_K_FINGER_MD5"
[ -n "$finger_path" ] || finger_path=~/.k_md5
[ -d "$finger_path" ] || mkdir -p "$finger_path"

#.k_md5 : for photo
#.k_md5_files : for files

#echo "$1 | $find_path | $finger_path | $dest | $cmd"
# run command
[ "$cmd" == "rsync" ] && cmd="rsync -a --progress"
find "$find_path" -type f | while read path_file; do
    echo "$path_file" | grep -e "/.cedata/" -e "\.cedata$" -e "/.ceid" -e "\.ceid$" -e ".DS_Store$" -e "/.DS_Store/" -e ".log$" -e ".txt$" -e "/.k_md5" -e "/.k_md5_files" -e "/Thumbs.db$" -e "\.THM$" -e "/_SYNCAPP" -e "/.com.apple" >& /dev/null && continue 
#    echo -n "Checking : $path_file => "
    $fprint_cmd "$path_file" "$finger_path" "$dest" "$cmd" $mod
done
}

# IF run a shell then run a shell. if load the shell then not running shell. just load
if [ "$(basename $0)" == "fp.k" ]; then
    declare -F _k_k >& /dev/null ||  source $_K_BIN/k.k
    _k_load_include $0

    # Run this script to main function
    _k_$(basename $0 | sed "s/${KTAG}$//g") "$@" || exit $?
fi


