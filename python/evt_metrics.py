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
from evtio import read_events

# INPUT: an increasingly ordered by begin interval list: [(begin, end)], 
#        aBegin is a number as the ones in the intervals
# OUTPUT: The index where an interval with begin == aBegin 
# can be inserted to mantain the order of the list of intervals.
# Time Complexity: O(Log(N)) with N = number of intervals to review     
def binarySearch(interval, intervals):
    if len(intervals) == 0 : 
        return 0

    return binarySearchRec(interval, intervals, 0, len(intervals)-1)

def binarySearchRec(interval, intervals, low, high):
    if high <= low: 
        return low+1 if (interval >= intervals[low]) else low 
  
    mid = low + (high-low) // 2
    otherInterval = intervals[mid]

    if(interval == otherInterval ): 
        return mid+1 
    elif(interval > otherInterval): 
        return binarySearchRec(interval, intervals, mid+1, high)
    else: 
        return binarySearchRec(interval, intervals, low, mid-1)

#Returns true if the interval w overlaps with any interval in I
#Time Complexity: O(Log(N)) with N = number of intervals to review 
def binary_match(w, I):
    if len(I) == 0 :
        return False

    begin_idx = 0
    end_idx = 1
    index = binarySearch(w, I)

    if index == 0:
        prev = (-INFINITY,-INFINITY) #If there is no prev, makes that match fail
        next = I[index]
    elif index == len(I):
        prev = I[index-1]
        next = (INFINITY, INFINITY) #If there is no next, makes that match fail
    else: 
        prev = I[index -1]
        next = I[index]

    return w[begin_idx]<= prev[end_idx] or w[end_idx] >= next[begin_idx]

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
        begin_overlap = w_i[begin_idx] <= w[begin_idx] <= w_i[end_idx]
        end_overlap = w_i[begin_idx] <= w[end_idx] <= w_i[end_idx]
        if begin_overlap or end_overlap:
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
        B_events.sort() #order them by begin time  
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

def printMetrics(obtained_fn, expected_fn, delta=0.1):
    O_events = read_events(obtained_fn)
    E_events = read_events(expected_fn)

    O_tot = sum([len(evts) for evts in O_events.values()])
    E_tot = sum([len(evts) for evts in E_events.values()])
    print("\nTotal amount of events of "+ obtained_fn + " "+ str(O_tot) )
    print("Total amount of events of "+ expected_fn + " "+ str(E_tot) )
    
    print("\nDetail of amount by channel")

    print("\n" + obtained_fn + ": \n")
    for chan, events in O_events.items():
        print( str(chan) + " --> " + str(len(events)) )
    
    print("\n" + expected_fn + ": \n")
    for chan, events in E_events.items():
        print( str(chan) + " --> " + str(len(events)) )

    print("\nPrinting proportions...")
    O_prop_by_chan = proportion_of(O_events, E_events)
    E_prop_by_chan = proportion_of(E_events, O_events)
    print("\n" + obtained_fn + ": \n")
    for chan, p in O_prop_by_chan.items():
        m, tot = p
        print( str(chan)+" --> "+str(m)+"/"+str(tot)+" = "+str(m/tot) )

    print("\n" + expected_fn + ": \n")
    for chan, p in E_prop_by_chan.items():
        m, tot = p
        print( str(chan)+" --> "+str(m)+"/"+str(tot)+" = "+str(m/tot) )
    
    subset_res = " is a subset of " if subset(O_events, E_events) else " is not a subset of " 
    print("\nWith tolerance == "+ str(delta)+ ", "+ obtained_fn + subset_res + expected_fn)

    subset_res = " is a subset of " if subset(E_events, O_events) else " is not a subset of " 
    print("With tolerance == "+ str(delta)+ ", "+ expected_fn + subset_res + obtained_fn)

    dist = distance(O_events, E_events)
    print("\nThe distance between both subsets with tolerance == "+ str(delta) + " is: "+ str(dist))
    dist_bool = dist <= delta
    print("Is distance <= delta == "+ str(delta) + "? "+ str(dist_bool))


