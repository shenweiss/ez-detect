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
import setuptools

VERSION = '1.0.0'
URL = 'http://gitlab.liaa.dc.uba.ar/tju-uba/ez-detect.git'

if __name__ == "__main__":
    setuptools.setup(name='ez_detect',
          description='HFO engine main code',
		version=VERSION,
          license='Propietary',
          url=URL,
          download_url=URL,
          long_description=open('README.md').read(),
          classifiers=['Programming Language :: Python, Matlab'],
          platforms='any',
          packages=setuptools.find_packages(),
          zip_safe=False,
	     install_requires=['mne', 'numpy',], #trcio, evtio
	     )
