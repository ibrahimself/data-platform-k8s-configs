kubectl patch resourcequota monitoring-quota -n monitoring -p '{"spec":{"hard":{"limits.cpu":"20"}}}'
