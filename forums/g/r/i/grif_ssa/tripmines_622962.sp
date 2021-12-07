#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0.2b"

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"
#define MDL_MINE "models/props_lab/tpplug.mdl"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"
#define SND_BUYMINE "items/itempickup.wav"
#define SND_CANTBUY "buttons/weapon_cant_buy.wav"

#define TEAM_T 2
#define TEAM_CT 3

#define COLOR_T "255 0 0"
#define COLOR_CT "0 0 255"
#define COLOR_DEF "0 255 255"

#define MAX_LINE_LEN 256

// globals
new gRemaining[MAXPLAYERS+1];                 // how many tripmines player has this spawn
new gCount = 1;

// for buy
new gInBuyZone = -1;
new gAccount = -1;

// convars
new Handle:cvNumMines = INVALID_HANDLE;
new Handle:cvMineCost = INVALID_HANDLE;
new Handle:cvActTime = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Tripmines",
	author = "L. Duke (mod by user)",
	description = "Plant a trip mine",
	version = PLUGIN_VERSION,
	url = "http://www.lduke.com/"
};


public OnPluginStart() 
{
  // translations
  LoadTranslations("plugin.tripmines");

  // events
  HookEvent("player_death", PlayerDeath);
  
  // convars
  CreateConVar("sm_tripmines_version", PLUGIN_VERSION, "Tripmines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  cvNumMines = CreateConVar("sm_tripmines_allowed", "3");
  cvActTime = CreateConVar("sm_tripmines_activate_time", "2.0");
  cvMineCost = CreateConVar("sm_tripmine_cost", "500");

  // prop offset
  gInBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
  gAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

  // commands
  RegConsoleCmd("sm_tripmine", Command_TripMine);
  RegConsoleCmd("sm_buytripmines", Command_BuyTripMines);
}

public OnEventShutdown(){
	UnhookEvent("player_death", PlayerDeath);
}

public OnMapStart()
{
  // precache models
  PrecacheModel(MDL_MINE, true);
  PrecacheModel(MDL_LASER, true);
  
  // precache sounds
  PrecacheSound(SND_MINEPUT, true);
  PrecacheSound(SND_MINEACT, true);
  PrecacheSound(SND_BUYMINE, true);
  PrecacheSound(SND_CANTBUY, true);
}

// When a new client is put in the server we reset their mines count
public OnClientPutInServer(client){
  if(client && !IsFakeClient(client)) gRemaining[client] = 0;
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
   
  if (gRemaining[client]>0) {
    SetMine(client);
  }
  else {
    PrintHintText(client, "%t", "nomines");
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
    SetEntityModel(ent,MDL_MINE);
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
    PrintHintText(client, "%t", "left", gRemaining[client]);
  }
  else
  {
    PrintHintText(client, "%t", "locationerr");
  }
}

public Action:TurnBeamOn(Handle:timer, Handle:data)
{
  decl String:color[26];

  ResetPack(data);
  new client = ReadPackCell(data);
  new ent = ReadPackCell(data);

  if (IsValidEntity(ent))
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

public bool:FilterAll (entity, contentsMask)
{
  return false;
}

public Action:Command_BuyTripMines(client, args){
  new max;
  new cnt;
  new cost;
  new money;
  decl String:txt[MAX_LINE_LEN];

  if(!client || IsFakeClient(client) || !IsPlayerAlive(client) || gInBuyZone == -1 || gAccount == -1)
    return Plugin_Handled;

  // args
  if(args > 0){
    GetCmdArg(1, txt, sizeof(txt));
    cnt = StringToInt(txt);
  }

  // buy
  if(cnt > 0){

    // check buy zone
    if(!GetEntData(client, gInBuyZone, 1)){
      PrintCenterText(client, "%t", "notinbuyzone");
      return Plugin_Handled;
    }

    cost = GetConVarInt(cvMineCost);
    money = GetEntData(client, gAccount);
    do{

      // check max count
      max = GetConVarInt(cvNumMines);
      if(gRemaining[client] >= max){
        PrintHintText(client, "%t", "maxmines", max);
        return Plugin_Handled;
      }

      // got money?
      money-= cost;
      if(money < 0){
        PrintHintText(client, "%t", "nomoney", cost, gRemaining[client]);
        EmitSoundToClient(client, SND_CANTBUY);
        return Plugin_Handled;
      }

      // deal
      SetEntData(client, gAccount, money);
      gRemaining[client]++;
      EmitSoundToClient(client, SND_BUYMINE);

    }while(--cnt);
  }

  // info
  PrintHintText(client, "%t", "cntmines", gRemaining[client]);
  
  return Plugin_Handled;
}
