---
name: rubocop-todo-fix
description: RuboCop違反解消 & PR作成ワークフロー
---

rubocop_todo.ymlから指定ファイルの除外を解消し、テストを拡充してPRを作成する。

## 参照ガイド

- **RSpec**: `~/.claude/references/rspec-guide.md`
- **RuboCop**: `~/.claude/references/rubocop-guide.md`

## 使用方法

```
/rubocop-todo-fix <ファイルパス>
```

例: `/rubocop-todo-fix app/controllers/biz/api/companies/registrations/info_controller.rb`

## 引数

- `$ARGUMENTS`: 対象ファイルのパス（必須）

## 実行手順

### Phase 1: 事前確認

1. **引数チェック**
   - `$ARGUMENTS` が空の場合、ユーザーにファイルパスを確認する
   - ファイルが存在するか確認する

2. **rubocop_todo.yml確認**
   - 対象ファイルが `.rubocop_todo.yml` に含まれているか確認
   - どのCop（違反ルール）で除外されているか特定

3. **現在のRuboCop違反を確認**
   ```bash
   docker compose run --rm app bundle exec rubocop <ファイルパス> --format json
   ```

### Phase 2: テスト拡充（実装修正前に必ず実施）

テスト拡充は実装修正の**前**に行う。これにより：
- 現在の挙動をテストでカバーする
- 修正後にテストが通れば「挙動が変わっていない」ことを証明できる

#### チェックリスト（全て完了するまでPhase 3に進まない）

- [ ] **1. RSpecファイルを探した**
- [ ] **2. 不足テストを特定した**
- [ ] **3. 不足テストを追加した**
- [ ] **4. テストが通ることを確認した**

### Phase 3: RuboCop違反解消

1. **違反を修正**
2. **rubocop_todo.ymlから削除**
3. **RuboCop再実行で確認**

### Phase 4: コードレビュー

1. **codexにレビューを依頼**

### Phase 5: Git操作 & PR作成

1. **ブランチ作成**
2. **コミット作成**
3. **プッシュ & PR作成**

## 制約事項

- テストが通らない状態でPRを作成しない
- 挙動を変える修正を行う場合は、既存テストを変更するのではなく実装を見直す
- セキュリティに関わる変更は慎重に行う
- 変更範囲外のコードは修正しない
