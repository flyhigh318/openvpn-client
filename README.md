## 生产环境已验证
> 上传到github时已经把关键的隐私信息做了修改，仅提供参考。

### openvpn 服务器配置
> a. openserver server.conf 支持客户端证书+密码认证模式  
> b. openserver server.conf 支持客户端分配固定ip模式  
> c. 生成证书的脚本在openvpnserver/keys/buildkeys.bash  
> d. 吊销脚本的脚本在openvpnserver/keys/delkeys.bash



### 线下打通阿里云内网操作步骤：

>a. 阿里云服务端配置openvpn并开启服务  
>b. 线下一台服务器拨号, 分别拨号.  
>c. 做基于路由策略的路由.  
>> c.1 创建相关的路由表 /etc/iproute2/rt_tables  
>>> echo "122 jiekuan" >> /etc/iproute2/rt_tables  
>>> echo "123 qiandai" >> /etc/iproute2/rt_tables  
>>> ip route show table jiekuan 检查相关的路由表有没成功
>>  
>> c.2 ip rule 路由策略 (用ip route add 效果一样)仅列举jiekuan路由表操作方法，qiandai的路由表相关路由一样     
>>> ip route add default via 192.168.105.5 dev tun0  table jiekuan  
>>> ip route add 172.18.16.0/20 via 192.168.105.5 dev tun0 table jiekuan  
>>> ip route add 192.168.105.1 via 192.168.105.5 dev tun0 table jiekuan  
>>> 上述方法是 ip route add 实现, 下面用ip rule add to 实现：  
>>> ip rule add to default via 192.168.105.5 dev tun0  table jiekuan  
>>> ip rule add to 172.18.16.0/20 via 192.168.105.5 dev tun0 table jiekuan  
>>> ip rule add to 192.168.105.1 via 192.168.105.5 dev tun0 table jiekuan  
>>> ip rule list table jiekuan 检查相关的路由表有没相关的路由指向  
> 
>d. 做NAT实现互通
>> iptables -A FORWARD -d 172.18.16.0/20 -i enp0s31f6 -o tun0 -j ACCEPT  
>> iptables  -t nat -A POSTROUTING -s 192.168.103.0/24 -d 172.18.72.12/32 -o tun0 -j MASQUERADE  
>> iptables  -t nat -A POSTROUTING -s 192.168.102.0/24 -d 172.18.72.12/32 -o tun0 -j MASQUERADE  
>> iptables  -t nat -A POSTROUTING -s 192.168.103.0/24 -d 172.18.16.0/20 -o tun0 -j MASQUERADE  
>> iptables  -t nat -A POSTROUTING -s 192.168.102.0/24 -d 172.18.16.0/20 -o tun0 -j MASQUERADE
>
>e. shell脚本启动,需要注意路径.

