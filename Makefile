TMP_DIR=./tmp
OUT_DIR=./build

SRC_DIR=.
# FCC_FILES=$(wildcard $(SRC_DIR)/*.fcc)
INSTALL_FCC=k3s-autoinstall.fcc

RELEASE_TAG=release
IMAGE_INSTALLER=quay.io/coreos/coreos-installer:${RELEASE_TAG}
IMAGE_VALIDATE=quay.io/coreos/ignition-validate:${RELEASE_TAG}
IMAGE_FCCT=quay.io/coreos/fcct:${RELEASE_TAG}

CMD_FCCT=podman run -i --rm ${IMAGE_FCCT}
CMD_INSTALLER=podman run --privileged --rm -v ${TMP_DIR}:/data -w /data ${IMAGE_INSTALLER}
CMD_VALIDATE=podman run --privileged --rm -i ${IMAGE_VALIDATE}

# Automatically export environment variables from .env
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: help download-coreos

help:  ## Print this help
	@echo "Usage: make [target]"
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

clean:  ## Clean up install files
	rm -rf ${TMP_DIR}

ensure-images:  ## Verify the latest CoreOS images are available
	podman pull ${INSTALLER_IMAGE}
	podman pull ${FCCT_IMAGE}

download-coreos:  ## Download base image
	mkdir -p ${TMP_DIR}
	${CMD_INSTALLER} download -f iso

validate-fcc:  ## Validate FCC files
	@echo "validating ${INSTALL_FCC}"
	${CMD_VALIDATE} - < ${INSTALL_FCC}

build-ign:  ## Build ignition files from butane fcc files. Authorized public key is filled in using fq from .env
	@echo "compiling files: ${INSTALL_FCC}"
	mkdir -p ${OUT_DIR}
	yq -y '.passwd.users[0].ssh_authorized_keys += [env.COREOS_USER_PUBKEY]' ${INSTALL_FCC} \
		| ${CMD_FCCT} --pretty --strict > ${OUT_DIR}/k3s-autoinstall.ign

