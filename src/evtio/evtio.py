import os
import sys
from os.path import expanduser
sys.path.insert(0, os.path.expanduser("~") + '/ez-detect/src/main')
import config
import scipy.io
from lxml import etree as eTree
import uuid
import time
from datetime import datetime, timedelta
from dateutil import parser as dateutil_parser
from trcio import read_raw_trc

def _newGuidString():
    return str(uuid.uuid4())

def _fixFormat(aDateTime):
    #Format requiered by Micromed acording to documentation examples.
    return aDateTime.strftime('%Y-%m-%dT%H:%M:%S') + aDateTime.strftime('.%f')[:7] + 'Z'

def _buildEventTree():
    
    now = _fixFormat(datetime.utcnow())  
    root = eTree.Element("EventFile", Version="1.00", 
                         CreationDate=now, Guid=_newGuidString())
    evt_types = eTree.SubElement(root, "EventTypes")
    category = eTree.SubElement(evt_types, "Category", Name="HFO")
    
    eTree.SubElement(category, "Description").text = "HFO Category"
    eTree.SubElement(category, "IsPredefined").text = "true"
    eTree.SubElement(category, "Guid").text = config.HFO_CATEGORY_GUID
    hfoCategory = eTree.SubElement(category, "SubCategory", Name="HFO")
    
    eTree.SubElement(hfoCategory, "Description").text = "HFO Subcategory"
    eTree.SubElement(hfoCategory, "IsPredefined").text = "true"
    eTree.SubElement(hfoCategory, "Guid").text = config.HFO_SUBCATEGORY_GUID

    _defineHFOType(parentElem=hfoCategory, name="HFO Spike", 
                  type_guid=config.DEF_HFO_SPIKE_GUID, description="HFO Spike Event Definition", 
                  text_color="4294901760", graph_color="805306623")


    _defineHFOType(parentElem=hfoCategory, name="HFO Ripple", 
                  type_guid=config.DEF_HFO_RIPPLE_GUID, description="HFO Ripple Event Definition",
                  text_color="4294901760", graph_color="822018048")

    
    _defineHFOType(parentElem=hfoCategory, name="HFO FastRipple",
                  type_guid=config.DEF_HFO_FASTRIPPLE_GUID, description="HFO FastRipple Event Definition",
                  text_color="4294901760", graph_color="805371648")

    #Create Events label empty to append annotations later.
    events = eTree.SubElement(root, "Events")

    return eTree.ElementTree(root)

def _defineHFOType(parentElem, name, type_guid, description, text_color, graph_color):

    anHFOtype = eTree.SubElement(parentElem, "Definition", Name=name)
    
    eTree.SubElement(anHFOtype, "Guid").text = type_guid
    eTree.SubElement(anHFOtype, "Description").text = description
    eTree.SubElement(anHFOtype, "IsPredefined").text = "true"
    eTree.SubElement(anHFOtype, "IsDefinitionAdjustable").text = "false"
    eTree.SubElement(anHFOtype, "CanInsert").text = "true"
    eTree.SubElement(anHFOtype, "CanDelete").text = "true"
    eTree.SubElement(anHFOtype, "CanUpdateText").text = "true"
    eTree.SubElement(anHFOtype, "CanUpdatePosition").text = "true"
    eTree.SubElement(anHFOtype, "CanReassign").text = "false"
    eTree.SubElement(anHFOtype, "InsertionType").text = "ClickAndDrag"
    eTree.SubElement(anHFOtype, "FixedInsertionDuration").text = "PT1S"
    eTree.SubElement(anHFOtype, "TextType").text = "FromDefinitionDescription"
    eTree.SubElement(anHFOtype, "ReferenceType").text = "SingleLine"
    eTree.SubElement(anHFOtype, "DurationType").text = "Interval"
    eTree.SubElement(anHFOtype, "TextArgbColor").text = text_color
    eTree.SubElement(anHFOtype, "GraphicArgbColor").text = graph_color
    eTree.SubElement(anHFOtype, "GraphicType").text = "FillRectangle"
    eTree.SubElement(anHFOtype, "TextPositionType").text = "Top"
    eTree.SubElement(anHFOtype, "VisualizationType").text = "TextAndGraphic"
    eTree.SubElement(anHFOtype, "FontFamily").text = "Segoe UI"
    eTree.SubElement(anHFOtype, "FontSize").text = "11"
    eTree.SubElement(anHFOtype, "FontItalic").text = "false"
    eTree.SubElement(anHFOtype, "FontBold").text = "false"

