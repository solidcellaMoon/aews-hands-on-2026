# 2주차 실습 내용

## 실습 코드 다운로드

실습 코드 repo를 받아 확인한다.
```bash
❯ git clone https://github.com/gasida/aews.git

❯ tree aews 
aews
├── 1w
│   ├── eks.tf
│   ├── var.tf
│   └── vpc.tf
└── eks-private
    ├── ec2.tf
    ├── main.tf
    ├── outputs.tf
    └── versions.tf

3 directories, 7 files

# 1주차 실습
❯ cd aews/1w
```

## VPC, EKS 배포 (12~15분 가량 소요)
```bash
# 변수 지정 -> tfvars 작성으로 대체함.
❯ vim terraform.tfvars

# 배포 : 12분 정도 소요
❯ terraform init
❯ terraform plan
❯ terraform apply


# 자격증명 설정
❯ aws eks update-kubeconfig --region ap-northeast-2 --name myeks
Added new context arn:aws:eks:ap-northeast-2:xxxxxxxxx:cluster/myeks to /Users/xxxx/.kube/config

# k8s config 확인 및 rename context
❯ cat ~/.kube/config | grep current-context | awk '{print $2}'
arn:aws:eks:ap-northeast-2:xxxxxxx:cluster/myeks

❯ k config rename-context $(cat ~/.kube/config | grep current-context | awk '{print $2}') myeks
Context "arn:aws:eks:ap-northeast-2:xxxxxxxx:cluster/myeks" renamed to "myeks".

❯ cat ~/.kube/config | grep current-context
current-context: myeks
```

## 노드에서 기본 네트워크 정보 확인
```bash
# EC2 ENI IP 확인
aws ec2 describe-instances --query "Reservations[*].Instances[*].{PublicIPAdd:PublicIpAddress,PrivateIPAdd:PrivateIpAddress,InstanceName:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters Name=instance-state-name,Values=running --output table

------------------------------------------------------------------------
|                           DescribeInstances                          |
+-----------------------+----------------+------------------+----------+
|     InstanceName      | PrivateIPAdd   |   PublicIPAdd    | Status   |
+-----------------------+----------------+------------------+----------+
|  myeks-1nd-node-group |  192.168.6.121 |  43.xxx.xxx.xxx  |  running |
|  myeks-1nd-node-group |  192.168.0.22  |  13.xxx.xxx.xxx  |  running |
|  myeks-1nd-node-group |  192.168.11.5  |  3.xx.xx.xx      |  running |
+-----------------------+----------------+------------------+----------+

# 아래 IP는 각자 실습 환경에 따라 사용
export N1=43.xxx.xxx.xxx
export N2=13.xxx.xxx.xxx
export N3=3.xx.xx.xx
```

### 네트워크 기본 정보 확인
```bash
# 파드 상세 정보 확인
❯ kubectl get daemonset aws-node --namespace kube-system -owide
NAME       DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE    CONTAINERS                   IMAGES                                                                                                                                                                                    SELECTOR
aws-node   3         3         3       3            3           <none>          150m   aws-node,aws-eks-nodeagent   602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon-k8s-cni:v1.21.1-eksbuild.5,602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-network-policy-agent:v1.3.1-eksbuild.1   k8s-app=aws-node

❯ kubectl describe daemonset aws-node --namespace kube-system
Name:           aws-node
Selector:       k8s-app=aws-node
Node-Selector:  <none>
Labels:         app.kubernetes.io/instance=aws-vpc-cni
                app.kubernetes.io/managed-by=Helm
                app.kubernetes.io/name=aws-node
                app.kubernetes.io/version=v1.21.1
                helm.sh/chart=aws-vpc-cni-1.21.1
                k8s-app=aws-node
Annotations:    deprecated.daemonset.template.generation: 1
Desired Number of Nodes Scheduled: 3
Current Number of Nodes Scheduled: 3
Number of Nodes Scheduled with Up-to-date Pods: 3
Number of Nodes Scheduled with Available Pods: 3
Number of Nodes Misscheduled: 0
Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:           app.kubernetes.io/instance=aws-vpc-cni
                    app.kubernetes.io/name=aws-node
                    k8s-app=aws-node
  Service Account:  aws-node
  Init Containers:
   aws-vpc-cni-init:
    Image:      602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon-k8s-cni-init:v1.21.1-eksbuild.5
    Port:       <none>
    Host Port:  <none>
    Requests:
      cpu:  25m
    Environment:
      DISABLE_TCP_EARLY_DEMUX:  false
      ENABLE_IPv6:              false
    Mounts:
      /host/opt/cni/bin from cni-bin-dir (rw)
  Containers:
   aws-node:
    Image:      602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon-k8s-cni:v1.21.1-eksbuild.5
    Port:       61678/TCP
    Host Port:  0/TCP
    Requests:
      cpu:      25m
    Liveness:   exec [/app/grpc-health-probe -addr=:50051 -connect-timeout=5s -rpc-timeout=5s] delay=60s timeout=10s period=10s #success=1 #failure=3
    Readiness:  exec [/app/grpc-health-probe -addr=:50051 -connect-timeout=5s -rpc-timeout=5s] delay=1s timeout=10s period=10s #success=1 #failure=3
    Environment:
      ADDITIONAL_ENI_TAGS:                    {}
      ANNOTATE_POD_IP:                        false
      AWS_VPC_CNI_NODE_PORT_SUPPORT:          true
      AWS_VPC_ENI_MTU:                        9001
      AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG:     false
      AWS_VPC_K8S_CNI_EXTERNALSNAT:           false
      AWS_VPC_K8S_CNI_LOGLEVEL:               DEBUG
      AWS_VPC_K8S_CNI_LOG_FILE:               /host/var/log/aws-routed-eni/ipamd.log
      AWS_VPC_K8S_CNI_RANDOMIZESNAT:          prng
      AWS_VPC_K8S_CNI_VETHPREFIX:             eni
      AWS_VPC_K8S_PLUGIN_LOG_FILE:            /var/log/aws-routed-eni/plugin.log
      AWS_VPC_K8S_PLUGIN_LOG_LEVEL:           DEBUG
      CLUSTER_ENDPOINT:                       https://CD8FBB5FC73D4F7C36EDD980E25FC54C.gr7.ap-northeast-2.eks.amazonaws.com
      CLUSTER_NAME:                           myeks
      DISABLE_INTROSPECTION:                  false
      DISABLE_METRICS:                        false
      DISABLE_NETWORK_RESOURCE_PROVISIONING:  false
      ENABLE_IMDS_ONLY_MODE:                  false
      ENABLE_IPv4:                            true
      ENABLE_IPv6:                            false
      ENABLE_MULTI_NIC:                       false
      ENABLE_POD_ENI:                         false
      ENABLE_PREFIX_DELEGATION:               false
      ENABLE_SUBNET_DISCOVERY:                true
      NETWORK_POLICY_ENFORCING_MODE:          standard
      VPC_CNI_VERSION:                        v1.21.1
      VPC_ID:                                 vpc-0c587c1dda2594bcd
      WARM_ENI_TARGET:                        1
      WARM_PREFIX_TARGET:                     1
      MY_NODE_NAME:                            (v1:spec.nodeName)
      MY_POD_NAME:                             (v1:metadata.name)
    Mounts:
      /host/etc/cni/net.d from cni-net-dir (rw)
      /host/opt/cni/bin from cni-bin-dir (rw)
      /host/var/log/aws-routed-eni from log-dir (rw)
      /run/xtables.lock from xtables-lock (rw)
      /var/run/aws-node from run-dir (rw)
   aws-eks-nodeagent:
    Image:      602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-network-policy-agent:v1.3.1-eksbuild.1
    Port:       8162/TCP
    Host Port:  0/TCP
    Args:
      --enable-ipv6=false
      --enable-network-policy=false
      --enable-cloudwatch-logs=false
      --enable-policy-event-logs=false
      --log-file=/var/log/aws-routed-eni/network-policy-agent.log
      --metrics-bind-addr=:8162
      --health-probe-bind-addr=:8163
      --conntrack-cache-cleanup-period=300
      --log-level=debug
    Requests:
      cpu:  25m
    Environment:
      MY_NODE_NAME:   (v1:spec.nodeName)
    Mounts:
      /host/opt/cni/bin from cni-bin-dir (rw)
      /sys/fs/bpf from bpf-pin-path (rw)
      /var/log/aws-routed-eni from log-dir (rw)
      /var/run/aws-node from run-dir (rw)
  Volumes:
   bpf-pin-path:
    Type:          HostPath (bare host directory volume)
    Path:          /sys/fs/bpf
    HostPathType:  
   cni-bin-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /opt/cni/bin
    HostPathType:  
   cni-net-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /etc/cni/net.d
    HostPathType:  
   log-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /var/log/aws-routed-eni
    HostPathType:  DirectoryOrCreate
   run-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /var/run/aws-node
    HostPathType:  DirectoryOrCreate
   xtables-lock:
    Type:               HostPath (bare host directory volume)
    Path:               /run/xtables.lock
    HostPathType:       FileOrCreate
  Priority Class Name:  system-node-critical
Events:                 <none>

# kube-proxy config 확인 : 모드 iptables 사용
❯ kubectl describe cm -n kube-system kube-proxy-config | grep iptables
iptables:
mode: "iptables"

❯ kubectl describe cm -n kube-system kube-proxy-config | grep iptables: -A5
iptables:
  masqueradeAll: false
  masqueradeBit: 14
  minSyncPeriod: 0s
  syncPeriod: 30s
ipvs:

# aws-node 데몬셋 env 확인
❯ kubectl get ds aws-node -n kube-system -o json | jq '.spec.template.spec.containers[0].env'
[
  {
    "name": "ADDITIONAL_ENI_TAGS",
    "value": "{}"
  },
  {
    "name": "ANNOTATE_POD_IP",
    "value": "false"
  },
  {
    "name": "AWS_VPC_CNI_NODE_PORT_SUPPORT",
    "value": "true"
  },
  {
    "name": "AWS_VPC_ENI_MTU",
    "value": "9001"
  },
  {
    "name": "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG",
    "value": "false"
  },
  {
    "name": "AWS_VPC_K8S_CNI_EXTERNALSNAT",
    "value": "false"
  },
  {
    "name": "AWS_VPC_K8S_CNI_LOGLEVEL",
    "value": "DEBUG"
  },
  {
    "name": "AWS_VPC_K8S_CNI_LOG_FILE",
    "value": "/host/var/log/aws-routed-eni/ipamd.log"
  },
  {
    "name": "AWS_VPC_K8S_CNI_RANDOMIZESNAT",
    "value": "prng"
  },
  {
    "name": "AWS_VPC_K8S_CNI_VETHPREFIX",
    "value": "eni"
  },
  {
    "name": "AWS_VPC_K8S_PLUGIN_LOG_FILE",
    "value": "/var/log/aws-routed-eni/plugin.log"
  },
  {
    "name": "AWS_VPC_K8S_PLUGIN_LOG_LEVEL",
    "value": "DEBUG"
  },
  {
    "name": "CLUSTER_ENDPOINT",
    "value": "https://CD8FBB5FC73D4F7C36EDD980E25FC54C.gr7.ap-northeast-2.eks.amazonaws.com"
  },
  {
    "name": "CLUSTER_NAME",
    "value": "myeks"
  },
  {
    "name": "DISABLE_INTROSPECTION",
    "value": "false"
  },
  {
    "name": "DISABLE_METRICS",
    "value": "false"
  },
  {
    "name": "DISABLE_NETWORK_RESOURCE_PROVISIONING",
    "value": "false"
  },
  {
    "name": "ENABLE_IMDS_ONLY_MODE",
    "value": "false"
  },
  {
    "name": "ENABLE_IPv4",
    "value": "true"
  },
  {
    "name": "ENABLE_IPv6",
    "value": "false"
  },
  {
    "name": "ENABLE_MULTI_NIC",
    "value": "false"
  },
  {
    "name": "ENABLE_POD_ENI",
    "value": "false"
  },
  {
    "name": "ENABLE_PREFIX_DELEGATION",
    "value": "false"
  },
  {
    "name": "ENABLE_SUBNET_DISCOVERY",
    "value": "true"
  },
  {
    "name": "NETWORK_POLICY_ENFORCING_MODE",
    "value": "standard"
  },
  {
    "name": "VPC_CNI_VERSION",
    "value": "v1.21.1"
  },
  {
    "name": "VPC_ID",
    "value": "vpc-0c587c1dda2594bcd"
  },
  {
    "name": "WARM_ENI_TARGET",
    "value": "1"
  },
  {
    "name": "WARM_PREFIX_TARGET",
    "value": "1"
  },
  {
    "name": "MY_NODE_NAME",
    "valueFrom": {
      "fieldRef": {
        "apiVersion": "v1",
        "fieldPath": "spec.nodeName"
      }
    }
  },
  {
    "name": "MY_POD_NAME",
    "valueFrom": {
      "fieldRef": {
        "apiVersion": "v1",
        "fieldPath": "metadata.name"
      }
    }
  }
]

# 노드 IP 확인
aws ec2 describe-instances --query "Reservations[*].Instances[*].{PublicIPAdd:PublicIpAddress,PrivateIPAdd:PrivateIpAddress,InstanceName:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters Name=instance-state-name,Values=running --output table
(생략)

# 파드 IP 확인
❯ kubectl get pod -n kube-system -o=custom-columns=NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase
NAME                      IP              STATUS
aws-node-2z6z6            192.168.11.5    Running
aws-node-kznsq            192.168.0.22    Running
aws-node-nbx4v            192.168.6.121   Running
coredns-d487b6fcb-8d8v9   192.168.4.8     Running
coredns-d487b6fcb-lz8w6   192.168.3.202   Running
kube-proxy-czplf          192.168.0.22    Running
kube-proxy-dmhf4          192.168.6.121   Running
kube-proxy-vr4nm          192.168.11.5    Running

# 파드 이름 확인
❯ kubectl get pod -A -o name
pod/aws-node-2z6z6
pod/aws-node-kznsq
pod/aws-node-nbx4v
pod/coredns-d487b6fcb-8d8v9
pod/coredns-d487b6fcb-lz8w6
pod/kube-proxy-czplf
pod/kube-proxy-dmhf4
pod/kube-proxy-vr4nm
```

