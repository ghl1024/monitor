package main

import (
        "os"
	"fmt"
//        "time"
  	. "github.com/jdcloud-api/jdcloud-sdk-go/services/domainservice/apis"
  	. "github.com/jdcloud-api/jdcloud-sdk-go/services/domainservice/models"
	. "github.com/jdcloud-api/jdcloud-sdk-go/services/domainservice/client"
	. "github.com/jdcloud-api/jdcloud-sdk-go/core"
)

func initDNSClient() *DomainserviceClient{
	// 申请到的AKSK, 下面的例子是以系统用户为例
	accessKey := "XXXXXXXXXXXXXXX"
        secretKey := "XXXXXXXXXXXXXXX"

	credentials := NewCredentials(accessKey, secretKey)

	config := NewConfig()
	config.SetScheme(SchemeHttp)
	// 云网关Endpoint
	config.SetEndpoint("domainservice.jdcloud-api.com")

	client := NewDomainserviceClient(credentials)
	client.SetConfig(config)
	return client
}

func GetDomains() {
    // 初始化
	client := initDNSClient()
	// 请求赋值
	req := NewDescribeDomainsRequest("cn-north-1", 1, 10)
       //	req.AddHeader("x-jdcloud-pin", "bnustu")
	
	// 做请求
	resp, err := client.DescribeDomains(req)
	// 输出结果
	if err != nil {
        client.Logger.Log(1, "err ->", err.Error())
	} else {
		if resp.Error.Code != 0 {
			fmt.Println("Error: ", resp.Error.Status, resp.Error.Message, resp.Error.Code)
		} else {
			fmt.Println(resp)
		}
	}
}


func ModifyRR(hostvalue string) {
	//初始化
	client := initDNSClient()
	//req := apis.NewAddRRRequest("cn-north-1", "199", rr)
        //hours, minutes, _ := time.Now().Clock()
        //currUTMinString := fmt.Sprintf("%d", minutes) 
        //hostvalue =   
       	rr := &UpdateRR{
                DomainName: "XXXXXX",
        	/* 主机记录  */
        	HostRecord: "XXXX",
        	/* 解析记录的值  */
        	HostValue: hostvalue,
        	/* 解析记录的生存时间  */
        	Ttl: 600,
        	/* 解析的类型  */
        	Type: "X",
        	/* 解析线路的ID，请调用getViewTree接口获取解析线路的ID。  */
        	ViewValue: X,
    	} 
        req := NewModifyResourceRecordRequest("XXXX", "XXXX", "XXXX", rr )
        //req := NewDescribeViewTreeRequest("XXXX", "XXXX", XX, XX)	
	// 做请求
	resp, err := client.ModifyResourceRecord(req)
	//resp, err := client.DescribeViewTree(req)
	// 输出结果
	if err != nil {
        client.Logger.Log(1, "err ->", err.Error())
	} else {
		if resp.Error.Code != 0 {
			fmt.Println("Error: ", resp.Error.Status, resp.Error.Message, resp.Error.Code)
		} else {
			fmt.Println(resp)
		}
	}
}
func main() {
    args := os.Args
    value := args[1]
    ModifyRR(value)
}
