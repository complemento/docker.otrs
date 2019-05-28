#!/usr/bin/perl
use HTTP::Server::Brick;
use HTTP::Status;

my $server = HTTP::Server::Brick->new( port => 80 );

# these next two are equivalent
$server->mount( '/favicon.ico' => {
    handler => sub { RC_NOT_FOUND },
});

# URL checked when status application is online
$server->mount( '/otrs-web/skins/Agent/default/img/icons/product.ico' => {
    handler => sub { RC_NOT_FOUND },
});

$server->mount( '/' => {
    path => '/var/www/html',
});

$server->mount( '/otrs/' => {
    handler => sub {
        my ($req, $res) = @_;
        $res->add_content('<meta http-equiv="refresh" content="0; URL=/" />');
        1;
    },
    wildcard => 1,
});

# start accepting requests (won't return unless/until process
# receives a HUP signal)
$server->start;
