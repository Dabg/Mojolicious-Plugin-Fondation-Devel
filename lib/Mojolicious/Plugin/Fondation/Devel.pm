package Mojolicious::Plugin::Fondation::Devel;

# ABSTRACT: Development tools for Fondation — plugin registry browser

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => {},
    };
}

sub register ($self, $app, $config) {

    $app->routes->get('/fondation/registry')->to(
        controller => 'Registry',
        action     => 'registry'
    ) if $app->mode eq 'development';

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
registry via a web interface, showing loaded plugins, their configuration,
templates, controllers, assets, and DBIC components.

All routes are restricted to C<development> mode only.

=head1 ROUTES

=over 4

=item GET /fondation/registry

Renders a dashboard showing every loaded plugin in load order, with details
about shared resources (templates, controllers, assets), DBIC components,
fixtures, and the full merged configuration for each plugin.

=back

=head1 DEPENDENCIES

This plugin depends on L<Mojolicious::Plugin::Fondation> for access to the
plugin registry.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,
L<Mojolicious::Plugin::Fondation::API>,
L<Mojolicious::Plugin::Fondation::Manager>

=cut
