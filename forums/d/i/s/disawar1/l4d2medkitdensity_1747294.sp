/********************************************************************************************
* Plugin	: [L4D2] Medkit Density in Versus/TeamVersus or Coop/Realism/Versus/TeamVersus
* Version	: 1.5.
* Game		: Left 4 Dead 2
* Author	: SwiftReal (Yves)
* Testers	: Myself, SwiftReal
* Website	: forums.alliedmods.net
* 
* Purpose	: This plugin removes, replaces, doubles or leaves medkits
* 			  at the start of a campaign, at checkpoints/safehouses and in the outdoors.
* 
* WARNING	: Please use sourcemod's latest 1.3 branch snapshot.
* 
* Version 1.5
* 		- added FCVAR_NOTIFY cvar flags to all cvars
* 		- added ability to have infite medkits at start, saferoom and outdoors
* 		- removed round_freeze_end event, applied different method
* Version 1.4
* 		- remove abilities to double, tripple or quadruple medkitcount at start, checkpoints and outdoors
* 		- added ability to set a specified amount of medkits at start and checkpoints
* 		- added ability to replace each outdoor medkit with specified amount of medkits
* 		- fixed case where random outdoor medkit was treated like a saferoom medkit
* 		- changed method of spawning saferoom medkits to gradually spawning
* 		- changed the method of finding entities
* 		- sm_md_start now effects every medkit at start of every map in versus games
* Version 1.3.2
* 		- fixed a bug where a survivor has his medkit removed from him/her
* 		- other minor changes 
* Version 1.3.1
* 		- applied another way to carry over the correct amount of medkits at checkpoint to next map
* 		- added a reset on closest medkit location on mapchange
* 		- changed convar limits for tripple, quadruple and 1defib+3medkits to work
* Version 1.3
* 		- really fixed carrying over the correct amount of medkits at checkpoint to next map
* 		- fixed replacing some outdoor medkits that the director spawned late into the game
* 		- added the abilities to tripple or quadruple medkitcount at start, checkpoints and outdoors
* 		- added the ability to replace 1 of 4 medkits with 1 defibrillator at start and checkpoints
* Version 1.2
* 		- fixed carrying over the correct amount of medkits at checkpoint to next map
* Version 1.1
* 		- set convar min and max limits
* 		- fixed issue with spawning way too many medkits after a few fail rounds
* Version 1.0
*      	- Initial release
* 
********************************************************************************************/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.5 FIXED"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define MEDKIT				"models/w_models/weapons/w_eq_medkit.mdl"
#define DEFIB				"models/w_models/weapons/w_eq_defibrillator.mdl"
#define PILLS				"models/w_models/weapons/w_eq_painpills.mdl"

new Handle:h_PluginEnabled
new Handle:h_OnlyVersus
new Handle:h_KitsStart
new Handle:h_KitsStartCount
new Handle:h_KitsSaferoom
new Handle:h_KitsSaferoomCount
new Handle:h_KitsOutdoors
new Handle:h_KitsOutdoorsCount
new Handle:timer_DensityOutdoors = INVALID_HANDLE
new String:g_MapName[128]
new String:g_GameMode[32]
new Float:vecLocationStart[3]
new Float:vecClosestKitStart[3]
new Float:vecLocationCheckpoint[3]
new Float:vecClosestKitCheckpoint[3]
new g_iCount = 0
new bool:g_bFirstItemPickedUp
new bool:g_bMissionLost
new bool:g_bRoundStarted

public Plugin:myinfo = 
{
	name			= "[L4D2] Medkit Density",
	author			= "SwiftReal",
	description		= "Removes, replaces or adds medkits at start, saferooms and outdoors",
	version			= PLUGIN_VERSION,
	url				= "http://forums.alliedmods.net/showthread.php?p=1121462"
}

