"""Tests for upload handler."""

import base64
import json
from unittest.mock import MagicMock, patch

import pytest


@patch("upload.dynamodb")
@patch("upload.s3")
def test_upload_jpeg_success(mock_s3, mock_dynamodb, api_gateway_event):
    """JPEG image upload should return 201 with image ID."""
    from upload import handler

    mock_table = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    image_data = b"\xff\xd8\xff\xe0" + b"\x00" * 100  # minimal JPEG header
    api_gateway_event["headers"]["Content-Type"] = "image/jpeg"
    api_gateway_event["body"] = base64.b64encode(image_data).decode()
    api_gateway_event["isBase64Encoded"] = True

    response = handler(api_gateway_event, None)

    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert "id" in body
    assert body["status"] == "uploading"
    mock_s3.put_object.assert_called_once()
    mock_table.put_item.assert_called_once()


@patch("upload.dynamodb")
@patch("upload.s3")
def test_upload_unsupported_type(mock_s3, mock_dynamodb, api_gateway_event):
    """Unsupported content type should return 400."""
    from upload import handler

    api_gateway_event["headers"]["Content-Type"] = "text/plain"
    api_gateway_event["body"] = "not an image"

    response = handler(api_gateway_event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "Unsupported content type" in body["error"]


@patch("upload.dynamodb")
@patch("upload.s3")
def test_upload_file_too_large(mock_s3, mock_dynamodb, api_gateway_event):
    """File exceeding 10MB should return 400."""
    from upload import handler

    mock_table = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    large_data = b"\x00" * (11 * 1024 * 1024)  # 11MB
    api_gateway_event["headers"]["Content-Type"] = "image/png"
    api_gateway_event["body"] = base64.b64encode(large_data).decode()
    api_gateway_event["isBase64Encoded"] = True

    response = handler(api_gateway_event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "too large" in body["error"]
