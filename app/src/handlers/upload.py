"""Upload handler — receives image via API Gateway and stores in S3."""

import base64
import os
import uuid
from datetime import datetime, timezone

import boto3

from utils.response import api_response

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

S3_BUCKET = os.environ["S3_BUCKET"]
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
table = dynamodb.Table(TABLE_NAME)

ALLOWED_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}
MAX_SIZE = 10 * 1024 * 1024  # 10MB


def handler(event, context):
    headers = event.get("headers", {})
    content_type = headers.get("Content-Type") or headers.get("content-type", "")
    if content_type not in ALLOWED_TYPES:
        return api_response(400, {"error": f"Unsupported content type: {content_type}. Allowed: {list(ALLOWED_TYPES.keys())}"})

    body = event.get("body", "")
    is_base64 = event.get("isBase64Encoded", False)
    image_data = base64.b64decode(body) if is_base64 else body.encode()

    if len(image_data) > MAX_SIZE:
        return api_response(400, {"error": f"File too large. Maximum size: {MAX_SIZE // (1024*1024)}MB"})

    image_id = str(uuid.uuid4())[:8]
    ext = ALLOWED_TYPES[content_type]
    s3_key = f"original/{image_id}{ext}"
    now = datetime.now(timezone.utc).isoformat()

    s3.put_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
        Body=image_data,
        ContentType=content_type,
    )

    table.put_item(
        Item={
            "image_id": image_id,
            "s3_key": s3_key,
            "content_type": content_type,
            "size_bytes": len(image_data),
            "status": "uploading",
            "created_at": now,
            "updated_at": now,
        }
    )

    return api_response(201, {
        "id": image_id,
        "status": "uploading",
        "message": "Image uploaded. Resize processing will start shortly.",
        "created_at": now,
    })
