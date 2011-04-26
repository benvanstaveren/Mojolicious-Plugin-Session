#!perl -T
use Test::More tests => 1;
use_ok('Mojolicious::Plugin::Session::Dummy') || BAIL_OUT('Mojolicious::Plugin::Session::Dummy has syntax errors');
