import argparse
import dataclasses
import os
from pathlib import Path
from typing import Any

import yaml

from coreos_schemas import (
    CoreOSFile,
    CoreOSFileContent,
    CoreOSPasswd,
    CoreOSSDUnit,
    CoreOSSInstall,
    CoreOSStorage,
    CoreOSUnits,
    CoreOSUser,
    InstallType,
    S3sConfig,
)


# fix pyyaml not printing multiline strings properly
# https://stackoverflow.com/a/50519774
def multiline_str_presenter(dumper, data):
    return dumper.represent_scalar(
        "tag:yaml.org,2002:str", data, style="|" if "\n" in data else None
    )


yaml.add_representer(str, multiline_str_presenter)

BASE_DIR = os.path.dirname(os.path.realpath(__file__))


def get_systemd_units(read_path: Path, context: dict[str, Any]) -> CoreOSUnits:
    systemd_units = os.listdir(read_path)
    processed = []
    for unit in systemd_units:
        with open(read_path / unit) as f:
            contents = f.read()
        contents = __inject_variables(contents, context)
        processed.append(CoreOSSDUnit(name=unit, enabled=True, contents=contents))

    return CoreOSUnits(units=processed)


def __inject_variables(file_contents: str, key_vals: dict[str, Any]) -> str:
    # CoreOS/Butane templates often use {{var}}, but .format() uses {var}.
    # We replace {{ and }} to { and } to support the common template style.
    safe_contents = file_contents.replace("{{", "{").replace("}}", "}")
    try:
        return safe_contents.format(**key_vals)
    except KeyError:
        return safe_contents


def get_scripts(
    read_path: Path, write_path: Path, context: dict[str, Any]
) -> list[CoreOSFile]:
    scripts = os.listdir(read_path)
    processed = []
    for script in scripts:
        with open(read_path / script) as f:
            contents = f.read()
        contents = __inject_variables(contents, context)
        processed.append(
            CoreOSFile(
                path=f"{write_path}/{script}",
                mode=644,
                contents=CoreOSFileContent(inline=contents),
                overwrite=True,
            )
        )

    return processed


def get_configs(s3s_config: S3sConfig) -> list[CoreOSFile]:
    # write_k3s_config(s3s_config, Path("tmp/files/s3s_config.yaml"))
    return []


def build_file_list(
    scripts: list[CoreOSFile], configs: list[CoreOSFile]
) -> list[CoreOSFile]:
    return scripts + configs


def write_fcc(install_config: CoreOSSInstall, path: Path) -> None:
    os.makedirs(path.parent, exist_ok=True)
    with open(path, "w") as f:
        yaml.dump(dataclasses.asdict(install_config), f)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--type",
        type=InstallType,
        choices=[t.value for t in InstallType],
        required=True,
    )
    parser.add_argument("--master-token", type=str, required=False)
    parser.add_argument("--install-username", type=str, required=True)
    parser.add_argument("--install-user-pubkey", type=str, required=True)
    parser.add_argument("--node-hostname", type=str, required=False)
    parser.add_argument("--node-addr", type=str, required=False)
    parser.add_argument("--k3s-selinux-rpm-url", type=str, required=True)
    parser.add_argument("--coreos-arch", default="x86_64", type=str, required=False)
    parser.add_argument(
        "--coreos-release-stream", default="stable", type=str, required=False
    )
    parser.add_argument("--coreos-platform", default="metal", type=str, required=False)
    parser.add_argument(
        "--install-device", default="/dev/sda", type=str, required=False
    )

    args = parser.parse_args()
    context = vars(args)
    units = get_systemd_units(Path(f"{BASE_DIR}/files/systemd_units"), context)
    scripts = get_scripts(
        Path(f"{BASE_DIR}/files/scripts"),
        Path(f"{BASE_DIR}/tmp/files/scripts"),
        context,
    )
    configs = [
        CoreOSFile(
            path="s3s_config.yaml",
            mode=644,
            contents=CoreOSFileContent(
                yaml.dump(
                    dataclasses.asdict(
                        S3sConfig(
                            token=args.master_token,
                            ttl_san=[
                                args.node_hostname,
                                args.node_addr,
                            ],
                            node_ip=args.node_addr,
                            write_kubeconfig_mode="0644",
                        )
                    )
                )
            ),
            overwrite=True,
        )
    ]
    built_coreos_install = CoreOSSInstall(
        systemd=units,
        storage=CoreOSStorage(
            files=build_file_list(scripts, configs),
        ),
        passwd=CoreOSPasswd(
            users=[
                CoreOSUser(
                    name=args.install_username,
                    ssh_authorized_keys=[args.install_user_pubkey],
                )
            ]
        ),
        variant="fcos",
        version="1.7.0",
    )
    write_fcc(built_coreos_install, Path("tmp/coreos_install.yaml"))


if __name__ == "__main__":
    main()
