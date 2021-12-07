//
// SourceMod Script
//
// Developed by <eVa>Dog
// February 2009
// http://www.theville.org
//

//
// DESCRIPTION:
// This plugin is a port of my TNT plugin
// originally created using EventScripts


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4.100"

#define ADMIN_LEVEL ADMFLAG_SLAY

new tntAmount[MAXPLAYERS+1]
new g_tntEnabled[MAXPLAYERS+1]
new tnt_entity[MAXPLAYERS+1][128]

new bool:pack_primed[MAXPLAYERS+1][128]
new bool:g_can_plant[MAXPLAYERS+1]

new Handle:g_Cvar_tntAmount   = INVALID_HANDLE
new Handle:g_Cvar_Damage      = INVALID_HANDLE
new Handle:g_Cvar_Admins      = INVALID_HANDLE
new Handle:g_Cvar_Enable      = INVALID_HANDLE
new Handle:g_Cvar_Delay       = INVALID_HANDLE
new Handle:g_Cvar_Restrict    = INVALID_HANDLE
new Handle:g_Cvar_Mode        = INVALID_HANDLE
new Handle:g_Cvar_tntDetDelay = INVALID_HANDLE
new Handle:g_Cvar_PlantDelay  = INVALID_HANDLE

new Handle:g_tntpack[MAXPLAYERS+1][128]

new String:g_TNTModel[128] 
new String:g_plant_sound[128]

new g_Explosion
new g_ent_location_offset

public Plugin:myinfo = 
{
	name = "Remote IED or TNT",
	author = "<eVa>Dog",
	description = "Plant packs and detonate them remotely or at a distance",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_plant", tnt, " -  Plants TNT at coords specified by player's crosshairs")
	RegConsoleCmd("sm_defuse", defuse, " -  Defuses a TNT pack under player's crosshairs ")
	RegConsoleCmd("sm_det", det, " -  Detonates a TNT pack under player's crosshairs ")
	
	CreateConVar("sm_tnt_version", PLUGIN_VERSION, "Version of SourceMod TNT on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_tntAmount   = CreateConVar("sm_tnt_amount", "2", " Number of tnt packs per player at spawn (max 10)", FCVAR_PLUGIN)
	g_Cvar_Damage      = CreateConVar("sm_tnt_damage", "200", " Amount of damage that the tnt does", FCVAR_PLUGIN)
	g_Cvar_Admins      = CreateConVar("sm_tnt_admins", "0", " Allow Admins only to use tnt", FCVAR_PLUGIN)
	g_Cvar_Enable      = CreateConVar("sm_tnt_enabled", "1", " Enable/Disable the TNT plugin", FCVAR_PLUGIN)
	g_Cvar_Delay       = CreateConVar("sm_tnt_delay", "5.0", " Delay between spawning and making tnt available", FCVAR_PLUGIN)
	g_Cvar_Restrict    = CreateConVar("sm_tnt_restrict", "0", " Class to restrict TNT to (see forum thread)", FCVAR_PLUGIN)
	g_Cvar_Mode        = CreateConVar("sm_tnt_mode", "1", " Detonation mode: 0=radio 1=crosshairs 2=timer", FCVAR_PLUGIN)
	g_Cvar_tntDetDelay = CreateConVar("sm_tnt_det_delay", "10", " Detonation delay", FCVAR_PLUGIN)
	g_Cvar_PlantDelay  = CreateConVar("sm_tnt_plant_delay", "1", " Delay between planting TNT", FCVAR_PLUGIN)
}

public OnMapStart()
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		HookEvent("player_spawn", PlayerSpawnEvent)
		HookEvent("player_death", PlayerDeathEvent)
		HookEvent("player_disconnect", PlayerDisconnectEvent)
		HookEvent("dod_round_start", RoundStartEvent)
		
		HookEntityOutput("prop_physics", "OnTakeDamage", TakeDamage)
		HookEntityOutput("prop_physics", "OnBreak", Break)
		
		g_Explosion = PrecacheModel("sprites/sprite_fire01.vmt")
		
		g_ent_location_offset = FindSendPropOffs("CDODPlayer", "m_vecOrigin")	
		
		g_TNTModel = "models/weapons/w_tnt.mdl"
		PrecacheModel(g_TNTModel, true)
		
		PrecacheSound("weapons/c4_plant.wav", true)
		strcopy(g_plant_sound, sizeof(g_plant_sound), "weapons/c4_plant.wav")
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_disconnect", PlayerDisconnectEvent)
	UnhookEvent("player_death", PlayerDeathEvent)
	UnhookEvent("dod_round_start", RoundStartEvent)
	
	UnhookEntityOutput("prop_physics", "OnTakeDamage", TakeDamage)
	UnhookEntityOutput("prop_physics", "OnBreak", Break)
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		PrintToConsole(client, "This server is running a TNT/IED plugin")
		PrintToConsole(client, "Bind a key to 'sm_plant' and the TNT will be planted where you aim your crosshairs")
		PrintToConsole(client, "Bind a key to 'sm_defuse' and defuse the TNT pack under your crosshairs")
		
		new String:detmsg[64]
		if (GetConVarInt(g_Cvar_Mode) == 1)
			strcopy(detmsg, sizeof(detmsg), "Bind a key to 'sm_det' and aim your crosshairs at the pack")
		if (GetConVarInt(g_Cvar_Mode) == 2)
			Format(detmsg, sizeof(detmsg), "Once planted, the pack will explode after %i seconds", GetConVarInt(g_Cvar_tntDetDelay))
		else
			strcopy(detmsg, sizeof(detmsg), "Bind a key to 'sm_det' to explode all planted packs")
			
		PrintToConsole(client, "Detonate: %s ", detmsg)
		
		PrintToConsole(client, "Each player receives %i TNT packs", GetConVarInt(g_Cvar_tntAmount))
	}
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
		{
			tnt_entity[client][i] = 0
		}
		
		if (GetConVarInt(g_Cvar_Admins) == 1)
		{
			if (GetUserFlagBits(client) & ADMIN_LEVEL)
			{
				tntAmount[client] = GetConVarInt(g_Cvar_tntAmount)
			}
			else
			{
				tntAmount[client] = 0
			}
		}
		else
		{
			if (GetConVarInt(g_Cvar_Restrict) > 0)
			{
				new class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
				
				class++
				if (class == GetConVarInt(g_Cvar_Restrict))
					tntAmount[client] = GetConVarInt(g_Cvar_tntAmount)
			}
			else
			{
				tntAmount[client] = GetConVarInt(g_Cvar_tntAmount)
			}
		}
		
		g_tntEnabled[client] = 0
		CreateTimer(GetConVarFloat(g_Cvar_Delay), SetTNT, client)
	}
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
		{
			if (tnt_entity[client][i] != 0)
			{
				CreateTimer(2.0, RemoveTNT, tnt_entity[client][i])
				tnt_entity[client][i] = 0
			}
		}
		
		tntAmount[client] = 0
	}
}



