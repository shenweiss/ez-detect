import config
import numpy as np #temp for the temp function

#temporary while translating from matlab to python, the final one is build_montage_from_trc
def build_montage_mat_from_trc(montages, ch_names, sug_montage_name, bp_montage_name):

    sug_lines = montages[sug_montage_name]['lines']
    bp_lines = montages[bp_montage_name]['lines']
    sug_defs = [def_pair for def_pair in montages[sug_montage_name]['inputs'][:sug_lines] ]
    bp_defs = [def_pair for def_pair in montages[bp_montage_name]['inputs'][:bp_lines]]
    def_ch_names_sug = [pair[1] for pair in sug_defs ] 
    def_ch_names_bp = [pair[1] for pair in bp_defs ] 
    
    try:
        assert(set(ch_names) == set(def_ch_names_sug))
    except AssertionError:
        logger.info("The 'Suggested montage' is badly formed, you must provide a definition" +
                    " for each channel name that appears in the 'Ref.'' montage.")
        assert(False)

    montage = []
    for ch_name in ch_names: #First col of montage.mat
        sug_idx = def_ch_names_sug.index(ch_name)
        suggestion = config.REFERENTIAL if sug_defs[sug_idx][0] == 'AVG' else config.BIPOLAR #Second col of montage.mat  

        if suggestion == config.BIPOLAR: #Third col of montage .mat
            if sug_defs[sug_idx][0] == ch_name: #For now we mean exclusion in this way
                bp_ref = config.NO_BP_REF
                exclude = config.EXCLUDE_CH
            else: 
                #Note that we know by the previous conditions that the index exists.
                #That string is defined inside BQ and its value is 'AVG' or another
                #ch_name that we have asserted that is in ch_names.
                bp_ref = ch_names.index(sug_defs[sug_idx][0]) + 1 
                exclude = config.DONT_EXCLUDE_CH

        else: #suggestion == config.REFERENTIAL
            exclude = 0
            try: 
                bp_idx = def_ch_names_bp.index(ch_name)
                bp_ref = ch_names.index(bp_defs[bp_idx][0]) + 1
            except ValueError: #user didn't defined a bp pair for this channel
                bp_ref = config.NO_BP_REF

        chan_montage_info = tuple([ch_name, suggestion, bp_ref, exclude])
        montage.append(chan_montage_info)

    return np.array(montage, dtype=object)

#Returns an object of EzMontage class
def build_montage_from_trc(montages, ch_names, sug_montage_name, bp_montage_name):

    sug_lines = montages[sug_montage_name]['lines']
    bp_lines = montages[bp_montage_name]['lines']
    sug_defs = [def_pair for def_pair in montages[sug_montage_name]['inputs'][:sug_lines] ]
    bp_defs = [def_pair for def_pair in montages[bp_montage_name]['inputs'][:bp_lines]]
    def_ch_names_sug = [pair[1] for pair in sug_defs ] 
    def_ch_names_bp = [pair[1] for pair in bp_defs ] 

    sug_as_ref = set()
    sug_as_bp = set()
    sug_as_excluded = set()
    pair_references = dict()

    try:
        assert(set(ch_names) == set(def_ch_names_sug))

    except AssertionError:
        raise ValueError('The Suggested montage is badly formed, you must provide a definition' +
                         ' for each channel name that appears in the Ref. montage.')

    montage = []
    for i in range( sug_lines ):
        ch_name = sug_defs[i][1]

        if sug_defs[i][0] == ch_name:
            sug_as_excluded.add( ch_names.index(ch_name) )

        elif sug_defs[i][0] == 'AVG' or sug_defs[i][0] == 'G2':
            sug_as_ref.add( ch_names.index(ch_name) )
            if ch_name in def_ch_names_bp and  bp_defs[def_ch_names_bp.index(ch_name)][0] != 'AVG': #user wants to cover a possible movement to bp 
                pair_references[i] = ch_names.index( bp_defs[def_ch_names_bp.index(ch_name)][0] )              

        elif sug_defs[i][0] in ch_names:
            sug_as_bp.add( ch_names.index(ch_name) )
            pair_references[i] = ch_names.index(sug_defs[i][0])

        else:
            raise ValueError('Incorrect definition in suggested montage.')

    return EzMontage(ch_names, sug_as_ref, sug_as_bp, sug_as_excluded, pair_references)

class EzMontage(): 
   
  #INPUT:
  # ch_names must be equal to raw['ch_names'] (the order in Ref. montage and eeg_data signals)
  # sug_as_ref, sug_as_bp and sug_as_excluded are disjoint sets of the ch_ids (indexes) in ch_names
  # The union of the above three sets conform the ch_names set, thus (ref U bp U excluded) == range( len (ch_names) )
  # pair_references are also channel ids for every channel that is not excluded and that may be taken as bipolar (not
  # only the ones suggested as bipolar but also the suggested as referential, that you want to allow ez-detect to move to bipolar montage
  # if necessary) 
    def __init__(self, ch_names, sug_as_ref, sug_as_bp, sug_as_excluded, pair_references):
        try:

            #Disjoint sets
            assert( not sug_as_ref.intersection(sug_as_bp).intersection(sug_as_excluded)) 
            #Union conform ch_names
            assert( list( range(len(ch_names)) ) == list(sug_as_ref.union(sug_as_bp).union(sug_as_excluded)) )
            #Definitions of pair_references are for ref or bp channels, not excluded. 
            #It is user responsibility to define well the pairs for these keys.
            for k in pair_references.keys(): 
                assert(k in sug_as_ref.union(sug_as_bp))

            self.ch_names = ch_names
            self.sug_as_ref = sug_as_ref
            self.sug_as_bp = sug_as_bp
            self.sug_as_excluded = sug_as_excluded
            self.pair_references = pair_references

        except AssertionError:
            raise ValueError('Value error in EzMontage constructor. Read class notes')
    
    def id(self, ch_name):
        return self.ch_names.index(ch_name)

    def name(self, ch_id):
        return self.ch_names[ch_id]

    def is_sug_monopolar(self, ch_id):
        return ch_id in self.sug_as_ref

    def is_sug_bipolar(self, ch_id):
        return ch_id in self.sug_as_bp

    def is_excluded(self, ch_id):
        return ch_id in sug_as_excluded

    def supports_bp(self, ch_id):
        return ch_id in self
