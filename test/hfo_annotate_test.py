# -*- coding: utf-8 -*-
import unittest

import ez_detect.config as config
from ez_detect.hfo_annotate import _calculate_block_amount


class hfoAnnotateTest(unittest.TestCase):
    def setUp(self):
        self.cycle_time_10_min = 600

        self.srate_2000hz = 2000

        snds_in_a_min = 60
        self.samples_2000hz_10_min = self.srate_2000hz * 10 * snds_in_a_min
        self.samples_2000hz_1_hour = self.srate_2000hz * 60 * snds_in_a_min

    def test_calculate_block_amount__single_block(self):
        blocks = _calculate_block_amount(self.srate_2000hz, self.cycle_time_10_min, self.samples_2000hz_10_min)
        self.assertEqual(blocks, 1)

    def test_calculate_block_amount__many_full_blocks(self):
        blocks = _calculate_block_amount(self.srate_2000hz, self.cycle_time_10_min, self.samples_2000hz_1_hour)
        self.assertEqual(blocks, 6)

    def test_calculate_block_amount__last_block_must_last_more_than_a_snds_constraint__take_last_block(self):
        n_samples = self.samples_2000hz_10_min + config.MIN_BLOCK_SNDS * self.srate_2000hz
        blocks = _calculate_block_amount(self.srate_2000hz, self.cycle_time_10_min, n_samples)
        self.assertEqual(blocks, 2)

    def test_calculate_block_amount__last_block_must_last_more_than_a_snds_constraint__drop_last_block(self):
        n_samples = self.samples_2000hz_10_min + config.MIN_BLOCK_SNDS * self.srate_2000hz - 1
        blocks = _calculate_block_amount(self.srate_2000hz, self.cycle_time_10_min, n_samples)
        self.assertEqual(blocks, 1)


if __name__ == "__main__":
    unittest.main()
