#!/usr/bin/env bash
set -euo pipefail

# Installs (or uninstalls) the Embedder Remote Headless bridge on a 64-bit
# Raspberry Pi OS Lite (or any systemd Linux). Run as root:
#   curl -fsSL https://embedder.dev/install-bridge.sh | sudo bash
# Uninstall:
#   sudo bash install-bridge.sh --uninstall

RELEASE_REPO="${EMBEDDER_BRIDGE_REPO:-embedder-dev/embedder-cli}"
VERSION="${EMBEDDER_BRIDGE_VERSION:-latest}"
BIN_DIR=/usr/local/bin
CONFIG_DIR=/etc/embedder-bridge
STATE_DIR=/var/lib/embedder-bridge
UNIT=/etc/systemd/system/embedder-bridge.service
SERVICE_USER=embedder-bridge
RELEASE_TAG_PREFIX=bridge-v

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

detect_arch() {
	case "$(uname -m)" in
		aarch64 | arm64) echo "aarch64-musl" ;;
		armv7l | armv6l) echo "armv7-musl" ;;
		*)
			err "unsupported architecture $(uname -m); the bridge needs a 64-bit (aarch64) or armv7 Linux"
			exit 1
			;;
	esac
}

latest_bridge_tag() {
	curl -fsSL -H "Accept: application/vnd.github+json" \
		"https://api.github.com/repos/${RELEASE_REPO}/releases?per_page=50" 2>/dev/null \
		| grep -oE "\"tag_name\": *\"${RELEASE_TAG_PREFIX}[0-9][^\"]*\"" \
		| head -n1 \
		| sed -E "s/.*\"(${RELEASE_TAG_PREFIX}[0-9][^\"]*)\".*/\1/"
}

resolve_tarball_url() {
	local arch="$1" asset="embedder-bridge-${1}.tar.gz" tag="$VERSION"
	if [ "$VERSION" = "latest" ]; then
		tag="$(latest_bridge_tag)"
		[ -n "$tag" ] || { err "no ${RELEASE_TAG_PREFIX}* release found in ${RELEASE_REPO}"; exit 1; }
	fi
	echo "https://github.com/${RELEASE_REPO}/releases/download/${tag}/${asset}"
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
	command -v openssl >/dev/null 2>&1 || { err "openssl is required to verify the release signature"; exit 1; }
	local pub; pub="$(mktemp)"
	printf '%s\n' "$BRIDGE_UPDATE_PUBKEY_PEM" > "$pub"
	if openssl pkeyutl -verify -pubin -inkey "$pub" -rawin -in "$dir/embedder-bridge" -sigfile "$dir/embedder-bridge.sig" >/dev/null 2>&1; then
		rm -f "$pub"
		info "release signature verified (ed25519)"
	else
		rm -f "$pub"
		err "signature verification FAILED for embedder-bridge; refusing to install"
		exit 1
	fi
}

install_bridge() {
	require_root
	local arch tarball tmp
	arch="$(detect_arch)"
	tmp="$(mktemp -d)"
	trap 'rm -rf "${tmp:-}"' EXIT

	if [ -n "${EMBEDDER_BRIDGE_TARBALL:-}" ]; then
		info "using local tarball ${EMBEDDER_BRIDGE_TARBALL}"
		cp "$EMBEDDER_BRIDGE_TARBALL" "$tmp/bridge.tar.gz"
	else
		tarball="$(resolve_tarball_url "$arch")"
		info "downloading ${tarball}"
		curl -fsSL "$tarball" -o "$tmp/bridge.tar.gz"
		if curl -fsSL "${tarball}.sha256" -o "$tmp/bridge.tar.gz.sha256" 2>/dev/null; then
			info "verifying checksum"
			expected="$(awk '{print $1}' "$tmp/bridge.tar.gz.sha256")"
			actual="$(sha256sum "$tmp/bridge.tar.gz" | awk '{print $1}')"
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

	info "creating service user ${SERVICE_USER}"
	if ! id "$SERVICE_USER" >/dev/null 2>&1; then
		useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
	fi
	usermod -aG dialout "$SERVICE_USER" 2>/dev/null || true
	usermod -aG plugdev "$SERVICE_USER" 2>/dev/null || true

	info "installing binary to ${BIN_DIR}/embedder-bridge"
	install -m 0755 "$tmp/embedder-bridge" "$BIN_DIR/embedder-bridge"

	install -d -m 0755 "$CONFIG_DIR"
	if [ ! -f "$CONFIG_DIR/config.toml" ]; then
		info "writing default config to ${CONFIG_DIR}/config.toml"
		install -m 0644 "$tmp/config.example.toml" "$CONFIG_DIR/config.toml"
	else
		info "keeping existing ${CONFIG_DIR}/config.toml"
	fi

	install -d -m 0700 -o "$SERVICE_USER" -g "$SERVICE_USER" "$STATE_DIR"

	info "installing systemd unit"
	install -m 0644 "$tmp/embedder-bridge.service" "$UNIT"
	systemctl daemon-reload
	systemctl enable embedder-bridge
	systemctl restart embedder-bridge

	printf "\n${BOLD}Bridge installed and running.${NC}\n\n"
	if [ -f "$CONFIG_DIR/config.toml" ] && grep -q "relay_bridge_id" "$CONFIG_DIR/config.toml"; then
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
	local code=""
	for _ in $(seq 1 20); do
		code="$(cat "$STATE_DIR/setup-code" 2>/dev/null || true)"
		[ -n "$code" ] && break
		sleep 0.5
	done
	if [ -z "$code" ]; then
		printf "Waiting for a setup code. Once it appears, run:\n"
		printf "  ${BOLD}sudo cat %s/setup-code${NC}\n" "$STATE_DIR"
		printf "or watch:  ${BOLD}sudo journalctl -u embedder-bridge -f${NC}\n"
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
	info "stopping and disabling service"
	systemctl disable --now embedder-bridge 2>/dev/null || true
	rm -f "$UNIT"
	systemctl daemon-reload
	rm -f "$BIN_DIR/embedder-bridge"
	if id "$SERVICE_USER" >/dev/null 2>&1; then
		userdel "$SERVICE_USER" 2>/dev/null || true
	fi
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
