---
name: rspec-refactor
description: RSpec リファクタリング
---

# RSpec リファクタリング

RSpecテストコードを分析し、可読性・保守性・実行速度の観点からリファクタリングを提案・実行します。

## 参照ガイド

- **RSpec**: `~/.claude/references/rspec-guide.md`

## 使用方法

```
/rspec-refactor <specファイルパス>
```

## 引数

- `$ARGUMENTS`: 対象specファイルのパス（必須）

## 実行手順

### Phase 1: 現状分析

1. 対象ファイルを読み込む
2. 以下の観点で問題点を特定：
   - テスト構造の可読性（describe/context/itの階層）
   - DRY原則（let vs let!、shared_examples）
   - 実行速度（build vs create、不要なデータ作成）
   - マッチャーの最適化
   - FactoryBotの使い方

### Phase 2: リファクタリング提案

1. 発見した問題点をリスト化
2. 優先度付け：実行速度 > 可読性 > DRY
3. ユーザーに提案内容を確認

### Phase 3: 修正実行

1. ユーザー承認後、段階的に修正
2. 各修正後にテストが通ることを確認
   ```bash
   docker compose run --rm app bin/rspec <specファイルパス>
   ```

## チェックリスト

- [ ] `let!` より `let` を優先しているか
- [ ] `create` より `build` / `build_stubbed` を使えないか
- [ ] `allow_any_instance_of` を使っていないか
- [ ] beforeブロック1行なら `{}` 形式か
- [ ] `subject { -> { ... } }` のlambda記法を使っていないか
- [ ] 各contextは独立しているか
- [ ] 不要なデータ作成はないか

## 注意事項

- **テストの独立性を維持**: 各テストは他に依存しない
- **過度なDRYは避ける**: テストは「新聞記事」のように読めることが重要
- **データ操作で状態を作らない**: `destroy!`より「最初から作らない」
