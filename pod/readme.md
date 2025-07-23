### 250703
# pod 생성하기
### <br/>

### 아래와 같이 pod yaml을 하나 테스트로 구성하였다.
### 참고로 나는 label에 먼저 role=service 라고 하나 생성해두었고, 해당 label에 맞는 node에만 pod가 생성된다.
### 아래를 참고하자.
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/node_label
#### jhshin-test-pod.yaml
```
# jhshin-test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: jhshin-test
spec:
  nodeSelector:
    role: service  # 이 라벨이 있는 노드에만 배치
  containers:
  - name: jhshin-container
    image: shinejh0528/jhshin_base:1.1.1
    command: [ "sleep", "3600" ]  # 1시간 대기 (테스트용)
```
### <br/>

### pod 생성
```
kubectl apply -f jhshin-test-pod.yaml
```
#### ![image](https://github.com/user-attachments/assets/2bdddf1f-41f6-4407-9fa2-b451cc40b211)
### <br/>

### pod 상태 확인
```
kubectl get pod jhshin-test -o wide
```
#### ![image](https://github.com/user-attachments/assets/7fe3c269-b80b-43a3-b202-04c65ea335b5)
### <br/>

### pod 내부에 접속하기
#### 기본적으로 docker exec와 거의 동일하다.
#### '--'은 kubectl 명령어의 인자와, 실행할 컨테이너 내부 명령어 인자를 구분하는 역할을 한다.
```
kubectl exec -it jhshin-test -- /bin/bash
```
### <br/>

### pod 삭제
```
kubectl delete pod jhshin-test
```
### <br/>
