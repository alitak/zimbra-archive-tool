# zimbra-archive-tool
Zimbra mailing system domain/account archive tool

For archiving unused domains. We had a lot of domains, accounts, which were unused on our server. This script lists distribution lists, accounts for domain and archives is. Also can delete accounts and domain.

Usage:
chmod +x backup_script.sh
./backup_script.sh [-h] [-d] [-s] [-f path]
-h	help, lists usage options
-d	delete, after creating archive, deletes account
-s	sync, on the end of the script will rsync to given place archives
-f	file, work from given file, otherwise will list domains from zimbra

Before run, set variables in .env (see: .env.example)

## Feel free to expand, update this script.
Contact me at a[at]diff.hu
