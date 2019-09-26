#!/bin/bash

R='\033[0;31m' # red
Y='\033[0;33m' # yellow
G='\033[0;32m' # green
NC='\033[0m' # No Color

# contants from .env file
if [ -f .env ]; then
    export $(egrep -v '^#' .env | xargs)
fi
BASE_PATH=`pwd`

if [ "$RESTORE_PATH" == "" ]; then
    printf "${R}RESTORE_PATH must set in env!\nTerminating${NC}\n"
    exit
fi

printf "${Y}Account restoring script\n${NC}"

for file in "$RESTORE_PATH"*.tar.gz; do
    # get domain name
    file_name="${file/$RESTORE_PATH/}"
    domain="${file_name/.tar.gz/}"
    domain_path="$RESTORE_PATH""$domain""/"
    printf "${Y}========== $domain ==========${NC}\n"

    # unpack archive file
    printf "unpacking $file_name"
    mkdir $domain_path
    tar zxf $file -C $domain_path
    printf "  ${G}[DONE]${NC}\n"

    # create domain
    printf "creating domain $domain"
    zmprov cd "$domain" > /dev/null
    printf "  ${G}[DONE]${NC}\n"

    # create distribution lists
    printf "creating distribution lists for $domain\n"

    for file in "$RESTORE_PATH""$domain"/distribution_lists*; do
        distribution_list_tmp=${file/"$RESTORE_PATH""$domain""/distribution_lists_"/}
        distribution_list=${distribution_list_tmp/.txt/}
        printf "creating distribution list $distribution_list"
        zmprov cdl $distribution_list >> /dev/null
        members=""
        while read email; do
            members=$members" "$email
        done < $file
        zmprov adlm $distribution_list $members
        printf "  ${G}[DONE]${NC}\n"
    done
    printf "creating distribution lists for $domain  ${G}[DONE]${NC}\n"

    # list account tar.gz files
    for account_file in "$domain_path"*.tar.gz; do
        account_file_name="${account_file/$domain_path/}"
        account="${account_file_name/.tar.gz/}"
        printf "${Y}===== $account ====${NC}\n"

        # create account
        printf "creating account $account"
        zmprov ca $account "$TEMP_PW" > /dev/null
        printf "  ${G}[DONE]${NC}\n"

        # import mail data
        printf "importing mail data to $account"
        account_file_escaped="${account_file/@/\\@}"
        zmmailbox -z -m $account -t 0 postRestURL "//?fmt=tgz&resolve=reset" $account_file
        printf "  ${G}[DONE]${NC}\n"

        # set configs
        printf "restoring configs\n"
        configs=""
        while read config; do
            zmprov ma $account `printf "$config" | cut -d' ' -f1` "`printf "$config" | cut -d' ' -f2-`"
        done < $RESTORE_PATH$domain/$account""_configs.txt
        printf "restoring configs  ${G}[DONE]${NC}\n"

        # add alias
        printf "creating aliases for $account\n"
        while read alias; do
            printf "creating $alias"
            zmprov aaa $account $alias
            printf "  ${G}[DONE]${NC}\n"
        done <"$RESTORE_PATH$domain/$account""_aliases.txt"
        printf "creating aliases for $account  ${G}[DONE]${NC}\n"
    done

    # remove temp files
    `rm -rf $domain_path`
done

printf "${Y}script finished${NC}\n"
