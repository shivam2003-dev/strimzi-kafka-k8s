# Kafka Users and Security

## Overview

Strimzi provides robust security features for Kafka, including authentication and authorization through KafkaUser custom resources.

## Authentication Methods

Strimzi supports multiple authentication mechanisms:

1. **SCRAM-SHA-512** (recommended for most use cases)
2. **SCRAM-SHA-256**
3. **TLS Client Authentication**

## Creating Users

### Apply User Configurations

```bash
# Create all users
kubectl apply -f 04-kafka-users.yaml

# List all users
kubectl get kafkausers -n kafka

# Get user credentials
kubectl get secret producer-user -n kafka -o jsonpath='{.data.password}' | base64 -d
```

## User Types and Permissions

### 1. Producer User

**Purpose**: Applications that only write data to Kafka

```yaml
authorization:
  acls:
    - resource:
        type: topic
        name: "*"
      operation: Write
```

**Use Cases**:
- Data ingestion services
- Log shippers
- Event publishers

### 2. Consumer User

**Purpose**: Applications that only read data from Kafka

```yaml
authorization:
  acls:
    - resource:
        type: topic
        name: "*"
      operation: Read
    - resource:
        type: group
        name: "*"
      operation: Read
```

**Use Cases**:
- Analytics applications
- Data processing pipelines
- Monitoring systems

### 3. Admin User

**Purpose**: Full administrative access

```yaml
authorization:
  acls:
    - resource:
        type: topic
        name: "*"
      operation: All
    - resource:
        type: cluster
      operation: All
```

**Use Cases**:
- Cluster management
- Topic administration
- User management

### 4. Application User

**Purpose**: Limited access to specific topics

```yaml
authorization:
  acls:
    - resource:
        type: topic
        name: test-topic
      operation: Read
    - resource:
        type: topic
        name: test-topic
      operation: Write
```

**Use Cases**:
- Microservices with specific topic access
- Multi-tenant applications
- Isolated workloads

## Retrieving User Credentials

When you create a KafkaUser, Strimzi automatically generates credentials and stores them in a Kubernetes Secret.

### Get Password

```bash
# For SCRAM-SHA-512 users
kubectl get secret producer-user -n kafka -o jsonpath='{.data.password}' | base64 -d
echo

# Store in environment variable
export KAFKA_PASSWORD=$(kubectl get secret producer-user -n kafka -o jsonpath='{.data.password}' | base64 -d)
```

### Get SASL Configuration

```bash
# Get the full SASL JAAS config
kubectl get secret producer-user -n kafka -o jsonpath='{.data.sasl\.jaas\.config}' | base64 -d
```

## Using Authenticated Connections

### Console Producer with Authentication

```bash
# Create a client properties file
cat > /tmp/client.properties <<EOF
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="producer-user" password="$(kubectl get secret producer-user -n kafka -o jsonpath='{.data.password}' | base64 -d)";
EOF

# Produce messages with authentication
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --producer.config /tmp/client.properties
```

### Console Consumer with Authentication

```bash
# Create a client properties file
cat > /tmp/consumer.properties <<EOF
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="consumer-user" password="$(kubectl get secret consumer-user -n kafka -o jsonpath='{.data.password}' | base64 -d)";
EOF

# Consume messages with authentication
kubectl exec -it kafka-client -n kafka -- bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --consumer.config /tmp/consumer.properties \
  --from-beginning
```

## TLS Encryption

### Enable TLS Listener

The Kafka cluster is configured with multiple listeners:

- **Plain** (port 9092): No encryption, no authentication
- **TLS** (port 9093): Encrypted, optional authentication
- **External** (port 9094): External access via NodePort

### Connect Using TLS

```bash
# Extract cluster CA certificate
kubectl get secret my-cluster-cluster-ca-cert -n kafka -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/ca.crt

# Create TLS client properties
cat > /tmp/tls-client.properties <<EOF
security.protocol=SSL
ssl.truststore.location=/tmp/truststore.jks
ssl.truststore.password=changeit
EOF

# Import CA certificate into truststore
keytool -import -trustcacerts -alias root -file /tmp/ca.crt -keystore /tmp/truststore.jks -storepass changeit -noprompt
```

