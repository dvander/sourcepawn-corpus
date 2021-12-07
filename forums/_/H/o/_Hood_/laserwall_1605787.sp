#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

#define TRACE_START 10.0
#define TRACE_END 80.0

#define MDL_LASER "sprites/laser.vmt"
#define MDL_MINE "models/props_lab/tpplug.mdl"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"
#define SND_BUYMINE "items/itempickup.wav"
#define SND_CANTBUY "buttons/weapon_cant_buy.wav"

public Plugin:myinfo = {
	name = "Laserwall",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Plants a laser wall",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_lw", Command_LaserWall, "Plants laser mine");
	HookEntityOutput("env_beam", "OnTouchedByEntity", OnTouchedByEntity);
	
	HookEvent("player_death", OnPlayerDeath);
}

public OnMapStart()
{
	PrecacheModel(MDL_MINE, true);
	PrecacheModel(MDL_LASER, true);

	PrecacheSound(SND_MINEPUT, true);
	PrecacheSound(SND_MINEACT, true);
	PrecacheSound(SND_BUYMINE, true);
	PrecacheSound(SND_CANTBUY, true);
}

public OnClientDisconnect(client)
{
	new index = MaxClients+1;
	while ((index = FindEntityByClassname(index, "env_beam")) != -1)
	{
		if (IsValidEntity(index) && GetEntPropEnt(index, Prop_Data, "m_hOwnerEntity") == client)
			AcceptEntityInput(index, "KillHierarchy");
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	OnClientDisconnect(client);
}

public Action:Command_LaserWall(client, argc)
{
	PlantMine(client);
	return Plugin_Handled;
}

public OnTouchedByEntity(const String:output[], caller, activator, Float:delay)
{
	new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity");
	if (owner == -1 || activator == owner || GetClientTeam(activator) == GetClientTeam(owner))
		return;
	
	SDKHooks_TakeDamage(activator, caller, owner, 500.0, DMG_ENERGYBEAM);
}

PlantMine(client)
{
	new Float:startent[3], Float:angle[3], Float:end[3], Float:normal[3], Float:beamend[3];
	GetClientEyePosition(client, startent);
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(end, end);

	startent[0] = startent[0] + end[0] * TRACE_START;
	startent[1] = startent[1] + end[1] * TRACE_START;
	startent[2] = startent[2] + end[2] * TRACE_START;

	end[0] = startent[0] + end[0] * TRACE_END;
	end[1] = startent[1] + end[1] * TRACE_END;
	end[2] = startent[2] + end[2] * TRACE_END;
	
	TR_TraceRayFilter(startent, end, CONTENTS_SOLID, RayType_EndPoint, FilterAll, 0);
	
	if (TR_DidHit(INVALID_HANDLE))
	{
		TR_GetEndPosition(end, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, normal);
		
		GetVectorAngles(normal, normal);
		
		TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
		TR_GetEndPosition(beamend, INVALID_HANDLE);
		
		
		new ent = CreateEntityByName("prop_physics_override");
		new beament = CreateEntityByName("env_beam");
		
		decl String:start[30], String:tmp[200];
		Format(start, sizeof(start), "Beam%i", beament);
		
		SetEntityModel(ent, MDL_MINE);
		
		DispatchKeyValue(ent, "StartDisabled", "false");
		DispatchKeyValue(ent, "ExplodeRadius", "300");
		DispatchKeyValue(ent, "ExplodeDamage", "200");
		DispatchSpawn(ent);
		
		TeleportEntity(ent, end, normal, NULL_VECTOR);
		
		SetEntProp(ent, Prop_Data, "m_usSolidFlags", 152);
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
		SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
		SetEntProp(ent, Prop_Data, "m_takedamage", 2);
		SetEntProp(ent, Prop_Data, "m_iHealth", 300);
		
		SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
		
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", start);
		DispatchKeyValue(ent, "OnBreak", tmp);
		
		SetEntityMoveType(ent, MOVETYPE_NONE);
		
		AcceptEntityInput(ent, "Enable");
		
		EmitSoundToAll(SND_MINEPUT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
		
		
		
		// Set keyvalues on the beam.
		DispatchKeyValue(beament, "targetname", start);
		DispatchKeyValue(beament, "damage", "0");
		DispatchKeyValue(beament, "framestart", "0");
		DispatchKeyValue(beament, "BoltWidth", "4.0");
		DispatchKeyValue(beament, "renderfx", "0");
		DispatchKeyValue(beament, "TouchType", "3"); // 0 = none, 1 = player only, 2 = NPC only, 3 = player or NPC, 4 = player, NPC or physprop
		DispatchKeyValue(beament, "framerate", "0");
		DispatchKeyValue(beament, "decalname", "Bigshot");
		DispatchKeyValue(beament, "TextureScroll", "35");
		DispatchKeyValue(beament, "HDRColorScale", "1.0");
		DispatchKeyValue(beament, "texture", MDL_LASER);
		DispatchKeyValue(beament, "life", "0"); // 0 = infinite, beam life time in seconds
		DispatchKeyValue(beament, "StrikeTime", "1"); // If beam life time not infinite, this repeat it back
		DispatchKeyValue(beament, "LightningStart", start);
		DispatchKeyValue(beament, "spawnflags", "1"); // 0 disable, 1 = start on, etc etc. look from hammer editor
		DispatchKeyValue(beament, "NoiseAmplitude", "0"); // straight beam = 0, other make noise beam
		DispatchKeyValue(beament, "Radius", "256");
		DispatchKeyValue(beament, "rendercolor", "255 255 255");
		DispatchKeyValue(beament, "renderamt", "100");
		SetEntityModel(beament, MDL_LASER);
		
		TeleportEntity(beament, beamend, NULL_VECTOR, NULL_VECTOR);
		
		SetEntPropVector(beament, Prop_Data, "m_vecEndPos", end);
		SetEntPropFloat(beament, Prop_Data, "m_fWidth", 4.0);
		SetEntPropEnt(beament, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(beament, Prop_Data, "m_hMoveChild", ent);
		
		AcceptEntityInput(beament, "TurnOn");

		Format(tmp, sizeof(tmp), "%s,TurnOff,,0.001,-1", start);
		DispatchKeyValue(beament, "OnTouchedByEntity", tmp);
		Format(tmp, sizeof(tmp), "%s,TurnOn,,0.002,-1", start);
		DispatchKeyValue(beament, "OnTouchedByEntity", tmp);

		EmitSoundToAll(SND_MINEACT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
	}
}

public bool:FilterAll (entity, contentsMask)
{
	return false;
}