#!perl -T
use Test::More tests => 1;
use_ok('Mojolicious::Plugin::Session::Mongodb') || BAIL_OUT('Mojolicious::Plugin::Session::Mongodb has syntax errors');
