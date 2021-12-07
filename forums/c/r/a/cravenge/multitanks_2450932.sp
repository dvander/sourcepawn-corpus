#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define CONSISTENCY_CHECK 1.0
#define PLUGIN_VERSION "1.8"
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY

#define GM_UNKNOWN 0
#define GM_COOP 1
#define GM_VERSUS 2
#define GM_SURVIVAL 3
#define GM_SCAVENGE 4

#define MS_UNKNOWN 0
#define MS_ROUNDSTART 1
#define MS_FINAL 2
#define MS_ESCAPE 3
#define MS_LEAVING 4
#define MS_ROUNDEND 5

new TanksSpawned = 0;
new TanksToSpawn = 0;
new TanksMustSpawned = 0;
new TanksFrustrated = 0;
new DefaultMaxZombies = 0;

new bool:g_IsFinalMap;
new g_GameMode;
new g_MTHealth;
new g_MTCount;
new g_MapState;
new g_Wave;
new g_Multiply;
new Float:g_FirstTankPos[3];

new propinfoburn = - 1;

new Handle:CurrentGameMode = INVALID_HANDLE;

new Handle:MTOn = INVALID_HANDLE;

new Handle:MTCountRegularCoop = INVALID_HANDLE;
new Handle:MTHealthRegularCoop = INVALID_HANDLE;
new Handle:MTHealthFinaleCoop = INVALID_HANDLE;
new Handle:MTCountFinaleCoop = INVALID_HANDLE;

new Handle:MTHealthRegularVersus = INVALID_HANDLE;
new Handle:MTCountRegularVersus	= INVALID_HANDLE;
new Handle:MTHealthFinaleVersus	= INVALID_HANDLE;
new Handle:MTCountFinaleVersus	= INVALID_HANDLE;
new Handle:MTHealthFinaleStartVersus = INVALID_HANDLE;
new Handle:MTCountFinaleStartVersus	= INVALID_HANDLE;
new Handle:MTHealthFinaleStart2Versus = INVALID_HANDLE;
new Handle:MTCountFinaleStart2Versus = INVALID_HANDLE;
new Handle:MTHealthEscapeStartVersus = INVALID_HANDLE;
new Handle:MTCountEscapeStartVersus	= INVALID_HANDLE;

new Handle:MTHealthSurvival	= INVALID_HANDLE;
new Handle:MTCountSurvival = INVALID_HANDLE;

new Handle:MTHealthScavenge	= INVALID_HANDLE;
new Handle:MTCountScavenge = INVALID_HANDLE;

new Handle:AnnounceTankHP = INVALID_HANDLE;
new Handle:MTSpawnTogether = INVALID_HANDLE;
new Handle:MTSpawnTogetherFinal	= INVALID_HANDLE;
new Handle:MTSpawnTogetherEscape = INVALID_HANDLE;
new Handle:MTSpawnDelay	= INVALID_HANDLE;
new Handle:MTSpawnCheck	= INVALID_HANDLE;
new Handle:MTSpawnDelayEscape = INVALID_HANDLE;

new Handle:SpawnTimer = INVALID_HANDLE;
new Handle:CheckTimer = INVALID_HANDLE;

new Handle:MTShowHUD = INVALID_HANDLE;

new bool:IsTank[MAXPLAYERS+1];
new bool:IsFrustrated[MAXPLAYERS+1];
new Frustrates[MAXPLAYERS+1];
new bool:IsRoundStarted;
new bool:IsRoundEnded;

static const L4D_ZOMBIECLASS_TANK = 5;
static const L4D2_ZOMBIECLASS_TANK = 8;

new ZC_TANK;

new infectedClass[MAXPLAYERS+1];
new bool:resetGhostState[MAXPLAYERS+1];
new bool:resetIsAlive[MAXPLAYERS+1];
new bool:resetLifeState[MAXPLAYERS+1];
new bool:restoreStatus[MAXPLAYERS+1];

new Float:HUD_UPDATE_INTERVAL = 1.0;
new Handle:g_hHUD = INVALID_HANDLE;
new Handle:HUDTimer = INVALID_HANDLE;

