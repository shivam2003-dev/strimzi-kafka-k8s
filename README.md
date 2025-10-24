# Strimzi Kafka on Kubernetes Tutorial

Complete guide for running Apache Kafka on Kubernetes using Strimzi operator - from local development to production deployment.

## 🚀 Quick Start

### Local Development (Colima)

```bash
# Start Colima
colima start --cpu 4 --memory 8

# Deploy Kafka
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
kubectl apply -f 02-kafka-cluster-light.yaml
kubectl apply -f 03-kafka-topics-light.yaml
kubectl apply -f 04-kafka-users.yaml
kubectl apply -f 05-test-applications.yaml
```

### Production (AWS/GCP/Azure)

```bash
# Use the automated setup script
./scripts/setup-cluster.sh
```

## 📁 Project Structure

```
strimzi-kafka-k8s/
├── README.md                          # This file
├── 01-strimzi-operator.yaml          # Operator reference
├── 02-kafka-cluster.yaml             # Production cluster (3 brokers + ZooKeeper)
├── 02-kafka-cluster-kraft.yaml       # Production cluster (KRaft mode)
├── 02-kafka-cluster-light.yaml       # Local development (single node)
├── 03-kafka-topics.yaml              # Production topics
├── 03-kafka-topics-light.yaml        # Local topics
├── 04-kafka-users.yaml               # Users with authentication
├── 05-test-applications.yaml         # Test apps
├── 06-monitoring.yaml                # Prometheus + Grafana
│
├── docs/                             # 📚 All documentation
│   ├── QUICKSTART.md                 # 5-minute quick start
│   ├── TUTORIAL.md                   # Complete tutorial
│   ├── INDEX.md                      # Complete index
│   ├── COLIMA-SETUP.md               # Local development guide
│   ├── 00-INSTALLATION-NOTES.md      # Installation guide
│   ├── 01-getting-started.md         # Setup guide
│   ├── 02-topics.md                  # Topic management
│   ├── 03-users-security.md          # Security guide
│   ├── 04-test-applications.md       # Testing guide
│   ├── 05-monitoring.md              # Monitoring guide
│   ├── 06-advanced-features.md       # Advanced topics
│   ├── PROJECT-SUMMARY.md            # What's included
│   ├── VISUAL-GUIDE.md               # Visual diagrams
│   └── DEPLOYMENT-SUCCESS.md         # Deployment notes
│
└── scripts/                          # 🛠️ Automation scripts
    ├── setup-cluster.sh              # Automated setup
    ├── test-kafka.sh                 # Test suite
    ├── monitor.sh                    # Monitoring tool
    └── cleanup.sh                    # Cleanup script
```

## 📖 Documentation

All documentation is in the `docs/` folder:

| Document | Description |
|----------|-------------|
| [**QUICKSTART.md**](docs/QUICKSTART.md) | Get started in 5 minutes |
| [**TUTORIAL.md**](docs/TUTORIAL.md) | Complete end-to-end tutorial |
| [**COLIMA-SETUP.md**](docs/COLIMA-SETUP.md) | Local development with Colima |
| [**INDEX.md**](docs/INDEX.md) | Complete navigation index |

### Detailed Guides

- [Installation Notes](docs/00-INSTALLATION-NOTES.md)
- [Getting Started](docs/01-getting-started.md)
- [Topic Management](docs/02-topics.md)
- [Users & Security](docs/03-users-security.md)
- [Test Applications](docs/04-test-applications.md)
- [Monitoring](docs/05-monitoring.md)
- [Advanced Features](docs/06-advanced-features.md)

## 🎯 What You'll Learn

- ✅ Kafka fundamentals and architecture
- ✅ Deploying Kafka on Kubernetes
- ✅ Using Strimzi operator
- ✅ Topic management and configuration
- ✅ Authentication and authorization (SCRAM-SHA-512, ACLs)
- ✅ Monitoring with Prometheus & Grafana
- ✅ Production best practices
- ✅ KRaft mode (Kafka without ZooKeeper)

## 🎓 Learning Path

### Beginner (Start Here)
1. Read [QUICKSTART.md](docs/QUICKSTART.md)
2. Deploy locally with [COLIMA-SETUP.md](docs/COLIMA-SETUP.md)
3. Test with console producer/consumer

### Intermediate
1. Follow [TUTORIAL.md](docs/TUTORIAL.md)
2. Learn [Topic Management](docs/02-topics.md)
3. Configure [Users & Security](docs/03-users-security.md)