### 노드에 네트워크 정보 확인
```bash
# cni log 확인
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i tree /var/log/aws-routed-eni ; echo; done
>> node 43.xxx.xxx.xxx <<
/var/log/aws-routed-eni
├── ebpf-sdk.log
├── egress-v6-plugin.log
├── ipamd.log
├── network-policy-agent.log
└── plugin.log

0 directories, 5 files

>> node 13.xxx.xxx.xxx <<
/var/log/aws-routed-eni
├── ebpf-sdk.log
├── egress-v6-plugin.log
├── ipamd.log
├── network-policy-agent.log
└── plugin.log

0 directories, 5 files

>> node 3.xx.xx.xx <<
/var/log/aws-routed-eni
├── ebpf-sdk.log
├── egress-v6-plugin.log
├── ipamd.log
├── network-policy-agent.log
└── plugin.log

0 directories, 5 files

for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo cat /var/log/aws-routed-eni/plugin.log | jq ; echo; done
(많아서 생략)

for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo cat /var/log/aws-routed-eni/ipamd.log | jq ; echo; done
(많아서 생략)

# 네트워크 정보 확인 : eniY는 pod network 네임스페이스와 veth pair
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -br -c addr; echo; done
>> node 43.xxx.xxx.xxx <<
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens5             UP             192.168.6.121/22 metric 512 fe80::444:8fff:fef8:bda7/64 
eni14227b50c6b@if3 UP             fe80::d8e2:7cff:fe4a:ae5/64 
ens6             UP             192.168.4.57/22 fe80::4b4:ddff:fea8:aa5f/64 

>> node 13.xxx.xxx.xxx <<
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens5             UP             192.168.0.22/22 metric 512 fe80::a6:a1ff:fec7:cc11/64 
eni92fed275402@if3 UP             fe80::fcf5:4bff:fef6:d0c1/64 
ens7             UP             192.168.3.59/22 fe80::5d:b4ff:fe96:6131/64 

>> node 3.xx.xx.xx <<
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens5             UP             192.168.11.5/22 metric 512 fe80::872:3dff:fe85:fc37/64 

❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c addr; echo; done
>> node 43.xxx.xxx.xxx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 06:44:8f:f8:bd:a7 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.6.121/22 metric 512 brd 192.168.7.255 scope global dynamic ens5
       valid_lft 2730sec preferred_lft 2730sec
    inet6 fe80::444:8fff:fef8:bda7/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eni14227b50c6b@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc noqueue state UP group default 
    link/ether da:e2:7c:4a:0a:e5 brd ff:ff:ff:ff:ff:ff link-netns cni-151d5dc3-d27e-45d4-bb78-9d00a908a114
    inet6 fe80::d8e2:7cff:fe4a:ae5/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
4: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 06:b4:dd:a8:aa:5f brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    inet 192.168.4.57/22 brd 192.168.7.255 scope global ens6
       valid_lft forever preferred_lft forever
    inet6 fe80::4b4:ddff:fea8:aa5f/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

>> node 13.xxx.xxx.xxx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:a6:a1:c7:cc:11 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.0.22/22 metric 512 brd 192.168.3.255 scope global dynamic ens5
       valid_lft 2729sec preferred_lft 2729sec
    inet6 fe80::a6:a1ff:fec7:cc11/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eni92fed275402@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc noqueue state UP group default 
    link/ether fe:f5:4b:f6:d0:c1 brd ff:ff:ff:ff:ff:ff link-netns cni-ec9d1341-0bfb-99da-a940-004620367286
    inet6 fe80::fcf5:4bff:fef6:d0c1/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
14: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:5d:b4:96:61:31 brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    inet 192.168.3.59/22 brd 192.168.3.255 scope global ens7
       valid_lft forever preferred_lft forever
    inet6 fe80::5d:b4ff:fe96:6131/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

>> node 3.xx.xx.xx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 0a:72:3d:85:fc:37 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.11.5/22 metric 512 brd 192.168.11.255 scope global dynamic ens5
       valid_lft 2728sec preferred_lft 2728sec
    inet6 fe80::872:3dff:fe85:fc37/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c route; echo; done
>> node 43.xxx.xxx.xxx <<
default via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.0.2 via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.4.0/22 dev ens5 proto kernel scope link src 192.168.6.121 metric 512 
192.168.4.1 dev ens5 proto dhcp scope link src 192.168.6.121 metric 512 
192.168.4.8 dev eni14227b50c6b scope link 

>> node 13.xxx.xxx.xxx <<
default via 192.168.0.1 dev ens5 proto dhcp src 192.168.0.22 metric 512 
192.168.0.0/22 dev ens5 proto kernel scope link src 192.168.0.22 metric 512 
192.168.0.1 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.0.2 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.3.202 dev eni92fed275402 scope link 

>> node 3.xx.xx.xx <<
default via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.0.2 via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.8.0/22 dev ens5 proto kernel scope link src 192.168.11.5 metric 512 
192.168.8.1 dev ens5 proto dhcp scope link src 192.168.11.5 metric 512 

❯ ssh ec2-user@$N1 sudo iptables -t nat -S
-P PREROUTING ACCEPT
-P INPUT ACCEPT
-P OUTPUT ACCEPT
-P POSTROUTING ACCEPT
-N AWS-CONNMARK-CHAIN-0
-N AWS-SNAT-CHAIN-0
-N KUBE-KUBELET-CANARY
-N KUBE-MARK-MASQ
-N KUBE-NODEPORTS
-N KUBE-POSTROUTING
-N KUBE-PROXY-CANARY
-N KUBE-SEP-2U7OSQXJZOB7WZ3Q
-N KUBE-SEP-5F3K6STVZ2RIMBVD
-N KUBE-SEP-7HMGISIDEKXTX3RL
-N KUBE-SEP-LKMWUDPNNHYGGRZY
-N KUBE-SEP-M2QJFXJS57EX5J5P
-N KUBE-SEP-P2RFBZXL77JSMBKZ
-N KUBE-SEP-V6N5HQQSW43PC5DW
-N KUBE-SEP-XYDDOFWXZXQGZRSQ
-N KUBE-SEP-YIAJBU22ST67ZZPR
-N KUBE-SERVICES
-N KUBE-SVC-ERIFXISQEP7F7OF4
-N KUBE-SVC-I7SKRZYQ7PWYV5X7
-N KUBE-SVC-JD5MR3NA4I4DYORP
-N KUBE-SVC-NPX46M4PTMTKRN6Y
-N KUBE-SVC-TCOU7JCQXEZGVUNU
-A PREROUTING -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A PREROUTING -i eni+ -m comment --comment "AWS, outbound connections" -j AWS-CONNMARK-CHAIN-0
-A PREROUTING -m comment --comment "AWS, CONNMARK" -j CONNMARK --restore-mark --nfmask 0x80 --ctmask 0x80
-A OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A POSTROUTING -m comment --comment "kubernetes postrouting rules" -j KUBE-POSTROUTING
-A POSTROUTING -m comment --comment "AWS SNAT CHAIN" -j AWS-SNAT-CHAIN-0
-A AWS-CONNMARK-CHAIN-0 -d 192.168.0.0/16 -m comment --comment "AWS CONNMARK CHAIN, VPC CIDR" -j RETURN
-A AWS-CONNMARK-CHAIN-0 -m comment --comment "AWS, CONNMARK" -j CONNMARK --set-xmark 0x80/0x80
-A AWS-SNAT-CHAIN-0 -d 192.168.0.0/16 -m comment --comment "AWS SNAT CHAIN" -j RETURN
-A AWS-SNAT-CHAIN-0 ! -o vlan+ -m comment --comment "AWS, SNAT" -m addrtype ! --dst-type LOCAL -j SNAT --to-source 192.168.6.121 --random-fully
-A KUBE-MARK-MASQ -j MARK --set-xmark 0x4000/0x4000
-A KUBE-POSTROUTING -m mark ! --mark 0x4000/0x4000 -j RETURN
-A KUBE-POSTROUTING -j MARK --set-xmark 0x4000/0x0
-A KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -j MASQUERADE --random-fully
-A KUBE-SEP-2U7OSQXJZOB7WZ3Q -s 192.168.3.202/32 -m comment --comment "kube-system/kube-dns:dns-tcp" -j KUBE-MARK-MASQ
-A KUBE-SEP-2U7OSQXJZOB7WZ3Q -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp" -m tcp -j DNAT --to-destination 192.168.3.202:53
-A KUBE-SEP-5F3K6STVZ2RIMBVD -s 192.168.4.8/32 -m comment --comment "kube-system/kube-dns:metrics" -j KUBE-MARK-MASQ
-A KUBE-SEP-5F3K6STVZ2RIMBVD -p tcp -m comment --comment "kube-system/kube-dns:metrics" -m tcp -j DNAT --to-destination 192.168.4.8:9153
-A KUBE-SEP-7HMGISIDEKXTX3RL -s 192.168.7.65/32 -m comment --comment "default/kubernetes:https" -j KUBE-MARK-MASQ
-A KUBE-SEP-7HMGISIDEKXTX3RL -p tcp -m comment --comment "default/kubernetes:https" -m tcp -j DNAT --to-destination 192.168.7.65:443
-A KUBE-SEP-LKMWUDPNNHYGGRZY -s 192.168.4.8/32 -m comment --comment "kube-system/kube-dns:dns" -j KUBE-MARK-MASQ
-A KUBE-SEP-LKMWUDPNNHYGGRZY -p udp -m comment --comment "kube-system/kube-dns:dns" -m udp -j DNAT --to-destination 192.168.4.8:53
-A KUBE-SEP-M2QJFXJS57EX5J5P -s 192.168.11.108/32 -m comment --comment "default/kubernetes:https" -j KUBE-MARK-MASQ
-A KUBE-SEP-M2QJFXJS57EX5J5P -p tcp -m comment --comment "default/kubernetes:https" -m tcp -j DNAT --to-destination 192.168.11.108:443
-A KUBE-SEP-P2RFBZXL77JSMBKZ -s 192.168.3.202/32 -m comment --comment "kube-system/kube-dns:metrics" -j KUBE-MARK-MASQ
-A KUBE-SEP-P2RFBZXL77JSMBKZ -p tcp -m comment --comment "kube-system/kube-dns:metrics" -m tcp -j DNAT --to-destination 192.168.3.202:9153
-A KUBE-SEP-V6N5HQQSW43PC5DW -s 192.168.3.202/32 -m comment --comment "kube-system/kube-dns:dns" -j KUBE-MARK-MASQ
-A KUBE-SEP-V6N5HQQSW43PC5DW -p udp -m comment --comment "kube-system/kube-dns:dns" -m udp -j DNAT --to-destination 192.168.3.202:53
-A KUBE-SEP-XYDDOFWXZXQGZRSQ -s 172.0.32.0/32 -m comment --comment "kube-system/eks-extension-metrics-api:metrics-api" -j KUBE-MARK-MASQ
-A KUBE-SEP-XYDDOFWXZXQGZRSQ -p tcp -m comment --comment "kube-system/eks-extension-metrics-api:metrics-api" -m tcp -j DNAT --to-destination 172.0.32.0:10443
-A KUBE-SEP-YIAJBU22ST67ZZPR -s 192.168.4.8/32 -m comment --comment "kube-system/kube-dns:dns-tcp" -j KUBE-MARK-MASQ
-A KUBE-SEP-YIAJBU22ST67ZZPR -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp" -m tcp -j DNAT --to-destination 192.168.4.8:53
-A KUBE-SERVICES -d 10.100.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -m tcp --dport 443 -j KUBE-SVC-NPX46M4PTMTKRN6Y
-A KUBE-SERVICES -d 10.100.135.59/32 -p tcp -m comment --comment "kube-system/eks-extension-metrics-api:metrics-api cluster IP" -m tcp --dport 443 -j KUBE-SVC-I7SKRZYQ7PWYV5X7
-A KUBE-SERVICES -d 10.100.0.10/32 -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp cluster IP" -m tcp --dport 53 -j KUBE-SVC-ERIFXISQEP7F7OF4
-A KUBE-SERVICES -d 10.100.0.10/32 -p tcp -m comment --comment "kube-system/kube-dns:metrics cluster IP" -m tcp --dport 9153 -j KUBE-SVC-JD5MR3NA4I4DYORP
-A KUBE-SERVICES -d 10.100.0.10/32 -p udp -m comment --comment "kube-system/kube-dns:dns cluster IP" -m udp --dport 53 -j KUBE-SVC-TCOU7JCQXEZGVUNU
-A KUBE-SERVICES -m comment --comment "kubernetes service nodeports; NOTE: this must be the last rule in this chain" -m addrtype --dst-type LOCAL -j KUBE-NODEPORTS
-A KUBE-SVC-ERIFXISQEP7F7OF4 -m comment --comment "kube-system/kube-dns:dns-tcp -> 192.168.3.202:53" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-2U7OSQXJZOB7WZ3Q
-A KUBE-SVC-ERIFXISQEP7F7OF4 -m comment --comment "kube-system/kube-dns:dns-tcp -> 192.168.4.8:53" -j KUBE-SEP-YIAJBU22ST67ZZPR
-A KUBE-SVC-I7SKRZYQ7PWYV5X7 -m comment --comment "kube-system/eks-extension-metrics-api:metrics-api -> 172.0.32.0:10443" -j KUBE-SEP-XYDDOFWXZXQGZRSQ
-A KUBE-SVC-JD5MR3NA4I4DYORP -m comment --comment "kube-system/kube-dns:metrics -> 192.168.3.202:9153" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-P2RFBZXL77JSMBKZ
-A KUBE-SVC-JD5MR3NA4I4DYORP -m comment --comment "kube-system/kube-dns:metrics -> 192.168.4.8:9153" -j KUBE-SEP-5F3K6STVZ2RIMBVD
-A KUBE-SVC-NPX46M4PTMTKRN6Y -m comment --comment "default/kubernetes:https -> 192.168.11.108:443" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-M2QJFXJS57EX5J5P
-A KUBE-SVC-NPX46M4PTMTKRN6Y -m comment --comment "default/kubernetes:https -> 192.168.7.65:443" -j KUBE-SEP-7HMGISIDEKXTX3RL
-A KUBE-SVC-TCOU7JCQXEZGVUNU -m comment --comment "kube-system/kube-dns:dns -> 192.168.3.202:53" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-V6N5HQQSW43PC5DW
-A KUBE-SVC-TCOU7JCQXEZGVUNU -m comment --comment "kube-system/kube-dns:dns -> 192.168.4.8:53" -j KUBE-SEP-LKMWUDPNNHYGGRZY

❯ ssh ec2-user@$N1 sudo iptables -t nat -L -n -v
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
   15   969 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
    1    85 AWS-CONNMARK-CHAIN-0  all  --  eni+   *       0.0.0.0/0            0.0.0.0/0            /* AWS, outbound connections */
   12   789 CONNMARK   all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* AWS, CONNMARK */ CONNMARK restore mask 0x80

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
15167  926K KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
15171  926K KUBE-POSTROUTING  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes postrouting rules */
15258  933K AWS-SNAT-CHAIN-0  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* AWS SNAT CHAIN */

Chain AWS-CONNMARK-CHAIN-0 (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    1    85 RETURN     all  --  *      *       0.0.0.0/0            192.168.0.0/16       /* AWS CONNMARK CHAIN, VPC CIDR */
    0     0 CONNMARK   all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* AWS, CONNMARK */ CONNMARK or 0x80

Chain AWS-SNAT-CHAIN-0 (1 references)
 pkts bytes target     prot opt in     out     source               destination         
 8524  517K RETURN     all  --  *      *       0.0.0.0/0            192.168.0.0/16       /* AWS SNAT CHAIN */
 4627  290K SNAT       all  --  *      !vlan+  0.0.0.0/0            0.0.0.0/0            /* AWS, SNAT */ ADDRTYPE match dst-type !LOCAL to:192.168.6.121 random-fully

Chain KUBE-KUBELET-CANARY (0 references)
 pkts bytes target     prot opt in     out     source               destination         

Chain KUBE-MARK-MASQ (9 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK or 0x4000

Chain KUBE-NODEPORTS (1 references)
 pkts bytes target     prot opt in     out     source               destination         

Chain KUBE-POSTROUTING (1 references)
 pkts bytes target     prot opt in     out     source               destination         
 1526 93861 RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0            mark match ! 0x4000/0x4000
    0     0 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK xor 0x4000
    0     0 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service traffic requiring SNAT */ random-fully

Chain KUBE-PROXY-CANARY (0 references)
 pkts bytes target     prot opt in     out     source               destination         

Chain KUBE-SEP-2U7OSQXJZOB7WZ3Q (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.3.202        0.0.0.0/0            /* kube-system/kube-dns:dns-tcp */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns-tcp */ tcp to:192.168.3.202:53

Chain KUBE-SEP-5F3K6STVZ2RIMBVD (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.4.8          0.0.0.0/0            /* kube-system/kube-dns:metrics */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:metrics */ tcp to:192.168.4.8:9153

Chain KUBE-SEP-7HMGISIDEKXTX3RL (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.7.65         0.0.0.0/0            /* default/kubernetes:https */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:https */ tcp to:192.168.7.65:443

Chain KUBE-SEP-LKMWUDPNNHYGGRZY (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.4.8          0.0.0.0/0            /* kube-system/kube-dns:dns */
    0     0 DNAT       udp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns */ udp to:192.168.4.8:53

Chain KUBE-SEP-M2QJFXJS57EX5J5P (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.11.108       0.0.0.0/0            /* default/kubernetes:https */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:https */ tcp to:192.168.11.108:443

Chain KUBE-SEP-P2RFBZXL77JSMBKZ (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.3.202        0.0.0.0/0            /* kube-system/kube-dns:metrics */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:metrics */ tcp to:192.168.3.202:9153

Chain KUBE-SEP-V6N5HQQSW43PC5DW (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.3.202        0.0.0.0/0            /* kube-system/kube-dns:dns */
    0     0 DNAT       udp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns */ udp to:192.168.3.202:53

Chain KUBE-SEP-XYDDOFWXZXQGZRSQ (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       172.0.32.0           0.0.0.0/0            /* kube-system/eks-extension-metrics-api:metrics-api */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/eks-extension-metrics-api:metrics-api */ tcp to:172.0.32.0:10443

Chain KUBE-SEP-YIAJBU22ST67ZZPR (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-MARK-MASQ  all  --  *      *       192.168.4.8          0.0.0.0/0            /* kube-system/kube-dns:dns-tcp */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns-tcp */ tcp to:192.168.4.8:53

Chain KUBE-SERVICES (2 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-SVC-NPX46M4PTMTKRN6Y  tcp  --  *      *       0.0.0.0/0            10.100.0.1           /* default/kubernetes:https cluster IP */ tcp dpt:443
    0     0 KUBE-SVC-I7SKRZYQ7PWYV5X7  tcp  --  *      *       0.0.0.0/0            10.100.135.59        /* kube-system/eks-extension-metrics-api:metrics-api cluster IP */ tcp dpt:443
    0     0 KUBE-SVC-ERIFXISQEP7F7OF4  tcp  --  *      *       0.0.0.0/0            10.100.0.10          /* kube-system/kube-dns:dns-tcp cluster IP */ tcp dpt:53
    0     0 KUBE-SVC-JD5MR3NA4I4DYORP  tcp  --  *      *       0.0.0.0/0            10.100.0.10          /* kube-system/kube-dns:metrics cluster IP */ tcp dpt:9153
    0     0 KUBE-SVC-TCOU7JCQXEZGVUNU  udp  --  *      *       0.0.0.0/0            10.100.0.10          /* kube-system/kube-dns:dns cluster IP */ udp dpt:53
  379 22784 KUBE-NODEPORTS  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service nodeports; NOTE: this must be the last rule in this chain */ ADDRTYPE match dst-type LOCAL

Chain KUBE-SVC-ERIFXISQEP7F7OF4 (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-SEP-2U7OSQXJZOB7WZ3Q  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns-tcp -> 192.168.3.202:53 */ statistic mode random probability 0.50000000000
    0     0 KUBE-SEP-YIAJBU22ST67ZZPR  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns-tcp -> 192.168.4.8:53 */

Chain KUBE-SVC-I7SKRZYQ7PWYV5X7 (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-SEP-XYDDOFWXZXQGZRSQ  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/eks-extension-metrics-api:metrics-api -> 172.0.32.0:10443 */

Chain KUBE-SVC-JD5MR3NA4I4DYORP (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-SEP-P2RFBZXL77JSMBKZ  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:metrics -> 192.168.3.202:9153 */ statistic mode random probability 0.50000000000
    0     0 KUBE-SEP-5F3K6STVZ2RIMBVD  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:metrics -> 192.168.4.8:9153 */

Chain KUBE-SVC-NPX46M4PTMTKRN6Y (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-SEP-M2QJFXJS57EX5J5P  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:https -> 192.168.11.108:443 */ statistic mode random probability 0.50000000000
    0     0 KUBE-SEP-7HMGISIDEKXTX3RL  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:https -> 192.168.7.65:443 */

Chain KUBE-SVC-TCOU7JCQXEZGVUNU (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 KUBE-SEP-V6N5HQQSW43PC5DW  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns -> 192.168.3.202:53 */ statistic mode random probability 0.50000000000
    0     0 KUBE-SEP-LKMWUDPNNHYGGRZY  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kube-system/kube-dns:dns -> 192.168.4.8:53 */
```
### 보조 IPv4 주소를 coredns 파드가 사용하는지 확인
```bash
# coredns 파드 IP 정보 확인
❯ kubectl get pod -n kube-system -l k8s-app=kube-dns -owide
NAME                      READY   STATUS    RESTARTS   AGE    IP              NODE                                               NOMINATED NODE   READINESS GATES
coredns-d487b6fcb-8d8v9   1/1     Running   0          165m   192.168.4.8     ip-192-168-6-121.ap-northeast-2.compute.internal   <none>           <none>
coredns-d487b6fcb-lz8w6   1/1     Running   0          165m   192.168.3.202   ip-192-168-0-22.ap-northeast-2.compute.internal    <none>           <none>

# 노드의 라우팅 정보 확인 >> EC2 네트워크 정보의 '보조 프라이빗 IPv4 주소'와 비교하기.
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c route; echo; done
>> node 43.xxx.xxx.xxx <<
default via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.0.2 via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.4.0/22 dev ens5 proto kernel scope link src 192.168.6.121 metric 512 
192.168.4.1 dev ens5 proto dhcp scope link src 192.168.6.121 metric 512 
192.168.4.8 dev eni14227b50c6b scope link 

>> node 13.xxx.xxx.xxx <<
default via 192.168.0.1 dev ens5 proto dhcp src 192.168.0.22 metric 512 
192.168.0.0/22 dev ens5 proto kernel scope link src 192.168.0.22 metric 512 
192.168.0.1 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.0.2 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.3.202 dev eni92fed275402 scope link 

>> node 3.xx.xx.xx <<
default via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.0.2 via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.8.0/22 dev ens5 proto kernel scope link src 192.168.11.5 metric 512 
192.168.8.1 dev ens5 proto dhcp scope link src 192.168.11.5 metric 512 

# IpamD debugging commands
# https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/troubleshooting.md
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i curl -s http://localhost:61679/v1/enis | jq; echo; done
>> node 43.xxx.xxx.xxx <<
{
  "0": {
    "TotalIPs": 10,
    "AssignedIPs": 1,
    "ENIs": {
      "eni-05084d1f2e789e47c": {
        "ID": "eni-05084d1f2e789e47c",
        "IsPrimary": true,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 0,
        "AvailableIPv4Cidrs": {
          "192.168.4.138/32": {
            "Cidr": {
              "IP": "192.168.4.138",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.4.138": {
                "Address": "192.168.4.138",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:42:29.892593033Z",
                "UnassignedTime": "2026-03-24T13:58:24.056812242Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.4.8/32": {
            "Cidr": {
              "IP": "192.168.4.8",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.4.8": {
                "Address": "192.168.4.8",
                "IPAMKey": {
                  "networkName": "aws-cni",
                  "containerID": "6400f25e7fd8133daef1f8e49b240dc4e0683013578bbdcde98e5d252c999c40",
                  "ifName": "eth0"
                },
                "IPAMMetadata": {
                  "k8sPodNamespace": "kube-system",
                  "k8sPodName": "coredns-d487b6fcb-8d8v9",
                  "interfacesCount": 1
                },
                "AssignedTime": "2026-03-24T12:56:48.117942313Z",
                "UnassignedTime": "0001-01-01T00:00:00Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.5.217/32": {
            "Cidr": {
              "IP": "192.168.5.217",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.217": {
                "Address": "192.168.5.217",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.067912612Z",
                "UnassignedTime": "2026-03-24T13:58:24.158186441Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.5.7/32": {
            "Cidr": {
              "IP": "192.168.5.7",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.7": {
                "Address": "192.168.5.7",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:47.968715799Z",
                "UnassignedTime": "2026-03-24T13:58:24.168168516Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.7.162/32": {
            "Cidr": {
              "IP": "192.168.7.162",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.7.162": {
                "Address": "192.168.7.162",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:42:35.893652918Z",
                "UnassignedTime": "2026-03-24T13:59:09.783784292Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 254
      },
      "eni-0ea9144f1eb771424": {
        "ID": "eni-0ea9144f1eb771424",
        "IsPrimary": false,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 1,
        "AvailableIPv4Cidrs": {
          "192.168.5.146/32": {
            "Cidr": {
              "IP": "192.168.5.146",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.146": {
                "Address": "192.168.5.146",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.424190322Z",
                "UnassignedTime": "2026-03-24T13:58:24.117642322Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.5.252/32": {
            "Cidr": {
              "IP": "192.168.5.252",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.252": {
                "Address": "192.168.5.252",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.158358297Z",
                "UnassignedTime": "2026-03-24T13:58:24.028539116Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.6.159/32": {
            "Cidr": {
              "IP": "192.168.6.159",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.6.159": {
                "Address": "192.168.6.159",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.269912639Z",
                "UnassignedTime": "2026-03-24T13:58:24.077109524Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.6.177/32": {
            "Cidr": {
              "IP": "192.168.6.177",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.6.177": {
                "Address": "192.168.6.177",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.313117509Z",
                "UnassignedTime": "2026-03-24T13:58:24.031161028Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.6.217/32": {
            "Cidr": {
              "IP": "192.168.6.217",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.6.217": {
                "Address": "192.168.6.217",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:40:41.911354946Z",
                "UnassignedTime": "2026-03-24T13:41:55.212919674Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 2
      }
    }
  }
}

>> node 13.xxx.xxx.xxx <<
{
  "0": {
    "TotalIPs": 10,
    "AssignedIPs": 1,
    "ENIs": {
      "eni-00c5445c5f1db45d4": {
        "ID": "eni-00c5445c5f1db45d4",
        "IsPrimary": true,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 0,
        "AvailableIPv4Cidrs": {
          "192.168.1.196/32": {
            "Cidr": {
              "IP": "192.168.1.196",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.196": {
                "Address": "192.168.1.196",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.077689585Z",
                "UnassignedTime": "2026-03-24T13:58:24.162466308Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.1.244/32": {
            "Cidr": {
              "IP": "192.168.1.244",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.244": {
                "Address": "192.168.1.244",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.182309449Z",
                "UnassignedTime": "2026-03-24T13:58:24.342194023Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.2.113/32": {
            "Cidr": {
              "IP": "192.168.2.113",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.2.113": {
                "Address": "192.168.2.113",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:42:34.887080551Z",
                "UnassignedTime": "2026-03-24T13:58:24.311196683Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.3.202/32": {
            "Cidr": {
              "IP": "192.168.3.202",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.3.202": {
                "Address": "192.168.3.202",
                "IPAMKey": {
                  "networkName": "aws-cni",
                  "containerID": "3bf0f4ea1779e94291b4fcbb48caca790e1d17ced78c12ec9773023bc443dd92",
                  "ifName": "eth0"
                },
                "IPAMMetadata": {
                  "k8sPodNamespace": "kube-system",
                  "k8sPodName": "coredns-d487b6fcb-lz8w6",
                  "interfacesCount": 1
                },
                "AssignedTime": "2026-03-24T12:56:48.068477383Z",
                "UnassignedTime": "0001-01-01T00:00:00Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.3.93/32": {
            "Cidr": {
              "IP": "192.168.3.93",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.3.93": {
                "Address": "192.168.3.93",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:47.887109429Z",
                "UnassignedTime": "2026-03-24T13:58:24.276159793Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 254
      },
      "eni-0eefccb53ab57354e": {
        "ID": "eni-0eefccb53ab57354e",
        "IsPrimary": false,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 2,
        "AvailableIPv4Cidrs": {
          "192.168.1.117/32": {
            "Cidr": {
              "IP": "192.168.1.117",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.117": {
                "Address": "192.168.1.117",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:42:36.887418807Z",
                "UnassignedTime": "2026-03-24T13:58:24.373474658Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.1.225/32": {
            "Cidr": {
              "IP": "192.168.1.225",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.225": {
                "Address": "192.168.1.225",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:54.106507083Z",
                "UnassignedTime": "2026-03-24T13:41:53.906414848Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.2.227/32": {
            "Cidr": {
              "IP": "192.168.2.227",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.2.227": {
                "Address": "192.168.2.227",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:53.900753611Z",
                "UnassignedTime": "2026-03-24T13:41:56.197890165Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.2.62/32": {
            "Cidr": {
              "IP": "192.168.2.62",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.2.62": {
                "Address": "192.168.2.62",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:53.422363656Z",
                "UnassignedTime": "2026-03-24T13:41:57.807384537Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.3.131/32": {
            "Cidr": {
              "IP": "192.168.3.131",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.3.131": {
                "Address": "192.168.3.131",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:53.806283092Z",
                "UnassignedTime": "2026-03-24T13:42:35.9851485Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 3
      }
    }
  }
}

>> node 3.xx.xx.xx <<
{
  "0": {
    "TotalIPs": 5,
    "AssignedIPs": 0,
    "ENIs": {
      "eni-0aa20caba88eee9bd": {
        "ID": "eni-0aa20caba88eee9bd",
        "IsPrimary": true,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 0,
        "AvailableIPv4Cidrs": {
          "192.168.11.208/32": {
            "Cidr": {
              "IP": "192.168.11.208",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.11.208": {
                "Address": "192.168.11.208",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:06:00.202476854Z",
                "UnassignedTime": "2026-03-24T15:07:49.339988055Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.11.63/32": {
            "Cidr": {
              "IP": "192.168.11.63",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.11.63": {
                "Address": "192.168.11.63",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:07:42.599808332Z",
                "UnassignedTime": "2026-03-24T15:10:45.251269857Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.9.217/32": {
            "Cidr": {
              "IP": "192.168.9.217",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.9.217": {
                "Address": "192.168.9.217",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:07:42.462719034Z",
                "UnassignedTime": "2026-03-24T15:10:45.16345917Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.9.237/32": {
            "Cidr": {
              "IP": "192.168.9.237",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.9.237": {
                "Address": "192.168.9.237",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:05:59.980496898Z",
                "UnassignedTime": "2026-03-24T15:07:45.425374626Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.9.75/32": {
            "Cidr": {
              "IP": "192.168.9.75",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.9.75": {
                "Address": "192.168.9.75",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:07:42.658784056Z",
                "UnassignedTime": "2026-03-24T15:10:44.947047027Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 254
      }
    }
  }
}

```

