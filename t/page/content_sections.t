
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Document;
use Statocles::Page::Document;
use Statocles::Site;
my $site = Statocles::Site->new(
    deploy => tempdir,
    title => 'Test Site',
    theme => $SHARE_DIR->child(qw( theme )),
);

my $doc = Statocles::Document->new(
    path => '/required.markdown',
    title => 'Page Title',
    author => 'preaction',
    tags => [qw( foo bar baz )],
    date => DateTime::Moonpig->new( time - 600 ),
    content => <<'MARKDOWN',
Page content
% content from_document => 'From document';
MARKDOWN
);

subtest 'content sections' => sub {
    my $page = Statocles::Page::Document->new(
        path => '/index.html',
        document => $doc,
        template => <<ENDHTML,
%= content 'from_document';
%= content
% content 'from_template' => 'From template';
ENDHTML

        layout => <<ENDHTML,
%= content 'from_document';
%= content 'from_template';
%= content
ENDHTML
    );

    eq_or_diff $page->render, "From document\nFrom template\nFrom document\n<p>Page content</p>\n\n\n", 'content sections are rendered';

    subtest 'state must be cleared after render because we cache templates' => sub {
        ok !exists $page->template->state->{content}{from_document},
            'template from_document state is cleared';
        ok !exists $page->layout->state->{content}{from_template},
            'layout from_template state is cleared';
        ok !exists $page->layout->state->{content}{from_document},
            'layout from_document state is cleared';
    };
};

done_testing;
