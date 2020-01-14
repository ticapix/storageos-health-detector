ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
NAME=$(shell basename $(ROOT_DIR))
REPO_HOST?=ticapix
REPO=$(REPO_HOST)/storageos-health-detector
TAG=0.2

.PHONY: help

help:
	$(ECHO) "$(NAME)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m=> %s\n", $$1, $$2}'

storageos:
	curl -sSLo storageos https://github.com/storageos/go-cli/releases/download/1.2.2/storageos_linux_amd64
	chmod +x storageos

install: storageos

docker-build: install
	docker build -f Dockerfile -t $(REPO):master .
	docker tag $(REPO):master $(REPO):$(TAG)

docker-inspect: docker-build
	docker image history --no-trunc $(REPO):master

docker-enter-image: docker-build
	docker run -it --entrypoint sh $(REPO):master

docker-push: docker-build
	docker push $(REPO)

deploy: docker-push
	kubectl apply -f setup/service-account.yaml
	kubectl apply -f setup/node-problem-detector.yaml

undeploy:
	kubectl delete -f setup/node-problem-detector.yaml
	kubectl delete -f setup/service-account.yaml

watch-log:
	kubectl -n storageos-operator logs -f `kubectl -n storageos-operator get pod -l app=node-problem-detector -o jsonpath='{.items[0].metadata.name}'`
	