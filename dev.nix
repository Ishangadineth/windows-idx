{ pkgs, ... }:

{
  # Ngôn ngữ / runtime (không bắt buộc)
  languages = {
    nix.enable = true;
  };

  # Packages được cài sẵn trong môi trường IDX
  packages = with pkgs; [
    qemu
    qemu_kvm
    curl
    sudo
    apt
    git
    wget
    unzip
    pciutils
    usbutils
    iproute2
    busybox
  ];

  # Biến môi trường
  env = {
    QEMU_AUDIO_DRV = "none";
  };

  # Script chạy khi workspace được tạo / rebuild
  scripts = {
    postStart = ''
      echo "✅ IDX dev environment ready"
      echo "QEMU version:"
      qemu-system-x86_64 --version
    '';
  };
}
