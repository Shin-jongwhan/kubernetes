### 250703
## taint란
### Kubernetes에서 특정 노드에 Pod이 자동으로 배치되지 않도록 제한하는 기능
### 왜 마스터 노드에는 기본적으로 Pod이 올라가지 않을까?
### 컨트롤 플레인 노드는 다음과 같은 중요한 시스템 컴포넌트가 작동하는 곳이기 때문이다.
| 컨트롤 플레인 구성요소              | 역할                  |
| ------------------------- | ------------------- |
| `kube-apiserver`          | 클러스터 통신의 핵심         |
| `etcd`                    | 클러스터 상태 저장 (데이터베이스) |
| `kube-controller-manager` | 리소스 상태 조정           |
| `kube-scheduler`          | Pod 배치 결정           |

### <br/>

### 이러한 핵심 컴포넌트에 리소스를 안정적으로 보장하기 위해, 기본적으로 마스터 노드는 "나는 일반 Pod 안 받는다"고 설정되어 있다.
### → 이게 바로 taint이다.
### <br/>

### Kubernetes Pod의 배치 흐름을 먼저 알면 좋다.
- 사용자가 kubectl apply -f pod.yaml → Pod 리소스 생성
- kube-scheduler가 어떤 노드에 Pod을 올릴지 판단
- **노드에 taint가 있고, Pod에 toleration이 없으면 ❌ 그 노드는 제외됨**
- 적절한 워커 노드가 있으면 그쪽에 배치됨
- 아무 노드도 조건에 안 맞으면 → Pod은 Pending 상태가 됨
### <br/>

### 그런데 마스터 노드에서도 pod를 배치하고 싶을 때는 untainted 설정을 하면 된다.
### 서버 규모가 작을 때는 충분히 고려할만 하다.
### 아래와 같이 node를 확인한다. NAME에 써진 게 node 이름이다.
```
kubectl get nodes
```
#### ![image](https://github.com/user-attachments/assets/bdfebab4-d2ff-4068-ab82-f23473b5aa79)
#### <br/>

### taint 확인
#### 기본적으로 마스터 노드(컨트롤 플레인)에는 taint 설정이 되어 있다.
#### NoSchedule이라고 써진 게 pod 생성을 제한(못 하게 함)하는 것이다. 
#### 정확하게 말하면 Pod은 생성되지만, taint가 설정된 노드에는 스케줄되지 않아서 해당 노드에 배치되지 않을 뿐이긴 한데 어쨋든...
```
kubectl describe node [node_name] | grep Taint
```
#### ![image](https://github.com/user-attachments/assets/79ba1c16-13fd-462a-aa7e-727b31943247)
### <br/>

### untainted 설정
```
kubectl taint nodes tgf-service node-role.kubernetes.io/control-plane-
```
#### ![image](https://github.com/user-attachments/assets/7834e2b9-9593-4f08-a616-d5b957e1b643)
### <br>

### 그럼 이제 마스터 노드에서 따로 join 할 필요가 있을까?
### 아니다. 마스터 노드는 이미 클러스터에 속해 있으므로 kubeadm join을 다시 할 필요 없다.
#### <br/>

### 왜 그럴까?
- kubeadm init은 이미 그 노드를 컨트롤 플레인 노드 + 워커 노드 둘 다의 기능을 할 수 있도록 구성한다.
- 단지 taint 때문에 일반 워크로드(Pod)가 올라가지 못했던 것뿐이다.
- taint를 제거한 순간, 이 노드는 워커 역할도 가능한 상태가 된다.
