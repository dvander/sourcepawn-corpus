/* 
* File: hgrsource.sp
* Author: SumGuy14 (Aka SoccerDude)
* CS:GO version by Sheepdude
* Description: Allows admins (or all players) to hook on to walls, grab other players, or swing on a rope
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define ACTION_HOOK 0
#define ACTION_GRAB 1
#define ACTION_ROPE 2

#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

public Plugin:myinfo = 
{
  name = "HGR:Source",
  author = "SumGuy14 (Aka Soccerdude) / Sheepdude",
  description = "Allows admins (or all players) to hook on to walls, grab other players, or swing on a rope",
  version = "CSGO:1.0.3e",
  url = "http://sourcemod.net/"
};

// General handles
new Handle:cvarAnnounce;
// Hook handles
new Handle:cvarHookEnable;
new Handle:cvarHookAdminOnly;
new Handle:cvarHookSpeed;
new Handle:cvarHookBeamColor;
new Handle:cvarHookRed;
new Handle:cvarHookGreen;
new Handle:cvarHookBlue;
// Grab handles
new Handle:cvarGrabEnable;
new Handle:cvarGrabAdminOnly;
new Handle:cvarGrabSpeed;
new Handle:cvarGrabBeamColor;
new Handle:cvarGrabRed;
new Handle:cvarGrabGreen;
new Handle:cvarGrabBlue;
// Rope handles
new Handle:cvarRopeEnable;
new Handle:cvarRopeAdminOnly;
new Handle:cvarRopeSpeed;
new Handle:cvarRopeBeamColor;
new Handle:cvarRopeRed;
new Handle:cvarRopeGreen;
new Handle:cvarRopeBlue;

// Client status arrays
new bool:gStatus[MAXPLAYERS+1][3];

// Hook array
new Float:gHookEndloc[MAXPLAYERS+1][3];

// Grab arrays
new gTargetindex[MAXPLAYERS+1];
new Float:gGrabDist[MAXPLAYERS+1];
new bool:gGrabbed[MAXPLAYERS+1];

// Rope arrays
new Float:gRopeEndloc[MAXPLAYERS+1][3];
new Float:gRopeDist[MAXPLAYERS+1];

// Clients that have access to hook or grab
new bool:gAllowedClients[MAXPLAYERS+1][3];

// Offset variables
new OriginOffset;
new GetVelocityOffset_0;
new GetVelocityOffset_1;
new GetVelocityOffset_2;
new LifeStateOffset;
new MoveTypeOffset;

// Precache variables
new precache_laser;

enum HGRSourceAction
{
  Hook = 0, /** User is using hook */
  Grab = 1, /** User is using grab */
  Rope = 2, /** User is using rope */
};

enum HGRSourceAccess
{
  Give = 0, /** Gives access to user */
  Take = 1, /** Takes access from user */
};

