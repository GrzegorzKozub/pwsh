qemu-system-x86_64 `
  -name windows `
  -smp 4,sockets=1,cores=2,threads=2 `
  -m 8G `
  -accel whpx,kernel-irqchip=off `
  -vga none -device qxl-vga,vgamem_mb=64,ram_size_mb=128,vram_size_mb=256,vram64_size_mb=256 `
  -nic user,model=virtio-net-pci,smb=d:\users\greg\downloads `
  -usbdevice tablet `
  -drive file=d:\software\windows.cow,if=virtio,aio=native,cache.direct=on `
  -boot menu=on `
  -monitor stdio

  # -cpu max,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,topoext `

