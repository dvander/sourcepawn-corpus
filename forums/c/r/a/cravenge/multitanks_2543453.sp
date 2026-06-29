#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define PLUGIN_VERSION "1.3"

enum GameModeStatus
{
	GMS_UNKNOWN = 0,
	GMS_COOP = 1,
	GMS_VERSUS = 2,
	GMS_SURVIVAL = 3,
	GMS_SCAVENGE = 4
};

enum MapStatus
{
	MS_UNKNOWN = 0,
	MS_REGULAR = 1,
	MS_FINALE = 2,
	MS_ESCAPE = 3,
	MS_LEAVING = 4,
	MS_ROUNDEND = 5
};

char sLabels[5][] =
{
	"regular",
	"finale",
	"1stwave",
	"2ndwave",
	"escape"
};

GameModeStatus gmsGameMode;
MapStatus mMapStatus;
int iMaxZombies, iFrustration[MAXPLAYERS+1], iTankClass, iMTHealthCoop[2], iMTHealthVersus[5], iMTHealthSurvival,
	iMTHealthScavenge, iMTCountCoop[2], iMTCountVersus[5], iMTCountSurvival, iMTCountScavenge, iFinaleWave,
	iTankHP, iTankCount, iMaxTankCount;

bool bRoundBegan, bRoundFinished, bFrustrated[MAXPLAYERS+1], bIsTank[MAXPLAYERS+1], bMTOn, bMTAnnounce,
	bMTSameSpawn[3], bMTDisplay, bFirstSpawned;

float fTankPos[3], fMTSpawnDelay[2];
ConVar hMTOn, hMTHealthCoop[2], hMTHealthVersus[5], hMTHealthSurvival, hMTHealthScavenge, hMTCountCoop[2],
	hMTCountVersus[5], hMTCountSurvival, hMTCountScavenge, hMTAnnounce, hMTSameSpawn[3], hMTSpawnDelay[2],
	hMTDisplay, hGameMode;

