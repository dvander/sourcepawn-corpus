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

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.107"

#define ADMIN_LEVEL ADMFLAG_SLAY

new gasAmount[MAXPLAYERS+1];
new g_gasEnabled[MAXPLAYERS+1];

new bool:g_roundstart = false;

new Handle:g_Cvar_GasAmount = INVALID_HANDLE;
new Handle:g_Cvar_Red    = INVALID_HANDLE;
new Handle:g_Cvar_Green  = INVALID_HANDLE;
new Handle:g_Cvar_Blue   = INVALID_HANDLE;
new Handle:g_Cvar_Random = INVALID_HANDLE;
new Handle:g_Cvar_Damage = INVALID_HANDLE;
new Handle:g_Cvar_Admins = INVALID_HANDLE;
new Handle:g_Cvar_Time   = INVALID_HANDLE;
new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_Cvar_Delay  = INVALID_HANDLE;
new Handle:g_Cvar_Msg    = INVALID_HANDLE;
new Handle:g_Cvar_Radius = INVALID_HANDLE;
new Handle:g_Cvar_Whoosh = INVALID_HANDLE;
new Handle:timer_handle[MAXPLAYERS+1][128];
new Handle:hurtdata[MAXPLAYERS+1][128];

new String:GameName[64];

public Plugin:myinfo = 
{
	name = "Gas",
	author = "<eVa>Dog",
	description = "Gas plugin",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_gas", Gas, " -  Calls in gas at coords specified by player's crosshairs");
	
	CreateConVar("sm_gas_version", PLUGIN_VERSION, "Version of SourceMod Gas on this server", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_GasAmount   = CreateConVar("sm_gas_amount", "1", " Number of gas attacks per player at spawn", FCVAR_PLUGIN);
	g_Cvar_Red         = CreateConVar("sm_gas_red", "180", " Amount of red color in gas", FCVAR_PLUGIN);
	g_Cvar_Green       = CreateConVar("sm_gas_green", "210", " Amount of green color in gas", FCVAR_PLUGIN);
	g_Cvar_Blue        = CreateConVar("sm_gas_blue", "0", " Amount of blue color in gas", FCVAR_PLUGIN);
	g_Cvar_Random      = CreateConVar("sm_gas_random", "0", " Make gas color random <1 to enable>", FCVAR_PLUGIN);
	g_Cvar_Damage      = CreateConVar("sm_gas_damage", "20", " Amount of damage that the gas does", FCVAR_PLUGIN);
	g_Cvar_Admins      = CreateConVar("sm_gas_admins", "0", " Allow Admins only to use Gas", FCVAR_PLUGIN);
	g_Cvar_Time        = CreateConVar("sm_gas_time", "18.0", " Length of time gas should be active", FCVAR_PLUGIN);
	g_Cvar_Enable      = CreateConVar("sm_gas_enabled", "1", " Enable/Disable the Gas plugin", FCVAR_PLUGIN);
	g_Cvar_Delay       = CreateConVar("sm_gas_delay", "20", " Delay between spawning and making gas available", FCVAR_PLUGIN);
	g_Cvar_Msg         = CreateConVar("sm_gas_showmessages", "1", " Show gas messages", FCVAR_PLUGIN);
	g_Cvar_Radius      = CreateConVar("sm_gas_radius", "50", " Radius of gas cloud", FCVAR_PLUGIN);
	g_Cvar_Whoosh	   = CreateConVar("sm_gas_launchmethod", "0", " 0=Launched by air  1=Instant", FCVAR_PLUGIN);
	
	GetGameFolderName(GameName, sizeof(GameName));
}

public OnMapStart()
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		AddFileToDownloadsTable("sound/gas/mortar.mp3");
		PrecacheSound("gas/mortar.mp3", true);
		PrecacheSound("player/heartbeat1.wav", true);
		
		HookEvent("player_spawn", PlayerSpawnEvent);
		HookEvent("player_death", PlayerDeathEvent);
		HookEvent("player_disconnect", PlayerDisconnectEvent);
		
		if (StrEqual(GameName, "dod"))
		{
			HookEvent("dod_round_start", RoundStartEvent);
		}
		else if (StrEqual(GameName, "tf"))
		{
			HookEvent("teamplay_round_start", RoundStartEvent);
		}
		else
		{
			HookEvent("round_start", RoundStartEvent);
		}
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent);
	UnhookEvent("player_disconnect", PlayerDisconnectEvent);
	UnhookEvent("player_death", PlayerDeathEvent);
		
	if (StrEqual(GameName, "dod"))
	{
		UnhookEvent("dod_round_start", RoundStartEvent);
	}
	else if (StrEqual(GameName, "tf"))
	{
		UnhookEvent("teamplay_round_start", RoundStartEvent);
	}
	else
	{
		UnhookEvent("round_start", RoundStartEvent);
	}
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (GetConVarInt(g_Cvar_Admins) == 1)
		{
			if (GetUserFlagBits(client) & ADMIN_LEVEL)
			{
				gasAmount[client] = GetConVarInt(g_Cvar_GasAmount);
			}
			else if (GetUserFlagBits(client) & ADMFLAG_ROOT)
			{
				gasAmount[client] = GetConVarInt(g_Cvar_GasAmount);
			}
			else
			{
				gasAmount[client] = 0;
			}
		}
		else
		{
			gasAmount[client] = GetConVarInt(g_Cvar_GasAmount);
		}
		
		g_gasEnabled[client] = 0;
		CreateTimer(GetConVarFloat(g_Cvar_Delay), SetGas, client);
	}
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		gasAmount[client] = 0;
	}
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		for (new i = GetConVarInt(g_Cvar_GasAmount); i > 0 ; i--)
		{
			if (timer_handle[client][i] != INVALID_HANDLE)
			{
				KillTimer(timer_handle[client][i]);
				timer_handle[client][i] = INVALID_HANDLE;
				CloseHandle(hurtdata[client][i]);
			}
		}
	}
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		g_roundstart = true;
		CreateTimer(1.0, Reset, 0);
		
		for (new klient = 1; klient <= 64; klient++)
		{
			for (new i = GetConVarInt(g_Cvar_GasAmount); i > 0 ; i--)
			{
				if (timer_handle[klient][i] != INVALID_HANDLE)
				{
					KillTimer(timer_handle[klient][i]);
					timer_handle[klient][i] = INVALID_HANDLE;
					CloseHandle(hurtdata[klient][i]);
				}
			}
		}
	}
}

