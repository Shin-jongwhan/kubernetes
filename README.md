### 241219
# kubernetes
### k8s라고 줄여서 부르기도 하는데 중간에 8글자라서 k8s라고 부른다고...
### 쿠버네티스는 컨테이너 오케스트레이션 오픈소스 프레임워크(플랫폼)이다.
### 컨테이너들에 대해 자동으로, 그리고 대규모로 관리, 확장, 배포해준다.
### RESTful API 중심으로 사용한다.
#### ![image](https://github.com/user-attachments/assets/ebc8b0b6-946d-46ea-9dc5-fe3cd115af20)
### <br/><br/>

## 잡담
### 컨테이너 개수가 많아지고 여러 서버를 관리하려다보니 힘들어서 고려하고 있다.
### 서비스가 엄청 크지 않기 때문에 쿠버네티스를 적용하기에 애매해서 적용은 안 했는데 작더라도 관리를 위해 적용하면 좋겠다 생각했다.
### <br/><br/><br/>


## 컨테이너 관리, orchastration tool
### 쿠버네티스는 매우 유명하고 유용한 툴이다 !
### 아주 다양한 기능들이 있다.
- load balancing
- server cluster 관리 (multi node kubernetes cluster)
- Ingress : proxy server, 로드 밸런싱. HPA와 같이 사용하면 트래픽 처리에 대해 오토스케일링이 된다.
- HPA (horizontal pod autoscaler) : autoscaling 관리
- 클라우드 연동
- rolling update : 컨테이너에 포함된 앱이 업데이트되면 점진적으로 최신 버전으로 이관되게 하는 기능
- 스토리지 오케스트레이션 : 로컬 스토리지, 클라우드 스토리지, 네트워크 스토리지 등 다양한 스토리지 솔루션과 연동
  - Persistent Volume (PV) : 클러스터 외부에서 데이터 저장을 위한 스토리지
  - Persistent Volume Claim (PVC) : Pod에서 스토리지를 요청하는 방식
- deployment : 배포 관리
  - rollback : 버전에 문제가 있는 경우 롤백 지원
  - ReplicaSet : replica를 stand by하고 복구에 지원
  - rolling update : 업데이트를 안전하게 수행하기 위한 전략. 업데이트 버전으로 점진적으로 이동한다.
  - update : 새로운 버전으로 pod의 컨테이너를 업데이트
- statefulSet : StatefulSet은 상태를 유지해야 하는 애플리케이션을 위한 리소스. 데이터베이스, 캐시 서버와 같은 애플리케이션에서 사용된다. 예를 들어 MySQL, Redis, MongoDB 등...
  - PV와 연동해서 사용한다.
  - statefulSet의 pod는 각각 고유의 DNS 주소를 가진다.
- DaemonSet : 클러스터의 모든 노드에서 Pod를 실행하기 위한 리소스. 노드에 필요한 시스템 작업, 로그 수집, 모니터링 에이전트를 배포하는 데 사용된다.
  - 노드당 하나의 Pod : 각 노드에 하나의 Pod만 실행. 노드가 추가되면 자동으로 새로운 Pod가 생성됨.
  - 자동 배포 및 삭제 : 새로운 노드가 클러스터에 추가되면 해당 노드에서 DaemonSet의 Pod가 자동으로 실행. 노드가 삭제되면 해당 Pod도 자동으로 제거됨.
  - 특정 노드에서만 실행 가능 : nodeSelector, taints 및 tolerations를 사용하여 특정 노드에서만 실행되도록 설정 가능.
  - 사용자 정의 네트워크 설정 : 각 Pod는 노드에 직접 연결되므로 로깅 및 네트워크 트래픽 수집에 유리함.
- secret : 민감한 정보를 암호화하여 저장. API 키, 비밀번호, 인증서 등 저장하는 데에 사용한다.
  ```
    apiVersion: v1
  kind: Secret
  metadata:
    name: example-secret
  type: Opaque
  data:
    username: dXNlcm5hbWU=  # Base64 인코딩
    password: cGFzc3dvcmQ=
  ```
- ConfigMap : 애플리케이션의 구성 데이터를 관리
  ```
    apiVersion: v1
  kind: ConfigMap
  metadata:
    name: example-config
  data:
    key1: value1
    key2: value2
  ```
- cronjob : 리눅스 cron이랑은 다름. 쿠버네티스에 특화된 작업 스케쥴러다. 모니터링, 로깅, 주기적인 실행과 같은 반복 작업에 사용한다.
### <br/><br/><br/>


## 쿠버네티스의 구성 요소
### 1. 클러스터 구성 요소
- Control Plane (제어 평면)
  - API Server : 모든 명령어와 조작을 받는 쿠버네티스의 엔트리 포인트.
  - Scheduler : 워커 노드에 작업을 할당.
  - Controller Manager : 클러스터 상태를 관리.
  - etcd : 클러스터의 상태를 저장하는 키-값 데이터 저장소.
- 노드 컴포넌트 :
  - kubelet : 워커 노드에서 Pod를 관리.
  - kube-proxy : 네트워크 라우팅.
  - 컨테이너 런타임 : Docker, containerd 등.
### <br/>

