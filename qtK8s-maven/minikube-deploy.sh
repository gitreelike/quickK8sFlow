#!/bin/sh

set -e -u

memory=${MINIKUBE_MEMORY:-2000mb}
cpus=${MINIKUBE_CPUS:-2}

export MINIKUBE_PROFILE=qtK8sShowcase

arg=${1:-}

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

mk_status() {
	minikube status >/dev/null 2>&1
}

current_ctx() {
	kubectl config current-context 2>/dev/null || printf "__unset"
}

startMinikubeWhenNecessary() {
	if ! mk_status; then
		echo Starting minikube
		minikube start --memory="$memory" --cpus="$cpus" --container-runtime=docker --ports "30080:30080"
	fi
}

switchContextWhenNecessary() {
  if [ "$(current_ctx)" != "${MINIKUBE_PROFILE}" ]; then
    kubectl config use-context "${MINIKUBE_PROFILE}"
  fi
}

warnIfContextChanged() {
  ctx=$(current_ctx)
  if [ "$original_ctx" != __unset ] && [ "$original_ctx" != "$ctx" ]; then
    echo "$(tput setaf 3)" This script changed the kubectl context from "$original_ctx" to "$ctx"!
    echo "$(tput setaf 3)" To restore your original context: run kubectl config use-context "$original_ctx"
  fi
}

#################
# Start of script
#################

script_dir="$(dirname "$(readlink "$0")")"
k8s_config_dir="$script_dir/../k8s-conf"

original_ctx=$(current_ctx)

(
  cd "$script_dir"
  
  startMinikubeWhenNecessary
  switchContextWhenNecessary

  if [ "$arg" != "nobuild" ]; then
    (
      # use minikube's docker daemon
      eval "$(minikube docker-env --shell=posix)"
      # build directly to minikube's docker daemon
      ./mvnw clean install jib:dockerBuild -Dmaven.test.skip=true
    )
  fi

  echo Deploying our application to K8S

  # we need to invalidate the old containers with the possibly old images
  # this can also be achieved by restarting all the relevant things via "kubectl rollout restart" after "kubectl apply"
  kubectl delete -f deployment.yaml || true

  kubectl apply -f "$k8s_config_dir"/deployment.yaml

  echo Waiting for deployment to finish
  kubectl rollout status deployment hello-world

  warnIfContextChanged
)