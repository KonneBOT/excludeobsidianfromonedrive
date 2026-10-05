## Start monitor with --check-for-nosync
Do not use the global config to enable check-for-nosync as this will apply to the process started by the user service.
Instead edit your running onedrive monitor service:
`systemctl --user edit onedrive.service`
Add
```plain
[Service]
ExecStart=
ExecStart=/usr/bin/onedrive --monitor --check-for-nosync
```
in between the comments after line 3 (!). This is a drop in, you won't modify the actual service file by doing it that way.

## Run the install.sh script
This should create the new user service, drop it into usr/bin and.