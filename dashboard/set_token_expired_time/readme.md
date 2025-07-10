### 250709
# token TTL (Time To Live) 설정 방법
### * 이 방법은 해봤는데 안 먹힘. 또 몇 시간 지나면 로그아웃된다. 다른 방법을 알아봐야 함.
### dashboard에 같은 token으로 접근하고 싶은데 자꾸 expired 가 되면 접속이 끊긴다.
### 그래서 ttl=0으로 해주면 만료 시간을 해제할 수 있다.
### <br/>

### kubernetes-dashboard-api에서 설정값을 수정해야 한다.
```
kubectl edit -n kubernetes-dashboard deployment kubernetes-dashboard-api
```
### <br/>

### args 부분에 아래 값을 추가한다.
```
args:
  - --token-ttl=0
```
