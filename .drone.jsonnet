local name = 'photoprism';
// Upstream release tag. Drives both the runtime docker image (date-only,
// `photoprism/photoprism:<date>`) and the source tarball pulled by build-fork.sh
// (`refs/tags/<date>-<sha>.tar.gz`).
local upstream_release = '260305-fad9d5395';
local upstream_release_date = std.split(upstream_release, '-')[0];
local version = upstream_release_date;
// Build env image. Photoprism publishes develop:<build-date>-<flavor> on its own
// rolling cadence; pick the closest jammy snapshot to upstream_release_date so
// the toolchain glibc matches the runtime image's bundled glibc.
local upstream_build = '260303-jammy';
local platform = '26.04.10';
local debian = 'bookworm-slim';
local python = '3.12-slim-bookworm';
local go = '1.26';
local dind = '20.10.21-dind';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];

local platform_image(distro, arch) =
  'syncloud/platform-' + distro + '-' + arch + ':' + platform;

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
      name: 'version',
      image: 'debian:' + debian,
      commands: [
        'echo $DRONE_BUILD_NUMBER > version',
      ],
    },
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
      image: platform_image(distro, arch),
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
        UPSTREAM_TAG: upstream_release,
      },
      commands: [
        './photoprism/build-fork.sh',
      ],
    },
  ] + [
    {
      name: 'photoprism test ' + distro,
      image: platform_image(distro, arch),
      commands: [
        './photoprism/test.sh',
      ],
    }
    for distro in distros
  ] + [
    {
      name: 'cli',
      image: 'golang:' + go,
      commands: [
        'cd cli',
        'mkdir -p ../build/snap/meta/hooks ../build/snap/bin',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/meta/hooks/install ./cmd/install',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/meta/hooks/configure ./cmd/configure',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/meta/hooks/pre-refresh ./cmd/pre-refresh',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/meta/hooks/post-refresh ./cmd/post-refresh',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/bin/cli ./cmd/cli',
      ],
    },
    {
      name: 'package',
      image: 'debian:' + debian,
      commands: [
        'VERSION=$(cat version)',
        './package.sh ' + name + ' $VERSION ',
      ],
    },
  ] + [
    {
      name: 'test ' + distro,
      image: 'python:' + python,
      commands: [
        'cd test',
        './deps.sh',
        'py.test -x -s test.py --distro=' + distro + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
      ],
    }
    for distro in distros
  ] + (if test_ui then [
         {
           name: 'e2e',
           image: 'mcr.microsoft.com/playwright:v1.48.2-jammy',
           environment: {
             PLAYWRIGHT_FULL_DOMAIN: distro_default + '.com',
             PLAYWRIGHT_APP_DOMAIN: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_HOST: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_USER: 'user',
             PLAYWRIGHT_DEVICE_PASSWORD: 'Password1',
             PLAYWRIGHT_ARTIFACT_DIR: '/drone/src/artifact',
           },
           commands: [
             'apt-get update -qq && apt-get install -y -qq sshpass openssh-client imagemagick curl',
             'cd test',
             'head -c $((3*1000*1000)) /dev/urandom | convert -depth 8 -size 1000x1000 RGB:- images/generated-big.png',
             'cd e2e',
             'npm ci --no-audit --no-fund',
             'npx playwright test --project=desktop',
           ],
         },
       ] else []) + [
    {
      name: 'test-upgrade',
      image: 'python:' + python,
      commands: [
        'cd test',
        './deps.sh',
        'py.test -x -s upgrade.py --distro=' + distro_default + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
      ],
    },
    {
      name: 'upload',
      image: 'debian:' + debian,
      environment: {
        AWS_ACCESS_KEY_ID: { from_secret: 'AWS_ACCESS_KEY_ID' },
        AWS_SECRET_ACCESS_KEY: { from_secret: 'AWS_SECRET_ACCESS_KEY' },
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      commands: [
        'PACKAGE=$(cat package.name)',
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release publish -f $PACKAGE -b $DRONE_BRANCH',
      ],
      when: {
        branch: ['stable', 'master'],
        event: ['push'],
      },
    },
    {
      name: 'promote',
      image: 'debian:' + debian,
      environment: {
        AWS_ACCESS_KEY_ID: { from_secret: 'AWS_ACCESS_KEY_ID' },
        AWS_SECRET_ACCESS_KEY: { from_secret: 'AWS_SECRET_ACCESS_KEY' },
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      commands: [
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release promote -n ' + name + ' -a $(dpkg --print-architecture)',
      ],
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
    event: [
      'push',
      'pull_request',
    ],
  },
  services: [
    {
      name: 'docker',
      image: 'docker:' + dind,
      privileged: true,
      volumes: [{
        name: 'dockersock',
        path: '/var/run',
      }],
    },
  ] + [
    {
      name: name + '.' + distro + '.com',
      image: platform_image(distro, arch),
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
    { name: 'dockersock', temp: {} },
  ],
}];

build('amd64', true) +
build('arm64', false)
