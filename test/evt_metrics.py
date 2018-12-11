#!/usr/bin/env python3
# -*- coding: utf-8 -*-
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
from math import inf as INFINITY
from dateutil.tz import tzutc
from datetime import datetime
from os.path import basename, splitext, expanduser
from tabulate import tabulate

import sys
import os
sys.path.insert(0, os.path.abspath('../src/main'))
from evtio import read_events

MIN_DATETIME = datetime.min.replace(tzinfo=tzutc())
MAX_DATETIME = datetime.max.replace(tzinfo=tzutc())

#temp until we get montage from trc
import scipy.io
def loadChansFromMontage(trc_filename, chans_num):

    filename = os.path.basename(trc_filename)
    filename = os.path.splitext(filename)[0]
    montage_filename = os.path.expanduser("~") + '/hfo_engine_1/montages/' + filename + '_montage.mat'
    aDic = scipy.io.loadmat(montage_filename)
    chanlist = [aDic['montage'][i][0][0] for i in range(chans_num) ]
    return chanlist

# INPUT: an increasingly ordered by begin interval list: [(begin, end)], 
#        aBegin is a number as the ones in the intervals
# OUTPUT: The index where an interval with begin == aBegin 
# can be inserted to mantain the order of the list of intervals.
# Time Complexity: O(Log(N)) with N = number of intervals to review     
def binary_search(interval, intervals):
    #print("trying to match")
    #print(interval)
    #print("with one here:")
    #for i in intervals:
    #    print(i)

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
def min_proportion(proportions_by_chan):
    min_m, min_tot = INFINITY, 1 #the first will replace it
    for chan, p in proportions_by_chan.items():
        matches, tot = p
        if matches/tot < min_m/min_tot:
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
    matches, tot = min_proportion(proportions_by_chan)

    return 1 - matches/tot <= delta

#Requiere neither A nor B are empty
def distance(A, B):
    A_prop_by_chan = proportion_of(A, B)
    B_prop_by_chan = proportion_of(B, A)

    matches_A, tot_A = min_proportion(A_prop_by_chan)
    matches_B, tot_B = min_proportion(B_prop_by_chan)
    A_min_p = matches_A / tot_A
    B_min_p = matches_B / tot_B
   
    return 2 - (A_min_p + B_min_p)
 
#INPUT: Two evt filenames, O is obtained and E is expected
# delta is the tolerance for similarity tests.

#como hago para que un path pueda ser ingresado como relativo o absoluto (shell)
def print_metrics(obtained_fn, expected_fn, delta=0.1):
    O_events = read_events(obtained_fn)
    E_events = read_events(expected_fn)

    obtained_basename = splitext(basename(obtained_fn))[0] 
    expected_basename = splitext(basename(expected_fn))[0] 
    O_tot = sum([len(evts) for evts in O_events.values()])
    E_tot = sum([len(evts) for evts in E_events.values()])

    #Highlighting max, make a function later
    if(O_tot > E_tot): 
        o_tot_str = '\x1b[6;30;42m' + str(O_tot) + '\x1b[0m'
    else:
        o_tot_str = str(O_tot)

    if(E_tot > O_tot): 
        e_tot_str = '\x1b[6;30;42m' + str(E_tot) + '\x1b[0m'
    else:
        e_tot_str = str(E_tot)

    original_chanlist = loadChansFromMontage('/home/tomas-pastore/hfo_engine_1/449_correct.trc', 66)
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
        
        #Highlighting max, make a function later
        if(o_evt_count > e_evt_count): 
            o_evt_count_str = '\x1b[6;30;42m' + str(o_evt_count) + '\x1b[0m'
        else:
            o_evt_count_str = str(o_evt_count)
        
        if(e_evt_count > o_evt_count): 
            e_evt_count_str = '\x1b[6;30;42m' + str(e_evt_count) + '\x1b[0m'
        else:
            e_evt_count_str = str(e_evt_count)
        
        r_i_chan_count = [chan_name, str(chan_id), o_evt_count_str, e_evt_count_str ]
        rows_chan_count.append(r_i_chan_count)
    sep = '---------------------'
    rows_chan_count.append([sep, sep, sep, sep])
    rows_chan_count.append(['Total count', str(" "), o_tot_str, e_tot_str])
    print("\nEvent count by channel...")
    print("\n"+tabulate( rows_chan_count, headers=opened_by_chan, tablefmt='orgtbl'))

    print("\nProportions of one in the other...")
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
        
        #Highlighting max, make a function later
        if(o_evt_prop > e_evt_prop): 
            o_evt_prop_str = '\x1b[6;30;42m' + str(o_evt_prop) + '\x1b[0m'
        else:
            o_evt_prop_str = str(o_evt_prop)
        
        if(e_evt_prop > o_evt_prop): 
            e_evt_prop_str = '\x1b[6;30;42m' + str(e_evt_prop) + '\x1b[0m'
        else:
            e_evt_prop_str = str(e_evt_prop)
        
        r_i_chan_prop = [chan_name, str(chan_id), o_evt_prop_str, e_evt_prop_str ]
        rows_chan_prop.append(r_i_chan_prop)
    sep = '---------------------'
    rows_chan_prop.append([sep, sep, sep, sep])
   
    O_matches, O_chan_events = min_proportion(O_prop_by_chan)
    E_matches, E_chan_events = min_proportion(E_prop_by_chan)
    #Highlighting max, make a function later
    
    obt_prop_exp = O_matches/O_chan_events
    exp_prop_obt = E_matches/E_chan_events

    if(obt_prop_exp > exp_prop_obt): 
        obt_prop_exp_str = '\x1b[6;30;42m' + str(obt_prop_exp) + '\x1b[0m'
    else:
        obt_prop_exp_str = str(obt_prop_exp)
    
    if(exp_prop_obt > obt_prop_exp): 
        exp_prop_obt_str = '\x1b[6;30;42m' + str(exp_prop_obt) + '\x1b[0m'
    else:
        exp_prop_obt_str = str(exp_prop_obt)

    rows_chan_prop.append(['Minimum proportion', str(" "), obt_prop_exp_str, exp_prop_obt_str])
    print("\n"+tabulate( rows_chan_prop, headers=proportions, tablefmt='orgtbl'))

    subset_res = " is a subset of " if subset(O_events, E_events) else " is not a subset of " 
    print("\nWith a tolerance of "+ str(delta*100) + " percent, "+ obtained_basename + subset_res + expected_basename)

    subset_res = " is a subset of " if subset(E_events, O_events) else " is not a subset of " 
    print("With a tolerance of "+ str(delta*100) + " percent, "+ expected_basename + subset_res + obtained_basename)

    dist = distance(O_events, E_events)
    print("\nThe distance between the event files is: "+ str(dist/2))


