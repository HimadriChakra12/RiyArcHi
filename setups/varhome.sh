sudo cp -a /var /home/var && sudo mv /var /var.old && sudo mkdir /var && sudo mount --bind /home/var /var && echo "/home/var /var none bind 0 0" | sudo tee -a /etc/fstab
