#!/bin/bash

# Instructions: 
# 1) in the first section below, set the IP addresses
# 2) then run this script on the host - assumes kind cluster is named kind.  And it has 2 workers (kind-worker and kind-worker2)
#    run from directory of git repo (tmp/w1 tmp/w2 cni should each be sub directories)


################

## kubectl get -o wide
## Then correct the IP addresses
controlplane_ip="172.18.0.4"
worker_ip="172.18.0.2"
worker2_ip="172.18.0.3"

## kind's default cni picks one of 10.244.0.0/24, 10.244.1.0/24, or 10.244.2.0/24 for the pods on that node.
## To determine, run ip route on worker and worker2
##   docker exec kind-worker ip route
##   docker exec kind-worker2 ip route

## The missing one is what that node's pod network will be.
## if the output includes routes for 10.244.0.0/24 and 10.244.1.0/24, that set the respective node's value to 2
## if the output includes routes for 10.244.0.0/24 and 10.244.2.0/24, that set the respective node's value to 1
## if the output includes routes for 10.244.1.0/24 and 10.244.2.0/24, that set the respective node's value to 0

worker_nodesubnet="2"
worker2_nodesubnet="1"

# For example, this sequence of commands indicates I should set worker_nodesubnet to 2:
#vagrant@ubuntu-jammy:~/mod5$ docker exec -it kind-worker /bin/bash
#root@kind-worker:/# ip route
#default via 172.18.0.1 dev eth0
#10.244.0.0/24 via 172.18.0.4 dev eth0
#10.244.1.0/24 via 172.18.0.3 dev eth0
#172.18.0.0/16 dev eth0 proto kernel scope link src 172.18.0.2

#######################


## 

cp ./cni/nppnet ./tmp/w1
cp ./cni/nppnet ./tmp/w2

kubectl label node kind-worker node=node1
kubectl label node kind-worker2 node=node2




# Create network on worker 1

docker exec kind-worker ip link add cni0 type bridge
docker exec kind-worker ip link set cni0 up
docker exec kind-worker ip addr add 10.244.$worker_nodesubnet.1/24 dev cni0


# Create the conf file for worker 1
echo "
{
        \"cniVersion\": \"0.3.1\",
        \"name\": \"nppnet\",
        \"type\": \"nppnet\",
        \"subnet_network\": \"10.244\",
        \"subnet_node\": \"$worker_nodesubnet\"
}
" > ./tmp/w1/09-nppnet.conf

docker exec kind-worker cp /npp-temp/09-nppnet.conf /etc/cni/net.d
docker exec kind-worker cp /npp-temp/nppnet /opt/cni/bin
docker exec kind-worker chmod +x /opt/cni/bin/nppnet




# Create network on worker 2

docker exec kind-worker2 ip link add cni0 type bridge
docker exec kind-worker2 ip link set cni0 up
docker exec kind-worker2 ip addr add 10.244.$worker2_nodesubnet.1/24 dev cni0

# Create the conf file for worker 2
echo "
{
        \"cniVersion\": \"0.3.1\",
        \"name\": \"nppnet\",
        \"type\": \"nppnet\",
        \"subnet_network\": \"10.244\",
        \"subnet_node\": \"$worker2_nodesubnet\"
}
" > ./tmp/w2/09-nppnet.conf

docker exec kind-worker2 cp /npp-temp/09-nppnet.conf /etc/cni/net.d
docker exec kind-worker2 cp /npp-temp/nppnet /opt/cni/bin
docker exec kind-worker2 chmod +x /opt/cni/bin/nppnet


