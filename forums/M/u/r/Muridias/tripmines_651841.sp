#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

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

new maxplayers, maxents;
new g_condOffset;

// convars
//new Handle:cvNumMines = INVALID_HANDLE;
new Handle:cvActTime = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;
new Handle:cvTeamRestricted = INVALID_HANDLE;
new Handle:cvNumMinesScout = INVALID_HANDLE;
new Handle:cvNumMinesSniper = INVALID_HANDLE;
new Handle:cvNumMinesSoldier = INVALID_HANDLE;
new Handle:cvNumMinesDemoman = INVALID_HANDLE;
new Handle:cvNumMinesMedic = INVALID_HANDLE;
new Handle:cvNumMinesHeavy = INVALID_HANDLE;
new Handle:cvNumMinesPyro = INVALID_HANDLE;
new Handle:cvNumMinesSpy = INVALID_HANDLE;
new Handle:cvNumMinesEngi = INVALID_HANDLE;

new Handle:cvDamage = INVALID_HANDLE;
new Handle:cvRadius = INVALID_HANDLE;

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
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_disconnect", PlayerDisconnect);
	
	// convars
	CreateConVar("sm_tripmines_version", PLUGIN_VERSION, "Tripmines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	//cvNumMines = CreateConVar("sm_tripmines_allowed", "20");
	cvActTime = CreateConVar("sm_tripmines_activate_time", "2.0");
	cvModel = CreateConVar("sm_tripmines_model", "models/props_lab/tpplug.mdl");
	cvTeamRestricted = CreateConVar("sm_tripmines_restrictedteam", "0");
	cvDamage = CreateConVar("sm_tripmines_damage", "100");
	cvRadius = CreateConVar("sm_tripmines_radius", "256");
	
	cvNumMinesScout = CreateConVar("sm_tripmines_scout_limit", "0");
	cvNumMinesSniper = CreateConVar("sm_tripmines_sniper_limit", "1");
	cvNumMinesSoldier = CreateConVar("sm_tripmines_soldier_limit", "0");
	cvNumMinesDemoman = CreateConVar("sm_tripmines_demoman_limit", "0");
	cvNumMinesMedic = CreateConVar("sm_tripmines_medic_limit", "0");
	cvNumMinesHeavy = CreateConVar("sm_tripmines_heavy_limit", "0");
	cvNumMinesPyro = CreateConVar("sm_tripmines_pyro_limit", "0");
	cvNumMinesSpy = CreateConVar("sm_tripmines_spy_limit", "1");
	cvNumMinesEngi = CreateConVar("sm_tripmines_engi_limit", "2");
	
	// commands
	RegConsoleCmd("sm_tripmine", Command_TripMine);
	
	AutoExecConfig( true, "plugin_tripmines");
}

public OnEventShutdown()
{
	UnhookEvent("player_death", PlayerDeath);
	UnhookEvent("player_spawn",PlayerSpawn);
}

