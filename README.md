# StorageOS plugin for [Node Problem Detector](https://github.com/kubernetes/node-problem-detector)

When StorageOS is used on a managed platform such as [OVH Managed Kubernetes Service](https://www.ovh.com/world/public-cloud/kubernetes/), the end user doesn't have access the cluster node.

The cluster rolling upgrade is done by the service provider. Once the node `N` is `Ready`, it'll update the node `N+1` if in `Ready` state.

By default, the update process is unaware of higher level of service deployed by the user.

To keep data consistency, the end-user must signal to the update process whether or not the node can be updated.

This is the goal of this plugin.

## Build the docker image

```shell
make docker-build
```
