#
# Copyright 2018 FastWave LLC
#
# Developed by Tomas Pastore <tomas.pastore@fastwavellc.com>
#
# NOTICE:  All information contained herein is, and remains the property of
# FastWave LLC. The intellectual and technical concepts contained
# herein are proprietary to FastWave LLC and its suppliers and may be covered
# by U.S. and Foreign Patents, patents in process, and are protected by
# trade secret or copyright law. Dissemination of this information or
# reproduction of this material is strictly forbidden unless prior written
# permission is obtained from FastWave LLC.

from os import path as op
from setuptools import setup

# get the version
version = None
with open(op.join('evtio', '__init__.py'), 'r') as fid:
    for line in (line.strip() for line in fid):
        if line.startswith('__version__'):
            version = line.split('=')[1].strip().strip('\'')
            break
if version is None:
    raise RuntimeError('Could not determine version')

DIST = 'evtio'
DESC = 'EVT File IO Module.'
URL = 'https://gitlab.liaa.dc.uba.ar/tju-uba/io_evt'
VERSION = version


if __name__ == "__main__":
    setup(name=DIST,
          maintainer='Tomas Pastore',
          maintainer_email='tomas.pastore@fastwavellc.com',
          description=DESC,
          license='Propietary',
          url=URL,
          version=VERSION,
          download_url=URL,
          long_description=open('README.md').read(),
          classifiers=['Programming Language :: Python'],
          platforms='any',
          packages=['evtio'],
          package_data={'evtio': []})
