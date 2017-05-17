#/bin/bash

# Argument
# $1:Profile
# $2:ALB name

PROFILE=$1
ALB_NAME=$2

#COMAND
AWSCLI="/usr/bin/aws"

#echo $PROFILE
#echo $ALB_NAME

#CHECK
if [ $# -ne 2 ] ; then
  echo "Missing Argument"
  echo 'Usage: ./aws_alb_healthcheck.sh Profile ALBName'
  exit 1
fi

#Get ALB ARN
GET_ALB_ARN=`$AWSCLI --profile $PROFILE \
	elbv2 describe-load-balancers \
	--query 'LoadBalancers[].[LoadBalancerName,LoadBalancerArn]' \
	--output text \
	| grep "^$ALB_NAME\s" \
	| cut -f2 \
	`
#echo GET_ALB_ARN
#echo $GET_ALB_ARN

#Get Target GROUP
GET_TARTGET_GROUP_ARN=`$AWSCLI --profile $PROFILE \
	elbv2 describe-listeners \
	--load-balancer-arn $GET_ALB_ARN \
	--query 'Listeners[].DefaultActions[].TargetGroupArn' \
	--output text \
	`

    echo "- ALB NAME \"$ALB_NAME\" "
#echo GET_TARTGET_GROUP_ARN
#echo $GET_TARTGET_GROUP_ARN

#Target Group host list get
for TARTGET_GROUP_ARN in ${GET_TARTGET_GROUP_ARN[@]}
do
  #Target Group name
  TARGET_GROUP_NAME=`sed 's%^.*:.*/\(.*\)\.*/.*%\1%' <<< $TARTGET_GROUP_ARN`


    #表示タイトル
    echo "-- ALB TARGET GROUP \"$TARGET_GROUP_NAME\" INSTANCE HEALTH STATUS( name , id , status) "
#echo TARGET_GEOUP_NAME
#echo $TARGET_GEOUP_NAME

    #スペース、改行でも区切られないように
    IFS_BACKUP=$IFS
    IFS=$'\n'

    #Target Group instance Tag Name Get
    for INSTANCE in `$AWSCLI --profile $PROFILE \
	elbv2 describe-target-health \
	--target-group-arn $GET_TARTGET_GROUP_ARN \
	--query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' \
	--output text \
	`
    do

    #Instance_ID,STATE,NAME
    INSTANCE_ID=`echo $INSTANCE | cut -f1`
    INSTANCE_STATE=`echo $INSTANCE | cut -f2`
    INSTANCE_NAME=`$AWSCLI --profile $PROFILE \
	ec2 describe-tags \
	--filters "Name=resource-id,Values=$INSTANCE_ID" "Name=tag-key,Values=Name" \
	--query "Tags[].Value" \
	--output text \
	`

#echo INSTANCE
#echo $INSTANCE
#echo ID
#echo $INSTANCE_ID
#echo STATE
#echo $INSTANCE_STATE
#echo NAME
#echo $INSTANCE_NAME

    #各表示
    echo "$INSTANCE_NAME , $INSTANCE_ID , $INSTANCE_STATE"

    done

    IFS=$IFS_BACKUP
done

exit 0