#Why some kinds are marked as spike and ripple or spike and fripple at the same time?.
def _append_annotations(eventsElem, events_matfile, rec_start_time, original_chanlist):

    if '_mp_' in events_matfile:
        chanlist_varname = 'monopolar_chanlist'
    elif '_bp_' in events_matfile:
        chanlist_varname = 'bipolar_chanlist'
    else:
        print("Error in xml_writer xml_append_annotations") #temporal
    #, variable_names=[chanlist_varname]
    modified_chanlist_dic = scipy.io.loadmat(events_matfile, variable_names=[chanlist_varname])
    modified_chanlist = modified_chanlist_dic[chanlist_varname] 

    _append_events(eventsElem, events_matfile, rec_start_time, ["TRonS", "ftTRonS", "FRonS", "ftFRonS"], 
                   config.DEF_HFO_SPIKE_GUID, config.spike_on_offset, config.spike_off_offset, 
                   original_chanlist, modified_chanlist)

    _append_events(eventsElem, events_matfile, rec_start_time, ["RonO", "TRonS"], 
                   config.DEF_HFO_RIPPLE_GUID, config.ripple_on_offset, config.ripple_off_offset, 
                   original_chanlist, modified_chanlist)

    _append_events(eventsElem, events_matfile, rec_start_time, ["ftRonO", "ftTRonS"], 
                   config.DEF_HFO_FASTRIPPLE_GUID, config.fripple_on_offset, config.fripple_off_offset,
                   original_chanlist, modified_chanlist)
    
def _append_events(eventsElem, events_matfile, rec_start_time, evt_type_vars, evt_type_guid,
                   on_offset, off_offset, original_chanlist, modified_chanlist):
    
    events = scipy.io.loadmat(events_matfile, variable_names=evt_type_vars)
    now = _fixFormat(datetime.utcnow())  
    for key in evt_type_vars:
        _appendEventsOfKind(key, events, rec_start_time, eventsElem, evt_type_guid, 
                            on_offset, off_offset, now, original_chanlist, modified_chanlist)

