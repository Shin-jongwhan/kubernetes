### 250715
# volume 유형 - hostPath, PV (persistance volume), PVC (persistance volume claim)
### 요약하자면 이렇다.
- emptyDir (pod 안에서만 사용 가능한  volume)는 temporary storage 이다.
- hostPath 는 persistance volume이지만 node dependent 하다.
- 모든 node 에 같이 사용하려면 network storage 를 사용해야 한다(ceph, S3 등).
#### <img width="455" height="582" alt="image" src="https://github.com/user-attachments/assets/abc7b317-fe8a-46b1-9535-8974cd75b0cb" />
### <br/>

### 적용한 예시는 다음을 참고하자
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/ingress/ingress_nginx/static_proxy

### <br/><br/>

## hostPath
### Pod가 노드의 로컬 디렉토리를 직접 마운트해서 사용하는 방식.
### 별도의 PV/PVC 없이 Pod 안에서 바로 설정 가능.
### <br/>

### 예시
```yaml
volumes:
  - name: my-volume
    hostPath:
      path: /data/mysql
      type: DirectoryOrCreate
```
### <br/>

### 특징
| 항목        | 설명                         |
| --------- | -------------------------- |
| 접근 방식     | 노드 디렉토리를 직접 사용             |
| 장점        | 간단하고 빠르며 설정 쉬움             |
| 단점        | Pod가 다른 노드로 이동 시 데이터 접근 불가 |
| 사용 예      | 로컬 테스트, static 파일, 로컬 DB 등 |
| 운영 환경 적합성 | ❌ 비추천 (데이터 유실/확장성 문제)      |

### <br/>

## PV (PersistentVolume)
### 정의
- 클러스터 관리자가 미리 정의하는 **스토리지 자원**.
- 다양한 백엔드(NFS, AWS EBS, hostPath 등)를 사용할 수 있음.
- **PVC에 의해 연결**될 수 있음.
### <br/>

### 예시
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/mysql
```
### <br/>

### 특징
| 항목            | 설명                         |
| ------------- | -------------------------- |
| 생성 주체         | 클러스터 관리자 또는 동적 프로비저너       |
| 백엔드 종류        | hostPath, NFS, Ceph, EBS 등 |
| 재사용성          | PVC가 삭제되지 않으면 재사용 가능       |
| ReclaimPolicy | Retain, Delete, Recycle    |
| 운영 환경 적합성     | ✅ 적합 (단, hostPath는 예외)     |

### <br/><br/>

## PVC (PersistentVolumeClaim)

### 정의
- 사용자가 필요한 스토리지 용량, 접근 모드를 명시해서 요청하는 객체.
- Kubernetes가 적절한 PV를 찾아 연결시킴.

### 예시
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```
### <br/>

### 특징

| 항목        | 설명                                        |
| --------- | ----------------------------------------- |
| 생성 주체     | 사용자 또는 Deployment 내부 volumeClaimTemplates |
| 용도        | 스토리지 요청용                                  |
| 바인딩 대상    | 조건이 일치하는 PV                               |
| 동적 프로비저닝  | StorageClass가 설정된 경우 자동 생성 가능             |
| 운영 환경 적합성 | ✅ 매우 적합                                   |

### <br/><br/>

## 관계도 요약

```
[ PVC (사용자 요청) ] ───(바인딩)───> [ PV (스토리지 제공자) ] ──> [ 실제 스토리지 (NFS, hostPath 등) ]
```

* `hostPath`: 단독으로 사용 가능 (PVC 없이)
* `PV`: PVC가 요청한 조건에 맞춰 실제 스토리지를 제공
* `PVC`: Pod가 요청하는 스토리지의 인터페이스

### <br/><br/>

## 비교표

| 항목      | hostPath   | PV                   | PVC            |
| ------- | ---------- | -------------------- | -------------- |
| 역할      | 로컬 디스크 마운트 | 스토리지 제공자             | 사용자 요청자        |
| 위치      | Pod 정의 내부  | 독립 리소스               | 독립 리소스         |
| 스토리지 유형 | 노드 로컬      | hostPath, NFS, EBS 등 | PV에 연결됨        |
| 마이그레이션  | ❌ 안 됨      | 백엔드 따라 다름            | PV와 연동 시 이동 가능 |
| 사용 용도   | 간단한 테스트용   | 영구적이고 재사용 가능한 스토리지   | 스토리지 요구 명세화    |

### <br/><br/>

## EBS는 local storage 인데 어떻게 PV 가 될 수 있나?
### 중요 참고 : v1.17부터 deprecated 되었고, 참고만 하자.
### EBS는 로컬 볼륨이 맞다(물리적으로).
### EBS는 특정 AZ(Availability Zone) 에 물리적으로 존재하는 block-level storage 이다.
### 특정 EC2 인스턴스에 attach 할 수 있고, 동시에 여러 인스턴스에서 사용할 수는 없다.
### 즉, EBS는 “AZ 내 단일 노드 전용 디스크”처럼 동작한다.
### <br/>

