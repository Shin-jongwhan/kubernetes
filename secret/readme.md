### 250710
# Secret
### secret에는 Opaque, tls, bash-auth 등 여러가지가 포함되어 있다. 
| Secret 타입 (`type:`)                   | 용도                                 |
| ------------------------------------- | ---------------------------------- |
| `Opaque`                              | 가장 일반적인 타입 (사용자 정의 키-값 저장)         |
| `kubernetes.io/tls`                   | TLS 인증서 (`tls.crt`, `tls.key`) 저장  |
| `kubernetes.io/basic-auth`            | 사용자 이름/비밀번호 저장 (HTTP Basic Auth 용) |
| `kubernetes.io/ssh-auth`              | SSH 개인 키 저장                        |
| `kubernetes.io/dockerconfigjson`      | Docker Registry 인증 정보 저장           |
| `kubernetes.io/service-account-token` | 자동 생성된 서비스 계정 토큰 저장 (K8s 내부용)      |
### <br>

### 아래 예시를 보면 각각이 어떤 secret인지 알 수 있다.
#### ✅ 1. Opaque (기본 타입)
```bash
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=1234
```
#### 결과 내부:
```
data:
  username: YWRtaW4=
  password: MTIzNA==
type: Opaque
```
#### <br/>

#### ✅ 2. kubernetes.io/tls
```
kubectl create secret tls my-tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key
```
#### 결과 내부:
```
data:
  tls.crt: (base64 인코딩된 인증서)
  tls.key: (base64 인코딩된 개인키)
type: kubernetes.io/tls
```
#### <br/>

#### ✅ 3. kubernetes.io/basic-auth
```
kubectl create secret generic my-basic-auth \
  --type=kubernetes.io/basic-auth \
  --from-literal=username=myuser \
  --from-literal=password=mypass
```
#### <br/>

#### ✅ 4. kubernetes.io/ssh-auth
```
kubectl create secret generic my-ssh-key \
  --type=kubernetes.io/ssh-auth \
  --from-file=ssh-privatekey=~/.ssh/id_rsa
```
#### <br/>

#### ✅ 5. kubernetes.io/dockerconfigjson (imagePullSecret용)
```
kubectl create secret docker-registry my-registry-secret \
  --docker-username=myuser \
  --docker-password=mypass \
  --docker-email=myemail@example.com \
  --docker-server=https://index.docker.io/v1/
```
#### 또는 파일 기반:
```
kubectl create secret generic my-docker-secret \
  --type=kubernetes.io/dockerconfigjson \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json
```
