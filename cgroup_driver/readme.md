### 250630
# cgroup driver (control group driver)
#### https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers
### cgroup driver는 Kubernetes에서 리눅스의 리소스 cgroup이란?제어 기능(cgroups) 을 어떻게 사용할지 결정하는 중요한 설정
### Kubernetes 클러스터의 안정성과 성능에 직접 영향을 주는 요소
### <br/><br/>

## cgroup
### Control Group (cgroup) 은 리눅스 커널 기능
### CPU, 메모리, 블록 I/O, 네트워크 등 시스템 자원을 프로세스 단위로 제한하고 관리할 수 있게 해준다.
### <br/><br/>

## cgroup driver
### Kubernetes와 컨테이너 런타임(containerd, Docker 등)이 cgroup을 "어떻게 제어할지" 결정하는 방식
### 이걸 **"driver"**라고 부르는 이유는 시스템이 cgroup을 제어하는 **방법(방식)**이 다르기 때문이다.
### <br/>

### 대표적인 cgroup driver 2가지
| 드라이버           | 설명                          | 사용 위치                          |
| -------------- | --------------------------- | ------------------------------ |
| **`cgroupfs`** | 전통적인 방식. cgroup 디렉토리를 직접 제어 | Docker 기본값이었음 (예전)             |
| **`systemd`**  | systemd가 cgroup을 관리         | 최신 Kubernetes & containerd 기본값 |
### <br/>

### cgroup driver가 불일치할 경우 
| 상황       | 결과                                                |
| -------- | ------------------------------------------------- |
| 드라이버 불일치 | kubelet이 컨테이너 관리 실패, Pod 안 뜸, kubelet crash 발생 가능 |
| 드라이버 일치  | 안정적인 컨테이너 실행, 리소스 제어 정상 작동                        |
### <br/>

### 1.22 버전 이후로는 default가 systemd라고 공식 docs에 나와있다.
#### ![image](https://github.com/user-attachments/assets/73011d64-29d7-40dc-9190-c9f05ae5c543)
### <br/>

## (참고) systemd
### '리눅스에서 시스템과 서비스(데몬)의 부팅과 실행을 관리하는 초기화 시스템(init system)'이다.
### Linux 시스템에서 서비스 실행, 프로세스 관리, 로그 기록, 부팅 순서 등을 총괄하는 init 시스템
### <br/>

### 주요 역할
- 시스템 부팅 초기화 (init)
- 데몬(service) 관리 (예: kubelet, docker, nginx)
- 서비스 자동 시작/중지 설정 (enable, disable)
- 의존성 있는 서비스 간의 실행 순서 관리
- 로그 관리 (journalctl)
### <br/>

### systemd와 systemctl의 관계
| 항목          | 설명                                                |
| ----------- | ------------------------------------------------- |
| `systemd`   | 리눅스의 **init 시스템**이자 **서비스 관리자** (시스템 전체의 백엔드 관리자) |
| `systemctl` | `systemd`를 **제어하고 조작하는 CLI 명령어 도구 (프론트엔드)**       |
### <br/>

### ex)
| 명령어                            | 설명         |
| ------------------------------ | ---------- |
| `systemctl start nginx`        | 서비스 시작     |
| `systemctl stop kubelet`       | 서비스 중지     |
| `systemctl restart containerd` | 재시작        |
| `systemctl enable kubelet`     | 부팅 시 자동 시작 |
| `systemctl status docker`      | 현재 상태 확인   |
| `journalctl -u kubelet`        | 로그 보기      |