public OnPluginStart()
{
	new String:GameFolder[50]
	GetGameFolderName(GameFolder, sizeof(GameFolder))
	if(!StrEqual(GameFolder, "left4dead2", false))
		SetFailState("Medkit Density supports Left 4 Dead 2 only")
	
	// Register Cmds and Cvars
	CreateConVar("medkitdensity_version", PLUGIN_VERSION, "Medkit Density version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD)
	SetConVarString(FindConVar("medkitdensity_version"), PLUGIN_VERSION)
	
	h_PluginEnabled 		= CreateConVar("sm_md_enabled", "1", "Should the plugin be on? 1[on] 2[off]", CVAR_FLAGS, true, 0.0, true, 1.0)
	h_OnlyVersus	 		= CreateConVar("sm_md_versusonly", "0", "Change medkit density in versus games only? 0[coop,realism,versus,teamversus] 1[versus,teamversus]", CVAR_FLAGS, true, 0.0, true, 1.0)
	h_KitsStart				= CreateConVar("sm_md_start", "1", "What to do with medkits at the start? (coop: start of campaign)(versus: start of every map) 0[do nothing] 1[use sm_md_start_medkitcount] 2[remove medkits] 3[replace with pills] 4[replace with defibrillators] 5[infinite medkits] 6[change 1 medkit to 1 defibrillator]", CVAR_FLAGS, true, 0.0, true, 6.0)
	h_KitsStartCount		= CreateConVar("sm_md_start_medkitcount", "8", "At start, replace medkits with how many medkits?", CVAR_FLAGS, true, 4.0, true, 20.0)
	h_KitsSaferoom 			= CreateConVar("sm_md_saferoom", "1", "What to do with medkits in saferooms? 0[do nothing] 1[use sm_md_checkpoint_medkitcount] 2[remove medkits] 3[replace with pills] 4[replace with defibrillators] 5[infinite] 6[replace 1 medkit with 1 defibrillator]", CVAR_FLAGS, true, 0.0, true, 6.0)
	h_KitsSaferoomCount		= CreateConVar("sm_md_saferoom_medkitcount", "12", "In saferooms, replace medkits with how many medkits?", CVAR_FLAGS, true, 4.0, true, 20.0)
	h_KitsOutdoors 			= CreateConVar("sm_md_outdoors", "1", "What to do with each medkit outdoors? 0[do nothing] 1[use sm_md_outdoors_medkitcount] 2[remove medkits] 3[replace with pills] 4[replace with defibrillators] 5[infinite]", CVAR_FLAGS, true, 0.0, true, 5.0)
	h_KitsOutdoorsCount		= CreateConVar("sm_md_outdoors_medkitcount", "2", "With how many medkits should each medkit in the outdoors be replaced?", CVAR_FLAGS, true, 2.0, true, 10.0)

	// Hook Events
	HookEvent("item_pickup", evtItemPickup)
	HookEvent("mission_lost", evtMissionLost)
	HookEvent("round_start", evtRoundStarted)
	
	// Execute or create cfg
	AutoExecConfig(true, "l4d2medkitdensity")
}

public OnMapStart()
{
	if(!IsModelPrecached(MEDKIT)) PrecacheModel(MEDKIT, true)	
	if(!IsModelPrecached(DEFIB)) PrecacheModel(DEFIB, true)	
	if(!IsModelPrecached(PILLS)) PrecacheModel(PILLS, true)
	
	g_bFirstItemPickedUp = false
	g_bMissionLost = false
	g_bRoundStarted = false
}

public evtItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(h_PluginEnabled))
	{
		if(!g_bFirstItemPickedUp)
		{
			CreateTimer(3.0, Timer_DelayChangeDensity)			
			g_bFirstItemPickedUp = true
		}
		else if(g_bMissionLost && g_bRoundStarted)
		{
			CreateTimer(1.0, Timer_DelayChangeDensity)
		}
	}
}

public OnClientDisconnect(client)
{
	if(!RealPlayersInGame(client))
	{
		if(timer_DensityOutdoors != INVALID_HANDLE)
		{
			KillTimer(timer_DensityOutdoors)
			timer_DensityOutdoors = INVALID_HANDLE
		}
		g_bFirstItemPickedUp = false
		g_bMissionLost = false
		g_bRoundStarted = false
	}
}

public evtMissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bMissionLost = true
	if(timer_DensityOutdoors != INVALID_HANDLE)
	{
		KillTimer(timer_DensityOutdoors)
		timer_DensityOutdoors = INVALID_HANDLE
	}
}

public evtRoundStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundStarted = true
}

public Action:Timer_DelayChangeDensity(Handle:timer)
{
	GetCurrentMap(g_MapName, sizeof(g_MapName))
	GetConVarString(FindConVar("mp_gamemode"), g_GameMode, sizeof(g_GameMode))
	new bool:bOnlyVersus = GetConVarBool(h_OnlyVersus)
	if((StrContains(g_GameMode, "versus", false) != -1) || ((StrContains(g_GameMode, "scavenge", false) == -1) && !bOnlyVersus))
	{
		FindLocationStart()
		FindLocationSaferoom()
		SetKitsDensity_Start()
		SetKitsDensity_Saferoom()
		if(timer_DensityOutdoors == INVALID_HANDLE)
			timer_DensityOutdoors = CreateTimer(10.0, Timer_DensityOutdoors, _, TIMER_REPEAT)
	}
	return Plugin_Handled
}

public Action:Timer_DensityOutdoors(Handle:timer)
{
	SetDensity_Outdoors()
	return Plugin_Continue
}

stock FindLocationStart()
{
	new ent
	decl Float:vecLocation[3]
	
	if(StrContains(g_MapName, "m1_", false) != -1)
	{
		// search for a survivor spawnpoint if first map of campaign
		ent = -1
		while((ent = FindEntityByClassname(ent, "info_survivor_position")) != -1)
		{
			if(IsValidEntity(ent))
			{
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
				vecLocationStart = vecLocation
				break
			}
		}
	}
	else
	{
		// Search for a locked exit door,
		ent = -1
		while((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
		{
			if(IsValidEntity(ent))
			{
				if(GetEntProp(ent, Prop_Send, "m_bLocked") == 1)
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
					vecLocationStart = vecLocation
					break
				}
			}
		}
	}	
	// search for an ammo pile close to spawnpoint or exit door
	ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
			if(GetVectorDistance(vecLocationStart, vecLocation, false) < 1000)
			{
				vecLocationStart = vecLocation
				break
			}
		}
	}
	return
}

stock FindLocationSaferoom()
{
	new ent
	decl Float:vecLocation[3]
	
	// Search for a locked checkpoint door,
	ent = -1
	while((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
	{
		if(IsValidEntity(ent))
		{
			if(GetEntProp(ent, Prop_Send, "m_bLocked") != 1)
			{
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
				vecLocationCheckpoint = vecLocation
			}
		}
	}
	
	if((StrContains(g_MapName, "c2m3", false) != -1) || (StrContains(g_MapName, "cm4m", false) != -1))
		return
	
	// search for an ammo pile close to checkpoint door
	ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
			if(GetVectorDistance(vecLocationCheckpoint, vecLocation, false) < 1000)
			{
				vecLocationCheckpoint = vecLocation
				return
			}
		}
	}
	return
}