Panel pMTList;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (StrEqual(sGameName, "left4dead", false) || StrEqual(sGameName, "left4dead2", false))
	{
		iTankClass = (StrEqual(sGameName, "left4dead2", false)) ? 8 : 5;
		return APLRes_Success;
	}
	
	strcopy(error, err_max, "[MT] Plugin Supports L4D And L4D2 Only!");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = "MultiTanks - Improved",
	author = "Red Alex, cravenge",
	description = "This Time, Let All Hell Break Loose!",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	hGameMode = FindConVar("mp_gamemode");
	HookConVarChange(hGameMode, OnMTCVarsChanged);
	
	gmsGameMode = GetGameModeInfo();
	
	iMaxZombies = (FindConVar("super_versus_version") != null) ? FindConVar("super_versus_infected_limit").IntValue : FindConVar("z_max_player_zombies").IntValue;
	HookConVarChange((FindConVar("super_versus_version") != null) ? FindConVar("super_versus_infected_limit") : FindConVar("z_max_player_zombies"), OnMTCVarsChanged);
	
	CreateConVar("multitanks_version", PLUGIN_VERSION, "MultiTanks Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hMTOn = CreateConVar("multitanks_on", "1", "Enable/Disable Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	hMTHealthSurvival = CreateConVar("multitanks_health_survival", "17500", "Health Of Tanks (Survival)", FCVAR_NOTIFY|FCVAR_SPONLY);
	hMTCountSurvival = CreateConVar("multitanks_count_survival", "2", "Total Count Of Tanks (Survival)", FCVAR_NOTIFY|FCVAR_SPONLY);
	hMTHealthScavenge = CreateConVar("multitanks_health_scavenge", "17500", "Health Of Tanks (Scavenge)", FCVAR_NOTIFY|FCVAR_SPONLY);
	hMTCountScavenge = CreateConVar("multitanks_count_scavenge", "2", "Total Count Of Tanks (Scavenge)", FCVAR_NOTIFY|FCVAR_SPONLY);
	hMTAnnounce = CreateConVar("multitanks_announce", "1", "Enable/Disable Announcements", FCVAR_NOTIFY|FCVAR_SPONLY);
	hMTDisplay = CreateConVar("multitanks_display", "0", "Enable/Disable HUD Display", FCVAR_NOTIFY|FCVAR_SPONLY);
	
	iMTHealthSurvival = hMTHealthSurvival.IntValue;
	iMTCountSurvival = hMTCountSurvival.IntValue;
	iMTHealthScavenge = hMTHealthScavenge.IntValue;
	iMTCountScavenge = hMTCountScavenge.IntValue;
	
	bMTOn = hMTOn.BoolValue;
	bMTAnnounce = hMTAnnounce.BoolValue;
	bMTDisplay = hMTDisplay.BoolValue;
	
	HookConVarChange(hMTOn, OnMTCVarsChanged);
	HookConVarChange(hMTHealthSurvival, OnMTCVarsChanged);
	HookConVarChange(hMTCountSurvival, OnMTCVarsChanged);
	HookConVarChange(hMTHealthScavenge, OnMTCVarsChanged);
	HookConVarChange(hMTCountScavenge, OnMTCVarsChanged);
	HookConVarChange(hMTAnnounce, OnMTCVarsChanged);
	HookConVarChange(hMTDisplay, OnMTCVarsChanged);
	
	char sDescriptions[3][128];
	for (int i = 0; i < 2; i++)
	{
		StripQuotes(sLabels[i]);
		
		Format(sDescriptions[0], 128, "multitanks_health_coop_%s", sLabels[i]);
		switch (i)
		{
			case 0:
			{
				strcopy(sDescriptions[1], 128, "22500");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Regular Maps");
			}
			case 1:
			{
				strcopy(sDescriptions[1], 128, "25000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Finale Maps");
			}
		}
		
		hMTHealthCoop[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		Format(sDescriptions[0], 128, "multitanks_count_coop_%s", sLabels[i]);
		strcopy(sDescriptions[1], 128, "1");
		switch (i)
		{
			case 0: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Regular Maps");
			case 1: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Finale Maps");
		}
		
		hMTCountCoop[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		iMTHealthCoop[i] = hMTHealthCoop[i].IntValue;
		iMTCountCoop[i] = hMTCountCoop[i].IntValue;
		
		HookConVarChange(hMTHealthCoop[i], OnMTCVarsChanged);
		HookConVarChange(hMTCountCoop[i], OnMTCVarsChanged);
		
		Format(sDescriptions[0], 128, "multitanks_spawn_delay_%s", sLabels[(i == 0) ? i : i + 3]);
		switch (i)
		{
			case 0:
			{
				strcopy(sDescriptions[1], 128, "5.0");
				strcopy(sDescriptions[2], 128, "Delay Of Spawning Tanks");
			}
			case 1:
			{
				strcopy(sDescriptions[1], 128, "2.5");
				strcopy(sDescriptions[2], 128, "Delay Of Spawning Tanks In Finale Escapes");
			}
		}
		
		hMTSpawnDelay[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		fMTSpawnDelay[i] = hMTSpawnDelay[i].FloatValue;
		HookConVarChange(hMTSpawnDelay[i], OnMTCVarsChanged);
	}
	
	for (int i = 0; i < 5; i++)
	{
		StripQuotes(sLabels[i]);
		
		Format(sDescriptions[0], 128, "multitanks_health_versus_%s", sLabels[i]);
		switch (i)
		{
			case 0:
			{
				strcopy(sDescriptions[1], 128, "20000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Regular Maps (Versus)");
			}
			case 1:
			{
				strcopy(sDescriptions[1], 128, "22500");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Finale Maps (Versus)");
			}
			case 2:
			{
				strcopy(sDescriptions[1], 128, "27500");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In First Wave Finales (Versus)");
			}
			case 3:
			{
				strcopy(sDescriptions[1], 128, "30000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Second Wave Finales (Versus)");
			}
			case 4:
			{
				strcopy(sDescriptions[1], 128, "25000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Finale Escapes (Versus)");
			}
		}
		
		hMTHealthVersus[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		Format(sDescriptions[0], 128, "multitanks_count_versus_%s", sLabels[i]);
		strcopy(sDescriptions[1], 128, "2");
		switch (i)
		{
			case 0: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Regular Maps (Versus)");
			case 1: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Finale Maps (Versus)");
			case 2: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In First Wave Finales (Versus)");
			case 3: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Second Wave Finales (Versus)");
			case 4: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Finale Escapes (Versus)");
		}
		
		hMTCountVersus[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		iMTHealthVersus[i] = hMTHealthVersus[i].IntValue;
		iMTCountVersus[i] = hMTCountVersus[i].IntValue;
		
		HookConVarChange(hMTHealthVersus[i], OnMTCVarsChanged);
		HookConVarChange(hMTCountVersus[i], OnMTCVarsChanged);
		
		if (i == 0 || i == 1 || i == 4)
		{
			Format(sDescriptions[0], 128, "multitanks_same_spawn_%s", sLabels[i]);
			strcopy(sDescriptions[1], 128, "0");
			switch (i)
			{
				case 0: strcopy(sDescriptions[2], 128, "Enable/Disable Same Spawn Of Tanks In Regular Maps");
				case 1: strcopy(sDescriptions[2], 128, "Enable/Disable Same Spawn Of Tanks In Finale Maps");
				case 4: strcopy(sDescriptions[2], 128, "Enable/Disable Same Spawn Of Tanks In Finale Escapes");
			}
			
			hMTSameSpawn[(i == 4) ? i - 2 : i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
			bMTSameSpawn[(i == 4) ? i - 2 : i] = hMTSameSpawn[(i == 4) ? i - 2 : i].BoolValue;
			HookConVarChange(hMTSameSpawn[(i == 4) ? i - 2 : i], OnMTCVarsChanged);
		}
	}
	
	AutoExecConfig(true, "multitanks");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("tank_frustrated", OnTankFrustrated);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("finale_start", OnFinaleStart);
	HookEvent("finale_escape_start", OnFinaleEscapeStart);
	HookEvent("finale_vehicle_leaving", OnFinaleVehicleLeaving);
	HookEvent("tank_spawn", OnTankSpawn);
}

public void OnPluginEnd()
{
	UnhookEvent("round_start", OnRoundStart);
	UnhookEvent("round_end", OnRoundEnd);
	UnhookEvent("tank_frustrated", OnTankFrustrated);
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	UnhookEvent("finale_start", OnFinaleStart);
	UnhookEvent("finale_escape_start", OnFinaleEscapeStart);
	UnhookEvent("finale_vehicle_leaving", OnFinaleVehicleLeaving);
	UnhookEvent("tank_spawn", OnTankSpawn);
}

public void OnMTCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	bMTOn = hMTOn.BoolValue;
	bMTAnnounce = hMTAnnounce.BoolValue;
	bMTDisplay = hMTDisplay.BoolValue;
	
	for (int i = 0; i < 5; i++)
	{
		if (i == 0 || i == 1 || i == 4)
		{
			bMTSameSpawn[(i != 4) ? i : i - 2] = hMTSameSpawn[(i != 4) ? i : i - 2].BoolValue;
		}
		
		iMTHealthVersus[i] = hMTHealthVersus[i].IntValue;
		iMTCountVersus[i] = hMTCountVersus[i].IntValue;
	}
	
	iMaxZombies = (FindConVar("super_versus_version") != null) ? FindConVar("super_versus_infected_limit").IntValue : FindConVar("z_max_player_zombies").IntValue;
	
	iMTHealthSurvival = hMTHealthSurvival.IntValue;
	iMTCountSurvival = hMTCountSurvival.IntValue;
	iMTHealthScavenge = hMTHealthScavenge.IntValue;
	iMTCountScavenge = hMTCountScavenge.IntValue;
	
	for (int i = 0; i < 2; i++)
	{
		iMTHealthCoop[i] = hMTHealthCoop[i].IntValue;
		iMTCountCoop[i] = hMTCountCoop[i].IntValue;
		
		fMTSpawnDelay[i] = hMTSpawnDelay[i].FloatValue;
	}
	if (bMTOn)
	{
		gmsGameMode = GetGameModeInfo();
		LaunchMTParameters();
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	mMapStatus = view_as<MapStatus>(MS_REGULAR);
	LaunchMTParameters();
	
	iTankCount = 0;
	iFinaleWave = 0;
	
	bRoundBegan = true;
	bRoundFinished = false;
	bFirstSpawned = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iFrustration[i] = 0;
			
			bIsTank[i] = false;
			bFrustrated[i] = false;
		}
	}
	
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	mMapStatus = view_as<MapStatus>(MS_ROUNDEND);
	LaunchMTParameters();
	
	iTankCount = 0;
	iFinaleWave = 0;
	
	bRoundBegan = false;
	bRoundFinished = true;
	bFirstSpawned = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iFrustration[i] = 0;
			
			bIsTank[i] = false;
			bFrustrated[i] = false;
		}
	}
	
	return Plugin_Continue;
}

public Action OnTankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (!IsTank(tank))
	{
		return Plugin_Continue;
	}
	
	bFrustrated[tank] = true;
	
	if (bMTAnnounce)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
			{
				PrintToChat(i, "\x04[MT]\x01 %N Lost Control!", tank);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (!IsTank(died))
	{
		return Plugin_Continue;
	}
	
	if (iTankCount > 0)
	{
		iTankCount -= 1;
		if (iTankCount <= 0)
		{
			bFirstSpawned = false;
		}
	}
	
	if (bFrustrated[died])
	{
		bFrustrated[died] = false;
	}
	bIsTank[died] = false;
	
	return Plugin_Continue;
}

public Action OnFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	if (gmsGameMode == view_as<GameModeStatus>(GMS_VERSUS))
	{
		mMapStatus = view_as<MapStatus>(MS_FINALE);
		iFinaleWave = 0;
	}
	else
	{
		mMapStatus = view_as<MapStatus>(MS_ROUNDEND);
		
		bRoundBegan = false;
		bRoundFinished = true;
		bFirstSpawned = false;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				iFrustration[i] = 0;
				
				bIsTank[i] = false;
				bFrustrated[i] = false;
			}
		}
	}
	LaunchMTParameters();
	
	return Plugin_Continue;
}

