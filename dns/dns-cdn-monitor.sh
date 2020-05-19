#!/bin/bash
readonly DOMAIN="monitor.site7x24.net.cn"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

readonly COMMAND="dig"

HOSTVALUE=$(date +%M|sed -r 's/0*([0-9])/\1/')

Domainlist=(223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 119.29.29.29 119.28.28.28 182.254.116.116 180.76.76.76 1.2.4.8)

#将输出结果默认赋值
result="-1"
cost="0"


#检查输出到prometheus的目录和文件是否存在，以及权限是否正确
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch dnsplus_monitor.prom && chmod 755 dnsplus_monitor.prom && echo >dns_cdn_monitor.prom
}

#对获取的value和预先定义好的value进行对比，判断结果是否正常
function check_result
{   
    for i in ${Domainlist[@]};do
        local start=$(date +%s%N)
        result=$(timeout $TIMESEC $COMMAND $DOMAIN @"$i" +short|grep -v c|head -n 1|cut -d "." -f4)
        local end=$(date +%s%N)
        local timecost=$((end-start))


	    #如果result有结果且结果是数字的话，则进行下面的处理；避免result没有获取到结果就参与计算，导致误报
	    if [ "$result" -ge 0 ];then
	        if [ "$HOSTVALUE" -ge "$result" ];then
	            cost=$((HOSTVALUE - result ))
	        else
	        #对于跨周期的情况，实际时间会小于dns的结果，因此需要加一个60的周期进行补偿
	            cost=$((HOSTVALUE + 60 - result ))
	        fi
		cd /var/lib/node_exporter/textfile
		echo -e "dns_cdn_monitor_status_$i 0\ndns_cdn_monitor_cost_$i $cost\ndns_cdn_monitor_time $timecost" >> dns_cdn_monitor.prom

	    else
	        cd /var/lib/node_exporter/textfile
	        echo -e "dnsplus_monitor_status_$i -1\ndnsplus_monitor_cost_$i  -1"  >> dns_cdn_monitor.prom
	    fi
    done
}

function main
{
    check_prometheus
    check_result  
}

main 
