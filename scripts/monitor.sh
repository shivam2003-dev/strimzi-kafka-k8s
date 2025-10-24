#!/bin/bash

# Kafka Monitoring Script
# Displays real-time monitoring information

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=========================================${NC}"
}

print_section() {
    echo -e "\n${BLUE}>>> $1${NC}"
}

# Check cluster status
check_cluster_status() {
    print_section "Kafka Cluster Status"
    
    STATUS=$(kubectl get kafka my-cluster -n kafka -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    
    if [ "$STATUS" == "True" ]; then
        echo -e "Status: ${GREEN}Ready${NC}"
    else
        echo -e "Status: ${RED}Not Ready${NC}"
    fi
    
    echo "Observed Generation: $(kubectl get kafka my-cluster -n kafka -o jsonpath='{.status.observedGeneration}' 2>/dev/null)"
}

# Show pod status
show_pods() {
    print_section "Pod Status"
    kubectl get pods -n kafka -o wide
}

# Show topics
show_topics() {
    print_section "Kafka Topics"
    kubectl get kafkatopics -n kafka
}

# Show users
show_users() {
    print_section "Kafka Users"
    kubectl get kafkausers -n kafka
}

# Show resource usage
show_resources() {
    print_section "Resource Usage"
    kubectl top pods -n kafka 2>/dev/null || echo "Metrics server not available"
}

# Show services
show_services() {
    print_section "Services"
    kubectl get svc -n kafka
}

# Show consumer groups
show_consumer_groups() {
    print_section "Consumer Groups"
    kubectl exec -it kafka-client -n kafka -- bin/kafka-consumer-groups.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --list 2>/dev/null || echo "Unable to fetch consumer groups"
}

# Show broker info
show_broker_info() {
    print_section "Broker Information"
    kubectl exec -it kafka-client -n kafka -- bin/kafka-broker-api-versions.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 2>/dev/null | head -10 || echo "Unable to fetch broker info"
}

# Show under-replicated partitions
show_under_replicated() {
    print_section "Under-Replicated Partitions"
    
    UNDER_REP=$(kubectl exec -it kafka-client -n kafka -- bin/kafka-topics.sh \
        --bootstrap-server my-cluster-kafka-bootstrap:9092 \
        --describe \
        --under-replicated-partitions 2>/dev/null)
    
    if [ -z "$UNDER_REP" ]; then
        echo -e "${GREEN}No under-replicated partitions${NC}"
    else
        echo -e "${RED}$UNDER_REP${NC}"
    fi
}

# Show recent logs
show_recent_logs() {
    print_section "Recent Kafka Logs (last 10 lines)"
    kubectl logs my-cluster-kafka-0 -n kafka --tail=10 2>/dev/null || echo "Unable to fetch logs"
}

# Show PVC usage
show_pvc_usage() {
    print_section "Persistent Volume Claims"
    kubectl get pvc -n kafka
}

# Continuous monitoring mode
continuous_monitor() {
    while true; do
        clear
        print_header "Kafka Cluster Monitor - $(date)"
        
        check_cluster_status
        show_pods
        show_resources
        show_under_replicated
        
        echo ""
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        
        sleep 5
    done
}

# Full report
full_report() {
    print_header "Kafka Cluster Full Report - $(date)"
    
    check_cluster_status
    show_pods
    show_topics
    show_users
    show_services
    show_resources
    show_consumer_groups
    show_broker_info
    show_under_replicated
    show_pvc_usage
    show_recent_logs
    
    echo ""
}

# Show help
show_help() {
    echo "Kafka Monitoring Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  -f, --full       Show full report"
    echo "  -w, --watch      Continuous monitoring mode"
    echo "  -s, --status     Show cluster status only"
    echo "  -p, --pods       Show pod status"
    echo "  -t, --topics     Show topics"
    echo "  -u, --users      Show users"
    echo "  -c, --consumers  Show consumer groups"
    echo "  -h, --help       Show this help message"
    echo ""
}

# Main execution
case "${1}" in
    -f|--full)
        full_report
        ;;
    -w|--watch)
        continuous_monitor
        ;;
    -s|--status)
        check_cluster_status
        ;;
    -p|--pods)
        show_pods
        ;;
    -t|--topics)
        show_topics
        ;;
    -u|--users)
        show_users
        ;;
    -c|--consumers)
        show_consumer_groups
        ;;
    -h|--help)
        show_help
        ;;
    *)
        full_report
        ;;
esac

