mkdir -p ~/.local/bin
cp obsidian-onedrive-sync.sh ~/.local/bin/obsidian-onedrive-sync
chmod +x ~/.local/bin/obsidian-onedrive-sync

mkdir -p ~/.config/systemd/user
cp obsidian-onedrive-sync.service ~/.config/systemd/user/obsidian-onedrive-sync.service

systemctl --user daemon-reload
systemctl --user enable --now obsidian-onedrive-sync.service
systemctl --user status obsidian-onedrive-sync.service