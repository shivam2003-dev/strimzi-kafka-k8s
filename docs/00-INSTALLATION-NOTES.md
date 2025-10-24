# Strimzi Installation Notes

## Installing Strimzi Operator

The Strimzi operator should be installed using the official installation files from the Strimzi project.

### Quick Installation

```bash
# Download and install Strimzi 0.38.0
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
```

### Or Manual Installation

```bash
# Download Strimzi
curl -L https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.38.0/strimzi-0.38.0.tar.gz -o /tmp/strimzi.tar.gz
tar xzf /tmp/strimzi.tar.gz -C /tmp/

# Update namespace to kafka
cd /tmp/strimzi-0.38.0
sed -i 's/namespace: .*/namespace: kafka/' install/cluster-operator/*RoleBinding*.yaml

# Install
kubectl create namespace kafka
kubectl apply -f install/cluster-operator/ -n kafka
```

### Verify Installation

```bash
# Wait for operator to be ready
kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n kafka --timeout=300s

# Check operator is running
kubectl get pods -n kafka
```

## After Operator Installation

Once the operator is running, proceed with deploying the Kafka cluster:

```bash
kubectl apply -f 02-kafka-cluster.yaml
kubectl apply -f 03-kafka-topics.yaml
kubectl apply -f 04-kafka-users.yaml
kubectl apply -f 05-test-applications.yaml
kubectl apply -f 06-monitoring.yaml
```

## Using the Automated Script

The `scripts/setup-cluster.sh` script has been updated to use the official Strimzi installation.

```bash
./scripts/setup-cluster.sh
```

## Note

The file `01-strimzi-operator.yaml` contains a simplified example for reference. 
For actual deployments, always use the official Strimzi installation files as shown above.

