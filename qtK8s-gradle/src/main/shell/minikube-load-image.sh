#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Force-load image (name=$1, file=$2).

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

tmp=$(mktemp -d)

cleanup() {
	if [[ -d $tmp ]]; then
		rm -rf "$tmp"
	fi
}
trap cleanup EXIT

image=$1
tar=$2

currdir=$PWD
(
	cd "$script_dir"/../../..

	logI "Loading image \"$image\" ($(maybeRelative "$currdir" "$tar"))."
	runtime=$(
		minikube profile list -o json |
			yq -r ".valid[] | select(.Name == \"${MINIKUBE_PROFILE:-qtK8sShowcase}\") | .Config.KubernetesConfig.ContainerRuntime"
	)
	if [[ $runtime == containerd ]]; then
		# This is quicker than minikube image load by preventing a useless tempfile.
		minikube -p "${MINIKUBE_PROFILE:-qtK8sShowcase}" ssh --native-ssh=false -- \
			sudo /usr/bin/ctr -n=k8s.io images import - <"$tar" >/dev/null
	else
		# NOTE: This operation appears to be useless, but is needed to work around a minikube bug:
		# minikube image load jib-image.tar copies the file to /var/lib/minikube/images/jib-image.tar in the minikube VM
		# before importing it with `/usr/bin/ctr -n=k8s.io images import /var/lib/minikube/images/jib-image.tar`.
		# This breaks when two images that have the same source file name (jib-image.tar), but different source directories.
		# Minikube will in parallel write both sources to the same file, and actually lead to Go panics and/or coredumps in
		# the minikube VM, but suprpess the errors completely and make the operation look successful.
		# The issue can only be seen in e.g. `minikube ssh sudo journalctl` or `minikube logs`.
		#
		# The workaround is to copy all source image tars to unique names in a temporary
		# directory before importing them.
		# Copy each jib-image.tar to a tempory directory with a distinct file name.
		# Rename Workaround for
		tmpfile=$(mktemp "$tmp"/XXXXXXXXXX)
		cp "$tar" "$tmpfile"

		minikube -p "${MINIKUBE_PROFILE:-qtK8sShowcase}" image load "$tmpfile"
	fi
)
