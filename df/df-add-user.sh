#!/usr/bin/expect

#exp_internal 1

spawn php artisan dreamfactory:setup

sleep 1
expect " > "
send "$::env(DF_USER_FN)\r"

sleep 1
expect " > "
send "$::env(DF_USER_LN)\r"

sleep 1
expect " > "
send "$::env(DF_USER)\r"

sleep 1
expect " > "
send "$::env(DF_USER_EMAIL)\r"

sleep 1
expect " > "
send "$::env(DF_USER_PWD)\r"

sleep 1
expect " > "
send "$::env(DF_USER_PWD)\r"

expect
