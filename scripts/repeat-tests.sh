#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ITERATIONS="${1:-101}"
DESTINATION="${IOS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
RESULT_DIR="$ROOT_DIR/build/test-results"

if ! [[ "$ITERATIONS" =~ '^[0-9]+$' ]] || (( ITERATIONS < 1 )); then
  echo "迭代次數必須是正整數。" >&2
  exit 2
fi

mkdir -p "$RESULT_DIR"
RESULT_BUNDLE="$RESULT_DIR/repeat-$(date +%Y%m%d-%H%M%S).xcresult"

cd "$ROOT_DIR"
echo "開始執行 $ITERATIONS 次 iOS 測試：$DESTINATION"
xcodebuild \
  -quiet \
  -project AIMorningBriefing.xcodeproj \
  -scheme AIMorningBriefing \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  -test-iterations "$ITERATIONS" \
  -resultBundlePath "$RESULT_BUNDLE" \
  test

echo "全部 $ITERATIONS 次測試通過。"
echo "結果：$RESULT_BUNDLE"
