#!/bin/bash
#定义的是命令执行的超时时间
readonly TIMESEC="30"
readonly URL="XXXX"
#将输出结果默认赋值
result="-1"
s3_monitor_status="-1"
MD5="71cfb9febe321ad91f0d58e1c2c50e46  -"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch s3_monitor.prom && chmod 755 s3_monitor.prom
}

#通过云存储的接口获取指定文件的内容并和预先定义的内容进行比对
#为什么不考虑使用wget，wget和curl的区别是什么
#需要对curl/wget的参数进行详细的理解和学习
function check_result
{
    local start=$(date +%s%N)
    result=$(timeout $TIMESEC curl -s $URL|md5sum)
    local end=$(date +%s%N)
    local cost=$[$end-$start]

    if [ "$result"=="$MD5" ];then
        cd /var/lib/node_exporter/textfile && echo -e "s3_monitor_status 0\ns3_read_cost $cost" > s3_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo -e "s3_monitor_status 1\ns3_read_cost $cost" > s3_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
