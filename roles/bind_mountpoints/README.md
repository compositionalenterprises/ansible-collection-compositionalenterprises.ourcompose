# Role bind_mountpoints

This role is for compositionalenterprises.ourcompose.bind_mountpoints

We now do some rudimentary error handling on nginx reloads.
If there is one misbehaving container, we remove the configuration file when restarting nginx.
This allows nginx to restart, and we can continue on to fix the broken container.