public bool:isSuperVersus()
{
	if (FindConVar("super_versus_version") != INVALID_HANDLE)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Plugin:myinfo =
{
	name = "Multitanks",
	author = "Red Alex, cravenge",
	description = "Spawns Multiple Tanks.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=101781"
};

public OnPluginStart()
{
	LoadTranslations("l4dmultitanks.phrases");
	
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrEqual(game, "left4dead2", false))
	{
		ZC_TANK = L4D2_ZOMBIECLASS_TANK;
	}
	else
	{
		ZC_TANK = L4D_ZOMBIECLASS_TANK;
	}
	
	RegAdminCmd("sm_mt_refresh", Command_RefreshSettings, ADMFLAG_GENERIC, "Refreshes Settings");
	RegAdminCmd("sm_mt_spawnbot", Command_MTSpawnBot, ADMFLAG_GENERIC, "Spawns Tank Bot");
	
	propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");
	
	HookEvent("tank_spawn", OnTankSpawn);
	HookEvent("tank_frustrated", OnTankFrustrated);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	
	HookEvent("finale_start", OnFinaleStart);
	HookEvent("finale_escape_start", OnFinaleEscapeStart);
	HookEvent("finale_vehicle_leaving", OnFinaleVehicleLeaving);
	
	MTOn = CreateConVar("multitanks_enabled", "1", "Enable/Disable Plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	CreateConVar("multitanks_version", PLUGIN_VERSION, "Multitanks Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	MTHealthRegularCoop = CreateConVar("multitanks_health_regular_coop", "30000.0", "Health Tanks Given In Coop", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountRegularCoop = CreateConVar("multitanks_count_regular_coop", "1", "Count Of Tanks In Coop", CVAR_FLAGS, true, 1.0, true, 6.0);
	MTHealthFinaleCoop = CreateConVar("multitanks_health_finale_coop", "32500.0", "Health Tanks Given In Coop Finales", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountFinaleCoop = CreateConVar("multitanks_count_finale_coop", "1", "Count Of Tanks In Coop Finales", CVAR_FLAGS, true, 1.0, true, 6.0);

	MTHealthRegularVersus = CreateConVar("multitanks_health_regular_versus", "27500.0", "Health Tanks Given In Versus", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountRegularVersus = CreateConVar("multitanks_count_regular_versus", "2", "Count Of Tanks In Versus", CVAR_FLAGS, true, 1.0, true, 6.0);
	MTHealthFinaleVersus = CreateConVar("multitanks_health_finale_versus", "30000.0", "Health Tanks Given In Versus Finales", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountFinaleVersus = CreateConVar("multitanks_count_finale_versus", "2", "Count Of Tanks In Versus Finales", CVAR_FLAGS, true, 1.0, true, 6.0);
	MTHealthFinaleStartVersus = CreateConVar("multitanks_health_firstwave_versus", "35000.0", "Health Tanks Given In Finale Wave 1", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountFinaleStartVersus = CreateConVar("multitanks_count_firstwave_versus", "2", "Count Of Tanks In Finale Wave 1", CVAR_FLAGS, true, 1.0, true, 6.0);
	MTHealthFinaleStart2Versus = CreateConVar("multitanks_health_secondwave_versus", "37500.0", "Health Tanks Given In Finale Wave 2", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountFinaleStart2Versus = CreateConVar("multitanks_count_secondwave_versus", "2", "Count Of Tanks In Finale Wave 2", CVAR_FLAGS, true, 1.0, true, 6.0);
	MTHealthEscapeStartVersus = CreateConVar("multitanks_health_escape_versus", "32500.0", "Health Tanks Given In Escapes", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountEscapeStartVersus = CreateConVar("multitanks_count_escape_versus", "2", "Count Of Tanks In Escapes", CVAR_FLAGS, true, 1.0, true, 6.0);
	
	MTHealthSurvival = CreateConVar("multitanks_health_survival", "17000.0", "Health Tanks Given In Survival", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountSurvival = CreateConVar("multitanks_count_survival", "2", "Count Of Tanks In Survival", CVAR_FLAGS, true, 1.0, true, 6.0);
	
	MTHealthScavenge = CreateConVar("multitanks_health_scavenge", "19500.0", "Health Tanks Given In Scavenge", CVAR_FLAGS, true, 0.0, true, 65535.0);
	MTCountScavenge = CreateConVar("multitanks_count_scavenge", "2", "Count Of Tanks In Scavenge", CVAR_FLAGS, true, 1.0, true, 6.0);
	
	AnnounceTankHP = CreateConVar("multitanks_announcehp", "1", "Enable/Disable HP Announcements", CVAR_FLAGS, true, 0.0, true, 1.0);
	MTSpawnTogether = CreateConVar("multitanks_spawntogether", "1", "Enable/Disable Same Tank Spawn Spot", CVAR_FLAGS, true, 0.0, true, 1.0);
	MTSpawnTogetherFinal = CreateConVar("multitanks_spawntogether_final", "1", "Enable/Disable Same Tank Spawn Spot In Finales", CVAR_FLAGS, true, 0.0, true, 1.0);
	MTSpawnTogetherEscape = CreateConVar("multitanks_spawntogether_escape", "1", "Enable/Disable Same Tank Spawn Spot During Escape", CVAR_FLAGS, true, 0.0, true, 1.0);
	MTSpawnDelay = CreateConVar("multitanks_spawndelay", "20.0", "Delay Between Tank Spawns", CVAR_FLAGS, true, 0.1, true, 60.0);
	MTSpawnDelayEscape = CreateConVar("multitanks_spawndelay_escape", "20.0", "Delay Between Tank Spawns During Escape", CVAR_FLAGS, true, 0.1, true, 60.0);
	MTSpawnCheck = CreateConVar("multitanks_spawncheck", "20.0", "Time To Check If All Tanks Spawned", CVAR_FLAGS, true, 1.0, true, 20.0);
	MTShowHUD = CreateConVar("multitanks_showhud", "0", "Enable/Disable HUD", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	CurrentGameMode = FindConVar("mp_gamemode");
	HookConVarChange(CurrentGameMode, OnCVGameModeChange);
	
	AutoExecConfig(true, "multitanks");
	
	CreateTimer(1.0, MapStart);
}

public Action:OnTankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.2, TankSpawn, GetEventInt(event, "userid"));
}

public Action:TankSpawn(Handle:timer, any:userid) 
{
	if (!GetConVarInt(MTOn))
	{
		return Plugin_Stop;
	}
	
	new client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return Plugin_Stop;
	}
	
	new bool:isNew = true;
	new bool:isTankClient = false;
	
	new TotalCount = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{	
		isTankClient = false;
		if (IsClientInGame(i) && IsPlayerTank(i) && IsPlayerAlive(i))
		{
			isTankClient = true;
			TotalCount++;
		}
		
		if (IsTank[i] && !isTankClient)
		{
			IsTank[i] = false;
			IsFrustrated[i] = false;
			isNew = false;
		}
		else if (g_GameMode != 2 && i != client && !IsTank[i] && isTankClient)
		{
			g_Multiply++;
		}
	}
	
	if (g_Multiply == 1)
	{
		return Plugin_Stop;
	}
	
	if (!IsFakeClient(client))
	{
		CreateTimer(10.0, CheckFrustration, client);
	}
	
	Frustrates[client] = 0;
	if (!IsTank[client])
	{
		IsTank[client] = true;
		if (isNew)
		{
			SetTankHP(client);
			
			TanksSpawned++;
			TanksMustSpawned--;
			
			if (TanksSpawned == 1)
			{		
				if ((HUDTimer == INVALID_HANDLE) && GetConVarInt(MTShowHUD))
				{
					HUDTimer = CreateTimer(HUD_UPDATE_INTERVAL, HUD_Timer, _, TIMER_REPEAT);
				}
				
				if (g_MapState == 2)
				{
					g_Wave++;
					CalculateTanksParamaters();
				}
				
				GetEntPropVector(client, Prop_Data, "m_vecOrigin", g_FirstTankPos);
				
				SaveAndInreaseMaxZombies(g_MTCount);
				TanksMustSpawned = 0;
				TanksToSpawn = g_MTCount - 1;
				SpawnTimer = CreateTimer(((g_MapState == 3) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);
			}
			else
			{
				if ((g_MapState == 2) ? GetConVarInt(MTSpawnTogetherFinal) : (g_MapState == 3) ? GetConVarInt(MTSpawnTogetherEscape) : GetConVarInt(MTSpawnTogether))
				{
					SetEntPropVector(client, Prop_Data, "m_vecOrigin", g_FirstTankPos);
				}
			}
			
			if (TanksSpawned == g_MTCount)
			{
				g_Multiply = 0;
				TanksSpawned = 0;
				TanksMustSpawned = 0;
				
				if (SpawnTimer != INVALID_HANDLE)
				{
					KillTimer(SpawnTimer);
					SpawnTimer = INVALID_HANDLE;
				}
				
				if (CheckTimer != INVALID_HANDLE)
				{
					KillTimer(CheckTimer);
					CheckTimer = INVALID_HANDLE;
				}
				
				RestoreMaxZombies();
			}
		}
		else
		{
			TanksFrustrated--;
			if (!IsFakeClient(client))
			{
				SetTankMaximumHP(client);
			}
		}
	}
	else
	{
		IsTank[client] = false;
	}
	
	return Plugin_Stop;
}

public Action:OnTankFrustrated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerTank(client))
	{
		return;
	}
	
	IsFrustrated[client] = true;
	TanksFrustrated++;
	
	decl String:PlayerName[200];
	GetClientName(client, PlayerName, sizeof(PlayerName));
	
	for (new i=1; i<=MaxClients; i++)
	{	
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
		{
			PrintToChat(i, "\x04[MT]\x01 %s %t", PlayerName, "Lost Tank Control");
		}
	}	
}

public CalculateTanksParamaters()
{
	switch (g_GameMode)
	{
		case GM_COOP:
		{
			switch (g_MapState)
			{
				case MS_ROUNDSTART:
				{
					g_MTHealth = g_IsFinalMap ? GetConVarInt(MTHealthFinaleCoop) : GetConVarInt(MTHealthRegularCoop); 	
					g_MTCount = g_IsFinalMap ? GetConVarInt(MTCountFinaleCoop) : GetConVarInt(MTCountRegularCoop); 	
				}
				case MS_LEAVING: g_MTCount = 0;
				case MS_ROUNDEND: g_MTCount = 0;
			}
		}
		case GM_VERSUS: 
		{
			switch (g_MapState)
			{
				case MS_ROUNDSTART:
				{
					g_MTHealth = g_IsFinalMap ? GetConVarInt(MTHealthFinaleVersus) : GetConVarInt(MTHealthRegularVersus); 	
					g_MTCount = g_IsFinalMap ? GetConVarInt(MTCountFinaleVersus) : GetConVarInt(MTCountRegularVersus); 	
				}
				case MS_FINAL:
				{
					g_MTHealth = (g_Wave == 2) ? GetConVarInt(MTHealthFinaleStart2Versus) : GetConVarInt(MTHealthFinaleStartVersus);
					g_MTCount =  (g_Wave == 2) ? GetConVarInt(MTCountFinaleStart2Versus) : GetConVarInt(MTCountFinaleStartVersus);
				}
				case MS_ESCAPE:
				{
					g_MTHealth = GetConVarInt(MTHealthEscapeStartVersus);
					g_MTCount = GetConVarInt(MTCountEscapeStartVersus);
				}
				case MS_LEAVING: g_MTCount = 0;
				case MS_ROUNDEND: g_MTCount = 0;
			}
		}
		case GM_SURVIVAL: 
		{
			g_MTHealth = GetConVarInt(MTHealthSurvival);
			g_MTCount = GetConVarInt(MTCountSurvival);
		}
		case GM_SCAVENGE: 
		{
			g_MTHealth = GetConVarInt(MTHealthScavenge);
			g_MTCount = GetConVarInt(MTCountScavenge);
		}
		case GM_UNKNOWN: 
		{
			g_MTHealth = 6000;
			g_MTCount = 1;
		}
	}
}

public Action:MapStart(Handle:timer)
{
	OnMapStart();
	return Plugin_Stop;
}

public OnMapStart()
{
	g_GameMode = l4d_gamemode();
	g_IsFinalMap = (IsFinalMap() || AreFaultyMaps());	
	CalculateTanksParamaters();
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_MapState = MS_ROUNDSTART;
	CalculateTanksParamaters();
	
	TanksSpawned = 0;
	TanksFrustrated = 0;
	TanksMustSpawned = 0;
	TanksToSpawn = 0;
	IsRoundStarted = true;
	IsRoundEnded = false;
	
	if (CheckTimer != INVALID_HANDLE)
	{
		KillTimer(CheckTimer);
		CheckTimer = INVALID_HANDLE;
	}
	
	if (SpawnTimer != INVALID_HANDLE)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
	}
	
	for (new i=1; i <= MaxClients; i++)
	{
 		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			IsTank[i] = false;
			IsFrustrated[i] = false;
		}
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_MapState = MS_ROUNDEND;
	CalculateTanksParamaters();
	
	if (TanksMustSpawned > 0)
	{
		RestoreMaxZombies();
	}
	
	TanksSpawned = 0;
	TanksFrustrated = 0;
	TanksMustSpawned = 0;
	TanksToSpawn = 0;
	IsRoundStarted = false;
	IsRoundEnded = true;
	
	if (CheckTimer != INVALID_HANDLE)
	{
		KillTimer(CheckTimer);
		CheckTimer = INVALID_HANDLE;
	}
	
	if (SpawnTimer != INVALID_HANDLE)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
	}
	
	for (new i=1; i <= MaxClients; i++)
	{
 		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			IsTank[i] = false;
			IsFrustrated[i] = false;
		}
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	if (IsPlayerTank(client))
	{
		if (IsFrustrated[client])
		{
			TanksFrustrated--;
			IsFrustrated[client] = false;
			IsTank[client] = false;
		}
		else if (!IsTank[client])
		{
			IsTank[client] = true;
		}
		else
		{
			TankDie(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:TankDie(any:client)
{
	IsTank[client] = false;
}

public Action:SetTankHP(any:client) 
{
	if (!GetConVarInt(MTOn))
	{
		return;
	}
	
	if (!IsClientInGame(client))
	{
		return;
	}
	
	new TankHP = g_MTHealth;
	if (TankHP > 65535)
	{
		TankHP = 65535;
	}
	
	if (GetConVarInt(AnnounceTankHP))
	{
		decl String:PlayerName[200];
		GetClientName(client, PlayerName, sizeof(PlayerName));
		
		for (new i=1; i<=MaxClients; i++)
		{	
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (GetClientTeam(i) == 3)
				{
					if (IsFakeClient(client))
					{
						PrintToChat(i, "\x04[MT]\x01 %t (%d HP) [%t]", "New Tank Spawning", TankHP, "Bot");
					}
					else
					{
						PrintToChat(i, "\x04[MT]\x01 %t (%d HP) [%s]", "New Tank Spawning", TankHP, PlayerName);
					}
				}
				else
				{
					PrintToChat(i, "\x04[MT]\x01 %t (%d HP)", "New Tank Spawning", TankHP);
				}
			}
		}
	}
	
	SetEntProp(client, Prop_Send, "m_iHealth", TankHP);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", TankHP);
}

public Action:SetTankMaximumHP(any:client) 
{
	if (!GetConVarInt(MTOn))
	{
		return;
	}
	
	if (!IsClientConnected(client) || !IsClientInGame(client))
	{
		return;
	}
	
	new TankHP = g_MTHealth;
	if (TankHP > 65535)
	{
		TankHP = 65535;
	}
	
	SetEntProp(client, Prop_Send, "m_iMaxHealth", TankHP);
}

public Action:SpawnAdditionalTank(Handle:timer, any:client)
{
	SpawnTimer = INVALID_HANDLE;
	
	if (!GetConVarInt(MTOn) || !IsRoundStarted || IsRoundEnded || TanksToSpawn <= 0)
	{
		return Plugin_Stop;
	}
	
	TanksToSpawn--;
	TanksMustSpawned++;

	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == 0)
	{
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			return Plugin_Stop;
		}
		
		temp = true;
	}

	new String:command[] = "z_spawn_old";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(anyclient, "%s %s", command, "tank auto");
	SetCommandFlags(command, flags);
	
	if (temp)
	{
		CreateTimer(0.1, kickbot, anyclient);
	}
	
	if (TanksToSpawn == 0)
	{
		CheckTimer = CreateTimer(GetConVarFloat(MTSpawnCheck), CheckAdditionalTanks, client);
	}
	else
	{
		SpawnTimer = CreateTimer(((g_MapState == MS_ESCAPE) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);
	}
	
	return Plugin_Stop;
}

public Action:CheckAdditionalTanks(Handle:timer, any:client)
{
	CheckTimer = INVALID_HANDLE;
	
	if (!GetConVarInt(MTOn) || !IsRoundStarted || IsRoundEnded)
	{
		return Plugin_Stop;
	}
	
	if (TanksMustSpawned > 0)
	{
		TanksToSpawn = TanksMustSpawned;
		TanksMustSpawned = 0;
		SpawnTimer = CreateTimer(((g_MapState == MS_ESCAPE) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);
	}
	else
	{
		new bool:isTankClient = false, TanksDissapears = 0;
		
		for (new i=1; i<=MaxClients; i++)
		{	
			isTankClient = false;
			if (IsClientInGame(i) && IsPlayerTank(i) && IsPlayerAlive(i))
			{
				isTankClient = true;
			}
			
			if (IsTank[i] && !isTankClient)
			{	
				TanksSpawned--;
				TanksDissapears++;
			}
		}
		if (TanksDissapears != 0)
		{
			PrintToChatAll("\x04[MT]\x01 Tank%s Magically Disappeared! Spawning %s Again!", (TanksDissapears > 1) ? "s" : "", (TanksDissapears > 1) ? "Them" : "It");
			
			SaveAndInreaseMaxZombies(TanksDissapears);
			TanksToSpawn = TanksDissapears;
			TanksMustSpawned = 0;
			SpawnTimer = CreateTimer(((g_MapState == MS_ESCAPE) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);
		}
	}
	
	return Plugin_Stop;
}

public SaveAndInreaseMaxZombies(number)
{
	if (isSuperVersus())
	{
		DefaultMaxZombies = GetConVarInt(FindConVar("super_versus_infected_limit"));
		UnsetNotifytVar(FindConVar("super_versus_infected_limit"));
		SetConVarInt(FindConVar("super_versus_infected_limit"), DefaultMaxZombies + number);
		SetNotifytVar(FindConVar("super_versus_infected_limit"));
	}
	else
	{
		DefaultMaxZombies = GetConVarInt(FindConVar("z_max_player_zombies"));
		SetConVarInt(FindConVar("z_max_player_zombies"), DefaultMaxZombies + number);
	}
}

public RestoreMaxZombies()
{
	if (isSuperVersus())
	{
		UnsetNotifytVar(FindConVar("super_versus_infected_limit"));
		SetConVarInt(FindConVar("super_versus_infected_limit"), DefaultMaxZombies);
		SetNotifytVar(FindConVar("super_versus_infected_limit"));
	}
	else
	{
		SetConVarInt(FindConVar("z_max_player_zombies"), DefaultMaxZombies);
	}
}

public UnsetNotifytVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(hndl, flags);
}
 
public SetNotifytVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(hndl, flags);
}

GetAnyClient()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			return i;
		}
	}
	return 0;
}

public Action:kickbot(Handle:timer, any:value)
{
	KickThis(value);
	return Plugin_Stop;
}

KickThis(client)
{
	if (IsClientConnected(client) && (!IsClientInKickQueue(client)))
	{
		KickClient(client, "Fake Tank!");
	}
}

public OnCVGameModeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
	{
		g_GameMode = l4d_gamemode();
		CalculateTanksParamaters();
	}
}

public Action:OnFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_GameMode != GM_VERSUS)
	{
		g_MapState = MS_ROUNDEND;
		
		if (TanksMustSpawned > 0)
		{
			RestoreMaxZombies();
		}
		
		TanksSpawned = 0;
		TanksFrustrated = 0;
		TanksMustSpawned = 0;
		TanksToSpawn = 0;
		IsRoundStarted = false;
		IsRoundEnded = true;
		
		if (CheckTimer != INVALID_HANDLE)
		{
			KillTimer(CheckTimer);
			CheckTimer = INVALID_HANDLE;
		}
		
		if (SpawnTimer != INVALID_HANDLE)
		{
			KillTimer(SpawnTimer);
			SpawnTimer = INVALID_HANDLE;
		}
		
		for (new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3)
			{
				IsTank[i] = false;
				IsFrustrated[i] = false;
			}
		}
	}
	else
	{
		g_MapState = MS_FINAL;
		g_Wave = 0;
	}
	CalculateTanksParamaters();	
}

