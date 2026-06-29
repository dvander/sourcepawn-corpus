// Beast - Run faster, jump higher, extra health and extra armor.

/* CVARS - copy and paste to shconfig.cfg
//Beast
beast_level 3
beast_gravity 0.30			//Gravity
beast_speed 1.2                     //Running speed
beast_health 175				//Starting health
beast_armor 175				//Starting armor
*/

#include <sourcemod>
#include "SHSource/SHSource_Interface.inc"
new heroID;
new Handle:cvarSpeed,Handle:cvarHealth,Handle:cvarArmor;

public Plugin:myinfo = 
{
	name = "Beast",
	author = "CloudStrife",
	description = "Speed/Gravity/HP/AP",
	version = "0.1",
}

public OnSHPluginReady()
{
    heroID=SH_CreateHero("Beast","beast","Speed/Gravity/HP/AP","3","0");
    cvarGravity=CreateConVar("beast_gravity","0.30");   
    cvarSpeed=CreateConVar("beast_speed","1.2");
    cvarHealth=CreateConVar("beast_health","175");
    cvarArmor=CreateConVar("beast_armor","175");
}

public OnHeroChanged(client,hero,bool:has)
{
    if(hero==heroID)
    {
        if(has)
        {
            SH_SetMinGravity(client,GetConVarFloat(cvarGravity));
            SH_SetMaxSpeed(client,GetConVarFloat(cvarSpeed));
            SH_SetMaxHealth(client,GetConVarInt(cvarHealth));
            SH_SetMaxArmor(client,GetConVarInt(cvarArmor));
        }
        else
        {
            SH_SetMinGravity(client,1.0);
            SH_SetMaxSpeed(client,1.0);
            SH_SetMaxHealth(client,100);
            SH_SetMaxArmor(client,0);
        }
    }
}