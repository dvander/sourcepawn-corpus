#include <sourcemod>
#include <sdktools>
#include <SHSource_Interface.inc>

#pragma semicolon 1
// Requires you do put ; after every line

new heroID; // Define the variable globally to store your hero's id

new Handle:cvarDamage; // Create a variable to store the cvar's handle

public Plugin:myinfo = 
{
  name = "SHSource Hero: Machete",
  author = "Prime",
  description = "An international mercenary",
  version = "1.0",
  url = "http://www.marveldatabase.com/Machete"
};
 
public OnSHPluginReady()
{
  heroID=SH_CreateHero("Machete","machete","Become more skilled with a knife and do more damage to your enemies!","6","0"); // Create my hero
  HookEvent("player_hurt",PlayerHurt); // Hook the plyer hurt event
  cvarDamage=CreateConVar("machete_dmgmult","2.0"); // Create a cvar to control the damage multiplier
}

public PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
  decl String:weapon[64];
  GetEventString(event,"weapon",weapon,64);
  if(StrEqual(weapon,"weapon_knife"))
  {
    new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
    new victim=GetClientOfUserId(GetEventInt(event,"userid"));
    if(SH_GetHasHero(attacker,heroID))
    {
      new damage=GetEventInt(event,"dmg_health");
      SH_SetHealth(victim,GetClientHealth(victim)+damage); // first, give them their health back
      new new_dmg=RoundToNearest(float(damage)*GetConVarFloat(cvarDamage));
      SH_SetHealth(victim,GetClientHealth(victim)-new_dmg); // take the multiplied damage away
    }
  }
}