public OnPluginStart()
{
  PrintToServer("----------------|         HGR:Source Loading        |---------------");
  
  // Hook events
  HookEvent("player_spawn",PlayerSpawnEvent);
  
  // Register client cmds
  RegConsoleCmd("+hook",HookCmd);
  RegConsoleCmd("-hook",UnHookCmd);
  RegConsoleCmd("hook_toggle",HookToggle);
  
  RegConsoleCmd("+grab",GrabCmd);
  RegConsoleCmd("-grab",DropCmd);
  RegConsoleCmd("grab_toggle",GrabToggle);
  
  RegConsoleCmd("+rope",RopeCmd);
  RegConsoleCmd("-rope",DetachCmd);
  RegConsoleCmd("rope_toggle",RopeToggle);
  
  // Register admin cmds
  RegAdminCmd("hgrsource_givehook",GiveHook,ADMFLAG_GENERIC);
  RegAdminCmd("hgrsource_takehook",TakeHook,ADMFLAG_GENERIC);
  RegAdminCmd("hgrsource_givegrab",GiveGrab,ADMFLAG_GENERIC);
  RegAdminCmd("hgrsource_takegrab",TakeGrab,ADMFLAG_GENERIC);
  RegAdminCmd("hgrsource_giverope",GiveRope,ADMFLAG_GENERIC);
  RegAdminCmd("hgrsource_takerope",TakeRope,ADMFLAG_GENERIC);
  
  // Find offsets
  OriginOffset=FindSendPropOffs("CBaseEntity","m_vecOrigin");
  if(OriginOffset==-1)
    SetFailState("[HGR:Source] Error: Failed to find the Origin offset, aborting");
  GetVelocityOffset_0=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
  if(GetVelocityOffset_0==-1)
    SetFailState("[HGR:Source] Error: Failed to find the GetVelocity_0 offset, aborting");
  GetVelocityOffset_1=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
  if(GetVelocityOffset_1==-1)
    SetFailState("[HGR:Source] Error: Failed to find the GetVelocity_1 offset, aborting");
  GetVelocityOffset_2=FindSendPropOffs("CBasePlayer","m_vecVelocity[2]");
  if(GetVelocityOffset_2==-1)
    SetFailState("[HGR:Source] Error: Failed to find the GetVelocity_2 offset, aborting");
  LifeStateOffset=FindSendPropOffs("CAI_BaseNPC","m_lifeState");
  if(LifeStateOffset==-1)
    SetFailState("[HGR:Source] Error: Failed to find the LifeState offset, aborting");
  MoveTypeOffset=FindSendPropOffs("CAI_BaseNPC","movetype");
  if(MoveTypeOffset==-1)
    SetFailState("[HGR:Source] Error: Failed to find the MoveType offset, aborting");
  
  // General cvars
  cvarAnnounce=CreateConVar("hgrsource_announce","1","This will enable announcements that the plugin is loaded");
  
  // Hook cvars
  cvarHookEnable=CreateConVar("hgrsource_hook_enable","1","This will enable the hook feature of this plugin");
  cvarHookAdminOnly=CreateConVar("hgrsource_hook_adminonly","1","If 1, only admins can use hook");
  cvarHookSpeed=CreateConVar("hgrsource_hook_speed","5.0","The speed of the player using hook");
  cvarHookBeamColor=CreateConVar("hgrsource_hook_color","2","The color of the hook, 0 = White, 1 = Team color, 2= custom");
  cvarHookRed=CreateConVar("hgrsource_hook_red","255","The red component of the beam (Only if you are using a custom color)");
  cvarHookGreen=CreateConVar("hgrsource_hook_green","0","The green component of the beam (Only if you are using a custom color)");
  cvarHookBlue=CreateConVar("hgrsource_hook_blue","0","The blue component of the beam (Only if you are using a custom color)");
  
  // Grab cvars
  cvarGrabEnable=CreateConVar("hgrsource_grab_enable","1","This will enable the grab feature of this plugin");
  cvarGrabAdminOnly=CreateConVar("hgrsource_grab_adminonly","1","If 1, only admins can use grab");
  cvarGrabSpeed=CreateConVar("hgrsource_grab_speed","5.0","The speed of the grabbers target");
  cvarGrabBeamColor=CreateConVar("hgrsource_grab_color","2","The color of the grab beam, 0 = White, 1 = Team color");
  cvarGrabRed=CreateConVar("hgrsource_grab_red","0","The red component of the beam (Only if you are using a custom color)");
  cvarGrabGreen=CreateConVar("hgrsource_grab_green","0","The green component of the beam (Only if you are using a custom color)");
  cvarGrabBlue=CreateConVar("hgrsource_grab_blue","255","The blue component of the beam (Only if you are using a custom color)");
  
  // Rope cvars
  cvarRopeEnable=CreateConVar("hgrsource_rope_enable","1","This will enable the rope feature of this plugin");
  cvarRopeAdminOnly=CreateConVar("hgrsource_rope_adminonly","1","If 1, only admins can use rope");
  cvarRopeSpeed=CreateConVar("hgrsource_rope_speed","5.0","The speed of the player using rope");
  cvarRopeBeamColor=CreateConVar("hgrsource_rope_color","2","The color of the rope, 0 = White, 1 = Team color");
  cvarRopeRed=CreateConVar("hgrsource_rope_red","0","The red component of the beam (Only if you are using a custom color)");
  cvarRopeGreen=CreateConVar("hgrsource_rope_green","255","The green component of the beam (Only if you are using a custom color)");
  cvarRopeBlue=CreateConVar("hgrsource_rope_blue","0","The blue component of the beam (Only if you are using a custom color)");
  
  // Auto-generate config
  AutoExecConfig();
  
  // Public cvar
  CreateConVar("hgrsource_version","1.0.3d","[HGR:Source] Current version of this plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

  PrintToServer("----------------|         HGR:Source Loaded         |---------------");
}

public OnConfigsExecuted()
{
  // Precache models
  precache_laser=PrecacheModel("materials/sprites/laserbeam.vmt");
  // Precache sounds
  PrecacheSound("weapons/crossbow/hit1.wav");
}

/********
 *Events*
*********/
 
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
  new index=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index
  // Tell plugin they aren't using any of its features
  gStatus[index][ACTION_HOOK]=false;
  gStatus[index][ACTION_GRAB]=false;
  gStatus[index][ACTION_ROPE]=false;
  if(GetConVarBool(cvarAnnounce))
    PrintToChat(index,"%c[HGR:Source] %cIs enabled, valid commands are: [%c+hook%c] [%c+grab%c] [%c+rope%c]",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
}

/******
 *Cmds*
*******/

public Action:HookCmd(client,argc)
{
  Action_Hook(client);
  return Plugin_Handled;
}

public Action:UnHookCmd(client,argc)
{
	if(IsClientAlive(client))
		Action_UnHook(client);
	return Plugin_Handled;
}

public Action:HookToggle(client,argc)
{
  if(gStatus[client][ACTION_HOOK])
    gStatus[client][ACTION_HOOK]=false;
  else
    Action_Hook(client);
  return Plugin_Handled;
}
    
public Action:GrabCmd(client,argc)
{
  Action_Grab(client);
  return Plugin_Handled;
}

public Action:DropCmd(client,argc)
{
  if(IsClientAlive(client))
    Action_Drop(client);
  return Plugin_Handled;
}

public Action:GrabToggle(client,argc)
{
  if(gStatus[client][ACTION_GRAB])
    gStatus[client][ACTION_GRAB]=false;
  else
    Action_Grab(client);
  return Plugin_Handled;
}

public Action:RopeCmd(client,argc)
{
  Action_Rope(client);
  return Plugin_Handled;
}

public Action:DetachCmd(client,argc)
{
  if(IsClientAlive(client))
    Action_Detach(client);
  return Plugin_Handled;
}

public Action:RopeToggle(client,argc)
{
  if(gStatus[client][ACTION_ROPE])
    gStatus[client][ACTION_ROPE]=false;
  else
    Action_Rope(client);
  return Plugin_Handled;
}

/*******
 *Admin*
********/

public Action:GiveHook(client,argc)
{
  if(argc>=1)
  {
    if(IsFeatureEnabled(Hook)&&IsFeatureAdminOnly(Hook))
    {
      decl String:target[64];
      GetCmdArg(1,target,64);
      new count=Access(target,Give,Hook);
      if(!count)
        ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
    }
  }
  else
    ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_givehook <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
  return Plugin_Handled;
}

public Action:TakeHook(client,argc)
{
  if(argc>=1)
  {
    if(IsFeatureEnabled(Hook)&&IsFeatureAdminOnly(Hook))
    {
      decl String:target[64];
      GetCmdArg(1,target,64);
      new count=Access(target,Take,Hook);
      if(!count)
        ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
    }
  }
  else
    ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takehook <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
  return Plugin_Handled;
}

public Action:GiveGrab(client,argc)
{
  if(argc>=1)
  {
    if(IsFeatureEnabled(Grab)&&IsFeatureAdminOnly(Grab))
    {
      decl String:target[64];
      GetCmdArg(1,target,64);
      new count=Access(target,Give,Grab);
      if(!count)
        ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
    }
  }
  else
    ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_givegrab <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
  return Plugin_Handled;
}

public Action:TakeGrab(client,argc)
{
  if(argc>=1)
  {
    if(IsFeatureEnabled(Grab)&&IsFeatureAdminOnly(Grab))
    {
      decl String:target[64];
      GetCmdArg(1,target,64);
      new count=Access(target,Take,Grab);
      if(!count)
        ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
    }
  }
  else
    ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takegrab <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
  return Plugin_Handled;
}

public Action:GiveRope(client,argc)
{
  if(argc>=1)
  {
    if(IsFeatureEnabled(Rope)&&IsFeatureAdminOnly(Rope))
    {
      decl String:target[64];
      GetCmdArg(1,target,64);
      new count=Access(target,Give,Rope);
      if(!count)
        ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
    }
  }
  else
    ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_giverope <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
  return Plugin_Handled;
}

public Action:TakeRope(client,argc)
{
  if(argc>=1)
  {
    if(IsFeatureEnabled(Rope)&&IsFeatureAdminOnly(Rope))
    {
      decl String:target[64];
      GetCmdArg(1,target,64);
      new count=Access(target,Take,Rope);
      if(!count)
        ReplyToCommand(client,"%c[HGR:Source] %cNo players on the server matched %c%s%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,target,COLOR_DEFAULT);
    }
  }
  else
    ReplyToCommand(client,"%c[HGR:Source] Usage: %chgrsource_takerope <@t/@ct/@userid/partial name>",COLOR_GREEN,COLOR_DEFAULT);
  return Plugin_Handled;
}

/********
 *Access*
*********/
 
public Access(const String:target[],HGRSourceAccess:access,HGRSourceAction:action)
{
  new clients[MAXPLAYERS];
  new count=FindMatchingPlayers(target,clients);
  if(count==0)
    return 0;
  for(new x=0;x<count;x++)
    ClientAccess(clients[x],access,action);
  return count;
}

public ClientAccess(client,HGRSourceAccess:access,HGRSourceAction:action)
{
  if(access==Give)
  {
    if(action==Hook)
      gAllowedClients[client][ACTION_HOOK]=true;
    else if(action==Grab)
      gAllowedClients[client][ACTION_GRAB]=true;
    else if(action==Rope)
      gAllowedClients[client][ACTION_ROPE]=true;
  }
  else if(access==Take)
  {
    if(action==Hook)
      gAllowedClients[client][ACTION_HOOK]=false;
    else if(action==Grab)
      gAllowedClients[client][ACTION_GRAB]=false;
    else if(action==Rope)
      gAllowedClients[client][ACTION_ROPE]=false;
  }
}

public bool:HasAccess(client,HGRSourceAction:action)
{
  decl String:steamid[32];
  GetClientAuthString(client,steamid,32);
  if(GetAdminFlag(GetUserAdmin(client),Admin_Generic,Access_Real)||GetAdminFlag(GetUserAdmin(client),Admin_Generic,Access_Effective)||GetAdminFlag(GetUserAdmin(client),Admin_Root,Access_Real)||GetAdminFlag(GetUserAdmin(client),Admin_Root,Access_Effective))
    return true;
  else
  {
    if(!IsFeatureEnabled(action))
      return false;
    if(!IsFeatureAdminOnly(action))
      return true;
    if(action==Hook)
      return gAllowedClients[client][ACTION_HOOK];
    else if(action==Grab)
      return gAllowedClients[client][ACTION_GRAB];
    else if(action==Rope)
      return gAllowedClients[client][ACTION_ROPE];
  }
  return false;
}

/******
 *CVar*
*******/
  
public bool:IsFeatureEnabled(HGRSourceAction:action)
{
  if(action==Hook)
    return GetConVarBool(cvarHookEnable);
  if(action==Grab)
    return GetConVarBool(cvarGrabEnable);
  if(action==Rope)
    return GetConVarBool(cvarRopeEnable);
  return false;
}

public bool:IsFeatureAdminOnly(HGRSourceAction:action)
{
  if(action==Hook)
    return GetConVarBool(cvarHookAdminOnly);
  if(action==Grab)
    return GetConVarBool(cvarGrabAdminOnly);
  if(action==Rope)
    return GetConVarBool(cvarRopeAdminOnly);
  return false;
}

public GetBeamColor(client,HGRSourceAction:action,color[4])
{
  new beamtype=0;
  new red=255;
  new green=255;
  new blue=255;
  if(action==Hook)
  {
    beamtype=GetConVarInt(cvarHookBeamColor);
    if(beamtype==2)
    {
      red=GetConVarInt(cvarHookRed);
      green=GetConVarInt(cvarHookGreen);
      blue=GetConVarInt(cvarHookBlue);
    }
  }
  else if(action==Grab)
  {
    beamtype=GetConVarInt(cvarGrabBeamColor);
    if(beamtype==2)
    {
      red=GetConVarInt(cvarGrabRed);
      green=GetConVarInt(cvarGrabGreen);
      blue=GetConVarInt(cvarGrabBlue);
    }
  }
  else if(action==Rope)
  {
    beamtype=GetConVarInt(cvarRopeBeamColor);
    if(beamtype==2)
    {
      red=GetConVarInt(cvarRopeRed);
      green=GetConVarInt(cvarRopeGreen);
      blue=GetConVarInt(cvarRopeBlue);
    }
  }
  if(beamtype==0)
  {
    color[0]=255;color[1]=255;color[2]=255;color[3]=255;
  }
  else if(beamtype==1)
  {
    if(GetClientTeam(client)==2)
    {
      color[0]=255;color[1]=0;color[2]=0;color[3]=255;
    }
    else if(GetClientTeam(client)==3)
    {
      color[0]=0;color[1]=0;color[2]=255;color[3]=255;
    }
  }
  else if(beamtype==2)
  {
    color[0]=red;color[1]=green;color[2]=blue;color[3]=255;
  }
}

/******
 *Hook*
*******/

public Action_Hook(client)
{
  if(GetConVarBool(cvarHookEnable))
  {
    if(client>0)
    {
      if(IsClientAlive(client)&&!gStatus[client][ACTION_HOOK]&&!gStatus[client][ACTION_ROPE]&&!gGrabbed[client])
      {
        if(HasAccess(client,Hook))
        {
          new Float:clientloc[3],Float:clientang[3];
          GetClientEyePosition(client,clientloc); // Get the position of the player's eyes
          GetClientEyeAngles(client,clientang); // Get the angle the player is looking
          TR_TraceRayFilter(clientloc,clientang,MASK_SOLID,RayType_Infinite,TraceRayTryToHit); // Create a ray that tells where the player is looking
          SetEntPropFloat(client,Prop_Data,"m_flGravity",0.0); // Set gravity to 0 so client floats in a straight line
          TR_GetEndPosition(gHookEndloc[client]); // Get the end xyz coordinate of where a player is looking
          EmitSoundFromOrigin("weapons/crossbow/hit1.wav",gHookEndloc[client]); // Emit sound from where the hook landed
          gStatus[client][ACTION_HOOK]=true; // Tell plugin the player is hooking
          Hook_Push(client);
          CreateTimer(0.1,Hooking,client,TIMER_REPEAT); // Create hooking loop
        }
        else
          PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use %chook%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
      }
    }
    else
      PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",COLOR_GREEN,COLOR_DEFAULT);
  }
  else
    PrintToChat(client,"%c[HGR:Source] Hook %cis currently disabled",COLOR_GREEN,COLOR_DEFAULT);
}

public Hook_Push(client)
{
  new Float:clientloc[3],Float:velocity[3];
  GetClientAbsOrigin(client,clientloc); // Get the xyz coordinate of the player
  new color[4];
  clientloc[2]+=30.0;
  GetBeamColor(client,Hook,color);
  BeamEffect("@all",clientloc,gHookEndloc[client],0.2,5.0,5.0,color,0.0,0);
  GetForwardPushVec(clientloc,gHookEndloc[client],velocity); // Get how hard and where to push the client
  TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,velocity); // Push the client
  new Float:distance=GetDistanceBetween(clientloc,gHookEndloc[client]);
  if(distance<30.0)
  {
    SetEntData(client,MoveTypeOffset,0,1); // Freeze client
    SetEntPropFloat(client,Prop_Data,"m_flGravity",1.0); // Set grav to normal
  }
}

public Action:Hooking(Handle:timer,any:index)
{
  if(IsClientInGame(index)&&IsClientAlive(index)&&gStatus[index][ACTION_HOOK]&&!gGrabbed[index])
    Hook_Push(index);
  else
  {
    Action_UnHook(index);
    return Plugin_Stop;
  }
  return Plugin_Continue; // Stop the timer
}

public Action_UnHook(client)
{
  gStatus[client][ACTION_HOOK]=false; // Tell plugin the client is not hooking
  SetEntPropFloat(client,Prop_Data,"m_flGravity",1.0); // Set grav to normal
  SetEntData(client,MoveTypeOffset,2,1); // Unfreeze client
}

/******
 *Grab*
*******/

public Action_Grab(client)
{
  if(GetConVarBool(cvarGrabEnable))
  {
    if(client>0)
    {
      if(IsClientAlive(client)&&!gStatus[client][ACTION_GRAB]&&!gGrabbed[client])
      {
        if(HasAccess(client,Grab))
        {
          gStatus[client][ACTION_GRAB]=true; // Tell plugin the seeker is grabbing a player
          CreateTimer(0.05,GrabSearch,client,TIMER_REPEAT); // Start a timer that searches for a client to grab
        }
        else
          PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use %cgrab%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
      }
    }
    else
      PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",COLOR_GREEN,COLOR_DEFAULT);
  }
  else
    PrintToChat(client,"%c[HGR:Source] Grab %cis currently disabled",COLOR_GREEN,COLOR_DEFAULT);
}

public Action:GrabSearch(Handle:timer,any:index)
{
	PrintCenterText(index,"[HGR] Searching for a target..."); // Tell client the plugin is searching for a target
	if(IsClientInGame(index)&&IsClientAlive(index)&&gStatus[index][ACTION_GRAB]&&!gGrabbed[index])
	{
		new Float:clientloc[3],Float:clientang[3];
		GetClientEyePosition(index,clientloc); // Get seekers eye coordinate
		GetClientEyeAngles(index,clientang); // Get angle of where the player is looking
		TR_TraceRayFilter(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayGrabEnt); // Create a ray that tells where the player is looking
		gTargetindex[index]=TR_GetEntityIndex(); // Set the seekers targetindex to the person he picked up
		if(gTargetindex[index]>0)
		{
			// Found a player
			new Float:targetloc[3];
			GetEntityOrigin(gTargetindex[index],targetloc); // Find the target's xyz coordinate
			EmitSoundFromOrigin("weapons/crossbow/hit1.wav",targetloc); // Emit sound from the entity being grabbed
			SetEntPropFloat(gTargetindex[index],Prop_Data,"m_flGravity",0.0); // Set gravity to 0 so the target moves around easy
			gGrabDist[index]=GetDistanceBetween(clientloc,targetloc); // Tell plugin the distance between the 2 to maintain
			if(gTargetindex[index]>0&&gTargetindex[index]<=64&&IsClientInGame(gTargetindex[index]))
			{
				gGrabbed[gTargetindex[index]]=true; // Tell plugin the target is being grabbed
			}
			CreateTimer(0.1,Grabbing,index,TIMER_REPEAT); // Start a repeating timer that will reposition the target in the grabber's crosshairs
			PrintCenterText(index,"[HGR] Target found, release key/toggle off to drop");
			return Plugin_Stop; // Stop the timer
		}
	}
	return Plugin_Stop; // Stop the timer
}

public Action:Grabbing(Handle:timer,any:index)
{
  if(IsClientInGame(index)&&IsClientAlive(index)&&gStatus[index][ACTION_GRAB]&&!gGrabbed[index])
  {
    if(gTargetindex[index]>64||IsClientInGame(gTargetindex[index])&&IsClientAlive(gTargetindex[index]))
    {
      // Find where to push the target
      new Float:clientloc[3],Float:clientang[3],Float:targetloc[3],Float:endvec[3],Float:distance[3];
      GetClientAbsOrigin(index,clientloc);
      GetClientEyeAngles(index,clientang);
      GetEntityOrigin(gTargetindex[index],targetloc);
      TR_TraceRayFilter(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayTryToHit); // Find where the player is aiming
      TR_GetEndPosition(endvec); // Get the end position of the trace ray
      distance[0]=endvec[0]-clientloc[0];
      distance[1]=endvec[1]-clientloc[1];
      distance[2]=endvec[2]-clientloc[2];
      new Float:que=gGrabDist[index]/(SquareRoot(distance[0]*distance[0]+distance[1]*distance[1]+distance[2]*distance[2]));
      new Float:velocity[3];
      velocity[0]=(((distance[0]*que)+clientloc[0])-targetloc[0])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
      velocity[1]=(((distance[1]*que)+clientloc[1])-targetloc[1])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
      velocity[2]=(((distance[2]*que)+clientloc[2])-targetloc[2])*(GetConVarFloat(cvarGrabSpeed)/1.666667);
      TeleportEntity(gTargetindex[index],NULL_VECTOR,NULL_VECTOR,velocity);
      // Make a beam from grabber to grabbed
      new color[4];
      if(gTargetindex[index]<=64)
        targetloc[2]+=45;
      GetBeamColor(index,Grab,color);
      BeamEffect("@all",clientloc,targetloc,0.2,1.0,10.0,color,0.0,0);
    }
    else
    {
      Action_Drop(index);
      return Plugin_Stop; // Stop the timer
    }
  }
  else
  {
    Action_Drop(index);
    return Plugin_Stop; // Stop the timer
  }
  return Plugin_Continue;
}

public Action_Drop(client)
{
  gStatus[client][ACTION_GRAB]=false; // Tell plugin the grabber has dropped his target
  if(gTargetindex[client]>0)
  {
    PrintCenterText(client,"Target has been dropped");
    SetEntPropFloat(gTargetindex[client],Prop_Data,"m_flGravity",1.0); // Set gravity back to normal
    if(gTargetindex[client]>0&&gTargetindex[client]<=64&&IsClientInGame(gTargetindex[client]))
      gGrabbed[gTargetindex[client]]=false; // Tell plugin the target is no longer being grabbed
    gTargetindex[client]=-1;
  }
  else
    PrintCenterText(client,"No target found");
}

/******
 *Rope*
*******/

public Action_Rope(client)
{
  if(GetConVarBool(cvarRopeEnable))
  {
    if(client>0)
    {
      if(IsClientAlive(client)&&!gStatus[client][ACTION_ROPE]&&!gStatus[client][ACTION_HOOK]&&!gGrabbed[client])
      {
        if(HasAccess(client,Rope))
        {
          new Float:clientloc[3],Float:clientang[3];
          GetClientEyePosition(client,clientloc); // Get the position of the player's eyes
          GetClientEyeAngles(client,clientang); // Get the angle the player is looking
          TR_TraceRayFilter(clientloc,clientang,MASK_ALL,RayType_Infinite,TraceRayTryToHit); // Create a ray that tells where the player is looking
          TR_GetEndPosition(gRopeEndloc[client]); // Get the end xyz coordinate of where a player is looking
          EmitSoundFromOrigin("weapons/crossbow/hit1.wav",gRopeEndloc[client]); // Emit sound from the end of the rope
          gRopeDist[client]=GetDistanceBetween(clientloc,gRopeEndloc[client]);
          gStatus[client][ACTION_ROPE]=true; // Tell plugin the player is roping
          CreateTimer(0.1,Roping,client,TIMER_REPEAT); // Create roping loop
        }
        else
          PrintToChat(client,"%c[HGR:Source] %cYou don't have permission to use %crope%c",COLOR_GREEN,COLOR_DEFAULT,COLOR_GREEN,COLOR_DEFAULT);
      }
    }
    else
      PrintToChat(client,"%c[HGR:Source] %cERROR: Please notify server administrator",COLOR_GREEN,COLOR_DEFAULT);
  }
  else
    PrintToChat(client,"%c[HGR:Source] Rope %cis currently disabled",COLOR_GREEN,COLOR_DEFAULT);
}

public Action:Roping(Handle:timer,any:index)
{
  if(IsClientInGame(index)&&gStatus[index][ACTION_ROPE]&&IsClientAlive(index)&&!gGrabbed[index])
  {
    new Float:clientloc[3],Float:velocity[3],Float:velocity2[3];
    GetClientAbsOrigin(index,clientloc);
    GetVelocity(index,velocity);
    velocity2[0]=(gRopeEndloc[index][0]-clientloc[0])*3.0;
    velocity2[1]=(gRopeEndloc[index][1]-clientloc[1])*3.0;
    new Float:y_coord,Float:x_coord;
    y_coord=velocity2[0]*velocity2[0]+velocity2[1]*velocity2[1];
    x_coord=(GetConVarFloat(cvarRopeSpeed)*20.0)/SquareRoot(y_coord);
    velocity[0]+=velocity2[0]*x_coord;
    velocity[1]+=velocity2[1]*x_coord;
    if(gRopeEndloc[index][2]-clientloc[2]>=gRopeDist[index]&&velocity[2]<0.0)
    velocity[2]*=-1;
    TeleportEntity(index,NULL_VECTOR,NULL_VECTOR,velocity);
    // Make a beam from grabber to grabbed
    new color[4];
    clientloc[2]+=50;
    GetBeamColor(index,Rope,color);
    BeamEffect("@all",clientloc,gRopeEndloc[index],0.2,3.0,3.0,color,0.0,0);
  }
  else
  {
    Action_Detach(index);
    return Plugin_Stop; // Stop the timer
  }
  return Plugin_Handled;
}

public Action_Detach(client)
{
  gStatus[client][ACTION_ROPE]=false; // Tell plugin the client is not hooking
}

/***************
 *Trace Filters*
****************/

public bool:TraceRayTryToHit(entity,mask)
{
  if(entity>0&&entity<=64) // Check if the beam hit a player and tell it to keep tracing if it did
    return false;
  return true;
}

public bool:TraceRayGrabEnt(entity,mask)
{
  if(entity>0) // Check if the beam hit an entity other than the grabber, and stop if it does
  {
    if(entity<=64&&!gStatus[entity][ACTION_GRAB]&&!gGrabbed[entity])
      return true;
    if(entity>64) 
      return true;
  }
  return false;
}

/*********
 *Helpers*
**********/

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
  EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

public GetEntityOrigin(entity,Float:output[3])
{
  GetEntDataVector(entity,OriginOffset,output);
}

public GetVelocity(client,Float:output[3])
{
  output[0]=GetEntDataFloat(client,GetVelocityOffset_0);
  output[1]=GetEntDataFloat(client,GetVelocityOffset_1);
  output[2]=GetEntDataFloat(client,GetVelocityOffset_2);
}

public IsClientAlive(client)
{
  return bool:!GetEntData(client,LifeStateOffset,1);
}

/****************
 *Math (Vectors)*
*****************/

public GetForwardPushVec(const Float:start[3],const Float:end[3],Float:output[3])
{
  CreateVectorFromPoints(start,end,output);
  NormalizeVector(output,output);
  output[0]*=GetConVarFloat(cvarHookSpeed)*140.0;
  output[1]*=GetConVarFloat(cvarHookSpeed)*140.0;
  output[2]*=GetConVarFloat(cvarHookSpeed)*140.0;
}

public Float:CreateVectorFromPoints(const Float:vec1[3],const Float:vec2[3],Float:output[3])
{
  output[0]=vec2[0]-vec1[0];
  output[1]=vec2[1]-vec1[1];
  output[2]=vec2[2]-vec1[2];
}

public AddInFrontOf(Float:orig[3],Float:angle[3],Float:distance,Float:output[3])
{
  new Float:viewvector[3];
  ViewVector(angle,viewvector);
  output[0]=viewvector[0]*distance+orig[0];
  output[1]=viewvector[1]*distance+orig[1];
  output[2]=viewvector[2]*distance+orig[2];
}
 
public ViewVector(Float:angle[3],Float:output[3])
{
  output[0]=Cosine(angle[1]/(180/FLOAT_PI));
  output[1]=Sine(angle[1]/(180/FLOAT_PI));
  output[2]=-Sine(angle[0]/(180/FLOAT_PI));
}

public Float:GetDistanceBetween(Float:startvec[3],Float:endvec[3])
{
  return SquareRoot((startvec[0]-endvec[0])*(startvec[0]-endvec[0])+(startvec[1]-endvec[1])*(startvec[1]-endvec[1])+(startvec[2]-endvec[2])*(startvec[2]-endvec[2]));
}

/*********
 *Effects*
**********/

public BeamEffect(const String:target[],Float:startvec[3],Float:endvec[3],Float:life,Float:width,Float:endwidth,const color[4],Float:amplitude,speed)
{
  new clients[MAXPLAYERS];
  new count=FindMatchingPlayers(target,clients);
  TE_SetupBeamPoints(startvec,endvec,precache_laser,0,0,66,life,width,endwidth,0,amplitude,color,speed);
  TE_Send(clients,count);
} 

/*********************
 *Partial Name Parser*
**********************/
 
public FindMatchingPlayers(const String:matchstr[],clients[])
{
  new count=0;
  new maxplayers=GetMaxClients();
  if(StrEqual(matchstr,"@all",false))
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x))
      {
        clients[count]=x;
        count++;
      }
    }
  }
  else if(StrEqual(matchstr,"@t",false))
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x)&&GetClientTeam(x)==2)
      {
        clients[count]=x;
        count++;
      }
    }
  }
  else if(StrEqual(matchstr,"@ct",false))
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x)&&GetClientTeam(x)==3)
      {
        clients[count]=x;
        count++;
      }
    }
  }
  else if(matchstr[0]=='@')
  {
    new userid=StringToInt(matchstr[1]);
    if(userid)
    {
      new index=GetClientOfUserId(userid);
      if(index)
      {
        if(IsClientInGame(index))
        {
          clients[count]=index;
          count++;
        }
      }
    }
  }
  else
  {
    for(new x=1;x<=maxplayers;x++)
    {
      if(IsClientInGame(x))
      {
        decl String:name[64];
        GetClientName(x,name,64);
        if(StrContains(name,matchstr,false)!=-1)
        {
          clients[count]=x;
          count++;
        }
      }
    }
  }
  return count;
}