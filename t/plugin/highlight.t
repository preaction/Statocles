
use Test::Lib;
use My::Test;

BEGIN {
    eval { require Syntax::Highlight::Engine::Kate; 1 } or plan skip_all => 'Syntax::Highlight::Engine::Kate needed';
};

use Statocles::Plugin::Highlight;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

# The given perl should contain all the HTML characters that need
# escaping, like '<', '>', and '&'
my $given_perl = <<'ENDPERL';
sub foo {
    my ( $self, @args ) = @_;
    return grep { $_ < 1 && $_ > -1 } @args;
}

print foo( 1 + 2, 4 . 5 );
ENDPERL

my $expect_perl = <<'ENDHTML';
<pre><code class="hljs"><span class="hljs-keyword">sub </span><span class="hljs-function">foo</span> {
    <span class="hljs-keyword">my</span> ( <span class="hljs-type">$self</span>, <span class="hljs-type">@args</span> ) = <span class="hljs-type">@_</span>;
    <span class="hljs-keyword">return</span> <span class="hljs-function">grep</span> { <span class="hljs-variable">$_</span> &lt; <span class="hljs-number">1</span> &amp;&amp; <span class="hljs-variable">$_</span> &gt; <span class="hljs-number">-1</span> } <span class="hljs-type">@args</span>;
}

<span class="hljs-function">print</span> foo( <span class="hljs-number">1</span> + <span class="hljs-number">2</span>, 4 . <span class="hljs-number">5</span> );
</code></pre>
ENDHTML
chomp $expect_perl;

subtest 'highlight' => sub {

    subtest 'highlight anything' => sub {
        my $plugin = Statocles::Plugin::Highlight->new;

        my $got_perl = $plugin->highlight( { }, Perl => $given_perl );
        eq_or_diff $got_perl, $expect_perl;

    };

    subtest 'page gets stylesheet added' => sub {
        my $plugin = Statocles::Plugin::Highlight->new(
            style => 'solarized-dark',
        );

        my $site = build_test_site();
        my $page = Statocles::Page::Plain->new(
            path => 'test.html',
            site => $site,
            content => '',
        );
        my $style_url = $site->theme->url( '/plugin/highlight/solarized-dark.css' );

        my $got_perl = $plugin->highlight( { page => $page }, Perl => $given_perl );
        eq_or_diff $got_perl, $expect_perl;
        is scalar grep( { $_->href eq $style_url } $page->links( 'stylesheet' ) ), 1,
            'correct stylesheet is added to the page';
    };

};

subtest 'register' => sub {

    my $plugin = Statocles::Plugin::Highlight->new;
    my $site = build_test_site(
        plugins => {
            highlight => $plugin,
        }
    );

    my $tmpl = $site->theme->build_template(
        test => '<%= highlight Perl => "print q{hello}" %>',
    );
    eq_or_diff $tmpl->render,
        qq{<pre><code class="hljs"><span class="hljs-function">print</span> q{<span class="hljs-string">hello</span>}</code></pre>\n},
        'highlight sub works in template';
};

subtest 'test helper interaction' => sub {

    subtest 'begin/end' => sub {
        my $plugin = Statocles::Plugin::Highlight->new;

        my $site = build_test_site(
            theme => $SHARE_DIR->child( 'theme' ),
            plugins => {
                highlight => $plugin,
            }
        );

        my $tmpl = $site->theme->build_template(
            test => <<ENDTMPL,
<%= highlight html => begin %>
<h1>Title</h1>
<% end %>
ENDTMPL
        );

        eq_or_diff $tmpl->render,
            qq{<pre><code class="hljs"><span class="hljs-keyword">&lt;h1&gt;</span>Title<span class="hljs-keyword">&lt;/h1&gt;</span>\n</code></pre>\n},
            'highlight works with begin/end';

    };

    subtest 'highlight an included file' => sub {
        my $plugin = Statocles::Plugin::Highlight->new;

        my $site = build_test_site(
            theme => $SHARE_DIR->child( 'theme' ),
            plugins => {
                highlight => $plugin,
            }
        );

        my $tmpl = $site->theme->build_template(
            test => '<%= highlight html => include "include/test.markdown.ep" %>',
        );
        eq_or_diff $tmpl->render( title => "Title" ),
            qq{<pre><code class="hljs"><span class="hljs-keyword">&lt;h1&gt;</span>Title<span class="hljs-keyword">&lt;/h1&gt;</span>\n</code></pre>\n},
            'highlight works with include';

    };

};

done_testing;
