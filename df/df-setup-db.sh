#!/usr/bin/expect

#exp_internal 1

spawn php artisan dreamfactory:setup

sleep 1

expect " > "

send -- "\r"

expect
