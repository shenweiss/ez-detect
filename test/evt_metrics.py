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
sys.path.insert(0, os.path.abspath('../src/main'))
from evtio import read_events
from trcio import read_raw_trc

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
    #print("does it match?")
    #print(res)
    #import pdb; pdb.set_trace()

    return res

#Input: A and B are dictionaries {channel_name: [(begin,end)]}  
#Output: Gives an idea of what proportion of A is in B. 
#Returns a dictionary {A_channel: p } where p is the proportion 
#of events of that channel that had a match in B. 
#Expressed as a tuple (m, tot) meaning matches over total of channel 
#Time Complexity: O(C* E_ci* log(E_ci)): for each channel takes n log n
#regarding the amount of events of the channel 
def proportion_of(A, B):
    proportions = dict()
    
    for chan, A_events in A.items():
        matches = 0
        tot = len(A_events)

        if chan not in B.keys():
            proportions[chan] = matches, tot
            continue #0 matches for this key
        
        B_events = B[chan]
        B_events.sort() #order them by begin time  
        for evt in A_events:
            if binary_match(evt, B_events): 
                matches+= 1

        proportions[chan] = matches, tot
    
    return proportions    

#'Naives' will be removed after some time testing binary match

#Returns true if the interval w overlaps with any interval in I
#Time Complexity: O(N) with N = number of intervals to review
def match_naive(w, I):
    begin_idx = 0
    end_idx = 1
    for w_i in I:
        w_begin_overlap = w_i[begin_idx] <= w[begin_idx] <= w_i[end_idx]
        w_end_overlap = w_i[begin_idx] <= w[end_idx] <= w_i[end_idx]
        w_contains_w_i = w[begin_idx]<=w_i[begin_idx]<=w_i[end_idx]<=w[end_idx]
        if w_begin_overlap or w_end_overlap or w_contains_w_i:
            return True
        
    return False

def proportion_of_naive(A, B):
    proportions = dict()
    
    for chan, A_events in A.items():
        matches = 0
        tot = len(A_events)

        if chan not in B.keys():
            proportions[chan] = matches, tot
            continue #0 matches for this key
        
        B_events = B[chan]
        for evt in A_events:
            if match_naive(evt, B_events): 
                matches+= 1

        proportions[chan] = matches, tot
    
    return proportions    


#Requieres input is not empty
#min_chan_tot is because it makes no sense to use proportions if total is too low.
#for example 3 events of 6 is 0.5 and the test would fail, but its just because the
#total amount is too low.
def min_proportion(proportions_by_chan, min_chan_tot=1):
    min_m, min_tot = INFINITY, 1 #the first will replace it
    for chan, p in proportions_by_chan.items():
        matches, tot = p
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
    proportions_by_chan = proportion_of(A, B,)
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

def print_count_by_channel(O_events, E_events, original_chanlist, obtained_basename, expected_basename):
    
    opened_by_chan= ['Channel Name', 
                     'Channel ID', 
                     'Event count in ' + obtained_basename,
                     'Event count in ' + expected_basename]
    rows_chan_count = []
    for i in range(len(original_chanlist)):
        chan_name = original_chanlist[i]
        chan_id = i+1
        o_evt_count = 0 if chan_id not in O_events.keys() else len(O_events[chan_id]) 
        e_evt_count = 0 if chan_id not in E_events.keys() else len(E_events[chan_id])
        o_evt_count_str, e_evt_count_str = highlight_max(o_evt_count, e_evt_count)           
        r_i_chan_count = [chan_name, str(chan_id), o_evt_count_str, e_evt_count_str ]
        rows_chan_count.append(r_i_chan_count)

    sep = '---------------------'
    rows_chan_count.append([sep, sep, sep, sep])

    O_tot = sum([len(evts) for evts in O_events.values()])
    E_tot = sum([len(evts) for evts in E_events.values()])
    o_tot_str, e_tot_str = highlight_max(O_tot, E_tot)
    rows_chan_count.append(['Total count', str(" "), o_tot_str, e_tot_str])

    print("\nEvent count by channel...")
    print("\n"+tabulate( rows_chan_count, headers=opened_by_chan, tablefmt='orgtbl'))

def print_proportions(O_events, E_events, original_chanlist, obtained_basename, expected_basename):

    proportions= ['Channel Name', 
                  'Channel ID', 
                  'Proportion of ' + obtained_basename + " events\n that are also in "+ expected_basename,
                  'Proportion of ' + expected_basename + " events\n that are also in "+ obtained_basename]
    
    O_prop_by_chan = proportion_of(O_events, E_events)
    E_prop_by_chan = proportion_of(E_events, O_events)
    rows_chan_prop = []
    for i in range(len(original_chanlist)):
        chan_name = original_chanlist[i]
        chan_id = i+1
        o_evt_prop = 100.0 if chan_id not in O_events.keys() else (O_prop_by_chan[chan_id][0]/O_prop_by_chan[chan_id][1]) * 100 
        e_evt_prop = 100.0 if chan_id not in E_events.keys() else (E_prop_by_chan[chan_id][0]/E_prop_by_chan[chan_id][1]) * 100
        o_evt_prop_str, e_evt_prop_str = highlight_max(o_evt_prop, e_evt_prop)
        r_i_chan_prop = [chan_name, str(chan_id), o_evt_prop_str, e_evt_prop_str ]
        rows_chan_prop.append(r_i_chan_prop)

    sep = '---------------------'
    rows_chan_prop.append([sep, sep, sep, sep])
   
    O_matches, O_chan_events = min_proportion(O_prop_by_chan, min_chan_tot=1)
    E_matches, E_chan_events = min_proportion(E_prop_by_chan, min_chan_tot=1)
    obt_prop_exp_min = O_matches/O_chan_events
    exp_prop_obt_min = E_matches/E_chan_events
    obt_prop_exp_str, exp_prop_obt_str = highlight_max(obt_prop_exp_min, exp_prop_obt_min) 
    rows_chan_prop.append(['Minimum proportion', str(" "), obt_prop_exp_str, exp_prop_obt_str])

    print("\nProportions of one in the other...")
    print("\n"+tabulate( rows_chan_prop, headers=proportions, tablefmt='orgtbl'))

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

    O_events = read_events(obtained_fn)
    E_events = read_events(expected_fn)
    print_count_by_channel(O_events, E_events, original_chanlist, obtained_basename, expected_basename)
    print_proportions(O_events, E_events, original_chanlist, obtained_basename, expected_basename)

    subset_res = " is a subset of " if subset(O_events, E_events) else " is not a subset of " 
    print("\nWith a tolerance of "+ str(delta*100) + " percent, "+ obtained_basename + subset_res + expected_basename)

    subset_res = " is a subset of " if subset(E_events, O_events) else " is not a subset of " 
    print("With a tolerance of "+ str(delta*100) + " percent, "+ expected_basename + subset_res + obtained_basename)

    dist = distance(O_events, E_events)
    print("\nThe distance between the event files is: "+ str(dist))


