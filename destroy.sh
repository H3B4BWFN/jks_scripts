#!/bin/bash

vpc=$1

ROUND=0
echo "Attemping to delete VPC ${vpc}..."

aws ec2 delete-vpc --vpc-id $vpc 2>/dev/null
while [ $? -ne 0 ]
do

echo "ROUND [${ROUND}] FAIL"
for A in $(aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep InternetGatewayId | cut -d'"' -f4); do aws ec2 detach-internet-gateway --vpc-id $vpc --internet-gateway-id $A 2>/dev/null; done;

aws ec2 delete-internet-gateway --internet-gateway-id $A 2>/dev/null;

for A in $(aws ec2 describe-subnets --filters 'Name=vpc-id,Values='$vpc | grep SubnetId | cut -d'"' -f4); do aws ec2 delete-subnet --subnet-id $A >/dev/null 2>&1; done;

for A in $(aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$vpc | grep RouteTableAssociationId | cut -d'"' -f4); do aws ec2 disassociate-route-table --association-id $A >/dev/null 2>&1; done;

for A in $(aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$vpc | grep RouteTableId | cut -d'"' -f4); do aws ec2 delete-route-table --route-table-id $A >/dev/null 2>&1; done;

for A in $(aws ec2 describe-network-acls --filters 'Name=vpc-id,Values='$vpc | grep NetworkAclId | cut -d'"' -f4); do aws ec2 delete-network-acl --network-acl-id $A >/dev/null 2>&1; done;

for A in $(aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$vpc | grep NatGatewayId | cut -d'"' -f4); do aws ec2 delete-nat-gateway --nat-gateway-id $A >/dev/null 2>&1; done;

for A in $(aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$vpc | grep AllocationId | cut -d'"' -f4); do aws ec2 release-address --allocation-id $A >/dev/null 2>&1; done;

for A in $(aws ec2 describe-security-groups --filters 'Name=vpc-id,Values='$vpc | grep GroupId | cut -d'"' -f4); do aws ec2 delete-security-group --group-id $A >/dev/null 2>&1; done;

for A in $(aws ec2 describe-instances --filters 'Name=vpc-id,Values='$vpc | grep InstanceId | cut -d'"' -f4); do aws ec2 terminate-instances --instance-ids $A >/dev/null 2>&1; done;

ROUND=$(( $ROUND + 1 ))
sleep 5

aws ec2 delete-vpc --vpc-id $vpc 2>/dev/null;
done

echo "ROUND [${ROUND}] SUCCESS";
