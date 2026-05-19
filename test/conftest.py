import sys
from os.path import dirname, join

DIR = dirname(__file__)
sys.path.insert(0, DIR)

from syncloudlib.integration.conftest import *


@pytest.fixture(scope="session")
def project_dir():
    return join(DIR, '..')
