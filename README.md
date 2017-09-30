# QColdsweat

Provides automatic, smart and convenient installation of [Coldsweat](https://github.com/passiomatic/coldsweat) for owners of QNAP devices. Finally __NOT__ a work under progress :).

Features:
* Coldsweat is patched so that application and data can be kept separate.
	* This is a design choice that allows vital data (most importantly configuration and database) to be preserved even if you remove the QPKG or upgrade to a newer version.
* Commitment for longterm support.
	* I'm using the QPKG myself and don't expect to move to any alternative as Coldsweat is only getting better and the authors seem quite reliable regarding the application's future.
* Tested on TS-212 and TS-251.

Known limitations:
* Sadly, no SSL/TLS yet (only plain http). Ergo, not too suitable for remote access if you care about your privacy. Should you really want/need this, however, let me know - I might be able to do something about it.
* By default, no automatic feed fetch yet (only manual CLI command to re-fetch feeds). But with [my guide](https://github.com/SkyCrawl/coldsweat-qpkg/wiki/Guide-to-patch-Coldsweat-to-provide-automatic-feed-fetch-feature-via-a-URL), it's easy to manually hotfix Coldsweat to provide the same functionality via a URL - then, you only need to create a bookmarklet (`http://<host-or-ip-address-of-your-qnap>:3333/feeds/fetch`) in your browser :).

Alternatively, Coldsweat can be installed via Docker but I don't think it's going to be always up to date, super stable, user convenient or without issues:
* <https://github.com/dannysu/docker-coldsweat>
* <https://github.com/RobinThrift/docker-coldsweat>

## Requirements

* QNAP firmware (QTS) v4.x (minimum v4.1.0).
* [Entware-ng](https://github.com/Entware-for-kernel-3x/Entware-ng-3x/wiki/Install-on-QNAP-NAS) (minimum v0.99).

## Installation

Very simple:

1. Download and install QColdsweat from the [build](https://github.com/qnap-pack-man/qcoldsweat/tree/master/build) folder.
    * __Note:__ first click on the target QPKG and then hit the `Download` button.
2. Login to your QNAP, open App Center, click on the cog icon (top right corner), navigate to the QPKG and confirm.
	* If you can't install Entware for some reason, navigate [here](https://forum.qnap.com/viewtopic.php?t=124894).
3. __NOTE: Installation is a little network intensive and even compiles some software so it may take up to 15 minutes or more to finish! Please be patient :).__
4. Open `http://<host-or-ip-address-of-your-qnap>:3333` in your browser and login as `coldsweat`, with `coldsweat` as password.
5. __IMPORTANT: Change the default password through the left menu__.
6. Either start trying it out or head over to [the official GitHub page](https://github.com/passiomatic/coldsweat) to learn more. I recommend paying attention to the combination of Fever API and client applications.

__Useful hints:__
* Speaking of Fever API, you actually authenticate to Coldsweat with an email. In case of the default account, that means `coldsweat@my-qnap.com`. No worries, you don't need real access to the email for anything. You can always create your own account anyway.

__Troubleshooting installation:__  
In the unlikely case that step 2 or 3 fails and you're sure about the host or IP address, installation most likely failed. Here's what you should do:

1. SSH (or sFTP) into your QNAP.
2. Retrieve the installation log (details over [here](https://github.com/SkyCrawl/coldsweat-qpkg/wiki)).
3. Submit a new issue here on GitHub and provide me with the log.

## Upgrading

1. Open App Center and uninstall the old version of QColdsweat. Don't worry, everything important is preserved.
2. Install the new version of QColdsweat (see the [installation](#installation) section).
3. Installation may give you a warning saying: `Configuration file needs to be upgraded manually`. In such an event, you have previously made manual modifications to Coldsweat's configuration file and the program can not upgrade it automatically. Your old configuration file is saved in the [data folder](https://github.com/SkyCrawl/QColdsweat/wiki) (it should be something like `config.5AE3`). I kindly ask you to:
    1. Merge the saved configuration file with the new one (named `config`).
    2. SSH into your QNAP and run:
    ```
    INSTALL_PATH="$(/sbin/getcfg QColdsweat Install_Path -f /etc/config/qpkg.conf)"
    python "$INSTALL_PATH/coldsweat/sweat.py" upgrade
    ```

## What you should definitely know about this QPKG

The most important thing is the backend database - by default, Coldsweat is backed by a single sqlite3 database image file. While this is the simplest of options (works out-of-the-box), it is not the best. For one thing, sqlite3 has not really been designed with concurrency in mind, i.e. for multiprocessing applications like Coldsweat (if interested, also see [this](http://beets.io/blog/sqlite-nightmare.html) article). Therefore, it is not recommended to use sqlite3 database as a backend indefinitely, especially if you're not going to be the only one using Coldsweat on your QNAP.

Alternatively, Coldsweat works with a MySQL-like databases or PostgreSQL. However, installation is a bit advanced and additional steps are required:
* [Befriend QColdsweat with a MySQL-like database](https://github.com/SkyCrawl/QColdsweat/wiki/Befriend-QColdsweat-with-a-MySQL-like-database).
* [Befriend QColdsweat with a PostgreSQL database](https://github.com/SkyCrawl/QColdsweat/wiki/Befriend-QColdsweat-with-a-PostgreSQL-database).

__Finally, I can't stress this enough... always regularly backup your database! You never know what issues you may run into and how much valuable data (think saved/starred resources) you may lose. Also notice that although Coldsweat is very stable now, the latest version is `0.9.7` (pre-release) which means that the authors are still not completely confident or feel that the application deserves to be "officially released" yet. With that said, don't be afraid of using the application. I'm using it myself and am happy with it, aside several small issues. This is how to properly back up your database:__
* [SQLite3](http://stackoverflow.com/questions/25675314/how-to-backup-sqlite-database).
* [PostgreSQL](https://www.postgresql.org/docs/9.3/static/backup.html).
* There's a number of MySQL-like databases but for reference:
	* [Oracle's MySQL](https://dev.mysql.com/doc/refman/5.5/en/backup-and-recovery.html).
	* [MariaDB](https://mariadb.com/kb/en/mariadb/backup-and-restore-overview/)
	
## Dev notes

* It's good to re-install Entware-ng before testing for successful installation of a release candidate.

## I'm your ally

If you have any issues, questions or requests, feel free to submit an issue here on GitHub.
