#pragma semicolon 1

/* SM Includes */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smac>
#undef REQUIRE_PLUGIN
#include <updater>

/* Plugin Info */
public Plugin:myinfo =
{
	name = "SMAC Anti-Wallhack",
	author = "GoD-Tony, psychonic, Kigen",
	description = "Prevents wallhack cheats from working",
	version = SMAC_VERSION,
	url = SMAC_URL
};

/* Globals */
#define UPDATE_URL	"http://godtony.mooo.com/smac/smac_wallhack.txt"

new Handle:g_hCvarWallhack = INVALID_HANDLE;
new bool:g_bEnabled;

new bool:g_bIsVisible[MAXPLAYERS+1][MAXPLAYERS+1];
new bool:g_bProcess[MAXPLAYERS+1];
new bool:g_bIgnore[MAXPLAYERS+1];

new g_iWeaponOwner[MAX_EDICTS];
new g_iTeam[MAXPLAYERS+1];
new Float:g_vMins[MAXPLAYERS+1][3];
new Float:g_vMaxs[MAXPLAYERS+1][3];
new Float:g_vAbsCentre[MAXPLAYERS+1][3];
new Float:g_vEyePos[MAXPLAYERS+1][3];
new Float:g_vEyeAngles[MAXPLAYERS+1][3];

new g_iCurrentThread = 1, g_iThread[MAXPLAYERS+1] = { 1, ... };
new g_iCacheTicks, g_iNumChecks;
new g_iTickCount, g_iCmdTickCount[MAXPLAYERS+1];
new Float:g_fTickDelta;

new bool:g_bIsModL4D = false;

/* Plugin Functions */
public OnPluginStart()
{
	// Convars.
	g_hCvarWallhack = SMAC_CreateConVar("smac_wallhack", "1", "Enable Anti-Wallhack. This will increase your server's CPU usage.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	OnSettingsChanged(g_hCvarWallhack, "", "");
	HookConVarChange(g_hCvarWallhack, OnSettingsChanged);
	
	// Clients use these for prediction.
	new Handle:hCvar = INVALID_HANDLE;
	new iTickRate = RoundToFloor(1.0 / GetTickInterval());
	
	if ((hCvar = FindConVar("sv_minupdaterate")) != INVALID_HANDLE)
		SetConVarInt(hCvar, iTickRate);
	if ((hCvar = FindConVar("sv_maxupdaterate")) != INVALID_HANDLE)
		SetConVarInt(hCvar, iTickRate);
	if ((hCvar = FindConVar("sv_client_min_interp_ratio")) != INVALID_HANDLE)
		SetConVarInt(hCvar, 0);
	if ((hCvar = FindConVar("sv_client_max_interp_ratio")) != INVALID_HANDLE)
		SetConVarInt(hCvar, 1);
	
	// Hooks.
	HookEvent("player_spawn", Event_PlayerStateChanged, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerStateChanged, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerStateChanged, EventHookMode_Post);
	
	// Initialize.
	g_iCacheTicks = TIME_TO_TICK(0.75);
	g_bIsModL4D = (SMAC_GetGameType() == Game_L4D || SMAC_GetGameType() == Game_L4D2);
	
	for (new i = 0; i < sizeof(g_bIsVisible[]); i++)
	{
		g_bIsVisible[0][i] = true;
	}
	
	// Updater.
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnClientPutInServer(client)
{
	if (g_bEnabled)
	{
		Wallhack_Hook(client);
		Wallhack_UpdateClientCache(client);
	}
}

public OnClientDisconnect(client)
{
	g_bProcess[client] = false;
	g_bIgnore[client] = false;
}

public Event_PlayerStateChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		Wallhack_UpdateClientCache(client);
	}
}

Wallhack_UpdateClientCache(client)
{
	g_iTeam[client] = GetClientTeam(client);
	g_bProcess[client] = IsPlayerAlive(client);
	
	// L4D - Only process survivor team.
	g_bIgnore[client] = g_bIsModL4D && g_iTeam[client] != 2;
}

public OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:bNewValue = GetConVarBool(convar);
	
	if (bNewValue && !g_bEnabled)
	{
		Wallhack_Enable();
	}
	else if (!bNewValue && g_bEnabled)
	{
		Wallhack_Disable();
	}
}

Wallhack_Enable()
{
	g_bEnabled = true;
	
	AddNormalSoundHook(Hook_NormalSound);
	
	switch (SMAC_GetGameType())
	{
		case Game_TF2:
		{
			HookEntityOutput("item_teamflag", "OnPickUp", TF2_Hook_FlagEquip);
			HookEntityOutput("item_teamflag", "OnDrop", TF2_Hook_FlagDrop);
			HookEntityOutput("item_teamflag", "OnReturn", TF2_Hook_FlagDrop);
			HookEvent("post_inventory_application", TF2_Event_Inventory, EventHookMode_Post);
		}
		
		case Game_CSS:
		{
			farESP_Enable();
		}
		
		case Game_L4D2:
		{
			HookEvent("player_first_spawn", Event_PlayerStateChanged, EventHookMode_Post);
			HookEvent("ghost_spawn_time", L4D_Event_GhostSpawnTime, EventHookMode_Post);
		}
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Wallhack_Hook(i);
			Wallhack_UpdateClientCache(i);
		}
	}
	
	new client = -1;
	for (new i = MaxClients + 1; i < MAX_EDICTS; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			client = GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity");
			
			if (IS_CLIENT(client))
			{
				g_iWeaponOwner[i] = client;
				SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
			}
		}
	}
}

Wallhack_Disable()
{
	g_bEnabled = false;
	
	RemoveNormalSoundHook(Hook_NormalSound);
	
	switch (SMAC_GetGameType())
	{
		case Game_TF2:
		{
			UnhookEntityOutput("item_teamflag", "OnPickUp", TF2_Hook_FlagEquip);
			UnhookEntityOutput("item_teamflag", "OnDrop", TF2_Hook_FlagDrop);
			UnhookEntityOutput("item_teamflag", "OnReturn", TF2_Hook_FlagDrop);
			UnhookEvent("post_inventory_application", TF2_Event_Inventory, EventHookMode_Post);
		}
		
		case Game_CSS:
		{
			farESP_Disable();
		}
		
		case Game_L4D2:
		{
			UnhookEvent("player_first_spawn", Event_PlayerStateChanged, EventHookMode_Post);
			UnhookEvent("ghost_spawn_time", L4D_Event_GhostSpawnTime, EventHookMode_Post);
		}
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Wallhack_Unhook(i);
		}
	}
	
	for (new i = MaxClients + 1; i < MAX_EDICTS; i++)
	{
		if (g_iWeaponOwner[i])
		{
			g_iWeaponOwner[i] = 0;
			SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
		}
	}
}

/**
 * Hooks
 */
Wallhack_Hook(client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_WeaponEquip, Hook_WeaponEquip);
	SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
}

Wallhack_Unhook(client)
{
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(client, SDKHook_WeaponEquip, Hook_WeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity > MaxClients && entity < MAX_EDICTS)
	{
		g_iWeaponOwner[entity] = 0;
	}
}

public OnEntityDestroyed(entity)
{
	if (entity > MaxClients && entity < MAX_EDICTS)
	{
		g_iWeaponOwner[entity] = 0;
	}
}

public Action:Hook_WeaponEquip(client, weapon)
{
	if (weapon > MaxClients && weapon < MAX_EDICTS)
	{
		g_iWeaponOwner[weapon] = client;
		SDKHook(weapon, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
	}
}

public Action:Hook_WeaponDrop(client, weapon)
{
	if (weapon > MaxClients && weapon < MAX_EDICTS)
	{
		g_iWeaponOwner[weapon] = 0;
		SDKUnhook(weapon, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
	}
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	/* Emit sounds to clients who aren't being transmitted the entity. */
	if (!entity || !IsValidEdict(entity))
		return Plugin_Continue;
		
	decl newClients[MaxClients];
	new newTotal = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bProcess[i] && 
			((IS_CLIENT(entity) && entity != i && !g_bIsVisible[entity][i]) || 
			(entity > MaxClients && g_iWeaponOwner[entity] && g_iWeaponOwner[entity] != i && !g_bIsVisible[g_iWeaponOwner[entity]][i])))
		{
			newClients[newTotal++] = i;
		}
	}
	
	// Re-emit without entity information.
	if (newTotal)
	{
		decl Float:vOrigin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vOrigin);
		EmitSound(newClients, newTotal, sample, SOUND_FROM_WORLD, channel, level, flags, volume, pitch, _, vOrigin);
	}
	
	return Plugin_Continue;
}

