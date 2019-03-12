#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
Metric criterion:

Let O (obtained) and E (expected) be two sets of events. 
Where an event is represented as (channel, (begin, end))

We want to test that these sets are 'similar'. We will ask then:

1) Enough of E events are found in O: meaning 'We keep finding what we found before'
2) Enough of O events are found in E: meaning 'We aren't adding many events that were not found before'

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

    distance(O,E) = 2 - (Crit_1 + Crit_2) /2

So in this way, we have a third criterion that is that this distance(O,E)
(which is a number between 0 and 1) must be short. This threshold can be a bit more strict than the one
for Crit_1 and 2 because one component can help the other if it gets a bad score. 

As an example, if we set the threshold to be 0.1, it will lead to the following constraints:

1) Crit_1 >= (1- 0.1) : which means that at least we are finding more or equal to 90% of the events that we were before.

2) Crit_2 >= (1- 0.1) : which means that at least 90% of what we found, was already beeing found (i.e 'we aren't adding too much) 

3) distance(O,E) <= 0.1 - 0.1 / 4  
#the /4 is to say that here they have to compensate each other so they have to reach a lower threshold.
Meaning that if Crit_1 is near '90%' Crit_2 must be near '100%' to compensate.

'''
from math import inf as INFINITY
from dateutil.tz import tzutc
from datetime import datetime
from os.path import basename, splitext, expanduser
from tabulate import tabulate

import sys
import os
import io
from contextlib import redirect_stdout
#sys.path.insert(0, os.path.abspath('../src/main'))
from evtio import read_evt
from trcio import read_raw_trc
import evt_config

MIN_DATETIME = datetime.min.replace(tzinfo=tzutc())
MAX_DATETIME = datetime.max.replace(tzinfo=tzutc())

# INPUT: an increasingly ordered by begin interval list: [(begin, end)], 
#        aBegin is a number as the ones in the intervals
# OUTPUT: The index where an interval with begin == aBegin 
# can be inserted to mantain the order of the list of intervals.
# Time Complexity: O(Log(N)) with N = number of intervals to review     
def binary_search(interval, intervals):
    if len(intervals) == 0 : 
        return 0

    return binary_search_rec(interval, intervals, 0, len(intervals)-1)

def binary_search_rec(interval, intervals, low, high):
    if high <= low: 
        return low+1 if (interval >= intervals[low]) else low 
  
    mid = low + (high-low) // 2
    otherInterval = intervals[mid]

    if(interval == otherInterval ): 
        return mid+1 
    elif(interval > otherInterval): 
        return binary_search_rec(interval, intervals, mid+1, high)
    else: 
        return binary_search_rec(interval, intervals, low, mid-1)

#Returns true if the interval w overlaps with any interval in I
#Time Complexity: O(Log(N)) with N = number of intervals to review 
def binary_match(w, I):
    if len(I) == 0 :
        return False

    begin_idx = 0
    end_idx = 1
    index = binary_search(w, I)
    if index == 0:
        prev = ( MIN_DATETIME, MIN_DATETIME) #If there is no prev, makes that match fail
        next = I[index]
    elif index == len(I):
        prev = I[index-1]
        next = (MAX_DATETIME, MAX_DATETIME) #If there is no next, makes that match fail
    else: 
        prev = I[index -1]
        next = I[index]
    res = w[begin_idx]<= prev[end_idx] or w[end_idx] >= next[begin_idx]

    return res

def add_prop_id_and_kind(rows, ch_id, kind, A, B): 
    matches = 0
    A_events = filter_id_and_kind(A, ch_id, kind)
    B_rip_times = [(e.begin(), e.end()) for e in filter_id_and_kind(B, ch_id, kind)]
    B_rip_times.sort() #order them by begin time
    for e in A_events:
        e_time = (e.begin(), e.end())
        if binary_match( e_time, B_rip_times): 
            matches+= 1

    rows[ch_id][kind] = (matches, len(A_events)) if len(A_events) > 0 else (1, 1)

#Input: A and B are dictionaries {channel_name: [(begin,end)]}  
#Output: Gives an idea of what proportion of A is in B. 
#Returns a dictionary {A_channel: p } where p is the proportion 
#of events of that channel that had a match in B. 
#Expressed as a tuple (m, tot) meaning matches over total of channel 
#Time Complexity: O(C* E_ci* log(E_ci)): for each channel takes n log n
#regarding the amount of events of the channel 
def proportion_of(A, B):
    props = dict()
    
    for i in range( max([e.ch_id() for e in A])):
        ch_id = i+1
        props[ch_id] = dict()
        add_prop_id_and_kind(props, ch_id, evt_config.ripple_kind, A, B)
        add_prop_id_and_kind(props, ch_id, evt_config.fastRipple_kind, A, B) 
        add_prop_id_and_kind(props, ch_id, evt_config.spike_kind, A, B) 

    return props
#Requieres input is not empty
#min_chan_tot is because it makes no sense to use proportions if total is too low.
#for example 3 events of 6 is 0.5 and the test would fail, but its just because the
#total amount is too low.
def min_proportion(props, min_chan_tot=1):
    min_m, min_tot = INFINITY, 1 #the first will replace it
    for ch_id in props.keys():
        for kind in props[ch_id]:
            matches, tot = props[ch_id][kind]
            if tot >= min_chan_tot and matches/tot < min_m/min_tot:
                min_m, min_tot = matches, tot

    return min_m, min_tot

#Input: Two dictionaries {channel_name: [(begin,end)]}
#Output: Returns True iff the amount of events of each channel
#in A that doesn't match an event in B is less or equal than 
# delta * #(A channel events). Default means a 10% tolerance.
def subset(A, B, delta=0.1):
    if len(A) == 0:
        return True
    proportions_by_chan = proportion_of(A, B)
    matches, tot = min_proportion(proportions_by_chan, min_chan_tot=50)

    return 1 - matches/tot <= delta

#Requiere neither A nor B are empty
def distance(A, B):
    A_prop_by_chan = proportion_of(A, B)
    B_prop_by_chan = proportion_of(B, A)

    matches_A, tot_A = min_proportion(A_prop_by_chan, min_chan_tot=50)
    matches_B, tot_B = min_proportion(B_prop_by_chan,  min_chan_tot=50)
    A_min_p = matches_A / tot_A
    B_min_p = matches_B / tot_B
   
    return 1 - (A_min_p + B_min_p) / 2 
 
def highlight_max(n, m):
    if(n > m): 
        n_str = '\x1b[6;30;42m' + str(n) + '\x1b[0m'
    else:
        n_str = str(n)

    if(m > n): 
        m_str = '\x1b[6;30;42m' + str(m) + '\x1b[0m'
    else:
        m_str = str(m)

    return n_str, m_str

def filter_id_and_kind(events, ch_id, kind):
    return [ e for e in events if e.ch_id() == ch_id and e.kind() == kind ]

def append_count_row(rows, O_events, E_events, ch_name, ch_id, kind):
    o_evt_count = len( filter_id_and_kind(O_events, ch_id, kind))
    e_evt_count = len( filter_id_and_kind(E_events, ch_id, kind))
    o_evt_count_str, e_evt_count_str = highlight_max(o_evt_count, e_evt_count)           
    ch_count = [ch_name, str(ch_id) if kind == evt_config.fastRipple_kind else '', kind, o_evt_count_str, e_evt_count_str ]
    rows.append(ch_count)

def print_count_by_channel(O_events, E_events, original_chanlist, obtained_basename, expected_basename):
    
    opened_by_chan= ['Ch Name', 
                     'Ch ID', 
                     'HFO kind',
                     '# in ' + obtained_basename,
                     '# in ' + expected_basename]
    rows = []
    for i in range(len(original_chanlist)):
        ch_name = original_chanlist[i]
        ch_id = i+1
        append_count_row(rows, O_events, E_events, '', ch_id, evt_config.ripple_kind)
        append_count_row(rows, O_events, E_events, ch_name, ch_id, evt_config.fastRipple_kind)        
        append_count_row(rows, O_events, E_events, '', ch_id, evt_config.spike_kind)        
        s = '-'
        rows.append([s*7, s*7, s*10, s*10, s*10])

    o_tot_str, e_tot_str = highlight_max( len(O_events), len(E_events))
    rows.append(['Total count', '', '', o_tot_str, e_tot_str])

    print("\nEvent count by channel...")
    print("\n"+tabulate( rows, headers=opened_by_chan, tablefmt='orgtbl'))

def prop(props, ch_id, kind):
    if ch_id not in props.keys() or kind not in props[ch_id].keys():
        return 100.0
    else:
        return props[ch_id][kind][0] / props[ch_id][kind][1] * 100

def append_prop_row(rows, O_prop, E_prop, ch_name, ch_id, kind):
    o_prop = prop(O_prop, ch_id, kind)
    e_prop = prop(E_prop, ch_id, kind)
    o_prop, e_prop = highlight_max(o_prop, e_prop)
    r = [ch_name, str(ch_id) if kind == evt_config.fastRipple_kind else '', kind, o_prop, e_prop ]
    rows.append(r)


def print_proportions(O_events, E_events, original_chanlist, obtained_basename, expected_basename):

    proportions= ['Channel Name', 
                  'Ch ID', 
                  'Kind',
                  'Proportion of ' + obtained_basename + " events\n that are also in "+ expected_basename,
                  'Proportion of ' + expected_basename + " events\n that are also in "+ obtained_basename]
    
    O_prop = proportion_of(O_events, E_events)
    E_prop = proportion_of(E_events, O_events)
    rows= []
    for i in range(len(original_chanlist)):
        ch_name = original_chanlist[i]
        ch_id = i+1
        append_prop_row(rows, O_prop, E_prop, '', ch_id, evt_config.ripple_kind)
        append_prop_row(rows, O_prop, E_prop, ch_name, ch_id, evt_config.fastRipple_kind)        
        append_prop_row(rows, O_prop, E_prop, '', ch_id, evt_config.spike_kind) 
        s = '-'
        rows.append([s*7, s*7, s*10, s*10, s*10])
   
    print("\nProportions of one in the other...")
    print("\n"+tabulate( rows, headers=proportions, tablefmt='orgtbl'))

#INPUT: Two evt filenames, O is obtained and E is expected,
# The trc_fname where to get the channel names
# delta is the tolerance for similarity tests.
#como hago para que un path pueda ser ingresado como relativo o absoluto (shell)
def print_metrics(obtained_fn, expected_fn, trc_fname, delta=0.1):
    obtained_basename = splitext(basename(obtained_fn))[0] 
    expected_basename = splitext(basename(expected_fn))[0] 
    
    f = io.StringIO()
    with redirect_stdout(f):
        original_chanlist = read_raw_trc(trc_fname, preload=False).info['ch_names']
    out = f.getvalue()

    O_events = read_evt(obtained_fn).events()
    E_events = read_evt(expected_fn).events()
    print_count_by_channel(O_events, E_events, original_chanlist, obtained_basename, expected_basename)
    print_proportions(O_events, E_events, original_chanlist, obtained_basename, expected_basename)

    subset_res = " is a subset of " if subset(O_events, E_events) else " is not a subset of " 
    print("\nWith a tolerance of "+ str(delta*100) + " percent, "+ obtained_basename + subset_res + expected_basename)

    subset_res = " is a subset of " if subset(E_events, O_events) else " is not a subset of " 
    print("With a tolerance of "+ str(delta*100) + " percent, "+ expected_basename + subset_res + obtained_basename)

    dist = distance(O_events, E_events)
    print("\nThe distance between the event files is: "+ str(dist))


