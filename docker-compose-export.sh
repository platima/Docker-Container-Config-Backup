#!/bin/bash

#############################################################################
# Docker Compose Export Script
#############################################################################
# Description: Exports docker-compose.yml files for all running and stopped
#              containers using docker-autocompose
#
# Author: Platima (https://github.com/platima)
# License: MIT
#
# Requirements:
#   - Docker installed and running
#   - Access to /var/run/docker.sock
#   - Network access to pull ghcr.io/red5d/docker-autocompose
#
# Usage: ./docker-compose-export.sh [OPTIONS]
#
# Options:
#   -o, --output-dir DIR    Specify output directory (default: current directory)
#   --nameonly              Use only container name in filename (name.compose.yml)
#   --idonly                Use only container ID in filename (id.compose.yml)
#   -h, --help             Show this help message
#
# Default behaviour: Files named as {name}-{id}.compose.yml
#
#############################################################################

set -eu  # Exit on error and undefined vars

# Colour codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Colour

# Default configuration
OUTPUT_DIR="."
AUTOCOMPOSE_IMAGE="ghcr.io/red5d/docker-autocompose"
NAMING_MODE="both"  # Options: both, nameonly, idonly

#############################################################################
# Functions
#############################################################################

# Print error message and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Print warning message
warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

# Print success message
success() {
    echo -e "${GREEN}$1${NC}"
}

# Display help message
show_help() {
    grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# \?//'
    exit 0
}

# Check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        error_exit "Docker is not running or you don't have permission to access it"
    fi
}

# Pull the latest autocompose image
pull_autocompose_image() {
    echo "Pulling latest docker-autocompose image..."
    if ! docker pull "$AUTOCOMPOSE_IMAGE" &> /dev/null; then
        warn "Failed to pull latest image, using cached version if available"
    fi
}

# Export compose file for a single container
export_container() {
    local container_id="$1"
    local container_name
    local output_file
    local filename
    
    # Get container name, removing leading slash
    container_name=$(docker inspect --format="{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///') || {
        warn "Could not get name for container $container_id, skipping"
        return 1
    }
    
    if [[ -z "$container_name" ]]; then
        warn "Could not get name for container $container_id, skipping"
        return 1
    fi
    
    # Create filename based on naming mode
    case "$NAMING_MODE" in
        nameonly)
            filename="${container_name}.compose.yml"
            ;;
        idonly)
            filename="${container_id}.compose.yml"
            ;;
        both|*)
            filename="${container_name}-${container_id}.compose.yml"
            ;;
    esac
    
    output_file="${OUTPUT_DIR}/${filename}"
    
    echo "Exporting $container_name ($container_id)..."
    
    # Run autocompose and export to file
    if docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "$AUTOCOMPOSE_IMAGE" \
        "$container_id" > "$output_file" 2>&1; then
        success "✓ Exported: $output_file"
        return 0
    else
        warn "Failed to export $container_name"
        rm -f "$output_file"  # Clean up partial file
        return 1
    fi
}

#############################################################################
# Main Script
#############################################################################

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --nameonly)
            NAMING_MODE="nameonly"
            shift
            ;;
        --idonly)
            NAMING_MODE="idonly"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            error_exit "Unknown option: $1\nUse -h or --help for usage information"
            ;;
    esac
done

# Validate and create output directory
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR" || error_exit "Could not create output directory: $OUTPUT_DIR"
fi

# Pre-flight checks
check_docker
pull_autocompose_image

# Get all container IDs
mapfile -t CONTAINER_IDS < <(docker ps -aq)

if [[ ${#CONTAINER_IDS[@]} -eq 0 ]]; then
    warn "No containers found"
    exit 0
fi

echo ""
echo "Found ${#CONTAINER_IDS[@]} container(s) to export"
echo "Output directory: $(realpath "$OUTPUT_DIR")"
echo ""

# Export each container
SUCCESS_COUNT=0
FAIL_COUNT=0

for container_id in "${CONTAINER_IDS[@]}"; do
    if export_container "$container_id"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

# Summary
echo ""
echo "=========================================="
echo "Export complete!"
echo "Successful: $SUCCESS_COUNT"
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo "Failed: $FAIL_COUNT"
fi
echo "=========================================="

exit 0
