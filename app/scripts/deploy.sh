#!/bin/bash
set -euo pipefail

# Lambda function deployment script
# Usage: ./deploy.sh [function_name]
# If no function name is specified, all functions are deployed.

PROJECT_NAME="serverless-image-resize"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${APP_DIR}/build"
HANDLERS_DIR="${APP_DIR}/src/handlers"

deploy_function() {
    local func_name=$1
    local handler_file=$2
    local zip_file="${BUILD_DIR}/${func_name}.zip"

    echo "==> Deploying ${func_name}..."

    mkdir -p "${BUILD_DIR}"
    rm -f "${zip_file}"

    # Create deployment package
    cd "${APP_DIR}"
    zip -j "${zip_file}" "${handler_file}"

    # Add utils
    cd "${APP_DIR}/src"
    zip -r "${zip_file}" utils/

    # Update Lambda function
    aws lambda update-function-code \
        --function-name "${PROJECT_NAME}-${func_name}" \
        --zip-file "fileb://${zip_file}" \
        --no-cli-pager

    echo "    Done: ${func_name}"
}

# Deploy specified function or all functions
case "${1:-all}" in
    upload)
        deploy_function "upload" "${HANDLERS_DIR}/upload.py"
        ;;
    resize)
        deploy_function "resize" "${HANDLERS_DIR}/resize.py"
        ;;
    get)
        deploy_function "get" "${HANDLERS_DIR}/get_image.py"
        ;;
    delete)
        deploy_function "delete" "${HANDLERS_DIR}/delete_image.py"
        ;;
    all)
        deploy_function "upload" "${HANDLERS_DIR}/upload.py"
        deploy_function "resize" "${HANDLERS_DIR}/resize.py"
        deploy_function "get" "${HANDLERS_DIR}/get_image.py"
        deploy_function "delete" "${HANDLERS_DIR}/delete_image.py"
        ;;
    *)
        echo "Usage: $0 [upload|resize|get|delete|all]"
        exit 1
        ;;
esac

echo "==> Deployment complete!"
