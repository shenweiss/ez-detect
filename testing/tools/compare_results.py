#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
#Usage: type 'python3 compare_results.py --help' in the shell

#Dependencies: In order to have support for matlab.engine module:
# 1) 'cd matlabroot/extern/engines/python'
# 2) 'python setup.py install' (may require sudo) 

import unittest
import matlab.engine
import sys
import argparse

class EqualMatfilesTest(unittest.TestCase):

    def setUp(self):
        print('Starting Matlab session...')
        eng = matlab.engine.start_matlab()
        print('Loading workspaces...')
        self.orig_workspace = eng.load(self.original)
        self.obtained_workspace = eng.load(self.obtained)        
        #Closing matlab session
        eng.quit()

    def assertDeepAlmostEqual(self, expected, actual, *args, **kwargs):
        #Assert that two complex structures have almost equal contents.
        #Compares lists, dicts and tuples recursively. Checks numeric values
        #using test_case's :py:meth:`unittest.TestCase.assertAlmostEqual` and
        #checks all other values with :py:meth:`unittest.TestCase.assertEqual`.
        #Accepts additional positional and keyword arguments and pass those
        #intact to assertAlmostEqual() (that's how you specify comparison
        #precision).
        is_root = not '__trace' in kwargs
        trace = kwargs.pop('__trace', 'ROOT')
        try:
            if isinstance(expected, (int, float, complex)):
                self.assertAlmostEqual(expected, actual, *args, **kwargs)
            elif isinstance(expected, (list, tuple)):
                self.assertEqual(len(expected), len(actual))
                for index in range(len(expected)):
                    v1, v2 = expected[index], actual[index]
                    self.assertDeepAlmostEqual(v1, v2, __trace=repr(index), 
                                              *args, **kwargs)
            elif isinstance(expected, dict):
                self.assertEqual(set(expected), set(actual))
                for key in expected:
                    self.assertDeepAlmostEqual(expected[key], actual[key],
                                          __trace=repr(key), *args, **kwargs)                    
            else:
                self.assertEqual(expected, actual)
        except AssertionError as exc:
            exc.__dict__.setdefault('traces', []).append(trace)
            if is_root:
                trace = ' -> '.join(reversed(exc.traces))
                exc = AssertionError("%s\nTRACE: %s" % (exc.__dict__, trace))
            raise exc

    def test_workspaces(self):
        self.assertDeepAlmostEqual(expected = self.orig_workspace,
                                   actual = self.obtained_workspace,
                                   delta = self.delta)
    
if __name__ == "__main__":
   
    parser = argparse.ArgumentParser()
    
    parser.add_argument("-o", "--original", 
                        help="Sets the filename of the original matfile", 
                        required=True)
    parser.add_argument("-t", "--obtained", 
                        help="Sets the filename of the matfile to be tested",
                        required=True)

    EqualMatfilesTest.delta = 0.000001 #1x10^-6 is default
    parser.add_argument("-d", "--delta", 
                        help="Sets the tolerance to determine equality between numbers. "+
                        "The difference between two given numbers will be checked to be less or equal "+
                        "than delta to pass the assertion. "+
                        "Default is: "+ str(EqualMatfilesTest.delta),
                        required=False)   

    args = parser.parse_args()
    
    EqualMatfilesTest.original = args.original
    EqualMatfilesTest.obtained = args.obtained

    if(args.delta):
        EqualMatfilesTest.delta = float(args.delta)
        sys.argv.pop()

    sys.argv.pop()
    sys.argv.pop()
    unittest.main()


