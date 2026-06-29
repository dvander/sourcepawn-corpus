// SUPERMAN! - Yeah - well not all of his powers or it'd be unfair...

/* CVARS - copy and paste to shconfig.cfg
//Superman
superman_level 0
superman_gravity 0.35			//Gravity
superman_health 150				//Starting health
superman_armor 150				//Starting armor
*/

#include <sourcemod>
#include <SHSource/SHSource_Interface.inc>
new heroID;
new Handle:cvarHealth,Handle:cvarArmor,Handle:cvarGravity;

public Plugin:myinfo = 
{
	name = "SUPERHERO Superman",
	author = "jtpizzalover/{HOJ} Batman",
	description = "Port of superman by {HOJ} Batman.",
	version = "1.2",
	url = "http://team-nu.com"
}

public OnSHPluginReady()
{
    heroID=SH_CreateHero("Superman","superman","Health/Armor/Gravity","0","0");
    cvarGravity=CreateConVar("superman_gravity","0.35");
    cvarHealth=CreateConVar("superman_health","150");
    cvarArmor=CreateConVar("superman_armor","150");
}

public OnHeroChanged(client,hero,bool:has)
{
    if(hero==heroID)
    {
        if(has)
        {
            SH_SetMaxHealth(client,GetConVarInt(cvarHealth));
            SH_SetMinGravity(client,GetConVarFloat(cvarGravity));
            SH_SetMaxArmor(client,GetConVarInt(cvarArmor));
        }
        else {
            SH_SetMinGravity(client,1.0);
            SH_SetMaxHealth(client,100);
            SH_SetMaxArmor(client,100);
       }
    }
}