#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/../lib";

# ─── Create app with Fondation + CSRF + Devel ──────────────────────────────────

use Mojolicious::Lite;

app->mode('development');
app->log->level('error');

plugin 'Fondation' => {
    dependencies => [
        { 'Fondation::CSRF' => {
            auto_protect => 1,
            exemptions   => [qr{^/webhook/}],
        }},
        'Fondation::Devel',
    ],
};

my $t   = Test::Mojo->new;
my $app = $t->app;

# ─── Add test routes ───────────────────────────────────────────────────────────

$app->routes->post('/form-submit')->to(cb => sub { shift->render(text => 'ok') });

$app->routes->post('/secure-action')
    ->requires('fondation.csrf')
    ->to(cb => sub { shift->render(text => 'ok') });

$app->routes->get('/safe-page')->to(cb => sub { shift->render(text => 'ok') });

$app->routes->post('/webhook/stripe')->to(cb => sub { shift->render(text => 'ok') });

$app->routes->any('/mixed-protected')
    ->requires('fondation.csrf')
    ->to(cb => sub { shift->render(text => 'ok') });

# Regenerate UA to pick up new routes
$t = Test::Mojo->new($app);

# ─── 1. Page loads ─────────────────────────────────────────────────────────────

$t->get_ok('/fondation/routes')
  ->status_is(200, '/fondation/routes returns 200');

$t->content_like(qr/Fondation Routes/,  'page title found');
$t->content_like(qr{/fondation/routes}, 'own route listed');
$t->content_like(qr{/fondation/registry}, 'registry route listed');

# ─── 2. Auth protection (group) ────────────────────────────────────────────────

$t->content_like(qr{group:\s*admin}, '/fondation/routes requires group admin');

# ─── 3. Explicit CSRF (route condition) ────────────────────────────────────────

my $body = $t->tx->res->body;

$t->content_like(qr{/secure-action}, '/secure-action listed');
like($body, qr{secure-action.*?CSRF<}s, 'explicit CSRF badge (no suffix)');

$t->content_like(qr{/mixed-protected}, '/mixed-protected listed');
like($body, qr{mixed-protected.*?CSRF<}s, 'mixed-protected explicit CSRF badge');

# ─── 4. Blanket CSRF (auto_protect=1, POST, no exemption) ──────────────────────

$t->content_like(qr{/form-submit}, '/form-submit listed');
like($body, qr{form-submit.*?CSRF:\s*blanket}s, 'blanket CSRF badge');

# ─── 5. Exempt CSRF (POST matching exemption pattern) ──────────────────────────

$t->content_like(qr{/webhook/stripe}, '/webhook/stripe listed');
like($body, qr{webhook/stripe.*?CSRF:\s*exempt}s, 'CSRF exempt badge');

# ─── 6. Safe GET route — no CSRF badge in its row ──────────────────────────────

$t->content_like(qr{/safe-page}, '/safe-page listed');
# The safe-page row shows "public" — ensure CSRF badge is NOT within 300 chars after /safe-page
unlike(substr($body, index($body, '/safe-page'), 300), qr/CSRF/,
    'safe GET route has no CSRF badge');

# ─── 7. Perm and group protection still works ──────────────────────────────────

$app->routes->get('/admin')->requires('fondation.perm' => 'admin_view')->to(cb => sub {
    shift->render(text => 'admin');
});
$app->routes->get('/members')->requires('fondation.group' => 'members')->to(cb => sub {
    shift->render(text => 'members');
});

$t = Test::Mojo->new($app);
$t->get_ok('/fondation/routes')->status_is(200);

$t->content_like(qr{/admin},             '/admin route listed');
$t->content_like(qr{perm:\s*admin_view}, 'perm: admin_view shown');
$t->content_like(qr{/members},           '/members route listed');
$t->content_like(qr{group:\s*members},   'group: members shown');

# ─── 8. Production mode → 404 ──────────────────────────────────────────────────

my $app_prod = Mojolicious->new;
$app_prod->mode('production');
$app_prod->log->level('error');
$app_prod->plugin('Fondation' => {
    dependencies => ['Fondation::Devel'],
});

my $t_prod = Test::Mojo->new($app_prod);
$t_prod->get_ok('/fondation/routes')
  ->status_is(404, '/fondation/routes returns 404 in production');

done_testing;
