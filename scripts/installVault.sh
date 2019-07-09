P=vault

VERSION=$(curl -sL https://releases.hashicorp.com/${P}/index.json | jq -r '.versions[].version' | sort -V | egrep -v 'ent|beta|rc|alpha' | tail -n1)
#VERSION=""
# arch
if [[ "`uname -m`" =~ "arm" ]]; then
  ARCH=arm
else
  ARCH=amd64
fi
wget -q -O /tmp/${P}.zip https://releases.hashicorp.com/${P}/${VERSION}/${P}_${VERSION}_linux_${ARCH}.zip
unzip -o -d /usr/local/bin /tmp/${P}.zip
rm /tmp/${P}.zip

# Some more debug if fails.
set -o xtrace

#Enable autocomplete
echo "Setting up autocomplete"

vault -autocomplete-install
complete -C /usr/local/bin/vault vault

# Enable mlock() without being root, it prevents memory pages to be swapped to the disk.
echo "Enabling mlock() without being root, it prevents memory pages to be swapped to the disk."
setcap cap_ipc_lock=+ep /usr/local/bin/vault

echo "Setting up vault user"
mkdir -p /etc/vault.d

chown -R vault:vault /etc/vault.d

sudo useradd --system --home /etc/vault.d --shell /bin/false vault

touch /etc/systemd/system/vault.service

# Unit file for Vault
cat << EOF > /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Conf dir and simple startup config


touch /etc/vault.d/vault.hcl

cat << EOF > /etc/vault.d/vault.hcl
backend "file" {
path = "/vaultDataDir"
}
listener "tcp" {
address = "0.0.0.0:8200"
tls_disable = 1
}

# Enable UI
ui = true
EOF

# Create data dir for Vault

echo "Creating date dir for Vault"

mkdir -p /vaultDataDir

chown vault:vault /vaultDataDir

# Let systemd know about its new UNIT file, and  us it.
systemctl daemon-reload
systemctl enable vault
systemctl start vault

apt-get autoremove -y
apt-get clean

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

# Zero out the free space to save space in the final image:
echo "Zeroing device to make space..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

set +x