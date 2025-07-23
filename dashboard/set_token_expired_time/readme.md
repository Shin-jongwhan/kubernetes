### 250718
# token TTL (Time To Live) 설정 방법
### 매우 쉽다. 그냥 --duration 옵션만 하나 넣어주면 된다.
```
kubectl -n kubernetes-dashboard create token admin-user --duration 8760h
```
