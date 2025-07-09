### 250709
# worker node join
### worker node를 join 시키기 위해서는 control plane에서 token을 출력해야 한다.
```
kubeadm token create --print-join-command
```
### <br/>

### 예시 출력
```
kubeadm join 192.168.0.10:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
### <br/>

### 그 다음 worker node에서 다음을 입력한다.
- --cri-socket /var/run/cri-dockerd.sock : 설정한 container runtime에 대한 socket 경로를 넣는다.
```
sudo kubeadm join 192.168.0.10:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --cri-socket /var/run/cri-dockerd.sock
```
### <br/>

### join 확인
```
kubectl get nodes
```
#### ![image](https://github.com/user-attachments/assets/da844c4e-4aa2-4359-bcbc-819f1325d9ad)
### <br/>

### 다음과 같이 ansible playbook도 만들 수 있다.
#### https://github.com/Shin-jongwhan/IaC_infrastructure_as_code/blob/main/ansible/playbook/join_kubernetes_worker.yml
### <br/>

### dashboard에서도 확인 가능하다.
#### ![image](https://github.com/user-attachments/assets/461f702c-7b63-4b57-9f06-7d41ed585a63)

