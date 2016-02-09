rem Windows script to start the virtualbox web service ready for rexray

cd "c:\Program Files\Oracle\VirtualBox\
VBoxManage setproperty websrvauthlibrary null
start vboxwebsrv -H 0.0.0.0 -v