public TF2_Hook_FlagEquip(const String:output[], caller, activator, Float:delay)
{
	if (caller > MaxClients && caller < MAX_EDICTS && IS_CLIENT(activator) && IsClientConnected(activator))
	{
		g_iWeaponOwner[caller] = activator;
		SDKHook(caller, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
	}
}

public TF2_Hook_FlagDrop(const String:output[], caller, activator, Float:delay)
{
	if (caller > MaxClients && caller < MAX_EDICTS)
	{
		g_iWeaponOwner[caller] = 0;
		SDKUnhook(caller, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
	}
}

public TF2_Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IS_CLIENT(client))
	{
		for (new i = MaxClients + 1; i < MAX_EDICTS; i++)
		{
			if (IsValidEdict(i) && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == client)
			{
				g_iWeaponOwner[i] = client;
				SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
			}
		}
	}
}

public L4D_Event_GhostSpawnTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(float(GetEventInt(event, "spawntime")) + 0.5, L4D_Timer_GhostSpawn, GetEventInt(event, "userid"));
}

public Action:L4D_Timer_GhostSpawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		Wallhack_UpdateClientCache(client);
	}

	return Plugin_Stop;
}

/**
 * OnGameFrame
 */
public OnGameFrame()
{
	g_iTickCount++;
	
	if (!g_bEnabled)
		return;

	static iTotalThreads = 1;
	new bool:bEvalThreads = false;
	
	// Increment to next thread.
	if (++g_iCurrentThread > iTotalThreads)
	{
		g_iCurrentThread = 1;
		bEvalThreads = true;
	}
	
	if (g_iNumChecks && bEvalThreads)
	{
		// Calculate total needed threads for the next pass.
		iTotalThreads = RoundToCeil(float(g_iNumChecks) / 128.0);
		
		// Adjust for prediction.
		g_fTickDelta = GetTickInterval() * float(iTotalThreads - 1);
		
		// Assign each client to a thread.
		new iThreadAssign = 1;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_bProcess[i])
			{
				g_iThread[i] = iThreadAssign;
				
				if (++iThreadAssign > iTotalThreads)
				{
					iThreadAssign = 1;
				}
			}
		}
	}
	
	g_iNumChecks = 0;
}

public Action:Hook_SetTransmit(entity, client)
{
	static iLastChecked[MAXPLAYERS+1][MAXPLAYERS+1],
		iCacheTick[MAXPLAYERS+1][MAXPLAYERS+1];
	
	// Data is transmitted multiple times per tick. Only run calculations once.
	if (iLastChecked[entity][client] == g_iTickCount)
	{
		return g_bIsVisible[entity][client] ? Plugin_Continue : Plugin_Handled;
	}
	else
	{
		iLastChecked[entity][client] = g_iTickCount;
	}
	
	if (g_bProcess[client] && g_bProcess[entity] && g_iTeam[client] != g_iTeam[entity] && !g_bIgnore[client])
	{
		// Grab client data before running traces.
		UpdateClientData(client);
		UpdateClientData(entity);
		
		if (g_iThread[client] == g_iCurrentThread)
		{
			if (IsAbleToSee(entity, client))
			{
				g_bIsVisible[entity][client] = true;
				iCacheTick[entity][client] = g_iTickCount + g_iCacheTicks;
			}
			else if (g_iTickCount > iCacheTick[entity][client])
			{
				g_bIsVisible[entity][client] = false;
			}
		}
		
		g_iNumChecks++;
	}
	else
	{
		g_bIsVisible[entity][client] = true;
	}
	
	return g_bIsVisible[entity][client] ? Plugin_Continue : Plugin_Handled;
}

