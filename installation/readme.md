### 250630
# install kubernetes
### 설치 대상
| 구성 요소       | Master 노드 | Worker 노드 |
| ----------- | --------- | --------- |
| **kubeadm** | ✅ 설치      | ✅ 설치      |
| **kubelet** | ✅ 설치      | ✅ 설치      |
| **kubectl** | ✅ 설치   | ❌ 선택 사항   |

### <br/>

### kube-apiserver, kube-proxy 같은 컴포넌트들은 컨테이너 이미지로 배포할 수 있다.
### 이러한 각 components들은 container 환경에서 운영하는 것이 좋다고 공식 docs에 나와있다.
#### https://kubernetes.io/docs/setup/
#### ![image](https://github.com/user-attachments/assets/075aae93-576d-4b0d-a468-b302f6fc607f)
### <br/>

### 여기서 kubernetes가 추구하는 철학이 드러난다.
#### https://kubernetes.io/releases/download/
#### kubernets의 로고는 조타(steering 또는 helm)로 그려져 있다. 그리고 그것을 조타가 있는 곳은 배(ship)이다.
#### ship을 하나 구성하면, 운항을 할 때 필요한 것들은 배 안에 container들을 실을 수 있다.
#### 배를 하나 만들고, container를 운영하는 것을 나타내는 것에 대해 비유적으로 아주 잘 설명해준다.
### <br/><br/>

