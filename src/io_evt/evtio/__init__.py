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

__version__ = '0.1_dev0'

from . import io
from .io import read_evt, write_evt, Event, EventFile, load_events_from_matfiles
from . import metrics