public Action:Hook_SetTransmitWeapon(entity, client)
{
	return g_bIsVisible[g_iWeaponOwner[entity]][client] ? Plugin_Continue : Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Alternative to using cmd->tick_count.
	static iLastReset[MAXPLAYERS+1];
	
	if (iLastReset[client] != g_iTickCount)
	{
		g_iCmdTickCount[client] = 0;
		iLastReset[client] = g_iTickCount;
	}
	
	g_iCmdTickCount[client]++;
	return Plugin_Continue;
}

UpdateClientData(client)
{
	/* Only update client data once per tick. */
	static iLastCached[MAXPLAYERS+1];
	
	if (iLastCached[client] == g_iTickCount)
		return;
	
	GetClientMins(client, g_vMins[client]);
	GetClientMaxs(client, g_vMaxs[client]);
	GetClientAbsOrigin(client, g_vAbsCentre[client]);
	GetClientEyePosition(client, g_vEyePos[client]);
	GetClientEyeAngles(client, g_vEyeAngles[client]);
	
	// Adjust vectors relative to the model's absolute centre.
	g_vMaxs[client][2] /= 2.0;
	g_vMins[client][2] -= g_vMaxs[client][2];
	g_vAbsCentre[client][2] += g_vMaxs[client][2];

	// Adjust vectors based on the clients velocity.
	decl Float:vVelocity[3];
	GetClientAbsVelocity(client, vVelocity);
	
	if (!IsVectorZero(vVelocity))
	{
		// Use velocity before it's modified.
		decl Float:vTemp[3];
		vTemp[0] = FloatAbs(vVelocity[0]) * 0.01;
		vTemp[1] = FloatAbs(vVelocity[1]) * 0.01;
		vTemp[2] = FloatAbs(vVelocity[2]) * 0.01;
		
		// Lag compensation.
		decl Float:fLagDelta;
		
		if (IsFakeClient(client))
		{
			fLagDelta = GetTickInterval();
		}
		else
		{
			new Float:fLerpTime = GetEntPropFloat(client, Prop_Data, "m_fLerpTime");
			new Float:fCorrect = GetClientLatency(client, NetFlow_Outgoing) + fLerpTime;
			
			fLagDelta = FloatAbs(fCorrect - FloatAbs(g_iCmdTickCount[client] * GetTickInterval() - fLerpTime));
			
			if (fLagDelta > 0.2)
			{
				// Cmd delta is too high to be reliable.
				fLagDelta = fCorrect;
			}
		}
		
		// Calculate predicted positions for the next frame.
		ScaleVector(vVelocity, g_fTickDelta + fLagDelta);
		AddVectors(g_vAbsCentre[client], vVelocity, g_vAbsCentre[client]);
		AddVectors(g_vEyePos[client], vVelocity, g_vEyePos[client]);
		
		// Expand the mins/maxs to help smooth during fast movement.
		if (vTemp[0] > 1.0)
		{
			g_vMins[client][0] *= vTemp[0];
			g_vMaxs[client][0] *= vTemp[0];
		}
		if (vTemp[1] > 1.0)
		{
			g_vMins[client][1] *= vTemp[1];
			g_vMaxs[client][1] *= vTemp[1];
		}
		if (vTemp[2] > 1.0)
		{
			g_vMins[client][2] *= vTemp[2];
			g_vMaxs[client][2] *= vTemp[2];
		}
	}
	
	iLastCached[client] = g_iTickCount;
}

/**
 * Calculations
 */
