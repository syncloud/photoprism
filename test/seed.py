from os.path import dirname, join

DIR = dirname(__file__)
IMAGES_DIR = join(DIR, 'images')
ORIGINALS = '/data/photoprism/photos/originals'
THUMBNAILS = '/data/photoprism/cache/thumbnails'
REGULAR_PASSWORD = 'regularpass123'

ADMIN_IMAGES = ('admin-1.jpg', 'admin-2.jpg')
USER_IMAGES = (
    ('regularuser1', ('user1-1.jpg', 'user1-2.jpg')),
    ('regularuser2', ('user2-1.jpg', 'user2-2.jpg')),
)
ALL_IMAGE_NAMES = tuple(
    list(ADMIN_IMAGES) + [name for _, files in USER_IMAGES for name in files]
)


def add_regular_users(device):
    for user, _ in USER_IMAGES:
        device.run_ssh(
            'snap run platform.cli user add {0} --password={1}'.format(user, REGULAR_PASSWORD),
            throw=False,
        )


def seed_multi_user_photos(device, images_dir=IMAGES_DIR):
    device.run_ssh('snap run photoprism.cli reset --index --yes')
    device.run_ssh('rm -rf {0}/* {0}/.photoprism {1}/*'.format(ORIGINALS, THUMBNAILS))
    for name in ADMIN_IMAGES:
        device.scp_to_device(join(images_dir, name), ORIGINALS + '/', throw=True)
    for user, files in USER_IMAGES:
        target = '{0}/users/{1}'.format(ORIGINALS, user)
        device.run_ssh('install -d -o photoprism -g photoprism {0}'.format(target))
        for name in files:
            device.scp_to_device(join(images_dir, name), target + '/', throw=True)
    device.run_ssh('chown -R photoprism:photoprism {0}'.format(ORIGINALS))
    device.run_ssh('snap run photoprism.cli index --cleanup')
    output = device.run_ssh('snap run photoprism.cli find')
    for name in ALL_IMAGE_NAMES:
        assert name in output, '{0} missing from indexed originals:\n{1}'.format(name, output)
