#!/bin/bash
# checklinks.sh — 站台內所有相對連結都必須指向真的存在的檔案。
#
# **這個站台存在的唯一理由，就是讓 ASC 那兩個 URL 回 200。**
# 一個 404 的隱私政策是會被拒審的，而壞掉的連結在瀏覽器裡看起來
# 跟好的連結一模一樣 —— 要點下去才知道。
#
# 帶一個已知會失敗的樣本：只會說「全部正常」的檢查，
# 和一個根本沒掃到任何連結的檢查，輸出長得一樣。
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
FAILED=0
CHECKED=0

check_file() {
  local f="$1" dir
  dir="$(dirname "$f")"
  # 取出 href，濾掉 mailto:、外部 http(s):、頁內錨點。
  grep -oE 'href="[^"]+"' "$f" 2>/dev/null | cut -d'"' -f2 \
  | grep -vE '^(mailto:|https?:|#)' | sort -u | while read -r link; do
      # 去掉可能的 ?query 與 #fragment
      local target="${link%%#*}"; target="${target%%\?*}"
      [ -z "$target" ] && continue
      if [ -e "$dir/$target" ]; then
        printf '  ✓ %-28s → %s\n' "${f#./}" "$link"
      else
        printf '  ✗ %-28s → %s 不存在\n' "${f#./}" "$link"
        echo "BROKEN" >> /tmp/checklinks.$$
      fi
    done
}

rm -f /tmp/checklinks.$$
while IFS= read -r f; do
  CHECKED=$((CHECKED + 1))
  check_file "$f"
# 排除 tools/：hub.css.html 是版式片段，不是頁面。把它算進來會讓「掃了 N 個」
# 比真正的頁數多一個 —— 一個數字不準的閘門，很快就沒有人相信它其他的輸出。
done < <(find . -name '*.html' -not -path './.git/*' -not -path './tools/*' | sort)

if [ -f /tmp/checklinks.$$ ]; then FAILED=1; rm -f /tmp/checklinks.$$; fi
echo "掃了 $CHECKED 個 HTML 檔"

echo "--- 自檢：已知會失敗的樣本 ---"
TMP="$(mktemp -d)"
printf '<a href="definitely-not-here.html">x</a>\n' > "$TMP/bad.html"
if grep -oE 'href="[^"]+"' "$TMP/bad.html" | cut -d'"' -f2 | while read -r l; do
     [ -e "$TMP/$l" ] || exit 7
   done; then
  echo "  ✗ 壞連結樣本沒有被判為壞 —— 上面的綠燈不可信"; FAILED=1
else
  echo "  ✓ 壞連結樣本被正確判為壞（比對確實在運作）"
fi
rm -rf "$TMP"

echo
if [ $FAILED -eq 0 ]; then echo "✓ 站內連結全數指向存在的檔案"; else echo "✗ 有連結指向不存在的檔案"; fi
exit $FAILED
