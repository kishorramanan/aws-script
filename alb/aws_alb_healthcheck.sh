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

#ALB Name CHECK
CHK_ALB_NAME=`$AWSCLI --profile $PROFILE \
	elbv2 describe-load-balancers \
	--name=$ALB_NAME \
	--query 'LoadBalancers[].[LoadBalancerName]'\
	--output text \
	`

if [ -z $CHK_ALB_NAME ] ; then
  echo "ALB Name \"$ALB_NAME\" is not found"
  exit 1
fi

#Get ALB ARN
GET_ALB_ARN=`$AWSCLI --profile $PROFILE \
	elbv2 describe-load-balancers \
	--name=$ALB_NAME \
	--query 'LoadBalancers[].[LoadBalancerArn]' \
	--output text \
	`
#echo GET_ALB_ARN
#echo $GET_ALB_ARN

#Get Listner ARN
GET_LISTER_ARN=`$AWSCLI --profile $PROFILE \
	elbv2 describe-listeners \
	--load-balancer-arn=$GET_ALB_ARN \
	--query 'Listeners[].ListenerArn' \
	--output text \
	`

#echo GET_LISTER_ARN
#echo $GET_LISTER_ARN

#GET_TARTGET_GROUP_ARN=`$AWSCLI --profile $PROFILE \
#	elbv2 describe-rules \
#	--listener-arn $GET_LISTER_ARN \
#	--query 'Rules[].Actions[].TargetGroupArn' \
#	--output text \
#	`

GET_PRIORITY_TARTGET_GROUP_ARN=`$AWSCLI --profile $PROFILE \
	elbv2 describe-rules \
	--listener-arn $GET_LISTER_ARN \
	--query 'Rules[].[Priority,Actions[].TargetGroupArn]' \
	--output text \
	`

    echo "- ALB NAME \"$ALB_NAME\" "

#Target Group host list get
for VALUE in ${GET_PRIORITY_TARTGET_GROUP_ARN[@]}
do

  #PRIORYTY or ARN CHECK
  if [[ "$VALUE" =~ ^arn* ]]; then
    TARTGET_GROUP_ARN=$VALUE

  else
    PRIORITY=$VALUE
    continue
  fi

    #Target Group name
    TARGET_GROUP_NAME=`sed 's%^.*:.*/\(.*\)\.*/.*%\1%' <<< $TARTGET_GROUP_ARN`

    #表示タイトル
    echo "-- ALB TARGET GROUP \"$TARGET_GROUP_NAME\" INSTANCE HEALTH STATUS( name , id , status) "
    echo "-- PRIORITY : $PRIORITY "

#echo TARGET_GEOUP_NAME
#echo $TARGET_GROUP_NAME

    #スペース、改行でも区切られないように
    IFS_BACKUP=$IFS
    IFS=$'\n'

    #Target Group instance Tag Name Get
    for INSTANCE in `$AWSCLI --profile $PROFILE \
	elbv2 describe-target-health \
	--target-group-arn $TARTGET_GROUP_ARN \
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
    #各表示
    echo "$INSTANCE_NAME , $INSTANCE_ID , $INSTANCE_STATE"

    done

    IFS=$IFS_BACKUP
done

exit 0
