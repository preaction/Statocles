use Test::Lib;
use My::Test;
use Statocles::App::Perldoc;

BEGIN {
    eval { require Syntax::Highlight::Engine::Kate; 1 } or plan skip_all => 'Syntax::Highlight::Engine::Kate needed';
};

use Statocles::Plugin::Highlight;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
diag $SHARE_DIR;
my $site = build_test_site(
    theme   => $SHARE_DIR->child( 'theme' ),
    plugins => {
      highlight => Statocles::Plugin::Highlight->new(style => 'solarized-dark')
    },
);

subtest 'syntax highlighting' => sub {
    my $app = Statocles::App::Perldoc->new(
        url_root => '/pod',
        inc => [
            $SHARE_DIR->child( qw( app perldoc lib ) ),
            $SHARE_DIR->child( qw( app perldoc bin ) ),
        ],
        modules => [qw( My My:: )],
        index_module => 'My::Internal',
        site => $site,
        data => {
            info => 'This is the app info',
        },
    );

    test_pages(
        $site, $app,
        '/pod/index.html' => sub {
            my ($html, $dom) = @_;
            ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
              'stylesheet included';
            is $dom->find('code[class=hljs]')->size, 1, 'dom query';
        },
        '/pod/My/Internal/source.html' => sub {
            my ($html, $dom) = @_;
            is $dom->find('pre')->size, 1, 'dom query';
            ok +(grep {$_->content =~ m/^package/ } $dom->find('pre')->each),
              'package...' or diag $dom;
            ok +(grep {$_->content =~ m/My::Internal/ } $dom->find('pre')->each),
              'My::Internal';

            #ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
            #  'stylesheet included';
            #is $dom->find('code[class=hljs]')->size, 1, 'dom query';
            #is $dom->find('span[class=hljs-keyword]')->size, 2, 'dom query';
        },
        '/pod/My/index.html' => sub {
            my ($html, $dom) = @_;
            ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
              'stylesheet included';
            is $dom->find('code[class=hljs]')->size, 1, 'dom query';
            is $dom->find('span[class=hljs-type]')->size, 3, 'dom query';
        },
        '/pod/My/source.html' => sub {
            my ($html, $dom) = @_;
            is $dom->find('pre')->size, 1, 'dom query';
            ok +(grep {$_->content =~ m/^package/} $dom->find('pre')->each),
              'package...';

            #ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
            #  'stylesheet included';
            #is $dom->find('code[class=hljs]')->size, 1, 'dom query';
            #is $dom->find('span[class=hljs-keyword]')->size, 2, 'dom query';
        },
        )
};

done_testing;
