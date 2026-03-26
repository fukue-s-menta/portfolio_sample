"""Get image handler — returns metadata and CDN URLs for a given image ID."""

import os

import boto3

from utils.response import api_response

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    image_id = event["pathParameters"]["id"]

    response = table.get_item(Key={"image_id": image_id})
    item = response.get("Item")

    if not item:
        return api_response(404, {"error": "Image not found"})

    return api_response(200, {
        "id": item["image_id"],
        "status": item["status"],
        "content_type": item.get("content_type"),
        "size_bytes": item.get("size_bytes"),
        "resized_urls": item.get("resized_urls", {}),
        "created_at": item["created_at"],
        "updated_at": item.get("updated_at"),
    })