## Download Kubernetes (넘어가기)
### [Install kubeadm](https://github.com/Shin-jongwhan/kubernetes/tree/main/installation#install-kubeadm) 에서 한 번에 kubeadm, kubelet, kubectl를 설치할 것이다. 참고만 하기.
#### https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
### kubectl을 local에 설치
### 나는 binary로 설치했다.
#### * apt로 설치하는 방법도 있다. 위 사이트를 참고한다.
```
# download
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# install
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
### <br/>

### 만약 root 권한이 없으면 다음을 실행한다.
```
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl
# and then append (or prepend) ~/.local/bin to $PATH
```
### <br/>

### 실행 확인
```
kubectl version --client
# or
kubectl version --client --output=yaml
```
### 테스트를 위해 Docker in Docker 환경에서 실행하였다.
#### ![image](https://github.com/user-attachments/assets/c8baf1ea-28b2-4cd8-a408-c87a93c62a57)
### <br/><br/>

## Install tools
#### https://kubernetes.io/docs/tasks/tools/
### 🔍 3가지 도구 비교 요약
| 도구                       | 특징                        | 사용하는 경우               | 설치 대상             |
| ------------------------ | ------------------------- | --------------------- | ----------------- |
| **Minikube**             | 가볍고 쉬운 All-in-one K8s 실행기 | 로컬에서 간단히 K8s 테스트, 실습용 | 설치만 하면 모든 것 자동    |
| **Kind (K8s IN Docker)** | Docker 위에서 K8s 클러스터 구성    | CI/CD 테스트나 멀티 노드 실험   | Docker 기반, 가상 환경  |
| **kubeadm**              | 실제 클러스터를 만드는 툴            | 진짜 서버에 K8s를 설치할 때     | 마스터/워커 노드 구성 시 필수 |
### <br/>

### 나는 service, db, backend 서버가 있고 service를 마스터로, db, backend를 worker로 구성할 것이다. 이를 위해 kubeadm을 사용할 것이다.
### <br/><br/>

## install kubeadm
#### https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
### 아래와 같이 서버 구성이 되어 있어야 한다.
#### ![image](https://github.com/user-attachments/assets/83865713-137e-4e1a-a452-99a49438a4a0)
### <br/>

### 1. 커널 버전 확인
#### 현재 컨테이너에서 테스트하고 있는데, uname -r로 확인하는 커널 버전은 컨테이너 밖 host의 커널 버전이다.
#### cat /etc/os-release로 표시되는 건 container 안 ubuntu 버전이다.
#### ![image](https://github.com/user-attachments/assets/7a4e18ee-ac31-4457-a8fc-f9b1c93850b2)
#### <br/>

#### 커널 버전 각 의미(uname -r 에서 확인하는 것)
| 항목        | 설명                                                           |
| --------- | ------------------------------------------------------------ |
| `6.8.0`  | 커널 **메인 버전** (Major.Minor.Patch)                             |
| `62`     | Ubuntu에서 자체적으로 붙이는 **패치 버전** 또는 **빌드 번호**                    |
| `generic` | 빌드된 커널의 **타입(variant)**. 주로 **일반 목적**(General-purpose)으로 사용됨 |

### <br/>

### 2. ip, MAC 주소 확인
### ifconfig로 ip가 unique한지 확인한다.
```
ifconfig -a
```
#### <br/>

### MAC 주소가 unique한지 확인한다.
```
cat /sys/class/dmi/id/product_uuid
```
### MAC과 NIC에 대한 자세한 내용은 아래를 참고한다.
#### https://github.com/Shin-jongwhan/network/blob/main/NIC_Network_Interface_Card/readme.md
#### <br/>

### Kubernetes는 각 노드를 식별하기 위해 product_uuid 또는 MAC 주소를 사용한다. 따라서 각 노드의 product_uuid 또는 MAC 주소는 반드시 고유해야 한다.
### VM 환경일 때는?
- 서버가 VM이라도 괜찮다. VM은 가상화 플랫폼(VMware 등... 내 케이스의 경우 proxmux)이 MAC 주소를 자동으로 생성해준다.
- 좀 더 자세히 말하면 가상 머신은 '가상 네트워크 카드'를 사용한다.
### kubernetes는 docker virtual NIC를 이용하는 건 아니다. ens18 (나 같은 경우 VM 환경이고, ens18은 가상화 플랫폼이 생성해준 virtual NIC이다)과 같은 걸 이용하는 거다. 
### <br/>

### 6443 포트 열려있는지 확인
#### 먼저 방화벽에서 포트를 차단하는지 확인한다.
#### 방화벽은 ufw, firewalld 두 개를 많이 쓰는데 둘 다 확인하자.
```
sudo ufw status
systemctl status firewalld
```
### <br/>

### nc (netcat, 포트 열려있는지 테스트하는 명령어)로 확인한다.
#### * 참고 : Kubernetes API Server에서 사용하는 포트이다. 만약 API server가 열려있지 않다면 그래도 connection refused가 나올 것이다. 방화벽에서 포트가 열려있다면 넘어가자.
- 127.0.0.1 : 테스트할 IP 주소 (로컬)
- 6443 : 테스트할 포트 번호
- -z : 연결만 시도하고 데이터 전송 안 함
- -v : 자세한 출력
- -w 2 : 연결 타임아웃 2초 설정
```
nc 127.0.0.1 6443 -zv -w 2
```
### <br/>

## Installing kubeadm, kubelet and kubectl
### 각 software에 대한 설명
#### 공식 docs에는 이렇게 적혀 있다.
- kubeadm: the command to bootstrap the cluster.
- kubelet: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
- kubectl: the command line util to talk to your cluster.
### <br/>

### 역할, 설치 위치
#### * 마스터 노드는 컨트롤 플레인을 의미한다.
| 구성 요소         | 역할                                          | 어디에 설치해야 하나요?                             |
| ------------- | ------------------------------------------- | ----------------------------------------- |
| **`kubeadm`** | 클러스터를 초기화(`init`)하거나 워커 노드로 연결(`join`)하는 도구 | ✅ **모든 노드 (마스터 + 워커)**                    |
| **`kubelet`** | 각 노드에서 Pod을 실행하고 관리하는 실제 에이전트               | ✅ **모든 노드 (마스터 + 워커)**                    |
| **`kubectl`** | 클러스터를 제어하는 CLI 도구 (`get pods`, `apply`, 등)  | 🔸 **선택적** (보통 마스터 노드 또는 운영자의 로컬 PC에만 설치) |
#### <br/>

### 참고, pkgs.k8s.io를 쓰라고 한다.
#### ![image](https://github.com/user-attachments/assets/e8f3bc00-df3e-485c-88d9-9e07e0a91e1a)
#### <br/>

### kubeadm, kubelet, kubectl 설치 
#### * 참고 : 위 테이블에서 보면 kubeadm, kubelet은 master, worker node 공통으로 설치하고, kubectl은 master node에만 설치한다.
```
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
### <br/>

