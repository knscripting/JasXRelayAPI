// Kehf Nelson 20241023  Example relay hud using
/*

This script acts as a functioning applier to jasx Relay commands.
Take the bits and pieces you need into your own project.

Please reach out if your have questions:
Kehf


*/

//!!! Set this to your preprocessor Directory !!!
// see: https://wiki.firestormviewer.org/fs_preprocessor
#include "_jasx_relay_lib.lsl"

integer listenJasx; 
integer listenJasxRelay; 

//Example Script
default {

    on_rez(integer startp) {
     
        llLinksetDataReset();
        llResetScript(); 
    }

    state_entry(){
        listenJasx=llListen(JASX_CHAN,"","","");
        getJasxInfo();
        listenJasxRelay=llListen(JASX_RELAY_CHAN,"","","");
        llOwnerSay("JasX Relay Handler Ready");

    }//entry

    listen (integer chan, string name, key id, string message)
    {
        //// Jasx Hud Listen
        if ((llGetOwnerKey(id) == llGetOwner()) && chan==JASX_CHAN ) {//Listen for the jasxHud to tell us what the current clothing levels are
            // DEBUG llOwnerSay("Jasx response: " + message);
    
            if (llGetSubString(message,0,5) == "outfit") {
                message = llGetSubString(message, 8, -1); //dump the tag, process out the rest of the JSON into lists
                jSlots = (integer)llJsonGetValue(message, [SLOTS]);
                jStrapon = (integer)llJsonGetValue(message, [STRAPON]);
                llLinksetDataWrite(JASX_LAST_OUTFIT,message);    
                //jasStats, makes it easy to parse all the outfit parts. Keeps a list of states, 2, 1 or ,0 corresponding to the clothing locations
                jasxStates = [
                    jasxSlotState(jSlots, SLOT_HEAD),
                    jasxSlotState(jSlots, SLOT_ARMS),
                    jasxSlotState(jSlots, SLOT_TORSO),
                    jasxSlotState(jSlots, SLOT_CROTCH),
                    jasxSlotState(jSlots, SLOT_BOOTS)  ];  
      
                jasxNextLogical2LSD();  // Set the next logical slots to strip or dress and save into LSD
                jasxResponseQueue(); //Run through a list of responses we need to make.      
            }else
            if (llGetSubString(message,0,5) == "settin"){
                message = llGetSubString(message, 9, -1); //dump the tag, process out the rest of the JSON into lists
                llLinksetDataWrite(JASX_LAST_SETTINGS,message); 
                jSex = (integer)llJsonGetValue(message, [SEX]);
                jSpecies = llJsonGetValue(message, [SPECIES]);
            }
        }
        else
        if (chan == JASX_RELAY_CHAN) { // JasX API relay
            //// DEBUG  llOwnerSay("Relay req:\n\t"+message);
            jasxRelay(message); //Processes the received command. 
                 
        }
    }
}
