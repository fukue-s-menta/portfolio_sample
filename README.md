# Serverless Image Resize API

> AWS サーバーレスアーキテクチャで構築した、画像アップロード・自動リサイズ API

![Architecture](docs/images/architecture.png)

## Overview

S3 にアップロードされた画像を Lambda で自動リサイズし、CloudFront 経由で高速配信するサーバーレス API です。
インフラは Terraform で完全にコード化し、GitHub Actions による CI/CD パイプラインを構築しています。

## Architecture

```
Client
  │
  ▼
API Gateway (REST API)
  ├── POST /images → Upload Lambda → S3 (original/)
  │                                    │
  │                          S3 Event Trigger
  │                                    ▼
  │                              Resize Lambda → S3 (resized/)
  │                                    │
  │                              DynamoDB (metadata)
  │
  ├── GET /images/{id} → Get Lambda → DynamoDB → CloudFront URL
  │
  └── DELETE /images/{id} → Delete Lambda → S3 + DynamoDB
                                    │
CloudFront ◄────────────────────────┘
  │
  ▼
End User (optimized image delivery)
```

### Tech Stack

| Category | Technology |
|----------|-----------|
| Compute | AWS Lambda (Python 3.12) |
| API | Amazon API Gateway (REST) |
| Storage | Amazon S3 |
| Database | Amazon DynamoDB |
| CDN | Amazon CloudFront |
| IaC | Terraform v1.7+ |
| CI/CD | GitHub Actions |
| Monitoring | Amazon CloudWatch |

## Design Points

### 1. コスト最適化設計 — 月額 $1〜3 運用

Lambda + DynamoDB + S3 の無料枠を最大限活用し、個人利用なら月額 $1〜3 で運用可能な設計にしています。NAT Gateway を使わずVPCレス構成とすることで、固定費を排除しました。

→ 詳細: [docs/cost-estimate.md](docs/cost-estimate.md)

### 2. ADR による設計判断の明文化

「なぜサーバーレスか」「なぜ DynamoDB か」といった設計判断を ADR (Architecture Decision Record) として記録しています。技術選定の思考プロセスを可視化することで、再現性のある意思決定を実現しています。

→ 詳細: [docs/adr/](docs/adr/)

### 3. IaC + CI/CD による再現可能なインフラ

Terraform モジュール構成でインフラを管理し、PR ごとに `terraform plan` が自動実行されます。main マージ時に自動デプロイされるため、手動オペレーションが不要です。

→ 詳細: [infra/](infra/)

## Getting Started

### Prerequisites

- AWS CLI v2 configured
- Terraform >= 1.7
- Python >= 3.12
- Docker (Lambda レイヤービルド用)

### Setup

```bash
# 1. リポジトリをクローン
git clone https://github.com/your-username/serverless-image-resize-api.git
cd serverless-image-resize-api

# 2. Terraform で AWS リソースをデプロイ
cd infra
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を環境に合わせて編集
terraform init
terraform plan
terraform apply

# 3. Lambda 関数のデプロイ
cd ../app
pip install -r requirements.txt -t package/
# deploy スクリプトで Lambda を更新
./scripts/deploy.sh

# 4. 動作確認
API_URL=$(cd ../infra && terraform output -raw api_endpoint)
# 画像アップロード
curl -X POST "${API_URL}/images" \
  -H "Content-Type: image/jpeg" \
  --data-binary @sample.jpg

# 画像取得
curl "${API_URL}/images/{image-id}"
```

## API Reference

### POST /images

画像をアップロードし、リサイズ処理をトリガーします。

```
POST /images
Content-Type: image/jpeg | image/png | image/webp

Response: 201 Created
{
  "id": "abc123",
  "original_url": "https://cdn.example.com/original/abc123.jpg",
  "resized_urls": {
    "thumbnail": "https://cdn.example.com/resized/abc123_thumb.jpg",
    "medium": "https://cdn.example.com/resized/abc123_medium.jpg",
    "large": "https://cdn.example.com/resized/abc123_large.jpg"
  },
  "created_at": "2026-01-15T10:30:00Z"
}
```

### GET /images/{id}

画像メタデータと配信 URL を取得します。

```
GET /images/{id}

Response: 200 OK
{
  "id": "abc123",
  "original_url": "https://cdn.example.com/original/abc123.jpg",
  "resized_urls": { ... },
  "size_bytes": 245000,
  "content_type": "image/jpeg",
  "created_at": "2026-01-15T10:30:00Z"
}
```

### DELETE /images/{id}

画像とメタデータを削除します。

```
DELETE /images/{id}

Response: 204 No Content
```

## Cost Estimate

| Service | Monthly Cost | Note |
|---------|-------------|------|
| Lambda | $0.00 | 無料枠: 100万リクエスト/月 |
| API Gateway | $0.00〜0.35 | 100万リクエストあたり $3.50 |
| S3 | $0.02〜0.10 | ストレージ + リクエスト |
| DynamoDB | $0.00 | 無料枠: 25GB + 25 WCU/RCU |
| CloudFront | $0.00〜0.50 | 無料枠: 1TB/月 |
| CloudWatch | $0.00 | 基本メトリクス無料 |
| **合計** | **$0.02〜$0.95** | 個人利用（月1,000リクエスト想定） |

→ 詳細: [docs/cost-estimate.md](docs/cost-estimate.md)

## Project Structure

```
.
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── requirements.md          # 要件定義
│   ├── architecture.md          # アーキテクチャ設計書
│   ├── cost-estimate.md         # コスト見積もり
│   ├── images/                  # 図版
│   │   └── architecture.png
│   └── adr/                     # Architecture Decision Records
│       ├── 001-serverless-architecture.md
│       ├── 002-dynamodb-over-rds.md
│       ├── 003-terraform-iac.md
│       ├── 004-github-actions-cicd.md
│       └── 005-cloudfront-cdn.md
├── infra/                       # Terraform IaC
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── api_gateway/
│       ├── lambda/
│       ├── s3/
│       ├── dynamodb/
│       ├── cloudfront/
│       └── iam/
├── app/                         # Application
│   ├── src/
│   │   ├── handlers/
│   │   │   ├── upload.py
│   │   │   ├── resize.py
│   │   │   ├── get_image.py
│   │   │   └── delete_image.py
│   │   └── utils/
│   │       ├── image_processor.py
│   │       └── response.py
│   ├── tests/
│   │   ├── test_upload.py
│   │   ├── test_resize.py
│   │   └── conftest.py
│   ├── requirements.txt
│   └── scripts/
│       └── deploy.sh
└── .github/
    └── workflows/
        ├── ci.yml
        └── deploy.yml
```

## Design Documents

| Document | Description |
|----------|------------|
| [Requirements](docs/requirements.md) | 機能・非機能要件の定義 |
| [Architecture](docs/architecture.md) | アーキテクチャ設計とサービス選定理由 |
| [Cost Estimate](docs/cost-estimate.md) | 月額コスト見積もりと最適化方針 |
| [ADR-001: Serverless](docs/adr/001-serverless-architecture.md) | サーバーレス採用の判断 |
| [ADR-002: DynamoDB](docs/adr/002-dynamodb-over-rds.md) | DynamoDB 選定の判断 |
| [ADR-003: Terraform](docs/adr/003-terraform-iac.md) | Terraform 採用の判断 |
| [ADR-004: GitHub Actions](docs/adr/004-github-actions-cicd.md) | CI/CD 基盤の判断 |
| [ADR-005: CloudFront](docs/adr/005-cloudfront-cdn.md) | CDN 構成の判断 |

## License

MIT License - see [LICENSE](LICENSE) for details.