### Network-Multitool Deployment 배포

```bash
# Network-Multitool 디플로이먼트 생성
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: netshoot-pod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: netshoot-pod
  template:
    metadata:
      labels:
        app: netshoot-pod
    spec:
      containers:
      - name: netshoot-pod
        image: praqma/network-multitool
        ports:
        - containerPort: 80
        - containerPort: 443
        env:
        - name: HTTP_PORT
          value: "80"
        - name: HTTPS_PORT
          value: "443"
      terminationGracePeriodSeconds: 0
EOF

# 파드 이름 변수 지정
export PODNAME1=$(kubectl get pod -l app=netshoot-pod -o jsonpath='{.items[0].metadata.name}')
export PODNAME2=$(kubectl get pod -l app=netshoot-pod -o jsonpath='{.items[1].metadata.name}')
export PODNAME3=$(kubectl get pod -l app=netshoot-pod -o jsonpath='{.items[2].metadata.name}')

❯ echo $PODNAME1 $PODNAME2 $PODNAME3
netshoot-pod-64fbf7fb5-f29pg netshoot-pod-64fbf7fb5-ptjz5 netshoot-pod-64fbf7fb5-rbsx8

# 파드 확인
❯ kubectl get pod -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP              NODE                                               NOMINATED NODE   READINESS GATES
netshoot-pod-64fbf7fb5-f29pg   1/1     Running   0          55s   192.168.7.162   ip-192-168-6-121.ap-northeast-2.compute.internal   <none>           <none>
netshoot-pod-64fbf7fb5-ptjz5   1/1     Running   0          55s   192.168.3.93    ip-192-168-0-22.ap-northeast-2.compute.internal    <none>           <none>
netshoot-pod-64fbf7fb5-rbsx8   1/1     Running   0          55s   192.168.9.75    ip-192-168-11-5.ap-northeast-2.compute.internal    <none>           <none>

❯ kubectl get pod -o=custom-columns=NAME:.metadata.name,IP:.status.podIP
NAME                           IP
netshoot-pod-64fbf7fb5-f29pg   192.168.7.162
netshoot-pod-64fbf7fb5-ptjz5   192.168.3.93
netshoot-pod-64fbf7fb5-rbsx8   192.168.9.75

# 노드에 라우팅 정보 확인
## 파드가 생성되면, 워커 노드에 eniY@ifN 추가되고 라우팅 테이블에도 정보가 추가된다.
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c route; echo; done
>> node 43.xxx.xxx.xxx <<
default via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.0.2 via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.4.0/22 dev ens5 proto kernel scope link src 192.168.6.121 metric 512 
192.168.4.1 dev ens5 proto dhcp scope link src 192.168.6.121 metric 512 
192.168.4.8 dev eni14227b50c6b scope link 
192.168.7.162 dev eni00faf3cc888 scope link 

>> node 13.xxx.xxx.xxx <<
default via 192.168.0.1 dev ens5 proto dhcp src 192.168.0.22 metric 512 
192.168.0.0/22 dev ens5 proto kernel scope link src 192.168.0.22 metric 512 
192.168.0.1 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.0.2 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.3.93 dev enic424b97b256 scope link 
192.168.3.202 dev eni92fed275402 scope link 

>> node 3.xx.xx.xx <<
default via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.0.2 via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.8.0/22 dev ens5 proto kernel scope link src 192.168.11.5 metric 512 
192.168.8.1 dev ens5 proto dhcp scope link src 192.168.11.5 metric 512 
192.168.9.75 dev enic50d0c641cc scope link 
```

