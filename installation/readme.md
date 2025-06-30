### 250630
# install kubernetes
### kubectl을 local에 설치하고 나머지는 container 환경에서 운영하는 것이 좋다고 공식 docs에 나와있다.
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

### 
