
use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'get the app list' => sub {
    my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

    my @args = (
        '--config' => "$config_fn",
        'apps',
    );
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    ok !$err, 'nothing on stderr' or diag "STDERR: $err";
    is $exit, 0;
    like $out, qr{blog \(/blog -- Statocles::App::Blog\)\n},
        'contains app name, url root, and app class';
};

subtest 'delegate to app command' => sub {
    my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

    local $ENV{MOJO_LOG_LEVEL} = '';
    local $ENV{EDITOR} = '';
    my @args = (
        '--config' => "$config_fn",
        'blog' => 'post',
        '--date' => '2014-01-01',
        'New post',
    );
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    ok !$err, 'nothing on stderr' or diag "STDERR: $err";
    is $exit, 0;
    like $out, qr{\QNew post at:}, 'contains new post';
    my $post = $tmp->child( qw( blog 2014 01 01 new-post index.markdown ) );
    ok $post->exists, 'correct post file exists';
};

done_testing;
