requires 'JSON::MaybeXS';
requires 'Plack';
requires 'WWW::Zitadel';

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'Plack::Test';
    requires 'Test::More';
};
