#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
#Usage: type 'python3 eventFiles_test.py --help' in the shell

import unittest
import sys
import os
import argparse
from math import inf as INFINITY
import evt_metrics as evt_metrics
sys.path.insert(0, os.path.abspath('../src/main'))
from evtio import read_events

class eventFilesTest(unittest.TestCase):
    def setUp(self):
        self.O_events = read_events(self.obtained_fn)
        self.E_events = read_events(self.expected_fn)

    def test_similar_event_files(self):
        self.assertTrue( evt_metrics.distance(self.O_events, self.E_events) <= self.delta) 

    def test_obtained_is_subset(self):
        self.assertTrue( evt_metrics.subset(self.O_events, self.E_events, self.delta) )

    def test_expected_is_subset(self):
        self.assertTrue( evt_metrics.subset(self.E_events, self.O_events, self.delta) )

    #Will be removed after some time
    #def test_binary_match(self):
    #    self.assertEqual(evt_metrics.proportion_of_naive(self.O_events, self.E_events),
    #                     evt_metrics.proportion_of(self.O_events, self.E_events))
    #    self.assertEqual(evt_metrics.proportion_of_naive(self.E_events, self.O_events),
    #                      evt_metrics.proportion_of(self.E_events, self.O_events))

    def test_print_metrics(self):
        evt_metrics.print_metrics(self.obtained_fn, self.expected_fn, self.delta) 
        pass

if __name__ == "__main__":
   
    parser = argparse.ArgumentParser()
    
    parser.add_argument("-e", "--expected", 
                        help="Sets the filename of the oracle eventfile", 
                        required=True)
    parser.add_argument("-o", "--obtained", 
                        help="Sets the filename of the eventfile to be tested",
                        required=True)

    eventFilesTest.delta = 0.1 #10% is default. Means that at most 10% of the events in the smaller set
                                 #may not match with an event in the other set.

    parser.add_argument("-d", "--delta", 
                        help="The two set of events will be tested to be equal "+
                        "with a delta tolerance, meaning that at most 10 percent of "+
                        "the events in the smaller set may not match with an "+
                        "event in the other set."
                        "Default is: "+ str(eventFilesTest.delta),
                        required=False)   

    args = parser.parse_args()
    
    eventFilesTest.expected_fn = args.expected
    eventFilesTest.obtained_fn = args.obtained

    if(args.delta):
        eventFilesTest.delta = float(args.delta)
        sys.argv.pop()

    sys.argv.pop()
    sys.argv.pop()
    unittest.main()


