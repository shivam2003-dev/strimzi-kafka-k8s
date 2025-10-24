#!/bin/bash

# Cleanup Script for Strimzi Kafka
# Removes all Kafka resources from the cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirm cleanup
confirm_cleanup() {
    echo "========================================="
    echo "  Kafka Cluster Cleanup"
    echo "========================================="
    echo ""
    print_warn "This will delete all Kafka resources including:"
    echo "  - Kafka cluster"
    echo "  - Topics and data"
    echo "  - Users and credentials"
    echo "  - Test applications"
    echo "  - Monitoring stack"
    echo "  - Strimzi operator"
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Cleanup cancelled"
        exit 0
    fi
}

# Delete test applications
delete_test_apps() {
    print_info "Deleting test applications..."
    
    if kubectl get -f ../05-test-applications.yaml &> /dev/null; then
        kubectl delete -f ../05-test-applications.yaml --ignore-not-found=true
        print_info "Test applications deleted"
    else
        print_info "No test applications found"
    fi
}

# Delete monitoring
delete_monitoring() {
    print_info "Deleting monitoring stack..."
    
    if kubectl get -f ../06-monitoring.yaml &> /dev/null; then
        kubectl delete -f ../06-monitoring.yaml --ignore-not-found=true
        print_info "Monitoring stack deleted"
    else
        print_info "No monitoring stack found"
    fi
}

# Delete users
delete_users() {
    print_info "Deleting Kafka users..."
    
    if kubectl get -f ../04-kafka-users.yaml &> /dev/null; then
        kubectl delete -f ../04-kafka-users.yaml --ignore-not-found=true
        print_info "Kafka users deleted"
    else
        print_info "No Kafka users found"
    fi
}

# Delete topics
delete_topics() {
    print_info "Deleting Kafka topics..."
    
    if kubectl get -f ../03-kafka-topics.yaml &> /dev/null; then
        kubectl delete -f ../03-kafka-topics.yaml --ignore-not-found=true
        print_info "Kafka topics deleted"
    else
        print_info "No Kafka topics found"
    fi
}

# Delete Kafka cluster
delete_kafka_cluster() {
    print_info "Deleting Kafka cluster..."
    
    if kubectl get kafka my-cluster -n kafka &> /dev/null; then
        kubectl delete -f ../02-kafka-cluster.yaml --ignore-not-found=true
        
        print_info "Waiting for Kafka cluster to be deleted..."
        kubectl wait --for=delete kafka/my-cluster -n kafka --timeout=300s 2>/dev/null || true
        
        print_info "Kafka cluster deleted"
    else
        print_info "No Kafka cluster found"
    fi
}

# Delete operator
delete_operator() {
    print_info "Deleting Strimzi operator..."
    
    if kubectl get deployment strimzi-cluster-operator -n kafka &> /dev/null; then
        kubectl delete -f ../01-strimzi-operator.yaml --ignore-not-found=true
        print_info "Strimzi operator deleted"
    else
        print_info "No Strimzi operator found"
    fi
}

# Delete namespace
delete_namespace() {
    print_info "Deleting kafka namespace..."
    
    if kubectl get namespace kafka &> /dev/null; then
        kubectl delete namespace kafka --timeout=300s
        print_info "Namespace deleted"
    else
        print_info "Namespace not found"
    fi
}

# Delete PVCs (optional)
delete_pvcs() {
    print_warn "Checking for persistent volume claims..."
    
    PVCS=$(kubectl get pvc -n kafka --no-headers 2>/dev/null | wc -l)
    
    if [ "$PVCS" -gt 0 ]; then
        echo ""
        print_warn "Found $PVCS PVCs. These contain your Kafka data."
        read -p "Do you want to delete PVCs and all data? (yes/no): " -r
        echo
        
        if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            kubectl delete pvc --all -n kafka
            print_info "PVCs deleted"
        else
            print_info "PVCs preserved"
        fi
    fi
}

# Main execution
main() {
    confirm_cleanup
    
    echo ""
    print_info "Starting cleanup process..."
    echo ""
    
    delete_test_apps
    sleep 2
    
    delete_monitoring
    sleep 2
    
    delete_users
    sleep 2
    
    delete_topics
    sleep 2
    
    delete_kafka_cluster
    sleep 5
    
    delete_pvcs
    
    delete_operator
    sleep 2
    
    delete_namespace
    
    echo ""
    print_info "Cleanup complete!"
    echo ""
    print_info "To verify cleanup:"
    echo "  kubectl get all -n kafka"
    echo "  kubectl get pvc -n kafka"
}

# Run main function
main

