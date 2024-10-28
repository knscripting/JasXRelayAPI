
//!!! Set this to your preprocessor Directory !!!
// see: https://wiki.firestormviewer.org/fs_preprocessor
#include "_jasx_relay_lib.lsl"


default
{
    touch_end(integer num)
    {
        //// Examples of the various commands the simplest implementation
         jasxRelaySend(llDetectedKey(0),-111111,"query",""); 
         //jasxRelaySend(llDetectedKey(0),-111111,"setclothes","underwear");   
         //jasxRelaySend(llDetectedKey(0),-111111,"auto","-1");
         //jasxRelaySend(llDetectedKey(0),-111111,"auto","1");
         //jasxRelaySend(llDetectedKey(0),-111111,"setclothes","bits/crotch");
    }
    
    state_entry()
    {
        llSetText("Query",<1,1,1>,1.0);
        llListen(-111111,"","","");
    }

    listen (integer chan, string name, key id, string message) {
        //optional if you want to hear the response
        if (chan == -111111) {
            
        llOwnerSay( "JasX Relay Response\n\tchan: "+(string)chan
            +"\n\tname: "+name
            +"\n\tid: "+(string)id
            +"\n\tmessage: "+message );
        }
    }
}