public Action:SetGas(Handle:timer, any:client)
{
	g_gasEnabled[client] = 1;
}

public Action:Reset(Handle:timer, any:client)
{
	g_roundstart = false;
}

public Action:Gas(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (client > 0)
		{	
			if (g_gasEnabled[client])
			{ 
				if (IsPlayerAlive(client))
				{
					if (gasAmount[client] > 0)
					{
						if (gasAmount[client] >= 127)
						{
							gasAmount[client] = 127;
						}
						
						new Float:vAngles[3];
						new Float:vOrigin[3];
						new Float:pos[3];

						GetClientEyePosition(client,vOrigin);
						GetClientEyeAngles(client, vAngles);

						new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

						if(TR_DidHit(trace))
						{
							TR_GetEndPosition(pos, trace);
							pos[2] += 10.0;
						}
						CloseHandle(trace);
						
						if (GetConVarInt(g_Cvar_Msg) == 1)
						{
							PrintToChat(client, "[SM] Gas has been called in.  Take cover!");
							FakeClientCommand(client, "say_team I have called in a gas attack...take cover!");
						}
						
						TE_SetupSparks(pos, NULL_VECTOR, 2, 1);
						TE_SendToAll(0.1);
						TE_SetupSparks(pos, NULL_VECTOR, 2, 2);
						TE_SendToAll(0.4);
						TE_SetupSparks(pos, NULL_VECTOR, 1, 1);
						TE_SendToAll(1.0);
						
						new Float:whooshtime;
						if (GetConVarInt(g_Cvar_Whoosh) == 0)
						{
							CreateTimer(2.5, BigWhoosh, client);
							whooshtime = 6.0;
						}
						else
						{
							whooshtime = 0.1;
						}
						
						new Handle:gasdata = CreateDataPack();
						CreateTimer(whooshtime, CreateGas, gasdata);
						WritePackCell(gasdata, client);
						WritePackFloat(gasdata, pos[0]);
						WritePackFloat(gasdata, pos[1]);
						WritePackFloat(gasdata, pos[2]);
						WritePackCell(gasdata, gasAmount[client]);
						
						gasAmount[client]--;
						PrintToChat(client, "Gas left: %i", gasAmount[client]);
					}
					else
					{
						PrintToChat(client, "[SM] Gas unavailable");
					}
				}
			}
			else
			{
				PrintToChat(client, "[SM] Gas unavailable.  Please wait....");
			}
		}
	}
	return Plugin_Handled;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
} 

