---
name: build-cruby
description: ruby/ruby (CRuby) をソースからビルドして ~/.rubies/ruby-master にインストールする手順を実行する。「CRubyビルド」「Rubyビルド」「Ruby開発環境構築」「ruby/ruby をビルド」「build cruby」「autogen.sh」「make ruby」などの発言で使用する。Rails等のRubyアプリ実行用ビルドではなく、CRuby本体への貢献（PR作成）目的のビルドに特化。
---

# build-cruby

CRuby (ruby/ruby) をソースからビルドし、`~/.rubies/ruby-master/bin/ruby` として動作する状態を作るスキル。

## 前提

- このスキルは **CRuby本体のリポジトリ** (`ruby/ruby` または fork) で実行する想定
- `doc/contributing/building_ruby.md` の **Quick start guide** が一次情報。これを最優先する
- 公式手順を改変しない。macOS 固有の追加は明示的に区別する

## 0. 一次情報の所在

最初に必ず以下を確認・参照する:

- `doc/contributing/building_ruby.md` の "Quick start guide" セクション
- このスキルの記述と公式 doc が乖離していたら、**公式 doc を信じてスキルを更新する**

## 1. 依存確認 (macOS / Homebrew)

公式 doc が要求する依存:
- C compiler / OpenSSL / libyaml / zlib / autoconf 2.67+ / ruby 3.1+ / git 2.32+
- 推奨: libffi, gmp, rustc (YJIT 用)
- gperf 3.1+ は通常不要（gperf を使うソースを編集する場合のみ）

確認コマンド:

```sh
# 必須
clang --version
git --version
ruby --version    # 3.1+ が必要

# brew パッケージ（macOS）
for pkg in autoconf openssl@3 libyaml zlib libffi gmp; do
  prefix=$(brew --prefix "$pkg" 2>/dev/null)
  if [ -d "$prefix" ]; then
    echo "$pkg: OK ($prefix)"
  else
    echo "$pkg: MISSING"
  fi
done
```

**重要**: `brew --prefix <pkg>` は formula が定義されていれば **未インストールでもパスを返す**。必ずディレクトリ存在を確認すること。

未インストールがあれば:
```sh
brew install <missing-package>
```

## 2. 公式 Quick start guide（原文ママ）

`doc/contributing/building_ruby.md` L86-143 に基づく:

```sh
# (CRuby リポジトリのルートで)
./autogen.sh
mkdir build && cd build
mkdir ~/.rubies
../configure --prefix="${HOME}/.rubies/ruby-master"
make
make install
~/.rubies/ruby-master/bin/ruby -e "puts 'Hello, World!'"
```

## 3. 公式に記載のある追加オプション

これらは公式 doc 内に記載があるので、必要に応じて使ってよい:

### 3.1 並列ビルド (公式 L196-202)

```sh
make -j$(sysctl -n hw.ncpu)   # macOS
make -j$(nproc)               # Linux
```

### 3.2 configure 結果のキャッシュ (公式 L118)

```sh
../configure -C --prefix=...
```

### 3.3 brew で入れたライブラリのパス指定 (公式 L34-54)

公式が提示する2パターン:

**(a) 一般ライブラリ (gmp, jemalloc 等):**
```sh
../configure --with-opt-dir=$(brew --prefix gmp):$(brew --prefix jemalloc)
```

**(b) 拡張ライブラリ (openssl/readline/libyaml/zlib):**
```sh
export CONFIGURE_ARGS=""
for ext in openssl@3 readline libyaml zlib; do
  CONFIGURE_ARGS="${CONFIGURE_ARGS} --with-$ext-dir=$(brew --prefix $ext)"
done
```

これらは **bundled gem の extension（fiddle, bigdecimal 等）がスキップされた場合** に検討する。素の `configure` でも CRuby 本体のビルドは成功する。

## 4. 公式に記載のない補足（経験則・明示ラベル）

以下は私の経験則であり、公式 doc には書かれていない。**鵜呑みにせず、必要に応じて使う**:

- **[経験則]** macOS で必要な追加 brew パッケージは多くの場合 `autoconf` のみ。他（openssl@3 等）は既にユーザー環境にあることが多い
- **[経験則]** `mkdir build` は、build ディレクトリが既にあると失敗する。再ビルド時は `cd build` で進める。完全に綺麗にするなら `git clean -xfd` (公式 L178-182 に記載)
- **[経験則]** `make install` 後の "skipped bundled gems" 警告（fiddle/bigdecimal/debug/nkf/racc/rbs/syslog/win32ole）は、CRuby 本体の動作には影響しない。これらが必要になったら 3.3 のフラグを足して再ビルド

## 5. ビルド成功の確認

```sh
~/.rubies/ruby-master/bin/ruby --version
# → ruby 4.x.0dev (... <git short hash>) +PRISM [arm64-darwin25] のような出力
~/.rubies/ruby-master/bin/ruby -e "puts 'Hello, World!'"
```

`ruby --version` の git short hash が `git rev-parse --short HEAD` と一致することを確認すれば、確実に手元のソースからビルドされたバイナリ。

## 6. doc 変更の preview（ドキュメント PR 用）

```sh
cd build
make html-server
# → http://localhost:4000 でライブリロード
```

公式 doc には `make html-server` の記載が直接ないが、ビルド済みターゲットとして存在する。pathname 等の RDoc 変更時に活用する。

## 7. デバッグビルド (公式 L261-282)

通常ビルドではなく、デバッグ用に `RUBY_DEBUG` を有効にしたい場合:

```sh
../configure cppflags="-DRUBY_DEBUG=1 -DUSE_RUBY_DEBUG_LOG=1" \
  --enable-debug-env \
  optflags="-O0 -fno-omit-frame-pointer" \
  --prefix="${HOME}/.rubies/ruby-debug"
```

## トラブルシューティング

### configure で OpenSSL が見つからない

→ 3.3(b) の `CONFIGURE_ARGS` でパスを渡す

### 「謎のビルドエラー」(公式 L176-182)

→ `git clean -xfd` で過去ビルドの残骸を削除してから再実行

### make が即失敗 (cwd 問題)

→ `pwd` で `build` ディレクトリ内にいるか確認。スクリプト・バックグラウンド実行の cwd は予測しづらいので、心配なら `cd /absolute/path/to/ruby/build && make ...` のように絶対パスで実行

## 実行時間の目安

- `./autogen.sh`: 数秒
- `../configure`: 1〜3分
- `make -j16` (Apple Silicon 16core): 10〜20分
- `make install`: 1〜2分

長時間ビルド中は `tee /tmp/cruby-make.log` でログを残し、`tail -f` で進捗を眺めると良い。
