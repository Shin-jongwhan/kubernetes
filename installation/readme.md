### 250630
# install kubernetes
### kubectl을 local에 설치하고 나머지는 container 환경에서 운영하는 것이 좋다고 공식 docs에 나와있다.
#### https://kubernetes.io/docs/setup/
#### ![image](https://github.com/user-attachments/assets/075aae93-576d-4b0d-a468-b302f6fc607f)
### <br/>

### 여기서 kubernetes가 추구하는 철학이 드러난다.
#### kubernets의 로고는 조타(steering 또는 helm)로 그려져 있다. 그리고 그것을 조타가 있는 곳은 배(ship)이다.
#### ship을 하나 구성하면, 운항을 할 때 필요한 것들은 배 안에 container들을 실을 수 있다.
#### 배를 하나 만들고, container를 운영하는 것을 나타내는 것에 대해 비유적으로 아주 잘 설명해준다.
### <br/><br/>

## Download Kubernetes
#### https://kubernetes.io/releases/download/
### kubectl을 local에 설치
#### https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
### 나는 binary로 설치했다.
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
