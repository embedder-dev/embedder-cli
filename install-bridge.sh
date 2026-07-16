#!/usr/bin/env bash
set -euo pipefail

# Installs (or uninstalls) the Embedder Remote Headless bridge on Linux (systemd,
# e.g. 64-bit Raspberry Pi OS) or macOS (launchd). Run as root:
#   curl -fsSL https://embedder.com/install-bridge.sh | sudo bash
# Uninstall:
#   sudo bash install-bridge.sh --uninstall

RELEASE_REPO="${EMBEDDER_BRIDGE_REPO:-embedder-dev/embedder-cli}"
VERSION="${EMBEDDER_BRIDGE_VERSION:-latest}"
RELEASE_TAG_PREFIX=bridge-v
BIN_DIR=/usr/local/bin

OS="$(uname -s)"
case "$OS" in
	Linux)
		CONFIG_DIR=/etc/embedder-bridge
		STATE_DIR=/var/lib/embedder-bridge
		UNIT=/etc/systemd/system/embedder-bridge.service
		SERVICE_USER=embedder-bridge
		;;
	Darwin)
		CONFIG_DIR=/usr/local/etc/embedder-bridge
		STATE_DIR=/usr/local/var/embedder-bridge
		LOG=/usr/local/var/log/embedder-bridge.log
		PLIST=/Library/LaunchDaemons/dev.embedder.bridge.plist
		LABEL=dev.embedder.bridge
		;;
	*)
		printf "error: unsupported OS %s\n" "$OS" >&2
		exit 1
		;;
esac

# ed25519 release-signing public key; matches UPDATE_PUBLIC_KEY baked into the binary
# fingerprint C42ejCdLXi5/YOdQetAM6vDdUMtffUwc8tTs69g5QOM=
BRIDGE_UPDATE_PUBKEY_PEM="-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEA30bEByhD4HtMtzgdNKEyXniX9mhO2tVzWDjbSq9kTmQ=
-----END PUBLIC KEY-----"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "${GREEN}==>${NC} %s\n" "$1"; }
err() { printf "${RED}error:${NC} %s\n" "$1" >&2; }

require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		err "must run as root (use sudo)"
		exit 1
	fi
}

detect_slug() {
	local os arch
	case "$OS" in
		Linux) os=linux ;;
		Darwin) os=darwin ;;
	esac
	case "$(uname -m)" in
		aarch64 | arm64) arch=aarch64 ;;
		x86_64 | amd64) arch=x86_64 ;;
		*)
			err "unsupported architecture $(uname -m); the bridge ships aarch64 and x86_64 builds"
			exit 1
			;;
	esac
	echo "${arch}-${os}"
}

sha256_of() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	else
		shasum -a 256 "$1" | awk '{print $1}'
	fi
}

latest_bridge_tag() {
	curl -fsSL -H "Accept: application/vnd.github+json" \
		"https://api.github.com/repos/${RELEASE_REPO}/releases?per_page=50" 2>/dev/null \
		| grep -oE "\"tag_name\": *\"${RELEASE_TAG_PREFIX}[0-9][^\"]*\"" \
		| head -n1 \
		| sed -E "s/.*\"(${RELEASE_TAG_PREFIX}[0-9][^\"]*)\".*/\1/"
}

resolve_tarball_url() {
	local asset="embedder-bridge-${1}.tar.gz" tag="$VERSION"
	if [ "$VERSION" = "latest" ]; then
		tag="$(latest_bridge_tag)"
		[ -n "$tag" ] || { err "no ${RELEASE_TAG_PREFIX}* release found in ${RELEASE_REPO}"; exit 1; }
	fi
	echo "https://github.com/${RELEASE_REPO}/releases/download/${tag}/${asset}"
}

# ed25519 needs openssl >= 3 (pkeyutl -rawin); stock macOS ships LibreSSL without
# it, so fall back to a self-contained python verifier (RFC 8032, stdlib only).
find_openssl() {
	local o
	for o in openssl /opt/homebrew/opt/openssl@3/bin/openssl /usr/local/opt/openssl@3/bin/openssl /opt/homebrew/bin/openssl; do
		command -v "$o" >/dev/null 2>&1 || continue
		if "$o" pkeyutl -help 2>&1 | grep -q -- -rawin; then echo "$o"; return 0; fi
	done
	return 1
}

