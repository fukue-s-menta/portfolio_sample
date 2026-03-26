"""Delete image handler — removes original, resized images and metadata."""

import os

import boto3

from utils.response import api_response

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

S3_BUCKET = os.environ["S3_BUCKET"]
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    image_id = event["pathParameters"]["id"]

    response = table.get_item(Key={"image_id": image_id})
    item = response.get("Item")

    if not item:
        return api_response(404, {"error": "Image not found"})

    # Delete original from S3
    s3_key = item.get("s3_key")
    if s3_key:
        s3.delete_object(Bucket=S3_BUCKET, Key=s3_key)

    # Delete resized versions from S3
    ext = s3_key.rsplit(".", 1)[1] if s3_key else "jpg"
    for size_name in ("thumb", "medium", "large"):
        resized_key = f"resized/{image_id}_{size_name}.{ext}"
        s3.delete_object(Bucket=S3_BUCKET, Key=resized_key)

    # Delete metadata from DynamoDB
    table.delete_item(Key={"image_id": image_id})

    return api_response(204)
