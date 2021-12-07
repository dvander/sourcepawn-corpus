#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0.4"

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"

#define COLOR_RED "255 0 0"
#define COLOR_BLU "0 0 255"

#define TF_TEAM_BLU		3
#define TF_TEAM_RED		2

#define MAX_LINE_LEN 256

#define PLAYERCOND_SPYCLOAK (1<<4)

// globals
new remaining[MAXPLAYERS+1];    // how many tripmines player has this spawn
new count = 1;
new String:mdlMine[256];

new maxplayers, maxents;

// convars
new Handle:model = INVALID_HANDLE;
new Handle:activation_time = INVALID_HANDLE;
new Handle:restricted_team = INVALID_HANDLE;

new Handle:scout = INVALID_HANDLE;
new Handle:sniper = INVALID_HANDLE;
new Handle:soldier = INVALID_HANDLE;
new Handle:demoman = INVALID_HANDLE;
new Handle:medic = INVALID_HANDLE;
new Handle:heavy = INVALID_HANDLE;
new Handle:pyro = INVALID_HANDLE;
new Handle:spy = INVALID_HANDLE;
new Handle:engineer = INVALID_HANDLE;

new Handle:damage = INVALID_HANDLE;
new Handle:radius = INVALID_HANDLE;

new Handle:friendly_fire = INVALID_HANDLE;
new Handle:cloak = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Tripmines",
	author = "L. Duke (modded by Goss)",
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
	
	model = CreateConVar("sm_tripmines_model", "models/props_lab/tpplug.mdl");
	
	activation_time = CreateConVar("sm_tripmines_activate_time", "2.0");
	restricted_team = CreateConVar("sm_tripmines_restrictedteam", "0");
	
	damage = CreateConVar("sm_tripmines_damage", "75");
	radius = CreateConVar("sm_tripmines_radius", "200");
	
	scout = CreateConVar("sm_tripmines_scout_limit", "0");
	sniper = CreateConVar("sm_tripmines_sniper_limit", "5");
	soldier = CreateConVar("sm_tripmines_soldier_limit", "0");
	demoman = CreateConVar("sm_tripmines_demoman_limit", "0");
	medic = CreateConVar("sm_tripmines_medic_limit", "0");
	heavy = CreateConVar("sm_tripmines_heavy_limit", "0");
	pyro = CreateConVar("sm_tripmines_pyro_limit", "0");
	spy = CreateConVar("sm_tripmines_spy_limit", "5");
	engineer = CreateConVar("sm_tripmines_engi_limit", "5");
	
	friendly_fire = CreateConVar("sm_tripmines_friendly_fire", "false");
	cloak = CreateConVar("sm_tripmines_engi_limit", "false");
	
	// commands
	RegConsoleCmd("sm_tripmine", Command_TripMine);
	RegAdminCmd("sm_clear", Command_Clear, ADMFLAG_GENERIC, "");
	
	AutoExecConfig(true, "trip_mines", "sourcemod");
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
	
	// set model based on cvar
	GetConVarString(model, mdlMine, sizeof(mdlMine));
	
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
	if(client && !IsFakeClient(client)) 
	{
		remaining[client] = 0;
	}
}
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout:{
			remaining[client] = GetConVarInt(scout);
		}
		case TFClass_Sniper:{
			remaining[client] = GetConVarInt(sniper);
		}
		case TFClass_Soldier:{
			remaining[client] = GetConVarInt(soldier);
		}
		case TFClass_DemoMan:{
			remaining[client] = GetConVarInt(demoman);
		}
		case TFClass_Medic:{
			remaining[client] = GetConVarInt(medic);
		}
		case TFClass_Heavy:{
			remaining[client] = GetConVarInt(heavy);
		}
		case TFClass_Pyro:{
			remaining[client] = GetConVarInt(pyro);
		}
		case TFClass_Spy:{
			remaining[client] = GetConVarInt(spy);
		}
		case TFClass_Engineer:{
			remaining[client] = GetConVarInt(engineer);
		}
		default:{
			remaining[client] = 0;
		}
		
	}
	
	removeMines(client);
	
	return Plugin_Continue;
}
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	removeMines(client);
	
	remaining[client] = 0;
	return Plugin_Continue;
}
public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	removeMines(client);
	
	return Plugin_Continue;
}
removeMines(client)
{
	for(new i = maxplayers; i <= maxents; i++)
	{
		if(IsValidEntity(i))
		{
			decl String:classname[32];
			GetEdictClassname(i, classname, sizeof(classname)); 
			
			if(StrEqual(classname, "env_beam") && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == client)
			{
				RemoveEdict(i);
			}
			if(StrEqual(classname, "prop_physics") && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == client)
			{
				decl String:target[64];
				GetEntPropString(i, Prop_Data, "m_iName", target, sizeof(target));
				
				if(StrContains(target, "tripmine", false) == 0)
				{
					RemoveEdict(i);
				}
			}
		}
	}
}
public Action:Command_Clear(client, args)
{
	for(new i = maxplayers; i <= maxents; i++)
	{
		if(IsValidEntity(i))
		{
			decl String:classname[32];
			GetEdictClassname(i, classname, sizeof(classname)); 
			
			if(StrEqual(classname, "env_beam"))
			{
				RemoveEdict(i);
			}
			else if(StrEqual(classname, "prop_physics"))
			{
				decl String:target[64];
				GetEntPropString(i, Prop_Data, "m_iName", target, sizeof(target));
				
				if(StrContains(target, "tripmine", false) == 0)
				{
					RemoveEdict(i);
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_TripMine(client, args)
{  
	// make sure client is not spectating
	if(GetConVarBool(cloak))
	{
		new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		if(cond & PLAYERCOND_SPYCLOAK)
		{
			return Plugin_Handled;
		}
	}
	if (!IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	// check restricted team 
	new team = GetClientTeam(client);
	
	if(team == GetConVarInt(restricted_team))
	{ 
		PrintHintText(client, "Your team does not have access to this equipment.");
		return Plugin_Handled;
	}
	
	// call SetMine if any remain in client's inventory
	if (remaining[client] > 0)
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
	
	new String:sdamage[8];
	new String:sradius[8];
	
	Format(beam, sizeof(beam), "%d", count);
	Format(beammdl, sizeof(beammdl), "tripmine%d", count);
	
	count++;
	if (count > 10000)
	{
		count = 1;
	}
	
	// trace client view to get position and angles for tripmine
	decl Float:start[3], Float:angle[3], Float:end[3], Float:normal[3], Float:beamend[3];
	GetClientEyePosition(client, start );
	GetClientEyeAngles(client, angle );
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
		remaining[client] -= 1;
		
		// find angles for tripmine
		TR_GetEndPosition(end, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, normal);
		GetVectorAngles(normal, normal);
		
		// trace laser beam
		TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
		TR_GetEndPosition(beamend, INVALID_HANDLE);
		
		IntToString(GetConVarInt(radius), sradius, sizeof(sradius));
		IntToString(GetConVarInt(damage), sdamage, sizeof(sdamage));
		
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
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		DispatchKeyValue(ent, "ExplodeRadius", sradius);
		DispatchKeyValue(ent, "ExplodeDamage", sdamage);
		Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
		DispatchKeyValue(ent, "OnHealthChanged", tmp);
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", beam);
		DispatchKeyValue(ent, "OnBreak", tmp);
		//SetEntProp(ent, Prop_Data, "m_takedamage", 2);
		AcceptEntityInput(ent, "Enable");
		
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
		HookSingleEntityOutput(ent2, "OnTouchedByEntity", mineBreak, false);
		
		new Handle:data = CreateDataPack();
		CreateTimer(GetConVarFloat(activation_time), TurnBeamOn, data);
		WritePackCell(data, client);
		WritePackCell(data, ent2);
		WritePackFloat(data, end[0]);
		WritePackFloat(data, end[1]);
		WritePackFloat(data, end[2]);
		
		// play sound
		EmitSoundToAll(SND_MINEPUT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
		
		// send message
		PrintHintText(client, "Tripmines remaining: %d", remaining[client]);
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
		if(team == TF_TEAM_BLU) 
		{
			color = COLOR_BLU;
		}
		else if(team == TF_TEAM_RED) 
		{
			color = COLOR_RED;
		}
		
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
public mineBreak(const String:output[], caller, activator, Float:delay)
{
	AcceptEntityInput(caller, "TurnOff");
	AcceptEntityInput(caller, "TurnOn");
	
	new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
	new cTeam = GetClientTeam(owner);
	new aTeam = GetClientTeam(activator);
	
	decl String:target[64];
	GetEntPropString(caller, Prop_Data, "m_iName", target, sizeof(target));
	
	new String:tmp[128];
	Format(tmp, sizeof(tmp), "tripmine%s,Break,,0,-1", target);
		
	if(GetConVarBool(friendly_fire) || aTeam != cTeam)
	{
		DispatchKeyValue(caller, "OnTouchedByEntity", tmp);
		
		UnhookSingleEntityOutput(caller, "OnBreak", mineBreak);
		AcceptEntityInput(caller,"kill");
	}
}
public bool:FilterAll (entity, contentsMask)
{
	return false;
}