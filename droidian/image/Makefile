DEVICE   ?= salami
DATE     := $(shell date +%Y%m%d)
IMAGE    := droidian-$(DEVICE)-arm64-$(DATE).img.gz
WIFI_SSID ?=
WIFI_PSK  ?=

.PHONY: all docker initramfs vbmeta clean check-docker

all: docker

# Build rootfs image
docker: check-docker
	@echo "==> Registering arm64 binfmt handlers..."
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	@echo "==> Building Droidian rootfs (debootstrap + chroot)..."
	docker run --rm \
	  --privileged \
	  -e WIFI_SSID="$(WIFI_SSID)" \
	  -e WIFI_PSK="$(WIFI_PSK)" \
	  -v "$$(realpath .)":/scripts \
	  -v "$$(realpath ../adaptation/sparse)":/adaptation \
	  -v "$$(realpath .)":/output \
	  debian:bookworm \
	  bash /scripts/build-rootfs.sh
	@echo "==> Done: $(IMAGE)"

# Build Linux initramfs + init_boot.img (fixes bootloop)
initramfs: check-docker
	@echo "==> Building ARM64 initramfs and init_boot.img..."
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker run --rm \
	  --privileged \
	  -v "$$(realpath ../initramfs)":/scripts \
	  -v "$$(realpath .)":/output \
	  debian:bookworm \
	  bash /scripts/build-initramfs.sh
	@echo "==> Flash with: fastboot flash init_boot init_boot.img"

# Generate vbmeta.img with AVB verification disabled (no backup needed)
vbmeta:
	python3 ../initramfs/mkvbmeta.py vbmeta.img
	@echo "==> Flash with:"
	@echo "    fastboot flash vbmeta vbmeta.img"
	@echo "    fastboot flash vbmeta_system vbmeta.img  (if separate)"

check-docker:
	@docker info > /dev/null 2>&1 || \
	  (echo "ERROR: Docker not running. Run: sudo systemctl start docker"; exit 1)

clean:
	rm -f *.img *.img.gz *.cpio.gz
