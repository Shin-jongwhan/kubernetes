### 250701
# CNI (Container Network Interface)
### Kubernetes에서 Pod 간 네트워크를 구성하기 위한 플러그인 표준 인터페이스.
### 즉, 각 Pod가 네트워크에 참여하고 서로 통신할 수 있도록 도와주는 구성 요소이다.
### <br/>

### CNI가 없으면 생기는 문제
- kubeadm init 이후 Pod를 생성해도 Pod 간 통신이 불가능
- kubectl get pods -A에서 coredns가 Pending 상태로 계속 남음
- 노드가 NotReady 상태로 뜰 수 있음
### <br/>

### CNI가 하는 일
- Pod에 IP 할당 (Pod-to-Pod 통신 가능하게)
- Pod와 외부 네트워크 간 통신 구성
- Kubernetes 서비스(ClusterIP, NodePort, LoadBalancer) 구현 기반
- 네트워크 정책(NetworkPolicy) 적용 가능하게 함 (일부 CNI만 지원)
### <br/>

### 요약
| 질문           | 답변                                               |
| ------------ | ------------------------------------------------ |
| CNI가 뭐야?     | Kubernetes Pod들이 네트워크에서 통신할 수 있게 해주는 네트워크 플러그인   |
| 왜 필요해?       | CNI 없이는 Pod 간 통신 불가 & 클러스터 작동 불완전                |
| 어떤 걸 설치해야 해? | Calico, Flannel, Cilium 중 하나 선택 (보통 Calico 많이 씀) |
### <br/><br/>

## 대표적인 CNI 플러그인 종류
### 1. **Calico**

* ✅ **특징**

  * 빠르고 확장성 뛰어남
  * 네트워크 정책(NetworkPolicy) 지원
  * 실무에서 가장 많이 사용됨
* 🔧 **설치 방법**

  ```bash
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
  ```
* ⚙️ **동작 방식 / 구조 설명**

  * L3 기반 라우팅 방식
  * 각 노드에서 BGP 또는 IP-in-IP를 통해 Pod 간 통신
  * iptables를 통한 정책 제어
  * etcd 또는 Kubernetes API를 데이터 저장소로 사용

#### <br/> 

### 2. **Flannel**

* ✅ **특징**

  * 가장 단순하고 가벼움
  * 네트워크 정책 미지원
  * 테스트나 소규모 환경에 적합
* 🔧 **설치 방법**

  ```bash
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  ```
* ⚙️ **동작 방식 / 구조 설명**

  * L2 오버레이 네트워크
  * VXLAN, host-gw, IP-in-IP 등의 백엔드를 사용해 Pod 간 통신
  * Pod 네트워크를 오버레이로 연결

#### <br/> 

### 3. **Cilium**

* ✅ **특징**

  * 고성능, 차세대 네트워킹 솔루션
  * eBPF 기반으로 커널 레벨에서 동작
  * L3\~L7 네트워크 정책까지 지원
* 🔧 **설치 방법**

  ```bash
  kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.15.3/install/kubernetes/quick-install.yaml
  ```
* ⚙️ **동작 방식 / 구조 설명**

  * 커널의 eBPF 기능을 사용하여 트래픽을 제어 (iptables 거의 사용 안 함)
  * HTTP, gRPC 등 애플리케이션 계층까지 정책 제어 가능
  * 고성능, 저지연 통신에 최적화

#### <br/> 

### 4. **Weave Net**

* ✅ **특징**

  * 설치 간편, 자동 IP 할당
  * 소규모 또는 개발 환경에 적합
  * 자체 암호화 지원
* 🔧 **설치 방법**

  ```bash
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
  ```
* ⚙️ **동작 방식 / 구조 설명**

  * 자체 오버레이 네트워크 프로토콜 사용
  * Weave DNS를 포함해 이름 기반 Pod 간 통신 가능
  * 노드 간 직접 연결 (암호화 가능)

#### <br/> 

### 5. **Canal**

* ✅ **특징**

  * Calico와 Flannel의 조합형
  * Flannel의 오버레이 + Calico의 정책 기능
  * 네트워크 정책이 필요한 경량 환경에 적합
* 🔧 **설치 방법**

  ```bash
  kubectl apply -f https://docs.projectcalico.org/manifests/canal.yaml
  ```
* ⚙️ **동작 방식 / 구조 설명**

  * Flannel로 Pod 간 오버레이 통신 구성
  * Calico의 iptables 기반 정책 제어 적용
  * etcd 없이 Kubernetes API만으로 동작 가능

