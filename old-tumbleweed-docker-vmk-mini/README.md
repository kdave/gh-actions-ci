# GH for CI/CD

Resurrect CI testing in Github actions.  Goal is to wire development git
branches to automated fstests testing on various configs and possibly hardware
setups.

## General design

The self-hosted runners need a daemon to wait for the jobs and execute them. To
run multiple daemons there's separation done by containers. The fstests need a
fresh kernel from git and must not take down the whole system on any problems.

The layers:

- physical host - network, storage, configs
- docker - root system, fstests.git, mount to physical host,
- virtualization - build kernel from git, run in a VM and start fstests; virtme
  or other qemu wrapper

The physical host mounts some directories for docker read-write so the updates
are easier and changes are not possibly lost in docker container upon restarts
or rebuilds.

Virtme (virtme-ng) sees most of the docker root system in read-only, IO is
virtualized. A read-write directory to the docker layer is provided (can be
partially visible from the host too).

## Fstests quirks

- tests btrfs/003 and btrfs/004 could hang for a long time if nothing happens
  in terminal/console
  - `common/preamble` in `_begin_test` add `shopt -e lastpipe` to fix this
  - fast storage can reproduce that
  - maybe it's just under `virtme` + `docker`
- with compression in `MOUNT_OPTINS` filling space can take a long time
- btrfs/010 could hang because of `od` + `/dev/urandom` read and not ending
  when stdout is closed (known and may still be broken)
- if `check` is not started from terminal session, run it as
  `env --default-signal=PIPE ./check` as the SIGPIPE signal is masked and
  messages like *broken pipe* show up in the logs

## Initial setup

### Self-hosted runner

- install docker and set it up so basic commands work
- `./docker-build` should do everything
- if build fails, eg. conflicting packages, run `docker pull opensuse/tumbleweed` first
- go to GH project, Actions -> Runners -> Self-hosted runners -> New runner -> New self-hosted runner
- choose OS and architecture
- go to `workspace/runner` and download the runner tar.gz (200M+), do not unpack yet
- run `docker-run -it -- /bin/bash` to configure the new worker
- worker must not run as root, so the runner directory must be owned by the internal
  user who will run it; this will likely be different UID than your outer user, if
  you see permission problems, `sudo chown fsgqa:fsgqa -R` as needed
- go to `/mnt/workspace/runner`
- do `su fsgqa`, the user we have for fstests
- unpack the tar.gz
- from GH web copy command for configuration (starting with `./config.sh --url
  ...`) and add parameter `--name WORKERNAME` and give it a unique name
- if it fails with *https://api.github.com/actions/runner-registration* and
  404, this is cryptic mesage saying the token has expired, go to web, F5
  refresh and copy the command line again
- the config is interactive, use all defaults, if it succeds, you can see the
  new worker in Settings -> Actions -> Runners as *offline*
- from the same docker shell do a test and start `./run.sh`, the worker should
  show up as *Idle* in the list of runners
- Ctrl-C, exit docker shell, the runner is ready for work

### Fstests git

- checkout or go to the `xfstests.git` (use https://github.com/kdave/xfstests
  repository and branch `local` that has many things fixed for our setups or use
  your own git)
- (temporary) tar up the directory (does not need to be configured or built) to
  file `fstests.tar.gz` and link or place it to `workspace/vm-gh`
- (temporary) once the root is set up, the file will have to be moved to the image

### VM

- note this is custom wrapper around qemu and requires special kernel config
  that does not have `initrd` (from https://github.com/kdave/vmk the "mini" set),
  custom init; this can/will be changed to different wrapper
- TBD


## Github hosted runner

- architectures: x86\_64, ARM (64bit)
- KVM is possible only on x86\_64
- storage is about 150G total and about 90G free for use
- docker is available
- sharing space between jobs does not work
- caching is tricky, not synchronized


## Github self-hosted runner

- on web page start the runner setup, use the commands exactly as there and do
  it in terminal right away (the configuraion phase, after that it's
  persistent)
- if starting `run.sh` fails, check if the token did not expire and recreate
  the runner from scratch
- if running from docker (`docker run` to start a new one), give it a proper
  name (must be unique)
- do not run it with `-it` ie. interactive, terminal may cause some problems
  when interacting with pipes and layers like docker/virtme
- check if it's running by `docker ps`
- stop the runner only via `docker stop CONTAINER`, Ctrl-C will stop the daemon
  but not the running VM (qemu)
- use unique names for VMs
- output of running worker is not interesting, can be also started as `docker
  start` on the background
- enter running container by `docker exec -it CONTAINER /bin/bash`, also
  possible to enter `virtme` if running from there and ssh/console is setup
  (usually it's just `virtme --ssh-client` as the sockets are global)
