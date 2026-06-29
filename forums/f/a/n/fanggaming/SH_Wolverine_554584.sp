#include <sourcemod>
#include <sdktools>
#include "SHSource/SHSource_Interface.inc"

#pragma semicolon 1
// Requires you do put ; after every line

new heroID; // Define the variable globally to store your hero's id
new Handle:cvarGravity,Handle:cvarSpeed,Handle:cvarHealth,Handle:cvarRTime,Handle:cvarRHealth;
new Handle:gTimer[MAXPLAYERS+1][2];


public Plugin:myinfo = 
{
  name = "SHSource Hero: Wolverine",
  author = "fanggaming",
  description = "A mutant, Wolverine possesses animal-keen senses, enhanced physical capabilities, and a healing factor that allows him to recover from virtually any wound.",
  version = "1.0",
  url = "http://www.marvel.com/universe/Wolverine_(James_Howlett)"
};
 
public OnSHPluginReady()
{
  heroID=SH_CreateHero("Wolverine","wolverine","Move Fast, Jump High and Heal over time!","5","0");
  HookEvent("player_hurt",PlayerHurt); // Hook the player hurt event
  cvarGravity=CreateConVar("wolverine_gravity","0.30");   
  cvarSpeed=CreateConVar("wolverine_speed","1.30");
  cvarHealth=CreateConVar("wolverine_health","175");
  cvarRTime=CreateConVar("wolverine_regentime","2");
  cvarRHealth=CreateConVar("wolverine_regenhealth","1");
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
    }
    else
    {
      SH_SetMinGravity(client,1.0);
      SH_SetMaxSpeed(client,1.0);
      SH_SetMaxHealth(client,100);
    }
  }
}


public PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
  new victim=GetClientOfUserId(GetEventInt(event,"userid"));
  if(SH_GetHasHero(victim,heroID)&&SH_IsAlive(victim))
  {
    gTimer[victim][0]=CreateTimer(GetConVarFloat(cvarRTime),HealthRegen_Done,victim);
  }
}

public Action:HealthRegen_Done(Handle:timer,any:index)
{
  CoolDown(index);
}

public CoolDown(victim)
{
  new hp=GetClientHealth(victim)+GetConVarInt(cvarRHealth);
  if(hp <= GetConVarInt(cvarHealth))
  {
    SH_SetHealth(victim,hp);
    gTimer[victim][0]=CreateTimer(GetConVarFloat(cvarRTime),HealthRegen_Done,victim);
  }
  else
  {
    SH_SetHealth(victim,GetConVarInt(cvarHealth));
    if(IsValidHandle(gTimer[victim][0]))
    CloseHandle(gTimer[victim][0]);
    gTimer[victim][0]=INVALID_HANDLE; // Erase timer handle
  }
}
