#!/bin/bash
# mihomo 一键部署脚本（macOS）
# 用法: bash mihomo-setup.sh "你的Clash订阅链接"

set -euo pipefail

SUB_URL="${1:-}"
LABEL="com.jeff.mihomo"          # launchd 标签名，随意
DIR="$HOME/.config/mihomo"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
MIHOMO_BIN="$(command -v mihomo || true)"
MIRRORS=(
  "https://ghproxy.net/https://github.com"
  "https://ghfast.top/https://github.com"
  "https://gh-proxy.com/https://github.com"
  "https://github.com"
)

fetch_gh() { # $1=GitHub路径 $2=保存路径；按顺序轮换镜像
  local base
  for base in "${MIRRORS[@]}"; do
    echo "  尝试: $base"
    curl -L -sS --connect-timeout 10 -o "$2" "$base/$1" && return 0
  done
  return 1
}

if [ -z "$SUB_URL" ]; then
  echo "用法: bash mihomo-setup.sh \"你的Clash订阅链接\""
  exit 1
fi
if [ -z "$MIHOMO_BIN" ]; then
  echo "未找到 mihomo，请先执行: brew install mihomo"
  exit 1
fi

echo "==> 1/8 下载订阅配置"
mkdir -p "$DIR"
curl -L -sS --connect-timeout 15 -o "$DIR/config.yaml" "$SUB_URL"
if ! grep -q 'proxies:' "$DIR/config.yaml"; then
  echo "✗ 订阅内容不对（没有 proxies 字段），请确认复制的是 Clash/Clash Meta 格式链接"
  exit 1
fi
echo "✓ 订阅有效，节点条目数: $(grep -c 'name:' "$DIR/config.yaml")"

echo "==> 2/8 补管理配置 + GEO 镜像地址"
grep -q '^external-controller' "$DIR/config.yaml" || echo 'external-controller: 127.0.0.1:9090' >> "$DIR/config.yaml"
grep -q '^external-ui' "$DIR/config.yaml" || echo 'external-ui: ui' >> "$DIR/config.yaml"
grep -q '^geox-url' "$DIR/config.yaml" || cat >> "$DIR/config.yaml" << 'GEO'
geox-url:
  geoip: "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat"
  geosite: "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
  mmdb: "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb"
GEO

echo "==> 3/8 下载 GEO 规则数据库"
# 先清掉体积异常的残次文件（小于 1MB 视为错误页面/残包）
for f in "$DIR/GeoSite.dat" "$DIR/geoip.metadb"; do
  [ -f "$f" ] && [ "$(stat -f%z "$f")" -lt 1000000 ] && rm -f "$f"
done
[ -s "$DIR/GeoSite.dat" ]   || fetch_gh "MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat" "$DIR/GeoSite.dat"
[ -s "$DIR/geoip.metadb" ]  || fetch_gh "MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb" "$DIR/geoip.metadb"
if [ ! -s "$DIR/GeoSite.dat" ] || [ ! -s "$DIR/geoip.metadb" ]; then
  echo "✗ GEO 数据库下载失败，所有镜像均不可用，请检查网络后重跑"
  exit 1
fi
echo "✓ GEO 数据库就绪"

echo "==> 4/8 下载面板文件"
if [ -f "$DIR/ui/index.html" ]; then
  echo "✓ 面板已存在，跳过"
else
  UI_OK=0
  for BASE in "${MIRRORS[@]}"; do
    echo "  尝试: $BASE"
    if curl -L -sS --connect-timeout 10 -o /tmp/mihomo-ui.zip "$BASE/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip" \
       && unzip -tq /tmp/mihomo-ui.zip >/dev/null 2>&1; then
      UI_OK=1; break
    fi
  done
  if [ "$UI_OK" = 1 ]; then
    mkdir -p "$DIR/ui" /tmp/mihomo-uix && rm -rf /tmp/mihomo-uix/*
    unzip -oq /tmp/mihomo-ui.zip -d /tmp/mihomo-uix
    cp -R /tmp/mihomo-uix/metacubexd-gh-pages/* "$DIR/ui/"
    echo "✓ 面板文件就绪"
  else
    echo "⚠ 面板下载失败（不影响代理功能），可稍后重跑本脚本"
  fi
fi

echo "==> 5/8 注册开机自启"
launchctl unload "$PLIST" 2>/dev/null || true
pkill -x mihomo 2>/dev/null || true
cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$MIHOMO_BIN</string>
        <string>-d</string>
        <string>$DIR</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$DIR/mihomo.log</string>
    <key>StandardErrorPath</key>
    <string>$DIR/mihomo.log</string>
</dict>
</plist>
EOF
launchctl load "$PLIST"

echo "==> 6/8 设置系统代理（持久生效）"
networksetup -setwebproxy "Wi-Fi" 127.0.0.1 7890
networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 7890
networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 7890

echo "==> 7/8 写入订阅更新脚本"
cat > "$DIR/update-sub.sh" << UPD
#!/bin/bash
cd "$DIR"
curl -L -sS -o config.yaml.new "$SUB_URL"
grep -q 'proxies:' config.yaml.new || { echo "下载内容不对，未替换"; rm -f config.yaml.new; exit 1; }
grep -q '^external-controller' config.yaml.new || echo 'external-controller: 127.0.0.1:9090' >> config.yaml.new
grep -q '^external-ui' config.yaml.new || echo 'external-ui: ui' >> config.yaml.new
grep -q '^geox-url' config.yaml.new || cat >> config.yaml.new << 'GEO'
geox-url:
  geoip: "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat"
  geosite: "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
  mmdb: "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb"
GEO
mv config.yaml.new config.yaml
launchctl kickstart -k gui/\$(id -u)/$LABEL
echo "订阅已更新，mihomo 已重启"
UPD
chmod +x "$DIR/update-sub.sh"

echo "==> 8/8 验证"
sleep 3
if curl -s -x http://127.0.0.1:7890 -I --max-time 30 https://www.google.com | head -1 | grep -q "HTTP"; then
  echo "✓ 代理链路已通"
else
  echo "✗ 代理未通。排查：tail -20 $DIR/mihomo.log"
  echo "  （日志为空就先把 config.yaml 里 log-level 改成 info，再重跑本脚本）"
fi

echo ""
echo "部署完成，日常只需要知道："
echo "  面板地址        http://127.0.0.1:9090/ui"
echo "  更新订阅        $DIR/update-sub.sh"
echo "  临时绕过代理    面板里把模式从「规则」切到「直连」"
echo "  彻底停用        launchctl unload \"$PLIST\""
echo "                  networksetup -setwebproxystate Wi-Fi off"
echo "                  networksetup -setsecurewebproxystate Wi-Fi off"
echo "                  networksetup -setsocksfirewallproxystate Wi-Fi off"
