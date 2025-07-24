#!/bin/bash

# 비밀번호
PASSWORD='pass'

# base64 인코딩
ENCODED_PASSWORD=$(echo -n "$PASSWORD" | base64)

# 인코딩된 값 출력 (참고용)
echo "Base64 Encoded Password: $ENCODED_PASSWORD"

# Secret 생성
kubectl create secret generic mysql-secret \
  --from-literal=MYSQL_ROOT_PASSWORD="$PASSWORD" \
  -n namespace
