#!/usr/bin/env bash

set -xeuo pipefail

TOOLS=("docker docker-machine docker-compose")
DOCKER_MACHINE=$(which docker-machine)
DOCKER_COMPOSE=$(which docker-compose)

function check_tools(){
   IFS=$" "
   for e in ${TOOLS[@]}
   do
      TOOL="$e"
      if ! [ -x "$(command -v "$TOOL")" ]; then
  	    echo Error "$TOOL" not found. Exiting >&2
  	    exit 1
      fi
   done
}

function init_docker_machine(){
   if [[ "$(already_exists)" ]]; then
        :
    else
        ($DOCKER_MACHINE create --driver virtualbox default; eval "$($DOCKER_MACHINE env default)")
    fi
}

function already_exists() {
   local exists=$($DOCKER_MACHINE ls -q | grep '^default$')

   echo "$exists"
}

function start_services(){
   exec "$DOCKER_COMPOSE up --build -d"
}

check_tools
init_docker_machine
start_services