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
wget -O pellcored https://github.com/0xPellNetwork/network-config/releases/download/v1.1.5/pellcored-v1.1.5-linux-amd64
chmod +x pellcored
mv pellcored ~/go/bin/
WASMVM_VERSION=v2.1.2
export LD_LIBRARY_PATH=~/.pellcored/lib
mkdir -p $LD_LIBRARY_PATH
wget "https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so" -O "$LD_LIBRARY_PATH/libwasmvm.$(uname -m).so"
echo "export LD_LIBRARY_PATH=$HOME/.pellcored/lib:$LD_LIBRARY_PATH" >> $HOME/.bash_profile
source ~/.bash_profile

# config
#pellcored config chain-id $PELL_CHAIN_ID
#pellcored config keyring-backend test

# init
pellcored init $NODENAME --chain-id $PELL_CHAIN_ID

# download genesis and addrbook
curl https://config-t.noders.services/pell/genesis.json -o ~/.pellcored/config/genesis.json
curl https://config-t.noders.services/pell/addrbook.json -o ~/.pellcored/config/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.001apell\"|" $HOME/.pellcored/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="f2474b5e49e1399ee933cb28776dd9893941457d@135.181.210.46:57656,e0db435083b4a927ef34d46780a86ae263dbed8c@95.216.54.249:58656,7fd83fe2a75067fd04aa8471a4ad2396134ee234@65.21.45.194:36656,ba285774a2551cf24807f9159f59762adc60a51f@135.181.236.254:57656,f24942ba7d9d4b30d6cd4f93c8ec0a9cf59e01c8@95.217.227.243:57656,c2bb903f085b74dd0742a51d5d736f0502b844bc@141.94.3.12:26656,b128b2e99ba25e8c2931467222fb3e59b18e357d@95.216.39.166:57656,c7b3b11ec3fbb7c2db6dacb7a3f62dd1cbba5341@37.27.219.111:26656,1449c8ddff43b2af357d81426664772da2227dab@95.217.229.93:57656,4efd5164f02c3af4247fc0292922af8d08a46ae6@51.89.1.16:26656,1189d15c84a5b79a95cdf0cc65d007c6aa85b66d@49.12.82.124:26656,69ba998fe803841a7d9d19012cdb9e5f9085b872@84.247.187.77:26656,0a03dd1ece6707d2e029a7c39b29d85ae0c8f307@188.245.102.28:57656,73270186a4ed6a4136a2c02274867c0c41c304dd@46.4.91.76:30356,969e6b8df14860c3f5176cba6af317e3666f721d@82.223.17.254:26656,933bc92601f9e799ce47ea66a96b706b784324ee@65.21.10.115:30156,f71d41138b798c313afab7c44cd46739bfb3419d@190.2.149.83:26656,f9d8f9da5b29108f514fc70e1aa884f7fae2db58@95.216.248.113:57656,8edf8c17a1145355594888c35341fdcc0f0f460a@158.220.96.232:26656,09a7ceb1234360d112b07cfc1a7df2be55185efc@77.237.241.33:26656,53eb7a5d2ee95d6e73de260b35659ecf8ba087ef@95.214.54.196:57656,a531b65eda28874fccfdf51278f62249c7f455f2@65.109.123.185:57656,58c2ffb3e16f61462ebf26730cbc27b458ea82c0@34.44.209.45:26656,1d43ae39c11c4c06d1858514d85bd7c1238e1499@184.107.182.148:59500,3fd4174c3680bbe70d689d9bab30bdb3a706523d@188.245.60.19:26656,08dc41bf9112b64e16492c28285f6db654f076d9@164.68.112.203:26656,a943ca236e0eb3d672af480cda68204e6c842f22@31.220.81.235:26656,a1e45d424b10bd28dad3afe5158a831096a36ecb@135.181.228.89:57656,5c7b279674645bbfe34ff7ee8fb4f3769e5e478b@95.214.55.209:57656,6acaeb73550facc3f8cc6f67134f7f5afed7f714@184.107.169.193:26656,cbe0793a6b3833c310ae324866c5e01ee9b33938@148.251.77.107:58656,5d4bed5a8d01898c156245311ced5252f6b4e6e7@207.188.6.109:15656,61773e616658ea599b2871b44f6fe81972cb572b@5.9.97.39:57656,415723270260f96c6d17defaa01047fae36cda92@95.214.54.252:26656,7cc16ef8eea8fd6087d172192b784d6a8d36aa0b@207.180.204.107:26656,bfb2a7a01bd7cc5083e5511062e4aec2342a99d4@152.53.51.57:57656,1a7b6f07673a96f3a0391705da32ee184730fb7d@91.205.105.37:26656,e05d151aacac6bf0a13c5cdc2437bec849f32ff2@38.242.227.168:26656,1bcc2348282d98636bb73eff3fc39f5f06d4a3c2@65.109.53.24:58656,7a850958b474360092f1ee39eca341fe525bb27f@84.247.191.181:43656,f242529a095e7d57c29abe5fd2436df310007405@37.120.166.10:26656,48c48532950e51fba80a1031d5a58c627737ed84@65.109.82.111:25656,64773a248037add918fd594f4c0b51ab5c433dc2@95.216.173.238:57656,db743ed6abd513d65a46d7ebf0c4e46474acc888@149.50.96.91:57656,4cad46992872f86da794f47ab662592bf9ca500a@135.181.79.242:57656,969eab8b58e22ce24ce06c653f0a352c576d4d8a@65.108.199.62:58656,c9271f5c59d84c71d8cbbed00a01ebb517543c8f@65.109.79.44:31656,7244d6fe0d306706b17abdf1378b3059f80e24c1@65.108.232.34:57656,29e9d8296657e74ed6b1ee058aa27f8cd82a6489@213.239.198.181:42656,113f7c172860ce049b9fbb5eb953fa80fdc93662@65.21.67.40:29656,9b98b3d59cd6cdb46d99b65c989b108544bdde63@188.40.85.207:26656,aa5f8efff39a42bda059f943a61c9ba4d88b645c@65.21.47.120:57656,dc19652bbf35857f77120138b1cc074534f28a22@152.53.110.190:26656,a4a3f561abf0c2c156a56d1272755ec710c25d76@212.47.64.127:26656,cc9acce34ac781b76be5c9f7d9f1ed307331de06@94.72.118.149:57656,739d38ce19e4d2b22eb77016f91bf468e93c22af@37.252.186.230:26656,9c1c580ace9455fe5bcac2dd266fb092d8267574@84.247.129.254:26656,c7d05ae46ec52fb82df83bb2e3fc4ab9fe92127d@37.27.216.37:26656,5c2a752c9b1952dbed075c56c600c3a79b58c395@195.3.221.9:26736,cc534f42fa3b5734de1a7496b64d0fa7c9dbe2db@158.220.125.190:26656,4004663212dfa427029db4d817abc5c0e7416835@31.220.73.1:26656,a3d2cf3a8a0e17adcb4577f5051082cad01307b3@193.34.212.80:57656,0da56281ef57abe4608193515df261f145408ba9@65.109.58.20:36656,32fac46251436c7bee07b9aa5571f69b5fb765f4@193.34.212.164:57656,883473cf1efb51e5d4d3d66c9136c70c82aac542@74.241.131.99:31556,835e8fd7063ff047a8fe5b89a8792d03ff36d008@84.247.177.126:26656,e952af1698527dc8063cfc78b317f4cce1421c63@212.47.64.123:26656,89348824f7ac977fb751efe24d21d2bf0721563d@144.126.158.28:26656,a4662f692cbca64f7867bc48ebdb6c8b748d09a5@31.220.93.115:57656,5f10959cc96b5b7f9e08b9720d9a8530c3d08d19@65.108.75.179:58656,81caef1e38e18974813624aea310722ad68a33dd@65.109.27.148:26656,7135263446491cfe5f57398fe7b69550c1e96c31@31.220.76.39:26656,4be3adc8c7c67d9a5d9120fd1863dcac2634066b@91.107.197.166:57656,30ad730817b26f2c62029db7d6912664361aa772@37.120.191.47:26656,3d231585b8f737d507208e2f2122f24e53aefdb3@162.55.25.233:26656,5534efc3ce5355def97d4caaa5505f7dc4479529@95.216.214.18:57656,decb454839c3bcd20010526547e33ffbbb77bd06@213.136.72.187:29656,ad4c6e4477eb0d48811bf4275463198966840480@157.173.199.156:11656,3ba8268bb6725359f93cff1d7ea5e38ed145e962@94.130.164.82:47956,d03af7a603dfdb1acbc1cdf5836d7eef0a9d7d19@195.201.242.202:44656"
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
sed -i -e "s/^app-db-backend *=.*/app-db-backend = \"goleveldb\"/;" $HOME/.pellcored/config/app.toml

# create service
sudo tee /etc/systemd/system/pellcored.service > /dev/null <<EOF
[Unit]
Description=Pell node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.pellcored
ExecStart=$(which pellcored) start --home $HOME/.pellcored
Environment=LD_LIBRARY_PATH=$HOME/.pellcored/lib/
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# reset
pellcored tendermint unsafe-reset-all --home $HOME/.pellcored --keep-addr-book
curl https://server-5.itrocket.net/testnet/pell/pell_2025-01-21_643282_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.pellcored

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