public Action:BigWhoosh(Handle:timer, any:client)
{
	EmitSoundToAll("gas/mortar.mp3", _, _, _, _, 0.8);
}

public Action:CreateGas(Handle:timer, Handle:gasdata)
{
	ResetPack(gasdata);
	new client = ReadPackCell(gasdata);
	new Float:location[3];
	location[0] = ReadPackFloat(gasdata);
	location[1] = ReadPackFloat(gasdata);
	location[2] = ReadPackFloat(gasdata);
	new gasNumber = ReadPackCell(gasdata);
	CloseHandle(gasdata);
	
	new pointHurt;
	
	new ff_on = GetConVarInt(FindConVar("mp_friendlyfire"));
	
	new String:originData[64];
	Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
	
	new String:gasRadius[64];
	Format(gasRadius, sizeof(gasRadius), "%i", GetConVarInt(g_Cvar_Radius));
	
	// Create the Explosion
	new explosion = CreateEntityByName("env_explosion");
	DispatchKeyValue(explosion,"Origin", originData);
	DispatchKeyValue(explosion,"Magnitude", gasRadius);
	DispatchSpawn(explosion);
	AcceptEntityInput(explosion, "Explode");
	AcceptEntityInput(explosion, "Kill");
	
	new String:gasDamage[64];
	Format(gasDamage, sizeof(gasDamage), "%i", GetConVarInt(g_Cvar_Damage));
	
	if (ff_on)
	{
		// Create the PointHurt
		pointHurt = CreateEntityByName("point_hurt");
		DispatchKeyValue(pointHurt,"Origin", originData);
		DispatchKeyValue(pointHurt,"Damage", gasDamage);
		DispatchKeyValue(pointHurt,"DamageRadius", gasRadius);
		DispatchKeyValue(pointHurt,"DamageDelay", "1.0");
		DispatchKeyValue(pointHurt,"DamageType", "65536");
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "TurnOn");
	}
	else
	{
		hurtdata[client][gasNumber] = CreateDataPack();
		WritePackCell(hurtdata[client][gasNumber], client);
		WritePackCell(hurtdata[client][gasNumber], gasNumber);
		WritePackFloat(hurtdata[client][gasNumber], location[0]);
		WritePackFloat(hurtdata[client][gasNumber], location[1]);
		WritePackFloat(hurtdata[client][gasNumber], location[2]);
		timer_handle[client][gasNumber] = CreateTimer(1.0, Point_Hurt, hurtdata[client][gasNumber], TIMER_REPEAT);
	}
	
	new String:colorData[64];
	if (GetConVarInt(g_Cvar_Random) == 0)
	{
		Format(colorData, sizeof(colorData), "%i %i %i", GetConVarInt(g_Cvar_Red), GetConVarInt(g_Cvar_Green), GetConVarInt(g_Cvar_Blue));
	}
	else
	{
		new red = GetRandomInt(1, 255);
		new green = GetRandomInt(1, 255);
		new blue = GetRandomInt(1, 255);
		Format(colorData, sizeof(colorData), "%i %i %i", red, green, blue);
	}
	
	// Create the Gas Cloud
	new String:gas_name[128];
	Format(gas_name, sizeof(gas_name), "Gas%i", client);
	new gascloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(gascloud,"targetname", gas_name);
	DispatchKeyValue(gascloud,"Origin", originData);
	DispatchKeyValue(gascloud,"BaseSpread", "100");
	DispatchKeyValue(gascloud,"SpreadSpeed", "10");
	DispatchKeyValue(gascloud,"Speed", "80");
	DispatchKeyValue(gascloud,"StartSize", "200");
	DispatchKeyValue(gascloud,"EndSize", "2");
	DispatchKeyValue(gascloud,"Rate", "15");
	DispatchKeyValue(gascloud,"JetLength", "400");
	DispatchKeyValue(gascloud,"Twist", "4");
	DispatchKeyValue(gascloud,"RenderColor", colorData);
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
	DispatchSpawn(gascloud);
	AcceptEntityInput(gascloud, "TurnOn");
	
	new Float:length;
	length = GetConVarFloat(g_Cvar_Time);
	if (length <= 8.0)
	{
		length = 8.0;
	}
	
	new Handle:entitypack = CreateDataPack();
	CreateTimer(length, RemoveGas, entitypack);
	length = length + 5.0;
	CreateTimer(length, KillGas, entitypack);
	WritePackCell(entitypack, gascloud);
	WritePackCell(entitypack, pointHurt);
	WritePackCell(entitypack, ff_on);
	WritePackCell(entitypack, gasNumber);
	WritePackCell(entitypack, client);
}

