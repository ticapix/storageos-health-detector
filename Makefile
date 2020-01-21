ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
NAME=$(shell basename $(ROOT_DIR))
REPO?=ticapix/$(NAME)
TAG?=latest

.PHONY: help

help:
	@echo "$(NAME)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m=> %s\n", $$1, $$2}'

storageos:
	curl -sSLo storageos https://github.com/storageos/go-cli/releases/download/1.2.2/storageos_linux_amd64
	chmod +x storageos

install: storageos

docker-build: install ## build docker image
	docker build -f Dockerfile -t $(REPO):master .
	docker tag $(REPO):master $(REPO):$(TAG)

docker-enter-image: docker-build  ## for local manual testing
	docker run -it --entrypoint sh $(REPO):master

docker-push: docker-build ## push docker image to hub.docker.io
	docker push $(REPO)

deploy: ## deploy plugin on the cluster
	kubectl apply -f setup/service-account.yaml
	kubectl apply -f setup/storageos-monitoring.yaml

undeploy: ## remove plugin from the cluster
	kubectl delete -f setup/storageos-monitoring.yaml || true
	kubectl delete -f setup/service-account.yaml || true

watch-log:
	kubectl -n storageos-operator logs -f `kubectl -n storageos-operator get pod -l app=node-problem-detector -o jsonpath='{.items[0].metadata.name}'`
	