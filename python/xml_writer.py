import config
import scipy.io
from lxml import etree as eTree
import uuid
from datetime import datetime, timedelta
from os import listdir
from trcio import read_raw_trc
def write_xml(output_filename):

    xml_set_event_types(output_filename)

    raw_trc = read_raw_trc('/home/tomas-pastore/EDFs/449_correct.TRC', preload=True, include=None)
    trc_header = raw_trc._raw_extras[0]
    rec_start_time = datetime( year = trc_header['rec_year'], month= trc_header['rec_month'],
                         day = trc_header['rec_day'], hour = trc_header['rec_hour'],
                         minute = trc_header['rec_min'], second = trc_header['rec_sec'])

    for filename in listdir(config.paths['ez_top_out']):
        if filename != '.keep':
            xml_append_annotations(output_filename, config.paths['ez_top_out']+filename, rec_start_time)


def newGuidString():
    return str(uuid.uuid4())

def fixFormat(aDateTime):
    #Format requiered by Micromed acording to documentation examples.
    return aDateTime.strftime('%Y-%m-%dT%H:%M:%S') + aDateTime.strftime('.%f')[:7] + 'Z'

def xml_set_event_types(xml_filename):

    now = fixFormat(datetime.utcnow())  
    
    root = eTree.Element("EventFile", Version="1.00", CreationDate=now, Guid=newGuidString() )
    evt_types = eTree.SubElement(root, "EventTypes")
    category = eTree.SubElement(evt_types, "Category", Name="HFO")
    
    eTree.SubElement(category, "Description").text = "HFO Category"
    eTree.SubElement(category, "IsPredefined").text = "true"
    eTree.SubElement(category, "Guid").text = config.HFO_CATEGORY_GUID
    hfoCategory = eTree.SubElement(category, "SubCategory", Name="HFO")
    
    eTree.SubElement(hfoCategory, "Description").text = "HFO Subcategory"
    eTree.SubElement(hfoCategory, "IsPredefined").text = "true"
    eTree.SubElement(hfoCategory, "Guid").text = config.HFO_SUBCATEGORY_GUID

    defineHFOType(parentElem=hfoCategory, name="HFO Spike", 
                  type_guid=config.DEF_HFO_SPIKE_GUID, description="HFO Spike Event Definition", 
                  text_color="4294901760", graph_color="805306623")


    defineHFOType(parentElem=hfoCategory, name="HFO Ripple", 
                  type_guid=config.DEF_HFO_RIPPLE_GUID, description="HFO Ripple Event Definition",
                  text_color="4294901760", graph_color="822018048")

    
    defineHFOType(parentElem=hfoCategory, name="HFO FastRipple",
                  type_guid=config.DEF_HFO_FASTRIPPLE_GUID, description="HFO FastRipple Event Definition",
                  text_color="4294901760", graph_color="805371648")

    #Create Events label empty to append annotations later.
    events = eTree.SubElement(root, "Events")

    tree = eTree.ElementTree(root)
    tree.write(xml_filename, encoding="utf-8", xml_declaration=True, pretty_print=True)

def defineHFOType(parentElem, name, type_guid, description, text_color, graph_color):

    anHFOtype = eTree.SubElement(parentElem, "Definition", Name=name)
    
    eTree.SubElement(anHFOtype, "Guid").text = type_guid
    eTree.SubElement(anHFOtype, "Description").text = description
    eTree.SubElement(anHFOtype, "IsPredefined").text = "true"
    eTree.SubElement(anHFOtype, "isDefinitionAdjustable").text = "false"
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
    eTree.SubElement(anHFOtype, "VisualizationType").text = "Graphic"
    eTree.SubElement(anHFOtype, "FontFamily").text = "Segoe UI"
    eTree.SubElement(anHFOtype, "FontSize").text = "11"
    eTree.SubElement(anHFOtype, "FontItalic").text = "false"
    eTree.SubElement(anHFOtype, "FontBold").text = "false"


#Why some kinds are marked as spike and ripple or spike and fripple at the same time?.
def xml_append_annotations(xml_file, events_matfile, rec_start_time):

    #Parti en 3 por si las variables que se cargan de matlab ocupan mucha memoria, despues vemos.
    append_events(xml_file, events_matfile, rec_start_time, ["TRonS", "ftTRonS", "FRonS", "ftFRonS"], 
                  config.DEF_HFO_SPIKE_GUID, config.spike_on_offset, config.spike_off_offset)

    append_events(xml_file, events_matfile, rec_start_time, ["RonO", "TRonS"], 
                  config.DEF_HFO_RIPPLE_GUID, config.ripple_on_offset, config.ripple_off_offset)

    append_events(xml_file, events_matfile, rec_start_time, ["ftRonO", "ftTRonS"], 
                  config.DEF_HFO_FASTRIPPLE_GUID, config.fripple_on_offset, config.fripple_off_offset)
    
def append_events(xml_file, events_matfile, rec_start_time, evt_type_vars, evt_type_guid, on_offset, off_offset):
    
    parser = eTree.XMLParser(remove_blank_text=True)
    tree = eTree.parse(xml_file, parser)
    root = tree.getroot()
    events = scipy.io.loadmat(events_matfile, variable_names=evt_type_vars)
    
    now = fixFormat(datetime.utcnow())  

    for key in evt_type_vars:
        appendEventsOfKind(key, events, rec_start_time, xml_file, tree, root, 
                           evt_type_guid, on_offset, off_offset, now)

def appendEventsOfKind(aKindOfEvent, events, rec_start_time, xml_file, tree, root, 
                       evt_def_guid, on_offset, off_offset, now):

    if len(events[aKindOfEvent]['channel']) > 0:

        for i in range(len(events[aKindOfEvent]['channel'])):
            channel = events[aKindOfEvent]['channel'][i][0]
            begin = fixFormat(rec_start_time + timedelta(seconds=events[aKindOfEvent]['start_t'][i][0])+on_offset)
            end = fixFormat(rec_start_time + timedelta(seconds=events[aKindOfEvent]['finish_t'][i][0])+off_offset)

            evt = eTree.SubElement(root.find("Events"), "Event", Guid=newGuidString() )
            eTree.SubElement(evt, "EventDefinitionGuid").text = evt_def_guid
            eTree.SubElement(evt, "Begin").text = begin
            eTree.SubElement(evt, "End").text = end
            eTree.SubElement(evt, "Value").text = "0"
            eTree.SubElement(evt, "ExtraValue").text = "0"
            eTree.SubElement(evt, "DerivationInvID").text = str(channel) #review this. Shennan was adding +63 in matlab code, but the doc says it is the channel reference
            eTree.SubElement(evt, "DerivationNotInvID").text = "0"
            eTree.SubElement(evt, "CreatedBy").text = "Shennan Weiss"
            eTree.SubElement(evt, "CreatedDate").text = now
            eTree.SubElement(evt, "UpdatedBy").text = "Shennan Weiss"
            eTree.SubElement(evt, "UpdatedDate").text = now

            tree.write(xml_file, encoding="utf-8", xml_declaration=True, pretty_print=True)
            
    