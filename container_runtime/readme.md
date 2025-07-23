### 250701
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

### <br/><br/><br/>

## container runtime 
#### https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
### Dockershim 은 kubernetes v1.24 이상에서부터(확인해보니 2020년 근처) 지원하는 container runtime에서 제거되었다.
#### ![image](https://github.com/user-attachments/assets/ac487d07-54d4-436f-be2c-c5ac710a0687)
### <br/>

### 위 페이지에 가면 각 container runtime에 대한 설정 방법이 안내되어 있다.
- containerd
- CRI-O
- Docker Engine (cri-dockerd를 설치하여 사용)
- Mirantis Container Runtime
### <br/><br/>

## 질문
### `질문` : 나는 container image가 docker hub에 올라가 있고, 여기서 image를 관리하고 있다. 그러면 나는 docker와 연동할 수 있는 방법을 찾는게 맞는 것인가?
### 그렇다.
### <br/>

### `질문` : 그러면 여기서 다시 이런 생각이 드는데, 다른 container runtime을 사용하는 사람들은 container image를 어떻게 관리하고 있는 것인가?
### containerd나 CRI-O를 사용하는 사람들은 Docker 없이도 컨테이너 이미지를 잘 관리하고 있다. 
#### Docker가 없어도 container image는 OCI(Open Container Initiative) 표준이기 때문에, containerd, CRI-O도 Docker Hub에 있는 이미지 pull/push/관리 전부 가능하다.
#### <br/>

### containerd 사용자들의 이미지 관리 방식
#### * 아래 테이블에는 없는데 내가 분석에서 사용했었던 singularity 도 이미지 빌드 도구 중 하나이다.
| 작업            | 대체 도구                                  | 설명                           |
| ------------- | -------------------------------------- | ---------------------------- |
| 이미지 빌드        | `nerdctl`, `buildkit`, `img`, `podman` | Docker 없이도 이미지 생성 가능         |
| 이미지 push/pull | `nerdctl push`, `ctr images pull` 등    | Docker Hub나 프라이빗 레지스트리 사용 가능 |
| 로컬 실행         | `nerdctl run`, `ctr run`               | Docker 없이도 컨테이너 실행 가능        |

#### <br/>

###  도구 설명
- nerdctl: Docker CLI와 거의 1:1로 호환되는 containerd용 CLI (가장 인기 있음)
- ctr: containerd 기본 CLI → 기능은 많지만 불편하고 저수준
- buildkit: 고성능 이미지 빌드 엔진 (Docker도 내부에서 사용 중)
- img: rootless 빌드를 위한 도구
- oras: OCI 레지스트리 연동을 위한 도구
### <br/>

### Docker 없이도 이렇게 사용 가능하다.
```
# 이미지 빌드 (Dockerfile 사용 가능)
nerdctl build -t myimage:latest .

# Docker Hub에 push
nerdctl login
nerdctl push myimage:latest

# 실행
nerdctl run -d --name web nginx

```
#### <br/>

### CRI-O 사용자들의 이미지 관리 방식
#### CRI-O는 기본적으로 이미지를 직접 빌드하지 않음 (이미지 실행 전용 런타임)
#### → 빌드/관리에는 Podman을 주로 사용함
| 작업   | 도구             | 설명                        |
| ---- | -------------- | ------------------------- |
| 빌드   | `podman build` | Dockerfile 빌드 가능          |
| push | `podman push`  | Docker Hub 등으로 업로드 가능     |
| 실행   | `podman run`   | rootless/secure한 실행 환경 지원 |

#### <br/>

### podman 특징
- Docker CLI와 거의 호환
- rootless로도 작동 가능 (보안 측면 우수)
- Red Hat, Fedora 계열에서 기본 채택 중
#### <br/>

