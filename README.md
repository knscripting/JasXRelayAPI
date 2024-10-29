
# JasX Relay API
Bring smart, fast, and consistent clothing stripping/dressing to Secondlife Builds without the hassel of direct RLV scripting.

A complimentary library to the JasX HUD. https://github.com/JasXSL/JasX-HUD

Thanks to Jas for the HUD and all those who helped with the design of this Relay API

=====
TLDR; Commands are sent in json, respones are returned in json reflecting the change from the command. 

Relay API Commands: (Note llDetectedKey(0) is used here assuming this is in a touch, could be a collision, sensor, etc)
```
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

Responses always look like:
{"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":682,"strapon":0,"sex":1,"species":"Dingo"}
```
====== 

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

The Relay works on channel -188455 responding to a listen channel you specify.

---Command Structure 
-The command format is a json consisting of:

RESPOND-To-UUID --  RESPOND-To-Channel (any channel that is not 0 ) -- COMMAND -- COMMAND_Option

Example touch Query in an object:
```
touch_end(integer num)
{
    jasxRelaySend(llDetectedKey(0),-111111,"query","");     //Sends Query
    // returns:   {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":682,"strapon":0,"sex":1,"species":"Dingo"}
        
    jasxRelaySend(llDetectedKey(0),-111111,"auto","-1");   //Sends strips next logical layer
    // returns:   {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":681,"strapon":0,"sex":1,"species":"Dingo"}

    jasxRelaySend(llDetectedKey(0),-111111,"auto","1");   /Dresses to the next logical layer
    // returns:   {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":682,"strapon":0,"sex":1,"species":"Dingo"}

    jasxRelaySend(llDetectedKey(0),-111111,"setclothes","bits/crotch");
    // returns:   {"target":"d1aa3f00-b010-427e-CCCC-9c96b925b3aa","slots":554,"strapon":0,"sex":1,"species":"Dingo"}
}
```
Notes:
Slots: Jasx Hud returns outfits in a bitwise integer.
    682 is fully dressed on all parts
    341 is fully underwear on all parts
    0 is fully naked on all parts
        Any other combination is the bitwise combined states of all the parts.
    -1 Means no JasX Info, or Bad Command sent 
    ** see _jasx_relay_lib.lsl for more details.

-188455: Proposed API Relay listen channel

targetId: variable for the UUID of the Agent you send the request to

auto -1 strips the next logical layer, the layers are HEAD,BOOTS,ARMS,TORSO,CROTCH in that order to whatever set is most dressed.

auto 1 dresses with the same logic in reverse, working from the CROTCH to head from the lowest dress level up.

Commands and responses are all sent in JSON for future proofing against the JasX hud's changes. The library contains #define macros to making working with JSON easier. 

The below library and LSL scripts have examples on usage and implementation. If you have questions at any time please reach out directly in game.

What you cannot do: Set Outfit, get outfit names, set sex, or change jasx Settings.
These things are considered intrusive.