## 노드 간 파드 통신
```bash
# 파드 IP 변수 지정
export PODIP1=$(kubectl get pod -l app=netshoot-pod -o jsonpath='{.items[0].status.podIP}')
export PODIP2=$(kubectl get pod -l app=netshoot-pod -o jsonpath='{.items[1].status.podIP}')
export PODIP3=$(kubectl get pod -l app=netshoot-pod -o jsonpath='{.items[2].status.podIP}')
❯ echo $PODIP1 $PODIP2 $PODIP3
192.168.7.162 192.168.3.93 192.168.9.75

# 파드1 Shell 에서 파드2로 ping 테스트
❯ kubectl exec -it $PODNAME1 -- ping -c 2 $PODIP2
PING 192.168.3.93 (192.168.3.93) 56(84) bytes of data.
64 bytes from 192.168.3.93: icmp_seq=1 ttl=125 time=1.37 ms
64 bytes from 192.168.3.93: icmp_seq=2 ttl=125 time=0.826 ms

--- 192.168.3.93 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.826/1.099/1.373/0.273 ms

❯ kubectl exec -it $PODNAME1 -- curl -s http://$PODIP2
Praqma Network MultiTool (with NGINX) - netshoot-pod-64fbf7fb5-ptjz5 - 192.168.3.93 - HTTP: 80 , HTTPS: 443
<br>
<hr>
<br>

<h1>05 Jan 2022 - Press-release: `Praqma/Network-Multitool` is now `wbitt/Network-Multitool`</h1>
...
<hr>

❯ kubectl exec -it $PODNAME1 -- curl -sk https://$PODIP2
Praqma Network MultiTool (with NGINX) - netshoot-pod-64fbf7fb5-ptjz5 - 192.168.3.93 - HTTP: 80 , HTTPS: 443
<br>
<hr>
<br>

<h1>05 Jan 2022 - Press-release: `Praqma/Network-Multitool` is now `wbitt/Network-Multitool`</h1>
...
<hr>

# 파드2 Shell 에서 파드3로 ping 테스트
❯ kubectl exec -it $PODNAME2 -- ping -c 2 $PODIP3
PING 192.168.9.75 (192.168.9.75) 56(84) bytes of data.
64 bytes from 192.168.9.75: icmp_seq=1 ttl=125 time=1.38 ms
64 bytes from 192.168.9.75: icmp_seq=2 ttl=125 time=1.09 ms

--- 192.168.9.75 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.087/1.232/1.377/0.145 ms

# 파드3 Shell 에서 파드1로 ping 테스트
❯ kubectl exec -it $PODNAME3 -- ping -c 2 $PODIP1
PING 192.168.7.162 (192.168.7.162) 56(84) bytes of data.
64 bytes from 192.168.7.162: icmp_seq=1 ttl=125 time=1.73 ms
64 bytes from 192.168.7.162: icmp_seq=2 ttl=125 time=1.32 ms

--- 192.168.7.162 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.322/1.527/1.732/0.205 m



# 워커 노드 EC2 : TCPDUMP 확인 (N1에서 확인해봄.)

## 외부 호출 커맨드
❯ kubectl exec -it $PODNAME3 -- ping -c 2 $PODIP1
PING 192.168.7.162 (192.168.7.162) 56(84) bytes of data.
64 bytes from 192.168.7.162: icmp_seq=1 ttl=125 time=1.30 ms
64 bytes from 192.168.7.162: icmp_seq=2 ttl=125 time=1.31 ms

--- 192.168.7.162 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.296/1.305/1.314/0.009 ms

## For Pod to external (outside VPC) traffic, we will program iptables to SNAT using Primary IP address on the Primary ENI.
[root@ip-192-168-6-121 ~]# tcpdump -i any -nn icmp
tcpdump: data link type LINUX_SLL2
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
16:01:58.257546 ens5  In  IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 12, seq 1, length 64
16:01:58.257590 eni00faf3cc888 Out IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 12, seq 1, length 64
16:01:58.257612 eni00faf3cc888 In  IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 12, seq 1, length 64
16:01:58.257620 ens5  Out IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 12, seq 1, length 64
16:01:59.259006 ens5  In  IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 12, seq 2, length 64
16:01:59.259041 eni00faf3cc888 Out IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 12, seq 2, length 64
16:01:59.259062 eni00faf3cc888 In  IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 12, seq 2, length 64
16:01:59.259072 ens5  Out IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 12, seq 2, length 64

[root@ip-192-168-6-121 ~]# tcpdump -i ens5 -nn icmp
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens5, link-type EN10MB (Ethernet), snapshot length 262144 bytes
16:02:36.068352 IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 13, seq 1, length 64
16:02:36.068424 IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 13, seq 1, length 64
16:02:37.070016 IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 13, seq 2, length 64
16:02:37.070077 IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 13, seq 2, length 64

[root@ip-192-168-6-121 ~]# tcpdump -i ens6 -nn icmp
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens6, link-type EN10MB (Ethernet), snapshot length 262144 bytes

[root@ip-192-168-6-121 ~]# tcpdump -i eni00faf3cc888 -nn icmp
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eni00faf3cc888, link-type EN10MB (Ethernet), snapshot length 262144 bytes
16:03:04.357584 IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 15, seq 1, length 64
16:03:04.357606 IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 15, seq 1, length 64
16:03:05.359042 IP 192.168.9.75 > 192.168.7.162: ICMP echo request, id 15, seq 2, length 64
16:03:05.359066 IP 192.168.7.162 > 192.168.9.75: ICMP echo reply, id 15, seq 2, length 64
```

