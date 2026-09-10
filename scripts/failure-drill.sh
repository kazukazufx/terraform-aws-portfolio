#!/usr/bin/env bash
set -euo pipefail

cluster="${ECS_CLUSTER:-terraform-aws-portfolio-dev}"
service="${ECS_SERVICE:-terraform-aws-portfolio-dev}"
region="${AWS_REGION:-ap-northeast-1}"

if [[ "${CONFIRM:-}" != "stop-one-ecs-task" ]]; then
  echo "No task was stopped. Set CONFIRM=stop-one-ecs-task after checking the AWS account, region, cluster, and service."
  exit 2
fi

aws sts get-caller-identity

task_arn="$(aws ecs list-tasks \
  --region "${region}" \
  --cluster "${cluster}" \
  --service-name "${service}" \
  --desired-status RUNNING \
  --query 'taskArns[0]' \
  --output text)"

if [[ -z "${task_arn}" || "${task_arn}" == "None" ]]; then
  echo "No running ECS task was found."
  exit 1
fi

echo "Stopping one task for the recovery drill: ${task_arn}"
aws ecs stop-task \
  --region "${region}" \
  --cluster "${cluster}" \
  --task "${task_arn}" \
  --reason "Portfolio recovery drill"

echo "Waiting for ECS Service to return to a stable state..."
aws ecs wait services-stable \
  --region "${region}" \
  --cluster "${cluster}" \
  --services "${service}"

aws ecs describe-services \
  --region "${region}" \
  --cluster "${cluster}" \
  --services "${service}" \
  --query 'services[0].{running:runningCount,desired:desiredCount,pending:pendingCount,events:events[0:5]}'
