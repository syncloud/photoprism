import hashlib
import os
from os.path import dirname, join
from subprocess import check_output, run
import pytest
import requests
from PIL import Image
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest

import seed

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'
IMPORT_DIR = '/data/photoprism/photos/import'

PRE_UPGRADE_IMAGES = [
    (join(DIR, '20220831_001704_66A1ECB0.heic'), '20220831_001704_66A1ECB0.heic'),
    (join(DIR, 'images/profile.jpeg'), 'profile.jpeg'),
    (join(DIR, 'images/generated-big.png'), 'generated-big.png'),
]


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir):
    def module_teardown():
        device.run_ssh('journalctl > {0}/refresh.journalctl.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), artifact_dir)
        run('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, device_host, domain, device):
    add_host_alias(app, device_host, domain)
    device.activated()
    device.run_ssh('rm -rf {0}'.format(TMP_DIR), throw=False)
    device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)


def test_install_from_store(device, app_domain):
    device.run_ssh('snap remove photoprism')
    device.run_ssh('snap install photoprism', retries=10)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


def test_seed_pictures_before_upgrade(device):
    _generate_random_png(join(DIR, 'images/generated-big.png'), 1000, 1000)
    for path, _ in PRE_UPGRADE_IMAGES:
        device.scp_to_device(path, IMPORT_DIR, throw=True)
    device.run_ssh('snap run photoprism.cli cp')
    device.run_ssh('snap run photoprism.cli index')


def test_pictures_visible_before_upgrade(device):
    assert_originals_present(device, "before upgrade")


def test_upgrade(device, device_host, device_password, app_archive_path, app_domain):
    device.run_ssh('journalctl --vacuum-time=1s', throw=False)
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


def test_pictures_visible_after_upgrade(device):
    assert_originals_present(device, "after upgrade")


def _generate_random_png(path, width, height):
    Image.frombytes('RGB', (width, height), os.urandom(3 * width * height)).save(path)


def file_sha1(path):
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def assert_originals_present(device, phase):
    output = device.run_ssh('snap run photoprism.cli find --json')
    for path, name in PRE_UPGRADE_IMAGES:
        checksum = file_sha1(path)
        assert checksum in output, "expected {0} ({1}) indexed {2}, got:\n{3}".format(name, checksum, phase, output)


def test_new_picture_scanned_after_upgrade(device):
    path = join(DIR, 'images/post-upgrade.png')
    device.scp_to_device(path, IMPORT_DIR, throw=True)
    device.run_ssh('snap run photoprism.cli cp')
    device.run_ssh('snap run photoprism.cli index')
    output = device.run_ssh('snap run photoprism.cli find --json')
    checksum = file_sha1(path)
    assert checksum in output, "new image ({0}) not indexed after upgrade, got:\n{1}".format(checksum, output)


def test_add_regular_users_after_upgrade(device):
    seed.add_regular_users(device)


def test_seed_multi_user_photos_after_upgrade(device):
    seed.seed_multi_user_photos(device)
