### 250710
# namespace
### 또는 리소스를 구분하는 '폴더' 또는 '환경' 이름
### 하나의 리소스 그룹이라고 생각하면 편하다.
### <br/>

### 네임스페이스 안에 포함될 수 있는 주요 리소스
| 리소스 종류                                               | 설명                         |
| ---------------------------------------------------- | -------------------------- |
| 🟢 **Pod**                                           | 컨테이너 실행 단위 (앱, 서비스 등)      |
| 🔵 **Service**                                       | Pod를 외부 또는 내부에서 접근 가능하게 해줌 |
| 🟣 **Deployment** / **ReplicaSet** / **StatefulSet** | Pod의 배포 및 관리 담당            |
| 🔐 **Secret**                                        | 비밀번호, 인증서 등 민감한 정보 저장      |
| 📦 **ConfigMap**                                     | 환경 설정 값 (예: 설정 파일) 저장      |
| 🔀 **Ingress**                                       | 외부 트래픽을 내부 서비스(Pod)로 라우팅   |
| 💾 **PersistentVolumeClaim (PVC)**                   | 저장 공간 요청 리소스 (Pod에서 마운트)   |
| 🧠 **Role**, **RoleBinding**                         | 네임스페이스 내부 권한 관리            |
| 📜 **ServiceAccount**                                | Pod가 API 서버에 접근할 때 사용하는 계정 |
| 🔍 **Job**, **CronJob**                              | 일회성 작업 또는 주기적 작업 실행 리소스    |

### <br/>

### 구조로 나타내면 다음과 같다.
```
📁 namespace/
├── 🐳 pods/
├── 🔀 services/
├── 📦 configmaps/
├── 🔐 secrets/
├── 📜 serviceaccounts/
├── 🛠 deployments/
└── 🔍 jobs/
```
### <br/>

### 네임스페이스 범위를 벗어나는 리소스 (클러스터 전체 대상)
| 리소스                                     | 설명                             |
| --------------------------------------- | ------------------------------ |
| **Node**                                | 클러스터의 물리/가상 서버, 네임스페이스에 속하지 않음 |
| **PersistentVolume (PV)**               | 실제 물리 볼륨, 클러스터 전체에서 사용 가능      |
| **Namespace**                           | 자체가 클러스터 리소스임                  |
| **ClusterRole**, **ClusterRoleBinding** | 전체 클러스터 범위의 권한 설정              |
| **CustomResourceDefinition (CRD)**      | 사용자 정의 리소스 정의                  |

### <br/>

### 유용한 명령어
#### 🔸 특정 네임스페이스 안 리소스 전체 보기
```
kubectl get all -n <namespace>
```
#### <br/>

#### 🔸 모든 네임스페이스 포함해서 보기
```
kubectl get all -A
```

