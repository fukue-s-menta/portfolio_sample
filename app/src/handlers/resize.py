"""Resize handler — triggered by S3 event, creates thumbnail/medium/large versions."""

import io
import json
import logging
import os
import urllib.parse
from datetime import datetime, timezone

import boto3
from PIL import Image

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

S3_BUCKET = os.environ["S3_BUCKET"]
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
CLOUDFRONT_DOMAIN = os.environ["CLOUDFRONT_DOMAIN"]
table = dynamodb.Table(TABLE_NAME)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

RESIZE_CONFIGS = {
    "thumb":  {"width": 150, "height": 150, "crop": True},
    "medium": {"width": 800, "height": None, "crop": False},
    "large":  {"width": 1920, "height": None, "crop": False},
}


def handler(event, context):
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        if not key.startswith("original/"):
            continue

        filename = key.split("/")[-1]
        image_id = filename.rsplit(".", 1)[0]
        ext = filename.rsplit(".", 1)[1]

        try:
            response = s3.get_object(Bucket=bucket, Key=key)
            original_image = Image.open(io.BytesIO(response["Body"].read()))
        except Exception as e:
            logger.error("Failed to open image %s: %s", key, e)
            now = datetime.now(timezone.utc).isoformat()
            table.update_item(
                Key={"image_id": image_id},
                UpdateExpression="SET #status = :status, error_message = :err, updated_at = :now",
                ExpressionAttributeNames={"#status": "status"},
                ExpressionAttributeValues={
                    ":status": "error",
                    ":err": str(e),
                    ":now": now,
                },
            )
            continue

        resized_urls = {}

        for size_name, config in RESIZE_CONFIGS.items():
            resized = _resize_image(original_image, config)
            if resized is None:
                continue

            output_key = f"resized/{image_id}_{size_name}.{ext}"
            buffer = io.BytesIO()
            img_format = "JPEG" if ext in ("jpg", "jpeg") else ext.upper()
            resized.save(buffer, format=img_format, quality=85)
            buffer.seek(0)

            s3.put_object(
                Bucket=S3_BUCKET,
                Key=output_key,
                Body=buffer.getvalue(),
                ContentType=f"image/{ext}",
            )

            resized_urls[size_name] = f"https://{CLOUDFRONT_DOMAIN}/{output_key}"

        now = datetime.now(timezone.utc).isoformat()
        table.update_item(
            Key={"image_id": image_id},
            UpdateExpression="SET #status = :status, resized_urls = :urls, updated_at = :now",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={
                ":status": "ready",
                ":urls": resized_urls,
                ":now": now,
            },
        )

    return {"statusCode": 200, "body": json.dumps({"message": "Resize complete"})}


def _resize_image(image, config):
    """Resize a single image according to config. Returns None if upscale would be needed."""
    width = config["width"]
    height = config["height"]
    crop = config["crop"]

    orig_w, orig_h = image.size

    if crop and height:
        # Center crop to exact dimensions (don't upscale)
        if orig_w < width or orig_h < height:
            return None
        ratio = max(width / orig_w, height / orig_h)
        resized = image.resize(
            (int(orig_w * ratio), int(orig_h * ratio)),
            Image.LANCZOS,
        )
        left = (resized.width - width) // 2
        top = (resized.height - height) // 2
        return resized.crop((left, top, left + width, top + height))
    else:
        # Resize by width, maintain aspect ratio (don't upscale)
        if orig_w <= width:
            return None
        ratio = width / orig_w
        new_height = int(orig_h * ratio)
        return image.resize((width, new_height), Image.LANCZOS)
