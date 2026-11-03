#!/usr/bin/env perl
use strict;
use warnings;

# Opt in to a sibling WWW::Zitadel checkout with
#   PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB=/path/to/p5-www-zitadel/lib
# Without it the suite runs against the installed WWW::Zitadel only.
use if $ENV{PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB},
    lib => $ENV{PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB};

use Test::More;

use_ok('Plack::Middleware::Zitadel');

SKIP: {
    skip 'sibling checkout requested explicitly', 1
        if $ENV{PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB};
    ok !( grep { m{/p5-www-zitadel/lib\z} } @INC ),
        'no sibling checkout on @INC unless asked for';
}

done_testing;