public Action OnFinaleEscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	if (gmsGameMode == view_as<GameModeStatus>(GMS_VERSUS))
	{
		mMapStatus = view_as<MapStatus>(MS_ESCAPE);
	}
	else
	{
		mMapStatus = view_as<MapStatus>(MS_ROUNDEND);
		
		bRoundBegan = false;
		bRoundFinished = true;
		bFirstSpawned = false;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				iFrustration[i] = 0;
				
				bIsTank[i] = false;
				bFrustrated[i] = false;
			}
		}
	}
	LaunchMTParameters();
	
	return Plugin_Continue;
}

public Action OnFinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	if (gmsGameMode == view_as<GameModeStatus>(GMS_VERSUS))
	{
		mMapStatus = view_as<MapStatus>(MS_LEAVING);
		iFinaleWave = 0;
	}
	else
	{
		mMapStatus = view_as<MapStatus>(MS_ROUNDEND);
		
		bRoundBegan = false;
		bRoundFinished = true;
		bFirstSpawned = false;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				iFrustration[i] = 0;
				
				bIsTank[i] = false;
				bFrustrated[i] = false;
			}
		}
	}
	LaunchMTParameters();
	
	return Plugin_Continue;
}

public Action OnTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!bMTOn)
	{
		return Plugin_Continue;
	}
	
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (!tank)
	{
		return Plugin_Continue;
	}
	
	if (!bIsTank[tank])
	{
		bIsTank[tank] = true;
		
		if (!bFirstSpawned && mMapStatus == view_as<MapStatus>(MS_FINALE))
		{
			bFirstSpawned = true;
			
			iFinaleWave += 1;
			LaunchMTParameters();
		}
		
		SetEntProp(tank, Prop_Send, "m_iHealth", iTankHP, 1);
		SetEntProp(tank, Prop_Send, "m_iMaxHealth", iTankHP, 1);
		
		if ((mMapStatus == view_as<MapStatus>(MS_ESCAPE)) ? bMTSameSpawn[2] : ((mMapStatus != view_as<MapStatus>(MS_FINALE)) ? bMTSameSpawn[1] : bMTSameSpawn[0]))
		{
			if (iTankCount <= 0)
			{
				GetEntPropVector(tank, Prop_Send, "m_vecOrigin", fTankPos);
			}
			else
			{
				TeleportEntity(tank, fTankPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
		
		iTankCount += 1;
		if (iTankCount < iMaxTankCount)
		{
			ChangeInfectedLimits(iMaxZombies + iMaxTankCount);
			CreateTimer((mMapStatus != view_as<MapStatus>(MS_ESCAPE)) ? fMTSpawnDelay[0] : fMTSpawnDelay[1], SpawnMoreTank);
		}
		else
		{
			ChangeInfectedLimits(iMaxZombies);
		}
		
		if (bMTAnnounce && mMapStatus != view_as<MapStatus>(MS_ROUNDEND))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (GetClientTeam(i) == 3)
					{
						if (IsFakeClient(tank))
						{
							PrintToChat(i, "\x04[MT]\x01 New Tank Spawning (%i HP) [AI]", iTankHP);
						}
						else
						{
							PrintToChat(i, "\x04[MT]\x01 New Tank Spawning (%i HP) [%N]", iTankHP, tank);
						}
					}
					else
					{
						PrintToChat(i, "\x04[MT]\x01 New Tank Spawning (%i HP)", iTankHP);
					}
				}
			}
		}
	}
	else
	{
		if (bFrustrated[tank])
		{
			bFrustrated[tank] = false;
		}
		SetEntProp(tank, Prop_Send, "m_iMaxHealth", iTankHP, 1);
	}
	
	if (!IsFakeClient(tank))
	{
		CreateTimer(10.0, CheckFrustration, GetClientUserId(tank));
	}
	
	if (bMTDisplay)
	{
		pMTList = new Panel();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == iTankClass && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated", 1))
			{
				char sText[128];
				if (IsPlayerBurning(i))
				{
					Format(sText, sizeof(sText), "%N: %i HP (FIRE)", i, GetEntProp(i, Prop_Send, "m_iHealth"));
				}
				else
				{
					Format(sText, sizeof(sText), "%N: %i HP, Control: %i％", i, GetEntProp(i, Prop_Send, "m_iHealth"), 100 - GetEntProp(i, Prop_Send, "m_frustration"));
				}
				pMTList.DrawText(sText);
			}
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) != 2 && !IsFakeClient(i))
			{
				pMTList.Send(i, MTListHandler, 1);
			}
		}
		delete pMTList;
	}
	
	return Plugin_Continue;
}