public Action:OnFinaleEscapeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_GameMode != GM_VERSUS)
	{
		g_MapState = MS_ROUNDEND;
		
		if (TanksMustSpawned > 0)
		{
			RestoreMaxZombies();
		}
		
		TanksSpawned = 0;
		TanksFrustrated = 0;
		TanksMustSpawned = 0;
		TanksToSpawn = 0;
		IsRoundStarted = false;
		IsRoundEnded = true;
		
		if (CheckTimer != INVALID_HANDLE)
		{
			KillTimer(CheckTimer);
			CheckTimer = INVALID_HANDLE;
		}
		
		if (SpawnTimer != INVALID_HANDLE)
		{
			KillTimer(SpawnTimer);
			SpawnTimer = INVALID_HANDLE;
		}
		
		for (new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3)
			{
				IsTank[i] = false;
				IsFrustrated[i] = false;
			}
		}
	}
	else
	{
		g_MapState = MS_ESCAPE;
	}
	CalculateTanksParamaters();
}

public Action:OnFinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_GameMode != GM_VERSUS)
	{
		g_MapState = MS_ROUNDEND;
		
		if (TanksMustSpawned > 0)
		{
			RestoreMaxZombies();
		}
		
		TanksSpawned = 0;
		TanksFrustrated = 0;
		TanksMustSpawned = 0;
		TanksToSpawn = 0;
		IsRoundStarted = false;
		IsRoundEnded = true;
		
		if (CheckTimer != INVALID_HANDLE)
		{
			KillTimer(CheckTimer);
			CheckTimer = INVALID_HANDLE;
		}
		
		if (SpawnTimer != INVALID_HANDLE)
		{
			KillTimer(SpawnTimer);
			SpawnTimer = INVALID_HANDLE;
		}
		
		for (new i=1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3)
			{
				IsTank[i] = false;
				IsFrustrated[i] = false;
			}
		}
	}
	else
	{
		g_MapState = MS_LEAVING;
	}
	CalculateTanksParamaters();
}

