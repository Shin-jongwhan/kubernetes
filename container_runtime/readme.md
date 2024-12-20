### 241220
# container runtime
### <br/><br/><br/>

## runtime이란?
### runtime은 프로그램이 실행 중인 상태나 그 실행 중인 환경을 의미한다.
### 그리고 runtime에서는 그 환경을 관리해주는 역할을 한다. 
### runtime이라는 것은 container 뿐만 아니라 모든 프로그램에 대해 적용되고, 프로그래밍 언어에서도 그 개념이 적용된다.
### <br/>

### 런타임이 처리하는 작업은 다음과 같다.
- 메모리 관리
  - 변수나 객체를 동적으로 생성하고 해제.
- 에러 처리
  - 런타임 에러(예: NullPointerException) 감지.
- 입출력 처리
  - 사용자 입력, 파일 읽기/쓰기 등.
- 프로세스 관리
  - 실행 흐름, 스레드 관리.
### <br/>

### 프로그래밍 언어에서는 C에서는 glibc, JAVA에서는 JRE (Java Runtime Environment)과 JVM (Java Virtual Machine), python에서는 cpython이 있다.
### 가비지 컬렉터, 동적 타이핑(python과 같이 변수 타입을 지정하지 않아도 동적으로 자동으로 정해주는 것), cpu와 메모리 관리, 모듈 로딩 등을 기능을 한다.
### JVM의 -Xmx 옵션으로 힙 메모리 크기를 설정하는 건 런타임을 실행 환경에 대한 옵션이다.
### <br/><br/>

---

## container runtime
### container runtime이란 컨테이너를 관리해주는 runtime이라고 보면 된다.
### containerd, CRI-O와 같은 것들이 있다.
### <br/>

### 주요 기능
- **컨테이너 이미지 실행**: Docker 이미지나 OCI(Open Container Initiative) 표준 이미지를 기반으로 컨테이너를 실행.
- **리소스 관리** : CPU, 메모리 등 시스템 리소스를 컨테이너 간에 효율적으로 분배.
- **네트워크 연결** : 컨테이너 간 통신과 외부 네트워크 연결을 설정.
- **파일시스템 관리** : 컨테이너의 파일시스템을 생성하고 필요한 데이터를 마운트.
- **컨테이너 라이프사이클 관리** : 시작, 정지, 재시작, 종료 등의 작업 수행.
### <br/><br/>

---

## containerd
### 1) Containerd는 Docker의 핵심 컨테이너 관리 기능을 독립 실행형 런타임으로 분리한 프로젝트
### **CNCF(Cloud Native Computing Foundation)**의 공식 프로젝트로 관리되고 있다.
### <br/>

### 2) 특징
- 심플한 설계 : 컨테이너 실행, 이미지 관리, 네트워크, 스토리지 등 핵심 기능만 담당.
- OCI(Open Container Initiative) 지원 : 컨테이너 이미지와 런타임의 표준을 준수.
- Docker 통합 : Docker는 내부적으로 Containerd를 사용하여 컨테이너를 실행.
### <br/>

### 3) 구조
### Containerd는 다음 구성 요소로 이루어져 있다.
- GRPC API : CRI를 통해 쿠버네티스와 통신.
- Snapshotters : 컨테이너 파일시스템 관리.
- Content Store : 컨테이너 이미지 저장 및 배포.
- Runtime : 컨테이너 실행(기본적으로 runc 사용).
### <br/><br/>

---

## CRI(Container Runtime Interface)
### CRI는 쿠버네티스와 컨테이너 런타임 간의 표준 인터페이스이다.
### 쿠버네티스는 직접 컨테이너 런타임(Docker 등)과 통신하지 않고, CRI를 통해 컨테이너 런타임과 상호작용한다.
### CRI를 사용하면 쿠버네티스는 특정 컨테이너 런타임에 종속되지 않으며, 다양한 런타임(Containerd, CRI-O 등)을 지원할 수 있다.
### containerd와 연결해서 쿠버네티스에서 container를 관리할 수 있게 하는 것이다. 
### <br/><br/><br/>

---

## CRI-O
### CRI-O는 레드햇이 개발한 쿠버네티스 전용 컨테이너 런타임이다. 쿠버네티스에 최적화된 container runtime. docker보다 경량화되어 있다.
### Docker를 대체하기 위해 만들어졌으며, CRI를 통해 쿠버네티스와 직접 통신한다. 
### <br/>

### docker는 그 자체적으로 관리할 수 있도록 사실 굉장히 많은 기능을 가지고 있다. 그리고 docker compose, docker swarm과 같이 다른 기능들도 제공을 한다. 
### 이들도 모두 container를 집합적으로 관리하는 도구이며 orchastration tool이다.
### 그런데 왜 쿠버네티스를 쓰냐 ! 그건... 기능이 강력하기 때문이 아닐까 한다. 
##### 뭐... 관리하기 위한 코드 개발 좀 하고 docker compose, docker swarm 이정도만 써도 다 되긴 하지...
### <br/>

### 1) 특징
- 가벼움 : 쿠버네티스 실행에 필요한 기능만 제공하며, 불필요한 도구를 포함하지 않음.
- OCI 호환성 : 컨테이너 이미지와 런타임에서 Open Container Initiative 표준을 준수.
- 레드햇 기반 시스템과의 최적화 : RHEL, OpenShift와 긴밀히 연동.
### <br/>

### 1) 구조
### CRI-O는 쿠버네티스와 함께 동작하며 다음 구성 요소로 이루어져 있다.
- CRI API : 쿠버네티스와의 통신을 처리.
- Runc : 컨테이너 실행에 사용되는 기본 런타임.
- Image Management : 컨테이너 이미지를 다운로드 및 실행.
### <br/><br/><br/>


## docker를 설치하면 쿠버네티스와 연동이 가능한 이유
### docker runtime은 containerd인데, 이 runtime 구조가 OCI 표준으로 만들어졌고, CRI로 쿠버네티스와 공유할 수 있기 때문에 가능한 것이다.
##### 아래 이미지 출처를 모르겠다.
#### ![image](https://github.com/user-attachments/assets/3dd07955-02cb-48f8-a7bb-884604840925)

