Based on https://github.com/dreamfactorysoftware/df-docker

```docker run -it --name=df -p 80:80 --add-host=oai.postgres.lo:<IP> df```

http://localhost/

Login: admin@example.com:dreamAdmin

```php artisan dreamfactory:import-pkg /tmp/oai-app.zip```

A new version of oai-app.zip can be created by POSTing fetch-package.json to the package service in the admin UI.