## 파드에서 외부 통신
```bash
# pod-1 Shell 에서 외부로 ping
❯ kubectl exec -it $PODNAME1 -- ping -c 1 www.google.com
PING www.google.com (142.251.151.119) 56(84) bytes of data.
64 bytes from 142.251.151.119 (142.251.151.119): icmp_seq=1 ttl=107 time=17.3 ms

--- www.google.com ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 17.299/17.299/17.299/0.000 ms

❯ kubectl exec -it $PODNAME1 -- ping -i 0.1 www.google.com
PING www.google.com (142.251.156.119) 56(84) bytes of data.
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=1 ttl=106 time=22.2 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=2 ttl=106 time=22.2 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=3 ttl=106 time=22.2 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=4 ttl=106 time=22.2 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=5 ttl=106 time=22.2 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=6 ttl=106 time=22.2 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=7 ttl=106 time=22.3 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=8 ttl=106 time=22.2 ms
64 bytes from 142.251.156.119 (142.251.156.119): icmp_seq=9 ttl=106 time=22.3 ms
^C
--- www.google.com ping statistics ---
9 packets transmitted, 9 received, 0% packet loss, time 804ms
rtt min/avg/max/mdev = 22.218/22.243/22.307/0.028 ms

❯ kubectl exec -it $PODNAME1 -- ping -i 0.1 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=5 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=6 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=7 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=8 ttl=107 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=9 ttl=107 time=22.5 ms
64 bytes from 8.8.8.8: icmp_seq=10 ttl=107 time=22.5 ms
^C
--- 8.8.8.8 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 906ms
rtt min/avg/max/mdev = 22.396/22.420/22.476/0.026 ms


# 워커 노드 EC2 : TCPDUMP 확인
[root@ip-192-168-6-121 ~]# tcpdump -i any -nn icmp
tcpdump: data link type LINUX_SLL2
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
16:04:27.077009 eni00faf3cc888 In  IP 192.168.7.162 > 142.251.118.104: ICMP echo request, id 13, seq 1, length 64
16:04:27.077035 ens5  Out IP 192.168.6.121 > 142.251.118.104: ICMP echo request, id 61619, seq 1, length 64
16:04:27.100131 ens5  In  IP 142.251.118.104 > 192.168.6.121: ICMP echo reply, id 61619, seq 1, length 64
16:04:27.100163 eni00faf3cc888 Out IP 142.251.118.104 > 192.168.7.162: ICMP echo reply, id 13, seq 1, length 64
^C
4 packets captured
5 packets received by filter
0 packets dropped by kernel

[root@ip-192-168-6-121 ~]# tcpdump -i ens5 -nn icmp
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens5, link-type EN10MB (Ethernet), snapshot length 262144 bytes
16:04:51.730330 IP 192.168.6.121 > 142.251.156.119: ICMP echo request, id 2509, seq 1, length 64
16:04:51.752476 IP 142.251.156.119 > 192.168.6.121: ICMP echo reply, id 2509, seq 1, length 64
^C
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

## AWS VPC CNI 설정 변경

### 현재 상태 확인
```bash
# aws-node DaemonSet의 env 확인
❯ kubectl get ds aws-node -n kube-system -o json | jq '.spec.template.spec.containers[0].env'
[
  {
    "name": "ADDITIONAL_ENI_TAGS",
    "value": "{}"
  },
  {
    "name": "ANNOTATE_POD_IP",
    "value": "false"
  },
  {
    "name": "AWS_VPC_CNI_NODE_PORT_SUPPORT",
    "value": "true"
  },
  {
    "name": "AWS_VPC_ENI_MTU",
    "value": "9001"
  },
  {
    "name": "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG",
    "value": "false"
  },
  {
    "name": "AWS_VPC_K8S_CNI_EXTERNALSNAT",
    "value": "false"
  },
  {
    "name": "AWS_VPC_K8S_CNI_LOGLEVEL",
    "value": "DEBUG"
  },
  {
    "name": "AWS_VPC_K8S_CNI_LOG_FILE",
    "value": "/host/var/log/aws-routed-eni/ipamd.log"
  },
  {
    "name": "AWS_VPC_K8S_CNI_RANDOMIZESNAT",
    "value": "prng"
  },
  {
    "name": "AWS_VPC_K8S_CNI_VETHPREFIX",
    "value": "eni"
  },
  {
    "name": "AWS_VPC_K8S_PLUGIN_LOG_FILE",
    "value": "/var/log/aws-routed-eni/plugin.log"
  },
  {
    "name": "AWS_VPC_K8S_PLUGIN_LOG_LEVEL",
    "value": "DEBUG"
  },
  {
    "name": "CLUSTER_ENDPOINT",
    "value": "https://CD8FBB5FC73D4F7C36EDD980E25FC54C.gr7.ap-northeast-2.eks.amazonaws.com"
  },
  {
    "name": "CLUSTER_NAME",
    "value": "myeks"
  },
  {
    "name": "DISABLE_INTROSPECTION",
    "value": "false"
  },
  {
    "name": "DISABLE_METRICS",
    "value": "false"
  },
  {
    "name": "DISABLE_NETWORK_RESOURCE_PROVISIONING",
    "value": "false"
  },
  {
    "name": "ENABLE_IMDS_ONLY_MODE",
    "value": "false"
  },
  {
    "name": "ENABLE_IPv4",
    "value": "true"
  },
  {
    "name": "ENABLE_IPv6",
    "value": "false"
  },
  {
    "name": "ENABLE_MULTI_NIC",
    "value": "false"
  },
  {
    "name": "ENABLE_POD_ENI",
    "value": "false"
  },
  {
    "name": "ENABLE_PREFIX_DELEGATION",
    "value": "false"
  },
  {
    "name": "ENABLE_SUBNET_DISCOVERY",
    "value": "true"
  },
  {
    "name": "NETWORK_POLICY_ENFORCING_MODE",
    "value": "standard"
  },
  {
    "name": "VPC_CNI_VERSION",
    "value": "v1.21.1"
  },
  {
    "name": "VPC_ID",
    "value": "vpc-0c587c1dda2594bcd"
  },
  {
    "name": "WARM_ENI_TARGET",
    "value": "1"
  },
  {
    "name": "WARM_PREFIX_TARGET",
    "value": "1"
  },
  {
    "name": "MY_NODE_NAME",
    "valueFrom": {
      "fieldRef": {
        "apiVersion": "v1",
        "fieldPath": "spec.nodeName"
      }
    }
  },
  {
    "name": "MY_POD_NAME",
    "valueFrom": {
      "fieldRef": {
        "apiVersion": "v1",
        "fieldPath": "metadata.name"
      }
    }
  }
]

