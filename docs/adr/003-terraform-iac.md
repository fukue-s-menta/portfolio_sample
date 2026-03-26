# ADR-003: Terraform による IaC 管理

## Status

Accepted

## Context

インフラをコードで管理し、再現可能なデプロイを実現する必要がある。
ポートフォリオとして、IaC スキルを実証する目的もある。

## Options

### Option A: Terraform

- HCL による宣言的記述
- マルチクラウド対応
- 求人市場での需要が最も高い
- State 管理が別途必要（S3 + DynamoDB）
- 豊富なプロバイダーとモジュールエコシステム

### Option B: AWS CloudFormation

- AWS ネイティブ（追加ツール不要）
- State は AWS が管理
- YAML/JSON 記述（冗長になりやすい）
- AWS 以外では使えない

### Option C: AWS CDK

- TypeScript/Python 等のプログラミング言語で記述
- CloudFormation を内部生成
- 型安全・IDE補完が使える
- 抽象度が高く、実際のリソース構成が見えにくい

## Decision

**Option A: Terraform** を採用する。

## Reasoning

1. **市場価値**: 2024-2025年の求人動向では Terraform スキルの需要が最も高い。ポートフォリオとしてのアピール力を最大化するため

2. **汎用性**: AWS 以外のクラウドでも使えるスキルであり、キャリアの選択肢を広げる

3. **モジュール構成**: `modules/` でリソースを分離管理でき、コードの再利用性と可読性が高い

4. **トレードオフ**: State 管理が別途必要だが、初期は local backend で開始し、後からS3 backend に移行可能。State の仕組みを理解すること自体が学習価値になる