public Action SpawnMoreTank(Handle timer)
{
	if (!bMTOn || !bRoundBegan || bRoundFinished)
	{
		return Plugin_Stop;
	}
	
	int iCommandExecuter = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iCommandExecuter = i;
			break;
		}
	}
	if (iCommandExecuter == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				iCommandExecuter = i;
				break;
			}
		}
	}
	
	int iFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(iCommandExecuter, "z_spawn_old tank auto");
	SetCommandFlags("z_spawn_old", iFlags|FCVAR_CHEAT);
	
	return Plugin_Stop;
}

public Action CheckFrustration(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsTank(client) || !IsPlayerAlive(client) || IsFakeClient(client))
	{
		return Plugin_Stop;
	}
	
	int iFrustrationProgress = GetEntProp(client, Prop_Send, "m_frustration");
	if (iFrustrationProgress >= 95)
	{
		if (!IsPlayerBurning(client))
		{
			iFrustration[client] += 1;
			if (iFrustration[client] < 2)
			{
				SetEntProp(client, Prop_Send, "m_frustration", 0);
				CreateTimer(0.1, CheckFrustration, GetClientUserId(client));
				
				for (int i = 1; i <= MaxClients; i++)
				{	
					if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
					{
						PrintToChat(i, "\x04[MT]\x01 %N Lost First Tank Control!", client);
					}
				}
			}
		}
		else
		{
			CreateTimer(0.1, CheckFrustration, GetClientUserId(client));
		}
	}
	else
	{
		CreateTimer(0.1 + (95 - iFrustrationProgress) * 0.1, CheckFrustration, GetClientUserId(client));
	}
	return Plugin_Stop;
}

