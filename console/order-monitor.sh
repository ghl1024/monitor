#!/bin/bash
readonly TIMESEC="200"
mess_create="Apply complete! Resources: 1 added, 0 changed, 0 destroyed."
mess_destory="Apply complete! Resources: 0 added, 0 changed, 1 destroyed."

function check_order
{
    cd /monitor/terraform-order && cp order order.tf
    mess_create_result=$(timeout $TIMESEC terraform apply -auto-approve 2>&1|grep -c "$mess_create")

    for((i=1;i<=10;i++));
    do
        echo "forxxxxxxxxxxxx"
        ping -c 2 10.0.192.192

        if [ "$?" -eq 0 ];then
             create_status=0
             break
        else
             create_status=1
        fi
        sleep 2
    done


    cd /monitor/terraform-order && rm -f order.tf
    mess_destory_result=$(timeout $TIMESEC terraform apply -auto-approve 2>&1|grep -c "$mess_destory")

    for((i=1;i<=10;i++));
    do
        echo "forxxxxxxxxxxxx"
        ping -c 2 10.0.192.192

        if [ "$?" -ne 0 ];then
             destory_status=0
             break
        else
             destory_status=1
        fi
        sleep 2
    done

    if [ "$mess_create_result" -eq 1 -a "$create_status" -eq 0  ];then
         echo "create_ok"
    else
         echo "create_error"
    fi
}


function main
{
    check_order
}

main
