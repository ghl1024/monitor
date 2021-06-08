#!/bin/bash
#set -x
#set encoding=utf-8

#使用说明：
#默认情况下，仅需要修改SERVER、PORT、PASSWORD的值，即可执行脚本进行对mysql服务的可用性监控


readonly SERVER="XXXXX"
readonly PASSWORD="XXXXX"
readonly USER="XXXXXX"
readonly DATABASE="XXXX"
readonly localhost=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

#key的定义要尽量复杂，避免和业务的key冲突了
#定义的是监控key的失效时间
readonly TTL="60"
readonly COMMAND="mysql"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

#将输出结果默认赋值
#result="-1"
insert_status="-1"
select_status="-1"
mysql_status="-1"

#判断是否安装了mysql-cli工具，如果没有安装则先安装完毕
#安装mysql-cli工具，需要先安装epel源才可以
function check_tools
{
    if [ ! -f /usr/bin/mysql-cli ];then
        nohup yum install -y epel-release >/dev/null 2>&1
        nohup yum install -y mysql >/dev/null 2>&1
    fi

    mkdir -p  /var/lib/node_exporter/textfile 
    cd /var/lib/node_exporter/textfile && touch mysql_monitor.prom && chmod 755 mysql_monitor.prom
}

# 往mysql中添加一个key，并设置key的过期时间较短
# 设置过期时间的目的是，避免服务异常不能写入而无法发现
# 增加timeout命令，限制执行时间，避免超时卡死
# 不关注命令执行的返回值，没有任何意义，需要通过获取key:value来判断才更合理
function mysql_insert
{
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -u $USER -p$PASSWORD -D$DATABASE -e "insert into test (host) values ('$localhost')")
    echo $?
}

# 从mysql中读取一个key
# 增加timeout命令，限制执行时间，避免超时卡死
# 取出一个key之后不能直接删除这个key，通过过期时间删除即可，防止del掉这个key的时候，各种异常导致误删除业务上的key
function mysql_select
{
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -u $USER -p$PASSWORD -D$DATABASE -s -e "select time from test where host='$localhost';")
    echo $result
}

function mysql_delete
{
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -u $USER -p$PASSWORD -D$DATABASE -e "delete from test where host='$localhost';")
    echo "$?"
}
#对获取的value和预先定义好的value进行对比，判断mysql是否正常
function check_result
{
    if [ -z "$*"]; then
        echo 1
        #cd /var/lib/node_exporter/textfile && echo "mysql_monitor_status 0" > mysql_monitor.prom
    else
        echo 0
        #cd /var/lib/node_exporter/textfile && echo "mysql_monitor_status 1" > mysql_monitor.prom
    fi
}


function main
{  
    content=""
    check_tools
    metric="mysql_monitor_insert{target=\"$SERVER\",region=\"XXXX\"}"
    local start=$(date +%s%N)
    insert_status=$(mysql_insert)
    local end=$(date +%s%N)
    local cost=$[$end-$start]
    #insert_status=$(check_result)
    content="$content$metric $insert_status\nmysql_insert_cost{target=\"$SERVER\",region=\"XXXX\"} $cost\n"
    
    metric="mysql_monitor_select{target=\"$SERVER\",region=\"cn-east-2\"}"
    local start=$(date +%s%N)
    select_status=$(mysql_select)
    local end=$(date +%s%N)
    local cost=$[$end-$start]
    select_status=$(check_result $select_status)
    content="$content$metric $select_status\nmysql_select_cost{target=\"$SERVER\",region=\"XXXX\"} $cost\n"
    
    metric="mysql_monitor_status{target=\"$SERVER\",region=\"XXXX\"}"
    mysql_status=$insert_status&&$select_status
    content="$content$metric $mysql_status\n"
    cd /var/lib/node_exporter/textfile && echo -e $content > mysql_monitor.prom
    
    mysql_delete 
}

main
