/*  

2024 10 22  Kehf Nelson      

Thanks to Jas for creating JasX Games and Tools
https://github.com/JasXSL

-The purpose of this relay is to allow objects to interact quickly with a user's jasx outfit.

Naturally a working JasX outfit is required, and the user or "target" has the jasX hud 0.6.0+
active and enabled

This script should serve as a template and example of how you can choose to interact with it.

The Relay works on channel -188455 responding to a standard listen

---Command Structure 
-The command format is a json consisting of:

RESPOND-To-UUID --  RESPOND-To-Channel (any channel that is not 0 ) -- COMMAND -- COMMAND_Option

Example touch Query in an object:

    touch_end(integer num)
    {
        jasxRelaySend(llDetectedKey(0),-111111,"query","");     //Sends Query

        // returns:   {"target":"d8cd5b84-b010-427e-CCCC-9c96b925b3aa","slots":682,"strapon":0,"sex":1,"species":"Dingo"}
        
        jasxRelaySend(llDetectedKey(0),-111111,"auto","-1");   //Sends strips next logical layer

        // returns:   {"target":"d8cd5b84-b010-427e-CCCC-9c96b925b3aa","slots":681,"strapon":0,"sex":1,"species":"Dingo"}

        jasxRelaySend(llDetectedKey(0),-111111,"setclothes","bits/crotch");

        // returns:   {"target":"d8cd5b84-b010-427e-CCCC-9c96b925b3aa","slots":554,"strapon":0,"sex":1,"species":"Dingo"}

    }

    ** See details below

    Query Returns to the sending object on channel -111111 the result of query
    
    {"target":"d8cd5b84-b010-427e-CCCC-9c96b925b3aa","slots":682,"strapon":0,"sex":1,"species":"Dingo"
    translated: 
    Kehf's UUID | Clothing State Full Dressed | Strapon False | Has Boy Parts | Is a Dingo
    *** Every command will return the full state of the target. 

Notes:
Slots: Jasx Hud returns outfits in a bitwise integer.
    682 is fully dressed
    341 is Underwear
    0 is naked
    -1 Means no JasX Info, or Bad Command sent 
    ** see code examples for quick functions to determine what is what

-188455: Proposed API Relay listen channel

targetId: variable for the UUID of the Agent you send the request to

JSON. JSON is hard, I know it, you know it, it isn't easy to work with but in talking with Jas
he highly recommends it as things are going to change with the JasX hud beyond 0.6.0....

To make your code and builds semi-future proof we are going ot use JSON stead of passing delimited lists.

The below code will have examples you can copy paste to handle the object - agent communications
The example will have parts of the Relay itself, and examples lines you can copy paste into
objects. 

TLDR; Commands are sent in json, respones are returned in json reflecting the change from the command. 

Relay API Commands: (Note llDetectedKey(0) is used here assuming this is in a touch, could be a collision, etc)

query:  Query returns helpful info from the jasx hud with no change to outfit
    jasxRelaySend(llDetectedKey(0),-111111,"query",""); 

auto: Strips or dresses next logical clothing item Requires a parameter 1 or -1
    jasxRelaySend(llDetectedKey(0),-111111,"auto","-1");
    jasxRelaySend(llDetectedKey(0),-111111,"auto","1");

setclothes: Works just like it does in the Jasx Hud  LEVEL/SLOT  ex Dressed/Arms
    jasxRelaySend(llDetectedKey(0),-111111,"setclothes","dressed/arms");
    jasxRelaySend(llDetectedKey(0),-111111,"setclothes","underwear"); 
    
strapon: Sets the strapon to 1 or 0
    jasxRelaySend(llDetectedKey(0),-111111,"strapon","1");
    jasxRelaySend(llDetectedKey(0),-111111,"strapon","0");

----    
What you cannot do

    Set Outfit, get outfit names, set sex, or change jasx Settings. These things are considered intrusive.
*/

