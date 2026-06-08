{ pkgs, ... }:
{
  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "ax25" "netrom" "rose"

    # Old or rare or insufficiently audited filesystems
    "adfs" "affs"
    "bfs" "befs"
    "cramfs"
    "efs" "erofs" "exofs"
    "freevxfs" "f2fs"
    "hfs" "hpfs"
    "jfs"
    "minix"
    "nilfs2" "ntfs"
    "omfs"
    "qnx4" "qnx6"
    "sysv"
    "ufs"
  ];

  security.protectKernelImage = true;

  boot.kernelParams = [
   # Don't merge slabs
   "slab_nomerge"

   # Overwrite free'd pages
   "page_poison=1"

   # Enable page allocator randomization
   "page_alloc.shuffle=1"

   # Disable debugfs
   "debugfs=off"
  ];
  
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = "2";
    "net.core.bpf_jit_enable" = false;
    "kernel.ftrace_enabled" = false;
    "kernel.io_uring_disabled" = 2;
    "net.ipv4.conf.all.log_martians" = true;
    "net.ipv4.conf.all.rp_filter" = "1";
    "net.ipv4.conf.default.log_martians" = true;
    "net.ipv4.conf.default.rp_filter" = "1";
    "net_ipv4.icmp_echo_ignore_broadcasts" = true;
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.all.secure_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv4.conf.default.secure_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;
  };

  security.forcePageTableIsolation = true;

  environment.memoryAllocator.provider = "graphene-hardened";

  security.apparmor.enable = true;
  security.apparmor.killUnconfinedConfinables = true;
}