l4d_gamemode()
{
	decl String:gmode[32];
	GetConVarString(FindConVar("mp_gamemode"), gmode, sizeof(gmode));
	if (StrEqual(gmode, "coop", false) || StrEqual(gmode, "realism", false))
	{
		return GM_COOP;
	}
	else if (StrEqual(gmode, "versus", false) || StrEqual(gmode, "teamversus", false))
	{
		return GM_VERSUS;
	}
	else if (StrEqual(gmode, "survival", false))
	{
		return GM_SURVIVAL;
	}
	else if (StrEqual(gmode, "scavenge", false) || StrEqual(gmode, "teamscavenge", false))
	{
		return GM_SCAVENGE;
	}
	else
	{
		return GM_UNKNOWN;
	}
}

bool:IsFinalMap()
{
	new entitycount = GetEntityCount();
	decl String:entname[50];
	
	for (new i = 1; i < entitycount; i++)
	{
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		GetEdictClassname(i, entname, sizeof(entname));
		if (StrContains(entname, "trigger_finale") > -1)
		{
			return true;
		}
	}

	return false;	
}

bool:AreFaultyMaps()
{
	decl String:currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	if ((StrEqual(currentMap, "c4m5_milltown_escape", false)) || (StrEqual(currentMap, "c5m5_bridge", false)) || (StrEqual(currentMap, "c13m4_cutthroatcreek", false)))
	{
		return true;
	}
	return false;
}

