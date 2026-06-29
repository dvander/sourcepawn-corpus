#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

static Handle:g_hSf, Handle:g_hBebop, Handle:g_hSurvivor, Handle:g_hTimer, Handle:g_hItems, Handle:g_hGameMode, 
	Handle:g_hDef, Handle:g_hModel, Handle:g_hxTimer,
	
	bool:bBlock[5], bool:bMapChange,  
	
	bool:g_bCvarSf, g_iCvarMin, g_iCvarMax, g_iCvarItems, bool:g_bCvarDef, Float:g_fCvarTimer, Float:g_fCvarXTimer,
	
	afk[MAXPLAYERS+1], loading[MAXPLAYERS+1], ID[MAXPLAYERS+1], Handle:hzTimer[MAXPLAYERS+1], 
	String:sModel[64][MAXPLAYERS+1], iData[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Sappy Fix",
	author = "raziEiL [disawar1]",
	description = "Fixes Various Bugs..",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
};

public OnPluginStart()
{
	CreateConVar("sappy_fix_version", PLUGIN_VERSION, "Sappy Bug Fix Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hSf =	CreateConVar("sappy_fix_sacrifice", "1", "Enable/Disable Sacrifice Survival Mode Fixes", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hBebop = CreateConVar("sappy_fix_bebop", "8", "Minimum Amount Of Survivors", FCVAR_NOTIFY);
	g_hSurvivor	= CreateConVar("sappy_fix_extrabots", "8", "Maximum Amount Of Survivors", FCVAR_NOTIFY);
	g_hTimer = CreateConVar("sappy_fix_timer", "5", "Time Before Limit Checking Starts", FCVAR_NOTIFY);
	g_hItems = CreateConVar("sappy_fix_dropitems", "1", "Enable/Disable Item Spamming Fix", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hDef = CreateConVar("sappy_fix_defibrillator", "1", "Enable/Disable Defibrillator Bug Fixes", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hModel =	CreateConVar("sappy_fix_models", "1", "Time Interval Between Each Models Fixes", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	AutoExecConfig(true, "sappy_fix");
	
	g_hGameMode	= FindConVar("mp_gamemode");
	
	HookConVarChange(g_hSf, OnCVarChange);
	HookConVarChange(g_hBebop, OnCVarChange);
	HookConVarChange(g_hSurvivor, OnCVarChange);
	HookConVarChange(g_hTimer, OnCVarChange);
	HookConVarChange(g_hItems, OnCVarChange);
	HookConVarChange(g_hDef, OnCVarChange);
	HookConVarChange(g_hModel, OnCVarChange);
}

public OnMapStart()
{
	if (g_bCvarSf && IsSurvivalMode())
	{
		ValidMap();
	}
	
	if (g_fCvarXTimer > 0)
	{
		bMapChange = false;
		RemoveClientModel();
	}
	
	if (g_bCvarDef)
	{
		GhostStatusToFalse();
	}
}

public Action:OnMapTranslition(Handle:event, String:Onname[], bool:dontBroadcast)
{
	bMapChange = true;
}

public Action:SaveEntityModel(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			iData[i] = GetEntProp(i, Prop_Send, "m_survivorCharacter");	
			GetClientModel(i, sModel[i], sizeof(sModel));
		}
	}
}

public Action:Triger(Handle:timer, any:client)
{
	ChangeEntityModel(client, client);
}

ChangeEntityModel(client, fake)
{	
	if (IsClientInGame(client) && IsClientInGame(fake) && !StrEqual(sModel[client], ""))
	{
		SetEntProp(fake, Prop_Send, "m_survivorCharacter", iData[client]);
		SetEntityModel(fake, sModel[client]);
	}
}

bool:IsSurvivalMode()
{
	decl String:mode[24];
	GetConVarString(g_hGameMode, mode, sizeof(mode));
	
	if (strcmp(mode, "survival") == 0)
	{
		return true;
	}
	return false;
}

ValidMap()
{
	decl String:map[5];
	GetCurrentMap(map, sizeof(map));
	
	if (strcmp(map, "c7m1") == 0 || strcmp(map, "c7m3") == 0)
	{
		new Handle:g_Rest = FindConVar("mp_restartgame");
		SetConVarInt(g_Rest, 1);
	}
}

public Action:OnPlayerIdle(Handle:event, String:Onname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new fake = GetClientOfUserId(GetEventInt(event, "bot"));
	
	if (client)
	{
		if (g_fCvarXTimer > 0 && GetClientTeam(client) != 3)
		{
			ChangeEntityModel(client, fake);
		}
		
		if (g_iCvarMin > 0)
		{
			afk[client] = client;
			afk[fake] = afk[client];
		}
	}
}

public Action:OnPlayerBack(Handle:event, String:Onname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && !IsFakeClient(client))
	{
		if (g_fCvarXTimer > 0 && GetClientTeam(client) != 2)
		{
			CreateTimer(0.01, Triger, client);
		}
		
		if (g_iCvarMin > 0)
		{
			if (loading[client] != 0 && GetClientTeam(client) != 1)
			{
				CreateTimer(1.0, TakeOverBot, client);
			}
			
			if (GetClientTeam(client) != 2)
			{
				IdleStatus(client);
			}
		}
	}
}

public Action:TakeOverBot(Handle:timer, any:client)
{
	loading[client] = 0;
	CreateTimer(0.1, SappyFix);
}

public OnClientConnected(client)
{
	if (client && !IsFakeClient(client))
	{
		loading[client] = 1;
	}
}

public OnClientDisconnect(client)
{
	if (client)
	{
		if (!IsFakeClient(client))
		{
			if (loading[client] != 0) 
			{
				loading[client] = 0;
			}
			
			if (g_iCvarMin != 0)
			{
				IdleStatus(client);
				CreateTimer(1.0, SappyFix, client);
			}
			
			if (g_fCvarXTimer > 0 && !bMapChange)
			{
				Format(sModel[client], sizeof(sModel), "");
			}
		}
		
		if (IsClientInGame(client) && IsFakeClient(client) && !IsBehopClient(client) && GetClientTeam(client) == 2)
		{
			Items(client);
			
			if (g_bCvarDef && !IsPlayerAlive(client))
			{
				DateBase(client);
			}
		}
		
		if (g_bCvarDef)
		{
			CreateTimer(1.5, ClearDB, client);
		}	
	}
}

public Action:ClearDB(Handle:timer, any:client)
{
	if (ID[client] != 0)
	{
		ID[client] = 0;
	}
	TimeToKill(client);
}

public Action:SappyFix(Handle:timer, any:id)
{
	new fake, fafk, spectator, total, connected, log;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (loading[i] != 0)
		{
			connected++;
		}
		
		if (IsClientInGame(i) && GetClientTeam(i) != 3)
		{
			if (GetClientTeam(i) == 2)
			{
				total++;
			}
			
			if (GetClientTeam(i) == 2 && IsFakeClient(i))
			{
				if (afk[i] == 0)
				{
					fake++;
				}
				else
				{
					fafk++;
				}
			}
			
			if (afk[i] != 0 && !IsFakeClient(i))
			{
				spectator++;
			}
		}
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (total > g_iCvarMin && fake > connected && IsFakeClient(i) && !IsBehopClient(i) && afk[i] == 0)
			{
				total--;
				fake--;
				log++;
				KickClient(i);
				
				DateBase(id);
			}
		}
	}
}

