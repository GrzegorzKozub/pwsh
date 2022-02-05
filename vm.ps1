qemu-system-x86_64 `
-name windows `
-smp 4,sockets=1,cores=2,threads=2 `
-m 8G `
-vga none -device qxl-vga,vgamem_mb=64,ram_size_mb=128,vram_size_mb=256,vram64_size_mb=256 `
-accel whpx,kernel-irqchip=off `
-device ich9-intel-hda `
-device hda-output `
-nic user,model=virtio-net-pci,smb=c:\users\greg\downloads `
-usbdevice tablet `
-drive file=windows.cow,if=virtio,aio=native,cache.direct=on `
-boot menu=on `
-monitor stdio

