FROM archlinux:base-devel
LABEL contributor="shadowapex@gmail.com"
COPY rootfs/etc/pacman.conf /etc/pacman.conf
RUN echo -e "keyserver-options auto-key-retrieve" >> /etc/pacman.d/gnupg/gpg.conf && \
    # Cannot check space in chroot
    sed -i '/CheckSpace/s/^/#/g' /etc/pacman.conf && \
    pacman-key --init && \
    pacman --noconfirm -Syyuu --disable-download-timeout && \
    pacman --noconfirm -S --disable-download-timeout \
    arch-install-scripts \
    btrfs-progs \
    fmt \
    xcb-util-wm \
    wget \
    pyalpm \
    python-build \
    python-installer \
    python-hatchling \
    python-markdown-it-py \
    python-setuptools \
    python-wheel \
    rust \
    sudo \
    && \
    pacman --noconfirm -S --disable-download-timeout --needed git && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd build -G wheel -m && \
    su - build -c "git clone https://aur.archlinux.org/pikaur.git /tmp/pikaur" && \
    su - build -c "cd /tmp/pikaur && makepkg -f" && \
    pacman --noconfirm -U /tmp/pikaur/pikaur-*.pkg.tar.zst

# Auto add PGP keys for users
RUN mkdir -p /etc/gnupg/ && echo -e "keyserver-options auto-key-retrieve" >> /etc/gnupg/gpg.conf

# Add a fake systemd-run script to workaround pikaur requirement.
RUN echo -e "#!/bin/bash\nif [[ \"$1\" == \"--version\" ]]; then echo 'fake 244 version'; fi\nmkdir -p /var/cache/pikaur\n" >> /usr/bin/systemd-run && \
    chmod +x /usr/bin/systemd-run

# substitute check with !check to avoid running software from AUR in the build machine
RUN sed -i -e 's/BUILDENV=(!distcc color !ccache check !sign)/BUILDENV=(!distcc color !ccache !check !sign)/g' /etc/makepkg.conf

COPY manifest /manifest
# Freeze packages and overwrite with overrides when needed
RUN source /manifest && \
    echo "Server=https://archive.archlinux.org/repos/${ARCHIVE_DATE}/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist && \
    pacman --noconfirm -Syyuu --disable-download-timeout; if [ -n "${PACKAGE_OVERRIDES}" ]; then wget --directory-prefix=/tmp/extra_pkgs ${PACKAGE_OVERRIDES}; pacman --noconfirm -U --overwrite '*' /tmp/extra_pkgs/*; rm -rf /tmp/extra_pkgs; fi

USER build
ENV BUILD_USER "build"
ENV GNUPGHOME  "/etc/pacman.d/gnupg"
# Built image will be moved here. This should be a host mount to get the output.
ENV OUTPUT_DIR /output

WORKDIR /workdir
