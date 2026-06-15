# NAME

Mojolicious::Plugin::Fondation::Devel - Development tools for Fondation — plugin registry browser

# VERSION

version 0.01

# SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Devel',
        ],
    };

# DESCRIPTION

[Mojolicious::Plugin::Fondation::Devel](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ADevel) provides development-time
introspection tools for Fondation applications. It exposes the plugin
registry via a web interface, showing loaded plugins, their configuration,
templates, controllers, assets, and DBIC components.

All routes are restricted to `development` mode only.

# ROUTES

- GET /fondation/registry

    Renders a dashboard showing every loaded plugin in load order, with details
    about shared resources (templates, controllers, assets), DBIC components,
    fixtures, and the full merged configuration for each plugin.

# DEPENDENCIES

This plugin depends on [Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation) for access to the
plugin registry.

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),
[Mojolicious::Plugin::Fondation::API](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAPI),
[Mojolicious::Plugin::Fondation::Manager](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AManager)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
