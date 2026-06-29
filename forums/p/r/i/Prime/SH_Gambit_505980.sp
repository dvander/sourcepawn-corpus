#include <sourcemod>
#include <sdktools>
#include <SHSource_Interface>

#pragma semicolon 1
// Requires you do put ; after every line

new heroID; // Define the variable globally to store your hero's id

new Handle:cvarDamage; // Create a variable to store the cvar's handle

public Plugin:myinfo = 
{
  name = "SHSource Hero: Gambit",
  author = "Prime",
  description = "Throw Powerful Gambit Grenades",
  version = "1.0",
  url = ""
};
 
public OnSHPluginReady()
{
  heroID=SH_CreateHero("Gambit","GambitGrenade","The HEgrenades you buy are 9 times more powerful than normal.","5","0"); // Create my hero
  HookEvent("player_hurt",PlayerHurt); // Hook the plyer hurt event
  cvarDamage=CreateConVar("gambit_dmgmult","10.0"); // Create a cvar to control the damage multiplier
}

public PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
  decl String:weapon[64];
  GetEventString(event,"weapon",weapon,64);
  if(StrEqual(weapon,"weapon_hegrenade"))
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