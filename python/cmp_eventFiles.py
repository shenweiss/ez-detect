#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
#Usage: type 'python3 cmpEventFiles.py --help' in the shell

'''
Metric criterion:

Let O (obtained) and E (expected) be two sets of events. 
Where an event is represented as (channel, (begin, end))

We want to test that these sets are 'similar'. We will ask then:

1) Enough of E events are found in O: meaning 'We keep finding what we found before'
2) Enough of O events are found in E: meaning 'We aren't adding many events that were not found before'

Specifically:  We defined the following metric.

Given an event 'e' and a set of events S, we will say that e 'is'(or has a match) in S if we find an event
in S which channel is the same as e's channel, and their time-windows overlap.

We will ask for similarity for each channel in the union of the two sets. 
So for each channel we will define:

    Criterion 1) 'We keep finding what we found before' as:
            
            #(Matches between O and E)/#E  : must be 'high' (for example >= 0.9) 
    
    Criterion 2) 'We aren't adding many events that were not found before' as:

            #(Matches between O and E)/#O  : must be 'high' (for example >= 0.9)

Finally, we will also ask that if one criterion is near the threshold, the other one must be 'good'
to compensate it. So we define the notion of distance between the two sets as follows, looking forward 
for it to be short. 

    distance(O,E) = 2 - (Crit_1 + Crit_2)

So in this way, we have a third criterion that is that this distance(O,E)
(which is a number between 0 and 2) must be short. 

As an example, if we set the threshold to be 0.1, it will lead to the following constraints:

1) Crit_1 >= (1- 0.1) : which means that at least we are finding more or equal to 90% of the events that we were before.

2) Crit_2 >= (1- 0.1) : which means that at least 90% of what we found, was already beeing found (i.e 'we aren't adding too much) 

3) distance(O,E) <= 0.1 
    2 - 0.1 <= Crit_1 + Crit_2
    1.9 <= Crit_1 + Crit_2

    Meaning that if Crit_1 is near '90%' Crit_2 must be near '100%' to compensate.

'''
import unittest
import sys
import argparse
from math import inf as INFINITY
import evt_metrics as evt_metrics
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
    def test_binary_match(self):
        self.assertEqual(evt_metrics.proportion_of_naive(self.O_events, self.E_events),
                          evt_metrics.proportion_of(self.O_events, self.E_events))

        self.assertEqual(evt_metrics.proportion_of_naive(self.E_events, self.O_events),
                          evt_metrics.proportion_of(self.E_events, self.O_events))

if __name__ == "__main__":
   
    parser = argparse.ArgumentParser()
    
    parser.add_argument("-o", "--expected", 
                        help="Sets the filename of the oracle eventfile", 
                        required=True)
    parser.add_argument("-t", "--obtained", 
                        help="Sets the filename of the eventfile to be tested",
                        required=True)

    eventFilesTest.delta = 0.1 #10% is default. Means that at most 10% of the events in the smaller set
                                 #may not match with an event in the other set.

    parser.add_argument("-d", "--delta", 
                        help="The two set of events will be tested to be equal "+
                        "with a delta tolerance, meaning that at most 10\% of "+
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


