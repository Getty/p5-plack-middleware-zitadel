use strict;
use warnings;

use if $ENV{PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB},
    lib => $ENV{PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB};

use Test::More;
use HTTP::Request::Common qw(GET);
use Plack::Test;

# The usage examples are the first thing a user copies; they have to run as
# written.  README.md is not part of the built distribution (dzil generates a
# plain README), so under `dzil test` only the SYNOPSIS is exercised.

sub slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "$file: $!\n";
    return do { local $/; <$fh> };
}

my $pod = slurp('lib/Plack/Middleware/Zitadel.pm');

sub check_example {
    my ($label, $code) = @_;

    ok defined $code, "$label: code block found" or return;

    like $code, qr/enable\s+'Plack::Middleware::Zitadel',/,
        "$label: enables the existing class";

    my $wrapped = eval "package Local::Example; no strict 'vars'; $code; \$wrapped";
    is $@, '', "$label: builds" or diag $code;
    is ref $wrapped, 'CODE', "$label: yields a PSGI app" or return;

    test_psgi $wrapped, sub {
        my ($cb) = @_;
        my $res = $cb->(GET 'http://localhost/');
        is $res->code, 401, "$label: answers 401 without a token";
        like $res->header('WWW-Authenticate'), qr/^Bearer realm="api"/,
            "$label: carries the Bearer challenge";
    };

    # Every attribute the example passes is documented in the POD.
    my ($enable) = $code =~ /enable\s+'[^']+',(.*?);/s;
    my @attrs = $enable =~ /(\w+)\s*=>/g;
    is_deeply [ sort @attrs ], [qw( audience issuer required_scopes )],
        "$label: uses issuer, audience and required_scopes";
    like $pod, qr/^=head2 \Q$_\E$/m, "$label: attribute $_ is documented"
        for @attrs;
}

my ($synopsis) = $pod =~ /^=head1 SYNOPSIS\n\n(.*?)^=head1/ms;
check_example('SYNOPSIS', $synopsis);

SKIP: {
    skip 'README.md is not in the built distribution', 1 unless -f 'README.md';

    my ($code) = slurp('README.md') =~ /^## Usage\s+```perl\n(.*?)^```/ms;
    subtest 'README.md Usage' => sub { check_example('README', $code); done_testing };
}

done_testing;