public int MTListHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		if (bMTDisplay)
		{
			pMTList = new Panel();
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == iTankClass && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated", 1))
				{
					char sText[128];
					if (IsPlayerBurning(i))
					{
						Format(sText, sizeof(sText), "%N: %i HP (FIRE)", i, GetEntProp(i, Prop_Send, "m_iHealth"));
					}
					else
					{
						Format(sText, sizeof(sText), "%N: %i HP, Control: %i％", i, GetEntProp(i, Prop_Send, "m_iHealth"), 100 - GetEntProp(i, Prop_Send, "m_frustration"));
					}
					pMTList.DrawText(sText);
				}
			}
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) != 2 && !IsFakeClient(i))
				{
					pMTList.Send(i, MTListHandler, 1);
				}
			}
			delete pMTList;
		}
	}
}

GameModeStatus GetGameModeInfo()
{
	char sGameMode[16];
	hGameMode.GetString(sGameMode, sizeof(sGameMode));
	if (StrEqual(sGameMode, "coop", false) || StrEqual(sGameMode, "realism", false))
	{
		return view_as<GameModeStatus>(GMS_COOP);
	}
	else if (StrEqual(sGameMode, "versus", false) || StrEqual(sGameMode, "teamversus", false))
	{
		return view_as<GameModeStatus>(GMS_VERSUS);
	}
	else if (StrEqual(sGameMode, "survival", false))
	{
		return view_as<GameModeStatus>(GMS_SURVIVAL);
	}
	else if (StrEqual(sGameMode, "scavenge", false) || StrEqual(sGameMode, "teamscavenge", false))
	{
		return view_as<GameModeStatus>(GMS_SCAVENGE);
	}
	else
	{
		return view_as<GameModeStatus>(GMS_UNKNOWN);
	}
}

