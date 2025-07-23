### 250715
# Volume
#### docs : 컨테이너 내의 디스크에 있는 파일은 임시적이며, 컨테이너에서 실행될 때 애플리케이션에 적지 않은 몇 가지 문제가 발생한다. 한 가지 문제는 컨테이너가 크래시될 때 파일이 손실된다는 것이다. kubelet은 컨테이너를 다시 시작하지만 초기화된 상태이다. 두 번째 문제는 Pod에서 같이 실행되는 컨테이너간에 파일을 공유할 때 발생한다. 쿠버네티스 볼륨 추상화는 이러한 문제를 모두 해결한다. 파드에 대해 익숙해지는 것을 추천한다.
### <br/><br/>

## Volume 유형
#### 스토리지 클래스라고도 한다. kubernetes docs에는 프로비저너라는 프로그램이 있고, 이게 PV 프로비저닝을 한다고 한다.
#### https://kubernetes.io/ko/docs/concepts/storage/storage-classes/#%ED%94%84%EB%A1%9C%EB%B9%84%EC%A0%80%EB%84%88
#### 각 스토리지클래스에는 PV 프로비저닝에 사용되는 볼륨 플러그인을 결정하는 프로비저너가 있다. 이 필드는 반드시 지정해야 한다.
### kubernets에서 사용하는 volume 유형은 다양한데, 사실 정리하자면 3개다.
- pod local storage : pod 안쪽에서만 쓸 수 있는 임시 스토리지. pod 삭제 시 같이 삭제된다.
- local node storage : 특정 node 서버에서만 쓸 수 있는 스토리지(hostPath)
- network storage : 네트워크로 연결하여 다른 node 들에서도 모두 쓸 수 있는 스토리지. 따라서 네트워크 스토리지는 별도 유지보수가 필요하다.

| 이름                     | 설명                                  |
| ---------------------- | ----------------------------------- |
| `emptyDir`             | 파드가 생성될 때 생성되고 파드가 삭제될 때 삭제되는 임시 볼륨 |
| `hostPath`             | 노드의 로컬 볼륨                           |
| `awsElasticBlockStore` | 아마존 웹 서비스 EBS 볼륨 (**v1.17 부터 deprecated**)              |
| `azureDisk`            | 마이크로소프트 애저 볼륨                       |
| `cephfs`               | Ceph4 분산 파일 시스템 볼륨                  |
| `cinder`               | 오픈스택 Cinder 블록 스토리지 볼륨              |
| `gcePersistentDisk`    | 구글 컴퓨트 엔진의 지속성 디스크 볼륨               |
| `glusterfs`            | GlusterFS 오픈소스 네트워크 파일시스템 볼륨        |
| `iSCSI`                | iSCSI(인터넷 소형 컴퓨터 시스템 인터페이스) 볼륨      |
| `NFS`                  | NFS(네트워크 파일 시스템) 볼륨                 |

### <br/>

### 📦 프로비저닝 (Provisioning)
#### 스토리지를 **PersistentVolume(PV)** 형태로 클러스터에 생성하는 단계임.
#### 프로비저닝 방식에는 두 가지가 존재함:
- **정적 프로비저닝 (Static Provisioning)**:
  관리자가 미리 특정 스토리지를 PV로 만들어 등록해두는 방식임.
  사용자는 이를 PVC(PersistentVolumeClaim)를 통해 요청하여 할당받음.
- **동적 프로비저닝 (Dynamic Provisioning)**:
  PVC가 제출될 때 조건에 맞는 PV가 없다면, **StorageClass**를 참조하여 **자동으로 PV를 생성**하는 방식임.
  이를 통해 관리자의 사전 작업 없이도 유연하게 볼륨을 할당받을 수 있음.
### <br/> 

### 🔗 바인딩 (Binding)
#### PVC가 생성되면, 해당 PVC의 요청 조건(용량, 접근 모드 등)에 맞는 PV를 검색하여 **자동으로 연결(Binding)** 됨.
- 바인딩은 PV, PVC 가 **1:1 대응** 관계임.
  하나의 PVC는 오직 하나의 PV와만 연결될 수 있으며, 반대로 하나의 PV도 단 하나의 PVC에만 연결됨.
- 조건에 맞는 PV가 존재하지 않으면 PVC는 **대기 상태(Pending)** 로 남아 있음.
  이후 조건에 맞는 PV가 생성되면 자동으로 바인딩됨.
### <br/> 