# 노드 정보 확인 : 노드 중 1대는 eni 가 1개만 배치됨!
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c addr; echo; done
>> node 43.xxx.xxx.xxx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 06:44:8f:f8:bd:a7 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.6.121/22 metric 512 brd 192.168.7.255 scope global dynamic ens5
       valid_lft 2901sec preferred_lft 2901sec
    inet6 fe80::444:8fff:fef8:bda7/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eni14227b50c6b@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc noqueue state UP group default 
    link/ether da:e2:7c:4a:0a:e5 brd ff:ff:ff:ff:ff:ff link-netns cni-151d5dc3-d27e-45d4-bb78-9d00a908a114
    inet6 fe80::d8e2:7cff:fe4a:ae5/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
4: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 06:b4:dd:a8:aa:5f brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    inet 192.168.4.57/22 brd 192.168.7.255 scope global ens6
       valid_lft forever preferred_lft forever
    inet6 fe80::4b4:ddff:fea8:aa5f/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

>> node 13.xxx.xxx.xxx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:a6:a1:c7:cc:11 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.0.22/22 metric 512 brd 192.168.3.255 scope global dynamic ens5
       valid_lft 2900sec preferred_lft 2900sec
    inet6 fe80::a6:a1ff:fec7:cc11/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eni92fed275402@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc noqueue state UP group default 
    link/ether fe:f5:4b:f6:d0:c1 brd ff:ff:ff:ff:ff:ff link-netns cni-ec9d1341-0bfb-99da-a940-004620367286
    inet6 fe80::fcf5:4bff:fef6:d0c1/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
