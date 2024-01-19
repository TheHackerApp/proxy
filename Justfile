# Show a list of tasks
help:
  @just -lu

# Start the proxy
start *ARGS:
  docker compose up -d --build --force-recreate {{ARGS}}

# Launch an interactive shell
shell:
  docker compose exec -it proxy ash

# Stop the proxy
stop:
  docker compose stop

# Run various linters
check:
  find . -type f -name "*.sh" -exec shellcheck -x {} \;
  luacheck .
  markdownlint-cli2 "**/*.md" "#echo/.venv"
  yamllint -s .

# Get the IP of the proxy container
ip:
  docker inspect -f '{{{{range.NetworkSettings.Networks}}{{{{.IPAddress}}{{{{end}}' proxy-proxy-1

# Show the proxy logs
logs *ARGS:
  docker compose logs proxy {{ARGS}}

# Validate the configuration
test:
  docker compose exec proxy nginx -t

# Reload the configuration
reload: test
  docker compose exec proxy nginx -s reload

# Recreate the proxy
recreate: stop start

alias up := start
alias down := stop

alias c := check
alias d := stop
alias l := logs
alias r := reload
alias s := shell
alias t := test
alias u := start