IdleStatus(client)
{
	if (afk[client] != 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (i != client && IsClientInGame(i) && afk[i] == client)
			{
				afk[i] = 0;
				
				if (g_bCvarDef && ID[i] != 0 && !IsPlayerAlive(i))
				{
					ID[client] = ID[i];
					ID[i] = 0;
				}
				
				break;
			}
		}
		afk[client] = 0;
	}
}

bool:IsBehopClient(client)
{
	decl String:name[32];
	GetClientName(client, name, sizeof(name));
	if (StrContains(name, "bebop_bot_fakeclient", false) != -1 || StrContains(name, "I am not real.", false) != -1 ||  StrContains(name, "FakeClient", false) != -1 || StrContains(name, "Not in Ghost.", false) != -1 || StrContains(name, "SurvivorBot", false) != -1)
	{
		return true;
	}
	return false;
}

public Action:DisableItems(Handle:timer)
{
	g_iCvarItems = 0;
}

Items(client)
{
	if (g_iCvarItems == 1)
	{
		for (new x = 0; x <= 4; x++)
		{
			new slot = GetPlayerWeaponSlot(client, x);
			if (slot != -1)
			{
				RemovePlayerItem(client, slot);
			}
		}
	}
}

public Action:OnRoundStart(Handle:event, String:Onname[], bool:dontBroadcast)
{
	if (g_bCvarDef)
	{
		GhostStatusToFalse();
	}
	
	if (g_fCvarTimer > 0)
	{
		ValidTime();
	}
}

ValidTime()
{
	if (g_iCvarMin > 0)
	{
		CreateTimer(g_fCvarTimer, SappyFix);
	}	
	else if (g_iCvarMax > 0)
	{
		CreateTimer(g_fCvarTimer, DoIt);
	}	
}

public Action:DoIt(Handle:timer)
{
	ValidLimit();
}

ValidLimit()
{
	new x, k;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			x++;
		}
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (x > g_iCvarMax && IsFakeClient(i))
			{
				k++;
				x--;
				KickClient(i);	
			}
		}
	}
}

public Action:OnPlayerDeath(Handle:event, String:Onname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && GetClientTeam(client) == 2 && ID[client] == 0)
	{
		new entity = -1;
		
		while ((entity = FindEntityByClassname(entity , "survivor_death_model")) != -1)
		{
			if (NotSavedEntity(entity))
			{
				ID[client] = entity;
				hzTimer[client] = CreateTimer(0.5, IsClientRevived, client, TIMER_REPEAT);
				
				break;
			}
		}	
	}
}

