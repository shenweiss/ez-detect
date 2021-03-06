#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
#Usage: type 'python3 cmp_evts.py --help' in the shell

import unittest
import sys
from pathlib import Path
import argparse
from evtio import read_evt, metrics as evt_metrics

class eventFilesTest(unittest.TestCase):
    def setUp(self):
        self.O_events = read_evt(self.obtained_fn).events()
        self.E_events = read_evt(self.expected_fn).events()

    def test_similar_event_files(self):
        self.assertTrue( evt_metrics.distance(self.O_events, self.E_events) <= self.delta-self.delta/4) 

    def test_obtained_is_subset(self):
        self.assertTrue( evt_metrics.subset(self.O_events, self.E_events, self.delta) )

    def test_expected_is_subset(self):
        self.assertTrue( evt_metrics.subset(self.E_events, self.O_events, self.delta) )

    def test_print_metrics(self):
        if self.trc_fname != 'NOT_GIVEN':
            evt_metrics.print_metrics(self.obtained_fn, self.expected_fn, self.trc_fname, self.delta) 
        pass

if __name__ == "__main__":
   
    parser = argparse.ArgumentParser()
    
    parser.add_argument("-e", "--expected", 
                        help="Sets the filename of the oracle eventfile", 
                        required=True)
    parser.add_argument("-o", "--obtained", 
                        help="Sets the filename of the eventfile to be tested",
                        required=True)

    parser.add_argument("-trc", "--trc_fname", 
                        help="Sets the filename of the tracefile that was runned in both "+
                        "versions, it is used to extract the channel list.",
                        required=False, default='NOT_GIVEN')

    parser.add_argument("-d", "--delta",
                        help="The two set of events will be tested to be equal "+
                        "with a delta tolerance, meaning that at most 100*delta percent of "+
                        "the events in one set may not match with an "+
                        "event in the other set.",
                        required=False, default= 0.15, type=float)   

    args = parser.parse_args()
    
    eventFilesTest.expected_fn = str(Path(args.expected).expanduser().resolve())
    eventFilesTest.obtained_fn = str(Path(args.obtained).expanduser().resolve())
    eventFilesTest.trc_fname = str(Path(args.trc_fname).expanduser().resolve())
    eventFilesTest.delta = float(args.delta)

    while(len(sys.argv) > 1):
        sys.argv.pop()
    unittest.main()


