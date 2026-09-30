<img width="131" height="42" alt="Developed-By-a-Human-Not-By-AI-Badge-black@2x" src="https://github.com/user-attachments/assets/8dc103c1-9d91-46ee-8de4-673ac1f589dc" />



### CoreOS w/ K3s Ignition Config Generator


Rough Makefile and Fedora CoreOS configuration to generate a CoreOS ISO or Ignition config that automatically installs K3s

Heavily based on this helpful article by Leanardo Murillo:
https://www.murillodigital.com/tech_talk/k3s_in_coreos/

### Usage:

#### SSH Key

Add your SSH public key as an env var to a new `.env` file:
```sh
COREOS_USER_PUBKEY="ssh-ed25519 AAAAetcetcetcASDASD"
```

`env.example` also lists all of the other configuration options you'll need to set too.

### Tweak Install Configuration (Optional)

Make any desired changes to the templates in `src/files`, however you shouldn't actually need to for most installs. Changing the `.env` values should be enough.

#### Build FCC YAML

Generate the Butane/FCC YAML file from the templates using the Python script:
```sh
make build-fcc
```

The make command automatically loads environment variables from `.env` and injects them into the exported template. The resulting file is saved to `./tmp/k3s-autoinstall.fcc`

#### Build IGN Config

Generate the IGN config from the FCC YAML:
```sh
make build-ign
```

The `.ign` file will be saved to `./build/k3s-autoinstall.igc'

#### Build the Ignition config into a CoreOS ISO

```sh
make build-iso
```

This will handle automatically downloading a base CoreOS ISO and edits it to include the Ignition config from `./build/k3s-autoinstall.ign`.

Once built, the ISO will be saved to `./build` and can be burned to a USB drive or loaded into a VM.

#### Alternative Installation

You can also install CoreOS manually using the base CoreOS ISO and the `.ign` file compiled with `make build-ign`.

Download [CoreOS](https://fedoraproject.org/coreos/download/) and then boot into it on your VM or PC

Start the install with the `coreos-installer` command and pass in the `.ign` file
