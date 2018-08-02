# undefinedsync

I have a Minecraft server hosted on an OUYA console. It runs the Oracle 8 JRE for ARMv7hf on Debian Wheezy. It's root filesystem is on a USB hard drive, and the console is booted tethered to a computer with ``adb reboot-bootloader; fastboot boot /path/to/kernel``. Once booted, the server is standalone and uses little power. It's a great way to utilize the OUYA.

However, I don't run the console 24/7, as it gets a bit warm and only sees use about 3 hours a day from various friends. Also, the server has to be taken down to use the OUYA as a game console. At times, while the console is offline, someone wants to play on their own machine, locally. The plan is for this app to allow for the sharing of the server world, configs, and JAR executable through file sharing services (e.g. Google Drive). That way, players can work on the world locally. Trusted users can then upload their local changes later. The app should act as a form of version control. It will be written in Nim, and be equipped with a simple GUI.

See:
* http://tuomas.kulve.fi/blog/2013/09/12/debian-on-ouya-all-systems-go/
* https://github.com/kulve/tegra-debian
* https://nim-lang.org/
