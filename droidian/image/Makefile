DEVICE  ?= salami
DATE    := $(shell date +%Y%m%d)
IMAGE   := droidian-$(DEVICE)-arm64-$(DATE).img.gz

.PHONY: all docker clean check-docker

all: docker

# Build rootfs image — works on any OS with Docker (Manjaro, Arch, Ubuntu, macOS)
docker: check-docker
	@echo "==> Registering qemu-user-static binfmt handlers..."
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	@echo "==> Building Droidian rootfs with debos (chroot mode)..."
	docker run --rm \
	  --privileged \
	  -v "$$(realpath .)":/recipes \
	  -v "$$(realpath ../adaptation)":/recipes/adaptation \
	  -w /recipes \
	  -e DATE=$(DATE) \
	  godebos/debos \
	    --disable-fakemachine \
	    --artifactdir=/recipes \
	    --cpus=$$(nproc) \
	    $(DEVICE).yaml
	@echo ""
	@echo "==> Done: $(IMAGE)"

check-docker:
	@docker info > /dev/null 2>&1 || \
	  (echo "ERROR: Docker is not running. Run: sudo systemctl start docker"; exit 1)

clean:
	rm -f *.img *.img.gz
