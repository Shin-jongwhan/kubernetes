### 250721
# Controller
### kubernetes에서 아주 핵심적인 개념. 클러스터를 자동으로 "원하는 상태"에 맞춰주는 관리자이다.
### 클러스터 전체의 상태를 감시하고 조정하는 역할을 한다.
### pod를 컨트롤해주데, Controller는 Kubernetes의 핵심 구성요소인 Control Plane 안에 포함된다.
### <br/><br/>

## Controller 종류
### 대표적인 Kubernetes Controller 종류
| Controller                | 설명                                | 사용 목적             |
| ------------------------- | --------------------------------- | ----------------- |
| **Deployment**            | Stateless 앱 배포/업데이트/스케일링          | 웹서버, API 서버 등     |
| **StatefulSet**           | 이름·스토리지 고정이 필요한 Stateful 앱        | DB, Kafka 등       |
| **DaemonSet**             | 모든 노드에 1개 Pod 자동 배포               | 로그 수집, 모니터링       |
| **ReplicaSet**            | Pod 복제 수 관리 (Deployment 내부에서 사용됨) | 직접 사용은 드묾         |
| **Job**                   | **한 번만 실행되는 작업**을 위한 컨트롤러         | 데이터 마이그레이션, 배치 작업 |
| **CronJob**               | **주기적으로 실행되는 Job**                | 예약 백업, 정기 리포트     |
| **ReplicationController** | 구버전의 ReplicaSet (거의 안 씀)          | 과거 Kubernetes 호환용 |

### <br/><br/>


## 사용자가 자주 사용하는 Controller
### Deployment, StatefulSet, DaemonSet 3개를 자주 쓴다.
### 1. Deployment
### 📌 일반적인 애플리케이션(Stateless 서비스)에 가장 많이 사용

| 항목    | 설명                                            |
| ----- | --------------------------------------------- |
| 목적    | **Stateless 앱** 배포 및 관리                       |
| 예시    | 웹서버, API 서버, 프론트엔드                            |
| 이름/순서 | 중요하지 않음 (Pod 이름 자동 생성됨)                       |
| 업데이트  | **Rolling Update**, Rollback, Scaling 등 모두 지원 |
| 복제본   | 레플리카 수만큼 자유롭게 증감 가능                           |
| 상태 유지 | ❌ (Pod가 재시작되면 이름/스토리지 바뀜)                     |

### ✅ 사용 예

```bash
kubectl create deployment nginx --image=nginx
```

### <br/>

### 2. StatefulSet
### 📌 이름과 순서가 중요한 **상태 기반(=Stateful)** 서비스용

| 항목    | 설명                                      |
| ----- | --------------------------------------- |
| 목적    | **Stateful 앱** (데이터 저장이 필요한 앱)          |
| 예시    | Prometheus, MySQL, Kafka, Elasticsearch |
| 이름/순서 | **중요**. 예: `pod-0`, `pod-1` 이름 고정       |
| 업데이트  | 순차적으로 1개씩 롤링 업데이트                       |
| 복제본   | **순서대로 생성/종료됨** (`pod-0` → `pod-1`)     |
| 상태 유지 | ✅ (Pod 이름과 PersistentVolume이 고정 연결됨)    |

### ✅ 사용 예

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  replicas: 3
  serviceName: mysql-headless
```

### <br/>

### 3. DaemonSet
### 📌 **클러스터의 모든 노드**에 1개씩 Pod을 배포하고 싶을 때 사용

| 항목    | 설명                                                |
| ----- | ------------------------------------------------- |
| 목적    | **모든 노드에 1개씩 Pod 실행**                             |
| 예시    | node-exporter, Fluentd, log agent, network plugin |
| 이름/순서 | 중요하지 않음                                           |
| 업데이트  | 각 노드에서 Rolling 방식으로 순차 업데이트                       |
| 복제본   | 노드 수와 동일 (노드가 늘어나면 자동 배포)                         |
| 상태 유지 | 보통 ❌ (Stateless가 일반적)                             |

### ✅ 사용 예

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
```

### <br/>

## 📊 차이 비교 요약표

| 항목        | Deployment    | StatefulSet       | DaemonSet              |
| --------- | ------------- | ----------------- | ---------------------- |
| 용도        | Stateless 서비스 | Stateful 서비스      | 모든 노드에 1개 Pod          |
| Pod 이름    | 자동 랜덤         | pod-0, pod-1 (고정) | 노드별 1개씩 생성             |
| 순서 보장     | ❌             | ✅                 | ❌                      |
| Volume 관리 | 공유 또는 없음      | Pod에 고정(PVC 바인딩)  | 보통 없음                  |
| 스케일링      | 수평적으로 자유롭게    | 순서대로 스케일링         | 노드 개수만큼 자동             |
| 예시        | Nginx, Django | Prometheus, Kafka | Fluentd, node-exporter |

