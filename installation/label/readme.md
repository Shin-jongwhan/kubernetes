### 250703
# Label
### node를 구분하기 위해 특정 label 을 달고, 각 label에 따라서 node를 운영할 수 있게 한다.
### 예를 들어 service 서버, database 서버, backend 서버 이렇게 각각 나눠서 운영해야 할 때 필요하다.
### <br/>

### node 이름 조회
```
kubectl get nodes
```
### <br/>

### label 생성
#### 참고 : 이미 label이 있는데 또 쓰면 새로운 값으로 덮어씌워진다.
```
kubectl label node [node_name] role=service
```
### <br/>

### node 별 label 조회
```
kubectl get nodes --show-labels
```
#### ![image](https://github.com/user-attachments/assets/bf4b7748-a278-4633-a3d8-cf6b03b57d04)
### <br/>

