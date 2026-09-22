### CoreOS w/ K3s Ignition Config Generator

Rough Makefile and Fedora CoreOS configuration to generate an ~~image~~
Ignition config that automatically installs K3s

Heavily based on this helpful article by Leanardo Murillo:
https://www.murillodigital.com/tech_talk/k3s_in_coreos/

### Usage:

#### SSH Key

Add your SSH public key as an env var to a new `.env` file:
```sh
COREOS_USER_PUBKEY="ssh-ed25519 AAAAetcetcetcASDASD"
```

### Tweak Install Configuration (Optional)

Make any desired changes to `./k3s-autoinstall.fcc`

#### Build IGN Config

Generate the IGN config from the FCC YAML:
```sh
make build-ign
```

#### Install CoreOS with Ignition Config

Download [CoreOS](https://fedoraproject.org/coreos/download/) and boot into it on your VM or PC

Start the install using the previously compiled `.ign` file
