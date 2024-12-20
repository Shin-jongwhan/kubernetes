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
- 컨테이너 이미지 실행: Docker 이미지나 OCI(Open Container Initiative) 표준 이미지를 기반으로 컨테이너를 실행.
- 리소스 관리: CPU, 메모리 등 시스템 리소스를 컨테이너 간에 효율적으로 분배.
- 네트워크 연결: 컨테이너 간 통신과 외부 네트워크 연결을 설정.
- 파일시스템 관리: 컨테이너의 파일시스템을 생성하고 필요한 데이터를 마운트.
- 컨테이너 라이프사이클 관리: 시작, 정지, 재시작, 종료 등의 작업 수행.