## Access Control Lists (ACLs)

### Understanding ACL Operations

- **Read**: Consume from topics, read offsets
- **Write**: Produce to topics
- **Create**: Create topics
- **Delete**: Delete topics
- **Alter**: Modify topic configurations
- **Describe**: View topic metadata
- **All**: All operations

### Resource Types

- **Topic**: Kafka topics
- **Group**: Consumer groups
- **Cluster**: Cluster-level operations
- **TransactionalId**: Transactional operations

### Pattern Types

- **Literal**: Exact match
- **Prefix**: Prefix match (e.g., "app-*" matches "app-logs", "app-events")

## Creating Custom Users

### Example: Read-Only User for Specific Topic

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: readonly-user
  namespace: kafka
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: scram-sha-512
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: user-events
          patternType: literal
        operation: Read
        host: "*"
      - resource:
          type: topic
          name: user-events
          patternType: literal
        operation: Describe
        host: "*"
      - resource:
          type: group
          name: readonly-group
          patternType: literal
        operation: Read
        host: "*"
```

### Example: Multi-Topic Producer

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: multi-producer
  namespace: kafka
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: scram-sha-512
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: app-
          patternType: prefix
        operation: Write
        host: "*"
      - resource:
          type: topic
          name: app-
          patternType: prefix
        operation: Describe
        host: "*"
```

## Testing User Permissions

### Test Producer Access

```bash
# Get producer credentials
PRODUCER_PASSWORD=$(kubectl get secret producer-user -n kafka -o jsonpath='{.data.password}' | base64 -d)

# Try to produce (should succeed)
kubectl exec -it kafka-client -n kafka -- bash -c "
cat > /tmp/producer.properties <<EOF
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=\"producer-user\" password=\"$PRODUCER_PASSWORD\";
EOF

echo 'Test message' | bin/kafka-console-producer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --producer.config /tmp/producer.properties
"
```

### Test Consumer Access

```bash
# Get consumer credentials
CONSUMER_PASSWORD=$(kubectl get secret consumer-user -n kafka -o jsonpath='{.data.password}' | base64 -d)

# Try to consume (should succeed)
kubectl exec -it kafka-client -n kafka -- bash -c "
cat > /tmp/consumer.properties <<EOF
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=\"consumer-user\" password=\"$CONSUMER_PASSWORD\";
EOF

bin/kafka-console-consumer.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic test-topic \
  --consumer.config /tmp/consumer.properties \
  --from-beginning \
  --max-messages 5
"
```

## Security Best Practices

1. **Use Strong Authentication**
   - Always use SCRAM-SHA-512 or TLS authentication in production
   - Never use plain text in production

2. **Principle of Least Privilege**
   - Grant only necessary permissions
   - Use specific topic names instead of wildcards when possible

3. **Rotate Credentials**
   - Regularly update user passwords
   - Use Kubernetes secrets rotation

4. **Enable TLS**
   - Encrypt data in transit
   - Use TLS for all production traffic

5. **Monitor Access**
   - Log authentication attempts
   - Monitor unauthorized access attempts

## Troubleshooting

### Authentication Failures

```bash
# Check user exists
kubectl get kafkauser producer-user -n kafka

# Check secret was created
kubectl get secret producer-user -n kafka

# View user status
kubectl describe kafkauser producer-user -n kafka
```

### Authorization Errors

```bash
# Check ACLs in Kafka
kubectl exec -it kafka-client -n kafka -- bin/kafka-acls.sh \
  --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --list

# Check user ACL configuration
kubectl get kafkauser producer-user -n kafka -o yaml
```

## Next Steps

- [Deploy Test Applications](04-test-applications.md)
- [Monitor Your Cluster](05-monitoring.md)

