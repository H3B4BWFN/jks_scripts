#!/bin/bash

## Création du VPC
VPCID=$(aws ec2 create-vpc --cidr-block "10.0.0.0/16" | grep '"VpcId":' | cut -d'"' -f4)

## Création du subnet public
SUBNET_PUBLIC=$(aws ec2 create-subnet --cidr-block "10.0.0.0/24" --vpc-id ${VPCID} | grep '"SubnetId":' | cut -d'"' -f4)

## Change le parametre du subnet public => Associer une IP publique par défaut
A=$(aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id ${SUBNET_PUBLIC})

## Création du subnet privé
SUBNET_PRIVATE=$(aws ec2 create-subnet --cidr-block "10.0.1.0/24" --vpc-id ${VPCID} | grep '"SubnetId":' | cut -d'"' -f4)

## Création de l'Internet Gateway
IGW=$(aws ec2 create-internet-gateway | grep '"InternetGatewayId":' | cut -d'"' -f4)

## Attacher l'Internet Gateway au VPC
A=$(aws ec2 attach-internet-gateway --internet-gateway-id ${IGW} --vpc-id ${VPCID})

## Création de la table de routage publique
ROUTETABLEPUBLIC=$(aws ec2 create-route-table --vpc-id ${VPCID} | grep '"RouteTableId":' | cut -d'"' -f4)

sleep 5

## Ajout d'une route par défaut dans la table de routage publique
A=$(aws ec2 create-route --route-table-id ${ROUTETABLEPUBLIC} --destination-cidr-block "0.0.0.0/0" --gateway-id ${IGW})

## Association de la route table publique et du subnet
A=$(aws ec2 associate-route-table --route-table-id ${ROUTETABLEPUBLIC} --subnet-id ${SUBNET_PUBLIC})

## eipalloc-093c2a84172e00c0c => IP publique pour la NAT gateway
EIP=$(aws ec2 allocate-address | grep '"AllocationId":' | cut -d'"' -f4)

## Création de la NAT Gateway
NATGW=$(aws ec2 create-nat-gateway --allocation-id ${EIP} --subnet-id ${SUBNET_PUBLIC} | grep '"NatGatewayId":' | cut -d'"' -f4)

sleep 5

## Création de la table de routage privée
ROUTETABLEPRIVATE=$(aws ec2 create-route-table --vpc-id ${VPCID} | grep '"RouteTableId":' | cut -d'"' -f4)

sleep 5

## Ajoute d'une route par défaut dans la table de routage privée
A=$(aws ec2 create-route --route-table-id ${ROUTETABLEPRIVATE} --destination-cidr-block "0.0.0.0/0" --nat-gateway-id ${NATGW})

## Association de la route table private et du subnet
A=$(aws ec2 associate-route-table --route-table-id ${ROUTETABLEPRIVATE} --subnet-id ${SUBNET_PRIVATE})

## Création du Security Group Public
SG_PUB=$(aws ec2 create-security-group --vpc-id ${VPCID} --description "SG-PUBLIC" --group-name "SG-PUBLIC" | grep 'GroupId' | cut -d'"' -f4)

## Création du Security Group Privé
SG_PRIV=$(aws ec2 create-security-group --vpc-id ${VPCID} --description "SG-PRIVATE" --group-name "SG-PRIVATE" | grep 'GroupId' | cut -d'"' -f4)

## Authorisation SSH pour instance publique
A=$(aws ec2 authorize-security-group-ingress --group-id ${SG_PUB} --protocol "tcp" --port "22" --cidr "0.0.0.0/0")

## Authorisation SSH pour instance privée
A=$(aws ec2 authorize-security-group-ingress --group-id ${SG_PRIV} --protocol "tcp" --port "22" --source-group ${SG_PUB})

## Création instance publique
A=$(aws ec2 run-instances --subnet-id ${SUBNET_PUBLIC} --image-id ami-0f15e0a4c8d3ee5fe --instance-type t2.micro --key-name "test_keypair" --security-group-ids ${SG_PUB})

## Création instance privée
A=$(aws ec2 run-instances --subnet-id ${SUBNET_PRIVATE} --image-id ami-0f15e0a4c8d3ee5fe --instance-type t2.micro --key-name "test_keypair" --security-group-ids ${SG_PRIV})

echo "Created Elements in vpc ${VPCID}"
