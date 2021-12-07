/**
 * Credits:
 * sharky - Original author of Gohan CS 1.6
 * PimpinJuice - For his Cola Lover Code and for the plugin itself
 */

#include <sourcemod>
#include "SHSource/SHSource_Interface.inc"

new heroID;
new Handle:cvarSpeed,Handle:cvarGravity,Handle:cvarHealth,Handle:cvarHealthMax,Handle:cvarRegenInterval,Handle:cvarRegenHealth;
new maxClientCount;

public OnSHPluginReady()
{
    heroID = SH_CreateHero("Gohan","Super Power-Up","Start with more HP, gain even more each second. Also, has Ultra Speed and Low Gravity!","10","0");
    cvarSpeed = CreateConVar("gohan_speed","1.6");
    cvarGravity = CreateConVar("gohan_gravity","0.4");
    cvarHealth = CreateConVar("gohan_health","150");
    cvarHealthMax = CreateConVar("gohan_healmax","400");
    cvarRegenInterval = CreateConVar("gohan_regen_interval","2.0");
    cvarRegenHealth = CreateConVar("gohan_regen_health","10");
    CreateTimer(GetConVarFloat(cvarRegenInterval),RegenTimer);
    maxClientCount = GetMaxClients();
}

public OnHeroChanged(client,hero,bool:has)
{
    if(hero==heroID)
    {
        if(has)
        {
            SH_SetMaxSpeed(client,GetConVarFloat(cvarSpeed));
            SH_SetMinGravity(client,GetConVarFloat(cvarGravity));
            SH_SetMaxHealth(client,GetConVarInt(cvarHealth));
        }
        else
        {
            SH_SetMaxSpeed(client,1.0);
            SH_SetMinGravity(client,1.0);
            SH_SetMaxHealth(client,100);
        }
    }
}

public Action:RegenTimer(Handle:timer)
{
    for(new x=1;x<=maxClientCount;x++)
    {
        if(IsClientInGame(x)&& SH_IsAlive(x)&& SH_GetHasHero(x,heroID))
        {
            new max_hp = GetConVarInt(cvarHealthMax);
            new new_hp = GetClientHealth(x)+GetConVarInt(cvarRegenHealth);
            if(new_hp>max_hp)
                new_hp = max_hp;
            SH_SetHealth(x,new_hp);
        }
    }
    CreateTimer(GetConVarFloat(cvarRegenInterval),RegenTimer);
}