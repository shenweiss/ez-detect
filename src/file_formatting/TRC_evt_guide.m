function [event_guide_string]=TRC_evt_guide
      entry_1=lower(sdec2hex(randi(1e9,1),8));
      entry_2=lower(sdec2hex(randi(9e3,1),4));
      entry_3=lower(sdec2hex(randi(9e3,1),4));
      entry_4=lower(sdec2hex(randi(9e3,1),4));
      entry_5=lower(sdec2hex(randi(1e13,1),12));
      event_guide_string=[entry_1 '-' entry_2 '-' entry_3 '-' entry_4 '-' entry_5];


      
      