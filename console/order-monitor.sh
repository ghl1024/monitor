#!/bin/bash
readonly TIMESEC="200"
readonly SERVER="10.0.192.192"
mess_create="Apply complete! Resources: 1 added, 0 changed, 0 destroyed."
mess_destory="Apply complete! Resources: 0 added, 0 changed, 1 destroyed."

function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch order_monitor.prom && chmod 755 order_monitor.prom
}

function check_order
{
    #order文件是模板文件，但是取消后缀，在使用的时候，进行复制后使用
    cd /monitor/terraform-order && cp order order.tf
    timeout $TIMESEC terraform init
    #通过terraform发起创建云主机的操作，然后从返回的内容中grep是否有$mess_create的内容来判断创建是否成功
    local start=$(date +%s%N)
    mess_create_result=$(timeout $TIMESEC terraform apply -auto-approve 2>&1|grep -c "$mess_create")
    local end=$(date +%s%N)
    local cost=$[$end-$start]
    
    #当云主机创建成功后，因为IP地址是预设的，因此会通过ping命令二次确认是否真实创建完毕
    #之前是sleep 30秒然后Ping，但是这样耗时太久，所以放在了for循环中，减少常态的执行时间，因为每次超时大概需要2s，因此15次循环也到了30s
    for((i=1;i<=15;i++));
    do
        ping -c 2 $SERVER

        if [ "$?" -eq 0 ];then
             create_status=0
             break
        else
             create_status=1
        fi
        sleep 2
    done

    #创建完毕检查后，就可以进行销毁了，因此需要删除tf文件
    cd /monitor/terraform-order && rm -f order.tf
    mess_destory_result=$(timeout $TIMESEC terraform apply -auto-approve 2>&1|grep -c "$mess_destory")

    #删除后，同样需要检查是否真的删除成功，因此还是需要Ping一下
    for((i=1;i<=15;i++));
    do
        ping -c 2 $SERVER

        if [ "$?" -ne 0 ];then
             destory_status=0
             break
        else
             destory_status=1
        fi
        sleep 2
    done

    #判断成功与否的方法：1，需要terraform返回内容是符合预期的，2，需要ping能够通 两者都OK才能视为创建成功
    if [ "$mess_create_result" -eq 1 -a "$create_status" -eq 0  -a "$destory_status" -eq 0 ];then
         cd /var/lib/node_exporter/textfile && echo -e "order_monitor_status 0\norder_read_cost $cost" > order_monitor.prom
    else
         cd /var/lib/node_exporter/textfile && echo -e "order_monitor_status 1\norder_read_cost $cost" > order_monitor.prom
    fi
    

    
}


function main
{
    check_order
}

main
