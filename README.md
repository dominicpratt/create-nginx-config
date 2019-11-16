# create-nginx-config

This is a tiny little bash script to create all the configurations needed for hosting a website with nginx.

It creates:

* nginx Virtual Host (/etc/nginx/sites-available)
* PHP 7.3-FPM-Pool (/etc/php/7.3/fpm/pool.d)
* MySQL-Database
* System-User for SFTP access

## Dependencies

As I'm using this or a similar script on all my servers I've just tested this against software that I use.

* Debian Buster (10)
* Nginx
* PHP 7.3-FPM
* MariaDB
* Bash

Don't forget to create a .my.cnf-File in

```
/root/.my.cnf
```

Else you have to put your MySQL-Credentials directly in the script.

## Installation

The installation is quite easy - just download the script and mark it executable.

```
curl -o /usr/local/bin/create_website https://gitlab.com/dominicpratt/create-nginx-config/raw/master/create_website.sh
chmod +x /usr/local/bin/create_website
```

That's it.

## Usage

If the script is located in the $PATH (e.g. /usr/local/bin) of the system, it is sufficient to simply execute 

```
create_website
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)