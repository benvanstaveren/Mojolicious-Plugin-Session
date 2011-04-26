#!perl -T
use Test::More tests => 1;
use_ok('Mojolicious::Plugin::Session') || BAIL_OUT('Mojolicious::Plugin::Session has syntax errors');
