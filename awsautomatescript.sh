#/bin/bash


echo "CREATING VPC"

aws ec2 create-vpc --cidr-block 10.0.0.0/16 

# Selecting vpcid from the vpc-describe and assign this value to a variable

	export vpcid="$(aws ec2 describe-vpcs |grep vpc | cut -d'"' -f 4)"

echo "CREATING SUBNET"

aws ec2 create-subnet --vpc-id $vpcid --cidr-block 10.0.1.0/24

export subnetid="$(aws ec2 describe-subnets | grep SubnetId | cut -d'"' -f 4)"

echo "CREATING SECURITY GROUP"
aws ec2 create-security-group --vpc-id $vpcid --group-name MySecurityGroup --description "My security group" 

export securitygroupid="$(aws ec2 describe-security-groups | grep GroupId | cut -d'"' -f 4 | head -1)"
#export securitygroup2="$(aws ec2 describe-security-groups | grep GroupId | cut -d'"' -f 4 | xargs -n1 | sort -u |tail -1)


echo "ADDING RULE TO SECURITY GATEWAY"
aws ec2 authorize-security-group-ingress --group-id $securitygroupid --protocol tcp --port  80 --cidr 0.0.0.0/0

echo "ADDING RULE TO SECURITY GATEWAY"
aws ec2 authorize-security-group-ingress --group-id $securitygroupid --protocol tcp --port 22 --cidr 101.98.14.209/29

#echo "ADDING RULE TO SECURITY GATEWAY"
#aws ec2 authorize-security-group-ingress --group-id $securitygroup2 --protocol tcp --port  80 --cidr 0.0.0.0/0

#echo "ADDING RULE TO SECURITY GATEWAY"
#aws ec2 authorize-security-group-ingress --group-id $securitygroup2 --protocol tcp --port  22  --cidr 101.98.14.209/29

echo "CREATING INTERNETGATEWAY"
aws ec2 create-internet-gateway

	export awsaccesskey="$(less .aws/credentials | grep aws_access_key | cut -d'=' -f 2)"		
	export awsseceretkey="$(less .aws/credentials | grep aws_secre | cut -d'=' -f 2)"
	export internetgateway="$(aws ec2 describe-internet-gateways | grep InternetGatewayId |cut -d'"' -f 4)"
	export routetableid="$(aws ec2 describe-route-tables | grep RouteTableId | cut -d'"' -f 4 | head -1)"


echo "ATTACHING INTERNETGATEWAY TO VPC"
ec2-attach-internet-gateway $internetgateway --region us-west-2 -c $vpcid --aws-access-key $awsaccesskey --aws-secret-key $awsseceretkey

echo "CREATING ROUTE"
aws ec2 create-route --region us-west-2 --route-table-id $routetableid --destination-cidr-block 0.0.0.0/0 --gateway-id $internetgateway

#echo "AllocatING IP address"

#aws ec2 allocate-address

#sleep 1m

#publicip="$(aws ec2 describe-addresses |grep  PublicIp | cut -d'"' -f 4)"
#allocationid="$(aws ec2 describe-addresses |grep  AllocationId | cut -d'"' -f 4)"

echo "CREATING AN INSTANCE"
ec2-run-instances ami-02a24162 -t t2.micro --region us-west-2 --associate-public-ip-address true -p arn:aws:iam::124998388760:instance-profile/ecsInstanceRole  -s $subnetid -k MyKeyPair --aws-access-key $awsaccesskey  --aws-secret-key $awsseceretkey

sleep 1m

export instanceid="$(aws ec2 describe-instances | grep  InstanceId | cut -d'"' -f 4)"


#echo  "TERMINATING EC2 INSTANCE"

#aws ec2 terminate-instances --instance-ids $instanceid

#echo "DELETING VPC"
#aws ec2 delete-vpc --vpc-id $vpcid






#echo "ASSOCIATING PUBLIC IP TO INSTANCE"

#aws ec2 associate-address --instance-id $instanceid --allocation-id $allocationid


echo PLEASE WAIT INSTANCE IS INTIALISING............................
sleep 1m

echo "CREATING LOAD BALANCER"
aws elb create-load-balancer --load-balancer-name my-load-balancer --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --subnets $subnetid --security-groups $securitygroupid


#REGISTERING A TASK DEFINATION

echo "Registering Task Definition"
aws ecs register-task-definition --family webserver --container-definitions "[{\"name\":\"WebContainer\",\"image\":\"124998388760.dkr.ecr.us-west-2.amazonaws.com/containers:latest\",\"cpu\":10,\"memory\":500,\"essential\":true}]"

echo "CREATING TASK"
#aws ecs run-task --cluster default --task-definition webserver:9

echo ""
