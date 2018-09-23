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
        modules => [qw( My My:: Highlight)],
        index_module => 'My::Internal',
        site => $site,
        data => {
            info => 'This is the app info',
        },
    );

    $site->apps->{perldoc} = $app;

    test_page_objects(
        [ $site->pages ],
        # Highlight.pm has no code in SYNOPSIS or elsewhere - should have no
        # reference to highlight classes
        '/pod/Highlight/index.html' => sub {
            my ( $page ) = @_;
            my $dom = $page->dom;
            my $html = $dom.'';
            is +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
              0, 'no stylesheet included';
            is $dom->find('code[class=hljs]')->size, 0, 'dom query' or diag $dom;
            is +($html =~ s/DOCTYPE/DOCTYPE/g), 1, 'no duplication';
        },
        '/pod/Highlight/source.html' => sub {
            my ( $page ) = @_;
            my $dom = $page->dom;
            my $html = $dom.'';
            is $dom->find('pre')->size, 1, 'dom query for pre in source';
            ok +(grep {$_->content =~ m/^package/ } $dom->find('pre')->each),
              'package...' or diag $dom;
            ok +(grep {$_->content =~ m/Highlight/ } $dom->find('pre')->each),
              'Highlight' or diag $dom;
            is +($html =~ s/DOCTYPE/DOCTYPE/g), 1, 'no duplication';
        },
        '/pod/index.html' => sub {
            my ( $page ) = @_;
            my $dom = $page->dom;
            my $html = $dom.'';
            ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
              'stylesheet included';
            is $dom->find('code[class=hljs]')->size, 1,
              'dom query for highlight class on code tag';
            is +($html =~ s/DOCTYPE/DOCTYPE/g), 1, 'no duplication';
        },
        '/pod/My/Internal/source.html' => sub {
            my ( $page ) = @_;
            my $dom = $page->dom;
            my $html = $dom.'';
            is $dom->find('pre')->size, 1, 'dom query';
            ok +(grep {$_->content =~ m/^package/ } $dom->find('pre')->each),
              'package...' or diag $dom;
            ok +(grep {$_->content =~ m/My::Internal/ } $dom->find('pre')->each),
              'My::Internal';
            is +($html =~ s/DOCTYPE/DOCTYPE/g), 1, 'no duplication';
            #ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
            #  'stylesheet included';
            #is $dom->find('code[class=hljs]')->size, 1, 'dom query';
            #is $dom->find('span[class=hljs-keyword]')->size, 2, 'dom query';
        },
        '/pod/My/index.html' => sub {
            my ( $page ) = @_;
            my $dom = $page->dom;
            my $html = $dom.'';
            ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
              'stylesheet included';
            is $dom->find('code[class=hljs]')->size, 1,
              'dom query for highlight class on code tag';
            is $dom->find('span[class=hljs-type]')->size, 3,
              'dom query for highlight class on span tag';
            is +($html =~ s/DOCTYPE/DOCTYPE/g), 1, 'no duplication';
        },
        '/pod/My/source.html' => sub {
            my ( $page ) = @_;
            my $dom = $page->dom;
            my $html = $dom.'';
            is $dom->find('pre')->size, 1, 'dom query';
            ok +(grep {$_->content =~ m/^package/} $dom->find('pre')->each),
              'package...';
            is +($html =~ s/DOCTYPE/DOCTYPE/g), 1, 'no duplication';
            #ok +(grep { $_->attr('href') =~ m/solarized/ } $dom->find('link[rel=stylesheet]')->each),
            #  'stylesheet included';
            #is $dom->find('code[class=hljs]')->size, 1, 'dom query';
            #is $dom->find('span[class=hljs-keyword]')->size, 2, 'dom query';
        },
    )
};

done_testing;
