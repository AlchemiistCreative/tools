#!/bin/bash

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Required APIs for the services we are going to check
REQUIRED_APIS=("compute.googleapis.com" "sqladmin.googleapis.com" "storage.googleapis.com" "container.googleapis.com")

# Function to check if gcloud CLI is installed
check_gcloud_installed() {
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Error: gcloud CLI is not installed. Please install it and try again.${NC}"
        exit 1
    fi
}

# Function to check if gcloud is authenticated
check_gcloud_authenticated() {
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    if [ -z "$ACTIVE_ACCOUNT" ]; then
        echo -e "${RED}Error: gcloud is not authenticated. Please run 'gcloud auth login' and try again.${NC}"
        exit 1
    else
        echo -e "${GREEN}Authenticated account found: ${YELLOW}$ACTIVE_ACCOUNT${NC}"
        read -p "$(echo -e Is this the correct account? y/n: ${NC})" CONFIRM_ACCOUNT
        if [[ "$CONFIRM_ACCOUNT" != "y" && "$CONFIRM_ACCOUNT" != "Y" ]]; then
            echo -e "${RED}Please switch accounts using 'gcloud auth login' and try again.${NC}"
            exit 1
        fi
    fi
}

# Function to list all GCP projects
list_projects() {
    echo -e "${BLUE}Listing all available projects:${NC}"
    gcloud projects list --format="table(projectId,name)"
}

# Function to check if a specific API is enabled for the project
is_api_enabled() {
    local PROJECT_ID="$1"
    local API="$2"

    # Check if the API is enabled
    if gcloud services list --enabled --project "$PROJECT_ID" --filter="config.name:$API" --format="value(config.name)" | grep -q "$API"; then
        return 0 
    else
        return 1
    fi
}


# Function to list VM instances if Compute Engine API is enabled
list_vm_instances() {
    if is_api_enabled "$PROJECT_ID" "compute.googleapis.com"; then
        echo -e "${BLUE}Listing all VM instances in project ${YELLOW}$PROJECT_ID${NC}"
        gcloud compute instances list --format="table(name,zone,status)" > vm_instances_report.txt
        echo -e "${GREEN}VM Instances report saved to vm_instances_report.txt${NC}"
    else
        echo -e "${YELLOW}Compute Engine API is not enabled. Skipping VM instances listing.${NC}"
    fi
}

# Function to list Cloud Storage buckets if Storage API is enabled
list_storage_buckets() {
    if is_api_enabled "$PROJECT_ID" "storage.googleapis.com"; then
        echo -e "${BLUE}Listing all Cloud Storage buckets${NC}"
        gcloud storage buckets list --format="table(name,location,storageClass)" > storage_buckets_report.txt
        echo -e "${GREEN}Storage Buckets report saved to storage_buckets_report.txt${NC}"
    else
        echo -e "${YELLOW}Cloud Storage API is not enabled. Skipping Cloud Storage buckets listing.${NC}"
    fi
}

# Function to list Cloud SQL instances if SQL API is enabled
list_sql_instances() {
    if is_api_enabled "$PROJECT_ID" "sqladmin.googleapis.com"; then
        echo -e "${BLUE}Listing all Cloud SQL instances${NC}"
        gcloud sql instances list --format="table(name,region,backendType,state)" > sql_instances_report.txt
        echo -e "${GREEN}Cloud SQL Instances report saved to sql_instances_report.txt${NC}"
    else
        echo -e "${YELLOW}Cloud SQL API is not enabled. Skipping Cloud SQL instances listing.${NC}"
    fi
}

# Function to list GKE clusters if Kubernetes Engine API is enabled
list_gke_clusters() {
    if is_api_enabled "$PROJECT_ID" "container.googleapis.com"; then
        echo -e "${BLUE}Listing all GKE clusters${NC}"
        gcloud container clusters list --format="table(name,location,status)" > gke_clusters_report.txt
        echo -e "${GREEN}GKE Clusters report saved to gke_clusters_report.txt${NC}"
    else
        echo -e "${YELLOW}Kubernetes Engine API is not enabled. Skipping GKE clusters listing.${NC}"
    fi
}

# First check if gcloud is installed
check_gcloud_installed

# Then check if gcloud is authenticated and confirm the account
check_gcloud_authenticated

# Parsing arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --list)
            list_projects
            exit 0
            ;;
        --project)
            PROJECT_ID="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Invalid argument: $1${NC}"
            exit 1
            ;;
    esac
done

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Please set a Project ID using --project <project-id>.${NC}"
    exit 1
fi

# Set the project in gcloud
gcloud config set project $PROJECT_ID

#List resources based on enabled APIs
list_vm_instances
list_storage_buckets
list_sql_instances
list_gke_clusters

# Optional: Check the health status for Compute Engine VM instances
#if is_api_enabled "$PROJECT_ID" "compute.googleapis.com"; then
#    echo -e "${BLUE}Checking health status of all Compute Engine instances${NC}"
#    gcloud compute instances list --format="value(name,zone,status)" | while read INSTANCE; do
#        NAME=$(echo $INSTANCE | awk '{print $1}')
#        ZONE=$(echo $INSTANCE | awk '{print $2}')
#        STATUS=$(echo $INSTANCE | awk '{print $3}')
#        echo "Instance: $NAME in $ZONE is $STATUS" >> vm_health_report.txt
#    done
#    echo -e "${GREEN}VM Health report saved to vm_health_report.txt${NC}"
#else
#    echo -e "${YELLOW}Compute Engine API is not enabled. Skipping VM health check.${NC}"
#fi

# Summarizing the reports
echo -e "${GREEN}All resource reports generated successfully.${NC}"

# List of generated reports
#ls -l *_report.txt
