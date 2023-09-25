#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Ensures images exists, but don't load them again if they do.
# Expects pairs in the form
# 	"qtk8s:0.0.1-SNAPSHOT" /[…]/theApplication/build/jib-image.tar
# as arguments.
# $0 image-name tar [image-name tar]...

readlink() {
	if [[ $(uname) == Darwin ]]; then
		command readlink "$1" || printf "%s\n" "$1"
	else
		command readlink -e "$1"
	fi
}

script_dir="$(dirname "$(readlink "$0")")"

# shellcheck disable=SC1091
. "$script_dir"/_commons.sh

(
	cd "$script_dir"/../../..
	while [ $# -gt 0 ]; do
		image=$1
		shift
		tar=$1
		shift

    "$script_dir"/minikube-load-image.sh "$image" "$tar" &
    didWork=1
	done

	wait

	if [[ -n ${didWork:-} ]]; then
		# didWork trigger in gradle
		exit 100
	fi
)
