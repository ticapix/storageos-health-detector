Travis integration: [![Build Status](https://travis-ci.org/ticapix/storageos-health-detector.svg?branch=master)](https://travis-ci.org/ticapix/storageos-health-detector)

Docker Hub: https://hub.docker.com/r/ticapix/storageos-health-detector


# StorageOS plugin for managed Kubernetes service

When StorageOS is used on a managed platform such as [OVH Managed Kubernetes Service](https://www.ovh.com/world/public-cloud/kubernetes/), the end user doesn't have access the cluster node.

The cluster rolling upgrade is done by the service provider. Once the node `N` is `Ready`, it'll update the node `N+1` if in `Ready` state.

By default, the update process is unaware of higher level of service deployed by the user.

To keep data consistency, the end-user must signal to the update process whether or not the node can be updated.

This is the goal of this plugin.

## Prepare your environment

First thing is to setup your environment. I usually put all that part in a `activate` file. Edit the file according to our setting.

```shell
. ./activate
```

## Install StorageOS

Follow the instruction here https://docs.storageos.com/docs/platforms/kubernetes/install/1.15

**Note**: you must use an external etcd

or with helm

```shell
helm repo add storageos https://charts.storageos.com
helm install \
  --set cluster.namespace=storageos \
  --set cluster.secretRefName=storageos-api \
  --set cluster.kvBackend.embedded=false \
  --set cluster.kvBackend.address=http://<ETCD_SERVER>:2379 \
  --set cluster.kvBackend.backend=etcd \
  --set cluster.csi.enable=true \
  --namespace storageos-operator \
  --name storageos \
  storageos/storageos-operator
```

(How to install helm: https://gist.github.com/ticapix/762878ad070fcc1d164ff35fbc25b5ca)

## Deploy the service

The DaemonSet can be deployed and undeployed with `make`.

```shell
make deploy
# or
make undeploy
```

*TODO: use helm instead*
