#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0.4"

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"

#define TEAM_T 2
#define TEAM_CT 3

#define COLOR_T "255 0 0"
#define COLOR_CT "0 0 255"
#define COLOR_DEF "0 255 255"

#define MAX_LINE_LEN 256

// globals
new gRemaining[MAXPLAYERS+1];    // how many tripmines player has this spawn
new gCount = 1;
new String:mdlMine[256];

// convars
new Handle:cvNumMines = INVALID_HANDLE;
new Handle:cvActTime = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;
new Handle:cvTeamRestricted = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Tripmines",
	author = "L. Duke (mod by user)",
	description = "Plant a trip mine",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};


public OnPluginStart() 
{
  // events
  HookEvent("player_death", PlayerDeath);
  HookEvent("player_spawn",PlayerSpawn);
  
  // convars
  CreateConVar("sm_tripmines_version", PLUGIN_VERSION, "Tripmines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  cvNumMines = CreateConVar("sm_tripmines_allowed", "3");
  cvActTime = CreateConVar("sm_tripmines_activate_time", "2.0");
  cvModel = CreateConVar("sm_tripmines_model", "models/props_lab/tpplug.mdl");
  cvTeamRestricted = CreateConVar("sm_tripmines_restrictedteam", "0");

  // commands
  RegConsoleCmd("sm_tripmine", Command_TripMine);
}

public OnMapStart()
{
  // set model based on cvar
  GetConVarString(cvModel, mdlMine, sizeof(mdlMine));
  
  // precache models
  PrecacheModel(mdlMine, true);
  PrecacheModel(MDL_LASER, true);
  
  // precache sounds
  PrecacheSound(SND_MINEPUT, true);
  PrecacheSound(SND_MINEACT, true);
}

// When a new client is put in the server we reset their mines count
public OnClientPutInServer(client){
  if(client && !IsFakeClient(client)) gRemaining[client] = 0;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	gRemaining[client] = GetConVarInt(cvNumMines);
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	gRemaining[client] = 0;
	return Plugin_Continue;
}

public Action:Command_TripMine(client, args)
{  
  // make sure client is not spectating
  if (!IsPlayerAlive(client))
    return Plugin_Handled;
    
  // check restricted team 
  new team = GetClientTeam(client);
  if(team == GetConVarInt(cvTeamRestricted))
  { 
    PrintHintText(client, "Your team does not have access to this equipment.");
    return Plugin_Handled;
  }
  
  // call SetMine if any remain in client's inventory
  if (gRemaining[client]>0) {
    SetMine(client);
  }
  else {
    PrintHintText(client, "You do not have any tripmines.");
  }
  return Plugin_Handled;
}

SetMine(client)
{
  
  // setup unique target names for entities to be created with
  new String:beam[64];
  new String:beammdl[64];
  new String:tmp[128];
  Format(beam, sizeof(beam), "tmbeam%d", gCount);
  Format(beammdl, sizeof(beammdl), "tmbeammdl%d", gCount);
  gCount++;
  if (gCount>10000)
  {
    gCount = 1;
  }
  
  // trace client view to get position and angles for tripmine
  
  decl Float:start[3], Float:angle[3], Float:end[3], Float:normal[3], Float:beamend[3];
  GetClientEyePosition( client, start );
  GetClientEyeAngles( client, angle );
  GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
  NormalizeVector(end, end);

  start[0]=start[0]+end[0]*TRACE_START;
  start[1]=start[1]+end[1]*TRACE_START;
  start[2]=start[2]+end[2]*TRACE_START;
  
  end[0]=start[0]+end[0]*TRACE_END;
  end[1]=start[1]+end[1]*TRACE_END;
  end[2]=start[2]+end[2]*TRACE_END;
  
  TR_TraceRayFilter(start, end, CONTENTS_SOLID, RayType_EndPoint, FilterAll, 0);
  
  if (TR_DidHit(INVALID_HANDLE))
  {
    // update client's inventory
    gRemaining[client]-=1;
    
    // find angles for tripmine
    TR_GetEndPosition(end, INVALID_HANDLE);
    TR_GetPlaneNormal(INVALID_HANDLE, normal);
    GetVectorAngles(normal, normal);
    
    // trace laser beam
    TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
    TR_GetEndPosition(beamend, INVALID_HANDLE);
    
    // create tripmine model
    new ent = CreateEntityByName("prop_physics_override");
    SetEntityModel(ent,mdlMine);
    DispatchKeyValue(ent, "StartDisabled", "false");
    DispatchSpawn(ent);
    TeleportEntity(ent, end, normal, NULL_VECTOR);
    SetEntProp(ent, Prop_Data, "m_usSolidFlags", 152);
    SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
    SetEntityMoveType(ent, MOVETYPE_NONE);
    SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
    SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
    SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
    DispatchKeyValue(ent, "targetname", beammdl);
    DispatchKeyValue(ent, "ExplodeRadius", "256");
    DispatchKeyValue(ent, "ExplodeDamage", "400");
    Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
    DispatchKeyValue(ent, "OnHealthChanged", tmp);
    Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", beam);
    DispatchKeyValue(ent, "OnBreak", tmp);
    SetEntProp(ent, Prop_Data, "m_takedamage", 2);
    AcceptEntityInput(ent, "Enable");
    HookSingleEntityOutput(ent, "OnBreak", mineBreak, true);

    
    // create laser beam
    ent = CreateEntityByName("env_beam");
    TeleportEntity(ent, beamend, NULL_VECTOR, NULL_VECTOR);
    SetEntityModel(ent, MDL_LASER);
    DispatchKeyValue(ent, "texture", MDL_LASER);
    DispatchKeyValue(ent, "targetname", beam);
    DispatchKeyValue(ent, "TouchType", "4");
    DispatchKeyValue(ent, "LightningStart", beam);
    DispatchKeyValue(ent, "BoltWidth", "4.0");
    DispatchKeyValue(ent, "life", "0");
    DispatchKeyValue(ent, "rendercolor", "0 0 0");
    DispatchKeyValue(ent, "renderamt", "0");
    DispatchKeyValue(ent, "HDRColorScale", "1.0");
    DispatchKeyValue(ent, "decalname", "Bigshot");
    DispatchKeyValue(ent, "StrikeTime", "0");
    DispatchKeyValue(ent, "TextureScroll", "35");
    Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
    DispatchKeyValue(ent, "OnTouchedByEntity", tmp);   
    SetEntPropVector(ent, Prop_Data, "m_vecEndPos", end);
    SetEntPropFloat(ent, Prop_Data, "m_fWidth", 4.0);
    AcceptEntityInput(ent, "TurnOff");

    new Handle:data = CreateDataPack();
    CreateTimer(GetConVarFloat(cvActTime), TurnBeamOn, data);
    WritePackCell(data, client);
    WritePackCell(data, ent);
    WritePackFloat(data, end[0]);
    WritePackFloat(data, end[1]);
    WritePackFloat(data, end[2]);
    
    // play sound
    EmitSoundToAll(SND_MINEPUT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
    
    // send message
    PrintHintText(client, "Tripmines remaining: %d", gRemaining[client]);
  }
  else
  {
    PrintHintText(client, "Invalid location for Tripmine");
  }
}

public Action:TurnBeamOn(Handle:timer, Handle:data)
{
  decl String:color[26];

  ResetPack(data);
  new client = ReadPackCell(data);
  new ent = ReadPackCell(data);

  if (IsClientInGame(client) && IsValidEntity(ent))
  {
    new team = GetClientTeam(client);
    if(team == TEAM_T) color = COLOR_T;
    else if(team == TEAM_CT) color = COLOR_CT;
    else color = COLOR_DEF;

    DispatchKeyValue(ent, "rendercolor", color);
    AcceptEntityInput(ent, "TurnOn");

    new Float:end[3];
    end[0] = ReadPackFloat(data);
    end[1] = ReadPackFloat(data);
    end[2] = ReadPackFloat(data);

    EmitSoundToAll(SND_MINEACT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
  }

  CloseHandle(data);
}

public mineBreak (const String:output[], caller, activator, Float:delay)
{
  UnhookSingleEntityOutput(caller, "OnBreak", mineBreak);
  AcceptEntityInput(caller,"kill");
}

public bool:FilterAll (entity, contentsMask)
{
  return false;
}


