use utf8;
use Test::Lib;
use My::Test;
use Path::Tiny  'path';
use Statocles::Document;
my $SHARE_DIR = path( __DIR__, 'share' );

my %default = ();

subtest 'status' => sub {
    my $doc = Statocles::Document->new(
        %default,
    );

    is $doc->status => 'published';

};

subtest 'images' => sub {
    my $doc = Statocles::Document->new(
        %default,
        images => {
            title => {
                src => '/image.jpg',
                alt => 'Title image',
            },
            banner => 'banner.jpg',
        },
    );

    my $img = $doc->images( 'title' );
    isa_ok $img, 'Statocles::Image';
    is $img->src => '/image.jpg';
    is $img->alt => 'Title image';

    $img = $doc->images( 'banner' );
    isa_ok $img, 'Statocles::Image';
    is $img->src, 'banner.jpg';

};

subtest 'author' => sub {

    subtest 'coerce from string' => sub {
        my $doc = Statocles::Document->new(
            author => 'Doug Bell <doug@example.com>',
        );
        isa_ok $doc->author, 'Statocles::Person', 'author isa Person object';
        is $doc->author->name, 'Doug Bell', 'author name is correct';
        is $doc->author->email, 'doug@example.com', 'author email is correct';
        is $doc->author."", 'Doug Bell', 'author stringification is correct';
    };
};

subtest 'parse_content' => sub {
    my $path = $SHARE_DIR->child( qw( store docs required.markdown ) );
    cmp_deeply
        +Statocles::Document->parse_content(
            path => $path.'',
            content => $path->slurp_utf8,
        ),
        methods(
            title => 'Required Document',
            content => "No optional things in here, at all!\n",
        );

    subtest 'does not warn without more than one line' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        cmp_deeply
            +Statocles::Document->parse_content(
                content => 'only one line',
            ),
            methods(
                content => "only one line\n",
            );
        ok !@warnings, 'no warnings' or diag explain \@warnings;
    };

    subtest 'does not warn with only a newline' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        cmp_deeply
            +Statocles::Document->parse_content(
                content => "\n",
            ),
            methods(
                content => "",
            );
        ok !@warnings, 'no warnings' or diag explain \@warnings;
    };
    subtest 'UTF-8 front matter ' => sub {
        is +Statocles::Document->parse_content(
          content => path('t/share/store/docs/utf8-json.md')->slurp_utf8(),
        )->title, 'Zero » One Hundred', 'json front matter parsed ok';
        is +Statocles::Document->parse_content(
          content => path('t/share/store/docs/utf8-yml.md')->slurp_utf8(),
        )->title, 'Zero » One Hundred', 'yaml front matter parsed ok';
    };
};

done_testing;
