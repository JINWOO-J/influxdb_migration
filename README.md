
##InfluxDB migration ( V0.8 -> V0.9 )


-  InfluxDB가 버젼이 바뀌면서 구조가 바뀌었다. 
- 변경 예 : `<tagName>.<tagValue>[.<tagName>.<tagValue>].<measurement>.`  -> `<measurement>,<tagName>=<tagValue>[,<tagName>=<tagValue>]`
- 참조 : https://docs.influxdata.com/influxdb/v0.9/concepts/08_vs_09/



## 0.8의 데이터 덤프
- dump 명령

```
# curl -s -k -G "http://localhost:8086/db/${DBNAME}/series?u=root&p=root&chunked=true" --data-urlencode "q=select * from /.*/" | jq . -c -M >> db1.txt
```
- option 설명
	 -  ` chunked=true` : 연속적으로 데이터 가져오기
  	 - `q=select * from /.*/"` : 모든 데이터 쿼리
	 - `  jq . -c -M ` : 행 정렬


## 0.9로 데이터 이전
 - TCP와 UDP로 insert 할 수 있으나, UDP가 압도적으로 빠르다. ( 10배이상 )


###UDP를 이용한 이전
- UDP를 사용하기 위해서 /etc/influxdb/influxdb.conf 수정

 ```conf
 [[udp]]
  enabled = true
  bind-address = ":8089"
  database = "mig_new_schema"  #UDP를 사용할 때는 한개의 데이터 베이스만 사용할 수 있다.
  ```

- line protocol을 이용한 INSERT 확인

  ```
  echo "cpu value=1"> /dev/udp/localhost/8089
  ```
  
- 참조 : https://docs.influxdata.com/influxdb/v0.9/write_protocols/udp/
  
  
### perl script 실행
```
# ./influxdb_mig_dup.pl
```
