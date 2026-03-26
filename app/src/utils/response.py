"""Shared response helper for Lambda handlers."""

import json


def api_response(status_code, body=None):
    """Build a standard API Gateway proxy response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body) if body else "",
    }
