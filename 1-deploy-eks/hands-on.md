
## 실습 코드 다운로드

실습 코드 repo를 받아 확인한다.
```bash
❯ git clone https://github.com/gasida/aews.git

❯ tree aews 
aews
├── 1w
│   ├── eks.tf
│   ├── var.tf
│   └── vpc.tf
└── eks-private
    ├── ec2.tf
    ├── main.tf
    ├── outputs.tf
    └── versions.tf

3 directories, 7 files

# 1주차 실습
❯ cd aews/1w
```

## VPC, EKS 배포 (12~15분 가량 소요)
```bash
# 변수 지정
aws ec2 describe-key-pairs --query "KeyPairs[].KeyName" --output text
export TF_VAR_KeyName=$(aws ec2 describe-key-pairs --query "KeyPairs[].KeyName" --output text)
export TF_VAR_ssh_access_cidr=$(curl -s ipinfo.io/ip)/32
echo $TF_VAR_KeyName $TF_VAR_ssh_access_cidr

# 배포 : 12분 정도 소요
terraform init
terraform plan
nohup sh -c "terraform apply -auto-approve" > create.log 2>&1 &
tail -f create.log


# 자격증명 설정
aws eks update-kubeconfig --region ap-northeast-2 --name myeks

# k8s config 확인 및 rename context
cat ~/.kube/config
cat ~/.kube/config | grep current-context | awk '{print $2}'
kubectl config rename-context $(cat ~/.kube/config | grep current-context | awk '{print $2}') myeks
cat ~/.kube/config | grep current-context

```