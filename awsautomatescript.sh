#/bin/bash

echo "CREATING VPC"

aws ec2 create-vpc --cidr-block 10.0.0.0/16 

# Selecting vpcid from the vpc-describe and assign this value to a variable

vpcid="$(aws ec2 describe-vpcs |grep vpc | cut -d'"' -f 4)"

echo "CREATING SUBNET"

aws ec2 create-subnet --vpc-id $vpcid --cidr-block 10.0.1.0/24

subnetid="$(aws ec2 describe-subnets | grep SubnetId | cut -d'"' -f 4)"

echo "CREATING SECURITY GROUP"
aws ec2 create-security-group --vpc-id $vpcid --group-name MySecurityGroup --description "My security group" 

echo "CREATING INTERNETGATEWAY"

aws ec2 create-internet-gateway

awsaccesskey="$(less .aws/credentials | grep aws_access_key | cut -d'=' -f 2)"
awsseceretkey="$(less .aws/credentials | grep aws_secre | cut -d'=' -f 2)"

internetgateway="$(aws ec2 describe-internet-gateways | grep InternetGatewayId |cut -d'"' -f 4)"

routetableid="$(aws ec2 describe-route-tables | grep RouteTableId | cut -d'"' -f 4 | head -1)"


echo "ATTACHING INTERNETGATEWAY TO VPC"

ec2-attach-internet-gateway $internetgateway --region us-west-2 -c $vpcid --aws-access-key $awsaccesskey --aws-secret-key $awsseceretkey

echo "CREATING ROUTE"

aws ec2 create-route --region us-west-2 --route-table-id $routetableid --destination-cidr-block 0.0.0.0/0 --gateway-id $internetgateway

echo "AllocatING IP address"

aws ec2 allocate-address

sleep 2m

publicip="$(aws ec2 describe-addresses |grep  PublicIp | cut -d'"' -f 4)"
allocationid="$(aws ec2 describe-addresses |grep  AllocationId | cut -d'"' -f 4)"

echo "CREATING AN INSTANCE"

ec2-run-instances ami-9abea4fb -t t2.micro --region us-west-2  -s $subnetid -k MyKeyPair --aws-access-key $awsaccesskey  --aws-secret-key $awsseceretkey

sleep 2m

instanceid="$(aws ec2 describe-instances | grep  InstanceId | cut -d'"' -f 4)"

echo "ASSOCIATING PUBLIC IP TO INSTANCE"

aws ec2 associate-address --instance-id $instanceid --allocation-id $allocationid




