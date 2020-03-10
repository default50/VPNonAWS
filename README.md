# VPNonAWS

Deploy your own VPN service on AWS

#### ToDo

- Explore:
  - https://github.com/virtualjj/automated-openvpnas
  - https://gist.github.com/pbzona/91d6a6dd4b8cf27c9a032afe32703858
- Make outputs of URL not only with IPs
- Use Letsencrypt certs for SSL instead of custom ones

## OpenVPN

### Deploy

```
aws cloudformation create-stack --stack-name OpenVPN-IAD --parameters file://openvpn.params.json --template-body file://openvpn-aws.template.yaml --region us-east-1
```

### Update

Run `OpenVPN-AMIs.sh` to obtain an up to date mapping of AMIs per region and replace that in the CloudFormation template.

```
aws cloudformation update-stack --stack-name OpenVPN-IAD --parameters file://openvpn.params.json --template-body file://openvpn-aws.template.yaml --region us-east-1
```

## WireGuard

### Deploy

```
aws cloudformation create-stack --stack-name WireGuardVPN-IAD --parameters file://wireguard.params.json --template-body file://wireguard-aws.template.yaml --region us-east-1
```