### 다음으로 cgroup을 configure 하라고 나와 있는데, default가 systemd라서 그냥 건드릴 필요 없이 systemctl로 이용하면 된다.
### 자세한 내용은 아래 참고
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/cgroup_driver
#### ![image](https://github.com/user-attachments/assets/5b9669d5-5164-4003-951f-cee0ec98054c)
### <br/><br/>

## Creating a cluster with kubeadm
#### https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
### kubeadm을 사용하면 Kubernetes의 모범 사례에 부합하는 최소한의 실행 가능한(Minimum Viable) 클러스터를 만들 수 있고, 실제로 Kubernetes Conformance 테스트를 통과할 수 있는 클러스터를 구축할 수 있다고 한다.
### 나는 ansible을 별도로 사용하고 있고, 아래에 kubernetes 설치 관련해서 playbook도 정리하였다.
#### https://github.com/Shin-jongwhan/IaC_infrastructure_as_code/tree/main/ansible/playbook
#### ![image](https://github.com/user-attachments/assets/937e53ef-6992-4b22-a07d-f89ffd3e4389)
#### <br/>

### Kubernetes Conformance 테스트란?
- Kubernetes Certified 제품임을 입증하기 위해 거쳐야 하는 테스트 스위트(여러 개의 테스트 케이스들을 모은 그룹)
- API, 동작, 기능이 공식 Kubernetes 사양과 일치하는지 확인함
- CNCF(Cloud Native Computing Foundation)에서 인증하는 데 사용됨
#### <br/>

### kubeadm을 사용하면
#### kubeadm으로 설치한 클러스터는 정식 Kubernetes 사양에 부합하는 구조를 만들 수 있고,
#### 테스트 통과 및 인증 기반의 배포에도 적합한 수준의 품질을 제공한다는 의미이다.
#### 만약 기업 환경이나 표준 기반의 서비스 인프라를 구축하고자 한다면, kubeadm은 좋은 출발점이다.
### <br/>

### 업그레이드가 필요한 경우 아래 참고
#### https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/
### 버전 확인
```
kubectl version --client
kubeadm version
kubelet --version
```
#### ![image](https://github.com/user-attachments/assets/a1b03211-5339-4673-b4a1-23c9bcc9f624)
#### <br/>

