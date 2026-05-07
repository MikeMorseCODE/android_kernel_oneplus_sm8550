DEVICE  ?= salami
DATE    := $(shell date +%Y%m%d)
IMAGE   := droidian-$(DEVICE)-arm64-$(DATE).img.gz
DEB_SRC := $(shell ls ../adaptation-pkg/adaptation-droidian-salami_*.deb 2>/dev/null)

.PHONY: all deb image clean

all: image

# Build the Debian adaptation package
deb:
	cd ../adaptation && \
	  dpkg-buildpackage -us -uc -b --host-arch arm64 && \
	  mkdir -p ../adaptation-pkg && \
	  mv ../adaptation-droidian-salami_*.deb ../adaptation-pkg/

# Build the rootfs image (requires deb first)
image: deb
	export DATE=$(DATE) && \
	debos \
	  --artifactdir=. \
	  --cpus=$$(nproc) \
	  $(DEVICE).yaml

# Use Docker if debos is not installed natively
image-docker: deb
	export DATE=$(DATE) && \
	docker run --rm \
	  --privileged \
	  -v $$(pwd):/recipes \
	  -v $$(pwd)/../adaptation-pkg:/recipes/adaptation-pkg \
	  -w /recipes \
	  -e DATE=$(DATE) \
	  godebos/debos \
	  --artifactdir=/recipes \
	  --cpus=$$(nproc) \
	  $(DEVICE).yaml

clean:
	rm -f *.img *.img.gz
	rm -rf ../adaptation-pkg