public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
		{
			if (tnt_entity[client][i] != 0)
			{
				CreateTimer(2.0, RemoveTNT, tnt_entity[client][i])
				tnt_entity[client][i] = 0
			}
		}
	}
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
			{
				if (tnt_entity[client][i] != 0)
				{
					CreateTimer(2.0, RemoveTNT, tnt_entity[client][i])
					tnt_entity[client][i] = 0
				}
			}
		}
	}
}

public Action:SetTNT(Handle:timer, any:client)
{
	g_tntEnabled[client] = 1
	g_can_plant[client] = true
}

public Action:RemoveTNT(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		new Float:tnt_pos[3], String:classname[256]
		GetEntDataVector(ent, g_ent_location_offset, tnt_pos)
		TE_SetupEnergySplash(tnt_pos, NULL_VECTOR, true)
		TE_SendToAll(0.1)
		
		GetEdictClassname(ent, classname, sizeof(classname))
		if (StrEqual(classname, "prop_physics", false))
        {
			RemoveEdict(ent)
		}
	}
}


public Action:tnt(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (g_tntEnabled[client])
		{	
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
			{ 
				if (g_can_plant[client])
				{
					if (tntAmount[client] > 0)
					{
						if (tntAmount[client] >= 10)
						{
							tntAmount[client] = 10
						}
						
						new Float:vAngles[3]
						new Float:vOrigin[3]
						new Float:pos[3]
						new Float:pos_angles[3]

						GetClientEyePosition(client,vOrigin)
						GetClientEyeAngles(client, vAngles)

						new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer)

						if(TR_DidHit(trace))
						{
							TR_GetEndPosition(pos, trace)
						}
						CloseHandle(trace)
						
						if (pos[2] >= (vOrigin[2] - 50))
							pos_angles[0] = 90.0
						else
							pos_angles[0] = 0.0
							
						new Float:distance = GetVectorDistance(vOrigin, pos)
								
						if (distance > 100)
						{
							PrintToChat(client, "[SM] Too far away to plant")
						}
						else
						{
							TE_SetupSparks(pos, NULL_VECTOR, 2, 1)
							TE_SendToAll(0.1)
							
							new ent = CreateEntityByName("prop_physics_override")
							tnt_entity[client][tntAmount[client]] = ent
							pack_primed[client][tntAmount[client]] = false
							
							g_tntpack[client][tntAmount[client]] = CreateDataPack()
							WritePackCell(g_tntpack[client][tntAmount[client]], client)
							WritePackCell(g_tntpack[client][tntAmount[client]], tntAmount[client])
							CreateTimer(5.0, SetDefuseState, g_tntpack[client][tntAmount[client]])

							SetEntityModel(ent, g_TNTModel)
							DispatchKeyValue(ent, "StartDisabled", "false")
							DispatchKeyValue(ent, "ExplodeRadius", "200")

							new String:explodeforce[16]
							
							if (GetConVarInt(FindConVar("mp_friendlyfire")))
								Format(explodeforce, sizeof(explodeforce), "%i", GetConVarInt(g_Cvar_Damage))
							else
								Format(explodeforce, sizeof(explodeforce), "%i", 0)
								
							DispatchKeyValue(ent, "ExplodeDamage", explodeforce)
							
							DispatchKeyValue(ent, "massScale", "1.0")
							DispatchKeyValue(ent, "inertiaScale", "0.1")
							DispatchKeyValue(ent, "pressuredelay", "2.0")					

							DispatchSpawn(ent)
							
							AcceptEntityInput(ent, "Enable")
							AcceptEntityInput(ent, "TurnOn")
							AcceptEntityInput(ent, "DisableMotion")												
							TeleportEntity(ent, pos, pos_angles, NULL_VECTOR)

														
							tntAmount[client]--
							PrintToChat(client, "[SM] TNT left: %i", tntAmount[client])
							
							EmitSoundToAll(g_plant_sound, ent, _, _, _, 0.8)
							
							AttachParticle(ent, "grenadetrail")
							
							CreateTimer(5.0, Prime, ent)
							CreateTimer(GetConVarFloat(g_Cvar_PlantDelay), AllowPlant, client)
							g_can_plant[client] = false
						}
					}
					else
					{
						PrintToChat(client, "[SM] No TNT left")
					}
				}
			}
		}
		else
		{
			PrintToChat(client, "[SM] TNT unavailable.  Please wait....")
		}
	}
	return Plugin_Handled
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity
} 

