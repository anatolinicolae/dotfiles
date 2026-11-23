# Link Homebrew's Docker CLI plugins where the docker CLI looks for them, as
# Colima's docs describe. Skips plugins whose formula isn't installed, so this
# is a no-op on profiles without them.
prefix=$(brew --prefix)
for plugin in docker-compose docker-buildx; do
  bin="$prefix/opt/$plugin/bin/$plugin"
  if [[ -x $bin ]]; then
    mkdir -p ~/.docker/cli-plugins
    ln -sfn "$bin" ~/.docker/cli-plugins/$plugin
  fi
done