public Action:RemoveGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new gascloud = ReadPackCell(entitypack);
	new pointHurt = ReadPackCell(entitypack);
	new ff_on = ReadPackCell(entitypack);
	new gasNumber = ReadPackCell(entitypack);
	new client = ReadPackCell(entitypack);

	if (IsValidEntity(gascloud))
		AcceptEntityInput(gascloud, "TurnOff");
	
	if (ff_on)
	{
		if (IsValidEntity(pointHurt))
			AcceptEntityInput(pointHurt, "TurnOff");
	}
	else
	{
		if (timer_handle[client][gasNumber] != INVALID_HANDLE)
		{
			KillTimer(timer_handle[client][gasNumber]);
			timer_handle[client][gasNumber] = INVALID_HANDLE;
			CloseHandle(hurtdata[client][gasNumber]);
		}
	}
}

public Action:KillGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new gascloud = ReadPackCell(entitypack);
	new pointHurt = ReadPackCell(entitypack);
	new ff_on = ReadPackCell(entitypack);
	
	if (IsValidEntity(gascloud))
		AcceptEntityInput(gascloud, "Kill");
	
	if (ff_on)
	{
		if (IsValidEntity(pointHurt))
			AcceptEntityInput(pointHurt, "Kill");
	}
	
	CloseHandle(entitypack);
}

public Action:Point_Hurt(Handle:timer, Handle:hurt)
{
	ResetPack(hurt);
	new client = ReadPackCell(hurt);
	new gasNumber = ReadPackCell(hurt);
	new Float:location[3];
	location[0] = ReadPackFloat(hurt);
	location[1] = ReadPackFloat(hurt);
	location[2] = ReadPackFloat(hurt);
	
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
						new Float:targetVector[3];
						GetClientAbsOrigin(target, targetVector);
								
						new Float:distance = GetVectorDistance(targetVector, location);
								
						if (distance < 300)
						{							
							new target_health;
							target_health = GetClientHealth(target);
							
							target_health -= GetConVarInt(g_Cvar_Damage);
							
							if (target_health <= (GetConVarInt(g_Cvar_Damage) + 1))
							{
								ForcePlayerSuicide(target);
								LogAction(client, target, "\"%L\" gassed \"%L\"", client, target);
							}
							else
								SetEntityHealth(target, target_health);
						}
						//PrintToChatAll("%i - %f", target, distance)
					}
				}
			}
		}
	}
	else
	{
		KillTimer(timer);
		timer_handle[client][gasNumber] = INVALID_HANDLE;
		CloseHandle(hurt);
	}
}