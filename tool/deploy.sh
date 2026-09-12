#!/usr/bin/env bash
# GitHub Pages に出す。プロジェクトルートで `bash tool/deploy.sh` と叩く。
#
# gh-pages ブランチは「その時点のビルド結果1コミット」だけを持つ使い捨てにしてある。
# 45MB あるビルド成果物を積み上げるとリポジトリがすぐ膨らむので、毎回上書きする。
set -euo pipefail

REPO=git@github.com:yuusaku000/sunstory.git
BASE_HREF=/sunstory/   # プロジェクトページなので https://<user>.github.io/sunstory/ 配下

cd "$(dirname "$0")/.."

# Git Bash はスラッシュ始まりの引数を Windows パスに変換してしまう
MSYS_NO_PATHCONV=1 flutter build web --release --base-href "$BASE_HREF"

# Jekyll に触らせない。_ で始まるファイルが無視されるのを防ぐ。
touch build/web/.nojekyll

cd build/web
rm -rf .git
git init -q -b gh-pages
git add -A
git commit -q -m "deploy $(date '+%Y-%m-%d %H:%M')"
git push -q -f "$REPO" gh-pages
rm -rf .git

echo "done: https://yuusaku000.github.io/sunstory/"