### kubelet은 에이전트이기 때문에 업그레이드하면 restart 해야 한다(자세한 내용은 위 upgrading-linux-nodes 링크 참고).
```
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
### <br/>

### 여기서는 이걸 할 거임
- Install a single control-plane Kubernetes cluster
- Install a Pod network on the cluster so that your Pods can talk to each other
### <br/><br/>

## kubeadm의 네트워크 인식 방법
#### kubeadm과 다른 Kubernetes 컴포넌트들은 기본 게이트웨이를 가진 네트워크 인터페이스에서 사용 가능한 IP를 자동으로 찾아 **광고(advertising) 또는 수신(listening)**에 사용한다.
#### 이 IP는 ip route show 명령어로 확인 가능하며, "default via"로 시작하는 라인을 찾으면 된다.
```
ip route show
```
#### ![image](https://github.com/user-attachments/assets/a6f86875-33ec-478d-ab96-558329ad316e)
#### <br/>

### 왜 Kubernetes에서 글로벌 유니캐스트 IP를 선호할까?
### ❗ 중요 : 일반적으로 글로벌 유니캐스트 IP는 외부와 통신 가능한 IP로 공인 IP를 말하는데, 내부망으로 구성할 수 있는 거면 private IP를 사용한다. 
### 어쨋든 !! 가장 중요한 건 통신만 가능하면 된다는 거다.
- 클러스터의 컴포넌트들이 서로 통신해야 하므로, 외부나 다른 노드에서도 접근 가능한 IP여야 한다.
- 로컬에서만 동작하는 127.0.0.1이나 사설 IP만 사용할 경우 통신 장애가 발생할 수 있음.
- 단, 보안상 이유로 외부에 직접 노출되면 방화벽 등 보안 설정 필요.
### 글로벌 유니캐스트 IP에 대한 자세한 내용을 아래 링크를 확인하자.
#### [public_IP_and_global_unicast_IP](https://github.com/Shin-jongwhan/network/tree/main/public_IP_and_global_unicast_IP)
### <br/>

### X.509 certificate
#### Kubernetes 클러스터에서는 직접 만든 적이 없어도 kubeadm이 자동으로 X.509 인증서를 생성해서 사용한다.
#### Kubernetes의 보안 통신(예: kubelet ↔ API 서버, kubectl ↔ API 서버)은 모두 TLS를 기반으로 하고, 이때 X.509 인증서가 필수적으로 사용된다.
#### * HTTPS에 사용되는 인증서도 X.509 인증서임
### <br/>

### 전반적인 내용 요약
| 항목                                                | 설명                                          |
| ------------------------------------------------- | ------------------------------------------- |
| **기본 게이트웨이가 존재해야 함**                              | `ip route show` 명령에서 `"default via"`가 있어야 함 |
| **기본 게이트웨이에 연결된 네트워크 인터페이스에 글로벌 유니캐스트 IP가 있어야 함** | 이 IP를 자동으로 Kubernetes가 감지해서 사용함             |
| **IP 자동 감지를 선호함**                                 | 모든 컴포넌트에 직접 IP를 주는 방식은 권장하지 않음              |
| **IP가 바뀌면 인증서 갱신 필요**                             | 제어 플레인 노드 IP가 변경되면 X.509 인증서 재생성 필요         |

### <br/>

### 설정해야 하는 항목 (직접 설정이 필요한 경우)
| 설정 항목                   | 설정 위치 / 방법                                                                                    | 상황                                           |
| ----------------------- | --------------------------------------------------------------------------------------------- | -------------------------------------------- |
| **API 서버 advertise IP** | `--apiserver-advertise-address=<IP>` 또는 `InitConfiguration.localAPIEndpoint.advertiseAddress` | `kubeadm init` 또는 `join` 시 컨트롤 플레인 노드에 설정 필요 |
| **kubelet 노드 IP**       | `kubeadm.yaml` 내 `.nodeRegistration.kubeletExtraArgs.node-ip=<IP>`                            | 각 노드가 정확한 IP로 등록되게 하려면 설정                    |
| **기본 게이트웨이 경로 설정**      | `ip route add default via <게이트웨이 IP>`                                                         | 기본 경로가 없거나 바꾸고 싶을 때                          |
| **보안 설정**               | 방화벽, 필터링 설정 등                                                                                 | 기본 게이트웨이가 공인 IP일 경우 필수                       |

### <br/>

### 체크 사항
| 질문                                        | 설정 필요 여부         |
| ----------------------------------------- | ---------------- |
| 기본 게이트웨이가 하나 있고, 연결된 인터페이스에 IP가 자동 감지되나?  | ❌ 필요 없음          |
| 기본 게이트웨이가 없거나, 여러 개인데 잘못된 인터페이스 IP가 선택되나? | ✅ IP 직접 지정 필요    |
| 제어 플레인 노드에서 사용하는 IP가 바뀔 예정인가?             | ✅ 인증서 재발급 필요     |
| kubelet이 잘못된 IP를 리포트하거나 등록하나?             | ✅ `--node-ip` 필요 |

### <br/><br/>

## swap 비활성화
### 메모리 스왑이 켜져 있으면 스케줄링 정확성이 떨어진다.
| 항목            | 의미                                  |
| ------------- | ----------------------------------- |
| **RAM (메모리)** | 빠른 성능, 프로세스가 실제로 실행되는 곳             |
| **Swap (스왑)** | RAM이 부족할 때 디스크 공간을 임시 메모리처럼 사용하는 영역 |
| 속도            | RAM ≫≫≫ Swap (디스크 I/O는 수십\~수백 배 느림) |
#### <br/>

### Kubernetes는 Pod에게 메모리를 정확하게 할당하고, 그 자원 약속을 기반으로 **스케줄링(어느 노드에 파드를 배치할지)**을 결정한다.
### 그런데 스왑이 켜져 있으면 생기는 문제가 있다.
| 문제                                 | 설명                                                    |
| ---------------------------------- | ----------------------------------------------------- |
| 🔄 **실제 사용량과 다름**                  | kubelet은 메모리를 1GB 요청했다고 알고 있지만, 그 중 일부가 swap으로 밀려나 있음 |
| 🐢 **불규칙한 성능**                     | 스왑에 밀린 프로세스는 느려짐 → 서비스 지연 발생                          |
| ❌ **OOM(Out of Memory) Kill이 지연됨** | 실제 메모리 부족 상황이 swap 때문에 감지되지 않음                        |
| 📉 **스케줄러 예측력 저하**                 | Pod 배치 결정이 잘못되어 노드에 과부하 발생 가능                         |

### <br/>

### 아래와 같이 스왑을 비활성화한다.
### 컨트롤 플레인, 워커 노드 모두에 설정해야 하므로 ansible 등으로 설정한다.
```
sudo swapoff -a
# /etc/fstab에서 swap 항목 주석 처리
vi /etc/fstab
```
#### <br/>

### free -h로 메모리를 확인했을 때 swap 항목이 0이 되었는지 확인한다.
#### ![image](https://github.com/user-attachments/assets/ef8f5951-d84f-4554-b03d-5b9ea4797a95)
### <br/>

### ansible playbook은 아래를 참고한다.
### [add_user_docker_group.yml](https://github.com/Shin-jongwhan/IaC_infrastructure_as_code/blob/main/ansible/playbook/disable_swap_memory.yml)
### <br/><br/>

## container runtime 구성
### 나는 docker를 사용하고 있기 때문에 적절한 runtime을 구성해야 한다.
### Dockershim 은 kubernetes v1.24 이상부터 제거되었기 때문에 docker + cri-dockerd 로 구성하고자 한다. 자세한 내용은 아래 참고.
#### container runtime은 생각보다 내용이 훨씬 방대하다. 여러가지를 고려해보고 docker가 아닌 다른 걸로 옮길까 고민했는데, 나는 docker를 사용해도 무방하다는 결론을 내렸다. 
#### 보안적인 문제는 결국 어느 것에서든 똑같이 일어나고, container image 관리, 권한 관리는 별도로 운영하여 security 관련 compliance를 달성하는 게 맞다고 본다.
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/container_runtime
### 공식 문서도 참고하자.
#### https://kubernetes.io/docs/setup/production-environment/container-runtimes/
### <br/>

### cri-dockerd 설치
```
target_dir="/data/software"
sudo apt-get update
sudo apt-get install -y git golang-go make
cd $target_dir && git clone https://github.com/Mirantis/cri-dockerd.git
cd $target_dir/cri-dockerd && make cri-dockerd
cp $target_dir/cri-dockerd/cri-dockerd /usr/local/bin/cri-dockerd
chmod +x /usr/local/bin/cri-dockerd
```
### <br/>

### cri-dockerd socket 만들기
#### Kubernetes가 container runtime과 통신할 때 필요한 소켓 파일을 만든다.
#### 소켓 파일 위치는 /var/run/cri-dockerd.sock 이다.
#### /etc/systemd/system/cri-docker.socket
```
[Unit]
Description=CRI Dockerd Socket for Kubernetes
PartOf=cri-docker.service

