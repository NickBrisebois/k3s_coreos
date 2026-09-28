import dataclasses
import enum


class InstallType(enum.Enum):
    CONTROLPLANE = "controlplane"
    NODE = "node"

    def __str__(self):
        return self.value


@dataclasses.dataclass
class S3sConfig:
    token: str
    ttl_san: list[str]
    node_ip: str
    write_kubeconfig_mode: str


@dataclasses.dataclass
class CoreOSFileContent:
    inline: str


@dataclasses.dataclass
class CoreOSFile:
    path: str
    mode: int
    contents: CoreOSFileContent
    overwrite: bool = False


@dataclasses.dataclass
class CoreOSStorage:
    files: list[CoreOSFile]


@dataclasses.dataclass
class CoreOSUser:
    name: str
    ssh_authorized_keys: list[str]


@dataclasses.dataclass
class CoreOSPasswd:
    users: list[CoreOSUser]


@dataclasses.dataclass
class CoreOSSDUnit:
    name: str
    enabled: bool
    contents: str | None = None


@dataclasses.dataclass
class CoreOSUnits:
    units: list[CoreOSSDUnit]


@dataclasses.dataclass
class CoreOSSInstall:
    systemd: CoreOSUnits
    storage: CoreOSStorage
    passwd: CoreOSPasswd
    variant: str = "fcos"
    version: str = "1.7.0"
