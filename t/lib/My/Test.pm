package My::Test;

# ABSTRACT: Utilities for testing Statocles Tests

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    sub {
        # Disable spurious warnings on platforms that Net::DNS::Native does not
        # support. We don't use this much mojo
        $ENV{MOJO_NO_NDN} = 1;
        return;
    },
    strict => [],
    warnings => [],
    feature => [qw( :5.10 )],
    'Path::Tiny' => [qw( rootdir cwd )],
    'DateTime::Moonpig',
    'Statocles',
    qw( Test::More Test::Deep Test::Differences Test::Exception ),
    'Dir::Self' => [qw( __DIR__ )],
    'Path::Tiny' => [qw( path tempdir cwd )],
    'Statocles::Test' => [qw(
      test_constructor test_pages build_test_site build_test_site_apps
      build_temp_site
    )],
    'Statocles::Types' => [qw( DateTimeObj )],
    sub { $Statocles::VERSION ||= 0.001; return }, # Set version normally done via dzil
);


1;

