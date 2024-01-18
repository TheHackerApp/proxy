# Proxy

The [OpenResty][openresty] API proxy that authenticates and routes requests to the appropriate
backend service.

The root [Nginx][nginx] configuration file is [`nginx.conf`](./nginx.conf) The directories are as
follows:

- `conf`: static Nginx configuration files
- `lua`: Lua modules and entrypoints
- `snippets`: shared Nginx configuration snippets
- `templates`: Nginx configuration files containing environment variables for substitution

Additional startup configuration can be done by adding scripts to the
[`docker-entrypoint.d`](./docker-entrypoint.d) directory. All scripts are executed in lexigraphical
order and must end in either `.sh` or `.envsh`. The latter is a special file type that is sourced
instead of executed.

## Development

All development is done within a Docker container with the configuration files bind mounted into the
container. The [`Justfile`](./Justfile) contains all the commands needed to build, run, and test the
proxy.

Any changes to the Lua modules/entrypoints or static configuration files will require the Nginx
instance to be reloaded. This can be done by running `just reload`. However, any changes to the
static configuration files require a reload, and any changes to the templated configuration files
require the container to be restarted.

### VS Code Configuration

Install the recommended extensions: [Docker][vscode-docker], [Just][vscode-just], [Lua][vscode-lua],
and [MarkdownLint][vscode-markdownlint].

Once installed, launch the Lua addon manager by opening the command palette (`ctrl + shift + p` /
`cmd + shift + p`) and running `Lua: Open Addon Aanager`. Search for the "OpenResty" addon and
install it to enable autocompletion and linting.

## Credits

- [OpenTelemetry Lua][opentelemetry-lua]
- [OpenTelemetry Nginx Module][opentelemetry-nginx]

The [`Dockerfile`](./Dockerfile) and [entrypoint scripts](./docker-entrypoint.d) were based on those
found [official Nginx image][nginx-docker].

The authentication flow was based on the [Authelia Nginx integration][authelia-nginx] and translated
into Lua subrequests.

[authelia-nginx]: https://www.authelia.com/integration/proxies/nginx/
[nginx]: https://nginx.org/
[nginx-docker]: https://github.com/nginxinc/docker-nginx
[openresty]: https://openresty.org/en/
[opentelemetry-lua]: https://github.com/yangxikun/opentelemetry-lua
[opentelemetry-nginx]: https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/nginx
[vscode-docker]: https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker
[vscode-just]: https://marketplace.visualstudio.com/items?itemName=skellock.just
[vscode-lua]: https://marketplace.visualstudio.com/items?itemName=sumneko.lua
[vscode-markdownlint]: https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint
