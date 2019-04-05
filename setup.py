from setuptools import find_packages, setup

setup(
    name='ez_detect',
    version='1.0.0',
    packages=find_packages(),
    
    
   
)

# Copyright 2018 FastWave LLC
#
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

VERSION = '1.0.0'
URL = 'http://gitlab.liaa.dc.uba.ar/tju-uba/ez-detect.git'

if __name__ == "__main__":
    setup(name='ez_detect',
          description='HFO engine main code',
		  version='1.0.0',
          license='Propietary',
          url=URL,
          download_url=URL,
          long_description=open('README.md').read(),
          classifiers=['Programming Language :: Python, Matlab'],
          platforms='any',
          packages=['ez_detect'],
          package_data={'ez_detect': []},
          zip_safe=False,
	      install_requires=['mne', 'trcio', 'numpy',],
	      )
