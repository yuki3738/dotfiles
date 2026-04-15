#!/usr/bin/env bash
# GitHub PRレビュー依頼のうち未対応のものを取得する。
#
# - 個人（--review-requested=@me）とチーム（--review-requested=movinc/<team>）の両方を検索
# - Draft除外
# - Approve/Request Changes済みのPRは自動的にreview-requestedから外れるため、
#   このリストに残っているPRはすべて "要アクション" とみなせる（re-requestもここに現れる）
# - 対象org: movinc
#
# Usage: github_pending_reviews.sh [team-slug ...]
#   team-slug を渡さない場合はデフォルトのチーム一覧（自分のmovincチーム）を使用

set -euo pipefail

OWNER=movinc
DEFAULT_TEAMS=(product flamingo-fy2024 kaizen hiring)

teams=("$@")
if [ ${#teams[@]} -eq 0 ]; then
  teams=("${DEFAULT_TEAMS[@]}")
fi

tmp=$(mktemp)
trap "rm -f $tmp" EXIT

# 個人アサイン
gh search prs \
  --review-requested=@me \
  --state=open \
  --owner="$OWNER" \
  --limit=100 \
  --json number,title,url,repository,author,updatedAt,isDraft \
  | jq '[.[] | select(.isDraft == false) | . + {assignedVia: "personal"}]' \
  > "$tmp.personal"

# チームアサイン（チームごとにクエリ）
echo "[]" > "$tmp.team"
for team in "${teams[@]}"; do
  gh search prs \
    --review-requested="$OWNER/$team" \
    --state=open \
    --owner="$OWNER" \
    --limit=100 \
    --json number,title,url,repository,author,updatedAt,isDraft \
    | jq --arg t "$team" '[.[] | select(.isDraft == false) | . + {assignedVia: ("team:" + $t)}]' \
    > "$tmp.team_this"
  jq -s '.[0] + .[1]' "$tmp.team" "$tmp.team_this" > "$tmp.team.merged"
  mv "$tmp.team.merged" "$tmp.team"
done

# 重複排除（個人と複数チームで同じPRが引っかかる）
jq -s '
  (.[0] + .[1])
  | group_by(.url)
  | map({
      number: .[0].number,
      title: .[0].title,
      url: .[0].url,
      repository: .[0].repository.nameWithOwner,
      author: .[0].author.login,
      updatedAt: .[0].updatedAt,
      assignedVia: (map(.assignedVia) | unique | join(", "))
    })
  | sort_by(.updatedAt)
  | reverse
' "$tmp.personal" "$tmp.team"
