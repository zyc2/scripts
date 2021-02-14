#!/usr/bin/env bash
# shellcheck disable=SC2162
read -p "粘贴curl命令: " pb
max=$(echo "$pb" | grep -P -o '(?<=seg-)\d+(?=-v)')
if [ -z "$max" ]; then
  echo "错误的curl格式"
  exit 1
fi
ss=$(date +%s)
dir=$(echo "$pb" | grep -P -o '\d+.mp4')
mkdir -p "$dir"

THREAD=32
echo "开始下载视频=线程数=>$THREAD,线程过多服务器会限制导致抓取失败！！"
FIFO=$$.fifo
mkfifo $FIFO
exec 5<>${FIFO} #创建文件标示符“5”，以读写模式操作管道文件；系统调用exec是以新的进程去代替原来的进程，但进程的PID保持不变，换句话说就是在调用进程内部执行一个可执行文件
rm -rf ${FIFO}
for ((i = 1; i <= THREAD; i++)); do
  echo "" #借用read命令一次读取一行的特性，使用一个echo默认输出一个换行符，来确保每一行只有一个线程占位
done >&5
function displaytime() {
  local T=$1
  local D=$((T / 60 / 60 / 24))
  local H=$((T / 60 / 60 % 24))
  local M=$((T / 60 % 60))
  local S=$((T % 60))
  ((D > 0)) && printf '%3dd' $D
  ((H > 0)) && printf '%2dh:' $H
  ((M > 0)) && printf '%2dm:' $M
  printf '%2ds' $S
}

for ((i = 1; i <= max; i++)); do
  read -u5
  {
    bn=$(date +%s%N)
    echo "$pb" | sed -r 's/seg-[0-9]+-v/seg-'"$i"'-v/;s/^curl/curl -s -k/' | bash >"$dir/$i.ts"
    un=$(($(date +%s%N) - bn))
    rn=$(((max - i) * un / THREAD))
    bc=$(wc -c <"$dir/$i".ts)
    bs=$((bc * 1000000000 / un))
    printf "$i/$max($(numfmt --to=iec <<<$bc))\t$((100 * i / max))%%\t下载速度$(numfmt --to=iec <<<$bs)/s *${THREAD}\t剩余时间:$(displaytime $((rn / 1000000000)))\r"
    #    echo "$i/$max;$((100 * i / max))%"
    echo "" >&5 #任务执行完后在fd5中写入一个占位符，以保证这个线程执行完后，线程继续保持占位，继而维持管道中永远是THREAD个线程数
  } &

done
wait
exec 5>&- #关闭fd5的管道
echo

name=$1
if [ -z "$name" ]; then
  echo "总耗时:$(displaytime $(($(date +%s) - ss)))"
  exit 0
fi

find "$dir" -name "*.ts" | sort -V | xargs cat >>"$name".ts
rm -r "$dir"
echo "总耗时:$(displaytime $(($(date +%s) - ss)))"
exit 0