14: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:5d:b4:96:61:31 brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    inet 192.168.3.59/22 brd 192.168.3.255 scope global ens7
       valid_lft forever preferred_lft forever
    inet6 fe80::5d:b4ff:fe96:6131/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

>> node 3.xx.xx.xx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 0a:72:3d:85:fc:37 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.11.5/22 metric 512 brd 192.168.11.255 scope global dynamic ens5
       valid_lft 2899sec preferred_lft 2899sec
    inet6 fe80::872:3dff:fe85:fc37/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c route; echo; done
>> node 43.xxx.xxx.xxx <<
default via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.0.2 via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.4.0/22 dev ens5 proto kernel scope link src 192.168.6.121 metric 512 
192.168.4.1 dev ens5 proto dhcp scope link src 192.168.6.121 metric 512 
192.168.4.8 dev eni14227b50c6b scope link 

>> node 13.xxx.xxx.xxx <<
default via 192.168.0.1 dev ens5 proto dhcp src 192.168.0.22 metric 512 
192.168.0.0/22 dev ens5 proto kernel scope link src 192.168.0.22 metric 512 
192.168.0.1 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.0.2 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.3.202 dev eni92fed275402 scope link 

>> node 3.xx.xx.xx <<
default via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.0.2 via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.8.0/22 dev ens5 proto kernel scope link src 192.168.11.5 metric 512 
192.168.8.1 dev ens5 proto dhcp scope link src 192.168.11.5 metric 512 


