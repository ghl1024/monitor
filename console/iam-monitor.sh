#!/bin/bash
#定义的是命令执行的超时时间
readonly TIMESEC="30"
#将输出结果默认赋值
result="-1"
count=0
s3_mess="BucketAlreadyExists"
rds_mess="Monitor1234"
vpc_mess="CONFLICT"
instance_mess="PrimaryIpAddress"
#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch console_monitor.prom && chmod 755 console_monitor.prom
}

#通过云存储的接口获取指定文件的内容并和预先定义的内容进行比对
function check_result
{
    cd /monitor/terraform
    local start=$(date +%s%N)
    result=$( timeout $TIMESEC terraform apply -auto-approve 2>&1)
    result_s3=$(echo $result|grep -c $s3_mess)
    result_rds=$(echo $result|grep -c $rds_mess)
    result_vpc=$(echo $result|grep -c $vpc_mess)
    result_instance=$(echo $result|grep -c $instance_mess)
    local end=$(date +%s%N)
    local cost=$[$end-$start]

    if [ "$result_s3" -eq 1 ];then
        cd /var/lib/node_exporter/textfile && echo -e "iam_s3_monitor_status 0" > console_monitor.prom
        count=$((count + 1 ))
    else
        cd /var/lib/node_exporter/textfile && echo -e "iam_s3_monitor_status 1" > console_monitor.prom
    fi

    if [ "$result_rds" -eq 1 ];then
        cd /var/lib/node_exporter/textfile && echo -e "iam_rds_monitor_status 0" >> console_monitor.prom
        count=$((count + 1 ))
    else
        cd /var/lib/node_exporter/textfile && echo -e "iam_rds_monitor_status 1" >> console_monitor.prom
    fi

    if [ "$result_vpc" -eq 1 ];then
        cd /var/lib/node_exporter/textfile && echo -e "iam_vpc_monitor_status 0" >> console_monitor.prom
        count=$((count + 1 ))
    else
        cd /var/lib/node_exporter/textfile && echo -e "iam_vpc_monitor_status 1" >> console_monitor.prom
    fi

    if [ "$result_instance" -eq 1 ];then
        cd /var/lib/node_exporter/textfile && echo -e "iam_instance_monitor_status 0" >> console_monitor.prom
        count=$((count + 1 ))
    else
        cd /var/lib/node_exporter/textfile && echo -e "iam_instance_monitor_status 1" >> console_monitor.prom
    fi

    if [ "$count" -gt 2 ];then
        cd /var/lib/node_exporter/textfile && echo -e "iam_monitor_status 0\niam_read_cost $cost" >> console_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo -e "iam_monitor_status 1\niam_read_cost $cost" >> console_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
