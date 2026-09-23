
COREOS_RELEASE_STREAM?=stable
COREOS_ARCH?=x86_64
COREOS_PLATFORM?=metal

DEST_INSTALL_DEVICE?=/dev/sda
POST_INSTALL_SCRIPT?=post.sh

TMP_DIR=./tmp
OUT_DIR=./build

FILE_STATE_FILE=.base-iso-path
FILE_INSTALL_FCC=k3s-autoinstall.fcc
FILE_OUT_IGN=${OUT_DIR}/k3s-autoinstall.igc

RELEASE_TAG=release
IMAGE_INSTALLER=quay.io/coreos/coreos-installer:${RELEASE_TAG}
IMAGE_VALIDATE=quay.io/coreos/ignition-validate:${RELEASE_TAG}
IMAGE_FCCT=quay.io/coreos/fcct:${RELEASE_TAG}

CMD_FCCT=podman run -i --rm ${IMAGE_FCCT}
CMD_INSTALLER=podman run --privileged --rm -v .:/data -w /data ${IMAGE_INSTALLER}
CMD_VALIDATE=podman run --rm -i ${IMAGE_VALIDATE}

# Automatically export environment variables from .env
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.DEFAULT_GOAL := help
.PHONY: *

help:  ## Print this help
	@echo "Usage: make [target]"
	@echo "Targets:"
	@grep -Eh '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

clean:  ## Clean up install files
	rm -rf ${TMP_DIR}
	rm -rf ${OUT_DIR}

ensure-dependencies: ## Pull the latest docker images used by the Makefile
	podman pull ${IMAGE_INSTALLER}
	podman pull ${IMAGE_VALIDATE}
	podman pull ${IMAGE_FCCT}

validate-ign: ## Validate compiled IGN files
	@echo "validating ${FILE_OUT_IGN}"
	${CMD_VALIDATE} - < ${FILE_OUT_IGN} && (echo "IGN is valid"; exit 0)

build-ign: clean  ## Build ignition files from butane fcc files. Authorized public key is filled in using fq from .env
	@echo "compiling files: ${FILE_INSTALL_FCC}"
	mkdir -p ${OUT_DIR}
	yq -y '.passwd.users[0].ssh_authorized_keys += [env.COREOS_USER_PUBKEY]' ${FILE_INSTALL_FCC} \
		| ${CMD_FCCT} --pretty --strict > ${FILE_OUT_IGN}

download-base-iso:  ## Downloads the base CoreOS ISO
ifneq (,$(wildcard ${FILE_STATE_FILE}))
	@echo "CoreOS ISO already exists, skipping download (run \`make clean\` to force redownload)"
else
	@echo "downloading latest CoreOS ISO to ${TMP_DIR}"
	mkdir -p ${TMP_DIR}
	ISO_OUTPUT=$$(\
		${CMD_INSTALLER} download -f iso \
			--architecture ${COREOS_ARCH} \
			--platform ${COREOS_PLATFORM} \
			--stream ${COREOS_RELEASE_STREAM} \
		| tail -n 1 \
	) && \
	echo $$(basename $$ISO_OUTPUT) > ${TMP_DIR}/${FILE_STATE_FILE}
endif

build-iso: download-base-iso  ## Build the CoreOS ISO with the compiled IGN
	@echo "creating CoreOS ISO that installs to ${DEST_INSTALL_DEVICE}"
	${CMD_INSTALLER} iso customize \
		--dest-device ${DEST_INSTALL_DEVICE} \
		--dest-ignition ${FILE_OUT_IGN} \
		-o k3s-coreos.iso "$$(cat ${TMP_DIR}/${FILE_STATE_FILE})"