### 아래 블로그에서 좀 더 내용을 참고해보자.
### podman은 데몬이 없기 때문에 더 가볍다.
#### https://wing-beat.tistory.com/122
#### ![image](https://github.com/user-attachments/assets/38426ef4-b857-48e1-b69d-50fba5c3dd7e)
#### ![image](https://github.com/user-attachments/assets/1e968199-a41d-4453-bf62-6885a7071bd5)

### <br/>

### `질문` : docker를 사용하고 있다면 docker + cri-dockerd를 사용하는 게 적절한가?
### 그렇다.
### 하지만 containerd나 CRI-O를 사용할 수도 있다.
#### <br/>

### containerd / CRI-O를 Docker 대신 써도 되는 이유
| 이유                     | 설명                                                  |
| ---------------------- | --------------------------------------------------- |
| 📦 컨테이너 이미지 포맷         | Docker와 동일한 **OCI 이미지 포맷**을 사용                      |
| 🔄 이미지 호환성             | Docker Hub 이미지도 `containerd`, `CRI-O`에서 그대로 pull 가능 |
| 🎯 목적이 Kubernetes라면    | `containerd`, `CRI-O`가 **Kubernetes에 더 최적화**됨       |
| ✅ 클라우드/운영환경에서 실질적으로 사용 | EKS, GKE, AKS 등은 모두 containerd 사용 중                 |
#### <br/>

### 단, 아래와 같은 것들이 변화가 생긴다.
| 항목        | Docker 사용                   | containerd/CRI-O 사용                    |
| --------- | --------------------------- | -------------------------------------- |
| 이미지 빌드    | `docker build`              | `nerdctl build` / `podman build`       |
| 실행/테스트    | `docker run`, `docker exec` | `nerdctl run` / `podman run`           |
| 컨테이너 관리   | `docker ps`, `docker logs`  | `ctr`, `crictl`, `nerdctl`, `podman` 등 |
| 로컬 이미지 확인 | `docker images`             | `ctr images list`, `nerdctl images` 등  |

### <br/>

### `질문` : podman vs docker
### 뭐든 상관 없지만 docker는 데몬이 떠 있고 데몬이 root user로 실행 중인 건데 일반 사용자도 실행할 수 있다는 게 문제가 된다. 
### 그런데 이 문제 때문에 podman을 사용하는 건 아니고 주된 목적은 **데몬리스 경량화 환경을 제공하기 위함**이다.
### 아래 reddit에 보면 어느 유저가 잘 설명해주었다.
#### https://www.reddit.com/r/kubernetes/comments/10yckjz/podman_vs_docker_in_kubernete/
### gpt 요약
#### ![image](https://github.com/user-attachments/assets/f5a06bac-425e-421a-9bbc-46997b7d6e81)
#### ![image](https://github.com/user-attachments/assets/e28cc572-0bb2-4ef4-bd3f-816e79b66cfa)
### 정리
| 정리 항목                    | 내용                                     |
| ------------------------ | -------------------------------------- |
| Docker 보안 문제             | 데몬이 root인데 일반 사용자도 명령 가능 (docker.sock) |
| Podman/CRI-O 등장 이유       | 보안보단 Kubernetes에 최적화된 구조, 가벼운 런타임 추구   |
| Kubernetes에서 containerd는 | root로 실행되지만 사용자 접근이 제한되어 있어 실질 문제 없음   |
| 루트리스 Kubernetes          | 점차 개발 중, 실험적 기능 제공됨                    |

### <br/>

