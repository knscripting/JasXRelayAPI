/*
    Very basic call-response-example



    If you want to support both traditional RLV stripping OR jasx relay

    like RLV the JasX relay works best when we can get information from either system.
    RLV will tell us what outfits the target is wearing, the JasX relay does the same but simpler.

    Since this is a call/response relationship we have to provide a "timeout"

    By default we want to use jasX relay cause it's better :)

    

    
*/


//!!! Set this to your preprocessor Directory !!!
// see: https://wiki.firestormviewer.org/fs_preprocessor
#include "_jasx_relay_lib.lsl"

default
{
    touch_end(integer num)
    {
         jasxRelaySend(llDetectedKey(0),-111111,"query",""); 
    }
    
    timer() {
        
        if (jSlots > 0 ){ //jSlots has a value above 0. So we got a response and there's clothing that can be stripped. 
            jasxRelaySend(llDetectedKey(0),-111111,"auto","-1");
        } else 
        if (jSlots == -1) {//We never received a repsonse, use another method to strip.
            // RLV Strip command or system you use
        }
    }

    state_entry()
    {
        jSlots = -1 ; // jSlots is a bitwise integer returned from the jasX relay. If jasX responds this number will be between 0-682
        llSetText("Query",<1,1,1>,1.0);
        llListen(-111111,"","",""); //Listen on this channel to the JasX Relay
    }

    listen (integer chan, string name, key id, string message) {
        //optional if you want to hear the response
        if (chan == -111111) {
            jSlots = (integer)llJsonGetValue(message, [SLOTS]);
        }
        llSetTimerEvent(1.0); //Give the relay a second to respond then perform the action.
    }
}
