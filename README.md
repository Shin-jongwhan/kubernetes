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
- autoscaling
- load balancing
- health check 및 복
- server cluster 관리 (multi node kubernetes cluster)
- Ingress : proxy server, 로드 밸런싱. HPA와 같이 사용하면 트래픽 처리에 대해 오토스케일링이 된다.
- HPA (horizontal pod autoscaler) : 오토스케일링
- 클라우드 연동
- rolling update : 컨테이너에 포함된 앱이 업데이트되면 점진적으로 최신 버전으로 이관되게 하는 기능
- 스토리지 오케스트레이션 : 로컬 스토리지, 클라우드 스토리지, 네트워크 스토리지 등 다양한 스토리지 솔루션과 연동
- 배포와 롤백 : 문제가 발생할 경우 이전 버전으로 롤백
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
Pod는 수명 주기가 짧고, 삭제되었다가 다시 생성되면 IP가 변경될 수 있다.
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
### <br/>






