
from ez_detect import config, hfo_annotate
import argparse


'''
Usage && INPUT arguments: type 'python3 hfo_annotate.py --help' in the shell
Example with defaults: python3 hfo_annotate.py --trc_path=449.TRC

'''
#448 sleep 600 1 thread --> 48 minutes in grito

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser()
    
    parser.add_argument("-in", "--trc_path", 
                        help="The directory path to the file with the data to analyze.",
                        required=True)
    
    parser.add_argument("-out", "--xml_output_path", 
                        help="Path where the .evt output will be created.",
                        required=False, default= config.paths['xml_output_path'])
    
    parser.add_argument("-pdir", "--project_dir_path", 
                        help="Path to the root directory of the project. This is"+
                        " used to set relative paths of saving directories.",
                        required=False, default= config.paths['project_root'])

    parser.add_argument("-str_t", "--start_time", 
                        help="An integer in seconds indicating from when, "+ 
                        "relative to the file duration, do you want to analyze the eeg.",
                        required=False, default= config.START_TIME_DEFAULT, type=int)
    
    parser.add_argument("-stp_t", "--stop_time", 
                        help="An integer number in seconds indicating up to when, relative"+
                        "to the file duration, do you want to analyze the eeg.",
                        required=False, default= config.STOP_TIME_DEFAULT, type=int) 

    parser.add_argument("-c", "--cycle_time", 
                        help="A number in seconds indicating the size of the blocks"+ 
                        "for the data to be cut. This improves time performance.",
                        required=False, default= config.CYCLE_TIME_DEFAULT, type=int)

    parser.add_argument("-sug", "--suggested_montage", 
                        help="The name of one of the montages included in the TRC that should "+
                        "be considered as base montage.",
                        required=False, default= 'Ref.')

    parser.add_argument("-bp", "--bipolar_montage", 
                        help="The name of one of the montages included in the TRC with a definition "+
                        "of a pair electrode for every channel that we "+
                        "want to allow to move from referential to bipolar montage .",
                        required=False, default= 'Bipolar')

    parser.add_argument("-saf", "--swap_array_file_path", 
                        help="This optional file should contain a swap_array"+
                        " variable, which can be used to correct the channel"+
                        " assignments in case that channels were incorrectly"+
                        " assigned in the original EDF file as can be the case"+
                        " for intraop", required=False, default= config.paths['swap_array_file']) 

    args = parser.parse_args()
    
    paths = config.getAllPaths(args.trc_path, args.xml_output_path,  
                               args.project_dir_path, args.swap_array_file_path)

    config.clean_previous_execution()
    hfo_annotate(paths, args.start_time, args.stop_time, args.cycle_time, 
                 args.suggested_montage, args.bipolar_montage)