### <br/>

### 어떤 걸 써야 할까?

| 상황                            | 추천            |
| ----------------------------- | ------------- |
| 웹서버, API 서버 같이 Stateless 앱 배포 | `Deployment`  |
| 데이터 저장이 필요한 DB, 모니터링 시스템      | `StatefulSet` |
| 모든 노드에서 로그/모니터링 수집            | `DaemonSet`   |

### <br/><br/>


## 비교적 덜 직접적으로 사용하는 Controller
### ReplicaSet, Job, CronJob, ReplicationController가 있다.
### ReplicationController은 ReplicaSet의 구버전. 현재는 거의 사용되지 않음.
### <br/>

### 1. ReplicaSet
#### > Pod의 **개수를 항상 일정하게 유지**해주는 컨트롤러
#### > 👉 `Deployment` 내부에서 자동 생성되므로 **직접 쓸 일은 거의 없음**
### 역할
* 특정한 수의 Pod가 **항상 살아 있도록 보장**
* Pod가 죽으면 다시 자동 생성
* Pod가 너무 많으면 자동 삭제
#### <br/>

### 특징
* `Deployment`를 사용하면 자동으로 ReplicaSet이 만들어짐
* 직접 쓸 일은 거의 없지만, `Deployment` 업데이트 시 과거 버전 추적에 쓰임
#### <br/>

### 간단 예시
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: my-app-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-container
          image: nginx
```

### <br/>

### 2. Job
#### > **한 번만 실행하고 성공하면 종료되는** 일회성 작업 컨트롤러
### 역할
* **데이터 마이그레이션, 백업, 배치 처리**에 적합
* 실패하면 재시도 가능 (`backoffLimit`, `restartPolicy` 등 설정 가능)
* 완료되면 Pod는 **Completed 상태**로 유지됨
#### <br/>

### 예시
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-job
spec:
  template:
    spec:
      containers:
        - name: hello
          image: busybox
          command: ["echo", "Hello World"]
      restartPolicy: Never
```

### <br/>

### 3. CronJob
#### > `Job`을 **정기적으로 예약 실행**하는 컨트롤러
##### > cron 스케줄링 문법 사용 (예: 매일 자정 실행)
### 특징
* Job을 스케줄에 따라 생성
* 실행 간격, 실패 시 재시도, 보존 개수 등 설정 가능
* Job 실패 시 **`startingDeadlineSeconds`**, **`concurrencyPolicy`** 등 조절 가능
#### <br/>

### 예시
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cron
spec:
  schedule: "0 0 * * *"  # 매일 자정
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: hello
              image: busybox
              command: ["echo", "Hello from CronJob"]
          restartPolicy: OnFailure
```

### <br/>

### 4. ReplicationController (❌ 사용 권장 안 함)
#### > **ReplicaSet의 구버전**. 현재는 거의 사용되지 않음.
### 특징
* Pod 개수를 유지한다는 점에서는 `ReplicaSet`과 같음
* 단, **label selector가 유연하지 않음** (matchLabels만 지원)
* **Deployment와 호환되지 않음**
* Kubernetes 1.x 초창기에서 쓰였으나, 이제는 ReplicaSet으로 대체됨
#### <br/>

### 예시
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: rc-example
spec:
  replicas: 2
  selector:
    app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: my-container
          image: nginx
```

### <br/>

### 비교 요약표

| 항목    | ReplicaSet               | Job    | CronJob | ReplicationController |
| ----- | ------------------------ | ------ | ------- | --------------------- |
| 목적    | Pod 개수 유지                | 일회성 실행 | 정기 실행   | Pod 개수 유지 (구식)        |
| 업데이트  | ✖ (수동으로 변경)              | ✖      | ✖       | ✖                     |
| 재시도   | X (컨트롤 안함)               | ✅ 가능   | ✅ 가능    | X                     |
| 스케줄링  | X                        | X      | ✅       | X                     |
| 사용 추천 | 거의 안 씀 (Deployment가 대신함) | ✅      | ✅       | ❌ 사용 금지 수준            |

### <br/>

### 무엇을 언제 써야 할까?

| 상황                  | 추천 리소스                                  |
| ------------------- | --------------------------------------- |
| 웹 앱/서버              | `Deployment`                            |
| 데이터 마이그레이션, 스크립트 실행 | `Job`                                   |
| 백업, 리포트, 정기 작업      | `CronJob`                               |
| Pod 개수만 유지 (실습용 등)  | `ReplicaSet` (but 보통 `Deployment`)      |
| 예전 문서 호환성 필요        | `ReplicationController` (❌가급적 사용하지 말 것) |