### 2. 쿠버네티스 객체
- Pod : 컨테이너가 포함된 가장 작은 배포 단위. pod는 ip와 port를 할당받는다. CNI(Container Network Interface) 플러그인을 통해 할당 받는다. 대표적인 플러그인으로 Calico, Flannel, Weave 등이 있다.<br/>
참고로 컨테이너는 pod 내에서 로컬 ip와 포트로 접속되고 따로 쿠버네티스에서 관리하는 ip와 port는 할당 받지는 않는다.<br/>
pod는 service가 연결된 pod를 찾기 위해 ip와 포트 기반으로 endpoint 역할을 한다. 여기서 사용되는 포트는 service가 이용하는 포트이다.<br/>
Pod는 수명 주기가 짧고, 삭제되었다가 다시 생성되면 IP가 변경될 수 있다.<br/>
- Service : Pod에 대한 네트워크 접근을 추상화. service는 쿠버네티스가 관리하는 endpoint가 있어서, 쿠버네티스에서 통신을 할 때에는 endpoint로 pod와 연결된다. <br/>
Service는 Pod의 IP 변경과 관계없이 항상 안정적인 endpoint를 제공한다. 여기서 이용하는 포트는 client가 이용하는 포트이다.
- Deployment : 애플리케이션의 배포와 관리.
- ConfigMap & Secrets : 설정 정보와 민감 정보를 관리.
### <br/>

### 3. 클러스터 관리
- 노드 : 애플리케이션을 실행하는 물리적/가상 서버.
- 마스터 노드 : 클러스터 제어. <br/>
마스터 노드에서도 물론 pod를 운영할 수는 있지만 이는 워커 노드에서 해야 한다. 하지만 소규모 클러스터일 경우(서버가 하나거나...) 마스터와 워커 노드가 같이 운영된다.<br/>
마스터 노드는 다음의 기능을 주요로 실행한다.
  - API Server : 클러스터와 상호작용하는 엔트리 포인트.
  - Scheduler : Pod를 워커 노드에 스케줄링.
  - Controller Manager : 클러스터 상태를 모니터링하고 필요한 작업 수행.
  - etcd : 클러스터 상태를 저장하는 키-값 데이터 저장소.
- 워커 노드 : 컨테이너 실행.
- 스케줄러 : 컨테이너가 실행될 노드를 자동으로 선택.
### <br/><br/>

### container, pod, service의 포함 관계
- 가장 하위에는 container
- 그 다음으로는 pod (1개 이상의 container)
- 그 다음으로는 service (1개 이상의 pod)
### <br/>

### container, pod, worker node, service
### container는 pod에 포함 되어 있다. 그리고 worker node는 이 pod들을 직접적으로 관리하는 주체이다.
### 위 포함 관계에서 service가 여러 pod를 포함하고 있다고 이야기했지만, 이것은 포함 관계일 뿐 service가 pod를 관리한다는 것은 아니다.
### <br/><br/><br/>


## 쿠버네티스 주요 패키지: kubelet, kubeadm, kubectl
### 쿠버네티스는 하나의 프로그램이 아닌, 여러 패키지들의 집합이다. kubelet, kubeadm, kubectl은 쿠버네티스를 운영하기 위한 필수 패키지들이다.
### <br/>

### 1. `kubelet`
### Kubernetes + Let. Let은 하나의 단위를 의미한다.
- **역할**: 각 노드(서버)의 핵심 에이전트로 Pod 실행과 상태를 관리.
- **주요 기능**:
  - 쿠버네티스 API 서버와 통신하여 Pod 사양을 가져오고, 컨테이너를 생성/삭제.
  - 실행 중인 컨테이너의 상태를 모니터링하고 보고.
  - 노드 레벨에서 리소스(CPU, 메모리 등)를 관리.
- **실행 위치**: 모든 노드(마스터 및 워커)에 설치.
- **특징**: 클러스터의 모든 노드에서 항상 실행 중.

---

### 2. `kubeadm`
### Kubernetes + admin.
- **역할**: 쿠버네티스 클러스터를 설치하고 초기화하는 도구.
- **주요 기능**:
  - 클러스터 **마스터 노드 초기화** (`kubeadm init`).
  - 워커 노드 등록 (`kubeadm join`).
  - TLS 인증서 생성 및 배포.
  - 쿠버네티스 기본 구성 요소(API 서버, etcd 등) 설치.
  - 클러스터 업그레이드 및 리셋 기능 제공.
- **실행 위치**: 마스터 노드에서 주로 사용.
- **특징**: 설치 및 초기화 시점에만 실행.

---

### 3. `kubectl`
### Kubernetes + Control
- **역할**: 쿠버네티스 클러스터와 상호작용하는 CLI 도구.
- **주요 기능**:
  - 클러스터 상태 조회:
    ```bash
    kubectl get pods
    ```
  - 리소스 생성, 수정, 삭제:
    ```bash
    kubectl apply -f deployment.yaml
    kubectl delete pod my-pod
    ```
  - 디버깅 및 로그 확인:
    ```bash
    kubectl logs my-pod
    kubectl exec -it my-pod -- bash
    ```
  - 클러스터 구성 정보 관리(`~/.kube/config`).
- **실행 위치**: 로컬 머신 또는 원격에서 실행.
- **특징**: 필요 시 실행하며 API 서버와 통신.

---

### 요약 비교

| 패키지     | 역할                                    | 설치 위치            | 실행 시점            |
|------------|-----------------------------------------|----------------------|----------------------|
| `kubelet`  | 각 노드에서 Pod와 컨테이너 실행 관리     | 모든 노드            | 항상 실행 중         |
| `kubeadm`  | 클러스터 초기화 및 설정 도구            | 마스터 노드          | 초기화 시 실행       |
| `kubectl`  | 클러스터와 상호작용하는 CLI 도구        | 로컬 또는 원격 머신  | 필요 시 실행         |

---

### 쿠버네티스 워크플로 예시

1. **클러스터 초기화**:
   - `kubeadm init`으로 마스터 노드 초기화.
   - `kubeadm join`으로 워커 노드를 클러스터에 추가.

2. **노드 실행**:
   - 각 노드에서 `kubelet`이 실행 중이며 Pod와 컨테이너를 관리.

3. **클러스터 관리**:
   - `kubectl`을 사용하여 클러스터 상태를 확인하거나 리소스를 생성 및 관리.



