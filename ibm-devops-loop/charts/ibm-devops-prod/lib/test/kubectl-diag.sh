#!/usr/bin/env bash

if [ -z "$NAMESPACE" ]; then
  NAMESPACE=default
fi

if [ -z "$CMD_KUBECTL" ] && command -v oc >/dev/null; then
  CMD_KUBECTL=oc
fi

echo "Objects in ${NAMESPACE} namespace:"
${CMD_KUBECTL:-kubectl} get node,event,pod,job,deployment,statefulset,pvc -n "$NAMESPACE" -owide || true

echo
echo "Logs since ${SINCE:-beginning}:"

pods="$(${CMD_KUBECTL:-kubectl} get pod -n "$NAMESPACE" --no-headers -o custom-columns=\
NAME:.metadata.name,\
FINISHED_AT:.status.containerStatuses[*].lastState.terminated.finishedAt,\
EXIT_CODE:.status.containerStatuses[*].lastState.terminated.exitCode,\
REASON:.status.containerStatuses[*].lastState.terminated.reason,\
RESTARTS:.status.containerStatuses[*].restartCount | sed -e 's/[\t ][\t ]*/,/g')"

for pod in $pods; do
  if [[ "$pod" != *',0' ]]; then
    ${CMD_KUBECTL:-kubectl} logs "${pod%%,*}" -n "$NAMESPACE" "${SINCE:+--since-time=}${SINCE}" --all-containers --timestamps --prefix -p || true
  fi
  ${CMD_KUBECTL:-kubectl} logs "${pod%%,*}" -n "$NAMESPACE" "${SINCE:+--since-time=}${SINCE}" --all-containers --timestamps --prefix || true
done | sort -k2 | sed -e 's/\x1b\[[0-9;]*m//g; s#^\[pod/#\[#' | cut -d' ' -f1,3-

echo
echo "Reason for last termination:"

terminated="$(echo "NAME,FINISHED_AT,EXIT_CODE,REASON,RESTARTS"; grep -v ',0$' <<< "$pods")"
if command -v column >/dev/null; then
  column -t -s , <<< "$terminated"
else
  echo "$terminated"
fi