### `질문` : 그러면 podman이랑 docker 둘 중에 뭘 사용해야 하는 것인가?
| 항목                              | Docker 적합                      | Podman 적합                       |
| ------------------------------- | ------------------------------ | ------------------------------- |
| ✅ **Kubernetes와 연동**            | `cri-dockerd`가 필요함 (공식 지원 중단됨) | CRI-O와 함께 공식적으로 사용됨             |
| 🧱 **단순 개발/테스트**                | 사용 편하고 익숙한 CLI                 | Docker와 유사, rootless 사용 가능      |
| 🐳 **이미지 빌드/관리**                | Docker Hub와의 통합이 자연스러움         | Docker Hub 사용 가능 (다만 약간의 설정 필요) |
| 🔐 **보안 요구**                    | 데몬 기반, 루트 권한 이슈 있음             | 데몬리스, rootless 가능, 보안성 높음       |
| 🧪 **개발자 환경**                   | 익숙함이 장점                        | 보안과 가벼움이 장점                     |
| 🏭 **운영 환경 / 프로덕션**             | ❌ 권장하지 않음                      | ✅ Red Hat, OpenShift 등에서 사용 중   |
| 🔌 **추가 기능 (Compose, Swarm 등)** | 포함됨 (다소 무거움)                   | 미포함, 필요하면 따로 도구 설치              |

#### <br/>

### ❗ 중요 : docker가 아닌 다른 container runtime을 사용하는 게 best practice라는 말은 아니다. 
### 분명히 공식 docs에도 docker engine을 지원하고 있고, 오해하지 말아야 할 것이 containerd, CRI-O 또한 데몬이라는 점이다.
### podman이 데몬으로 실행이 안 되는 것일 뿐이다.
### 공식 docs의 best practice에도 docker는 써져 있고, containerd나 CRI-O를 사용하라고 나와 있지 않다. 
#### https://kubernetes.io/docs/setup/best-practices/node-conformance/
#### ![image](https://github.com/user-attachments/assets/a0c9d615-1e3b-451b-8da5-9b5b995a919d)
### <br/><br/>

## 보안 문제
### 아래 블로그 글에서 아주 자세하게 정리를 잘 해주었다. 
#### https://www.radsecurity.ai/blog/container-runtime
### RAD Security의 해당 글에서는 **어떤 container runtime을 선택하느냐보다**, **런타임 보안 체계를 어떻게 구축하느냐**가 훨씬 더 중요하다는 관점에서 접근하고 있다.
### <br/>

### RAD Security가 이야기하는 핵심 포인트들
1. **컨테이너 이미지 업데이트 및 취약점 스캔**
   - 최신 패치 적용, CI/CD에서 이미지 취약점 탐지 및 자동 업데이트 권장
2. **강력한 격리 메커니즘 활용**
   - 네임스페이스, cgroups, SELinux/AppArmor 등을 통해 격리 강화
3. **최소 권한 원칙(Lowest privilege)**
   - 컨테이너는 가능한 root 없이 실행하고, 커널 권한도 최소로 제한
4. **오케스트레이터 보안 강화**
   - 네트워크 정책, PSP, RBAC 등 Kubernetes 내 보안 정책 적용
5. **정기적인 보안 감사 및 모니터링**
   - 실행 중 이상 징후를 eBPF 기반 툴 등으로 모니터링하고 감사 로깅 사용
6. **런타임 환경의 지속적 패칭 및 업데이트**
   - Docker, containerd, CRI-O 등 컨테이너 런타임도 최신으로 유지
### <br/>

### 어떤 런타임이 "더 낫다"라고 말하지 않음
- 글 자체에서는 Docker, containerd, CRI-O 등 모두 언급하지만,
- **보안 체계를 어떻게 강화할 것인지**가 글의 핵심이며,
- 특정 런타임을 추천하지는 않는다.
### <br/>

### ✅ 판단 기준: “어떤 런타임을 사용하냐” 보다 "어떤 보안 전략을 적용하냐"
### 이런 요소들을 어떻게 구현할 수 있느냐가 **보안 완성도**를 결정한다.
- 이미지 취약점 스캔
- 격리 네임스페이스 및 권한 구성
- 이상 행동 모니터링 (Falco, Tetragon 등)
- Runtime 정기 업데이트 및 감사
### <br/>

### 결론
### **RAD Security의 관점에서는 런타임 선택보다, ‘보안 프로세스와 툴’이 더 중요하다.**
-  ✅ 이미지 스캔, 격리, 권한 제한
-  ✅ 이상 감지와 감사 로깅
-  ✅ 런타임 자체의 최신화