// ==========================
//Recommended Global Vars 
list respondTo = [] ; //Dirty List of Lists responses to send
//Usually set on receipt from JasX hud in a listen. 
//Required for jasxResponseQueue() 
integer jSlots ;
integer jStrapon ;
integer jSex ; 
string  jSpecies ;
list jasxStates=[]; 

//Listen Channel Constants
#define JASX_CHAN 2 
#define JASX_RELAY_CHAN -188455

//LSD keys to save responses from jasX hud, and next logial dress or strips. Feel free to change these
#define JASX_LAST_OUTFIT "TMP_JASX_LAST_OUTFIT"
#define JASX_LAST_SETTINGS "TMP_JASX_LAST_SETTINGS"
#define JASX_NEXT_DRESS "TMP_JASX_NEXT_DRESS"
#define JASX_NEXT_STRIP "TMP_JASX_NEXT_STRIP"

//Give names to the numbers so we can keep them straight
#define SLOT_HEAD 0
#define SLOT_ARMS 1
#define SLOT_TORSO 2
#define SLOT_CROTCH 3
#define SLOT_BOOTS 4
#define STATE_ORDER ["bits","underwear","dressed"]
#define jasxSlots ["head", "arms", "torso", "crotch", "boots"]

//Returns the state of a slot. ex: What level of dress is the torso
#define jasxSlotState(slots, slot) ((slots>>(slot*2))&3)

//The logical order is how you would get dressed or undressed naturally
//Stripping Crotch is always last
//Dressing it is first. 
//The order is  HEAD,BOOTS,ARMS,TORSO,CROTCH
//Reversed for Dressing
//Coresponds with indexs of jasxSlots list above
#define LOGICAL_SLOT_ORDER [0,4,1,2,3]

//jasx Defines for mySex other snips of jasx Code. Handy for you to have
// Ex: Integer of 7. I have all the parts.  Integer of 6 I just have boobs and a Vagina. 
#define SEX_PENIS 1
#define SEX_VAGINA 2
#define SEX_BREASTS 4

//JSON KEYS used in the Relay. 
//  All Caps is #define shorthand for the actual string keyword 
//  Sending back response keys
#define SLOTS "slots"
#define STRAPON "strapon"
#define SEX "sex"
#define SPECIES "species"

//  Sending command keys
#define TARGET "target"
#define RCHAN "chan"
#define COMMAND "command"
#define CDATA "cdata"

// Quick Json Commands to process from the relay

//Json Get and Set. Quick short hand to get data from a json string or put something in one
//If you want the first entry of an array it's just jGet(array, 0) or if it's assoc jGet(obj, "key")
//Ex:  jGet(somejsonstring,SEX) returns "7"  meaning this user has all sex flags set, 1, 2, and 4
//     jGet(somejsonString,SLOTS) returns "682" meaning this user is fully dressed.  
#define jGet(data, path) llJsonGetValue(data, (list)path)

//re-writes a json data with a key path set to Value
//Ex:  jSet(somejsonString,COMMAND,"query");  sets the command key in somejsonString to "query"
#define jSet(data, path, value) data = llJsonSetValue(data,(list)path,value)

//JasX Json Keys and quick commands
// These examples are here to help you work with the json string returned by the query
// They assume you are using this file as an include and so all the globals #defined
// are active and in use. If you deviate you need to change this info.

/*
takes the relevant json data elements and returns json string

EXAMPLE: llRegionSayTo(target-UUID,-2222,jasx2JsonResponse(jSlots,jStrapon,jSex,jSpecies) );
 Where jSlots, jStrapon, jSex are global integers you use and mySpecies is the string of species. 
 jasx2JsonResponse is used by targets JASX API Relay */

#define jasx2JsonResponse(slots,strapon,sex,species)\
    llList2Json(JSON_OBJECT,[ TARGET, (string)llGetOwner(), SLOTS, slots, STRAPON, strapon, SEX, sex, SPECIES, species ]) 

