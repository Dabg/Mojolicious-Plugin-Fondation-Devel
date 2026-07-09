package Mojolicious::Plugin::Fondation::Devel;

# ABSTRACT: Development tools for Fondation — plugin registry browser

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [ 'Fondation::CSRF'],
        defaults     => {},
    };
}

sub register ($self, $app, $config) {

    if ($app->mode eq 'development') {
        $app->routes->get('/fondation/registry')
            ->requires('fondation.group' => 'admin')
            ->to(
                controller => 'Registry',
                action     => 'registry'
            );
        $app->routes->get('/fondation/routes')
            ->requires('fondation.group' => 'admin')
            ->to(
                controller => 'Routes',
                action     => 'routes'
            );
        $app->routes->get('/fondation/graph')
            ->requires('fondation.group' => 'admin')
            ->to(
                controller => 'Graph',
                action     => 'graph'
            );
    }

    return $self;
}

1;

=encoding UTF-8

=head1 SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Devel',
        ],
    };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Fondation::Devel> provides development-time
introspection tools for Fondation applications. It exposes the plugin
registry and the route table via a web interface.

All routes are restricted to C<development> mode only and require
C<fondation.group =E<gt> 'admin'>.

=head1 ROUTES

=over 4

=item GET /fondation/registry

Renders a dashboard showing every loaded plugin in load order, with details
about shared resources (templates, controllers, assets), DBIC components,
fixtures, and the full merged configuration for each plugin.

=item GET /fondation/routes

Renders a table listing every registered route (HTML and API) with its
HTTP methods, type, and protection status. Protection is extracted from
C<requires('fondation.perm')>, C<requires('fondation.group')>, and
C<requires('fondation.authenticated')> conditions. Routes without any
protection condition are shown as public.

=back

=head1 DEPENDENCIES

This plugin depends on L<Mojolicious::Plugin::Fondation> for access to the
plugin registry.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,
L<Mojolicious::Plugin::Fondation::API>,
L<Mojolicious::Plugin::Fondation::Manager>

=cut