def _appendEventsOfKind(aKindOfEvent, events, rec_start_time, eventsElem, evt_def_guid, 
                        on_offset, off_offset, now, original_chanlist, modified_chanlist):
    #(Pdb) events['TRonS']  
    # import pdb; pdb.set_trace()
    #array([[(array([], shape=(0, 0), dtype=uint8), array([], shape=(0, 0), dtype=uint8), array([], shape=(0, 0), dtype=uint8), array([], shape=(0, 0), dtype=uint8), array([], shape=(0, 0), dtype=uint8), array([], shape=(0, 0), dtype=uint8), array([], shape=(0, 0), dtype=uint8), array([], shape=(0, 0), dtype=uint8))]],
    #dtype=[('channel', 'O'), ('freq_av', 'O'), ('freq_pk', 'O'), ('power_av', 'O'), ('power_pk', 'O'), ('duration', 'O'), ('start_t', 'O'), ('finish_t', 'O')])
    #Para acceder al arreglo de freq_pk tenes que hacer events[0][0][2] 
    channels = events[aKindOfEvent][0][0][0]
    if len(channels) > 0:

        for i in range(len(channels)):
            modified_channel_idx = channels[i][0] #index in modified_chanlist
            chan_name = modified_chanlist[0][modified_channel_idx - 1][0]
            channel_id = original_chanlist.index(chan_name) + 1 #assuming that start by 1 
            start_t = events[aKindOfEvent][0][0][6][i][0]
            finish_t = events[aKindOfEvent][0][0][7][i][0]
            begin = _fixFormat(rec_start_time + timedelta(seconds=start_t)+on_offset)
            end = _fixFormat(rec_start_time + timedelta(seconds=finish_t)+off_offset)

            evt = eTree.SubElement(eventsElem, "Event", Guid=_newGuidString() )
            eTree.SubElement(evt, "EventDefinitionGuid").text = evt_def_guid
            eTree.SubElement(evt, "Begin").text = begin
            eTree.SubElement(evt, "End").text = end
            eTree.SubElement(evt, "Value").text = "0"
            eTree.SubElement(evt, "ExtraValue").text = "0"
            eTree.SubElement(evt, "DerivationInvID").text = str(channel_id) #Channel number. Starting from 0 or 1? Guess that from 1. 
            eTree.SubElement(evt, "DerivationNotInvID").text = "0" #0 is referential. Channel num if bipolar. 
            eTree.SubElement(evt, "CreatedBy").text = "Shennan Weiss"
            eTree.SubElement(evt, "CreatedDate").text = now
            eTree.SubElement(evt, "UpdatedBy").text = "Shennan Weiss"
            eTree.SubElement(evt, "UpdatedDate").text = now

class EventFile():

    def __init__(self, fname):
        self.fname = fname
        self.xml_tree = _buildEventTree()

    def rename(self, new_fname):
        self.fname = new_fname

    def change_xml_tree(self, new_xml_tree):
        self.xml_tree = new_xml_tree

    def name(self):
        return self.fname

    def event_tree(self):
        return self.xml_tree

    # event is a dictionary with the following content
    #   begin: must have the format of _fixFormat function (standard UTC)
    #   end: must have the format of _fixFormat function (standard UTC)
    #   value: TODO
    #   extra_value: TODO
    #   derivationInvId: Channel number in original montage, starting by 1.
    #   derivationNotInvID: 0 for referential. A channel number if bipolar.
    #   createdBy: a username
    #   createdDate: a date in the same format as the other times.
    #   updatedBy: a username
    #   updatedDate: a date in the same format as the other times.
    def append_event(self, event):
        return
        #TODO when events come from python structures

def read_raw_evt(evt_fname):
    evt_file = EventFile(evt_fname)
    parser = eTree.XMLParser(remove_blank_text=True)
    xml_tree = eTree.parse(evt_fname, parser)
    evt_file.change_xml_tree(xml_tree)
    
    #test
    #tree = evt_file.event_tree()
    #tree.write('test'+evt_file.name(), encoding="utf-8", xml_declaration=True, pretty_print=True)

    return evt_file

def read_events(evt_fname):
    raw_evt = read_raw_evt(evt_fname)
    root = raw_evt.event_tree().getroot()
    eventsElem = root.find('Events')
    xml_events = eventsElem.findall('Event')
    events = dict()
    for event in xml_events:
        begin = dateutil_parser.parse( event.findtext('Begin') )
        end = dateutil_parser.parse( event.findtext('End') )
        channel = int( event.findtext('DerivationInvID') )
        if channel not in events.keys():
            events[channel] = [ (begin, end) ]
        else:
            events[channel].append( (begin, end) )
    
    return events

def write_evt(output_filename, trc_path, rec_start_time, original_chanlist):
    
    print(original_chanlist)
    
    evt_file = EventFile(output_filename)
    evt_tree = evt_file.event_tree()
    eventsElem = evt_tree.getroot().find("Events")
    for filename in os.listdir(config.paths['ez_top_out']):
        if filename != '.keep':
            _append_annotations(eventsElem, config.paths['ez_top_out']+filename, 
                                rec_start_time, original_chanlist)

    evt_tree.write(evt_file.name(), encoding="utf-8", xml_declaration=True, pretty_print=True)
