#!/bin/bash

# ユーザーに選択を求める際に音を鳴らす
afplay /System/Library/Sounds/Purr.aiff

# 音声での通知も追加する場合（オプション）
# say "選択をお願いします"

# 標準入力からJSONを読み込んで標準出力にそのまま返す
cat