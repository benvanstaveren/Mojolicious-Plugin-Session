#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;
plan tests => 9;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'session', {
    backend    => 'mongodb',
    database   => 'mps_test',
    collection => 'session',
};

get '/' => sub {
    my $self = shift;
    $self->render(text => 'index page');
};

get '/putsession/:key/:value' => sub {
    my $self = shift;
    my $key  = $self->stash('key');
    my $value= $self->stash('value');
    $self->session->{$key} = $value;
    $self->render(text => 'ok');
};

get '/sessionkey' => sub {
    my $self = shift;
    $self->render(text => $self->session->{session_key});
};

get '/getsession/:key' => sub {
    my $self = shift;
    my $key  = $self->stash('key');
    $self->render(text => $self->session->{$key});
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_is('index page');
$t->get_ok('/putsession/test/foobar')->status_is(200)->content_is('ok');
$t->get_ok('/getsession/test')->status_is(200)->content_is('foobar');
