#!/bin/bash

R='\033[0;31m' # red
Y='\033[0;33m' # yellow
G='\033[0;32m' # green
NC='\033[0m' # No Color

# contants from .env file
if [ -f .env ]; then
    export $(egrep -v '^#' .env | xargs)
fi
WHICH_RSYNC=`which rsync`
BASE_PATH=`pwd`

DELETE_ACCOUNT=false
RSYNC=false
SOURCE_FILE=false
FROM_DEDICATED_SOURCE=false

while getopts "hdsf:" option
do
    case $option in
        h) printf "usage: $0 [-h] [-d] [-s] [-f path]\n";exit;;
        d) DELETE_ACCOUNT=true;;
        s) RSYNC=true;;
        f) SOURCE_FILE="$BASE_PATH""/""$OPTARG";FROM_DEDICATED_SOURCE=true;;
    esac
done

printf "Domain list from ${Y}"
if [ -f "$SOURCE_FILE" ]; then
    printf "$SOURCE_FILE"
else
    # list domains to file
    printf "zimbra domains"
    SOURCE_FILE="$BASE_PATH""/domains_temp.txt"
    `zmprov gad > "$SOURCE_FILE"`
fi
printf "${NC}\n"

printf "Delete account ${Y}""$DELETE_ACCOUNT""${NC}\n"
printf "Sync account ${Y}""$RSYNC""${NC}\n"

printf "${Y}Start script (y*/n)?${NC} "
read answer
if [ "$answer" != "${answer#[Yy]}" ] || [ "$answer" == "" ] ;then
    printf ""
else
    printf "${R}Terminating script${NC}\n"
    exit
fi

while read domain;
do
    printf "${Y}========== $domain ==========${NC}\n"
    # create folder for backup
    `mkdir -p "$BACKUP_PATH""$domain"`

    # get distribution lists
    printf "${Y}distribution lists${NC}\n"
    `touch "$BACKUP_PATH""$domain"/distribution_lists.txt`
    zmprov gadl "$domain" | while read dl
    do
        printf "listing $dl"
        `zmprov gdlm "$dl" >> "$BACKUP_PATH""$domain"/distribution_lists.txt`
        printf "  ${G}[DONE]${NC}"
        if [ "$DELETE_ACCOUNT" = true ]; then
            printf "  deleting distribution list: $dl"
            `zmprov ddl "$dl"`
            printf "  ${G}[DELETED]"
        fi
        printf "  ${NC}\n"
    done

    printf "${Y}Creating account backups${NC}\n"
    # loop accounts, create targz
    zmprov -l gaa "$domain" | while read account
    do
        IFS='@' read -r -a array <<< "$account"
        account=${array[0]}"@""$domain"

        # get aliases
        printf "listing ""$account"" aliases"
        `zmprov ga "$account" | grep zimbraMailAlias > tmp_aliases.txt`
        while read alias; do
            alias=${alias#"zimbraMailAlias: "}
            `echo $alias >> "$BACKUP_PATH""$domain"/"$account"_aliases.txt`
        done < tmp_aliases.txt 
        `rm tmp_aliases.txt`
        printf "  ${G}[DONE]${NC}\n"

        printf "creating archive: $domain - $account"
        `zmmailbox -z -m "$account" getRestURL "//?fmt=tgz" > "$BACKUP_PATH""$domain""/""$account"".tar.gz"`
        printf "  ${G}[DONE]${NC}\n"
        if [ "$DELETE_ACCOUNT" = true ]; then
            printf "deleting account: $account"
            `zmprov da "$account"`
            printf "  ${G}[DELETED]${NC}\n"
        fi
    done

    if [ "$DELETE_ACCOUNT" = true ]; then
        printf "deleting postmaster alias"
        `zmprov raa admin@zimbra.different.hu postmaster@"$domain"`
        printf "  ${G}[DELETED]${NC}\n"
        printf "deleting domain: $domain"
        `zmprov dd "$domain"`
        printf "  ${G}[DELETED]${NC}\n"
    fi

    # tar domain dir
    printf "creating archive file for ""$domain"
    `cd "$BACKUP_PATH""$domain" && tar -zcf "$BACKUP_PATH""$domain"".tar.gz" . && cd "$BASE_PATH"`
    printf "  ${G}[DONE]${NC}\n"

    # remove account files
    printf "${Y}removing account backup files${NC}\n"
    ls "$BACKUP_PATH""$domain" | while read account
    do
        printf "deleting ""$BACKUP_PATH""$domain"/"$account"
        `rm "$BACKUP_PATH""$domain""/""$account"`
        printf "  ${G}[DELETED]${NC}\n"
    done
    printf "deleting ""$BACKUP_PATH""$domain"
    `rmdir "$BACKUP_PATH""$domain"`
    printf "  ${G}[DELETED]${NC}\n"

	if [ "$RSYNC" = true ]; then
        # rsync tar to new zimbra
        printf "${Y}rsync ""$domain${NC}"
        `"$WHICH_RSYNC" --remove-source-files -e ssh "$BACKUP_PATH""$domain".tar.gz "$REMOTE_USER"@"$REMOTE_SERVER":"$REMOTE_PATH"`
        printf "  ${G}[DONE]${NC}\n"
    fi

done <"$SOURCE_FILE"

if [ "$FROM_DEDICATED_SOURCE" = false ];then
    `rm "$SOURCE_FILE"`
fi
printf "${Y}script finished${NC}\n"
