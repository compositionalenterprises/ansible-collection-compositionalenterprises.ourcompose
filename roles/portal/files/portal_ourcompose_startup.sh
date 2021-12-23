#!/bin/bash
set -exv

# Figure out which storage location we should be looking at for portal
storage='local'
if [[ -d /srv/remote/portal_storage/ansible ]]; then
  storage='remote'
fi

# Get the vault pass and the collection version from the existing
# containers/directories
vault_pass=$(docker inspect portal --format '{{json .Config.Env}}' | grep -oe 'ENVIRONMENT_VAULT_PASSWORD=[a-zA-Z0-9_-]\+' | cut -d '=' -f 2)
if [[ -z ${vault_pass} ]]; then
  vault_pass='notnil'
fi
coll_vers=$(docker inspect portal --format '{{json .Config.Env}}' | grep -oe 'ROLE_BRANCH=[a-zA-Z0-9_.-]\+' | cut -d '=' -f 2)

# Export the ourcomposebot read-only key into the environment
if ! grep -R 'ourcompose_portal_ourcomposebot_ro_key' /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml; then
  ro_key=$(docker inspect portal --format '{{json .Config.Env}}' | grep -oe 'OURCOMPOSEBOT_RO_KEY=[^"]\+' | cut -d '=' -f 2-)
  # Don't add the key if it's empty
  if [[ ! -z ${ro_key} ]]; then
    echo "ourcompose_portal_ourcomposebot_ro_key: |" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
    echo "  $(echo -e "${ro_key}" | sed '1q;d')" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
    echo "  $(echo -e "${ro_key}" | sed '2q;d')" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
    echo "  $(echo -e "${ro_key}" | sed '3q;d')" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
    echo "  $(echo -e "${ro_key}" | sed '4q;d')" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
    echo "  $(echo -e "${ro_key}" | sed '5q;d')" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
    echo "  $(echo -e "${ro_key}" | sed '6q;d')" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
    echo "  $(echo -e "${ro_key}" | sed '7q;d')" >> /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
  fi
fi

# Get the string to pass to the cert_volume when nginx is restarted
if ! grep -R 'ourcompose_common_cert_volume' /srv/${storage}/portal_storage/ansible/environment; then
  certs_mount=$(docker inspect nginx | grep -A 4 'Binds' | tail -n 4 | grep -v srv | cut -d '"' -f 2 | cut -d ':' -f 1-2)
fi

# Remove all of the configs that are present in the nginx custom config because we don't know what's running right now, and what's not
# Figure out which storage location we should be looking at for nginx
nginx_storage='local'
if [[ -e /srv/remote/nginx_conf.d/default.conf ]]; then
  nginx_storage='remote'
fi
# Remove all the custom configs
find /srv/${storage}/nginx_conf.d/$(ls /srv/${storage}/nginx_conf.d/ | grep -v conf)/ -type f -exec rm {} \;

# ourcompose_nginx_rewrite_default: prevent overwriting nginx's default.conf and having to deal with all of the complicated templating there of the certs
# ourcompose_portal_allow_cr: this skips the check to see if commands_receivable is running so that restarting portal itself can be ran via c_r
echo "{'script': 'playbooks/run_ourcompose_roles.yml', \
       'vault_password': '${vault_pass}', \
       'collection_version': '${coll_vers:-master}', \
       'args': {
         'ourcompose_common_cert_volume': '${certs_mount}', \
         'ourcompose_nginx_rewrite_default': 'no', \
         'ourcompose_portal_allow_cr': 'yes', \
         'ourcompose_portal_role_branch': '${coll_vers:-master}' \
         } \
       }" | \
  socat -t 1000 UNIX-CONNECT:/var/run/commands_receivable.sock -

# Remove the ourcomposebot read-only key from the environment
# TODO: Why are we doing this again?
if grep -R 'ourcompose_portal_ourcomposebot_ro_key' /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml; then
  sed -i "/ourcompose_portal_ourcomposebot_ro_key:/I,+7 d" /srv/${storage}/portal_storage/ansible/environment/group_vars/all/all.yml
fi
