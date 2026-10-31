local name = 'photoprism';
local version = '261029';
local upstream_source = '261029-963b58c50';
local upstream_build = '261027-resolute';
local platform = '26.10.02';
local debian = 'bookworm-slim';
local python = '3.12-slim-bookworm';
local go = '1.27.3';
local playwright = 'mcr.microsoft.com/playwright:v1.48.2-jammy';
local store_publisher = 'stable-366';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];

local platform_image(distro) =
  'syncloud/platform-' + distro + ':' + platform;

local build(arch, test_ui) = [{
  kind: 'pipeline',
  type: 'docker',
  name: arch,
  platform: {
    os: 'linux',
    arch: arch,
  },
  steps: [
    {
      name: 'mariadb',
      image: 'linuxserver/mariadb:10.5.16-alpine',
      commands: [
        './mariadb/build.sh',
      ],
    },
  ] + [
    {
      name: 'mariadb test ' + distro,
      image: platform_image(distro),
      commands: [
        './mariadb/test.sh',
      ],
    }
    for distro in distros
  ] + [
    {
      name: 'photoprism',
      image: 'photoprism/photoprism:' + version,
      commands: [
        './photoprism/build.sh',
      ],
    },
    {
      name: 'photoprism fork',
      image: 'photoprism/develop:' + upstream_build,
      environment: {
        UPSTREAM_TAG: upstream_source,
      },
      commands: [
        './photoprism/build-fork.sh',
      ],
    },
  ] + [
    {
      name: 'photoprism test ' + distro,
      image: platform_image(distro),
      commands: [
        './photoprism/test.sh',
      ],
    }
    for distro in distros
  ] + [
    {
      name: 'cli',
      image: 'golang:' + go,
      commands: ['./cli/build.sh'],
    },
    {
      name: 'package',
      image: 'debian:' + debian,
      commands: ['./package.sh ' + name + ' $DRONE_BUILD_NUMBER'],
    },
  ] + [
    {
      name: 'test ' + distro,
      image: 'python:' + python,
      commands: ['./ci/test.sh test.py ' + distro + ' ' + name],
    }
    for distro in distros
  ] + (if test_ui then [
         {
           name: 'e2e',
           image: playwright,
           commands: ['./test/e2e/run.sh e2e'],
         },
       ] else []) + [
    {
      name: 'test-upgrade',
      image: 'python:' + python,
      commands: ['./ci/test.sh upgrade.py ' + distro_default + ' ' + name],
    },
  ] + (if test_ui then [
         {
           name: 'e2e-after-upgrade',
           image: playwright,
           commands: ['./test/e2e/run.sh e2e-after-upgrade'],
         },
       ] else []) + [
    {
      name: 'publish',
      image: 'syncloud/store-publisher:' + store_publisher,
      environment: {
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      command: ['snap', '-c', '${DRONE_BRANCH}'],
      when: {
        branch: ['stable'],
        event: ['push'],
      },
    },
    {
      name: 'artifact',
      image: 'appleboy/drone-scp:1.6.4',
      settings: {
        host: { from_secret: 'artifact_host' },
        username: 'artifact',
        key: { from_secret: 'artifact_key' },
        timeout: '2m',
        command_timeout: '2m',
        target: '/home/artifact/repo/' + name + '/${DRONE_BUILD_NUMBER}-' + arch,
        source: 'artifact/*',
        strip_components: 1,
      },
      when: {
        status: ['failure', 'success'],
        event: ['push'],
      },
    },
  ],
  trigger: {
    event: ['push'],
  },
  services: [
    {
      name: name + '.' + distro + '.com',
      image: platform_image(distro),
      privileged: true,
      entrypoint: ['/bin/sh', '-c', "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"],
      volumes: [
        { name: 'dbus', path: '/var/run/dbus' },
        { name: 'dev', path: '/dev' },
      ],
    }
    for distro in distros
  ],
  volumes: [
    { name: 'dbus', host: { path: '/var/run/dbus' } },
    { name: 'dev', host: { path: '/dev' } },
  ],
}];

build('amd64', true) +
build('arm64', false)