# IpamD debugging commands  https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/troubleshooting.md
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i curl -s http://localhost:61679/v1/enis | jq; echo; done
>> node 43.xxx.xxx.xxx <<
{
  "0": {
    "TotalIPs": 10,
    "AssignedIPs": 1,
    "ENIs": {
      "eni-05084d1f2e789e47c": {
        "ID": "eni-05084d1f2e789e47c",
        "IsPrimary": true,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 0,
        "AvailableIPv4Cidrs": {
          "192.168.4.138/32": {
            "Cidr": {
              "IP": "192.168.4.138",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.4.138": {
                "Address": "192.168.4.138",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:42:29.892593033Z",
                "UnassignedTime": "2026-03-24T13:58:24.056812242Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.4.8/32": {
            "Cidr": {
              "IP": "192.168.4.8",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.4.8": {
                "Address": "192.168.4.8",
                "IPAMKey": {
                  "networkName": "aws-cni",
                  "containerID": "6400f25e7fd8133daef1f8e49b240dc4e0683013578bbdcde98e5d252c999c40",
                  "ifName": "eth0"
                },
                "IPAMMetadata": {
                  "k8sPodNamespace": "kube-system",
                  "k8sPodName": "coredns-d487b6fcb-8d8v9",
                  "interfacesCount": 1
                },
                "AssignedTime": "2026-03-24T12:56:48.117942313Z",
                "UnassignedTime": "0001-01-01T00:00:00Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.5.217/32": {
            "Cidr": {
              "IP": "192.168.5.217",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.217": {
                "Address": "192.168.5.217",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.067912612Z",
                "UnassignedTime": "2026-03-24T13:58:24.158186441Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.5.7/32": {
            "Cidr": {
              "IP": "192.168.5.7",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.7": {
                "Address": "192.168.5.7",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:47.968715799Z",
                "UnassignedTime": "2026-03-24T13:58:24.168168516Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.7.162/32": {
            "Cidr": {
              "IP": "192.168.7.162",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.7.162": {
                "Address": "192.168.7.162",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:44:43.129996633Z",
                "UnassignedTime": "2026-03-24T16:06:26.957083162Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 254
      },
      "eni-0ea9144f1eb771424": {
        "ID": "eni-0ea9144f1eb771424",
        "IsPrimary": false,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 1,
        "AvailableIPv4Cidrs": {
          "192.168.5.146/32": {
            "Cidr": {
              "IP": "192.168.5.146",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.146": {
                "Address": "192.168.5.146",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.424190322Z",
                "UnassignedTime": "2026-03-24T13:58:24.117642322Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.5.252/32": {
            "Cidr": {
              "IP": "192.168.5.252",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.5.252": {
                "Address": "192.168.5.252",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.158358297Z",
                "UnassignedTime": "2026-03-24T13:58:24.028539116Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.6.159/32": {
            "Cidr": {
              "IP": "192.168.6.159",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.6.159": {
                "Address": "192.168.6.159",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.269912639Z",
                "UnassignedTime": "2026-03-24T13:58:24.077109524Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.6.177/32": {
            "Cidr": {
              "IP": "192.168.6.177",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.6.177": {
                "Address": "192.168.6.177",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.313117509Z",
                "UnassignedTime": "2026-03-24T13:58:24.031161028Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.6.217/32": {
            "Cidr": {
              "IP": "192.168.6.217",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.6.217": {
                "Address": "192.168.6.217",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:40:41.911354946Z",
                "UnassignedTime": "2026-03-24T13:41:55.212919674Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 2
      }
    }
  }
}

>> node 13.xxx.xxx.xxx <<
{
  "0": {
    "TotalIPs": 10,
    "AssignedIPs": 1,
    "ENIs": {
      "eni-00c5445c5f1db45d4": {
        "ID": "eni-00c5445c5f1db45d4",
        "IsPrimary": true,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 0,
        "AvailableIPv4Cidrs": {
          "192.168.1.196/32": {
            "Cidr": {
              "IP": "192.168.1.196",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.196": {
                "Address": "192.168.1.196",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.077689585Z",
                "UnassignedTime": "2026-03-24T13:58:24.162466308Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.1.244/32": {
            "Cidr": {
              "IP": "192.168.1.244",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.244": {
                "Address": "192.168.1.244",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:41:48.182309449Z",
                "UnassignedTime": "2026-03-24T13:58:24.342194023Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.2.113/32": {
            "Cidr": {
              "IP": "192.168.2.113",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.2.113": {
                "Address": "192.168.2.113",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:42:34.887080551Z",
                "UnassignedTime": "2026-03-24T13:58:24.311196683Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.3.202/32": {
            "Cidr": {
              "IP": "192.168.3.202",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.3.202": {
                "Address": "192.168.3.202",
                "IPAMKey": {
                  "networkName": "aws-cni",
                  "containerID": "3bf0f4ea1779e94291b4fcbb48caca790e1d17ced78c12ec9773023bc443dd92",
                  "ifName": "eth0"
                },
                "IPAMMetadata": {
                  "k8sPodNamespace": "kube-system",
                  "k8sPodName": "coredns-d487b6fcb-lz8w6",
                  "interfacesCount": 1
                },
                "AssignedTime": "2026-03-24T12:56:48.068477383Z",
                "UnassignedTime": "0001-01-01T00:00:00Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.3.93/32": {
            "Cidr": {
              "IP": "192.168.3.93",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.3.93": {
                "Address": "192.168.3.93",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:44:43.150274964Z",
                "UnassignedTime": "2026-03-24T16:06:26.992935597Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 254
      },
      "eni-0eefccb53ab57354e": {
        "ID": "eni-0eefccb53ab57354e",
        "IsPrimary": false,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 2,
        "AvailableIPv4Cidrs": {
          "192.168.1.117/32": {
            "Cidr": {
              "IP": "192.168.1.117",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.117": {
                "Address": "192.168.1.117",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:42:36.887418807Z",
                "UnassignedTime": "2026-03-24T13:58:24.373474658Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.1.225/32": {
            "Cidr": {
              "IP": "192.168.1.225",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.1.225": {
                "Address": "192.168.1.225",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:54.106507083Z",
                "UnassignedTime": "2026-03-24T13:41:53.906414848Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.2.227/32": {
            "Cidr": {
              "IP": "192.168.2.227",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.2.227": {
                "Address": "192.168.2.227",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:53.900753611Z",
                "UnassignedTime": "2026-03-24T13:41:56.197890165Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.2.62/32": {
            "Cidr": {
              "IP": "192.168.2.62",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.2.62": {
                "Address": "192.168.2.62",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:53.422363656Z",
                "UnassignedTime": "2026-03-24T13:41:57.807384537Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.3.131/32": {
            "Cidr": {
              "IP": "192.168.3.131",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.3.131": {
                "Address": "192.168.3.131",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T13:39:53.806283092Z",
                "UnassignedTime": "2026-03-24T13:42:35.9851485Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 3
      }
    }
  }
}

>> node 3.xx.xx.xx <<
{
  "0": {
    "TotalIPs": 5,
    "AssignedIPs": 0,
    "ENIs": {
      "eni-0aa20caba88eee9bd": {
        "ID": "eni-0aa20caba88eee9bd",
        "IsPrimary": true,
        "IsTrunk": false,
        "IsEFA": false,
        "DeviceNumber": 0,
        "AvailableIPv4Cidrs": {
          "192.168.11.208/32": {
            "Cidr": {
              "IP": "192.168.11.208",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.11.208": {
                "Address": "192.168.11.208",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:06:00.202476854Z",
                "UnassignedTime": "2026-03-24T15:07:49.339988055Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.11.63/32": {
            "Cidr": {
              "IP": "192.168.11.63",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.11.63": {
                "Address": "192.168.11.63",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:07:42.599808332Z",
                "UnassignedTime": "2026-03-24T15:10:45.251269857Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.9.217/32": {
            "Cidr": {
              "IP": "192.168.9.217",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.9.217": {
                "Address": "192.168.9.217",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:07:42.462719034Z",
                "UnassignedTime": "2026-03-24T15:10:45.16345917Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.9.237/32": {
            "Cidr": {
              "IP": "192.168.9.237",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.9.237": {
                "Address": "192.168.9.237",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:05:59.980496898Z",
                "UnassignedTime": "2026-03-24T15:07:45.425374626Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          },
          "192.168.9.75/32": {
            "Cidr": {
              "IP": "192.168.9.75",
              "Mask": "/////w=="
            },
            "IPAddresses": {
              "192.168.9.75": {
                "Address": "192.168.9.75",
                "IPAMKey": {
                  "networkName": "",
                  "containerID": "",
                  "ifName": ""
                },
                "IPAMMetadata": {},
                "AssignedTime": "2026-03-24T15:44:43.125451879Z",
                "UnassignedTime": "2026-03-24T16:06:26.987261376Z"
              }
            },
            "IsPrefix": false,
            "AddressFamily": ""
          }
        },
        "IPv6Cidrs": {},
        "RouteTableID": 254
      }
    }
  }
}
```

### AWS VPC CNI 설정 변경 적용

eks.tf 수정
- 이후, `terraform apply`로 반영하기.
- 
```bash
  # add-on
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          #WARM_ENI_TARGET = "1" # 현재 ENI 외에 여유 ENI 1개를 항상 확보
          WARM_IP_TARGET  = "5" # 현재 사용 중인 IP 외에 여유 IP 5개를 항상 유지, 설정 시 WARM_ENI_TARGET 무시됨
          MINIMUM_IP_TARGET   = "10" # 노드 시작 시 최소 확보해야 할 IP 총량 10개
          #ENABLE_PREFIX_DELEGATION = "true" 
          #WARM_PREFIX_TARGET = "1" # PREFIX_DELEGATION 사용 시, 1개의 여유 대역(/28) 유지
        }
      })
    }
  }
```

이어서 확인한다.
```bash
# 파드 재생성 확인
❯ kubectl get pod -n kube-system -l k8s-app=aws-node
NAME             READY   STATUS    RESTARTS   AGE
aws-node-7nr28   2/2     Running   0          4m3s
aws-node-f57s7   2/2     Running   0          4m10s
aws-node-jpfz9   2/2     Running   0          3m59s

# addon 확인
❯ eksctl get addon --cluster myeks
2026-03-25 01:14:52 [ℹ]  Kubernetes version "1.34" in use by cluster "myeks"
2026-03-25 01:14:52 [ℹ]  getting all addons
2026-03-25 01:14:53 [ℹ]  to see issues for an addon run `eksctl get addon --name <addon-name> --cluster <cluster-name>`
NAME            VERSION                 STATUS  ISSUES  IAMROLE UPDATE AVAILABLECONFIGURATION VALUES                                     POD IDENTITY ASSOCIATION ROLES
coredns         v1.13.2-eksbuild.3      ACTIVE  0
kube-proxy      v1.34.5-eksbuild.2      ACTIVE  0
vpc-cni         v1.21.1-eksbuild.5      ACTIVE  0                               {"env":{"MINIMUM_IP_TARGET":"10","WARM_IP_TARGET":"5"}}


# aws-node DaemonSet의 env 확인
❯ kubectl get ds aws-node -n kube-system -o json | jq '.spec.template.spec.containers[0].env'
[
  {
    "name": "ADDITIONAL_ENI_TAGS",
    "value": "{}"
  },
  {
    "name": "ANNOTATE_POD_IP",
    "value": "false"
  },
  {
    "name": "AWS_VPC_CNI_NODE_PORT_SUPPORT",
    "value": "true"
  },
  {
    "name": "AWS_VPC_ENI_MTU",
    "value": "9001"
  },
  {
    "name": "AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG",
    "value": "false"
  },
  {
    "name": "AWS_VPC_K8S_CNI_EXTERNALSNAT",
    "value": "false"
  },
  {
    "name": "AWS_VPC_K8S_CNI_LOGLEVEL",
    "value": "DEBUG"
  },
  {
    "name": "AWS_VPC_K8S_CNI_LOG_FILE",
    "value": "/host/var/log/aws-routed-eni/ipamd.log"
  },
  {
    "name": "AWS_VPC_K8S_CNI_RANDOMIZESNAT",
    "value": "prng"
  },
  {
    "name": "AWS_VPC_K8S_CNI_VETHPREFIX",
    "value": "eni"
  },
  {
    "name": "AWS_VPC_K8S_PLUGIN_LOG_FILE",
    "value": "/var/log/aws-routed-eni/plugin.log"
  },
  {
    "name": "AWS_VPC_K8S_PLUGIN_LOG_LEVEL",
    "value": "DEBUG"
  },
  {
    "name": "CLUSTER_ENDPOINT",
    "value": "https://CD8FBB5FC73D4F7C36EDD980E25FC54C.gr7.ap-northeast-2.eks.amazonaws.com"
  },
  {
    "name": "CLUSTER_NAME",
    "value": "myeks"
  },
  {
    "name": "DISABLE_INTROSPECTION",
    "value": "false"
  },
  {
    "name": "DISABLE_METRICS",
    "value": "false"
  },
  {
    "name": "DISABLE_NETWORK_RESOURCE_PROVISIONING",
    "value": "false"
  },
  {
    "name": "ENABLE_IMDS_ONLY_MODE",
    "value": "false"
  },
  {
    "name": "ENABLE_IPv4",
    "value": "true"
  },
  {
    "name": "ENABLE_IPv6",
    "value": "false"
  },
  {
    "name": "ENABLE_MULTI_NIC",
    "value": "false"
  },
  {
    "name": "ENABLE_POD_ENI",
    "value": "false"
  },
  {
    "name": "ENABLE_PREFIX_DELEGATION",
    "value": "false"
  },
  {
    "name": "ENABLE_SUBNET_DISCOVERY",
    "value": "true"
  },
  {
    "name": "MINIMUM_IP_TARGET",
    "value": "10"
  },
  {
    "name": "NETWORK_POLICY_ENFORCING_MODE",
    "value": "standard"
  },
  {
    "name": "VPC_CNI_VERSION",
    "value": "v1.21.1"
  },
  {
    "name": "VPC_ID",
    "value": "vpc-0c587c1dda2594bcd"
  },
  {
    "name": "WARM_ENI_TARGET",
    "value": "1"
  },
  {
    "name": "WARM_IP_TARGET",
    "value": "5"
  },
  {
    "name": "WARM_PREFIX_TARGET",
    "value": "1"
  },
  {
    "name": "MY_NODE_NAME",
    "valueFrom": {
      "fieldRef": {
        "apiVersion": "v1",
        "fieldPath": "spec.nodeName"
      }
    }
  },
  {
    "name": "MY_POD_NAME",
    "valueFrom": {
      "fieldRef": {
        "apiVersion": "v1",
        "fieldPath": "metadata.name"
      }
    }
  }
]

❯ kubectl describe ds aws-node -n kube-system | grep -E "WARM_IP_TARGET|MINIMUM_IP_TARGET"
      MINIMUM_IP_TARGET:                      10
      WARM_IP_TARGET:                         5

# 노드 정보 확인 : (hostNetwork 제외) 파드가 없는 노드에도 ENI 추가 확인
❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c addr; echo; done
>> node 43.xxx.xxx.xxx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 06:44:8f:f8:bd:a7 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.6.121/22 metric 512 brd 192.168.7.255 scope global dynamic ens5
       valid_lft 2392sec preferred_lft 2392sec
    inet6 fe80::444:8fff:fef8:bda7/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eni14227b50c6b@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc noqueue state UP group default 
    link/ether da:e2:7c:4a:0a:e5 brd ff:ff:ff:ff:ff:ff link-netns cni-151d5dc3-d27e-45d4-bb78-9d00a908a114
    inet6 fe80::d8e2:7cff:fe4a:ae5/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
4: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 06:b4:dd:a8:aa:5f brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    inet 192.168.4.57/22 brd 192.168.7.255 scope global ens6
       valid_lft forever preferred_lft forever
    inet6 fe80::4b4:ddff:fea8:aa5f/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

>> node 13.xxx.xxx.xxx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:a6:a1:c7:cc:11 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.0.22/22 metric 512 brd 192.168.3.255 scope global dynamic ens5
       valid_lft 2392sec preferred_lft 2392sec
    inet6 fe80::a6:a1ff:fec7:cc11/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eni92fed275402@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc noqueue state UP group default 
    link/ether fe:f5:4b:f6:d0:c1 brd ff:ff:ff:ff:ff:ff link-netns cni-ec9d1341-0bfb-99da-a940-004620367286
    inet6 fe80::fcf5:4bff:fef6:d0c1/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
14: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:5d:b4:96:61:31 brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    inet 192.168.3.59/22 brd 192.168.3.255 scope global ens7
       valid_lft forever preferred_lft forever
    inet6 fe80::5d:b4ff:fe96:6131/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

>> node 3.xx.xx.xx <<
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 0a:72:3d:85:fc:37 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 192.168.11.5/22 metric 512 brd 192.168.11.255 scope global dynamic ens5
       valid_lft 2391sec preferred_lft 2391sec
    inet6 fe80::872:3dff:fe85:fc37/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
342: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 0a:11:c0:58:d5:51 brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    inet 192.168.11.25/22 brd 192.168.11.255 scope global ens6
       valid_lft forever preferred_lft forever
    inet6 fe80::811:c0ff:fe58:d551/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

❯ for i in $N1 $N2 $N3; do echo ">> node $i <<"; ssh ec2-user@$i sudo ip -c route; echo; done
>> node 43.xxx.xxx.xxx <<
default via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.0.2 via 192.168.4.1 dev ens5 proto dhcp src 192.168.6.121 metric 512 
192.168.4.0/22 dev ens5 proto kernel scope link src 192.168.6.121 metric 512 
192.168.4.1 dev ens5 proto dhcp scope link src 192.168.6.121 metric 512 
192.168.4.8 dev eni14227b50c6b scope link 

>> node 13.xxx.xxx.xxx <<
default via 192.168.0.1 dev ens5 proto dhcp src 192.168.0.22 metric 512 
192.168.0.0/22 dev ens5 proto kernel scope link src 192.168.0.22 metric 512 
192.168.0.1 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.0.2 dev ens5 proto dhcp scope link src 192.168.0.22 metric 512 
192.168.3.202 dev eni92fed275402 scope link 

>> node 3.xx.xx.xx <<
default via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.0.2 via 192.168.8.1 dev ens5 proto dhcp src 192.168.11.5 metric 512 
192.168.8.0/22 dev ens5 proto kernel scope link src 192.168.11.5 metric 512 
192.168.8.1 dev ens5 proto dhcp scope link src 192.168.11.5 metric 512 
```