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
### 이렇게 나오면 현재 아무 rule도 없다는 뜻이다.
#### ![image](https://github.com/user-attachments/assets/bbf1d840-257b-4083-b3f1-deac9c9c3f5a)
### <br/>

### 만약 globalnetworkpolicy에 아무것도 뜨지 않는다면 외부로 통신하는 네트워크 차단하는 rule이 없다는 것이다.
### 클러스터에 GlobalNetworkPolicy가 존재하지 않는다는 것의 의미
- ❌ 기본적으로 모든 egress를 차단하는 글로벌 정책은 없음
- ❌ default-deny, egress-deny, allow-only-some 같은 글로벌 제한 정책 없음
- ✅ 즉, Calico 자체가 의도적으로 모든 외부 트래픽을 차단하고 있진 않음
