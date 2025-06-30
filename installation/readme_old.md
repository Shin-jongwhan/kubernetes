# 미완성
### 250206
## install 방법
### 참고
#### [install-kubectl-linux](https://kubernetes.io/ko/docs/tasks/tools/install-kubectl-linux/)
#### [install-kubeadm](https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#verify-mac-address)
#### [컨테이너 런타임](https://kubernetes.io/ko/docs/setup/production-environment/container-runtimes/)
#### https://jbground.tistory.com/107
### <br/><br/>

### 쿠버네티스를 이용하려면 swap 이용을 꺼야 한다고 한다.
```
swapoff -a

# vi로 열어 swap이라고 써진 줄을 주석 처리(#)
vi /etc/fstab
```
### <br/>

### 필수 패키지 설치
```
apt update
apt install -y apt-transport-https ca-certificates curl gnupg
```
### <br/>

### 공개 사이닝 키 다운로드
```
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```
### <br/>

### 다음을 설치하라고 한다.
#### ![image](https://github.com/user-attachments/assets/d9c87ba2-96c3-49af-9534-9a127e08a449)
### <br/>

### 공식 홈페이지에서 현재 release를 확인한다. 나는 이 중에 최신 버전을 설치할 것이다.
#### https://kubernetes.io/ko/
#### ![image](https://github.com/user-attachments/assets/8a36cf7f-68b7-47cf-8824-c1671dcd7e7c)
### <br/>

### 설치
```
# 공개 사이닝 키 다운로드
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# apt repo 추가
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 설치
sudo apt-get update

# 쿠버네티스 패키지 버전 고정
sudo apt-get install -y kubelet kubeadm kubectl
```
### <br/>

### 그리고 만약 docker가 설치가 안 되어 있다면 설치한다.
### 설치되어 있다면 방화벽 설정을 하고, 필요 없다면 생략한다.
```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
```
### <br/>

### cgroup 확인
### 자세한 것은 공식 홈페이지 내용을 확인한다.
#### [컨테이너 런타임](https://kubernetes.io/ko/docs/setup/production-environment/container-runtimes/)
#### ![image](https://github.com/user-attachments/assets/1f5c52ee-c5a6-430f-ad88-bca93b441929)

### cmd
```
docker info | grep -i cgroup
```
### 다음과 같이 출력되면 설정 상태가 이용해도 괜찮은 상태라고 한다.
#### ![image](https://github.com/user-attachments/assets/b53ac05b-998e-438c-97a1-e0172cace81a)
### <br/>

### 버전 확인
```
kubectl version --client
# detail
kubectl version --client --output=yaml

kubelet --version

kubeadm version
```
#### ![image](https://github.com/user-attachments/assets/b4d62cae-6691-4099-aa19-0d617ceb065b)

### <br/>

### service 실행 및 확인
### service 또는 systemctl 명령어를 이용한다.
```
service kubelet start
service kubelet status
```
#### ![image](https://github.com/user-attachments/assets/6b9820cf-870b-40f4-890c-918b72f8bf35)
### <br/><br/><br/>


## 노드 구성하기(마스터 노드, 워커 노드)
### 먼저 마스터 노드를 구성해야 한다.
```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```
#### kubeadm 옵션 참고
- --config : 초기화에 사용할 구성 파일을 지정
- --token : 클러스터에 대한 액세스를 허용하는 토큰을 초기화
- --pod-network-cidr : 클러스터에 대한 Pod 네트워크 CIDR 범위를 지정
- --apiserver-advertise-address : API 서버가 퍼블릭 엔드포인트에 대해 알릴 IP 주소를 지정
- --apiserver-cert-extra-sans : 마스터 노드 인정스에 추가할 DNS 이름을 지정
- --control-plane-endpoint : 컨트롤 플레인 구성요소가 서로 통신하는데 사용할 엔드포인트를 지정
- --cri-socket : 사용할 CRI의 소켓을 지정
### <br/>