public Action:Command_RefreshSettings(client, args)
{
	CalculateTanksParamaters();
	ReplyToCommand(client, "[MT] Settings Refreshed!");
	
	return Plugin_Handled;
}

public Action:Command_MTSpawnBot(client, args)
{
	for (new i=1; i<=MaxClients; i++)
	{
		restoreStatus[i] = false;
		
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i)) 
		{
			restoreStatus[i] = true;
			infectedClass[i] = GetEntProp(i, Prop_Send, "m_zombieClass");
			
			SetEntProp(i, Prop_Send, "m_zombieClass", ZC_TANK);
			
			if (IsPlayerGhost(i))
			{
				resetGhostState[i] = true;
				SetPlayerGhostStatus(i, false);
				resetIsAlive[i] = true;
				SetPlayerIsAlive(i, true);
			}
			else if (!IsPlayerAlive(i))
			{
				resetLifeState[i] = true;
				SetPlayerLifeState(i, false);
			}
		}
	}
	
	new flags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn_old tank");
	SetCommandFlags("z_spawn_old", flags);
	
	CreateTimer(0.1, RevertPlayerStatus);
	return Plugin_Handled;
}

public Action:RevertPlayerStatus(Handle:timer)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i) && restoreStatus[i]) 
		{
			if (resetGhostState[i])
			{
				SetPlayerGhostStatus(i, true);
			}
			
			if (resetIsAlive[i])
			{
				SetPlayerIsAlive(i, false);
			}
			
			if (resetLifeState[i])
			{
				SetPlayerLifeState(i, true);
			}
			
			SetEntProp(i, Prop_Send, "m_zombieClass", infectedClass[i]);
		}
	}
	
	return Plugin_Stop;
}

