#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0.1"

#define MAX_PLAYERS 64


// globals
new gObj[MAXPLAYERS+1];    // how many tripmines player has this spawn
new Handle:gTimer;       
new String:gSound[256];

// convars
new Handle:cvSpeed = INVALID_HANDLE;
new Handle:cvDistance = INVALID_HANDLE; 
new Handle:cvTeamRestrict = INVALID_HANDLE;
new Handle:cvSound = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Grabber:SM",
	author = "L. Duke",
	description = "grabber (gravgun)",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};


public OnPluginStart() 
{
  // events
  HookEvent("player_death", PlayerDeath);
  HookEvent("player_spawn",PlayerSpawn);
  
  // convars
  CreateConVar("sm_grabber_version", PLUGIN_VERSION, "Grabber:SM Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  cvSpeed = CreateConVar("sm_grabber_speed", "10.0");
  cvDistance = CreateConVar("sm_grabber_distance", "64.0");
  cvTeamRestrict = CreateConVar("sm_grabber_team_restrict", "0", "team restriction (0=all use, 2 or 3 to restrict that team");
  cvSound = CreateConVar("sm_grabber_sound", "weapons/physcannon/hold_loop.wav", "sound to play, change takes effect on map change");
  
  // commands
  RegConsoleCmd("+grab", Command_Grab);
  RegConsoleCmd("-grab", Command_UnGrab);
}

public OnEventShutdown(){
	UnhookEvent("player_death", PlayerDeath);
	UnhookEvent("player_spawn",PlayerSpawn);
}

public OnMapStart()
{ 
  // reset object list
  new i;
  for (i=0; i<MAX_PLAYERS; i++)
  {
    gObj[i]=-1;
  }
  
  // start timer
  gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT);
  
  // precache sounds
  GetConVarString(cvSound, gSound, sizeof(gSound));
  PrecacheSound(gSound, true);
}

public OnMapEnd()
{
  CloseHandle(gTimer);
}

// When a new client is put in the server we reset their mines count
public OnClientPutInServer(client){
  if(client && !IsFakeClient(client)) gObj[client] = -1;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	// reset object held
	gObj[client] = -1;
	StopSound(client, SNDCHAN_AUTO, gSound);
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	// reset object held
	gObj[client] = -1;
	StopSound(client, SNDCHAN_AUTO, gSound);
	return Plugin_Continue;
}

public Action:Command_Grab(client, args)
{  
  // make sure client is not spectating
  if (!IsPlayerAlive(client))
    return Plugin_Handled;
  
  // check team restrictions
  new restrict = GetConVarInt(cvTeamRestrict);
  if (restrict>0)
  {
    if (restrict==GetClientTeam(client))
    {
      return Plugin_Handled;
    }
  }
  
  // find entity
  new ent = TraceToEntity(client);
  if (ent==-1)
    return Plugin_Handled;
  
  // only grab physics entities
  new String:edictname[128];
  GetEdictClassname(ent, edictname, 128);
  if (strncmp("prop_", edictname, 5, false)==0)
  {
    // grab entity
    gObj[client] = ent;
    EmitSoundToAll(gSound, client);
  }

  return Plugin_Handled;
}

public Action:Command_UnGrab(client, args)
{  
  // make sure client is not spectating
  if (!IsPlayerAlive(client))
    return Plugin_Handled;
  
  StopSound(client, SNDCHAN_AUTO, gSound);
  gObj[client] = -1;

  return Plugin_Handled;
}


public Action:UpdateObjects(Handle:timer)

{
  new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];      // vectors
  new Float:viewang[3];                                       // angles
  new i;
  new Float:speed = GetConVarFloat(cvSpeed);
  new Float:distance = GetConVarFloat(cvDistance);
  for (i=0; i<MAX_PLAYERS; i++)
  {
    if (gObj[i]>0)
    {
      if (IsValidEdict(gObj[i]) && IsValidEntity(gObj[i]))
      {
        // get client info
        GetClientEyeAngles(i, viewang);
        GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
        GetClientEyePosition(i, vecPos);
        
        // update object 
        vecPos[0]+=vecDir[0]*distance;
        vecPos[1]+=vecDir[1]*distance;
        vecPos[2]+=vecDir[2]*distance;
        
        GetEntPropVector(gObj[i], Prop_Send, "m_vecOrigin", vecDir);
        
        SubtractVectors(vecPos, vecDir, vecVel);
        ScaleVector(vecVel, speed);
        
        TeleportEntity(gObj[i], NULL_VECTOR, NULL_VECTOR, vecVel);
      }
      else
      {
        gObj[i]=-1;
      }
        
    }
  }
  
  return Plugin_Continue;
}















public TraceToEntity(client)
{
  new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
  GetClientEyePosition(client, vecClientEyePos); // Get the position of the player's eyes
  GetClientEyeAngles(client, vecClientEyeAng); // Get the angle the player is looking    
  
  //Check for colliding entities
  TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
  
  if (TR_DidHit(INVALID_HANDLE))
  {
    new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
    return TRIndex;
  }
  
  return -1;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
  if(entity == data) // Check if the TraceRay hit the itself.
  {
    return false; // Don't let the entity be hit
  }
  return true; // It didn't hit itself
}

