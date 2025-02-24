#!/bin/bash
# Script for check users password using shadow file
# It is not working with FreeIPA accounts
wordlist=($(cat wordlist || echo a))

# Give all users which are truthly 'users'
users=$(getent passwd |
  grep -vE '(nologin|false)$' |
  awk -F: -v min=$(awk '/^UID_MIN/ {print $2}' /etc/login.defs) \
    -v max=$(awk '/^UID_MAX/ {print $2}' /etc/login.defs) \
    '{if(($3 >= min)&&($3 <= max)) print $1}' |
  sort -u)

for user in ${users[@]}; do
  userline=$(getent shadow ${user} | cut -f2 -d:)
  OFS=$IFS
  IFS='$'
  a=($userline)
  IFS=$OFS
  is_md5=false
  if [[ "${a[1]}" == "" && "${a[2]}" == "" ]]; then
    a[1]=1
    a[2]=${userline}
    is_md5=true
  fi
  for pass in ${wordlist[@]} ${user}; do
    if [[ is_md5 == true ]]; then
      if [[ "$(echo -n "${pass}" | md5sum)" = "${userline}" ]]; then
        echo "${user}:${pass}" 1>&2
        echo "${user}"
      fi
    fi
    if [[ "$(echo -n "${pass}" | openssl passwd -"${a[1]}" -salt "${a[2]}" -stdin 2>>/dev/null)" = "${userline}" ]]; then
      echo "${user}:${pass}" 1>&2
      echo "${user}"
    fi
  done
done
