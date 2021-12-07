#include <sourcemod>
#include <sdktools>
#include "SHSource/SHSource_Interface"

#pragma semicolon 1

new heroID;
new Handle:cvarCooldown;
new Handle:cvarTime;
new Handle:cvarDarkness;
new Handle:cvarSkyName;

new String:dSkyName[32];

new bool:gIsDark;
new bool:gCooledDown[MAXPLAYERS+1];
new Handle:gTimer[MAXPLAYERS+1][2];

public OnSHPluginReady()
{
  // Hook events
  HookEvent("round_start",RoundStartEvent);
  HookEvent("player_spawn",PlayerSpawnEvent);
  heroID=SH_CreateHero("Pitch Black","pitchblack","Darken the map for everyone but you","0","0");  // Make hero
  // Create cvars
  cvarCooldown=CreateConVar("pitchblack_cooldown","60.0","The cooldown period after darkening the map"); 
  cvarTime=CreateConVar("pitchblack_time","7.0","How long the map is darkened");
  cvarDarkness=CreateConVar("pitchblack_darkness","252","How dark the map becomes (0-255, 255 being pitch black)");
}

public OnConfigsExecuted()
{
  // Find cvar
  cvarSkyName=FindConVar("sv_skyname");
  GetConVarString(cvarSkyName,dSkyName,32);
  // Find offsets
  // todo: find offsets
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  Lighten();
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  new index=GetClientOfUserId(GetEventInt(event,"userid"));
  CoolDown(index);
}

public OnPowerCommand(client,hero,bool:pressed)
{
  if(heroID==hero)
  {
    if(pressed)
      if(gCooledDown[client])
        if(!gIsDark)
          Darken(client); // Darken the map
        else
          PrintToChat(client,"[SHSource] The map is already dark! Please wait until it has returned to normal");
      else
        PrintToChat(client,"[SHSource] There is a %d second cooldown for this power",GetConVarInt(cvarCooldown));
  }
}

public Darken(client)
{
  gCooledDown[client]=false; // Restrict them from using again for a while
  gIsDark=true; // Tell the plugin the map is dark
  gTimer[client][0]=CreateTimer(GetConVarFloat(cvarTime),Darken_Done,client); // Start timer for lightening the map
  gTimer[client][1]=CreateTimer(GetConVarFloat(cvarCooldown),CoolDown_Done,client); // Start timer for unrestricting the power
  // Darken map
  SetConVarString(cvarSkyName,"sky_borealis01");
  // Darken player's screens
  new color[4]={25,25,30,0};
  color[3]=GetConVarInt(cvarDarkness);
  new clientcolor[4]={25,255,25,190};
  new maxplayers=GetMaxClients();
  for(new x=1;x<=maxplayers;x++)
    if(IsClientInGame(x))
      if(x!=client)
        Fade(x,0,5,RoundToNearest(GetConVarFloat(cvarTime)),color);
      else
        Fade(x,0,5,RoundToNearest(GetConVarFloat(cvarTime)),clientcolor);
  // Announce
  decl String:name[64];
  GetClientName(client,name,64);
  PrintToChatAll("[SHSource] %s made the map pitch black!",name);
}

public Action:Darken_Done(Handle:timer,any:index)
{
  if(IsValidHandle(gTimer[index][0]))
    CloseHandle(gTimer[index][0]);
  gTimer[index][0]=INVALID_HANDLE; // Erase timer handle
  Lighten();
}

public Lighten()
{
  gIsDark=false; // Tell the plugin the map is normal
  // Lighten map
  SetConVarString(cvarSkyName,dSkyName,true,false);
}

public Action:CoolDown_Done(Handle:timer,any:index)
{
  CoolDown(index);
}

public CoolDown(client)
{
  gCooledDown[client]=true; // Allow them to darken map again
  if(IsValidHandle(gTimer[client][1]))
    CloseHandle(gTimer[client][1]);
  gTimer[client][1]=INVALID_HANDLE; // Erase timer handle
}

public Fade(client,type,duration,time,const color[4])
{
  new Handle:hBf=StartMessageOne("Fade",client);
  if(hBf!=INVALID_HANDLE)
  {
    duration*=400;
    time*=400;
    BfWriteShort(hBf,duration);
    BfWriteShort(hBf,time);
    BfWriteShort(hBf,type);
    BfWriteByte(hBf,color[0]);
    BfWriteByte(hBf,color[1]);
    BfWriteByte(hBf,color[2]);
    BfWriteByte(hBf,color[3]);
    EndMessage();
  }
}