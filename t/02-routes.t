#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/../lib";

# ─── Create app with Fondation + Devel ────────────────────────────────────────

use Mojolicious::Lite;

app->mode('development');
app->log->level('error');

plugin 'Fondation' => {
    dependencies => ['Fondation::Devel'],
};

my $t = Test::Mojo->new;
my $app = $t->app;

# ─── 1. Route exists ──────────────────────────────────────────────────────────

$t->get_ok('/fondation/routes')
  ->status_is(200, '/fondation/routes returns 200');

# ─── 2. Page content ──────────────────────────────────────────────────────────

$t->content_like(qr/Fondation Routes/,  'page title found');
$t->content_like(qr{/fondation/routes}, 'own route listed');
$t->content_like(qr{/fondation/registry}, 'registry route listed');

# ─── 3. Routes now have group protection ──────────────────────────────────────

$t->content_like(qr{group:\s*admin}, '/fondation/routes requires group admin');

# ─── 4. Add a protected route and check it appears ────────────────────────────

my $r = $app->routes;
$r->get('/admin')->requires('fondation.perm' => 'admin_view')->to(cb => sub {
    shift->render(text => 'admin');
});

# Rebuild the test user-agent to pick up the new route
$t = Test::Mojo->new($app);

$t->get_ok('/fondation/routes')
  ->status_is(200);

$t->content_like(qr{/admin},               '/admin route listed');
$t->content_like(qr{perm:\s*admin_view},   'perm: admin_view shown');

# ─── 5. Group-protected route ─────────────────────────────────────────────────

$r->get('/members')->requires('fondation.group' => 'members')->to(cb => sub {
    shift->render(text => 'members');
});

$t = Test::Mojo->new($app);
$t->get_ok('/fondation/routes')->status_is(200);
$t->content_like(qr{/members},           '/members route listed');
$t->content_like(qr{group:\s*members},   'group: members shown');

# ─── 6. Mode production → 404 ─────────────────────────────────────────────────

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
