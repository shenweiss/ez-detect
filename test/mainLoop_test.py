#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
import argparse
#from math import inf as INFINITY
import sys
import os
sys.path.insert(0, os.path.abspath('../src/main'))
from hfo_annotate import _getFilePointers, _calculateBlockAmount
import config

class hfoAnnotateTest(unittest.TestCase):
    def setUp(self):
        self.srate_1024 = 1024
        self.srate_2000 = 2000
        self.str_t_1 = 1 #Since first second.
        self.str_t_min30 = 1741 #Since minute 30 (skip 29 minutes).
        self.stp_t_min31 = 1801 #Stp before start reading minute 31
        self.stp_t_all = config.STOP_TIME_DEFAULT
        self.cycle_time_5min = 300
        self.cycle_time_10min = 600
        self.samples_1Hr_1024hz = 3686400
        self.samples_1Hr_andHalfSec_1024hz = 3686912

    def test_getFilePointers_wholeRec(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_1, self.stp_t_all, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        self.assertEqual( file_pointers['start'], 0) #the first sample
        self.assertEqual( file_pointers['end'], self.samples_1Hr_1024hz ) #last idx+1 to take [...) convention

    def test_getFilePointers_suffixRec(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_min30, self.stp_t_all, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        self.assertEqual( file_pointers['start'], 29 * 60 * self.srate_1024) #idx the first sample of min 30 
        self.assertEqual( file_pointers['end'], self.samples_1Hr_1024hz ) #last idx+1 to take [...) convention

    def test_getFilePointers_prefixRec(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_1, self.stp_t_min31, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        self.assertEqual( file_pointers['start'], 0) #idx of the first sample
        self.assertEqual( file_pointers['end'], (self.stp_t_min31-1) * self.srate_1024 ) #idx of the first sample of min 31

    def test_getFilePointers_middleRec(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_min30, self.stp_t_min31, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        self.assertEqual( file_pointers['start'], 29 * 60 * self.srate_1024) #the first sample of min 30 
        self.assertEqual( file_pointers['end'], (self.stp_t_min31-1) * self.srate_1024 ) #idx of the first sample of min 31

    def test_getFilePointers_blockSize_1(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_min30, self.stp_t_min31, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        self.assertEqual( file_pointers['block_size'], self.cycle_time_5min * self.srate_1024)

    def test_getFilePointers_blockSize_2(self):
        file_pointers = _getFilePointers(self.srate_2000, self.str_t_min30, self.stp_t_min31, 
                                         self.cycle_time_10min, self.samples_1Hr_1024hz)
        self.assertEqual( file_pointers['block_size'], self.cycle_time_10min * self.srate_2000)

    def test_calculateBlockAmount_fullBlocks(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_1, self.stp_t_min31, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        blocks = _calculateBlockAmount(file_pointers, self.srate_1024)

        self.assertEqual(blocks, 6)

    def test_calculateBlockAmount_takeRemainingIfMoreThan100Snds(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_1, self.stp_t_min31 + 100, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        blocks = _calculateBlockAmount(file_pointers, self.srate_1024)

        self.assertEqual(blocks, 7)

    def test_calculateBlockAmount_dropRemainingIfLessThan100Snds(self):
        file_pointers = _getFilePointers(self.srate_1024, self.str_t_1, self.stp_t_min31 + 99, 
                                         self.cycle_time_5min, self.samples_1Hr_1024hz)
        blocks = _calculateBlockAmount(file_pointers, self.srate_1024)

        self.assertEqual(blocks, 6)

if __name__ == "__main__":
   
    unittest.main()












