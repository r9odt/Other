#!/bin/bash
# If bash reloaded - reset config to empty.
CURRENT_AWS_PROFILE="unknown"
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

set_aws() {
  which aws > /dev/null 2>&1
  aws_cli_is_exist=$?
  
  if [ 0 -ne ${aws_cli_is_exist} ]; then
    printf "Aws CLI not found in PATH. Please install it\n"
    return 1
  fi
  
  if [ -z ${1} ]; then
    printf "Empty profile string, profile not changed\n"
    return 2
  fi
  _AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile ${1} 2>/dev/null)
  aws_access_key_export_code=$?
  _AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile ${1} 2>/dev/null)
  aws_secret_access_key_export_code=$?
  
  if [ 0 -ne ${aws_access_key_export_code} ] || 
  [ 0 -ne ${aws_secret_access_key_export_code} ]; then
    printf "Export error\n"
    printf "aws_access_key_export_code: ${aws_access_key_export_code}\n"
    printf "aws_secret_access_key_export_code: ${aws_secret_access_key_export_code}\n"
    return 3
  fi

  CURRENT_AWS_PROFILE=${1}
  export AWS_ACCESS_KEY_ID=${_AWS_ACCESS_KEY_ID}
  export AWS_SECRET_ACCESS_KEY=${_AWS_SECRET_ACCESS_KEY}
  printf "Set profile ${CURRENT_AWS_PROFILE}\n"

  return 0
}

get_aws() {
  which aws > /dev/null 2>&1
  aws_cli_is_exist=$?
  
  if [ 0 -ne ${aws_cli_is_exist} ]; then
    printf "Aws CLI not found in PATH. Please install it\n"
    return 1
  fi

  aws_list_profiles_cmd="aws configure list-profiles"

  printf "Current profile: ${CURRENT_AWS_PROFILE}\n\n"
  printf "Available profiles:\n"
  ${aws_list_profiles_cmd}
}