[Socket]
ListenStream=/var/run/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
```
#### <br/>

#### /etc/systemd/system/cri-docker.service
```
[Unit]
Description=CRI Dockerd Service
After=network.target docker.service
Requires=docker.service cri-docker.socket

[Service]
ExecStart=/usr/local/bin/cri-dockerd --container-runtime-endpoint fd://
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
```
#### <br/>

### cri-dockerd 서비스 띄워서 소켓 파일 생성하기
#### 아래 명령어로 서비스를 띄우면 /var/run/cri-dockerd.sock이 생성될 것이다.
#### 서비스는 계속 실행된 상태여야 한다.
#### 이제 이걸로 kubeadm init config에 등록하면 된다.
```
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable --now cri-docker.socket
sudo systemctl start cri-docker.service

# 확인
sudo systemctl status cri-docker.socket
sudo systemctl status cri-docker.service

```
### <br/><br/>

## kubeadm config, init
### 컨트롤 플레인을 띄우기 위한 작업이다.
### init config 파일 생성
```
kubeadm config print init-defaults > kubeadm-init.yaml
cp kubeadm-init.yaml kubeadm.yaml
```
### 아래와 같이 생성된다.
#### [kubeadm-init_1.33.0.yaml](https://github.com/Shin-jongwhan/kubernetes/blob/main/installation/kubeadm/kubeadm-init_1.33.0.yaml)
### <br/>

### 아래를 수정해준다.
- IP : private IP를 사용해도 되고, 공인 IP를 사용해도 되는데 보통은 private IP를 사용한다.
- hostname : null로 그냥 둬도 되긴 한데, 명시해주는 게 좋다.
- criSocket : 나는 docker로 써서 kubernetes에서 인식할 수 있는 URI 형식으로 써준다.
- criSocket : 위에서 만든 cri-dockerd 소켓 위치
- etcd : etcd 데이터 저장 위치
```
localAPIEndpoint:
  advertiseAddress: [IP]
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/cri-dockerd.sock
  imagePullPolicy: IfNotPresent
  imagePullSerial: true
  name: [hostname]
  taints: null

