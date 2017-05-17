#/bin/bash

# Argument
# $1:Profile
# $2:Target Group Name
# $3:instance Name

PROFILE=$1
TARGET_GROUP_NAME=$2
INSTANCE_NAME=$3

#COMAND
AWSCLI="/usr/bin/aws"

echo $PROFILE
echo $TARGET_GROUP_NAME
echo $INSTANCE_NAME

#CHECK
if [ $# -ne 3 ] ; then
  echo "Missing Argument"
  echo 'Usage: ./aws_alb_instance_remove_tg.sh Profile TargetName InstanceName'
  exit 1
fi

#Get Target Group ARN
TARGET_GROUP_ARN=`$AWSCLI --profile $PROFILE \
	elbv2 describe-target-groups \
	--query 'TargetGroups[].[TargetGroupName,TargetGroupArn]' \
	--output text \
	| grep "^$TARGET_GROUP_NAME\s" \
	| cut -f2 \
	`
echo Targer Group Name
echo $TARGET_GROUP_ARN

#Targer Group Name がない場合エラー
if [ -z $TARGET_GROUP_ARN ] ; then
  echo "Target Group \"$TARGET_GROUP_NAME\" is not found"
  exit 1
fi

#Name=InstanceID桁数チェック
if [[ "$INSTANCE_NAME" =~ ^i-[0-9a-f]{17}$ ]]; then
  TARGET_INSTANCE_ID=$INSTANCE_NAME
else
  TARGET_INSTANCE_ID=`$AWSCLI --profile $PROFILE \
	ec2 describe-instances \
	--filters "Name=tag-key,Values=Name" "Name=tag-value,Values=$INSTANCE_NAME" \
	--query 'Reservations[].Instances[].InstanceId' \
	--output text \
	`
fi

#Instance Nameなかったらエラー
if [ -z $TARGET_INSTANCE_ID ] ; then
    echo "Instance Name \"$INSTANCE_NAME\" is not found"
    exit 1
fi

echo TARGET_INSTANCE_ID
echo $TARGET_INSTANCE_ID

#Taget Groupから削除
DEREGISTER_RES=`$AWSCLI --profile $PROFILE \
	elbv2 deregister-targets \
	--target-group-arn $TARGET_GROUP_ARN \
	--targets Id=$TARGET_INSTANCE_ID \
	`
#echo $DEREGISTER_RES

exit 0