verify_ed25519_python() {
	local msg="$1" sig="$2" vpy
	vpy="$(mktemp)"
	cat > "$vpy" <<'PYEOF'
import sys, os, base64, hashlib
p = 2**255 - 19
def inv(x): return pow(x, p - 2, p)
d = (-121665 * inv(121666)) % p
Iv = pow(2, (p - 1) // 4, p)
def xrecover(y):
    xx = (y * y - 1) * inv(d * y * y + 1) % p
    x = pow(xx, (p + 3) // 8, p)
    if (x * x - xx) % p != 0: x = (x * Iv) % p
    if x % 2 != 0: x = p - x
    return x
By = 4 * inv(5) % p
B = (xrecover(By) % p, By % p)
def add(P, Q):
    x1, y1 = P; x2, y2 = Q
    t = d * x1 * x2 * y1 * y2 % p
    return ((x1 * y2 + x2 * y1) * inv(1 + t) % p, (y1 * y2 + x1 * x2) * inv(1 - t) % p)
def mult(P, e):
    Q = (0, 1)
    while e > 0:
        if e & 1: Q = add(Q, P)
        P = add(P, P); e >>= 1
    return Q
def bit(h, i): return (h[i // 8] >> (i % 8)) & 1
def decodepoint(s):
    y = sum(2**i * bit(s, i) for i in range(255))
    x = xrecover(y)
    if x & 1 != bit(s, 255): x = p - x
    if (-x * x + y * y - 1 - d * x * x * y * y) % p != 0: raise ValueError("off curve")
    return (x, y)
pem = os.environ["PUBKEY_PEM"]
pk = base64.b64decode("".join(l for l in pem.splitlines() if "-" not in l))[-32:]
msg = open(sys.argv[1], "rb").read()
sig = open(sys.argv[2], "rb").read()
if len(sig) != 64: sys.exit(1)
try:
    if len(sig) != 64: raise ValueError("bad signature length")
    R = decodepoint(sig[:32]); A = decodepoint(pk)
    S = sum(2**i * bit(sig[32:], i) for i in range(256))
    h = sum(2**i * bit(hashlib.sha512(sig[:32] + pk + msg).digest(), i) for i in range(512))
    ok = mult(B, S) == add(R, mult(A, h % (2**252 + 27742317777372353535851937790883648493)))
except Exception:
    ok = False
sys.exit(0 if ok else 1)
PYEOF
	local ok=1
	PUBKEY_PEM="$BRIDGE_UPDATE_PUBKEY_PEM" python3 "$vpy" "$msg" "$sig" && ok=0
	rm -f "$vpy"
	return $ok
}

verify_signature() {
	local dir="$1"
	if [ ! -f "$dir/embedder-bridge.sig" ]; then
		if [ -n "${EMBEDDER_BRIDGE_TARBALL:-}" ]; then
			info "local tarball has no signature; skipping verification (dev install)"
			return 0
		fi
		err "release is missing embedder-bridge.sig; refusing to install an unsigned binary"
		exit 1
	fi
	local ossl
	if ossl="$(find_openssl)"; then
		local pub; pub="$(mktemp)"
		printf '%s\n' "$BRIDGE_UPDATE_PUBKEY_PEM" > "$pub"
		if "$ossl" pkeyutl -verify -pubin -inkey "$pub" -rawin -in "$dir/embedder-bridge" -sigfile "$dir/embedder-bridge.sig" >/dev/null 2>&1; then
			rm -f "$pub"; info "release signature verified (ed25519)"; return 0
		fi
		rm -f "$pub"; err "signature verification FAILED for embedder-bridge; refusing to install"; exit 1
	fi
	if command -v python3 >/dev/null 2>&1; then
		if verify_ed25519_python "$dir/embedder-bridge" "$dir/embedder-bridge.sig"; then
			info "release signature verified (ed25519)"; return 0
		fi
		err "signature verification FAILED for embedder-bridge; refusing to install"; exit 1
	fi
	err "need openssl 3.x or python3 to verify the release signature; install one and retry"
	exit 1
}

write_default_config() {
	local src="$1"
	install -d -m 0755 "$CONFIG_DIR"
	if [ -f "$CONFIG_DIR/config.toml" ]; then
		info "keeping existing ${CONFIG_DIR}/config.toml"
		return
	fi
	info "writing default config to ${CONFIG_DIR}/config.toml"
	install -m 0644 "$src/config.example.toml" "$CONFIG_DIR/config.toml"
	case "$OS" in
		Darwin) sed -i '' -E "s|^state_dir = .*|state_dir = \"$STATE_DIR\"|" "$CONFIG_DIR/config.toml" ;;
		*) sed -i -E "s|^state_dir = .*|state_dir = \"$STATE_DIR\"|" "$CONFIG_DIR/config.toml" ;;
	esac
}

install_service_linux() {
	local src="$1"
	info "creating service user ${SERVICE_USER}"
	if ! id "$SERVICE_USER" >/dev/null 2>&1; then
		useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
	fi
	usermod -aG dialout "$SERVICE_USER" 2>/dev/null || true
	usermod -aG plugdev "$SERVICE_USER" 2>/dev/null || true
	install -d -m 0700 -o "$SERVICE_USER" -g "$SERVICE_USER" "$STATE_DIR"
	info "installing systemd unit"
	install -m 0644 "$src/embedder-bridge.service" "$UNIT"
	systemctl daemon-reload
	systemctl enable embedder-bridge
	systemctl restart embedder-bridge
}

install_service_macos() {
	install -d -m 0700 "$STATE_DIR"
	install -d -m 0755 "$(dirname "$LOG")"
	info "installing launchd daemon ${LABEL}"
	cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key><string>$LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>$BIN_DIR/embedder-bridge</string>
		<string>--config</string>
		<string>$CONFIG_DIR/config.toml</string>
		<string>run</string>
	</array>
	<key>RunAtLoad</key><true/>
	<key>KeepAlive</key><true/>
	<key>StandardOutPath</key><string>$LOG</string>
	<key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
PLISTEOF
	chmod 0644 "$PLIST"
	launchctl bootout "system/$LABEL" 2>/dev/null || true
	launchctl bootstrap system "$PLIST"
	launchctl enable "system/$LABEL" 2>/dev/null || true
}

install_bridge() {
	require_root
	local slug tarball tmp
	slug="$(detect_slug)"
	tmp="$(mktemp -d)"
	trap 'rm -rf "${tmp:-}"' EXIT

	if [ -n "${EMBEDDER_BRIDGE_TARBALL:-}" ]; then
		info "using local tarball ${EMBEDDER_BRIDGE_TARBALL}"
		cp "$EMBEDDER_BRIDGE_TARBALL" "$tmp/bridge.tar.gz"
	else
		tarball="$(resolve_tarball_url "$slug")"
		info "downloading ${tarball}"
		curl -fsSL "$tarball" -o "$tmp/bridge.tar.gz"
		if curl -fsSL "${tarball}.sha256" -o "$tmp/bridge.tar.gz.sha256" 2>/dev/null; then
			info "verifying checksum"
			local expected actual
			expected="$(awk '{print $1}' "$tmp/bridge.tar.gz.sha256")"
			actual="$(sha256_of "$tmp/bridge.tar.gz")"
			if [ "$expected" != "$actual" ]; then
				err "checksum mismatch for ${tarball}; refusing to install"
				exit 1
			fi
		else
			err "no published checksum for ${tarball}; refusing to install unverified binary"
			exit 1
		fi
	fi

	tar -xzf "$tmp/bridge.tar.gz" -C "$tmp"
	verify_signature "$tmp"

	info "installing binary to ${BIN_DIR}/embedder-bridge"
	install -d -m 0755 "$BIN_DIR"
	install -m 0755 "$tmp/embedder-bridge" "$BIN_DIR/embedder-bridge"

	write_default_config "$tmp"

	case "$OS" in
		Linux) install_service_linux "$tmp" ;;
		Darwin) install_service_macos ;;
	esac

	printf "\n${BOLD}Bridge installed and running.${NC}\n\n"
	if [ -f "$STATE_DIR/relay-bridge-id" ] || grep -qE '^[[:space:]]*relay_bridge_id[[:space:]]*=' "$CONFIG_DIR/config.toml" 2>/dev/null; then
		printf "This bridge is already enrolled and connecting to the relay.\n"
	else
		show_setup_code
	fi
	printf "\nInstall a flasher toolchain your project needs (esptool, west, JLink, openocd);\n"
	printf "see docs/remote-headless-bridge.md.\n"
}

