#!/bin/bash
#定义的是命令执行的超时时间
readonly TIMESEC="20"
#将输出结果默认赋值
result="-1"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch iam_monitor.prom && chmod 755 iam_monitor.prom
}

#通过terraform创建一个S3的bucket，来间接验证IAM的可用性，当然会受到S3可用性的影响
function check_result
{
    cd /monitor/terraform
    local start=$(date +%s)
    result=$( timeout $TIMESEC terraform apply -auto-approve 2>&1|grep -c BucketAlreadyExists)
    local end=$(date +%s)
    local cost=$[$end-$start]

    if [ "$result" -eq 1 ];then
        cd /var/lib/node_exporter/textfile && echo -e "iam_monitor_status 0\niam_read_cost $cost" > iam_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo -e "iam_monitor_status 1\niam_read_cost $cost" > iam_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
