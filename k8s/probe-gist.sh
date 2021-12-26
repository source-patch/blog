cat<<EOF > /tmp/podlist.gotemplate 
{{- range .items -}}{{\$pod := .}}
    {{- range .spec.containers -}}{{\$container := .}}
        {{- \$pod.metadata.name -}}{{- "," -}}
        {{- \$pod.metadata.namespace -}}{{- "," -}}
        {{- range \$pod.status.conditions -}}
            {{- if eq .type "PodScheduled" -}}
                {{- .lastTransitionTime -}}
            {{- end -}}
        {{- end -}}
        {{- "," -}}
        {{- range \$pod.status.conditions -}}
            {{- if eq .type "Initialized" -}}
                {{- .lastTransitionTime -}}
            {{- end -}}
        {{- end -}}
        {{- "," -}}
        {{- range \$pod.status.conditions -}}
            {{- if eq .type "ContainersReady" -}}
                {{- .lastTransitionTime -}}
            {{- end -}}
        {{- end -}}
        {{- "," -}}
        {{- range \$pod.status.conditions -}}
            {{- if eq .type "Ready" -}}
                {{- .lastTransitionTime -}}
            {{- end -}}
        {{- end -}}
        {{- "," -}}
        {{- .name -}}
        {{- ",runtime," -}}
        {{- .startupProbe.failureThreshold -}}{{- "," -}}
        {{- .startupProbe.successThreshold -}}{{- "," -}}
        {{- .startupProbe.periodSeconds -}}{{- "," -}}
        {{- .startupProbe.timeoutSeconds -}}{{- "," -}}
        {{- .startupProbe.initialDelaySeconds -}}{{- "," -}}
        {{- .readinessProbe.failureThreshold -}}{{- "," -}}
        {{- .readinessProbe.successThreshold -}}{{- "," -}}
        {{- .readinessProbe.periodSeconds -}}{{- "," -}}
        {{- .readinessProbe.timeoutSeconds -}}{{- "," -}}
        {{- .readinessProbe.initialDelaySeconds -}}{{- "," -}}
        {{- .livenessProbe.failureThreshold -}}{{- "," -}}
        {{- .livenessProbe.successThreshold -}}{{- "," -}}
        {{- .livenessProbe.periodSeconds -}}{{- "," -}}
        {{- .livenessProbe.timeoutSeconds -}}{{- "," -}}
        {{- .livenessProbe.initialDelaySeconds -}}{{- "," -}}
        {{- range \$pod.status.containerStatuses -}}
            {{- if eq .name \$container.name -}}
                {{- .started -}}{{- "," -}}
                {{- .ready -}}{{- "," -}}
                {{- .restartCount -}}{{- "," -}}
                {{- .lastState.terminated.finishedAt -}}{{- "," -}}
                {{- if .state.running.startedAt -}}
                    {{- .state.running.startedAt -}}
                {{- else -}}
                    {{- .state.terminated.startedAt -}}
                {{- end -}}
                {{- "," -}}
                {{- .state.terminated.reason -}}
            {{- end -}}
        {{- end -}}
        {{"\n"}}
    {{- end -}}
{{- end -}}
EOF

echo "pod name, pod namespace, pod scheduled, pod initialized, pod containers ready, pod ready, container name, container type, startup probe failure threshold, startup probe success threshold, startup probe period, startup probe failure timeout, startup probe initial delay, readiness probe failure threshold, readiness probe success threshold, readiness probe period, readiness probe failure timeout, readiness probe initial delay, liveness probe failure threshold, liveness probe success threshold, liveness probe period, liveness probe failure timeout, liveness probe initial delay, started, ready, restarts, running at, terminated at, reason, startup duration"
kubectl get pod -o go-template-file=/tmp/podlist.gotemplate | \
sed "s|<no value>|nil|g" | \
while read -r line
do
    cell_count=1
    pod_initialized=0
    restart_count=0
    last_terminated=0
    duration=0
    for cell in ${line//,/ }
    do
        if [[ ${cell} == *-*-*T*:*:* ]]; then
            timestamp=$(date -d "${cell}" "+%s")
            cell="${timestamp}"
        fi
        if [ ${cell_count} -eq 4 ]; then
            pod_initialized=${timestamp}
        fi
        if [ ${cell_count} -eq 26 ] && [ "${cell}" != "nil" ]; then
            restart_count=${cell}
        fi
        if [ ${cell_count} -eq 27 ] && [ "${cell}" != "nil" ];  then
            last_terminated=${timestamp}
        fi
        if [ ${cell_count} -eq 28 ]; then
            if [ "${restart_count}" -gt 0 ]; then 
                if [ "${last_terminated}" -gt 0 ]; then
                    duration=$((timestamp-last_terminated))
                else
                    duration="-"
                fi
            else
                duration=$((timestamp-pod_initialized))
            fi
        fi
        echo -n "${cell},"
        cell_count=$((cell_count+1))
    done

    echo "${duration}"
done
