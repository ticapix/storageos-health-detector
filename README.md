# StorageOS plugin for [Node Problem Detector](https://github.com/kubernetes/node-problem-detector)

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

## Deploy the service

The DaemonSet can be deployed and undeployed with `make`.

```shell
make deploy
# or
make undeploy
```

*TODO: use helm instead*

## Testing

While looking at kube-apiserver event with `kubectl get events -w` in a separate terminal, try to start/stop nodes with `openstack server start|stop <node_name>` and check data consistency.