public Action:AllowPlant(Handle:timer, any:client)
{
	g_can_plant[client] = true
}

public Action:Prime(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		new String:tntname[128]	
		Format(tntname, sizeof(tntname), "TNT-%i", entity)
		DispatchKeyValue(entity, "targetname", tntname)
		
		DispatchKeyValue(entity, "physdamagescale", "9999.0")	
		DispatchKeyValue(entity, "spawnflags", "304")
		DispatchKeyValue(entity, "health", "1")
		SetEntProp(entity, Prop_Data, "m_takedamage", 2)
		
		AcceptEntityInput(entity, "EnableDamageForces")
		
		if (GetConVarInt(g_Cvar_Mode) == 2)
		{
			CreateTimer(1.0, Fuse, entity, TIMER_REPEAT)
			CreateTimer(GetConVarFloat(g_Cvar_tntDetDelay), DelayedDetonation, entity)
		}
	}
		
	return Plugin_Continue
}

public Action:DelayedDetonation(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "break")
	}
}

public Action:Fuse(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		new Float:tnt_pos[3]
		GetEntDataVector(entity, g_ent_location_offset, tnt_pos)
		TE_SetupSparks(tnt_pos, NULL_VECTOR, 2, 1)
		TE_SendToAll(0.1)
	}
	else
	{
		KillTimer(timer)
	}
}

public Action:SetDefuseState(Handle:timer, any:tntpack)
{
	ResetPack(tntpack)
	new owner = ReadPackCell(tntpack)
	new tntnumber = ReadPackCell(tntpack)
	CloseHandle(tntpack)
	
	pack_primed[owner][tntnumber] = true
}

public TakeDamage(const String:output[], caller, activator, Float:delay)
{	
	for (new client = 1; client <= MaxClients; client++)
	{
		for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
		{
			if (tnt_entity[client][i] == caller)
			{
				AcceptEntityInput(caller,"break")
				break
			}
		}
	}
}

public Break(const String:output[], caller, activator, Float:delay)
{	
	new owner
	
	new Float:tnt_pos[3]
	GetEntDataVector(caller, g_ent_location_offset, tnt_pos)
	TE_SetupExplosion(tnt_pos, g_Explosion, 10.0, 1, 0, 600, 5000)
	TE_SendToAll()
	
	
	if (GetConVarInt(FindConVar("mp_friendlyfire")) == 0)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
			{
				if (tnt_entity[client][i] == caller)
				{
					owner = client
					tnt_entity[client][i] = 0
					break
				}
			}
		}

		if (owner == 0)
			return
		
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				if (IsPlayerAlive(target))
				{
					if (GetClientTeam(owner) != GetClientTeam(target))
					{
						new Float:targetVector[3]
						GetClientAbsOrigin(target, targetVector)
														
						new Float:distance = GetVectorDistance(targetVector, tnt_pos)
								
						if (distance < (GetConVarInt(g_Cvar_Damage)))
						{
							LogAction(owner, target, "\"%L\" bombed \"%L\"", owner, target)
							
							PushAway(caller, target)
							ForcePlayerSuicide(target)
						}
					}
				}
			}
		}
	}
	AcceptEntityInput(caller,"kill")
}

