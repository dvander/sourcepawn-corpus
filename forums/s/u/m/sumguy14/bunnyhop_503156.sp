/* BunnyHop
* Author: Soccerdude
* Description: Gives players the ability to jump higher
*/
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Declare offsets

new VelocityOffset_0;
new VelocityOffset_1;
new BaseVelocityOffset;

// Declare convar handles

new Handle:hPush;
new Handle:hHeight;

public Plugin:myinfo = 
{
  name = "BunnyHop",
  author = "Soccerdude",
  description = "Gives players the ability to jump higher",
  version = "1.0.1",
  url = "http://sourcemod.net/"
};

public OnPluginStart()
{
  PrintToServer("----------------|         BunnyHop Loading        |---------------");
  // Hook Events
  HookEvent("player_jump",PlayerJumpEvent);
  // Find offsets
  VelocityOffset_0=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
  if(VelocityOffset_0==-1)
    SetFailState("[BunnyHop] Error: Failed to find Velocity[0] offset, aborting");
  VelocityOffset_1=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
  if(VelocityOffset_1==-1)
    SetFailState("[BunnyHop] Error: Failed to find Velocity[1] offset, aborting");
  BaseVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
  if(BaseVelocityOffset==-1)
    SetFailState("[BunnyHop] Error: Failed to find the BaseVelocity offset, aborting");
  // Create cvars
  hPush=CreateConVar("bunnyhop_push","1.0","The forward push when you jump");
  hHeight=CreateConVar("bunnyhop_height","1.0","The upward push when you jump");
  // Create config
  AutoExecConfig();
  // Public cvar
  CreateConVar("bunnyhop_version","1.0.1","[BunnyHop] Current version of this plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
  PrintToServer("----------------|         BunnyHop Loaded         |---------------");
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  new index=GetClientOfUserId(GetEventInt(event,"userid"));
  new Float:finalvec[3];
  finalvec[0]=GetEntDataFloat(index,VelocityOffset_0)*GetConVarFloat(hPush)/2.0;
  finalvec[1]=GetEntDataFloat(index,VelocityOffset_1)*GetConVarFloat(hPush)/2.0;
  finalvec[2]=GetConVarFloat(hHeight)*50.0;
  SetEntDataVector(index,BaseVelocityOffset,finalvec,true);
}