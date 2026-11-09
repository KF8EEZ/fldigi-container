# fldigi container

fldigi 4.2.13 (plus flmsg, flamp and flwrap, launched from fldigi's menus) built from upstream source; the same Containerfile builds on amd64 and arm64 (Raspberry Pi 5).

## Use
```
cp .env.example .env      # set DIGIRIG_SERIAL (ls /dev/serial/by-id/) and UID (id -u)
xhost +SI:localuser:$USER # allow the container to use your display (each login)
podman-compose up --build
```
Change the version with `FLDIGI_VERSION` in `.env`. To verify the download, pass `FLDIGI_SHA256` as a build arg.

## Digirig settings in fldigi
- Configure → Sound Card → Audio: pick the Digirig ("USB Audio CODEC") via PulseAudio or PortAudio.
- Configure → Rig Control → Hamlib or RigCAT: use serial device `/dev/digirig`. For PTT, use RTS on the same port.

Config, logs and NBEMS data persist in `./data/` (`fldigi`, `fldigi.files`, `nbems`, `NBEMS.files`).

## Helper binaries
Installed in the container under `/usr/bin`. In fldigi, set these under Configure → Misc → NBEMS:
- flmsg: `/usr/bin/flmsg`
- flamp: `/usr/bin/flamp`
- flwrap: `/usr/bin/flwrap`
