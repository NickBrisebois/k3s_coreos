<img width="131" height="42" alt="Developed-By-a-Human-Not-By-AI-Badge-black@2x" src="https://github.com/user-attachments/assets/8dc103c1-9d91-46ee-8de4-673ac1f589dc" />



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


##### Option 1:
Download [CoreOS](https://fedoraproject.org/coreos/download/) and boot into it on your VM or PC

Start the install using the previously compiled `.ign` file

##### Option 2:
Build CoreOS ISO with Ignition config built in:
```sh
make build-iso
```

Install the ISO
