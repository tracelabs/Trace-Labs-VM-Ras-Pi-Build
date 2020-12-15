# Add /opt/vc/bin to the PATH for all users.
if ! echo "$PATH" | tr : '\n' | grep -q "^/opt/vc/bin$"; then
  PATH="/opt/vc/bin:$PATH"
fi