public Action:IsClientRevived(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		ID[client] = 0;
		TimeToKill(client);
	}
}

TimeToKill(client)
{
	if (hzTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hzTimer[client]);
		hzTimer[client] = INVALID_HANDLE;
	}
}

bool:NotSavedEntity(entity)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (ID[i] == entity)
		{
			return false;
		}
	}
	return true;
}

DateBase(const id)
{
	if (ID[id] != 0 && IsValidEntity(ID[id]) && IsValidEdict(ID[id]))
	{
		AcceptEntityInput(ID[id], "Kill");
		
		ID[id] = 0;
	}
}

GhostStatusToFalse()
{
	for (new i = 1; i < MaxClients; i++)
	{
		ID[i] = 0;
		TimeToKill(i);
	}
}

RemoveClientModel()
{
	if (IsSurvivalMode())
	{
		return;
	}
	
	decl String:map[24];
	GetCurrentMap(map, sizeof(map));
	
	if (strcmp(map, "c1m1_hotel") == 0 || strcmp(map, "c2m1_highway") == 0 || strcmp(map, "c3m1_plankcountry") == 0 || strcmp(map, "c4m1_milltown_a") == 0 || strcmp(map, "c5m1_waterfront") == 0 || strcmp(map, "c6m1_riverbank") == 0 || strcmp(map, "c7m1_docks") == 0 || strcmp(map, "c8m1_apartment") == 0 || strcmp(map, "c9m1_alleys") == 0 || strcmp(map, "c10m1_caves") == 0 || strcmp(map, "c11m1_greenhouse") == 0 || strcmp(map, "c12m1_hilltop") == 0 || strcmp(map, "c13m1_alpinecreek") == 0 || strcmp(map, "c6m3_port") == 0)
	{
		for (new i = 1; i < MaxClients; i++)
		{
			Format(sModel[i], sizeof(sModel), "");
		}
	}
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
	PrepareFix();
}

public OnConfigsExecuted()
{
	GetCVars();
	PrepareFix();
}

GetCVars()
{
	g_bCvarSf = GetConVarBool(g_hSf);
	g_iCvarMax = GetConVarInt(g_hSurvivor);
	g_iCvarItems = GetConVarInt(g_hItems);
}

PrepareFix()
{
	g_iCvarMin = GetConVarInt(g_hBebop);
	g_fCvarTimer = GetConVarFloat(g_hTimer);
	g_bCvarDef = GetConVarBool(g_hDef);
	g_fCvarXTimer = GetConVarFloat(g_hModel);
	
	if (g_hxTimer != INVALID_HANDLE)
	{
		KillTimer(g_hxTimer);
		g_hxTimer = INVALID_HANDLE;
	}
	
	if (g_fCvarXTimer != 0)
	{
		g_hxTimer = CreateTimer(g_fCvarXTimer, SaveEntityModel, _, TIMER_REPEAT);
	}
	
	if ((g_fCvarTimer > 0 || g_bCvarDef) && !bBlock[1])
	{
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		bBlock[1] = true;
	}
	else if (g_fCvarTimer == 0 && !g_bCvarDef && bBlock[1])
	{
		UnhookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		bBlock[1] = false;
	}
	
	if ((g_iCvarMin > 0 || g_fCvarXTimer > 0) && !bBlock[2]){
	
		HookEvent("player_bot_replace", OnPlayerIdle);
		HookEvent("map_transition", OnMapTranslition, EventHookMode_PostNoCopy);
		bBlock[2] = true;
	}
	else if (g_iCvarMin == 0 && g_fCvarXTimer == 0 && bBlock[2])
	{
		UnhookEvent("player_bot_replace", OnPlayerIdle);
		UnhookEvent("map_transition", OnMapTranslition, EventHookMode_PostNoCopy);
		bBlock[2] = false;
	}
	
	if ((g_iCvarMin > 0 || g_fCvarTimer > 0 || g_fCvarXTimer > 0) && !bBlock[3])
	{
		HookEvent("player_team", OnPlayerBack);
		bBlock[3] = true;
	}
	else if (g_iCvarMin == 0 && g_fCvarTimer == 0 && g_fCvarXTimer == 0 && bBlock[3])
	{
		UnhookEvent("player_team", OnPlayerBack);
		bBlock[3] = false;
	}
	
	if (g_bCvarDef && !bBlock[4])
	{
		HookEvent("player_death", OnPlayerDeath);
		bBlock[4] = true;
	}
	else if (!g_bCvarDef && bBlock[4])
	{
		UnhookEvent("player_death", OnPlayerDeath);
		bBlock[4] = false;
		
		GhostStatusToFalse();
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:buffer[24];
	GetGameFolderName(buffer, sizeof(buffer));
	
	if (strcmp(buffer, "left4dead") == 0 || strcmp(buffer, "left4dead2") == 0)
	{
		return APLRes_Success;
	}
	
	Format(buffer, sizeof(buffer), "[FIX] Plugin Supports L4D and L4D2 Only!", buffer);
	strcopy(error, err_max, buffer);
	return APLRes_Failure;
}