...

etcd:
  local:
    dataDir: /data/kubernetes/etcd
```
### <br/>

### kubeadm init 
#### Kubernetes 클러스터의 첫 번째 마스터(컨트롤 플레인) 노드를 초기화하는 명령어이다.
```
sudo kubeadm init --config kubeadm.yaml
```
#### <br/>

### kubeadm init 명령어가 하는 일
#### kubeadm init은 다음 작업을 자동으로 수행한다.
- ✅ CA 인증서 및 TLS 인증서 생성
- ✅ API Server, Controller Manager, Scheduler, etcd 등 핵심 컴포넌트 설정
- ✅ /etc/kubernetes/ 디렉토리 생성 및 구성 (admin.conf, pki/, etc)
- ✅ kubelet 설정 및 시작
- ✅ kube-proxy 및 CoreDNS 설정을 위한 기본 매니페스트 생성
- ✅ kubeadm join에 사용할 토큰 출력
#### 결과적으로, 이 명령어를 실행하면 노드는 클러스터의 제어 센터(마스터 노드) 가 된다.
#### 다른 워커 노드들은 kubeadm join 명령으로 이 마스터에 연결하게 된다.
### <br/>

### 만약 config가 수정이 되서 다시 실행하고자 한다면 아래 명령어로 종료시킨다. 
```
sudo kubeadm reset -f --cri-socket unix:///var/run/cri-dockerd.sock
# 그리고 config 수정 완료되면 다시 시작
sudo kubeadm init --config kubeadm.yaml
```
#### ![image](https://github.com/user-attachments/assets/5e438386-02de-4171-b001-3cc8f0dcee0f)
#### <br/>

### cubectl로 kube-system 확인
```
# 없으면 만들기
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# kube-system 확인
kubectl get pods -n kube-system
```
### <br/>

### worker node가 join 할 때 사용할 token이랑 cert-hash 값 출력은 아래 명령어로 확인한다. 이걸 기억해놔야 worker node를 설정할 수 있다.
```
sudo kubeadm token create --print-join-command
```
### <br/>

### kube-controller-manager.yaml 수정
#### * kubeadm init 할 때 자동으로 설정하려면 좀 더 아래에 'kube-controller-manager.yaml, etcd.yaml 자동 설정 방법' 참고
#### 로컬 말고 kubernetes 클러스터 각 node에서 통신할 수 있게 수정해줘야 한다.
```
sudo vi /etc/kubernetes/manifests/kube-controller-manager.yaml
```
#### <br>

### 아래와 같이 수정하자.
```
# --port=0 있으면 제거

