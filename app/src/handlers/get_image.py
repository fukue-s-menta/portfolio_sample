"""Get image handler — returns metadata and CDN URLs for a given image ID."""

import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    image_id = event["pathParameters"]["id"]

    response = table.get_item(Key={"image_id": image_id})
    item = response.get("Item")

    if not item:
        return _response(404, {"error": "Image not found"})

    return _response(200, {
        "id": item["image_id"],
        "status": item["status"],
        "content_type": item.get("content_type"),
        "size_bytes": item.get("size_bytes"),
        "resized_urls": item.get("resized_urls", {}),
        "created_at": item["created_at"],
        "updated_at": item.get("updated_at"),
    })


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }
