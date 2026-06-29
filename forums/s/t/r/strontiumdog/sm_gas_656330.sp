//
// SourceMod Script
//
// Developed by <eVa>Dog
// July 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// This plugin is a port of my Gas plugin
// originally created using EventScripts
// 
// Trace routine borrowed from Spazman0's Teleport script
//
// CHANGELOG:
// - 07.18.2008 Version 1.0.100

// - 07.18.2008 Version 1.0.101
// Added detection for friendly fire
// Added gas that doesn't hurt own team

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.101"

#define ADMIN_LEVEL ADMFLAG_SLAY

new gasAmount[33]

new bool:g_roundstart = false

new Handle:g_Cvar_GasAmount = INVALID_HANDLE
new Handle:g_Cvar_Red    = INVALID_HANDLE
new Handle:g_Cvar_Green  = INVALID_HANDLE
new Handle:g_Cvar_Blue   = INVALID_HANDLE
new Handle:g_Cvar_Random = INVALID_HANDLE
new Handle:g_Cvar_Damage = INVALID_HANDLE
new Handle:g_Cvar_Admins = INVALID_HANDLE
new Handle:g_Cvar_Time   = INVALID_HANDLE
new Handle:timer_handle[65][128]
new Handle:hurtdata[65][128]

new String:GameName[64]

public Plugin:myinfo = 
{
	name = "Gas",
	author = "<eVa>Dog",
	description = "Gas plugin",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_gas", Gas, " -  Calls in gas at coords specified by player's crosshairs")
	
	CreateConVar("sm_gas_version", PLUGIN_VERSION, "Version of SourceMod Gas on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_GasAmount   = CreateConVar("sm_gas_amount", "1", " Number of gas attacks per player at spawn", FCVAR_PLUGIN)
	g_Cvar_Red         = CreateConVar("sm_gas_red", "180", " Amount of red color in gas", FCVAR_PLUGIN)
	g_Cvar_Green       = CreateConVar("sm_gas_green", "210", " Amount of green color in gas", FCVAR_PLUGIN)
	g_Cvar_Blue        = CreateConVar("sm_gas_blue", "0", " Amount of blue color in gas", FCVAR_PLUGIN)
	g_Cvar_Random      = CreateConVar("sm_gas_random", "0", " Make gas color random <1 to enable>", FCVAR_PLUGIN)
	g_Cvar_Damage      = CreateConVar("sm_gas_damage", "200", " Amount of damage that the gas does", FCVAR_PLUGIN)
	g_Cvar_Admins      = CreateConVar("sm_gas_admins", "0", " Allow Admins only to use Gas", FCVAR_PLUGIN)
	g_Cvar_Time        = CreateConVar("sm_gas_time", "18.0", " Length of time gas should be active", FCVAR_PLUGIN)
	
	GetGameFolderName(GameName, sizeof(GameName))
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/gas/mortar.mp3")
	PrecacheSound("gas/mortar.mp3", true)
	PrecacheSound("player/heartbeat1.wav", true)
	
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookEvent("player_disconnect", PlayerDisconnectEvent)
	
	if (StrEqual(GameName, "dod"))
	{
		HookEvent("dod_round_start", RoundStartEvent)
	}
	else if (StrEqual(GameName, "tf"))
	{
		HookEvent("teamplay_round_start", RoundStartEvent)
	}
	else
	{
		HookEvent("round_start", RoundStartEvent)
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_disconnect", PlayerDisconnectEvent)
		
	if (StrEqual(GameName, "dod"))
	{
		UnhookEvent("dod_round_start", RoundStartEvent)
	}
	else if (StrEqual(GameName, "tf"))
	{
		UnhookEvent("teamplay_round_start", RoundStartEvent)
	}
	else
	{
		UnhookEvent("round_start", RoundStartEvent)
	}
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (GetConVarInt(g_Cvar_Admins) == 1)
	{
		if (GetUserFlagBits(client) & ADMIN_LEVEL)
		{
			gasAmount[client] = GetConVarInt(g_Cvar_GasAmount)
		}
		else
		{
			gasAmount[client] = 0
		}
	}
	else
	{
		gasAmount[client] = GetConVarInt(g_Cvar_GasAmount)
	}
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	for (new i = GetConVarInt(g_Cvar_GasAmount); i > 0 ; i--)
	{
		if (timer_handle[client][i] != INVALID_HANDLE)
		{
			KillTimer(timer_handle[client][i])
			timer_handle[client][i] = INVALID_HANDLE
			CloseHandle(hurtdata[client][i])
		}
	}
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_roundstart = true
	CreateTimer(1.0, Reset, 0)
	
	for (new klient = 1; klient <= 64; klient++)
	{
		for (new i = GetConVarInt(g_Cvar_GasAmount); i > 0 ; i--)
		{
			if (timer_handle[klient][i] != INVALID_HANDLE)
			{
				KillTimer(timer_handle[klient][i])
				timer_handle[klient][i] = INVALID_HANDLE
				CloseHandle(hurtdata[klient][i])
			}
		}
	}
}

public Action:Reset(Handle:timer, any:client)
{
	g_roundstart = false
}

public Action:Gas(client, args)
{
	if (client)
	{
		if (IsPlayerAlive(client))
		{
			if (gasAmount[client] > 0)
			{
				if (gasAmount[client] >= 127)
				{
					gasAmount[client] = 127
				}
				
				new Float:vAngles[3]
				new Float:vOrigin[3]
				new Float:pos[3]

				GetClientEyePosition(client,vOrigin)
				GetClientEyeAngles(client, vAngles)

				new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer)

				if(TR_DidHit(trace))
				{
					TR_GetEndPosition(pos, trace)
					pos[2] += 10.0
				}
				CloseHandle(trace)
				
				PrintToChat(client, "[SM] Gas has been called in.  Take cover!")
				FakeClientCommand(client, "say_team I have called in a gas attack...take cover!")
				
				TE_SetupSparks(pos, NULL_VECTOR, 2, 1)
				TE_SendToAll(0.1)
				TE_SetupSparks(pos, NULL_VECTOR, 2, 2)
				TE_SendToAll(0.4)
				TE_SetupSparks(pos, NULL_VECTOR, 1, 1)
				TE_SendToAll(1.0)
				
				CreateTimer(2.5, BigWhoosh, client)
				
				new Handle:gasdata = CreateDataPack()
				CreateTimer(6.0, CreateGas, gasdata)
				WritePackCell(gasdata, client)
				WritePackFloat(gasdata, pos[0])
				WritePackFloat(gasdata, pos[1])
				WritePackFloat(gasdata, pos[2])
				WritePackCell(gasdata, gasAmount[client])
				
				gasAmount[client]--
				PrintToChat(client, "Gas left: %i", gasAmount[client])
			}
			else
			{
				PrintToChat(client, "[SM] Gas unavailable")
			}
		}
	}
	return Plugin_Handled
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity
} 

public Action:BigWhoosh(Handle:timer, any:client)
{
	EmitSoundToAll("gas/mortar.mp3", _, _, _, _, 0.8)
}

public Action:CreateGas(Handle:timer, Handle:gasdata)
{
	ResetPack(gasdata)
	new client = ReadPackCell(gasdata)
	new Float:location[3]
	location[0] = ReadPackFloat(gasdata)
	location[1] = ReadPackFloat(gasdata)
	location[2] = ReadPackFloat(gasdata)
	new gasNumber = ReadPackCell(gasdata)
	CloseHandle(gasdata)
	
	new pointHurt
	
	new ff_on = GetConVarInt(FindConVar("mp_friendlyfire"))
	
	new String:originData[64]
	Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2])
	
	// Create the Explosion
	new explosion = CreateEntityByName("env_explosion")
	DispatchKeyValue(explosion,"Origin", originData)
	DispatchKeyValue(explosion,"Magnitude", "50")
	DispatchSpawn(explosion)
	AcceptEntityInput(explosion, "Explode")
	AcceptEntityInput(explosion, "Kill")
	
	new String:gasDamage[64]
	Format(gasDamage, sizeof(gasDamage), "%i", GetConVarInt(g_Cvar_Damage))
	
	if (ff_on)
	{
		// Create the PointHurt
		pointHurt = CreateEntityByName("point_hurt")
		DispatchKeyValue(pointHurt,"Origin", originData)
		DispatchKeyValue(pointHurt,"Damage", gasDamage)
		DispatchKeyValue(pointHurt,"DamageRadius", gasDamage)
		DispatchKeyValue(pointHurt,"DamageDelay", "1.0")
		DispatchKeyValue(pointHurt,"DamageType", "65536")
		DispatchSpawn(pointHurt)
		AcceptEntityInput(pointHurt, "TurnOn")
	}
	else
	{
		hurtdata[client][gasNumber] = CreateDataPack()
		WritePackCell(hurtdata[client][gasNumber], client)
		WritePackCell(hurtdata[client][gasNumber], gasNumber)
		WritePackFloat(hurtdata[client][gasNumber], location[0])
		WritePackFloat(hurtdata[client][gasNumber], location[1])
		WritePackFloat(hurtdata[client][gasNumber], location[2])
		timer_handle[client][gasNumber] = CreateTimer(1.0, Point_Hurt, hurtdata[client][gasNumber], TIMER_REPEAT)
	}
	
	new String:colorData[64]
	if (GetConVarInt(g_Cvar_Random) == 0)
	{
		Format(colorData, sizeof(colorData), "%i %i %i", GetConVarInt(g_Cvar_Red), GetConVarInt(g_Cvar_Green), GetConVarInt(g_Cvar_Blue))
	}
	else
	{
		new red = GetRandomInt(1, 255)
		new green = GetRandomInt(1, 255)
		new blue = GetRandomInt(1, 255)
		Format(colorData, sizeof(colorData), "%i %i %i", red, green, blue)
	}
	
	// Create the Gas Cloud
	new String:gas_name[128]
	Format(gas_name, sizeof(gas_name), "Gas%i", client)
	new gascloud = CreateEntityByName("env_smokestack")
	DispatchKeyValue(gascloud,"targetname", gas_name)
	DispatchKeyValue(gascloud,"Origin", originData)
	DispatchKeyValue(gascloud,"BaseSpread", "100")
	DispatchKeyValue(gascloud,"SpreadSpeed", "10")
	DispatchKeyValue(gascloud,"Speed", "80")
	DispatchKeyValue(gascloud,"StartSize", "200")
	DispatchKeyValue(gascloud,"EndSize", "2")
	DispatchKeyValue(gascloud,"Rate", "15")
	DispatchKeyValue(gascloud,"JetLength", "400")
	DispatchKeyValue(gascloud,"Twist", "4")
	DispatchKeyValue(gascloud,"RenderColor", colorData)
	DispatchKeyValue(gascloud,"RenderAmt", "100")
	DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt")
	DispatchSpawn(gascloud)
	AcceptEntityInput(gascloud, "TurnOn")
	
	new Float:length
	length = GetConVarFloat(g_Cvar_Time)
	if (length <= 8.0)
	{
		length = 8.0
	}
	
	new Handle:entitypack = CreateDataPack()
	CreateTimer(length, RemoveGas, entitypack)
	length = length + 5.0
	CreateTimer(length, KillGas, entitypack)
	WritePackCell(entitypack, gascloud)
	WritePackCell(entitypack, pointHurt)
	WritePackCell(entitypack, ff_on)
	WritePackCell(entitypack, gasNumber)
	WritePackCell(entitypack, client)
}

public Action:RemoveGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack)
	new gascloud = ReadPackCell(entitypack)
	new pointHurt = ReadPackCell(entitypack)
	new ff_on = ReadPackCell(entitypack)
	new gasNumber = ReadPackCell(entitypack)
	new client = ReadPackCell(entitypack)

	if (IsValidEntity(gascloud))
		AcceptEntityInput(gascloud, "TurnOff")
	
	if (ff_on)
	{
		if (IsValidEntity(pointHurt))
			AcceptEntityInput(pointHurt, "TurnOff")
	}
	else
	{
		if (timer_handle[client][gasNumber] != INVALID_HANDLE)
		{
			KillTimer(timer_handle[client][gasNumber])
			timer_handle[client][gasNumber] = INVALID_HANDLE
			CloseHandle(hurtdata[client][gasNumber])
		}
	}
}

public Action:KillGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack)
	new gascloud = ReadPackCell(entitypack)
	new pointHurt = ReadPackCell(entitypack)
	new ff_on = ReadPackCell(entitypack)
	
	if (IsValidEntity(gascloud))
		AcceptEntityInput(gascloud, "Kill")
	
	if (ff_on)
	{
		if (IsValidEntity(pointHurt))
			AcceptEntityInput(pointHurt, "Kill")
	}
	
	CloseHandle(entitypack)
}

public Action:Point_Hurt(Handle:timer, Handle:hurt)
{
	ResetPack(hurt)
	new client = ReadPackCell(hurt)
	new gasNumber = ReadPackCell(hurt)
	new Float:location[3]
	location[0] = ReadPackFloat(hurt)
	location[1] = ReadPackFloat(hurt)
	location[2] = ReadPackFloat(hurt)
	
	
	
	if (!g_roundstart)
	{
		for (new target = 1; target <= GetMaxClients(); target++)
		{
			if (IsClientInGame(target))
			{
				if (IsPlayerAlive(target))
				{
					if (GetClientTeam(client) != GetClientTeam(target))
					{
						new Float:targetVector[3]
						GetClientAbsOrigin(target, targetVector)
								
						new Float:distance = GetVectorDistance(targetVector, location)
								
						if (distance < 300)
						{
							LogAction(client, target, "\"%L\" gassed \"%L\"", client, target)
							ForcePlayerSuicide(target)
						}
						//PrintToChatAll("%i - %f", target, distance)
					}
				}
			}
		}
	}
	else
	{
		KillTimer(timer)
		timer_handle[client][gasNumber] = INVALID_HANDLE
		CloseHandle(hurt)
	}
}