stock SetKitsDensity_Start()
{	
	new ent
	decl Float:vecLocation[3]
	new iKitsStart = GetConVarInt(h_KitsStart)
	new iKitsStartCount = GetConVarInt(h_KitsStartCount)
	
	// Find closest medkit nearby survivors start
	ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
			
			// If vecClosestKit is zero, then this must be the first medkit we found.
			if((vecClosestKitStart[0] + vecClosestKitStart[1] + vecClosestKitStart[2]) == 0.0)
				vecClosestKitStart = vecLocation
			
			// If this medkit is closer than the last medkit, record its location.
			if(GetVectorDistance(vecLocationStart, vecLocation, false) < GetVectorDistance(vecLocationStart, vecClosestKitStart, false))
				vecClosestKitStart = vecLocation
		}
	}
	// Remove, replace or leave the medkits near it
	ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
			if(GetVectorDistance(vecClosestKitStart, vecLocation, false) < 200)
			{
				if((StrContains(g_MapName, "m1_", false) != -1) || (StrContains(g_GameMode, "versus", false) != -1))
				{
					switch(iKitsStart)
					{
						case 0:
						{
							break
						}
						case 1:
						{
							if(iKitsStartCount > 4)
							{
								// set medkit count (1 medkit found, 6 medkits in total)
								if(StrContains(g_MapName, "c4m1", false) != -1)
								{
									if(iKitsStartCount > 6)
									{
										iKitsStartCount -= 5
									}
									else if(iKitsStartCount == 5)
									{
										AcceptEntityInput(ent, "Kill")
										break
									}
									else
									{
										break
									}
								}
								// set medkit count (1 medkit found, 4 medkits in total)
								else
								{
									iKitsStartCount -= 3									
								}								
								new Float:fCount = float(iKitsStartCount)
								DispatchKeyValueFloat(ent, "count", fCount)
								break
							}
						}
						case 2:
						{
							AcceptEntityInput(ent, "Kill")
						}
						case 3:
						{
							ReplaceOrAddEnt(ent, "weapon_pain_pills", true)
						}
						case 4:
						{
							ReplaceOrAddEnt(ent, "weapon_defibrillator", true)
						}
						case 5:
						{
							DispatchKeyValueFloat(ent, "count", 100.0)
						}
						case 6:
						{
							// replace one kit with defib and stop
							ReplaceOrAddEnt(ent, "weapon_defibrillator", true)
							break
						}
					}
				}
				else if((StrContains(g_MapName, "m1_", false) == -1) || (StrContains(g_GameMode, "versus", false) != -1))
				{
					if(GetConVarInt(h_KitsSaferoom) == 5)
					{
						DispatchKeyValueFloat(ent, "count", 100.0)
					}
				}
			}
		}
	}
	return
}

stock SetKitsDensity_Saferoom()
{	
	new ent
	decl Float:vecLocation[3]
	new iKitsSaferoom = GetConVarInt(h_KitsSaferoom)
	new iKitsSaferoomCount = GetConVarInt(h_KitsSaferoomCount)
	
	// Find closest medkit nearby a checkpoint door
	ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
			// If vecClosestKit is zero, then this must be the first medkit we found.
			if((vecClosestKitCheckpoint[0] + vecClosestKitCheckpoint[1] + vecClosestKitCheckpoint[2]) == 0.0)
				vecClosestKitCheckpoint = vecLocation
			
			// If this medkit is closer than the last medkit, record its location.
			if(GetVectorDistance(vecLocationCheckpoint, vecLocation, false) < GetVectorDistance(vecLocationCheckpoint, vecClosestKitCheckpoint, false))
				vecClosestKitCheckpoint = vecLocation
		}
	}
	// Remove, replace or leave the medkits near it
	ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
			if(GetVectorDistance(vecClosestKitCheckpoint, vecLocation, false) < 200)
			{
				switch(iKitsSaferoom)
				{
					case 0:
					{
						break
					}
					case 1:
					{
						if(iKitsSaferoomCount > 4)
						{
							// set medkit count (1 medkit found, 6 medkits in total)
							if(StrContains(g_MapName, "c4m1", false) != -1)
							{
								if(iKitsSaferoomCount > 6)
								{
									iKitsSaferoomCount -= 6
								}
								else if(iKitsSaferoomCount == 5)
								{
									AcceptEntityInput(ent, "Kill")
									break
								}
								else
								{
									break
								}
							}
							// set medkit count (1 medkit found, 4 medkits in total)
							else
							{
								iKitsSaferoomCount -= 4									
							}
							// spawn medkits (above it) every second
							new ref = EntIndexToEntRef(ent)
							new Handle:datapack
							CreateDataTimer(1.5, Timer_GraduallySpawnMedkits, datapack, TIMER_REPEAT)
							WritePackCell(datapack, ref)
							WritePackCell(datapack, iKitsSaferoomCount)			
							break
						}
					}
					case 2:
					{
						AcceptEntityInput(ent, "Kill")
					}
					case 3:
					{
						ReplaceOrAddEnt(ent, "weapon_pain_pills", true)
					}
					case 4:
					{
						ReplaceOrAddEnt(ent, "weapon_defibrillator", true)
					}
					case 5:
					{
						DispatchKeyValueFloat(ent, "count", 100.0)
					}
					case 6:
					{
						// replace one kit with defib
						ReplaceOrAddEnt(ent, "weapon_defibrillator", true)
						// stop replacing anything else
						break
					}
				}
			}
		}
	}
	return
}

