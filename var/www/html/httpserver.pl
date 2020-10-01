#!/usr/bin/perl
use HTTP::Server::Brick;
use HTTP::Status;

my $server = HTTP::Server::Brick->new( port => 80 );

my $root_path = '/var/www/html';

# these next two are equivalent
$server->mount( '/favicon.ico' => {
    handler => sub { RC_NOT_FOUND },
});

# URL checked when status application is online
$server->mount( '/otrs-web/skins/Agent/default/img/icons/product.ico' => {
    handler => sub { RC_NOT_FOUND },
});

$server->mount( '/' => {
    path => $root_path,
});

$server->mount( '/otrs/' => {
    wildcard => 1,
    handler => sub {
        my ($req, $res) = @_;
        $res->header( 'Content-type', 'text/html' );

        $filename = "$root_path/index.html";        
        open(my $fh, '<:encoding(UTF-8)', $filename)
        or die "Error to open '$filename' $!";
        
        while (my $row = <$fh>) {
            chomp $row;
            $res->add_content("$row\n");
        }
        
        1;
    }
});

# start accepting requests (won't return unless/until process
# receives a HUP signal)
$server->start;
