use strict;
use warnings;

use Test::More;
use File::Spec;
use Pod::Checker;

my $file = 'lib/Plack/Middleware/Zitadel.pm';

my $checker = Pod::Checker->new( -warnings => 1 );
open my $null, '>', File::Spec->devnull or die "devnull: $!\n";
$checker->parse_from_file( $file, $null );

is $checker->num_errors, 0, 'podchecker finds no errors';
cmp_ok $checker->num_errors, '!=', -1, 'the file contains POD commands';

open my $fh, '<', $file or die "$file: $!\n";
my $source = do { local $/; <$fh> };

for my $heading (qw( SYNOPSIS DESCRIPTION ATTRIBUTES ), 'SEE ALSO') {
    like $source, qr/^=head1 \Q$heading\E$/m, "=head1 $heading present";
}

for my $attr (qw( issuer audience required_scopes claims_env_key realm oidc )) {
    like $source, qr/^=head2 \Q$attr\E$/m, "attribute $attr documented";
}

done_testing;
