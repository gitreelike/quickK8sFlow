#!/usr/bin/env bash

set -e
set -u
set -o pipefail

readlink() {
	if [[ $(uname) == Darwin ]]; then
		command readlink "$1" || printf "%s\n" "$1"
	else
		command readlink -e "$1"
	fi
}

script_dir="$(dirname "$(readlink "$0")")"
. "$script_dir"/_commons.sh

(
	cd "$script_dir"/../../../../k8s-conf

  # we need to invalidate the old containers with the possibly old images
  # this can also be achieved by restarting all the relevant things via "kubectl rollout restart" after "kubectl apply"
	kubectl delete -f deployment.yaml || true

	# install the system
	kubectl apply -f deployment.yaml

  log "Waiting for deployment to start..."
	kubectl rollout status deployment/hello-world
)
