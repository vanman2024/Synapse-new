@echo off
wsl -d Ubuntu-22.04 -e bash -c "cd /mnt/c/Users/user/SynapseProject/Synapse-new && nohup ./scripts/auto-commit.sh 3 > auto-commit.log 2>&1 &"
exit
