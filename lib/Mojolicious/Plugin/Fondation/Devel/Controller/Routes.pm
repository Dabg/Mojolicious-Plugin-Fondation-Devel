package Mojolicious::Plugin::Fondation::Devel::Controller::Routes;

# ABSTRACT: Development endpoint listing all routes with their protection status

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw(decode_json);
use Mojo::File 'path';

sub routes ($c) {

    # ─── Gather CSRF config if the plugin is loaded ────────────────────────────

    my $csrf_config;
    my $manager = $c->app->manager;
    if ($manager) {
        my $registry = $manager->registry;
        if (my $csrf = $registry->{'Mojolicious::Plugin::Fondation::CSRF'}) {
            $csrf_config = $csrf->{config};
        }
    }

    # ─── Walk the route tree ──────────────────────────────────────────────────

    my @all_routes;
    _walk($c->app->routes, '', \@all_routes, $csrf_config);

    $c->stash(
        title  => 'Fondation Routes',
        routes => \@all_routes,
    );
    $c->render(template => 'devel/routes');
}

# ---------------------------------------------------------------------------
# Recursively walk the route tree, collecting terminal routes
# ---------------------------------------------------------------------------

sub _walk ($route, $prefix, $collect, $csrf_config) {
    my $pattern = '';
    if ($route->pattern && !$route->pattern->unparsed) {
        # Intermediate node (under/over) — skip, walk children only
        for my $child (@{$route->children}) {
            _walk($child, $prefix, $collect, $csrf_config);
        }
        return;
    }

    if ($route->pattern) {
        $pattern = $route->pattern->unparsed // '';
    }

    my $full_path = $prefix . $pattern;

    # Only collect terminal routes (those with methods or a defined action)
    my $methods = $route->methods || [];
    if (@$methods || _has_action($route)) {
        my $type = _detect_type($route);

        push @$collect, {
            path         => $full_path || '/',
            methods      => [sort @$methods],
            type         => $type,
            protection   => _extract_protection($route),
            csrf         => _csrf_status($route, $full_path, $csrf_config),
        };
    }

    # Recurse into children
    for my $child (@{$route->children}) {
        _walk($child, $full_path, $collect, $csrf_config);
    }
}

# ---------------------------------------------------------------------------
# Check if a route has a real action (controller or callback)
# ---------------------------------------------------------------------------

sub _has_action ($route) {
    my $to = $route->to;
    return 0 unless $to && ref $to eq 'HASH';
    return 1 if $to->{cb};
    return 1 if $to->{controller} || $to->{action};
    return 0;
}

# ---------------------------------------------------------------------------
# Detect route type: html or api
# ---------------------------------------------------------------------------

sub _detect_type ($route) {
    my $defaults = $route->pattern->defaults;
    return 'api' if $defaults->{'openapi.path'};
    return 'api' if $defaults->{'openapi.default_options'};

    # OPTIONS routes added by OpenAPI CORS don't have openapi.path
    # but live under the API base path
    my $path = '';
    if ($route->pattern) {
        $path = $route->pattern->unparsed // '';
    }
    return 'api' if $path =~ m{^/api/};

    return 'html';
}

# ---------------------------------------------------------------------------
# Extract protection from route conditions
# ---------------------------------------------------------------------------

sub _extract_protection ($route) {
    my $requires = $route->requires || [];
    my %seen;
    my @perms;
    my @groups;
    my $authenticated;       # undef = not set, 0 = !auth, 1 = auth required

    for (my $i = 0; $i < @$requires; $i++) {
        my $cond = $requires->[$i];
        if ($cond eq 'fondation.perm') {
            my $value = $requires->[$i + 1];
            push @perms, $value if defined $value && !$seen{"perm:$value"}++;
        }
        elsif ($cond eq 'fondation.group') {
            my $value = $requires->[$i + 1];
            push @groups, $value if defined $value && !$seen{"group:$value"}++;
        }
        elsif ($cond eq 'fondation.authenticated') {
            my $value = $requires->[$i + 1];
            $authenticated = $value ? 1 : 0;
        }
    }

    return {
        perms         => \@perms,
        groups        => \@groups,
        authenticated => $authenticated,
        has_auth      => (defined $authenticated || @perms || @groups) ? 1 : 0,
    };
}

# ---------------------------------------------------------------------------
# Determine CSRF protection status for a route
# ---------------------------------------------------------------------------

sub _csrf_status ($route, $full_path, $csrf_config) {
    my $requires = $route->requires || [];

    # 1. Explicit condition on the route
    for (my $i = 0; $i < @$requires; $i++) {
        if ($requires->[$i] eq 'fondation.csrf') {
            return 'explicit';
        }
    }

    # 2. No CSRF plugin loaded — nothing to report
    return undef unless $csrf_config;

    # 3. Check methods: blanket only applies to mutating methods
    my $methods = $route->methods || [];
    my @mutating = grep { /^(POST|PUT|PATCH|DELETE)$/i } @$methods;

    # Routes with no explicit methods could match anything,
    # but without specific POST/PUT/PATCH/DELETE there's nothing to report
    return 'safe' unless @mutating;

    # 4. Blanket auto_protect
    if ($csrf_config->{auto_protect}) {
        my $exemptions = $csrf_config->{exemptions} // [];
        for my $pattern (@$exemptions) {
            if ($full_path =~ $pattern) {
                return 'exempt';
            }
        }
        return 'blanket';
    }

    # 5. auto_protect disabled, no explicit condition
    return 'disabled';
}

1;
