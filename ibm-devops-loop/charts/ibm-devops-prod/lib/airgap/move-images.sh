#!/usr/bin/env bash
set -e

to=${1:-localhost:32000}
from=${2:-cp.icr.io/cp}

while read i
do
  echo "Moving $i"
  if command -v skopeo > /dev/null; then
    if [[ $i == *@* ]] ; then
      skopeo copy "docker://$from/${i/:*/}@${i/*@/}" "docker://$to/${i%@sha*}" $CRED_ARGUMENTS
    else
      skopeo copy "docker://$from/$i" "docker://$to/$i" $CRED_ARGUMENTS
    fi
  elif [[ $to == *.azurecr.io* ]] && command -v az > /dev/null; then
    if [[ $to == */* ]]; then
      prefix=${to/*\//}
    fi
    if [[ $i == *@* ]] ; then
      az acr import $PULL_ARGUMENTS -n ${to%%.*}  --source "$from/${i/:*/}@${i/*@/}" --image "${prefix+$prefix/}${i%@sha*}"
    else
      az acr import $PULL_ARGUMENTS -n ${to%%.*}  --source "$from/$i" --image "${prefix+$prefix/}$i"
    fi
  elif command -v docker > /dev/null; then
    docker pull "$from/$i"
    if [[ $i == *@* ]] ; then
      docker tag "$from/${i/:*/}@${i/*@/}" "$to/${i%@sha*}"
    else
      docker tag "$from/$i" "$to/$i"
    fi
    docker rmi "$from/$i"
    docker push "$to/${i%@sha*}"
    docker rmi "$to/${i%@sha*}"
  elif command -v k3s > /dev/null; then
    k3s ctr images pull $PULL_ARGUMENTS "$from/$i"
    k3s ctr images push $PUSH_ARGUMENTS "$to/${i%@sha*}" "$from/$i"
    k3s ctr images remove "$from/$i"
  fi
done < $(dirname "${BASH_SOURCE[0]}")/images.txt

echo "Product images have been copied to $to. You can use these by adding this helm value:"
echo "  --set imageRegistry=$to"
