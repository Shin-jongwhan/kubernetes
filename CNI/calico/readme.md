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
### <br/>

### Calico의 기본 동작 설정 확인
```
calicoctl get felixconfiguration default -o yaml
```
#### <br/>

### 조회 결과
#### defaultEndpointToHostAction: Accept
#### 이 항목이 설정되어 있지 않으면 Calico는 기본값으로 Drop을 적용할 수도 있다.
#### (버전에 따라 기본값은 Drop, Accept, 또는 설정되지 않음 → Drop 처리)
#### 외부 접속을 허용하고 싶다면 defaultEndpointToHostAction: Accept 추가가 필요하다.
```yaml
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  creationTimestamp: "2025-07-02T07:39:55Z"
  name: default
  resourceVersion: "7221"
  uid: 22b43263-b847-4326-9081-feccf6a9d09c
spec:
  bpfConnectTimeLoadBalancing: TCP
  bpfHostNetworkedNATWithoutCTLB: Enabled
  bpfLogLevel: ""
  floatingIPs: Disabled
  logSeverityScreen: Info
  reportingInterval: 0s
```
### <br/>

### 아래 명령어로 적용 후 다시 조회해보자.
```
calicoctl patch felixconfiguration default \
  --patch='{"spec": {"defaultEndpointToHostAction": "Accept"}}'

calicoctl get felixconfiguration default -o yaml
```
#### <br/>

### 조회 결과
```yaml
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  creationTimestamp: "2025-07-02T07:39:55Z"
  name: default
  resourceVersion: "914180"
  uid: 22b43263-b847-4326-9081-feccf6a9d09c
spec:
  bpfConnectTimeLoadBalancing: TCP
  bpfHostNetworkedNATWithoutCTLB: Enabled
  bpfLogLevel: ""
  defaultEndpointToHostAction: Accept
  floatingIPs: Disabled
  logSeverityScreen: Info
  reportingInterval: 0s
```
### <br/>

## IPpool
### IPPool이란?
### Calico에서 Pod에 할당할 수 있는 'IP 주소 범위'를 정의한 리소스
### <br/>

### 왜 중요한가?
### IPPool에는 단순한 IP 대역 설정 외에도 다음과 같은 중요한 네트워크 동작 제어 옵션이 포함된다.
| 필드                       | 설명                       |
| ------------------------ | ------------------------ |
| `cidr`                   | Pod에 할당될 IP 주소 대역        |
| `natOutgoing`            | Pod가 외부로 나갈 때 SNAT 적용 여부 |
| `ipipMode` / `vxlanMode` | 노드 간 통신 시 터널링 방식 설정      |
| `disabled`               | 사용 여부 (false면 사용됨)       |
### <br/>

### ippool 조회
```
# 전체 조회
calicoctl get ippool -o wide
# 설정 조회
calicoctl get ippool -o yaml
```
#### <br/>

### 출력 결과
```
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  cidr: 192.168.0.0/16           # Pod에 할당될 IP 대역
  blockSize: 26                  # IP 블록당 64개 IP
  ipipMode: Always               # 노드 간 통신은 IP-in-IP 터널 사용
  vxlanMode: Never               # VXLAN은 사용하지 않음
  natOutgoing: true              # 외부 통신 시 SNAT 적용 (노드 IP로 나감)
  nodeSelector: all()           # 모든 노드에 이 풀 적용
  allowedUses:
    - Workload
    - Tunnel
```
### <br/>

### 아래 설정은 egress (외부로 나가는 네트워크)에 문제가 될 수 있다.
```
natOutgoing: true
```
#### 이 설정 때문에
- Pod가 내부망으로 나가는 요청도 SNAT 처리됨
- 즉, Pod의 IP 대신 노드의 IP로 요청이 나감
- 내부망 서버는 Pod의 진짜 IP를 모르기 때문에 응답을 줄 수 없음
  - → SSH timeout 발생
### <br/>

### 다음을 바꿔야 한다.
#### * 굳이 새로 생성 안 하고 default 로 있는 ippool에서 바꿔도 된다.
- natOutgoing: true
- CIDR은 겹치지 않도록 새 범위로 설정 (예: 192.168.100.0/24). 만약 CIDR block 이 겹치면 에러난다.
#### non-nat-pool.yaml
```yaml
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: no-nat-pool
spec:
  cidr: 192.168.100.0/24
  natOutgoing: true
  ipipMode: Always
  vxlanMode: Never
  nodeSelector: all()
```
### <br/>

### yaml을 적용한다.
```
calicoctl apply -f no-nat-pool.yaml
```
### <br/>

### 그런데 아직 새롭게 적용한 ippool이 default와 우선 순위가 밀려서 적용이 안 될 것이다.
```
calicoctl get ippool -o wide
```
### 아래는 원래 false로 되어 있다. 이걸 true로 만들어야 한다.
#### ![image](https://github.com/user-attachments/assets/5371777a-5b31-424b-95a0-83c75debdaee)
### <br/>

### yaml을 하나 만들어서 disabled로 만들자.
#### disable-default-pool.yaml
```yaml
# 기존 default calico ippool을 비활성화할 때 사용한다.
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  cidr: 192.168.0.0/16
  natOutgoing: true
  ipipMode: Always
  vxlanMode: Never
  nodeSelector: all()
  disabled: true
```
#### <br/>

### yaml 적용 후 다시 확인하면 disabled가 true로 바뀌어있을 것이다.
```
calicoctl apply -f disable-default-pool.yaml
```
### <br/>

### calico 새로운 설정을 적용했더라도, 기존에 실행된 pod는 여전히 다른 IP 대역대를 가지고 있다. 그래서 재실행해줘야 한다.
```
# pod 삭제
kubectl delete pod <pod-name> -n <namespace>
# pod 실행 (yaml로 실행)
kubectl apply -f pod.yaml
# pod 조회
kubectl get pod <pod-name> -o wide -n <namespace>
```
### <br/>

### 이렇게 IP 대역대가 바뀌어있을 것이다.
#### ![image](https://github.com/user-attachments/assets/1eb4c8f8-319f-4c88-9139-a7b15c0bff29)
