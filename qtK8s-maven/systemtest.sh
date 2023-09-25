#!/bin/sh

set -e -u

####################
# Start of functions
####################

readlink() {
	if [ "$(uname)" = Darwin ]; then
		command readlink "$1" || printf "%s\n" "$1"
	else
		command readlink -e "$1"
	fi
}

#################
# Start of script
#################

script_dir="$(dirname "$(readlink "$0")")"

(
  cd "$script_dir"

  ./minikube-deploy.sh

  ./mvnw verify -pl systemtest -Psystemtest
)