# ADR-002: DynamoDB の採用（RDS 不採用）

## Status

Accepted

## Context

画像メタデータ（ID, URL, サイズ, 作成日時等）を永続化するデータベースが必要。
アクセスパターンは以下の通り:

- 画像 ID をキーとした単一レコードの CRUD
- 複雑な結合クエリや集計は不要
- 低レイテンシでの読み取りが必要

## Options

### Option A: Amazon DynamoDB

- Key-Value / ドキュメントDB
- VPC 不要（Lambda から直接アクセス）
- オンデマンドモードで低トラフィック時のコスト最小
- 25GB + 25 WCU/RCU が常時無料

### Option B: Amazon RDS (PostgreSQL)

- フル SQL 対応
- VPC 内配置が必須 → NAT Gateway が必要
- 最小構成（t3.micro）でも ~$15/月
- 豊富なクエリ柔軟性

### Option C: S3 メタデータ（オブジェクトタグ）

- 追加サービス不要
- S3 オブジェクトのタグ/メタデータに情報を付与
- クエリ性能が低い（ListObjects が必要）
- 柔軟なメタデータ管理が困難

## Decision

**Option A: Amazon DynamoDB** を採用する。

## Reasoning

1. **アクセスパターンとの適合**: 画像 ID をパーティションキーとした Key-Value アクセスが中心であり、DynamoDB の得意とするパターンに完全に一致する

2. **コスト**: RDS は VPC 内配置が必須で、Lambda からアクセスするには NAT Gateway（~$32/月）が追加で必要。DynamoDB は VPC 不要で、低トラフィック時は実質無料

3. **運用負荷**: フルマネージドでバックアップも自動。RDS はパッチ適用やストレージ管理が必要

4. **トレードオフ**: 将来的に「ユーザー別の画像一覧」「タグ検索」等の複雑なクエリが必要になった場合、GSI（グローバルセカンダリインデックス）の追加やクエリ設計の見直しが必要。ただし現時点の MVP ではシンプルなアクセスパターンで十分
