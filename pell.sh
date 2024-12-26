#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export PELL_CHAIN_ID=ignite_186-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 -y

# install go
cd $HOME
VER="1.22.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

# download binary
cd $HOME
wget -O pellcored https://github.com/0xPellNetwork/network-config/releases/download/v1.1.1-ignite/pellcored-v1.1.1-linux-amd64
chmod +x pellcored
mv pellcored ~/go/bin/
WASMVM_VERSION=v2.1.2
export LD_LIBRARY_PATH=~/.pellcored/lib
mkdir -p $LD_LIBRARY_PATH
wget "https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so" -O "$LD_LIBRARY_PATH/libwasmvm.$(uname -m).so"
echo "export LD_LIBRARY_PATH=$HOME/.pellcored/lib:$LD_LIBRARY_PATH" >> $HOME/.bash_profile
source ~/.bash_profile

# config
pellcored config chain-id $PELL_CHAIN_ID
pellcored config keyring-backend test

# init
pellcored init $NODENAME --chain-id $PELL_CHAIN_ID

# download genesis and addrbook
wget -O $HOME/.pellcored/config/genesis.json https://server-5.itrocket.net/testnet/pell/genesis.json
wget -O $HOME/.pellcored/config/addrbook.json  https://server-5.itrocket.net/testnet/pell/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0apell\"|" $HOME/.pellcored/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="d003cb808ae91bad032bb94d19c922fe094d8556@pell-testnet-peer.itrocket.net:58656,c9271f5c59d84c71d8cbbed00a01ebb517543c8f@65.109.79.44:31656,bfb2a7a01bd7cc5083e5511062e4aec2342a99d4@152.53.51.57:57656,845f329a0d3b6854de2375fc61bdfe38548009df@161.35.238.92:26656,9c1c580ace9455fe5bcac2dd266fb092d8267574@84.247.129.254:26656,9b955d07f05b02b3d622f9cb7a0e6cfecd719985@34.87.47.193:26656,d52c32a6a8510bdf0d33909008041b96d95c8408@34.87.39.12:26656,a4a3f561abf0c2c156a56d1272755ec710c25d76@212.47.64.127:26656,226370ed50e18b838b3f3454d55d0143a3b6d6b3@5.252.55.45:26656,c5b95fa4083e83c8183ee46fb7e749dffc78ef8e@37.27.219.111:26656,cc534f42fa3b5734de1a7496b64d0fa7c9dbe2db@158.220.125.190:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.pellcored/config/config.toml

# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.pellcored/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.pellcored/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.pellcored/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.pellcored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.pellcored/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.pellcored/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.pellcored/config/config.toml

# create service
sudo tee /etc/systemd/system/pellcored.service > /dev/null << EOF
[Unit]
Description=Pell node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which pellcored) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# reset
pellcored tendermint unsafe-reset-all --home $HOME/.pellcored --keep-addr-book
curl https://server-5.itrocket.net/testnet/pell/pell_2024-12-26_288738_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.pellcored

# start service
sudo systemctl daemon-reload
sudo systemctl enable pellcored
sudo systemctl restart pellcored

break
;;

"Create Wallet")
pellcored keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
PELL_WALLET_ADDRESS=$(pellcored keys show $WALLET -a)
PELL_VALOPER_ADDRESS=$(pellcored keys show $WALLET --bech val -a)
echo 'export PELL_WALLET_ADDRESS='${PELL_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export PELL_VALOPER_ADDRESS='${PELL_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
pellcored tx staking create-validator \
--amount=1000000apell \
--pubkey=$(pellcored tendermint show-validator) \
--moniker=$NODENAME \
--chain-id=ignite_186-1 \
--commission-rate=0.10 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=wallet \
--gas-adjustment=1.5 \
--gas=300000 \
-y 
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