### 🧩 사용 (Using)
#### 바인딩된 PVC는 파드(Pod)의 명세에 포함되어 볼륨으로 사용됨.
- 파드는 마치 로컬 디스크처럼 PVC를 마운트하여 사용함.
  실제로는 백엔드 스토리지(예: NFS, iSCSI, Ceph 등)에 연결되어 동작함.
- 이 단계에서 애플리케이션은 파일 시스템을 통해 데이터를 읽고 쓰는 등의 작업을 수행함.
### <br/> 

### 🧹 회수 (Reclaiming)
#### PVC가 삭제되면, 해당 PVC와 바인딩되어 있던 PV는 **재사용 여부를 결정하기 위한 "회수 정책(Reclaim Policy)"** 에 따라 처리됨.
#### 회수 정책에는 다음 세 가지가 존재함:
1. **유지(Retain)**:
   - PVC가 삭제되어도 PV는 삭제되지 않으며, 상태는 `Released`로 변경됨.
   - **데이터는 그대로 유지**되며, 보안상 또는 수동 정리가 필요한 경우 사용됨.
   - 관리자가 직접 PV를 초기화하거나 삭제해야 함.
2. **삭제(Delete)**:
   - PVC가 삭제되면 PV와 백엔드 스토리지 리소스(예: EBS 볼륨 등)도 함께 자동 삭제됨.
   - **동적 프로비저닝된 볼륨에 주로 사용**되며, 관리 부담이 적음.
3. **재사용(Recycle)** *(현재는 더 이상 사용되지 않음)*:
   - PVC가 삭제되면 PV는 `Pending` 상태로 돌아가고, 간단한 데이터 삭제 후 다시 사용 가능하게 됨.
   - 과거에는 테스트 환경 등에서 사용되었으나, 보안 및 신뢰성 이슈로 **더 이상 권장되지 않음**.
   - kubernetes docs 에는 이렇게 써져 있음
     - [kubernetes docs - persistance volume](https://kubernetes.io/ko/docs/concepts/storage/persistent-volumes/)
     - Recycle 반환 정책은 더 이상 사용하지 않는다. 대신 권장되는 방식은 동적 프로비저닝을 사용하는 것이다.
### <br/> 

### ✅ **요약**
| 단계    | 설명                                              |
| ----- | ----------------------------------------------- |
| 프로비저닝 | PV를 생성하는 단계. 정적/동적 방식이 있음.                      |
| 바인딩   | PVC가 조건에 맞는 PV와 자동 연결되는 단계. 1:1 관계 유지.          |
| 사용    | Pod에서 PVC를 볼륨으로 마운트하여 사용하는 단계.                  |
| 회수    | PVC 삭제 이후 PV를 어떻게 처리할지 결정하는 단계. Retain/Delete 등 |

### <br/><br/> 

## 퍼시스턴트 볼륨의 유형
#### https://kubernetes.io/ko/docs/concepts/storage/persistent-volumes/#%ED%8D%BC%EC%8B%9C%EC%8A%A4%ED%84%B4%ED%8A%B8-%EB%B3%BC%EB%A5%A8%EC%9D%98-%EC%9C%A0%ED%98%95
### 퍼시스턴트볼륨 유형은 플러그인으로 구현된다. 쿠버네티스는 현재 다음의 플러그인을 지원한다.
- cephfs - CephFS 볼륨
- csi - 컨테이너 스토리지 인터페이스 (CSI)
- fc - Fibre Channel (FC) 스토리지
- hostPath - HostPath 볼륨 (단일 노드 테스트 전용. 다중-노드 클러스터에서 작동하지 않음. 대신 로컬 볼륨 사용 고려)
- iscsi - iSCSI (SCSI over IP) 스토리지
- local - 노드에 마운트된 로컬 스토리지 디바이스
- nfs - 네트워크 파일 시스템 (NFS) 스토리지
- rbd - Rados Block Device (RBD) 볼륨
### <br/>

### 사용 중단이 꽤 많다. 자세한 건 위 공식 docs 참고
#### <img width="767" height="495" alt="image" src="https://github.com/user-attachments/assets/fa6a0611-c6e5-4ca3-8cd2-51099325f536" />

### <br/><br/> 

## 참고
#### [Kubernetes CSI 개념 정리 및 실습](https://tech.gluesys.com/blog/2022/06/21/CSI.html#fn:7)
#### [kubernetes docs - persistance volume](https://kubernetes.io/ko/docs/concepts/storage/persistent-volumes/)
#### [kubernetes docs - volume](https://kubernetes.io/ko/docs/concepts/storage/volumes/)
#### https://github.com/Shin-jongwhan/network/tree/main/iSCSI_VS_NFS