public OnMapStart()
{
	maxplayers = GetMaxClients();
	maxents = GetMaxEntities();
	g_condOffset = FindSendPropInfo("CTFPlayer","m_nPlayerCond");
	
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
public OnClientPutInServer(client)
{
	if(client && !IsFakeClient(client)) gRemaining[client] = 0;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	switch(TF2_GetPlayerClass(client)){
		//scout
		case 1:{
			gRemaining[client] = GetConVarInt(cvNumMinesScout);
		}
		//sniper
		case 2:{
			gRemaining[client] = GetConVarInt(cvNumMinesSniper);
		}
		//soldier
		case 3:{
			gRemaining[client] = GetConVarInt(cvNumMinesSoldier);
		}
		//demoman
		case 4:{
			gRemaining[client] = GetConVarInt(cvNumMinesDemoman);
		}
		//medic
		case 5:{
			gRemaining[client] = GetConVarInt(cvNumMinesMedic);
		}
		//heavy
		case 6:{
			gRemaining[client] = GetConVarInt(cvNumMinesHeavy);
		}
		//pyro
		case 7:{
			gRemaining[client] = GetConVarInt(cvNumMinesPyro);
		}
		//spy
		case 8:{
			gRemaining[client] = GetConVarInt(cvNumMinesSpy);
		}
		//engineer
		case 9:{
			gRemaining[client] = GetConVarInt(cvNumMinesEngi);
		}
		default:{
			gRemaining[client] = 0;
		}
		
	}
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	gRemaining[client] = 0;
	return Plugin_Continue;
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for(new i = maxplayers; i < maxents; i++)
	{
		if(IsValidEntity(i))
		{
			if(GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == client)
			{
				RemoveEdict(i);
			}
		}
		//Why is this here...?
		return Plugin_Continue;
	}
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
	
	//prevent spy from planting a tripmine while cloaked
	new cond = GetEntData(client, g_condOffset);
	switch(TF2_GetPlayerClass(client)){
		case 8:{
			if(cond == 16 || cond == 20 || cond == 24){
				return Plugin_Handled;
			}
		}
	}
	
	// call SetMine if any remain in client's inventory
	if (gRemaining[client]>0)
		SetMine(client);
	else 
	PrintHintText(client, "You do not have any tripmines.");
	return Plugin_Handled;
}


SetMine(client)
{
	// setup unique target names for entities to be created with
	new String:beam[64];
	new String:beammdl[64];
	new String:tmp[128];
	new String:damage[8];
	new String:radius[8];
	Format(beam, sizeof(beam), "%d", gCount);
	Format(beammdl, sizeof(beammdl), "tmbeammdl%d", gCount);
	gCount++;
	if (gCount>10000)
		gCount = 1;
	
	
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
		
		IntToString(GetConVarInt(cvRadius), radius, sizeof(radius));
		IntToString(GetConVarInt(cvDamage), damage, sizeof(damage));
		
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
		DispatchKeyValue(ent, "ExplodeRadius", radius);
		DispatchKeyValue(ent, "ExplodeDamage", damage);
		Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
		DispatchKeyValue(ent, "OnHealthChanged", tmp);
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", beam);
		DispatchKeyValue(ent, "OnBreak", tmp);
		SetEntProp(ent, Prop_Data, "m_takedamage", 2);
		AcceptEntityInput(ent, "Enable");
		HookSingleEntityOutput(ent, "OnBreak", mineBreak2, true);
		
		// create laser beam
		new ent2 = CreateEntityByName("env_beam");
		TeleportEntity(ent2, beamend, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(ent2, MDL_LASER);
		DispatchKeyValue(ent2, "texture", MDL_LASER);
		DispatchKeyValue(ent2, "targetname", beam);
		AcceptEntityInput(ent2, "AddOutput");
		DispatchKeyValue(ent2, "TouchType", "4");
		DispatchKeyValue(ent2, "LightningStart", beam);
		DispatchKeyValue(ent2, "BoltWidth", "4.0");
		DispatchKeyValue(ent2, "life", "0");
		DispatchKeyValue(ent2, "rendercolor", "0 0 0");
		DispatchKeyValue(ent2, "renderamt", "0");
		DispatchKeyValue(ent2, "HDRColorScale", "1.0");
		DispatchKeyValue(ent2, "decalname", "Bigshot");
		DispatchKeyValue(ent2, "StrikeTime", "0");
		DispatchKeyValue(ent2, "TextureScroll", "35"); 
		SetEntPropVector(ent2, Prop_Data, "m_vecEndPos", end);
		SetEntPropFloat(ent2, Prop_Data, "m_fWidth", 4.0);
		SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", client);
		AcceptEntityInput(ent2, "TurnOff");
		HookSingleEntityOutput(ent2, "OnTouchedByEntity", mineBreak, true);
		
		new Handle:data = CreateDataPack();
		CreateTimer(GetConVarFloat(cvActTime), TurnBeamOn, data);
		WritePackCell(data, client);
		WritePackCell(data, ent2);
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

public mineBreak (const String:output[], caller, activator, Float:delay)
{
	new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
	new cTeam = GetClientTeam(owner);
	new aTeam = GetClientTeam(activator);
	
	decl String:target[64];
	GetEntPropString(caller, Prop_Data, "m_iName", target, sizeof(target));
	
	if(aTeam != cTeam)
	{
		new String:tmp[128];
		Format(tmp, sizeof(tmp), "tmbeammdl%s,Break,,0,-1", target);
		
		DispatchKeyValue(caller, "OnTouchedByEntity", tmp);
		
		UnhookSingleEntityOutput(caller, "OnBreak", mineBreak);
		AcceptEntityInput(caller,"kill");
	}
}

public mineBreak2 (const String:output[], caller, activator, Float:delay)
{
	UnhookSingleEntityOutput(caller, "OnBreak", mineBreak2);
	AcceptEntityInput(caller,"kill");
}

public bool:FilterAll (entity, contentsMask)
{
	return false;
}