public Action:CheckFrustration(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerTank(client) || !IsPlayerAlive(client) || IsFakeClient(client))
	{
		return Plugin_Stop;
	}
	
	new frustration = GetEntProp(client, Prop_Send, "m_frustration");
	if (frustration >= 95) 
	{
		if (!IsPlayerBurning(client))
		{
			Frustrates[client]++;
			
			decl String:PlayerName[200];
			GetClientName(client, PlayerName, sizeof(PlayerName));
			for (new i=1; i<=MaxClients; i++)
			{	
				if (IsClientInGame(i) && IsPlayerTank(i) && !IsFakeClient(i))
				{
					if (Frustrates[client] >= 2)
					{
						PrintToChat(i, "\x04[MT]\x01 %s %t", PlayerName, "Lost Tank Control");
					}
					else
					{
						PrintToChat(i, "\x04[MT]\x01 %s %t", PlayerName, "Lost First Tank Control");
					} 
				}
			}
			if (Frustrates[client] >= 2)
			{
				ChangeClientTeam(client, 1); 
				CreateTimer(0.1, RestoreInfectedTeam, client);
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_frustration", 0);
				CreateTimer(0.1, CheckFrustration, client);
			}
		}
		else
		{
			CreateTimer(0.1, CheckFrustration, client);
		}
	}
	else
	{
		CreateTimer(0.1 + (95 - frustration) * 0.1, CheckFrustration, client);
	}
	
	return Plugin_Stop;
}

