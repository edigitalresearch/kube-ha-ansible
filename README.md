# Kubernetes HA Ansible

This role sets up a HA Kubernetes cluster according to [https://kubernetes.io/docs/setup/independent/high-availability/](https://kubernetes.io/docs/setup/independent/high-availability/). For setting up the required infrastructure see - [https://github.com/dylanrhysscott/kube-ha-terraform/tree/master](https://github.com/dylanrhysscott/kube-ha-terraform/tree/master). Under the hood this role used `kubeadm` for management of the cluster. Once the cluster has been created the generated certificates will be downloaded to your local machine. Adding new masters is currently not supported.

You can also deploy a single master configuration with no load balancer if required.

## Defining Hosts

This role expects hosts to be grouped in the following way:

* `root_cluster` - The first control plane
* `second_cluster` - The second control plane
* `third_cluster` - The third control plane
* `kube_workers` - Cluster workers

An example hosts file may look like this:

```
[root_cluster]
1.1.1.1

[second_cluster]
2.2.2.2

[third_cluster]
3.3.3.3

[kube_workers]
4.4.4.4
5.5.5.5
6.6.6.6

[kube_masters:children]
root_cluster
second_cluster
third_cluster

[kubecluster:children]
kube_masters
kube_workers

```

## Configuring the cluster

By default this role will deploy a cluster with flannel networking and a load balancer in front of the stacked control. All variables are namespaced under a `kubernetes` key. The minimal requirements are specifying a load balancer domain and port

```
kubernetes:
  load_balancer:
    dns: cluster.example.com
    port: 443

```

The CNI for the cluster can be configured by adding a `networking` key with the `podCidr` and `podManifest` specified. The example for flannel can be seen below

```
networking:
  podCidr: 10.244.0.0/16
  podManifest: https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Additional API SANS can be added to the certificates by adding an `extra_sans` key to the load balancer configuration. This is optional

```
kubernetes:
  load_balancer:
    extra_sans:
      - my.extra.apiserver.domain
```

This is useful for if you are using an internal load balancer that has a private DNS name

## Example task with role

```
- name: Install Kubernetes
  hosts: all
  roles:
    - kube-ha
```

## Adding additional workers

Additional workers can be added to the cluster by:

1. Adding the new node to to the `kube_workers` group
1. Running the role again specifying both a limit of a cluster and the new worker IP with the `scale` tag. For example: `ansible-playbook -i hosts -u root -b --limit root_cluster,7.7.7.7 --tags=core,scale main.yml`

The initial cluster creation will be skipped by core components will be installed and the node joined via token

## Cloud Provider Integration

### Cloud Controller Manager

This role provides support for Cloud Controller Manager (CCM). This provides Kubernetes integration with various cloud providers. Specifically Persistent Volumes and Load Balancers.

**Note: At the time of writing CCM is bleeding edge and Kubernetes support is not yet ready. It is encouraged to use Kube Controller as support is more mature. CCM does not provide support for in tree storage plugins / load balancers out of the box. As the spec develops and cloud provider support decouples from core this should change**

* [https://kubernetes.io/docs/tasks/administer-cluster/running-cloud-controller/#limitations](https://kubernetes.io/docs/tasks/administer-cluster/running-cloud-controller/#limitations)
* [https://kubernetes.io/docs/tasks/administer-cluster/running-cloud-controller/](https://kubernetes.io/docs/tasks/administer-cluster/running-cloud-controller/)

The steps to enable this are listed for **documentation purposes only!**. To enable CCM support:

```
kubernetes:
  cloudController: true
```

Then run the CCM tags. For example: `ansible-playbook -i inventory -u root -b playbooks/kube-ha.yml --tags=ccm`. This will update flags to the kubelet and apply the relevant taints. You must then deploy the cloud controller with your environment configuration: [https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/admin/cloud/ccm-example.yaml](https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/admin/cloud/ccm-example.yaml)

## Operating in standalone mode

A standalone non HA cluster can be deployed in the same way by setting `kubernetes.ha` to `false`. This removes the requirement for a load balancer and the `second_cluster` and `third_cluster` groups. In standalone mode you must specify an advertise address. In HA mode it is assumed there is an `eth0` adapter with the private IP address to advertise. In future both methods should pick the correct advertise IPs.

```
kubernetes:
  networking:
    advertiseAddress: 1.1.1.1
  ha: false
```

```
[root_cluster]
1.1.1.1

[kube_workers]
2.2.2.2
3.3.3.3
4.4.4.4

[kube_masters:children]
root_cluster

[kubecluster:children]
kube_masters
kube_workers
```
