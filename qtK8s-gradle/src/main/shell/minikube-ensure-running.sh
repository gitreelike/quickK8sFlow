#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Start a minikube if required. Extra script to be able to do it in parallel with build tasks.

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

option() {
	local val=${!2:-"$3"}
	log "$1 set to $val, \`export $2=...\` to customize"
	printf "%s" "$val"
}

is_driver() {
	[[ $driver == "$1" ]] || [[ ${MINIKUBE_DRIVER:-} == "$1" ]] || [[ $(minikube config get driver) == "$1" ]]
}

if ! minikube -p qtK8sShowcase status >/dev/null 2>&1; then
	old_kubecontext=$(kubectl config current-context 2>/dev/null || :)
	log Starting minikube...
	cpus=$(option "cpus" "MK_CPUS" "2")
	memory=$(option "memory" "MK_MEM" "4g")
	driver=$(option "driver" "MK_DRIVER" "docker")
	runtime=$(option "runtime" "MK_RT" "containerd")
	if is_driver docker || is_driver podman; then
		if [[ $runtime != "containerd" ]]; then
			logE "When using the docker driver, runtime should be set to containerd (export MK_RT=containerd). Current runtime: $runtime"
		fi
		ports=(
			"30080:30080"
		)
	else
		ports=()
	fi
	kubev=$(option "kubernetes version" "MK_KUBEV" "v1.27.4")
	minikube start \
		-p qtK8sShowcase \
		--cpus="$cpus" \
		--driver="$driver" \
		--memory "$memory" \
		--container-runtime "$runtime" \
		${ports:+$(printf -- "--ports %s " "${ports[@]}")} \
		--kubernetes-version="$kubev" \
		--keep-context \
		--delete-on-failure
	log The minikube profile is \`qtK8sShowcase\`. Pass \`-p qtK8sShowcase\` to minikube commands, or \`export MINIKUBE_PROFILE=qtK8sShowcase\` \
		in your environment.
	if [[ $old_kubecontext == qtK8sShowcase ]] || [[ -z $old_kubecontext ]]; then
		log Refreshing kubectl context \`qtK8sShowcase\`
		kubectl config use-context qtK8sShowcase
	fi
	# didWork trigger
	exit 100
fi
