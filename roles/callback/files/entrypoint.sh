#!/bin/bash
set -evx

if [ -z "${CALLBACK_USER}" ]; then
  echo "Need the user to setup as CALLBACK_USER env variable. Abnormal exit ..."
  exit 2
fi

if [ -z "${CALLBACK_KEYS}" ]; then
  echo "Need your ssh public key as AUTHORIZED_KEYS env variable. Abnormal exit ..."
  exit 1
fi

# Create the user
if ! id ${CALLBACK_USER} > /dev/null 2>&1; then
    useradd --shell /bin/rbash --create-home ${CALLBACK_USER}
fi

# Add the .ssh key directory and directory for the privkeys
mkdir -p /home/${CALLBACK_USER}/instance_privkeys/
chown -R ${CALLBACK_USER}:${CALLBACK_USER} /home/${CALLBACK_USER}/instance_privkeys/
chmod -R 0700 /home/${CALLBACK_USER}/instance_privkeys/

# Setup and secure non_writable_dir which we will use as the location of the user
mkdir -p /home/${CALLBACK_USER}/non_writable_dir
chown -R ${CALLBACK_USER}:${CALLBACK_USER} /home/${CALLBACK_USER}/non_writable_dir
chmod -R a-r /home/${CALLBACK_USER}/non_writable_dir

# Setup Privkey programs
mkdir -p /home/${CALLBACK_USER}/programs
chown -R  ${CALLBACK_USER}:${CALLBACK_USER} /home/${CALLBACK_USER}/programs
cp /usr/local/bin/setup_privkey.sh /home/${CALLBACK_USER}/programs/
cp /usr/local/bin/teardown_privkey.sh /home/${CALLBACK_USER}/programs/

# Setup Bash Profile and make it immutible (chattr +1). Only if we haven't set it up before
if ! touch /home/${CALLBACK_USER}/.bash_profile; then
  chattr -i /home/${CALLBACK_USER}/.bash_profile
  cat << EOF > /home/${CALLBACK_USER}/.bash_profile
# .bash_profile  

# Get the aliases and functions  
if [ -f ~/.bashrc ]; then  
    . ~/.bashrc  
fi  

# Change to a non-writable directory
cd /home/${CALLBACK_USER}/non_writable_dir

# User specific environment and startup programs  
readonly PATH=/home/${CALLBACK_USER}/programs  
export PATH

# Turn off the history
shopt -u -o history

EOF
  chattr +i /home/${CALLBACK_USER}/.bash_profile
fi

# Set the authorized keys stuffs and chown the whole dir to that user
mkdir -p /home/${CALLBACK_USER}/.ssh/
chown -R ${CALLBACK_USER}:${CALLBACK_USER} /home/${CALLBACK_USER}/.ssh/
chmod -R 0700 /home/${CALLBACK_USER}/.ssh/
echo "Populating ${CALLBACK_USER}/.ssh/authorized_keys with the value from AUTHORIZED_KEYS env variable ..."
echo "${CALLBACK_KEYS}" > /home/${CALLBACK_USER}/.ssh/authorized_keys
chown -R ${CALLBACK_USER}:${CALLBACK_USER} /home/${CALLBACK_USER}/.ssh/

# Execute the CMD from the Dockerfile:
exec "$@"