### Advanced
1. Set up [Monitoring](docs/05-monitoring.md)
2. Explore [Advanced Features](docs/06-advanced-features.md)
3. Deploy to production

## 🛠️ Automation Scripts

All scripts are in the `scripts/` folder:

```bash
# Automated cluster setup
./scripts/setup-cluster.sh

# Run comprehensive tests
./scripts/test-kafka.sh

# Monitor cluster health
./scripts/monitor.sh
./scripts/monitor.sh --watch

# Clean up resources
./scripts/cleanup.sh
```

## 🎯 Key Features

| Feature | Local (Colima) | Production |
|---------|---------------|------------|
| **Kafka Version** | 4.0.0 (KRaft) | 3.6.0 / 4.0.0 |
| **Brokers** | 1 | 3 |
| **ZooKeeper** | None (KRaft) | 3 nodes / None (KRaft) |
| **Replication** | 1 | 3 |
| **Storage** | Ephemeral | Persistent (10Gi+) |
| **Resources** | ~1GB RAM | 8GB+ RAM |

## 🚀 Deployment Options

### Option 1: Local Development (Colima)
```bash
# See docs/COLIMA-SETUP.md
colima start
kubectl apply -f 02-kafka-cluster-light.yaml
```

### Option 2: Production (with ZooKeeper)
```bash
# See docs/QUICKSTART.md
./scripts/setup-cluster.sh
```

### Option 3: Production (KRaft mode)
```bash
# See docs/00-INSTALLATION-NOTES.md
kubectl apply -f 02-kafka-cluster-kraft.yaml
```

## 📊 What's Included

### Kubernetes Resources
- **6 YAML files** for complete deployment
- **3 cluster configurations** (production, KRaft, lightweight)
- **Production-ready** settings with best practices

### Documentation
- **14 comprehensive guides** (5,000+ lines)
- **Step-by-step tutorials** with examples
- **Visual diagrams** and architecture guides
- **Real-world use cases** and patterns

### Automation
- **4 shell scripts** for common operations
- **10 automated tests** for validation
- **Monitoring tools** for health checks
- **Cleanup utilities** for safe removal

## 🧪 Testing

```bash
# Run all tests
./scripts/test-kafka.sh

# Manual testing
kubectl exec -it kafka-client -n kafka -- /bin/bash

# Inside the pod:
bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --list
bin/kafka-console-producer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic test-topic
bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic test-topic --from-beginning
```

## 📈 Monitoring

```bash
# Deploy monitoring stack
kubectl apply -f 06-monitoring.yaml

# Access Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n kafka

# Access Grafana (admin/admin)
kubectl port-forward svc/grafana 3000:3000 -n kafka
```

## 🧹 Cleanup

```bash
# Safe cleanup with confirmation
./scripts/cleanup.sh

# Or manual cleanup
kubectl delete namespace kafka
```

## 💡 Use Cases

This tutorial covers:
- 📦 **E-commerce**: Order processing and inventory management
- 📊 **Analytics**: Real-time data processing and aggregation
- 📝 **Logging**: Centralized log aggregation
- 🔄 **Event Sourcing**: Event-driven microservices
- 🔔 **Notifications**: Real-time alerting systems

## 🌟 Highlights

- ✅ **Modern Kafka 4.0** with KRaft mode
- ✅ **Production-ready** configurations
- ✅ **Local development** with Colima
- ✅ **Comprehensive docs** (14 guides)
- ✅ **Automated scripts** for operations
- ✅ **Security** (SCRAM-SHA-512, ACLs)
- ✅ **Monitoring** (Prometheus + Grafana)
- ✅ **Real examples** with Python & Bash

## 📚 Additional Resources

- [Strimzi Documentation](https://strimzi.io/docs/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

Feel free to:
- Report issues
- Suggest improvements
- Share your use cases
- Contribute examples

## 📝 License

This tutorial is provided as-is for educational purposes.

## 🎉 Getting Started

**Choose your path:**

1. **New to Kafka?** → Start with [docs/QUICKSTART.md](docs/QUICKSTART.md)
2. **Local testing?** → See [docs/COLIMA-SETUP.md](docs/COLIMA-SETUP.md)
3. **Production deployment?** → Follow [docs/TUTORIAL.md](docs/TUTORIAL.md)
4. **Need reference?** → Check [docs/INDEX.md](docs/INDEX.md)

**Happy Kafka-ing! 🚀**
