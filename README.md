# JasX Relay API
Make your JasX HUD Work with Anything

A supplimental package for devleopers to extend the interactivity with the JasX HUD. https://github.com/JasXSL/JasX-HUD

Thanks to Jas for the HUD and all those who helped with the design of this Relay API

The JasX HUD outfit system for Secondlife is a lovely bit of scripting that makes your avatar outfit near infinately configurable, stripable, and interractive. What it can't do is allow for easy access to other scripted objects. This relay API intends to fix that and offer creators a simple pathway to dress, strip avatars using a compatible JasX outfit.

Adding relay commands to your obejct can be as simple as a single line of code or for more advanced.

Included are the main relay #include library with a few functions for more robust implementations as well as example scripts detailing out processes.

Requred: 
-JasX Hud 0.6.0+  
-JasX Outfit
-A HUD or Script that houses this Relay API

Guides and free stuff:
JasX Setup Guide: https://drauslittlewebsite.com/jasx-account/
Free Outfit Stripper and Relay: https://marketplace.secondlife.com/p/JasX-Clothing-Ripper-Stripper/20211415

--- On to the API

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

        // returns:   {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":682,"strapon":0,"sex":1,"species":"Dingo"}
        
        jasxRelaySend(llDetectedKey(0),-111111,"auto","-1");   //Sends strips next logical layer

        // returns:   {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":681,"strapon":0,"sex":1,"species":"Dingo"}

        jasxRelaySend(llDetectedKey(0),-111111,"setclothes","bits/crotch");

        // returns:   {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":554,"strapon":0,"sex":1,"species":"Dingo"}

    }

    ** See details below

    Query Returns to the sending object on channel -111111 the result of query
    
    {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":682,"strapon":0,"sex":1,"species":"Dingo"
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
      
    Set Outfit, get outfit names, set sex, or change jasx Settings. These things are considered intrusive.

