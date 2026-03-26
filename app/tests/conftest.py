"""Shared fixtures for Lambda handler tests."""

import os
import sys
from pathlib import Path

import pytest

# Add handlers and src directories to path so imports work like in Lambda
_app_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_app_dir / "src" / "handlers"))
sys.path.insert(0, str(_app_dir / "src"))

# Set environment variables before importing handlers
os.environ["S3_BUCKET"] = "test-bucket"
os.environ["DYNAMODB_TABLE"] = "test-table"
os.environ["CLOUDFRONT_DOMAIN"] = "d123456.cloudfront.net"


@pytest.fixture
def api_gateway_event():
    """Generate a base API Gateway proxy event."""
    return {
        "httpMethod": "GET",
        "headers": {"Content-Type": "application/json"},
        "pathParameters": {},
        "queryStringParameters": None,
        "body": None,
        "isBase64Encoded": False,
    }


@pytest.fixture
def s3_event():
    """Generate a base S3 event notification."""
    return {
        "Records": [
            {
                "s3": {
                    "bucket": {"name": "test-bucket"},
                    "object": {"key": "original/abc12345.jpg"},
                }
            }
        ]
    }
