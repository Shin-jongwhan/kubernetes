### 250710
# Calico
### calico 설치 관련은 installation 에 정리하였다.
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/installation#cni-container-network-interface
### <br/>

### calico 관련해서 명령어로 제어하려면 calicoctl을 설치해야 한다.
#### https://docs.tigera.io/calico/latest/operations/calicoctl/install
### 버전에 맞게 설치한다. 
```
curl -L -o calicoctl https://github.com/projectcalico/calico/releases/download/v3.27.0/calicoctl-linux-amd64
chmod +x calicoctl
```
#### <br/>

### 그 다음 환경변수에 등록하여 사용한다.
```bash
alias calicoctl='/data/software/calicoctl'
```
### <br/>

### globalnetworkpolicy 조회
```
calicoctl get globalnetworkpolicy
```
