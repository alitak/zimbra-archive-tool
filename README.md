# zimbra-archive-tool
Zimbra mailing system domain/account archive tool

For archiving unused domains. We had a lot of domains, accounts, which were unused on our serveer. This script lists distribution lists, account for domain and archives is. Also will delete accounts and domain.

Usage:
chmod +x backup_script.sh
./backup_script.sh [domains.txt OPTIONAL]

If you determine a file with list of domains (see: domains.txt.example), the script will archive only given domains. Otherwise will archive all domains from server.

Before run, set variables in .env (see: .env.example)

## Feel free to expand, update this script.
Contact me at a[at]diff.hu
