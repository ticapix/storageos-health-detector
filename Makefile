REPO_HOST?=ticapix
REPO=$(REPO_HOST)/storageos-health-detector
TAG=0.2

help:
	echo "make build"

storageos:
	curl -sSLo storageos https://github.com/storageos/go-cli/releases/download/1.2.2/storageos_linux_amd64
	chmod +x storageos

docker-build: storageos
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
	