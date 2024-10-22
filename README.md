
## Install or update


### Installazione dipendenze

* GnuPG
* AWS cli
* jq
* pv


#### GnuPG e jq

Su debian e derivate:

```bash
apt-get install gpg jq pv
```

#### AWS cli

Seguire le istruzioni della [documentazione ufficiale](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

In breve: 

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws
```


### Installazione script

```bash
# download e installazione script
mkdir -p /opt/backup-cloud && \
    curl -sL https://github.com/acattaneo-bitagora/cloud-backup/archive/master.tar.gz | tar -xzvC /opt/backup-cloud --strip-components=1

# creare il file di configurazione 
cp /opt/backup-cloud/config.default.sh /opt/backup-cloud/config.sh
```


### Configurazione

Editare `/opt/backup-cloud/config.sh` per configurare i parametri necessari al backup.

Il percorso di cui effettuare il backup è configurabile modificando la variabile `FOLDER_TO_PROCESS` all'interno del file di configurazione.
Può essere impostato anche come parametro al comando di backup, in questo caso il parametro ha la precedenza sulla configurazione.
