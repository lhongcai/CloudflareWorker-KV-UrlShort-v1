#!/bin/sh

# 这是调用 “简短分享”改版的API接口，配合natmap使用，来提交大内网web服务的访问http地址！
short_code="$4"
# 后缀
domain_name="$5"
# 第三方免费的短链接网站
password="$6"
# 密码

ip="$1"
# natmap传递公网ipv4地址
port="$2"
# natmap传递公网端口号
long_url="http://${ip}:${port}"
# 长链接或原链接

log_file="/tmp/log/${domain_name}_${short_code}.txt"
# 自定义记录文件路径
log_() {
    logger -t "【$domain_name/$short_code】" $1
    echo -e "\033[36;1m【$(TZ=UTC-8 date -R +%Y年%m月%d月\ %X)】 : \033[0m\033[35;1m$1 \033[0m"
#    echo -e "【$(TZ=UTC-8 date -R +%Y年%m月%d月\ %X)】【${domain_name}\/${short_code}】 : $1" >> /tmp/log/UrlShort_wr.log
    
}

# 检查必要的参数是否为空
[ -z "${short_code}" ] && log_ "请在脚本中输入<你的短链接>" && exit
[ -z "${domain_name}" ] && log_ "请在脚本中输入<网站域名>" && exit
[ -z "${password}" ] && log_ "请在脚本输入<密码>" && exit

# 确保日志目录存在
 [ ! -d "/tmp/log/" ] && mkdir "/tmp/log/"

log_ "当前公网ipv4地址：${ip} 端口号： ${port}"
log_ "短链接 http://${domain_name}/${short_code}"

# 检查长链接是否为空
[ -z "${long_url}" ] && log_ "获取不了公网访问地址" && exit

# 检查地址是否有变化
old_addr=$(tail -n 1 "${log_file}" 2>/dev/null | awk '{print $4}') || old_addr="::"
[ "$long_url" = "${old_addr}" ] && log_ "公网访问地址与记录相同"  && exit



# 尝试更新短链接

retry='--retry 3 --retry-delay 2 --retry-max-time 10 -#kL'


for i in $(seq 1 5) ;do
    info=$(curl  ${retry} "${domain_name}/api" -X POST -d '{
      "longUrl": "'"${long_url}"'",
      "shortCode": "'"${short_code}"'",
      "type": "link",
      "expiration": "",
      "burn_after_reading": "false",
      "password": "'"${password}"'"
    }')

    [ $? -eq 0 ] && {
    log_ "${info}"
    [ -n "$(echo ${info} | grep -o '密码错误')" ] || {
    log_ "提交成功！"

	echo "$(date "+%G-%m-%d %H:%M:%S") 公网访问地址记录： ${long_url}" >> "${log_file}"
    log_ "短链接是：${domain_name}/${short_code}"
    break
    }

    }
sleep 60
done