void LaunchMTParameters()
{
	switch (view_as<int>(gmsGameMode))
	{
		case GMS_COOP:
		{
			switch (view_as<int>(mMapStatus))
			{
				case MS_REGULAR:
				{
					iTankHP = (L4D_IsMissionFinalMap()) ? iMTHealthCoop[1] : iMTHealthCoop[0];
					iMaxTankCount = (L4D_IsMissionFinalMap()) ? iMTCountCoop[1] : iMTCountCoop[0];
				}
				case MS_ROUNDEND: iMaxTankCount = 0;
			}
		}
		case GMS_VERSUS: 
		{
			switch (view_as<int>(mMapStatus))
			{
				case MS_REGULAR:
				{
					iTankHP = (L4D_IsMissionFinalMap()) ? iMTHealthVersus[1] : iMTHealthVersus[0]; 	
					iMaxTankCount = (L4D_IsMissionFinalMap()) ? iMTCountVersus[1] : iMTCountVersus[0];
				}
				case MS_FINALE:
				{
					iTankHP = (iFinaleWave == 2) ? iMTHealthVersus[3] : iMTHealthVersus[2];
					iMaxTankCount = (iFinaleWave == 2) ? iMTCountVersus[3] : iMTCountVersus[2];
				}
				case MS_ESCAPE:
				{
					iTankHP = iMTHealthVersus[4];
					iMaxTankCount = iMTCountVersus[4];
				}
				case MS_LEAVING: iMaxTankCount = 0;
				case MS_ROUNDEND: iMaxTankCount = 0;
			}
		}
		case GMS_SURVIVAL: 
		{
			iTankHP = iMTHealthSurvival;
			iMaxTankCount = iMTCountSurvival;
		}
		case GMS_SCAVENGE: 
		{
			iTankHP = iMTHealthScavenge;
			iMaxTankCount = iMTCountScavenge;
		}
		case GMS_UNKNOWN: 
		{
			iTankHP = 15000;
			iMaxTankCount = 1;
		}
	}
}

void ChangeInfectedLimits(int iValue)
{
	if (FindConVar("super_versus_version") == null)
	{
		FindConVar("z_max_player_zombies").SetInt(iValue, true, false);
	}
	else
	{
		int iFlags = FindConVar("super_versus_infected_limit").Flags;
		FindConVar("super_versus_infected_limit").Flags = iFlags & ~FCVAR_NOTIFY;
		FindConVar("super_versus_infected_limit").SetInt(iValue);
		FindConVar("super_versus_infected_limit").Flags = iFlags|FCVAR_NOTIFY;
	}
}

bool IsTank(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == iTankClass);
}

bool IsPlayerBurning(int client)
{
	float fBurning = GetEntDataFloat(client, FindSendPropInfo("CTerrorPlayer", "m_burnPercent"));
	return (fBurning > 0.0) ? true : false;
}

