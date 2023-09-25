#!/usr/bin/env bash

set -e
set -u
set -o pipefail

_log() {
	local pre=$1
	shift
	local post=$1
	shift

	{
		printf "%s  " "$(date +"%Y-%m-%dT%H:%M:%SZ")"
		printf "%s" "$pre"
		printf "%s " "$@"
		printf "%s" "$post"
		printf "\n"
	} >&2
}

log() {
	_log "" "" "$@"
}

# Error, red
logE() {
	_log "$(tput setaf 1)" "$(tput sgr0)" "$@"
}

# Info, green
logI() {
	_log "$(tput setaf 2)" "$(tput sgr0)" "$@"
}

die() {
	logE Fatal: "$@"
	exit 1
}

dir() {
	mkdir -p "$1"
	printf "%s" "$1"
}

readlink() {
	if [[ $(uname) == Darwin ]]; then
		command readlink "$1" || printf "%s\n" "$1"
	else
		command readlink -e "$1"
	fi
}

find_up() {
	local boundary
	boundary=$(readlink "$1")
	local dir
	dir=$(readlink "$2")
	local target
	target=$3
	local abs
	abs=$(printf "%s/%s" "$dir" "$target")
	if [[ -f $abs ]]; then
		printf "%s\n" "$abs"
	elif [[ ! -d $dir || $dir == "$boundary" ]]; then
		return 1
	else
		find_up "$boundary" "$(dirname "$dir")" "$target"
	fi
}

gradlew() {
	local gradle
	gradle=$(find_up "${WORKSPACE:-"$HOME"}" "$PWD" gradlew)
	found=$?
	if [[ $found != 0 ]]; then
		logE "Unable to find gradlew in any parents until $WORKSPACE, invoking global gradle!"
		command gradle "$@"
	else
		"$gradle" "$@"
	fi
}

gradle() {
	gradlew --continue "$@"
}

is_mk_docker() {
	minikube profile list -o json | jq -e '.valid[] | select(.Name == "qtK8sShowcase") | .Config.Driver == "docker"' >/dev/null
}

maybeRelative() {
	if ! [[ $(uname) == Darwin ]]; then
		command realpath --relative-to "$1" -e "$2"
	fi
}
