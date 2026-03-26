# ADR-005: CloudFront による画像配信

## Status

Accepted

## Context

リサイズ済み画像をエンドユーザーに配信する方法を決定する必要がある。
画像は世界中からアクセスされる可能性があり、低レイテンシ配信が望ましい。

## Options

### Option A: Amazon CloudFront + S3 OAC

- エッジロケーションからのキャッシュ配信
- S3 への直接アクセスを遮断（OAC で CloudFront 経由のみ）
- 1TB/月の無料枠
- SSL 証明書自動管理

### Option B: S3 静的ウェブサイトホスティング

- S3 バケットを直接公開
- CloudFront なし（レイテンシは S3 リージョンに依存）
- 設定がシンプル
- S3 バケットポリシーでパブリック公開が必要

### Option C: API Gateway 経由の画像配信

- 全リクエストが API Gateway → Lambda → S3 を経由
- API Gateway のデータ転送料金が発生
- レイテンシが高い
- キャッシュが効きにくい

## Decision

**Option A: Amazon CloudFront + S3 OAC** を採用する。

## Reasoning

1. **セキュリティ**: S3 バケットをパブリック公開せず、CloudFront 経由のみでアクセス可能にする。OAC（Origin Access Control）により、S3 への直接アクセスを完全に遮断

2. **パフォーマンス**: エッジキャッシュにより、世界中から低レイテンシ（< 50ms）で画像を配信。S3 直接アクセスだとリージョン間のレイテンシが発生する

3. **コスト**: 1TB/月の無料枠があり、個人利用（月5GB程度）では無料。S3 からのデータ転送料金も CloudFront 経由の方が安価

4. **トレードオフ**: CloudFront のキャッシュ無効化（Invalidation）に数分かかるため、画像の即時差し替えには不向き。ただし、本システムでは画像の更新（上書き）は想定せず、削除 → 再アップロードのフローとするため問題にならない
