#!/usr/bin/env zsh
NUM=10
if [[ $1 =~ ^[0-9]+$ ]] ;then
    NUM=$1
fi

BRANCHES=(
  $(git reflog |
    egrep -io "moving from ([^[:space:]]+)" |
    awk '{ print $3 }' |
    awk ' !x[$0]++' | # Removes duplicates.See http://stackoverflow.com/questions/11532157
    egrep -v '^[a-f0-9]{40}$' |
    head -n $NUM
  )
)
counter=1
p=""
for br in $BRANCHES; do
    p+=$counter') \e[1;33m '$br'\e[0m|'$(
        git --no-pager log \
            --pretty='%Cblue%s|%Cgreen%ar|%C(magenta)%an|%C(cyan)%h%Creset' -1 $br --color 2>/dev/null \
        || echo '\e[1;31m<== 已删除的分支,deleted branch ==>\e[0m'
      )'\n';
    counter=$((counter+1));
done
echo $p|column -ts '|'
echo "Choose a branch: "
read n
git checkout ${BRANCHES[n]}