### 사실상 local disk와 차이가 없다.
| 항목            | EBS                     | 로컬 디스크 (`hostPath`, `local`) |
| ------------- | ----------------------- | ---------------------------- |
| 스토리지 위치       | AWS의 AZ 기반 네트워크 블록 스토리지 | 실제 노드 안의 디스크                 |
| 여러 노드에서 사용    | ❌ No (ReadWriteOnce)    | ❌ No (해당 노드에서만 사용 가능)        |
| 이동성           | EC2 간 attach/detach 가능  | 물리적으로 이동 불가                  |
| 속도            | 빠르지만 네트워크 딜레이 존재        | 매우 빠름 (로컬 I/O)               |
| ReclaimPolicy | `Retain`, `Delete` 등 가능 | 동일하게 가능                      |
| 운영 난이도        | AWS가 관리                 | 사용자가 직접 디렉토리 존재 확인/관리 필요     |

### <br/><br/>

## local storage 도 PV 가 될 수 있나?
### 로컬 스토리지(Local Storage) 도 Kubernetes 에서 PersistentVolume(PV) 로 연결해서 사용할 수 있다.
### 그리고 로컬 스토리지를 이용할 때 PV를 이용하는 방법이 권장되는 방법이다.
### <br/>

### ex yaml) hostPath 방식 (가장 간단)
#### 📌 주의: hostPath는 노드에 종속되기 때문에 반드시 nodeAffinity로 어떤 노드의 디스크인지 명시해야 함.
#### hostPath는 간단하지만 운영 환경에서는 피해야 할 방식이다.
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-hostpath
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/mysql
  persistentVolumeReclaimPolicy: Retain
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - your-node-name
```
### <br/>

### ex yaml) local 볼륨 타입 (정식 로컬 볼륨)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/disks/data1
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - your-node-name
```
### <br/>

### 주의할 점
| 항목                    | 설명                                                                    |
| --------------------- | --------------------------------------------------------------------- |
| 스토리지는 **고정된 노드**에만 존재 | Pod는 해당 노드에만 스케줄 되어야 함 (`nodeAffinity` or `nodeSelector`)             |
| 다른 노드로 이동 ❌           | 로컬 디스크는 공유되지 않으므로 다른 노드에서 접근 불가                                       |
| 볼륨 존재 여부 확인 필요        | `/data/mysql`, `/mnt/disks/data1` 디렉토리가 실제로 존재해야 함                    |
| 동적 프로비저닝 불가 (기본 상태)   | `hostPath`나 `local`은 동적 생성되지 않음. 필요한 경우 `local-static-provisioner` 사용 |

### <br/>

### 문답
| 질문                     | 대답                                        |
| ---------------------- | ----------------------------------------- |
| 로컬 스토리지도 PV로 연결할 수 있어? | ✅ 가능함 (`hostPath`, `local` 방식)            |
| 자동 생성돼?                | ❌ 기본적으로는 수동 생성 필요                         |
| 어떤 노드인지 지정해야 해?        | ✅ 반드시 `nodeAffinity` 또는 `nodeSelector` 필요 |
| 공유 가능한가?               | ❌ 아님. 해당 노드에서만 접근 가능함                     |

### <br/>

### hostPath와 local PV의 차이
| 항목           | `hostPath`                    | `local PV (PersistentVolume with local storage)` |
| ------------ | ----------------------------- | ------------------------------------------------ |
| 🏷️ 목적       | 디버깅/테스트/개발                    | 운영용 로컬 디스크 할당                                    |
| 📦 자원 관리     | Kubernetes 리소스가 아님 (제외됨)      | PV로 Kubernetes가 직접 관리                            |
| 🔐 보안성       | Pod가 호스트 디렉토리에 직접 접근 → **위험** | 제한된 디렉토리만 접근 → **안전**                            |
| 📌 스케줄링 통합   | ❌ 불가능 (Pod가 특정 노드에 고정되지 않음)   | ✅ `nodeAffinity`로 정확하게 연동됨                       |
| 🔄 데이터 추적    | ❌ 추적 불가                       | ✅ PV, PVC 통해 상태 추적 가능                            |
| ⚠️ 실수 방지     | ❌ 사용자 마음대로 host 경로 바꿀 수 있음    | ✅ 고정된 path만 사용                                   |
| 🔧 동적 프로비저닝  | ❌ 지원 안 됨                      | ❌ 기본적으로는 없음 (수동 PV 필요)                           |
| 🔁 재시작/재스케줄링 | ❌ Pod가 다른 노드로 가면 mount 실패     | ✅ nodeAffinity로 같은 노드에만 스케줄됨                     |
| 📚 권장도       | ❌ 실서비스 비추천                    | ✅ 로컬 디스크 기반 운영 환경에서 권장                           |

### <br/><br/>