# --bind-address=127.0.0.1을 수정
--bind-address=0.0.0.0
```
#### <br/>

### 10257 포트를 사용하는데, 조금만 기다리면 netstat에서 listen을 확인할 수 있다.
```
sudo netstat -tulnp | grep 10257
```
#### <img width="837" height="38" alt="image" src="https://github.com/user-attachments/assets/b4b54efa-51a3-4290-852a-b9232237cd93" />
### <br/>

### etcd.yaml
#### * kubeadm init 할 때 자동으로 설정하려면 좀 더 아래에 'kube-controller-manager.yaml, etcd.yaml 자동 설정 방법' 참고
#### 이것도 마찬가지로 다른 node에서 통신할 수 있게 수정해줘야 한다.
```
sudo vi /etc/kubernetes/manifests/etcd.yaml
```
#### <br/>

### 다음을 수정한다.
```
# --listen-metrics-urls=http://127.0.0.1:2381로 되어 있는 걸 아래와 같이 수정
--listen-metrics-urls=http://0.0.0.0:2381
```
#### <br/>

### listen 확인
```
sudo netstat -tulnp | grep 2381
```
#### <img width="753" height="35" alt="image" src="https://github.com/user-attachments/assets/18e6fc17-e1c0-40fd-a3fd-7c4ac6185261" />
### <br/>

### kube-scheduler.yaml 수정
#### * kubeadm init 할 때 자동으로 설정하려면 좀 더 아래에 'kube-controller-manager.yaml, etcd.yaml 자동 설정 방법' 참고
#### 이것도 마찬가지로 다른 node에서 통신할 수 있게 수정해줘야 한다.
```
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
```
#### <br/>

#### 아래 항목 수정
```
# --bind-address=127.0.0.1을 수정
--bind-address=0.0.0.0
```
#### <br/>

#### listen 확인
```
sudo netstat -tulnp | grep 10259
```
#### <img width="807" height="35" alt="image" src="https://github.com/user-attachments/assets/e36bd59b-64ed-449a-8e7b-ec6ad64cb89b" />
### <br/>

### kube-controller-manager.yaml, etcd.yaml, kube-scheduler.yaml 자동 설정 방법
### kube-controller-manager.yaml, etcd.yaml을 kubeadm init할 때 config로 설정하려면 이렇게 하면 된다. 
### 나는 이미 kubeadm init을 하고 후속처리 하느라 위 처럼 그냥 수동으로 했다.
```yaml
controllerManager:
  extraArgs:
    bind-address: "0.0.0.0"
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /data/kubernetes/etcda
    extraArgs:
      listen-metrics-urls: "http://0.0.0.0:2381"
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
```
### <br/>

### kube-proxy - configmap 수정
#### 이건 수동으로 해야 한다.
```
kubectl -n kube-system edit configmap kube-proxy
```
#### <br/>

#### 아래 항목을 찾아 수정한다.
```
metricsBindAddress: "0.0.0.0:10249"
```
#### <br/>

#### 재적용
```
kubectl -n kube-system delete pod -l k8s-app=kube-proxy
```
#### <br/>

#### 확인
```
sudo netstat -tulnp | grep 10249
```
#### <img width="799" height="34" alt="image" src="https://github.com/user-attachments/assets/146f128d-344c-453a-b6ff-74b214397276" />

### <br/><br/>

## CNI (Container Network Interface)
### CNI에 대해서는 아래를 참고하자. 나는 여기서 calico를 사용해볼 것이다.
### CNI를 구성해야 pod 간 통신, 인식이 가능해진다.
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/CNI
### 아래 보면 coredns 두 개가 Pending 상태이다. 
#### ![image](https://github.com/user-attachments/assets/7400abda-7171-4648-afb7-4a95b0069922)
### <br/>

### calico 설치
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```
### <br/>

### 설치 후 다시 확인해보면 이렇게 바뀐다. 
```
kubectl get pods -n kube-system
```
#### ![image](https://github.com/user-attachments/assets/a80dc382-4ec7-4de2-975a-cf5b396cb450)
#### ![image](https://github.com/user-attachments/assets/0925a6d8-1d9b-43e8-a2be-0d7600094a50)
#### <br/>

### 최종적으로 Running이 되는 걸 확인한다.
#### ![image](https://github.com/user-attachments/assets/91b23a58-1df1-4164-b2cf-eae4abd4d348)
### <br/><br/>


