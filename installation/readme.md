# 작성 중...
### 241219
## install 방법
### 참고
#### https://kubernetes.io/ko/docs/tasks/tools/install-kubectl-linux/
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
apt install -y apt-transport-https ca-certificates curl
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

### kubectl 다운로드
### 버전 호환은 공식 홈페이지에 해당 버전에서 2버전 차이 나는 것만 호환된다고 써져 있음
#### 클러스터의 마이너(minor) 버전 차이 내에 있는 kubectl 버전을 사용해야 한다. 예를 들어, v1.32 클라이언트는 v1.31, v1.32, v1.33의 컨트롤 플레인과 연동될 수 있다. 호환되는 최신 버전의 kubectl을 사용하면 예기치 않은 문제를 피할 수 있다.
### 최신 버전 설치
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
### 특정 버전 설치
```
curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl
```
### <br/>

### kubectl 설치
```
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
### 버전 확인은 다음과 같이 하면 된다.
```
kubectl version --client

# detail
kubectl version --client --output=yaml
```
#### ![image](https://github.com/user-attachments/assets/4f9f090e-e210-4683-9b3a-629ca5d3fa20)

### <br/>

