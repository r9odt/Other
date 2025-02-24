#!bin/bash
export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"
[ -d ${TF_PLUGIN_CACHE_DIR} ] || mkdir -p ${TF_PLUGIN_CACHE_DIR}