bool:IsAbleToSee(entity, client)
{
	// L4D - Extra checks.
	if (g_bIsModL4D)
	{
		if (L4D_IsPlayerGhost(entity))
		{
			return false;
		}
		else if (L4D_IsSurvivorBusy(client))
		{
			return true;
		}
	}
	
	// Skip all traces if the player isn't within the field of view.
	// - Temporarily disabled until eye angle prediction is added.
	// if (IsInFieldOfView(g_vEyePos[client], g_vEyeAngles[client], g_vAbsCentre[entity]))
		
	// Check if centre is visible.
	if (IsPointVisible(g_vEyePos[client], g_vAbsCentre[entity]))
	{
		return true;
	}
	
	// Check if weapon tip is visible.
	if (IsFwdVecVisible(g_vEyePos[client], g_vEyeAngles[entity], g_vEyePos[entity]))
	{
		return true;
	}
	
	// Check outer 4 corners of player.
	if (IsRectangleVisible(g_vEyePos[client], g_vAbsCentre[entity], g_vMins[entity], g_vMaxs[entity], 1.30))
	{
		return true;
	}

	// Check inner 4 corners of player.
	if (IsRectangleVisible(g_vEyePos[client], g_vAbsCentre[entity], g_vMins[entity], g_vMaxs[entity], 0.65))
	{
		return true;
	}
	
	return false;
}

stock bool:IsInFieldOfView(const Float:start[3], const Float:angles[3], const Float:end[3])
{
	decl Float:normal[3], Float:plane[3];
	
	GetAngleVectors(angles, normal, NULL_VECTOR, NULL_VECTOR);
	SubtractVectors(end, start, plane);
	NormalizeVector(plane, plane);
	
	return GetVectorDotProduct(plane, normal) > 0.4226; // Cosine(Deg2Rad(130/2))
}

public bool:Filter_NoPlayers(entity, mask)
{
	return entity > MaxClients && !IS_CLIENT(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"));
}

bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_VISIBLE, RayType_EndPoint, Filter_NoPlayers);

	return TR_GetFraction() == 1.0;
}

bool:IsFwdVecVisible(const Float:start[3], const Float:angles[3], const Float:end[3])
{
	decl Float:fwd[3];
	
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 50.0);
	AddVectors(end, fwd, fwd);

	return IsPointVisible(start, fwd);
}

bool:IsRectangleVisible(const Float:start[3], const Float:end[3], const Float:mins[3], const Float:maxs[3], Float:scale=1.0)
{
	new Float:ZpozOffset = maxs[2];
	new Float:ZnegOffset = mins[2];
	new Float:WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;

	// This rectangle is just a point!
	if (ZpozOffset == 0.0 && ZnegOffset == 0.0 && WideOffset == 0.0)
	{
		return IsPointVisible(start, end);
	}

	// Adjust to scale.
	ZpozOffset *= scale;
	ZnegOffset *= scale;
	WideOffset *= scale;
	
	// Prepare rotation matrix.
	decl Float:angles[3], Float:fwd[3], Float:right[3];

	SubtractVectors(start, end, fwd);
	NormalizeVector(fwd, fwd);

	GetVectorAngles(fwd, angles);
	GetAngleVectors(angles, fwd, right, NULL_VECTOR);

	decl Float:vRectangle[4][3], Float:vTemp[3];

	// If the player is on the same level as us, we can optimize by only rotating on the z-axis.
	if (FloatAbs(fwd[2]) <= 0.7071)
	{
		ScaleVector(right, WideOffset);
		
		// Corner 1, 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vRectangle[0]);
		SubtractVectors(vTemp, right, vRectangle[1]);
		
		// Corner 3, 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vRectangle[2]);
		SubtractVectors(vTemp, right, vRectangle[3]);
		
	}
	else if (fwd[2] > 0.0) // Player is below us.
	{
		fwd[2] = 0.0;
		NormalizeVector(fwd, fwd);
		
		ScaleVector(fwd, scale);
		ScaleVector(fwd, WideOffset);
		ScaleVector(right, WideOffset);
		
		// Corner 1
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[0]);
		
		// Corner 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		SubtractVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[1]);
		
		// Corner 3
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[2]);
		
		// Corner 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		SubtractVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[3]);
	}
	else // Player is above us.
	{
		fwd[2] = 0.0;
		NormalizeVector(fwd, fwd);
		
		ScaleVector(fwd, scale);
		ScaleVector(fwd, WideOffset);
		ScaleVector(right, WideOffset);

		// Corner 1
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[0]);
		
		// Corner 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		SubtractVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[1]);
		
		// Corner 3
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[2]);
		
		// Corner 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		SubtractVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[3]);
	}

	// Run traces on all corners.
	for (new i = 0; i < 4; i++)
	{
		if (IsPointVisible(start, vRectangle[i]))
		{
			return true;
		}
	}

	return false;
}

/**
 * CS:S farESP Blocking
 */
#define CS_TEAM_NONE		0	/**< No team yet. */
#define CS_TEAM_SPECTATOR	1	/**< Spectators. */
#define CS_TEAM_T			2	/**< Terrorists. */
#define CS_TEAM_CT			3	/**< Counter-Terrorists. */

#define MAX_RADAR_CLIENTS	36	// Max amount of client data we can include in one message.

new bool:g_bFarEspEnabled = false;

new UserMsg:g_msgUpdateRadar = INVALID_MESSAGE_ID;
new Handle:g_hRadarTimer = INVALID_HANDLE;
new bool:g_bPlayerSpotted[MAXPLAYERS+1];

new g_iPlayerManager = -1;
new g_iPlayerSpotted = -1;

farESP_Enable()
{
	if ((g_iPlayerManager = FindEntityByClassname(0, "cs_player_manager")) == -1)
		return;
	
	g_iPlayerSpotted = FindSendPropOffs("CCSPlayerResource", "m_bPlayerSpotted");
	SDKHook(g_iPlayerManager, SDKHook_ThinkPost, PlayerManager_ThinkPost);
	
	g_msgUpdateRadar = GetUserMessageId("UpdateRadar");
	HookUserMessage(g_msgUpdateRadar, Hook_UpdateRadar, true);
	
	g_hRadarTimer = CreateTimer(1.0, Timer_UpdateRadar, _, TIMER_REPEAT);
	
	g_bFarEspEnabled = true;
}

farESP_Disable()
{
	SDKUnhook(g_iPlayerManager, SDKHook_ThinkPost, PlayerManager_ThinkPost);
	
	for (new i = 0; i < sizeof(g_bPlayerSpotted); i++)
	{
		g_bPlayerSpotted[i] = false;
	}
	
	KillTimer(g_hRadarTimer);
	g_hRadarTimer = INVALID_HANDLE;
	
	UnhookUserMessage(g_msgUpdateRadar, Hook_UpdateRadar, true);
	
	g_bFarEspEnabled = false;
}

public OnMapStart()
{
	if (g_bEnabled && !g_bFarEspEnabled && SMAC_GetGameType() == Game_CSS)
	{
		farESP_Enable();
	}
}

public OnMapEnd()
{
	if (g_bFarEspEnabled)
	{
		farESP_Disable();
	}
}

public Action:Hook_UpdateRadar(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	// We will send custom messages only.
	return Plugin_Handled;
}

public PlayerManager_ThinkPost(entity)
{
	if (!g_bFarEspEnabled)
		return;
	
	// Keep track of which players have been spotted.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bProcess[i] && GetEntData(entity, g_iPlayerSpotted + i, 1))
		{
			// Immediately update this client's data.
			if (!g_bPlayerSpotted[i])
			{
				g_bPlayerSpotted[i] = true;
				SendClientDataToAll(i);
			}
		}
		else
		{
			g_bPlayerSpotted[i] = false;
		}
	}
}

