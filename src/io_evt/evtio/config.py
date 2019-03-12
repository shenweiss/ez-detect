# EVENT FILE CONFIGURATION (XML .evt FILE)

from datetime import timedelta

# MICROMED | BRAINQUICK DEFINES
HFO_CATEGORY_GUID = "27e2727f-e49d-4113-aa8c-4944ef8f2588"
HFO_SUBCATEGORY_GUID = "c142e214-826e-4dfe-965a-110246492c9e"
DEF_HFO_RIPPLE_GUID = "167b6fad-f95a-4880-a9c6-968f468a1297"
DEF_HFO_FASTRIPPLE_GUID = "e0a58c9c-b3c0-4a7d-a3c3-d3ed6a57dc3a"
DEF_HFO_SPIKE_GUID = "bf513752-2cb7-43bc-93f5-370def800b93"

ripple_kind = 'Ripple'
fastRipple_kind = 'FastRipple'
spike_kind = 'Spike'

event_kind_by_guid = {
	DEF_HFO_RIPPLE_GUID : ripple_kind,
	DEF_HFO_FASTRIPPLE_GUID : fastRipple_kind,
	DEF_HFO_SPIKE_GUID : spike_kind
}

event_guid_by_kind = {
	ripple_kind : DEF_HFO_RIPPLE_GUID,
	fastRipple_kind : DEF_HFO_FASTRIPPLE_GUID,
	spike_kind : DEF_HFO_SPIKE_GUID
}

#Gaps of time before and after events
spike_on_offset = - timedelta(seconds=0.02)
spike_off_offset = + timedelta(seconds=0.01)
ripple_on_offset = - timedelta(milliseconds=5)
ripple_off_offset = + timedelta(milliseconds=5)
fripple_on_offset = - timedelta(milliseconds=2.5)
fripple_off_offset = + timedelta(milliseconds=2.5)
        