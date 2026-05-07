DEVICE  ?= salami
DATE    := $(shell date +%Y%m%d)
IMAGE   := droidian-$(DEVICE)-arm64-$(DATE).img.gz

.PHONY: all docker clean check-docker

all: docker

# Works on Manjaro, Arch, Ubuntu, macOS — only needs Docker
docker: check-docker
	@echo "==> Registering arm64 binfmt handlers..."
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	@echo "==> Building Droidian rootfs (debootstrap + chroot)..."
	docker run --rm \
	  --privileged \
	  -v "$$(realpath .)":/scripts \
	  -v "$$(realpath ../adaptation/sparse)":/adaptation \
	  -v "$$(realpath .)":/output \
	  debian:bookworm \
	  bash /scripts/build-rootfs.sh
	@echo ""
	@ls -lh $(IMAGE) 2>/dev/null || echo "Check /output for image"

check-docker:
	@docker info > /dev/null 2>&1 || \
	  (echo "ERROR: Docker not running. Run: sudo systemctl start docker"; exit 1)

clean:
	rm -f *.img *.img.gz
