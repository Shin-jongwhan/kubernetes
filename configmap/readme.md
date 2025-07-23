### 250721
# ConfigMap
### 매우 간단하지만, 아주 유용하니 꼭 알아두자.
### key value 저장소로 말 그대로 config이다.
### namespace 별로 관리되고, metadata에 namespace를 적지 않으면 default로 등록된다.
### <br/><br/>


## ConfigMap에서 등록할 수 있는 주요 필드

| 필드 이름        | 설명                                                |
| ------------ | ------------------------------------------------- |
| `data`       | 문자열 기반의 key-value 쌍 (일반적으로 가장 많이 사용됨)             |
| `binaryData` | base64로 인코딩된 이진 데이터. 파일 형태로 주입할 때 사용              |
| `metadata`   | 이름, 네임스페이스, 라벨 등 리소스 메타데이터                        |
| `immutable`  | `true`로 설정하면 변경 불가한 ConfigMap이 됨 (K8s 1.18+부터 지원) |

### <br/><br/>

## metadata
#### 객체를 식별하고 분류하고 제어하는 정보를 담는다.

| 필드명                 | 설명                                                    |
| ------------------- | ----------------------------------------------------- |
| `name`              | 이 ConfigMap의 이름 (필수)                                  |
| `namespace`         | 속한 네임스페이스. 없으면 `default`로 들어감                         |
| `labels`            | 리소스 그룹화/선택을 위한 태그 (예: `kubectl get cm -l app=my-app`) |
| `annotations`       | 설명/도구/정책/문서화용 주석. Helm, ArgoCD 등이 사용함                 |
| `creationTimestamp` | 생성된 시간. 자동 생성됨. 사용자가 지정 ❌                             |
| `uid`               | 고유 식별자. 자동 생성됨                                        |
| `resourceVersion`   | 수정 횟수 등 트래킹용 버전. 자동 생성됨                               |

### <br/>

### 자주 사용하는 것
- name
- namespace
- labels
- annotations (Helm, ArgoCD, CI/CD 등에서 사용됨)
### <br/>

### metadata 예시
```yaml
metadata:
  name: custom-prometheus-config
  namespace: monitoring
  labels:
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/component: config
  annotations:
    description: "Custom scrape targets for Prometheus"
```
### <br/><br/>


## data
### 다차원의 데이터를 넣으려면 '|'으로 여러 줄 형식으로 넣어야 한다.
- 가장 기본적인 문자열 설정
- key는 파일 이름처럼 쓸 수도 있고
- value는 단일 줄 또는 여러 줄 가능 (| 등으로)
### <br/>

### 예시
```yaml
data:
  app.conf: |
    debug=true
    port=8080
```
### <br/>


## binaryData
### 선택적으로 사용하고, 자주 사용하지는 않는다.
- 이진 파일이나 특수 문자 포함된 내용을 저장할 때 사용
- value는 base64로 인코딩된 문자열이어야 함
### <br/>

### 에시
```yaml
binaryData:
  logo.png: iVBORw0KGgoAAAANSUhEUgAA...  # base64
```
### <br/><br/>


## immutable
### 수정 방지를 위한 Boolean 플래그
### 변경하려면 삭제 후 다시 만들어야 함
```yaml
immutable: true
```
### <br/><br/>


## 전체 예시
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
  namespace: default
  labels:
    app: my-app
immutable: true
data:
  config.yaml: |
    logging: debug
    retries: 5
binaryData:
  cert.pem: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t...
```
