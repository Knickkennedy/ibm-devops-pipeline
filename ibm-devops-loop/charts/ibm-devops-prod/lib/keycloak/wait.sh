#!/usr/bin/env bash

while true; do
  code=$(curl $CAFILE -sw '%{http_code}' "$1" -o /dev/null || true)
  echo response $code
  if [ "$code" = "200" ]; then
      break
  fi
  sleep 15
done
