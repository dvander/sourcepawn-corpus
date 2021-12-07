#include <sourcemod>
#include "SHSource/SHSource_Interface"

#pragma semicolon 1

new heroID;
new Handle:cvarMinAlpha;
new Handle:cvarMaxAlpha;
new Handle:cvarAlphaDifference;

new Float:gLastLoc[MAXPLAYERS+1][3];

public OnSHPluginReady()
{
  heroID=SH_CreateHero("Invisible Woman","invisiwoman","Become less visible to all players","0","0");  // Make hero
  // Hook events
  HookEvent("player_spawn",PlayerSpawnEvent);
  // Create cvars
  cvarMinAlpha=CreateConVar("invisiwoman_minalpha","10","The minimum alpha of the Invisible Woman (0-255, 0 being completely invisible)");
  cvarMaxAlpha=CreateConVar("invisiwoman_maxalpha","150","The maxmimum alpha of the Invisible Woman (0-255, 0 being completely invisible)");
  cvarAlphaDifference=CreateConVar("invisiwoman_alphadifference","5","How much Invisible Woman's alpha changes per half second"); 
}

public OnConfigsExecuted()
{
  CreateTimer(0.5,CheckPlayers,0,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnHeroChanged(client,hero,bool:has)
{
  if(heroID==hero)
  {
    if(has)
      SH_SetMinVisibility(client,GetConVarInt(cvarMaxAlpha));
    else
      SH_SetMinVisibility(client,255);
  }
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
  if(index&&SH_GetHasHero(index,heroID))
    SH_SetMinVisibility(index,GetConVarInt(cvarMinAlpha));
}

public Action:CheckPlayers(Handle:timer)
{
  new maxplayers=GetMaxClients();
  for(new x=1;x<=maxplayers;x++)
  {
    if(IsClientInGame(x)&&SH_IsAlive(x)&&SH_GetHasHero(x,heroID))
    {
      new Float:clientloc[3];
      GetClientAbsOrigin(x,clientloc);
      if(SH_DistanceBetween(gLastLoc[x],clientloc)>1.0)
      {
        new alpha=SH_GetMinVisibility(x)-GetConVarInt(cvarAlphaDifference);
        if(alpha<GetConVarInt(cvarMinAlpha))
          alpha=GetConVarInt(cvarMinAlpha);
        SH_SetMinVisibility(x,alpha);
      }
      else
      {
        new alpha=SH_GetMinVisibility(x)+GetConVarInt(cvarAlphaDifference);
        if(alpha>GetConVarInt(cvarMaxAlpha))
          alpha=GetConVarInt(cvarMaxAlpha);
        SH_SetMinVisibility(x,alpha);
      }
      gLastLoc[x][0]=clientloc[0];
      gLastLoc[x][1]=clientloc[1];
      gLastLoc[x][2]=clientloc[2];
    }
  }
}