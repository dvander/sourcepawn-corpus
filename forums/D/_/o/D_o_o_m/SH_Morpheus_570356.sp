/**
 * Credits:
 * Freecode - Original author of Morpheus CS 1.6
 * PimpinJuice - For his Cola Lover Code and for the plugin itself
 * Prime - For his Machete Hero (Damage part)
 */

#include <sourcemod>
#include <sdktools>
#include "SHSource/SHSource_Interface.inc"

new heroID;
new Handle:cvarGravity,Handle:cvarDamage;

public OnSHPluginReady()
{
    heroID = SH_CreateHero("Morpheus","Dual MP5's","Lower Gravity/Dual MP5's/Unlimited Ammo","8","0");
    cvarGravity = CreateConVar("morpheus_gravity","0.35");
    cvarDamage = CreateConVar("morpheus_mp5mult","2.0");
    HookEvent("player_hurt",PlayerHurt);
}

public OnHeroChanged(client,hero,bool:has)
{
    if(hero==heroID)
    {
        if(has)
        {
            SH_SetMinGravity(client,GetConVarFloat(cvarGravity));
            GivePlayerItem(client,"weapon_mp5navy",0);
        }
        else
        {
            SH_SetMinGravity(client,1.0);
        }
    }
}

public PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
  	decl String:weapon[64];
  	GetEventString(event,"weapon",weapon,64);
  	if(StrEqual(weapon,"weapon_mp5navy"))
  	{
    	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
    	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
    	if(SH_GetHasHero(attacker,heroID))
    	{
      	new damage = GetEventInt(event,"dmg_health");
      	SH_SetHealth(victim,GetClientHealth(victim)+damage);
      	new new_dmg = RoundToNearest(float(damage)*GetConVarFloat(cvarDamage));
      	SH_SetHealth(victim,GetClientHealth(victim)-new_dmg);
    	}
  	}
}