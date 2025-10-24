#!/bin/bash

# Strimzi Kafka Cluster Setup Script
# This script automates the deployment of Kafka on Kubernetes using Strimzi

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_info "Prerequisites check passed"
}

# Install Strimzi operator
install_operator() {
    print_info "Installing Strimzi operator..."
    
    # Create namespace
    kubectl create namespace kafka 2>/dev/null || true
    
    # Install using official Strimzi files
    print_info "Downloading and installing official Strimzi operator..."
    kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
    
    print_info "Waiting for operator to be ready..."
    kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n kafka --timeout=300s
    
    print_info "Strimzi operator installed successfully"
}

# Deploy Kafka cluster
deploy_kafka() {
    print_info "Deploying Kafka cluster..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    kubectl apply -f "${PROJECT_DIR}/02-kafka-cluster.yaml"
    
    print_info "Waiting for Kafka cluster to be ready (this may take 5-10 minutes)..."
    kubectl wait kafka/my-cluster --for=condition=Ready --timeout=600s -n kafka
    
    print_info "Kafka cluster deployed successfully"
}

# Create topics
create_topics() {
    print_info "Creating Kafka topics..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    kubectl apply -f "${PROJECT_DIR}/03-kafka-topics.yaml"
    
    sleep 10
    
    print_info "Topics created successfully"
    kubectl get kafkatopics -n kafka
}

# Create users
create_users() {
    print_info "Creating Kafka users..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    kubectl apply -f "${PROJECT_DIR}/04-kafka-users.yaml"
    
    sleep 10
    
    print_info "Users created successfully"
    kubectl get kafkausers -n kafka
}

# Deploy test applications
deploy_test_apps() {
    print_info "Deploying test applications..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    kubectl apply -f "${PROJECT_DIR}/05-test-applications.yaml"
    
    sleep 5
    
    print_info "Test applications deployed"
    kubectl get pods -n kafka | grep -E 'producer|consumer|client'
}

# Deploy monitoring
deploy_monitoring() {
    print_info "Deploying monitoring stack..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    kubectl apply -f "${PROJECT_DIR}/06-monitoring.yaml"
    
    print_info "Waiting for monitoring components..."
    kubectl wait --for=condition=ready pod -l app=prometheus -n kafka --timeout=300s
    kubectl wait --for=condition=ready pod -l app=grafana -n kafka --timeout=300s
    
    print_info "Monitoring stack deployed successfully"
}

# Display cluster information
display_info() {
    print_info "Cluster Information:"
    echo ""
    
    print_info "Kafka Pods:"
    kubectl get pods -n kafka
    echo ""
    
    print_info "Kafka Services:"
    kubectl get svc -n kafka
    echo ""
    
    print_info "Kafka Topics:"
    kubectl get kafkatopics -n kafka
    echo ""
    
    print_info "Kafka Users:"
    kubectl get kafkausers -n kafka
    echo ""
    
    print_info "Access Information:"
    echo "  Prometheus: kubectl port-forward svc/prometheus 9090:9090 -n kafka"
    echo "  Grafana: kubectl port-forward svc/grafana 3000:3000 -n kafka"
    echo "  Kafka Client: kubectl exec -it kafka-client -n kafka -- /bin/bash"
    echo ""
}

# Main execution
main() {
    echo "========================================="
    echo "  Strimzi Kafka Cluster Setup"
    echo "========================================="
    echo ""
    
    check_prerequisites
    install_operator
    deploy_kafka
    create_topics
    create_users
    deploy_test_apps
    deploy_monitoring
    display_info
    
    print_info "Setup complete! Your Kafka cluster is ready to use."
}

# Run main function
main