public Action:Timer_UpdateRadar(Handle:timer)
{
	if (!g_bFarEspEnabled)
		return Plugin_Stop;
	
	// Send one message for spotted players, and two for team-specific.
	decl allClients[MaxClients], tClients[MaxClients], ctClients[MaxClients];
	new numAllClients, numTClients, numCTClients;
	
	// Determine which clients we'll send our messages to.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			allClients[numAllClients++] = i;
		}
		
		if (g_bProcess[i])
		{
			switch (g_iTeam[i])
			{
				case CS_TEAM_T:
				{
					tClients[numTClients++] = i;
				}
				case CS_TEAM_CT:
				{
					ctClients[numCTClients++] = i;
				}
			}
		}
	}
	
	// Send scrambled spotted players first so they can be overwritten for teammates later.
	decl Float:vOrigin[3], Float:vAngles[3], Handle:bf, client, count;
	
	// Spotted players.
	if (numAllClients)
	{
		bf = StartMessageEx(g_msgUpdateRadar, allClients, numAllClients, USERMSG_BLOCKHOOKS);
		
		count = 0;
		for (new i = 1; i <= MaxClients && count <= MAX_RADAR_CLIENTS; i++)
		{
			if (g_bPlayerSpotted[i] && g_bProcess[i])
			{
				GetClientAbsOrigin(i, vOrigin);
				GetClientAbsAngles(i, vAngles);
				
				BfWriteByte(bf, i);
				BfWriteSBitLong(bf, RoundToNearest(vOrigin[0] / 4.0), 13);
				BfWriteSBitLong(bf, RoundToNearest(vOrigin[1] / 4.0), 13);
				BfWriteSBitLong(bf, RoundToNearest((vOrigin[2] - MT_GetRandomFloat(500.0, 1000.0)) / 4.0), 13);
				BfWriteSBitLong(bf, RoundToNearest(vAngles[1]), 9);
				count++;
			}
		}
		
		BfWriteByte(bf, 0);
		EndMessage();
	}
	
	// Terrorists.
	if (numTClients)
	{
		bf = StartMessageEx(g_msgUpdateRadar, tClients, numTClients, USERMSG_BLOCKHOOKS);
		
		count = 0;
		for (new i = 0; i < numTClients && count <= MAX_RADAR_CLIENTS; i++)
		{
			client = tClients[i];
			
			GetClientAbsOrigin(client, vOrigin);
			GetClientAbsAngles(client, vAngles);
			
			BfWriteByte(bf, client);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[0] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[1] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[2] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vAngles[1]), 9);
			count++;
		}
		
		BfWriteByte(bf, 0);
		EndMessage();
	}
	
	// Counter-Terrorists.
	if (numCTClients)
	{
		bf = StartMessageEx(g_msgUpdateRadar, ctClients, numCTClients, USERMSG_BLOCKHOOKS);
		
		count = 0;
		for (new i = 0; i < numCTClients && count <= MAX_RADAR_CLIENTS; i++)
		{
			client = ctClients[i];
			
			GetClientAbsOrigin(client, vOrigin);
			GetClientAbsAngles(client, vAngles);
			
			BfWriteByte(bf, client);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[0] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[1] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[2] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vAngles[1]), 9);
			count++;
		}
		
		BfWriteByte(bf, 0);
		EndMessage();
	}
	
	return Plugin_Continue;
}

SendClientDataToAll(client)
{
	decl iClients[MaxClients], Float:vOrigin[3], Float:vAngles[3];
	new numClients, iTeam = g_iTeam[client];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bProcess[i] && g_iTeam[i] != iTeam)
		{
			iClients[numClients++] = i;
		}
	}
	
	if (numClients)
	{
		new Handle:bf = StartMessageEx(g_msgUpdateRadar, iClients, numClients, USERMSG_BLOCKHOOKS);
		GetClientAbsOrigin(client, vOrigin);
		GetClientAbsAngles(client, vAngles);
		
		BfWriteByte(bf, client);
		BfWriteSBitLong(bf, RoundToNearest(vOrigin[0] / 4.0), 13);
		BfWriteSBitLong(bf, RoundToNearest(vOrigin[1] / 4.0), 13);
		BfWriteSBitLong(bf, RoundToNearest((vOrigin[2] - MT_GetRandomFloat(500.0, 1000.0)) / 4.0), 13);
		BfWriteSBitLong(bf, RoundToNearest(vAngles[1]), 9);

		BfWriteByte(bf, 0);
		EndMessage();
	}
}
