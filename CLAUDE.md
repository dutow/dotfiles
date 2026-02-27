This is my dotfiles repository for quickly configuring new installations.

It uses ansible + dotbot to setup a new machine from scratch and then manage configuration, in a variety of setups.

It supports the following linux distributions:
* Ubuntu LTS versions (22.04, 24.04)
* openSUSE Tumbleweed
* Oracle Linux (8, 9, 10)

And it has 3 different target environments:
* Console only installations, like servers, small virtual machines or interactive docker/podman instances
* WSL installations (mostly console, but can contain UI apps)
* Real computer installations (laptop, desktop pcs) with a full desktop environment (different desktop might have some different configurations because of hardware/setup differences)

For real computer installations, the matrix doesn't have to be full, for now we only support Tumbleweed.

We also want some "sets" that are not part of the basic console setup, but are selectable separately - for example not all console setups need all C/C++ development tools. WSL/Desktop setups should be "all inclusive", and contain all specific sets.
