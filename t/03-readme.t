use strict;
use warnings;

use if $ENV{PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB},
    lib => $ENV{PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB};

use Test::More;
use HTTP::Request::Common qw(GET);
use Plack::Test;

# The first code block under "## Usage" in README.md is the first thing a
# user copies; it has to run as written.
open my $readme_fh, '<', 'README.md' or die "README.md: $!\n";
my $readme = do { local $/; <$readme_fh> };

my ($code) = $readme =~ /^## Usage\s+```perl\n(.*?)^```/ms;
ok defined $code, 'README has a Usage code block' or BAIL_OUT('no Usage block');

like $code, qr/enable\s+'Plack::Middleware::Zitadel',/,
    'README enables the existing class';

my $wrapped = eval "package Local::Readme; no strict 'vars'; $code; \$wrapped";
is $@, '', 'README example builds' or diag $code;
is ref $wrapped, 'CODE', 'README example yields a PSGI app';

test_psgi $wrapped, sub {
    my ($cb) = @_;
    my $res = $cb->(GET 'http://localhost/');
    is $res->code, 401, 'README app answers 401 without a token';
    like $res->header('WWW-Authenticate'), qr/^Bearer realm="api"/,
        'README app carries the Bearer challenge';
};

# Every attribute the example passes is documented in the POD.
my ($enable) = $code =~ /enable\s+'[^']+',(.*?);/s;
my @attrs = $enable =~ /(\w+)\s*=>/g;
is_deeply [ sort @attrs ], [qw( audience issuer required_scopes )],
    'README example uses issuer, audience and required_scopes';

open my $pm_fh, '<', 'lib/Plack/Middleware/Zitadel.pm' or die "lib: $!\n";
my $pod = do { local $/; <$pm_fh> };
like $pod, qr/^=head2 \Q$_\E$/m, "README attribute $_ is documented"
    for @attrs;

done_testing;