public Action:RestoreInfectedTeam(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
 	FakeClientCommand(client, "jointeam 3");
	return Plugin_Stop;
}

stock SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive)
	{
		SetEntData(client, offset, 1, 1, true);
	}
	else
	{
		SetEntData(client, offset, 0, 1, true);
	}
}

stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1))
	{
		return true;
	}
	return false;
}

stock SetPlayerGhostStatus(client, bool:ghost)
{
	if(ghost)
	{	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

stock SetPlayerLifeState(client, bool:ready)
{
	if (ready)
	{
		SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
	}
}

stock bool:IsPlayerTank(client)
{
	return (GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK);
}

bool:IsPlayerBurning(client)
{
	new Float:isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning > 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Action:HUD_Timer(Handle:timer)
{
	HUD_Draw();
	for (new i=1; i<=MaxClients; i++)
	{	
		if (IsClientInGame(i) && GetClientTeam(i) != 2 && !IsFakeClient(i))
		{
			SendPanelToClient(g_hHUD, i, HUD_Handler, 1);
		}
	}
	
	return Plugin_Continue;
}

public HUD_Handler(Handle:menu, MenuAction:action, param1, param2) 
{
}

HUD_Draw()
{
	if (g_hHUD != INVALID_HANDLE)
	{
		CloseHandle(g_hHUD);
	}
	
	g_hHUD = CreatePanel();
	
	decl String:PlayerName[200];
	
	new TotalCount = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{	
		if (IsClientInGame(i) && IsPlayerTank(i) && IsPlayerAlive(i) && !IsPlayerIncapped(i))
		{
			TotalCount++;
			
			GetClientName(i, PlayerName, sizeof(PlayerName));
			
			new frustration = 100 - GetEntProp(i, Prop_Send, "m_frustration");
			new health = GetEntData(i, FindDataMapOffs(i, "m_iHealth"));
			
			decl String:tBuffer[512];
			if (IsPlayerBurning(i)) 
			{
				Format(tBuffer, sizeof(tBuffer), "%s: %d HP (FIRE)", PlayerName, health);
			}
			else
			{
				Format(tBuffer, sizeof(tBuffer), "%s: %d HP, Control: %d％", PlayerName, health, frustration);
			}
			DrawPanelText(g_hHUD, tBuffer);
		}
	}


	if (TotalCount == 0)
	{
		if (HUDTimer != INVALID_HANDLE)
		{
			KillTimer(HUDTimer);
			HUDTimer = INVALID_HANDLE;
		}
	}
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	else
	{
		return false;
	}
}

