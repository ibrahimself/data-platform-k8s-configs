kubectl apply -f applications/monitoring-helm.yaml
kubectl apply -f applications/monitoring-resources.yaml
sleep 60
kubectl apply -f applications/postgresql-helm.yaml
kubectl apply -f applications/postgresql-resources.yaml
sleep 60
kubectl apply -f applications/spark-helm.yaml
kubectl apply -f applications/spark-resources.yaml
sleep 60
kubectl apply -f applications/minio.yaml
kubectl apply -f applications/airflow-helm.yaml
kubectl apply -f applications/airflow-resources.yaml
sleep 60
kubectl apply -f applications/dremio-helm.yaml
kubectl apply -f applications/dremio-resources.yaml
