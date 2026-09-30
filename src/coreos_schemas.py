import dataclasses
import enum


class InstallType(enum.Enum):
    CONTROLPLANE = "controlplane"
    NODE = "node"

    def __str__(self):
        return self.value


@dataclasses.dataclass
class BaseCoreOSSchema:
    def to_yaml_dict(self) -> dict:
        return dataclasses.asdict(
            self, dict_factory=lambda x: {k: v for (k, v) in x if v is not None}
        )


@dataclasses.dataclass
class K3sConfig(BaseCoreOSSchema):
    token: str
    ttl_san: list[str]
    node_ip: str
    write_kubeconfig_mode: int


@dataclasses.dataclass
class CoreOSFileContent(BaseCoreOSSchema):
    inline: str


@dataclasses.dataclass
class CoreOSFile(BaseCoreOSSchema):
    path: str
    mode: int
    contents: CoreOSFileContent
    overwrite: bool = False


@dataclasses.dataclass
class CoreOSStorage(BaseCoreOSSchema):
    files: list[CoreOSFile]


@dataclasses.dataclass
class CoreOSUser(BaseCoreOSSchema):
    name: str
    ssh_authorized_keys: list[str]


@dataclasses.dataclass
class CoreOSPasswd(BaseCoreOSSchema):
    users: list[CoreOSUser]


@dataclasses.dataclass
class CoreOSSDUnitBase(BaseCoreOSSchema):
    name: str


@dataclasses.dataclass
class CoreOSSDUnit(CoreOSSDUnitBase):
    enabled: bool | None = None
    contents: str | None = None


@dataclasses.dataclass
class CoreOSSDUnitDropin(CoreOSSDUnitBase):
    name: str
    dropins: list[CoreOSSDUnit] | None = None


@dataclasses.dataclass
class CoreOSUnits(BaseCoreOSSchema):
    units: list[CoreOSSDUnitBase]


@dataclasses.dataclass
class CoreOSSInstall(BaseCoreOSSchema):
    systemd: CoreOSUnits
    storage: CoreOSStorage
    passwd: CoreOSPasswd
    variant: str = "fcos"
    version: str = "1.7.0"