stock SetDensity_Outdoors()
{	
	new ent
	decl Float:vecLocation[3]
	new iKitsOutdoors = GetConVarInt(h_KitsOutdoors)
	new iKitsOutdoorsCount = GetConVarInt(h_KitsOutdoorsCount)
	
	// Find all medkits far from a safe area
	ent = -1
	while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)			
			// Remove, replace or leave the medkits away from a safe area
			if((GetVectorDistance(vecClosestKitStart, vecLocation, false) > 800) && (GetVectorDistance(vecClosestKitCheckpoint, vecLocation, false) > 800))
			{
				if(!IsLocationFar(vecLocation[0], vecLocation[1], vecLocation[2]))
				{
					break
				}
				else
				{
					switch(iKitsOutdoors)
					{
						case 0:
						{
							break
						}
						case 1:
						{
							// set medkit count (1 medkit found, who knows how many medkits in total)
							if(iKitsOutdoorsCount > 1)
							{
								new Float:fCount = float(iKitsOutdoorsCount)
								DispatchKeyValueFloat(ent, "count", fCount)
							}
							else
							{
								break
							}
						}
						case 2:
						{
							AcceptEntityInput(ent, "Kill")
						}
						case 3:
						{
							ReplaceOrAddEnt(ent, "weapon_pain_pills", true)
						}
						case 4:
						{
							ReplaceOrAddEnt(ent, "weapon_defibrillator", true)
						}
						case 5:
						{
							DispatchKeyValueFloat(ent, "count", 100.0)
						}
					}
				}
			}
		}
	}
	return
}

stock bool:IsLocationFar(const Float:vecX, const Float:vecY, const Float:vecZ)
{
	decl Float:vecLocation[3]
	vecLocation[0] = vecX
	vecLocation[1] = vecY
	vecLocation[2] = vecZ
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i))
			continue
		if(!IsClientInGame(i))
			continue
		if(GetClientTeam(i) != 2)
			continue
		
		decl Float:vecOrigin[3]
		GetClientAbsOrigin(i, vecOrigin)
		
		if(GetVectorDistance(vecOrigin, vecLocation, false) < 500)
			return false
	}
	return true
}

stock bool:RealPlayersInGame(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != client)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				return true
		}
	}	
	return false
}

public Action:Timer_GraduallySpawnMedkits(Handle:timer, Handle:datapack)
{
	ResetPack(datapack, false)
	new ref = ReadPackCell(datapack)
	new count = ReadPackCell(datapack)
	
	new ent = EntRefToEntIndex(ref)
	ReplaceOrAddEnt(ent, "weapon_first_aid_kit", false)	
	g_iCount++
	
	if(g_iCount == count)
	{
		g_iCount = 0
		return Plugin_Stop
	}	
	return Plugin_Continue
}

stock ReplaceOrAddEnt(any:ent, const String:entname[], bool:delent)
{
	if(!IsValidEntity(ent)) return
	
	decl Float:vecLocation[3]
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation)
	new entCreated = CreateEntityByName(entname)
	if(entCreated != -1)
	{
		decl Float:vecAngles[3]
		GetEntPropVector(ent, Prop_Send, "m_angRotation", vecAngles)
		
		if((StrContains(entname, "weapon_pain_pills", false) != -1) && vecAngles[0] == 90.0)
		{
			vecAngles[0] = 0.0
			vecLocation[2] -= 3.0
		}
		
		if(StrContains(entname, "weapon_first_aid_kit", false) != -1)
			vecLocation[2] += 32.0
		
		TeleportEntity(entCreated, vecLocation, vecAngles, NULL_VECTOR)
		DispatchSpawn(entCreated)
		
		if(delent)
			AcceptEntityInput(ent, "Kill")
	}
	return
}