/* EXAMPLE: 
On the receiving side of the above response you can do something like this
string jx = message; //where message is something you get from a listen or lsd data
integer exSlots = (integer)jGet(jx,SLOTS);
integer exSex = (integer)jGet(jx,SEX);
integer exStrapon = (integer)jGet(jx,STRAPON);
string exSpecies = jGet(jx,SPECIES);
*/

//Send to an Agents relay
#define jasxRelaySend(id,chan,command,command_data)\
    llRegionSayTo(id,JASX_RELAY_CHAN,llList2Json(JSON_OBJECT,[TARGET, llGetKey(), RCHAN, chan, COMMAND, command, CDATA, command_data]))

/*
On the receiving side of above you could do something like this in a listen
    We breakout the JSON and send it to the jasX relay for processing

    msg = the message of the listen
    
    jasXRelay(jGet(msg,TARGET), jGet(msg,RCHAN), jGet(msg,COMMAND));
*/

//Reuqests outfit info and settings, can be called by anyone if users JasX hud is set visible
#define getJasxInfo() \
    llRegionSayTo(llGetOwner(), 1, "jasx.getoutfitinfo");\
    llRegionSayTo(llGetOwner(), 1, "jasx.settings");

// ==== #included functions
// -- JASX API System Example. 
/*
    Two example functions here: 
    jasxRelay() inbound handlers
    jasxRespondTo() handles the response

    There is a delay in with the jasx hud performing tasks and querying back
    usually about .5-2 seconds.

    The jasxRelay() example will attempt to perform the command immediatly
    sending a response to the initiator a few seconds later.

    These examples use a crude "dirty" list and function that triggers when 
    the JasX hud responds.

    You can code a resposne anyway you wish, just be sure to follow the API

*/
// ---------------------------------------------------------------------------
/* ====  JasX Relay Handler 

    Usually this bit of code is on the Agent/User side

*/
//Process the commands supported by the relay API. 
jasxRelay(string msg){
    string jOutfit = llLinksetDataRead(JASX_LAST_OUTFIT);
    integer chan = (integer)jGet(msg,RCHAN);
    key id = (key)jGet(msg,TARGET);
    //Special Case, We need data from both queries, if nothing in either, send the error
    if (jOutfit == "") { //There is no jasX info recorded from the jasx hud outfit req
        //Return -1 error codes for all values. 
        llRegionSayTo(id,chan,  jasx2JsonResponse("-1","-1","-1",""));
        return; //nothing else to do. Escape out of jasxRelay
    }

    //string jSettings = llLinksetDataRead(JASX_LAST_SETTINGS);
    string response = "" ; //Used as a "scratch" string and a flag to determine if the relay will respond to command. 
    string command = jGet(msg,COMMAND);
    string command_data = jGet(msg,CDATA);

    ////Debug llOwnerSay("jasxRelay \n"+command + " " +command_data + "\ntarget: "+llKey2Name(id) +"\nchan: "+(string)chan); 

    //The LSD keys used here can be changed to what you want. See Example Scripts. 
    //DebugllOwnerSay("JasxRelay from: "+(string)id + " Respond to: "+(string)chan + " Request: "+msg );

    //We have data to work with from LSD, process the command request

    switch (command) {
        case "auto": { 
            //The stripping process automatically sets the next logical strip state into LSD
            //Auto will just apply the result depending on the value passed to it in CDATA
            if ((integer)command_data > 0 ) {
                response = llLinksetDataRead(JASX_NEXT_DRESS);
            }else {
                response = llLinksetDataRead(JASX_NEXT_STRIP);
            }
            //llOwnerSay(response);
            if (response != "") { //We have data in next logical step
                llRegionSayTo(llGetOwner(), 1, "jasx.setclothes "+response);
                response = "1";
            }else { //No data in next logical step, can't do anything
                response = "" ;
            }
            break;
        }

        case "setclothes": {
            llRegionSayTo(llGetOwner(), 1, "jasx.setclothes " + command_data); 
            response = "1" ;
            break;
        }

        case "strapon": {
            llRegionSayTo(llGetOwner(), 1, "jasx.setstrapon "+ command_data);
            response = "1" ;
            break;
        }

        case "query": { //No function to do but query the JasX hud and send it back
            response = "1";
            break;
        }

        default: {// Bad command, no response
            response = "";
            chan = 0; 
        }
    }//Switch

    //Setup Response List.
    if (( chan != 0 ) && (response != "")) { //must be something and somewhere to respond to
        respondTo += (string)id+"$"+(string)chan; //Add response to dirty list queue for processing on next JasX Hud response
        getJasxInfo() ; //Query jasx Hud 
        
        //Debug llOwnerSay("My Response: "+llList2String(respondTo,0));
    }
}//Jasx Relay Handler

