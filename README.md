# Introduction

This set of demos and lab goes along with the coursera course: `Network Principles in Practice: Linux Networking`.   This particular module was on Kubernetes and Kubernetes networking.  

You are welcome to run this code and I try to make it as self explanatory as possible, but some of the explanation will be in the videos for the course.



# Vagrantfile

A Vagrantfile is provided that will create a Ubuntu 22.04 VM, and install the needed software on the VM.

This was tested using vagrant VirtualBox running on Windows 11.

```
vagrant up
```


Configure your ssh client with the following.  I use [MobaXterm](https://mobaxterm.mobatek.net/).
```
Hostname/IP address: 127.0.0.1
Port number: 2222
Username: vagrant
Private Key: <path/to/private_key>
Note: you’ll want x11 forwarding on
```

To get the location of the private key:

```
vagrant ssh-config
```


When you want to stop the VM, you can either run `vagrant suspend` to save the state so you can resume it later with `vagrant up`, or `vagrant halt` to shut the VM down.


# For exploring Kubernetes

We use [Kubernetes in Docker (KinD)](https://kind.sigs.k8s.io/) to create a Kubernetes cluster.  Provided are a few sample configuration files (under cluster-config directory), but kind is simple to use.

```
kind create cluster --config ./cluster-configs/1master2worker.yaml
```

Also provided are some sample Pod, Service, and Deployment configurations.

```
kubectl apply -f pod-configs/simple-nginx.yaml
```

# For making a network plugin

The core of the material centers around creating a CNI network plugin.  We do this in bash, and it applies what we covered in the rest of the modules.  There are two main files - a configuration file, which gets put in /etc/cni/net.d, and an executable, which gets put in /opt/cni/bin.  We start with a skeleton - which won't work, but is enough to see it getting called by looking at the log file.  Then, we have a full example (nppnet that is very basic).

Below is a walkthrough of one possible way to install and run the network plugin.

First, create directories that will be mounted in the docker containers created with kind (representing the Kubernetes nodes).

```
run ./make_dirs.sh
```

Then, create the cluster with kind.  This config will spin up 1 control plane node and 2 workers, and will mount a directory for each.

``` 
kind create cluster --config ./cluster-configs/1master2workerMount.yaml
```

Next, you need to edit nppnet-install.sh to set the IP addresses - instructions are in the file.  Then run it.  It's useful to look at the script to see what it is doing - you can even do each of the commands manually to really see how it's working.

```
./nppnet-install.sh
```

At this point, we have a network plugin installed, so you can run some pods.

```
kubectl apply -f pod-configs/forexec1-node1.yaml
kubectl apply -f pod-configs/forexec2-node1.yaml
kubectl apply -f pod-configs/forexec3-node2.yaml
```

Get the IP addresses of the pods

```
kubectl get pods -o wide
```

Ping each other pod. e.g., if forexec1 was 10.244.2.2 and you wanted to ping from forexec3, do this:

```
kubectl exec -it forexec3 -- ping 10.244.2.2
```

To get inside of worker 1:

```
docker exec -it kind-worker /bin/bash
```

Then you can do things like:

```
cat /var/log/nppnet.log   #(to see the output of the nppnet plugin
ls /opt/cni/bin/   #(you should see nppnet)
ls /etc/cni/net.d/ #(you should see 09-nppnet.conf)
ip netns
crictl ps
```

# To clean up

To delete a pod:

```
kubectl delete --force pod forexec1
```
(you should see the DEL command show up in the /var/log/nppnet/log - which we didn't do anything for, other than print a message)


To delete the cluster:

```
kind delete cluster
```

# License

For all files in this repo, we follow the MIT license.  See LICENSE file.

