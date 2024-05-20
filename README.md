### Kubespray w/ terraform on GCP

### Setup kubespray VENV
```bash
# from root of project
VENVDIR=.kubespray-venv
KUBESPRAYDIR=kubespray
python3 -m venv $VENVDIR
source $VENVDIR/bin/activate
cd $KUBESPRAYDIR
pip install -U -r requirements.txt
```

### Setup terraform infrastructure

create a `./terraform/inputs/vars.tfvars` file with the following content:
```hcl
cp_count      = 3 # how many control plane nodes, 3 is default if not specified
worker_count  = 1 # how many worker nodes, 1 is default if not specified
project       = "<gcp project id>" # your gcp project id e.g. name-123456
public_ip      = "0.0.0.0/32" # your public ip in CIDR format, use ./scripts/whoami.sh if you don't know your public ip address
```
other overridable variables available in `./terraform/variables.tf`

create a servce account in GCP and download the json key file and place it in `./terraform/inputs/credentials.json` or
somewhere else specified by your `gcp_credentials` variable.

```bash
# from root of project
cd ./terraform
terraform init
terraform apply -var-file="./inputs/vars.tfvars"
```

### Run Kubespray
make sure that ansible-playbook is using the binary in your venv.
```bash
which ansible-playbook
```
the result should be inside `/<project path>/.kubespray-venv/bin/ansible-playbook`, if not restart shell and reactivate 
python venv with `./kubespray-venv/bin/activate`

```bash
# from root of project
cd ./kubespray
ansible-playbook -i inventory/hosts.yaml ./kubespray/cluster.yml --become
```



