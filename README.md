# Coldsweat QPKG wrapper

This project is meant to provide automatic installation and management of _[Coldsweat](https://github.com/passiomatic/coldsweat)_ in a user convenient way for owners of QNAP devices.

Work under progress.

## Features planned

1. Provide access to Coldsweat's web UI (reader) with some features already included.
3. Basic configuration of Coldsweat via a dedicated web UI (currently, only CLI is supported):
    * User management.
    * Coldsweat's web UI: port number and public access specification.
4. Safety measures:
    * Export database content.
    * Export current configuration.
    
## Features NOT planned (at least in the meantime)

1. Automatic update. Coldsweat is still not perfectly fine-tuned and this project can not impose structural dependencies on it just yet. If such an update occurs, the QPKG would not function correctly.

## Updating QPKG in QTS

Has to be done manually for now:

1. Export & save configuration.
2. Export & save database content.
3. Uninstall the old version from QNAP.
4. Install the new version on QNAP.
5. Import saved configuration.
6. Import saved database content.
7. Execute Coldsweat's own [update procedure](https://github.com/passiomatic/coldsweat#upgrading-from-previous-versions).
