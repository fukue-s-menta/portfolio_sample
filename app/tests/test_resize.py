"""Tests for resize handler."""

import io
from unittest.mock import MagicMock, patch

import pytest
from PIL import Image


def _create_test_image(width=2000, height=1500):
    """Create an in-memory test image."""
    img = Image.new("RGB", (width, height), color="red")
    buffer = io.BytesIO()
    img.save(buffer, format="JPEG")
    buffer.seek(0)
    return buffer.getvalue()


@patch("resize.dynamodb")
@patch("resize.s3")
def test_resize_creates_three_sizes(mock_s3, mock_dynamodb, s3_event):
    """S3 event should trigger creation of thumb, medium, large versions."""
    from resize import handler

    mock_table = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    image_bytes = _create_test_image()
    mock_s3.get_object.return_value = {
        "Body": MagicMock(read=MagicMock(return_value=image_bytes))
    }

    handler(s3_event, None)

    # 3 resized images uploaded
    assert mock_s3.put_object.call_count == 3

    # DynamoDB updated with status "ready"
    mock_table.update_item.assert_called_once()
    call_kwargs = mock_table.update_item.call_args[1]
    assert call_kwargs["ExpressionAttributeValues"][":status"] == "ready"


@patch("resize.dynamodb")
@patch("resize.s3")
def test_resize_skips_small_image(mock_s3, mock_dynamodb, s3_event):
    """Small images should skip sizes that would require upscaling."""
    from resize import handler

    mock_table = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    # 100x100 image — too small for all resize targets
    image_bytes = _create_test_image(width=100, height=100)
    mock_s3.get_object.return_value = {
        "Body": MagicMock(read=MagicMock(return_value=image_bytes))
    }

    handler(s3_event, None)

    # No resized images should be created (all would upscale)
    assert mock_s3.put_object.call_count == 0


@patch("resize.dynamodb")
@patch("resize.s3")
def test_resize_handles_invalid_image(mock_s3, mock_dynamodb, s3_event):
    """Invalid image data should set status to 'error' instead of crashing."""
    from resize import handler

    mock_table = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    mock_s3.get_object.return_value = {
        "Body": MagicMock(read=MagicMock(return_value=b"not-an-image"))
    }

    handler(s3_event, None)

    # DynamoDB should be updated with error status
    mock_table.update_item.assert_called_once()
    call_kwargs = mock_table.update_item.call_args[1]
    assert call_kwargs["ExpressionAttributeValues"][":status"] == "error"
