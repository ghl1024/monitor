#/usr/bin/bash

STATUS=-1

HOSTS=('XX.X.X.X' 'X.X.X.X')
CMDS=('ls ~','touch aaa','mv aaa bbb','cat bbb','ps -elf','lsof -a', 'netstat -anp')

prepare()
{
    yum install -y expect
}


check_status()
{
    cmd=time -o $1
     
}

login()
{
    user="XXXXXXXXXXXXXXX"
    password="XXXXXXXXXXXXXXX"
    expect -c "
    set host $1
    spawn ssh $user@$host
    expect {
       \"*password:\" {set timeout 300; send $password;}
       \"yes/no\" {send \"yes\r\"; exp_continue;}
    }
    "
}
doit()
{
    for host in ${HOSTS[@]};
    do 
        printf "$host"
        login host CMDS
        for cmd in CMDS:
        do 
            check_status cmd
        done
    done
}

prepare
doit
