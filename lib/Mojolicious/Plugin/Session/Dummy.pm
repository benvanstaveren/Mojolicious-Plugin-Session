use strict;
use warnings;
package Mojolicious::Plugin::Session::Dummy;
# ABSTRACT: Dummy storage class for session module
use Mojo::Base 'Mojolicious::Plugin::Session::Base';

has _data => sub { {} };

sub cleanup_data {
    my $self = shift;

    foreach my $k (keys(%{$self->_data})) {
        next if($self->_data->{$k}->{expires} == -1);
        delete($self->_data->{$k}) if($self->_data->{$k}->{expires} < time());
    }
}

sub create_data {
    my $self = shift;
    my %args = (@_);
    my $session = {
        _id     => $args{'key'},
        data    => undef,
        touched => Time::HiRes::time(),
        expires => -1,
        };

    $self->_data->{$args{'key'}} = $session;
    return $args{'key'};
}

sub load_data {
    my $self = shift;
    my %args = (@_);

    return $self->_data->{$args{'key'}}->{data} || {};
}

sub store_data {
    my $self = shift;
    my %args = (
        data => undef,
        expires => -1,
        @_);

    $self->_data->{$args{'key'}}->{data} = $args{'data'};
    $self->_data->{$args{'key'}}->{expires} = $args{'expires'};
}

sub clear_data {
    my $self = shift;
    my %args = (@_);

    delete($self->_data->{$args{'key'}});
}

1;
=pod
=head1 NAME

Mojolicious::Plugin::Session::Dummy - Dummy backend driver

=head1 CONFIGURATION

This driver has no options

=head1 WARNING

Do not use this driver in a production environment. It merrily keeps everything in memory, and is mainly used to illustrate the methods a driver needs to implement, and it's used in the module's tests. Use this at your own risk, YMMV, batteries not included, #include <std_disclaimer.h>, $disclaimer = 'standard', you know the drill.

=head1 BUGS/CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/issues>. 
You can fork my Git repository at L<https://github.com/benvanstaveren/Mojolicious-Plugin-Session/> if you want to make changes or supply me with patches.
=cut
