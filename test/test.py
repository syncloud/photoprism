import os
from os.path import join, dirname
from subprocess import check_output
import time
import pytest
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from syncloudlib.http import wait_for_rest
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


@pytest.fixture(scope="session")
def module_setup(request, device, app_dir, artifact_dir):
    def module_teardown():
        device.run_ssh('ls -la /var/snap/photoprism/current/config > {0}/config.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/photoprism/current/config/photoprism.yaml {0}/photoprism.yaml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl | tail -1000 > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap > {0}/snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap/photoprism > {0}/snap.photoprism.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap > {0}/var.snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/photoprism > {0}/var.snap.photoprism.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/photoprism/current/ > {0}/var.snap.photoprism.current.ls.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('snap run photoprism.sqlite .dump > {0}/app.test.db.dump.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('ls -la /var/snap/photoprism/common > {0}/var.snap.photoprism.common.ls.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('ls -la /data > {0}/data.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /data/photoprism > {0}/data.photoprism.ls.log'.format(TMP_DIR), throw=False)

        app_log_dir = join(artifact_dir, 'log')
        os.mkdir(app_log_dir)
        device.scp_from_device('/var/snap/photoprism/common/log/*.log', app_log_dir)
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, device_host, app, domain):
    add_host_alias(app, device_host, domain)
    device.run_ssh('date', retries=100)
    device.run_ssh('mkdir {0}'.format(TMP_DIR))


def test_activate_device(device):
    response = retry(device.activate_custom)
    assert response.status_code == 200, response.text


def test_install(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_index(app_domain):
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)


def __log_data_dir(device):
    device.run_ssh('ls -la /data')
    device.run_ssh('mount')
    device.run_ssh('ls -la /data/')
    device.run_ssh('ls -la /data/photoprism')


def test_storage_change_event(device):
    device.run_ssh('snap run photoprism.storage-change > {0}/storage-change.log'.format(TMP_DIR))


def test_access_change_event(device):
    device.run_ssh('snap run photoprism.access-change > {0}/access-change.log'.format(TMP_DIR))


def test_ffmpeg(device):
    device.run_ssh('/snap/photoprism/current/photoprism/bin/ffmpeg.sh -h > {0}/ffmpeg.log'.format(TMP_DIR))


def test_darktable(device):
    device.run_ssh('sudo -u photoprism /snap/photoprism/current/photoprism/bin/darktable-cli.sh -v')


def test_heif_convert(device):
    device.run_ssh('sudo -u photoprism /snap/photoprism/current/photoprism/bin/heif-convert -v')


def test_db_restore_on_upgrade(device, app_archive_path, device_host, device_password, app_domain):
    device.scp_to_device(join(DIR, '20220831_001704_66A1ECB0.heic'), '/data/photoprism/photos/import', throw=True)
    output = device.run_ssh('snap run photoprism.cli cp')
    assert 'media: generated 10 thumbnails' in output
    assert 'not supported' not in output
    device.run_ssh('snap run photoprism.cli index')
    device.run_ssh("snap run photoprism.sql photoprism --execute 'select count(*) from photos'")
    output = device.run_ssh('snap run photoprism.cli find')
    assert "20220831_001704_66A1ECB0.heic" in output
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)
    device.run_ssh("snap run photoprism.sql photoprism --execute 'select count(*) from photos'")
    output = device.run_ssh('snap run photoprism.cli find')
    assert "20220831_001704_66A1ECB0.heic" in output


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password, app_domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)


def test_upgrade(app_archive_path, device_host, device_password, app_domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)


def retry(method, retries=10):
    attempt = 0
    exception = None
    while attempt < retries:
        try:
            return method()
        except Exception as e:
            exception = e
            print('error (attempt {0}/{1}): {2}'.format(attempt + 1, retries, str(e)))
            time.sleep(5)
        attempt += 1
    raise exception