public Action:defuse(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new aim_entity = GetClientAimTarget(client, false)
		
		new owner
		new tntpack
		
		for (new target = 1; target <= MaxClients; target++)
		{
			for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
			{
				if (tnt_entity[target][i] == aim_entity)
				{
					owner = target
					tntpack = i
					break
				}
			}
		}
		
		if (owner == 0)
			return Plugin_Handled
		
		new Float:tnt_pos[3]
		GetEntDataVector(tnt_entity[owner][tntpack], g_ent_location_offset, tnt_pos)
		new Float:targetVector[3]
		GetClientAbsOrigin(client, targetVector)
															
		new Float:distance = GetVectorDistance(targetVector, tnt_pos)
		
		if (pack_primed[owner][tntpack])
		{
			if (distance > 100)
			{
				PrintToChat(client, "[SM] Too far away to defuse")
			}
			else
			{
				CreateTimer(2.0, RemoveTNT, tnt_entity[owner][tntpack])
				tnt_entity[client][tntpack] = 0
				
				tntAmount[client]++
				
				if (tntAmount[client] >= GetConVarInt(g_Cvar_tntAmount))
					tntAmount[client] = GetConVarInt(g_Cvar_tntAmount)
							
				PrintToChat(client, "[SM] TNT left: %i", tntAmount[client])
				PrintToChat(owner, "[SM] TNT pack defused")
			}
		}
		else
		{
			PrintToChat(client, "[SM] Cannot be defused yet...")
		}
	}
	
	return Plugin_Handled
}

public Action:det(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (GetConVarInt(g_Cvar_Mode) == 1)
		{
			new aim_entity = GetClientAimTarget(client, false)
		
			new owner
			new tntpack
		
			for (new target = 1; target <= MaxClients; target++)
			{
				for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
				{
					if (tnt_entity[target][i] == aim_entity)
					{
						owner = target
						tntpack = i
						break
					}
				}
			}
			
			if (owner == 0)
				return Plugin_Handled
			
			
			if (pack_primed[owner][tntpack])
			{
				if (client != owner)
				{
					PrintToChat(client, "[SM] This is not your TNT pack")
				}
				else
				{
					AcceptEntityInput(tnt_entity[owner][tntpack], "break")
				}
			}
			else
			{
				PrintToChat(client, "[SM] Still priming...Cannot be detonated yet...")
			}
		}
		else if (GetConVarInt(g_Cvar_Mode) == 0)
		{
			for (new i = GetConVarInt(g_Cvar_tntAmount); i > 0 ; i--)
			{
				if (tnt_entity[client][i] != 0)
				{
					if (IsValidEntity(tnt_entity[client][i]))
					{
						AcceptEntityInput(tnt_entity[client][i], "break")
					}
				}
			}
		}
	}
			
	return Plugin_Handled
}

public Action:KillExplosion(Handle:timer, any:ent)
{
    if (IsValidEntity(ent))
    {
        new String:classname[256]
        GetEdictClassname(ent, classname, sizeof(classname))
        if (StrEqual(classname, "env_explosion", false))
        {
            RemoveEdict(ent)
        }
    }
}

// Greyscale's AntiStick code adapted
PushAway(entity, client)
{
	new Float:vector[3]
			
	new Float:entityloc[3]
	new Float:clientloc[3]
			
	GetEntDataVector(entity, g_ent_location_offset, entityloc)
	GetClientAbsOrigin(client, clientloc)
			
	MakeVectorFromPoints(entityloc, clientloc, vector)
			
	NormalizeVector(vector, vector)
	ScaleVector(vector, 1000.0)
	vector[2]+=200
			
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector)
}

// L.Duke's Particle code
AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system")
	
	new String:tName[128]
	if (IsValidEdict(particle))
	{
		new Float:pos[3]
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos)
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR)
		
		Format(tName, sizeof(tName), "target%i", ent)
		DispatchKeyValue(ent, "targetname", tName)
		
		DispatchKeyValue(particle, "targetname", "tf2particle")
		DispatchKeyValue(particle, "parentname", tName)
		DispatchKeyValue(particle, "effect_name", particleType)
		DispatchSpawn(particle)
		SetVariantString(tName)
		AcceptEntityInput(particle, "SetParent", particle, particle, 0)
		ActivateEntity(particle)
		AcceptEntityInput(particle, "start")
		CreateTimer(5.0, DeleteParticles, particle)
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[256]
        GetEdictClassname(particle, classname, sizeof(classname))
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle)
        }
    }
}

