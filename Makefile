COREOS_RELEASE_STREAM?=stable
COREOS_ARCH?=x86_64
COREOS_PLATFORM?=metal

DEST_INSTALL_DEVICE?=/dev/sda
POST_INSTALL_SCRIPT?=post.sh

TMP_DIR=./tmp
OUT_DIR=./build

SRC_DIR=.
INSTALL_FCC=k3s-autoinstall.fcc
OUT_IGN=${OUT_DIR}/k3s-autoinstall.igc

RELEASE_TAG=release
IMAGE_INSTALLER=quay.io/coreos/coreos-installer:${RELEASE_TAG}
IMAGE_VALIDATE=quay.io/coreos/ignition-validate:${RELEASE_TAG}
IMAGE_FCCT=quay.io/coreos/fcct:${RELEASE_TAG}

CMD_FCCT=podman run -i --rm ${IMAGE_FCCT}
CMD_INSTALLER=podman run --privileged --rm -v ${TMP_DIR}:/data -w /data ${IMAGE_INSTALLER}
CMD_VALIDATE=podman run --rm -i ${IMAGE_VALIDATE}

# Automatically export environment variables from .env
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.DEFAULT_GOAL := help
.PHONY: *

help: ## Print this help
	@echo "Usage: make [target]"
	@echo "Targets:"
	@grep -Eh '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

clean: ## Clean up install files
	rm -rf ${TMP_DIR}
	rm -rf ${OUT_DIR}

ensure-dependencies: ## Pull the latest docker images used by the Makefile
	podman pull ${IMAGE_INSTALLER}
	podman pull ${IMAGE_VALIDATE}
	podman pull ${IMAGE_FCCT}

validate-ign: ## Validate compiled IGN files
	@echo "validating ${OUT_IGN}"
	${CMD_VALIDATE} - < ${OUT_IGN} && (echo "IGN is valid"; exit 0)

build-ign: clean  ## Build ignition files from butane fcc files. Authorized public key is filled in using fq from .env
	@echo "compiling files: ${INSTALL_FCC}"
	mkdir -p ${OUT_DIR}
	yq -y '.passwd.users[0].ssh_authorized_keys += [env.COREOS_USER_PUBKEY]' ${INSTALL_FCC} \
		| ${CMD_FCCT} --pretty --strict > ${OUT_IGN}

download-base-iso:  ## Downloads the base CoreOS ISO
	@echo "downloading latest CoreOS ISO to ${TMP_DIR}"
	mkdir -p ${TMP_DIR}
	${CMD_INSTALLER} download -f iso \
		--architecture ${COREOS_ARCH} \
		--platform ${COREOS_PLATFORM} \
		--stream ${COREOS_RELEASE_STREAM} \
		--directory ${TMP_DIR}

build-iso: ## Build the CoreOS ISO with the compiled IGN
	mkdir -p ${TMP_DIR}
	@echo "Creating CoreOS ISO that installs to ${DEST_DEVICE}"
	${CMD_INSTALLER} iso customize \
		--dest-device ${DEST_INSTALL_DEVICE} \
		--dest-ignition ${OUT_IGN} \
		--post-install ${POST_INSTALL_SCRIPT}
		-o k3s-coreos.iso k3s-coreos-input.iso
