from urllib.parse import urljoin, urlparse

import requests

REDIRECTS = (301, 302, 303, 307, 308)
OIDC_REDIRECT = '/api/v1/oidc/redirect'


def sso_login(app_domain, auth_domain, user, password):
    session = requests.session()
    session.verify = False
    first = session.post('https://{0}/api/firstfactor'.format(auth_domain), timeout=60, json={
        'username': user,
        'password': password,
        'keepMeLoggedIn': False,
        'requestMethod': 'GET',
        'targetURL': 'https://{0}/'.format(app_domain),
    })
    assert first.status_code == 200, first.text

    url = 'https://{0}/api/v1/oidc/login'.format(app_domain)
    for _ in range(10):
        response = session.get(url, allow_redirects=False, timeout=60)
        if response.status_code not in REDIRECTS:
            assert urlparse(url).path == OIDC_REDIRECT, '{0} {1}: {2}'.format(url, response.status_code, response.text[:500])
            assert response.status_code == 200, '{0} {1}: {2}'.format(url, response.status_code, response.text[:500])
            return
        url = urljoin(url, response.headers['Location'])
    raise AssertionError('too many redirects, last {0}'.format(url))


def api_login(app_domain, user, password):
    return requests.post('https://{0}/api/v1/session'.format(app_domain), verify=False, timeout=60,
                         json={'username': user, 'password': password})


def accounts(device):
    output = device.run_ssh(
        'snap run photoprism.sql photoprism --batch --skip-column-names --execute '
        "'select user_name, user_uid, auth_provider, super_admin, user_role, base_path from auth_users'"
    )
    result = {'raw': output}
    for line in output.splitlines():
        fields = line.split('\t')
        fields += [''] * (6 - len(fields))
        if len(fields) == 6 and fields[0]:
            name, uid, provider, super_admin, role, base_path = fields
            result[name] = {'uid': uid, 'provider': provider, 'super_admin': super_admin, 'role': role, 'base_path': base_path}
    return result


def set_provider(device, user, provider):
    device.run_ssh(
        'snap run photoprism.sql photoprism --execute '
        "'update auth_users set auth_provider = \\\"{0}\\\" where user_name = \\\"{1}\\\"'".format(provider, user)
    )
