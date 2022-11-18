#!/bin/bash
# Helper tool too install ansible and execute a playbook

########
# Config
########
INVENTORY_FILE=""
REQUIREMENTS_FILE=""
PLAYBOOK_FILE="plbook-lxcontainer-osquerybuilder.yaml"
ANSIBLE_PIP_PACKAGE="ansible-core>=2.11"
ANSIBLE_PLAY_HOST_FILTER=""
END_MSG="Installation finished, now you can login with osquery user, change o \$HOME/workspace/osquery path and build osquery, extensions, etc."

###########
# Functions
###########

##
# Simple logging function
##
# $2 Message
# $1 level from -2 to 4: -2 is ERROR (EE), -1 is Warning (!!) 0 to 4 is a higher to lower mark
##
function log() {
  local levels=("(**)" "(++)" "(--)" "(··)")
  local colorMods=("\033[32;1m" "\033[34;1m" "\033[35m" "\033[37;1m")
  local levelStr="(  )"
  local colorMod=""
  if [ $1 -eq -1 ]
  then
    levelStr="(!!)"
    colorMod="\033[33;5;1m"
  elif [ $1 -lt 0 ]
  then
    levelStr="(EE)"
    colorMod="\033[31;1m"
  elif [ $1 -lt 4 ]
  then
    levelStr=${levels[$1]}
    colorMod=${colorMods[$1]}
  fi

  if [ "${LOG_MSG_COLORS}" == "yes" ]
  then
    levelStr="${colorMod}${levelStr}\033[0m"
    echo -e "$levelStr $2"
  else
    echo "$levelStr $2"
  fi
}

##
# Check if command exists in quiet mode using `type` command
#   Status variable must be loaded to check if command exists.
#   For example checkCmd which && echo "which found" || echo "which NOT found"
##
# $1 command to check
##
function checkCmd() {
  type -t "$1" >/dev/null
}

installPip3() {
  local packages="python3-pip python3-setuptools"
  log 0 "Installing pip"

  local cmd
  if checkCmd "dnf"
  then
    cmd="dnf install -y"
  elif checkCmd "yum"
  then
    cmd="yum install -y"
  else
    cmd="apt update && apt install -y"
  fi

  log 1 "packages: ${packages}"
  log 2 "pkg mgr cmd: $cmd"
  /bin/bash -c "$cmd $packages"
}

installAnsible() {
  log 0 "Installing Ansible"
  log 1 "Update pip"
  pip3 install --upgrade pip
  log 1 "pip package: ${ANSIBLE_PIP_PACKAGE}"
  pip3 install "${ANSIBLE_PIP_PACKAGE}"
}

ansibleRequirements() {
  log 0 "Installing Ansible requirements"
  if [ "${REQUIREMENTS_FILE}" != "" ] && [ -f "${REQUIREMENTS_FILE}" ]
  then
    log 1 "REQUIREMENTS_FILE: ${REQUIREMENTS_FILE}"
    ansible-galaxy install -r "${REQUIREMENTS_FILE}"
  else
    log 1 "REQUIREMENTS_FILE is not defined or it is not a file"
  fi
}

execPlaybook() {
  log 0 "Running ansible playbook"
  local extraOpts=""
  if [ "${INVENTORY_FILE}" != "" ] && [ -f "${INVENTORY_FILE}" ]
  then
    extraOpts="${extraOpts} -i \"${INVENTORY_FILE}\""
  fi
  if [ "${ANSIBLE_PLAY_HOST_FILTER}" != "" ]
  then
    extraOpts="${extraOpts} --limit \"${ANSIBLE_PLAY_HOST_FILTER}\""
  fi
  log 1 "Playbook file ${PLAYBOOK_FILE}"
  log 2 "Ansible opts: $extraOpts"
  ansible-playbook $extraOpts "${PLAYBOOK_FILE}"
}

endMsg() {
  log -1 "${END_MSG}"
}

installPip3
installAnsible
ansibleRequirements
execPlaybook
endMsg
