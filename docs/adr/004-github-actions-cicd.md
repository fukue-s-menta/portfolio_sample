# ADR-004: GitHub Actions による CI/CD

## Status

Accepted

## Context

コード変更を安全かつ自動的にデプロイする CI/CD パイプラインが必要。
個人プロジェクトのため、コストと運用負荷を最小化したい。

## Options

### Option A: GitHub Actions

- GitHub リポジトリと完全統合
- パブリックリポジトリは無料、プライベートでも 2,000分/月無料
- YAML ベースのワークフロー定義
- 豊富な公式/コミュニティアクション

### Option B: AWS CodePipeline + CodeBuild

- AWS ネイティブで IAM 統合が容易
- CodePipeline: $1/パイプライン/月
- CodeBuild: ビルド時間課金
- AWS 固有のエコシステム

### Option C: CircleCI

- 高機能な CI/CD プラットフォーム
- 無料枠: 6,000分/月
- GitHub リポジトリと連携可能
- 別サービスの管理が必要

## Decision

**Option A: GitHub Actions** を採用する。

## Reasoning

1. **コスト**: 無料枠が十分（2,000分/月）で、個人利用では料金が発生しない

2. **統合性**: コード・Issue・PR・CI/CD が GitHub に一元化され、管理が容易。PR に `terraform plan` の結果を自動コメントでき、レビュー体験が向上する

3. **普及率**: 2024年時点で最も普及している CI/CD ツールであり、チーム開発でも知見が活かせる

4. **トレードオフ**: AWS 環境へのデプロイには OIDC 連携 or IAM アクセスキーの設定が必要。OIDC 連携を採用し、長期的な認証情報の管理を回避する