# A fresh bridge boots unenrolled and writes a short claim code to
# $STATE_DIR/setup-code; surface it so the operator can claim the device.
show_setup_code() {
	local code="" watch
	for _ in $(seq 1 20); do
		code="$(cat "$STATE_DIR/setup-code" 2>/dev/null || true)"
		[ -n "$code" ] && break
		sleep 0.5
	done
	case "$OS" in
		Darwin) watch="sudo tail -f $LOG" ;;
		*) watch="sudo journalctl -u embedder-bridge -f" ;;
	esac
	if [ -z "$code" ]; then
		printf "Waiting for a setup code. Once it appears, run:\n"
		printf "  ${BOLD}sudo cat %s/setup-code${NC}\n" "$STATE_DIR"
		printf "or watch:  ${BOLD}%s${NC}\n" "$watch"
		return
	fi
	printf "To connect this bridge to your team:\n"
	printf "  1. Open ${BOLD}https://app.embedder.dev/bridges${NC}\n"
	printf "  2. Click ${BOLD}Add bridge${NC} and enter this code:\n\n"
	printf "        ${BOLD}${GREEN}%s${NC}\n\n" "$code"
	printf "  3. Pick a team and name it. The bridge connects itself.\n"
}

uninstall_bridge() {
	require_root
	info "stopping and removing the bridge service"
	case "$OS" in
		Linux)
			systemctl disable --now embedder-bridge 2>/dev/null || true
			rm -f "$UNIT"
			systemctl daemon-reload
			if id "$SERVICE_USER" >/dev/null 2>&1; then
				userdel "$SERVICE_USER" 2>/dev/null || true
			fi
			;;
		Darwin)
			launchctl bootout "system/$LABEL" 2>/dev/null || true
			rm -f "$PLIST"
			;;
	esac
	rm -f "$BIN_DIR/embedder-bridge"
	printf "\n${BOLD}Bridge removed.${NC}\n"
	printf "Config left at ${CONFIG_DIR} and identity/pairings at ${STATE_DIR}.\n"
	printf "Delete ${STATE_DIR} to destroy the bridge identity and force all clients to re-pair.\n"
}

case "${1:-install}" in
	--uninstall | uninstall) uninstall_bridge ;;
	install) install_bridge ;;
	*)
		err "unknown argument: $1"
		exit 1
		;;
esac
