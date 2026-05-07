DEVICE  ?= salami
DATE    := $(shell date +%Y%m%d)
IMAGE   := droidian-$(DEVICE)-arm64-$(DATE).img.gz
REPO    := $(shell git -C ../.. rev-parse --show-toplevel 2>/dev/null || pwd)

.PHONY: all deb image image-docker docker clean check-docker

# ── Default: native (Debian/Ubuntu host) ───────────────────────────────────
all: image

# Build the .deb (requires dpkg-dev + debhelper — Debian/Ubuntu only)
deb:
	cd ../adaptation && \
	  dpkg-buildpackage -us -uc -b --host-arch arm64 && \
	  mkdir -p ../adaptation-pkg && \
	  mv ../adaptation-droidian-salami_*.deb ../adaptation-pkg/

image: deb
	DATE=$(DATE) debos \
	  --artifactdir=. \
	  --cpus=$$(nproc) \
	  $(DEVICE).yaml

# ── Manjaro / Arch / macOS / any OS with Docker ────────────────────────────
# Builds the .deb inside Debian Bookworm, then runs debos — zero host deps.
docker: check-docker
	@echo "==> [1/2] Building adaptation .deb inside Debian Bookworm..."
	mkdir -p ../adaptation-pkg
	docker run --rm \
	  -v "$$(realpath ../adaptation)":/src/adaptation \
	  -v "$$(realpath ../adaptation-pkg)":/src/adaptation-pkg \
	  -w /src/adaptation \
	  debian:bookworm \
	  bash -c "\
	    apt-get update -qq && \
	    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
	      dpkg-dev debhelper && \
	    dpkg-buildpackage -us -uc -b --host-arch arm64 && \
	    mv /src/adaptation-droidian-salami_*.deb /src/adaptation-pkg/"
	@echo "==> [2/2] Building rootfs image with debos..."
	docker run --rm \
	  --privileged \
	  -v "$$(realpath .)":/recipes \
	  -v "$$(realpath ../adaptation-pkg)":/recipes/adaptation-pkg \
	  -w /recipes \
	  -e DATE=$(DATE) \
	  godebos/debos \
	    --artifactdir=/recipes \
	    --cpus=$$(nproc) \
	    $(DEVICE).yaml
	@echo ""
	@echo "Done: $(IMAGE)"

check-docker:
	@docker info > /dev/null 2>&1 || \
	  (echo "ERROR: Docker is not running. Start it with: sudo systemctl start docker"; exit 1)

clean:
	rm -f *.img *.img.gz
	rm -rf ../adaptation-pkg