// ---------------------------------------------------------------------------
//Runs after each channel 2 response from the jasx hud probably in a listen, see Example scripts
//...Example of how you could do this
jasxResponseQueue() {

    integer length = llGetListLength(respondTo);
    integer idx = 0 ;
    while (idx < length) {
        list tmp = llParseString2List(llList2String(respondTo,0),["$"],[]);
        llRegionSayTo(llList2Key(tmp,0),llList2Integer(tmp,1), jasx2JsonResponse(jSlots,jStrapon,jSex,jSpecies)  );
        ++idx;

        ////DEBUG llOwnerSay("jasxResponQ:\n"+llList2String(tmp,0) + "chan: "+llList2String(tmp,1) +"\n"+jasx2JsonResponse(jSlots,jStrapon,jSex,jSpecies) );
    }
    respondTo =[];
}

// ---------------------------------------------------------------------------
jasxNextLogical2LSD() { 
    /*Converts jasx SLOT integer  to a list of usable strings to strip or dress in LOGICAL_SLOT_ORDER

    Output is sent to LSD as 
    "KN_JASX_NEXT_STRIP" or "KN_JASX_NEXT_DRESS" respectively
    the value for the LSD key is something like  bits/arms or dressed/arms
    if arms were currently set to underwear. 

    */
    integer pIdx=4 ; //Part index
    string t;
    integer sIdx = -1; 
    integer dIdx = -1;
    integer test ;
    integer high = -1;
    integer low = 2 ;

    while (pIdx >= 0 ) {
        test = jasxSlotState(jSlots,llList2Integer(LOGICAL_SLOT_ORDER,pIdx));

        if ( test == 2 ){
            high = test;
            sIdx = pIdx ;
        }else 
        if ( (test == 1) ){
            //if (high != 2) { //No two found so far, this is the highest strip value
            if (high < 2 ){
                high = 1 ;
                sIdx=pIdx;
            }

            if (low == 2 ) { //If we haven't hit a 0 or set anything yet
                low = 1 ;
                dIdx=pIdx;
            }
        }else
        if (test == 0){ //This state is empty and should be considered for dressing
             //since we are working backwards for getting dressed, only set the 1st found low
             if (low >= 1 ){
                low = 0;
                dIdx = pIdx;
             }
        }
        --pIdx;
    } //while 

    if (sIdx > -1 ) { //sIdx changed here's the new option
        llLinksetDataWrite(JASX_NEXT_STRIP, llList2String(STATE_ORDER,(high-1))+"/"+llList2String(jasxSlots,llList2Integer(LOGICAL_SLOT_ORDER,sIdx)));
    }else{
        llLinksetDataWrite(JASX_NEXT_STRIP,""); //No logical next, set to null
    }//sIdx

    if (dIdx > -1 ) {//dIdx changed
        llLinksetDataWrite(JASX_NEXT_DRESS, llList2String(STATE_ORDER,(low+1))+"/"+llList2String(jasxSlots,llList2Integer(LOGICAL_SLOT_ORDER,dIdx)));  
    }else {
        llLinksetDataWrite(JASX_NEXT_DRESS,""); //No logical next, set to null
    }//dIdx

    //DEBUG llOwnerSay(llLinksetDataRead("KN_JASX_NEXT_STRIP") + " Nexts " +llLinksetDataRead("KN_JASX_NEXT_DRESS"))  ;
}


