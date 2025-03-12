@echo off
wsl -d Ubuntu-22.04 -e bash -c "cd /home/vanman2025 && pm2 resurrect"
exit
