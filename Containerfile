# Multi-stage build
ARG FEDORA_MAJOR_VERSION=38

## Build ublue-os-base
FROM quay.io/fedora-ostree-desktops/sericea:${FEDORA_MAJOR_VERSION}
# See https://pagure.io/releng/issue/11047 for final location

COPY --from=ghcr.io/ublue-os/udev-rules:latest /ublue-os-udev-rules /

# Add Vanilla First Setup

COPY etc /etc

COPY ublue-firstboot /usr/bin
COPY recipe.yml /etc/ublue-recipe.yml

COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

RUN rpm-ostree override remove firefox firefox-langpacks && \
    echo "-- Installing RPMs defined in recipe.yml --" && \
    rpm_packages=$(yq '.rpms[]' < /etc/ublue-recipe.yml) && \
    for pkg in $rpm_packages; do \
        echo "Installing: ${pkg}" && \
        rpm-ostree install $pkg; \
    done && \ 
    echo "---" && \

    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable flatpak-system-update.timer && \
    rm -rf \
        /tmp/* \
        /var/* && \
    ostree container commit
