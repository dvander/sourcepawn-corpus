#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dukehacks>

#define PL_VERSION "0.7b"

// DUKEHACKS ARE NEEDED FOR THAT VERSION !

public Plugin:myinfo = {
	name        = "DoD:S GunGame",
	author      = "Tsunami, extended by Feuersturm and Darkranger",
	description = "DoD:S GunGame for SourceMod",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new g_iAmmo[MAXPLAYERS + 1];
new g_iAmount[MAXPLAYERS + 1];
new g_iClip;
new g_iLevel[MAXPLAYERS + 1]    = {1, ...};
new g_iLevels;
new g_iMaxClients;
new g_iOffset;
new g_ggWinner = -1;
new g_iOldLevel[MAXPLAYERS + 1] = {1, ...};
new g_iWeapon[MAXPLAYERS + 1]   = {-1, ...};
new bool:g_bEnabled             = true;
new Float:g_fPosition[MAXPLAYERS + 1][3];
new Handle:g_hEnabled;
new Handle:g_hFlags;
new Handle:g_hHandicap;
new Handle:g_hNextMap;
new Handle:g_hSpades;
new Handle:g_hSpadePro;
new Handle:g_hTurbo;
new Handle:g_nades;
new Handle:g_bonustime;
new Handle:g_bonustimekill;
new Handle:g_runspeed;
new Handle:g_runcommand;
new String:g_sPrefix[24]        = "\x06[] \x04GunGame \x06[] \x01";
new String:g_sSoundJoin[PLATFORM_MAX_PATH];
new String:g_sSoundLevelUp[PLATFORM_MAX_PATH];
new String:g_sSoundLevelDown[PLATFORM_MAX_PATH];
new String:g_sSoundLevelSteal[PLATFORM_MAX_PATH];
new String:g_sSoundWin[PLATFORM_MAX_PATH];
new String:g_sWeapon[MAXPLAYERS + 1][16];

public OnPluginStart()
{
	CreateConVar("sm_gungame_version", PL_VERSION, "DoD:S GunGame for SourceMod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_gungame_enabled",  "1", "Enable/disable DoD:S GunGame.",                   FCVAR_PLUGIN);
	g_hFlags    = CreateConVar("sm_gungame_flags",    "0", "Enable/disable flags in DoD:S GunGame.",          FCVAR_PLUGIN);
	g_hHandicap = CreateConVar("sm_gungame_handicap", "1", "Enable/disable Handicap mode in DoD:S GunGame.",  FCVAR_PLUGIN);
	g_hSpades   = CreateConVar("sm_gungame_spades",   "1", "Enable/disable spades in DoD:S GunGame.",         FCVAR_PLUGIN);
	g_hSpadePro = CreateConVar("sm_gungame_spadepro", "1", "Enable/disable Spade Pro mode in DoD:S GunGame.", FCVAR_PLUGIN);
	g_hTurbo    = CreateConVar("sm_gungame_turbo",    "1", "Enable/disable Turbo mode in DoD:S GunGame.",     FCVAR_PLUGIN);
	g_bonustime    = CreateConVar("sm_gungame_bonustime",    "12", "Length of Bonusround! standard: 12",     FCVAR_PLUGIN);
	g_bonustimekill    = CreateConVar("sm_gungame_bonustimekill",    "0", "<1/0> Enable/Disable Kills during bounsround! standard: 0",     FCVAR_PLUGIN);
	g_nades    = CreateConVar("sm_gungame_maxnades",    "8", "How much Frag Grenades are allowed! standard: 8",     FCVAR_PLUGIN);
	g_runspeed    = CreateConVar("sm_gungame_runspeed",    "70", "max. Stamina for Spade/Knife Level for permanent run! standard: 70",     FCVAR_PLUGIN);
	g_runcommand    = CreateConVar("sm_gungame_runcommand",    "sm_fireworks_start", "SM Command executed on gameEnd! standard: sm_fireworks_start",     FCVAR_PLUGIN);
	g_iClip     = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iOffset   = FindSendPropInfo("CBasePlayer",       "m_iAmmo");
	dhAddClientHook(CHK_TakeDamage, OnTakeDamage);
	HookConVarChange(g_hEnabled, ConVarChange_Enabled);
	HookConVarChange(g_hFlags,   ConVarChange_Flags);
	HookEvent("dod_round_start", Event_RoundStart);
	HookEvent("player_death",    Event_PlayerDeath);
	HookEvent("player_spawn",    Event_PlayerSpawn);
	RegConsoleCmd("drop",        Command_Drop, "Block weapons from being dropped in DoD:S GunGame.");
	LoadTranslations("gungame.phrases");
}

public Action:OnTakeDamage(client, attacker, inflictor, Float:Damage, &Float:damageMultiplier, damagetype)
{
	if(g_bEnabled && g_ggWinner != -1 && GetConVarInt(g_bonustimekill) == 0)
	{
		damageMultiplier = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	g_hNextMap    = FindConVar("sm_nextmap");
	g_iMaxClients = GetMaxClients();
	g_ggWinner = -1;

	LoadConfig();
}

public OnGameFrame()
{
	if (g_bEnabled && g_ggWinner == -1)
	{
		for (new i    = 1, iAmmo, iAmount; i <= g_iMaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && !StrEqual(g_sWeapon[g_iLevel[i]], "frag_ger") && !StrEqual(g_sWeapon[g_iLevel[i]], "frag_us"))
			{
				if(!StrEqual(g_sWeapon[g_iLevel[i]], "spade") && !StrEqual(g_sWeapon[g_iLevel[i]], "amerknife"))
				{
					iAmmo     = g_iAmmo[GetLevel(i)], iAmount = g_iAmount[i];
					if (iAmmo > g_iOffset && GetEntData(i, iAmmo) <= iAmount)
					{
						SetEntData(i, iAmmo, iAmount * 2, _, true);
					}
				}
				else
				{
					SetEntPropFloat(i, Prop_Send, "m_flStamina", GetConVarFloat(g_runspeed));
				}
			}
		}
	}
	// GIVE CLIENTs SPEED after WIN
	if (g_ggWinner != -1)
	{
		for(new client = 1; client <= MaxClients; client++)
			{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				SetEntPropFloat(client, Prop_Send, "m_flStamina", GetConVarFloat(g_runspeed));

			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (g_bEnabled && g_ggWinner == -1 && !StrEqual(g_sSoundJoin, ""))
	{
		EmitSoundToClient(client, g_sSoundJoin);
	}
	new iClients  = GetTeamClientCount(2) + GetTeamClientCount(3), iLevel = 0;
	if (GetConVarBool(g_hHandicap) && iClients > 0)
	{
		for (new i  = 1; i <= g_iMaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1)
			{
				iLevel += GetLevel(i);
			}
		}
		g_iLevel[client] = iLevel / iClients;
	}
	else
	{
		g_iLevel[client] = 1;
	}
	g_iWeapon[client]  = -1;
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled  = StrEqual(newValue, "1");

	ServerCommand("mp_clan_restartround 1");

	decl iLevel[MAXPLAYERS + 1] = {1, ...};
	g_iLevel                    = iLevel;
}

public ConVarChange_Flags(Handle:convar,   const String:oldValue[], const String:newValue[])
{
	SetFlags();
}

public MenuHandler_Give(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		GiveWeapon(param1);
	}
}

public Action:Command_Drop(client, args)
{
	return g_bEnabled ? Plugin_Handled : Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled && g_ggWinner == -1)
	{
		decl Float:fPosition[3], String:sWeapon[16];
		new iAttackerID = GetEventInt(event, "attacker"),
				iClientID   = GetEventInt(event, "userid"),
				iAttacker   = GetClientOfUserId(iAttackerID),
				iClient     = GetClientOfUserId(iClientID);
		GetClientAbsOrigin(iClient, fPosition);
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));

		if (IsValidEntity(g_iWeapon[iClient]))
		{
			RemoveWeapon(iClient, g_iWeapon[iClient]);
		}
		if (iAttacker == 0 || iAttacker == iClient)
		{
			if (g_iLevel[iClient] > 1)
			{
				g_iLevel[iClient]--;
				PrintToChatAll("%s%t", g_sPrefix, "Suicide", 4, iClient, 1);
				LogEvent("gg_leveldown",    iClientID);

				if (!StrEqual(g_sSoundLevelDown,    ""))
				{
					EmitSoundToClient(iClient, g_sSoundLevelDown);
				}
			}
		}
		else if (GetClientTeam(iAttacker) != GetClientTeam(iClient) && (StrEqual(sWeapon, g_sWeapon[GetLevel(iAttacker)]) || StrEqual(sWeapon, "spade")))
		{
			if (fPosition[0] == g_fPosition[iClient][0] && fPosition[1] == g_fPosition[iClient][1])
			{
				PrintHintText(iAttacker, "%t", "AFK", iClient);
			}
			else if (g_iLevel[iAttacker]++ < g_iLevels)
			{
				if (GetConVarBool(g_hSpades)   && GetConVarBool(g_hSpadePro) &&
						StrEqual(sWeapon, "spade") && g_iLevel[iClient] > 1)
						{
					g_iLevel[iClient]--;
					PrintToChatAll("%s%t", g_sPrefix, "Steal", 4, iAttacker, 1, 4, iClient, 1);
					LogEvent("gg_levelsteal", iAttackerID);
					LogEvent("gg_leveldown",  iClientID);

					if (!StrEqual(g_sSoundLevelSteal, ""))
					{
						EmitSoundToClient(iAttacker, g_sSoundLevelSteal);
					}
					if (!StrEqual(g_sSoundLevelDown,  ""))
					{
						EmitSoundToClient(iClient,   g_sSoundLevelDown);
					}
				}
				else
				{
					LogEvent("gg_levelup",    iAttackerID);

					if (!StrEqual(g_sSoundLevelUp,    ""))
					{
						EmitSoundToClient(iAttacker, g_sSoundLevelUp);
					}
				}

				new iLeader  = GetLeader(), iLevel = g_iLevel[iAttacker];
				if (IsPlayerAlive(iAttacker))
				{
					PrintToChat(iAttacker,   "%s%t", g_sPrefix, "Weapon",     4, g_sWeapon[iLevel]);
				}
				if (iLeader == iAttacker)
				{
					PrintToChatAll("%s%t", g_sPrefix, "Leader", 4, iAttacker, 1, 4, iLevel, 1);
				}
				else
				{
				new iLead  = g_iLevel[iLeader] - iLevel;
				if (iLead  > 0)
					{
					PrintToChat(iAttacker, "%s%t", g_sPrefix, "Difference", 4, iLead, 1, iLead == 1 ? "" : "s");
					}
				}

				if (GetConVarBool(g_hTurbo))
				{
					CreateTimer(0.1, Timer_Give, iAttacker);
				}
				else
				{
					new Handle:hGive = CreateMenu(MenuHandler_Give);
					SetMenuTitle(hGive, "You have leveled up!");
					SetMenuExitButton(hGive, true);
					AddMenuItem(hGive, "", "Press 1 to get your next weapon.");
					DisplayMenu(hGive, iAttacker, MENU_TIME_FOREVER);
				}
			}
			else
			{
			 	if(g_ggWinner == -1)
				{
					g_ggWinner = iAttacker;
					decl String:sNextMap[32];
					GetConVarString(g_hNextMap, sNextMap, sizeof(sNextMap));
					PrintToChatAll("%s%t", g_sPrefix, "Win", 4, iAttacker, 1, 4, sNextMap);
					Show_ggWinner(iAttacker);
					LogEvent("gg_win", iAttackerID);
					CreateTimer(GetConVarFloat(g_bonustime), Timer_EndGame);
					if (!StrEqual(g_sSoundWin, ""))
					{
						EmitSoundToAll(g_sSoundWin);
					}
					// ServerCommand("sm_fireworks_start");
					decl String:Runcommand[256];
					GetConVarString(g_runcommand, Runcommand, sizeof(Runcommand));
					ServerCommand("%s", Runcommand);
					// REMOVE CLIENT WEAPONS
					for(new client = 1; client <= MaxClients; client++)
					{
						if(IsClientInGame(client) && IsPlayerAlive(client))
						{
						for (new i = 0, s; i < 5; i++)
							{
								if ((s = GetPlayerWeaponSlot(client, i)) != -1)
								{
									RemoveWeapon(client, s);
								}
							}
						GivePlayerItem(client, "weapon_spade");
						}
					}
				}
			}
		}
	}
}


public Action:Show_ggWinner(ggWinner)
{
	new Handle:ggWinnerMenu = INVALID_HANDLE;
	ggWinnerMenu = CreatePanel();
	decl String:menutitle[256];
	Format(menutitle, sizeof(menutitle), "DoD GunGame");
	SetPanelTitle(ggWinnerMenu, menutitle);
	DrawPanelItem(ggWinnerMenu, "", ITEMDRAW_SPACER);
	decl String:Winner[256];
	Format(Winner, sizeof(Winner), "The Winner is: %N!", ggWinner);
	DrawPanelText(ggWinnerMenu, Winner);
	DrawPanelItem(ggWinnerMenu, "", ITEMDRAW_SPACER);
	decl String:sNextMap[32];
	GetConVarString(g_hNextMap, sNextMap, sizeof(sNextMap));
	decl String:NextMap[256];
	Format(NextMap, sizeof(NextMap), "have fun on next Map:  %s!!!", sNextMap);
	DrawPanelText(ggWinnerMenu, NextMap);
	DrawPanelItem(ggWinnerMenu, "", ITEMDRAW_SPACER);
	SetPanelCurrentKey(ggWinnerMenu, 10);
	DrawPanelItem(ggWinnerMenu, "Close", ITEMDRAW_CONTROL);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			SendPanelToClient(ggWinnerMenu, i, Handle_ggWinnerMenu, 14);
		}
	}
}

public Handle_ggWinnerMenu(Handle:TeamStatsMenu, MenuAction:action, client, itemNum)
{
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(iClient) > 1)
		{
			GetClientAbsOrigin(iClient, g_fPosition[iClient]);
			CreateTimer(0.1, Timer_Strip, iClient);
		}
	}
}

public Action:Event_RoundStart(Handle:event,  const String:name[], bool:dontBroadcast)
{
	for(new client = 1; client <= MaxClients; client++)
	//if(IsClientInGame(client) && IsPlayerAlive(client)) SetFlags();
	if(IsClientConnected(client) && IsClientInGame(client))
		{
		SetFlags();
		}
}

public Action:Timer_EndGame(Handle:timer)
{
	new iGameEnd  = FindEntityByClassname(-1, "game_end");
	if (iGameEnd == -1 && (iGameEnd = CreateEntityByName("game_end")) == -1)
	{
		LogError("Unable to create entity \"game_end\"!");
	}
	else
	{
		AcceptEntityInput(iGameEnd, "EndGame");
	}
}

public Action:Timer_Give(Handle:timer,  any:client)
{
	if (IsPlayerAlive(client))
	{
		GiveWeapon(client);
	}
}

public Action:Timer_Strip(Handle:timer, any:client)
{
	for (new i = 0, s; i < 5; i++)
	{
		if ((s = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemoveWeapon(client, s);
		}
	}
	if(g_ggWinner != -1)
	{
		GivePlayerItem(client, "weapon_spade");
		return Plugin_Handled;
	}

	new iLevel        = g_iLevel[client];
	g_iWeapon[client] = -1;
	PrintToChat(client, "%s%t", g_sPrefix, "Level", 4, iLevel, 1, 4, g_sWeapon[iLevel]);
	GiveWeapon(client);
	if (GetConVarBool(g_hSpades) && !StrEqual(g_sWeapon[iLevel], "amerknife") && !StrEqual(g_sWeapon[iLevel], "spade"))
	{
		GivePlayerItem(client, "weapon_spade");
	}
	return Plugin_Handled;
}

GetLeader()
{
	new iLeader = 0;
	for (new i  = 1; i <= g_iMaxClients; i++)
	{
		if (IsClientInGame(i) && g_iLevel[i] > g_iLevel[iLeader])
		{
			iLeader = i;
		}
	}

	return iLeader;
}

GetLevel(iClient)
{
	if (GetConVarBool(g_hTurbo))
	{
		return g_iLevel[iClient];
	}
	else
	{
		return g_iOldLevel[iClient];
	}
}

GiveWeapon(iClient)
{
	decl iWeapon, String:sWeapon[24];
	new iLevel = g_iOldLevel[iClient] = g_iLevel[iClient];
	Format(sWeapon, sizeof(sWeapon), "weapon_%s", g_sWeapon[iLevel]);

	if (IsValidEntity(g_iWeapon[iClient]))
	{
		RemoveWeapon(iClient, g_iWeapon[iClient]);
	}
	if (GetConVarBool(g_hSpades) && (iWeapon = GetPlayerWeaponSlot(iClient, 2)) != -1 && (StrEqual(g_sWeapon[iLevel], "amerknife") ||  StrEqual(g_sWeapon[iLevel], "spade")))
	{
		RemoveWeapon(iClient, iWeapon);
	}
	g_iWeapon[iClient] = GivePlayerItem(iClient, sWeapon);
	if(StrEqual(g_sWeapon[iLevel], "frag_ger") || StrEqual(g_sWeapon[iLevel], "frag_us"))
	{

		SetEntData(iClient, g_iAmmo[iLevel], GetConVarInt(g_nades), _, true);
		PrintHintText(iClient, "REMEMBER :You have only %d Grenades!", GetConVarInt(g_nades));
		PrintToChat(iClient, "REMEMBER :You have only %d Grenades!", GetConVarInt(g_nades));
		PrintCenterText(iClient, "REMEMBER :You have only %d Grenades!", GetConVarInt(g_nades));
	}
	else
	{
		if ((g_iAmount[iClient] = GetEntData(g_iWeapon[iClient], g_iClip)) < 1)
		{
			g_iAmount[iClient]    = 1;
		}
		if (g_iAmmo[iLevel]     > 0)
		{
			SetEntData(iClient, g_iAmmo[iLevel], g_iAmount[iClient] * 2, _, true);
		}
	}
}

LoadConfig()
{
	decl String:sLevel[4], String:sPath[PLATFORM_MAX_PATH], String:sWeapon[16],
			 String:sWeapons[22][16] = {"colt", "p38", "c96", "garand", "k98", "k98_scoped", "m1carbine", "spring", "thompson", "mp40", "mp44", "bar", "30cal", "mg42", "bazooka", "pschreck", "frag_us", "frag_ger", "smoke_us", "smoke_ger", "riflegren_us", "riflegren_ger"};

	new  iLevel = 1,
	iOffsets[22] = { 4, 8, 12, 16, 20, 20, 24, 28, 32, 32, 32, 36, 40, 44, 48, 48, 52, 56, 68, 72, 84, 88},
	Handle:hConfig          = CreateKeyValues("GunGame");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/gungame.txt");

	if (FileExists(sPath))
	{
		for (new i = 0; i < sizeof(g_sWeapon); i++)
		{
			g_iAmmo[i]   = g_iOffset;
			g_sWeapon[i] = "";
		}

		FileToKeyValues(hConfig, sPath);
		KvJumpToKey(hConfig, "Levels");
		KvGetString(hConfig, "1", sWeapon, sizeof(sWeapon));

		while (!StrEqual(sWeapon, ""))
		{
			g_sWeapon[iLevel] = sWeapon;

			IntToString(++iLevel, sLevel, sizeof(sLevel));
			KvGetString(hConfig,  sLevel, sWeapon, sizeof(sWeapon));
		}

		KvRewind(hConfig);
		KvJumpToKey(hConfig, "Sounds");
		KvGetString(hConfig, "Join",       g_sSoundJoin,       PLATFORM_MAX_PATH);
		KvGetString(hConfig, "LevelUp",    g_sSoundLevelUp,    PLATFORM_MAX_PATH);
		KvGetString(hConfig, "LevelDown",  g_sSoundLevelDown,  PLATFORM_MAX_PATH);
		KvGetString(hConfig, "LevelSteal", g_sSoundLevelSteal, PLATFORM_MAX_PATH);
		KvGetString(hConfig, "Win",        g_sSoundWin,        PLATFORM_MAX_PATH);

		if (!StrEqual(g_sSoundJoin,       ""))
		{
			LoadSound(g_sSoundJoin);
		}
		if (!StrEqual(g_sSoundLevelUp,    ""))
		{
			LoadSound(g_sSoundLevelUp);
		}
		if (!StrEqual(g_sSoundLevelDown,  ""))
		{
			LoadSound(g_sSoundLevelDown);
		}
		if (!StrEqual(g_sSoundLevelSteal, ""))
		{
			LoadSound(g_sSoundLevelSteal);
		}
		if (!StrEqual(g_sSoundWin,        ""))
		{
			LoadSound(g_sSoundWin);
		}

		g_iLevels  = --iLevel;
		for (new i = 1, j; i <= g_iLevels; i++)
		{
			for (j   = 0; j < sizeof(sWeapons); j++)
			{
				if (StrEqual(g_sWeapon[i], sWeapons[j]))
				{
					g_iAmmo[i] += iOffsets[j];
					break;
				}
			}
		}
	}
	else
	{
		SetFailState("File Not Found: %s", sPath);
	}
}

LoadSound(const String:sFile[])
{
	decl String:sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "sound/%s", sFile);
	PrecacheSound(sFile, true);
	AddFileToDownloadsTable(sPath);
}

LogEvent(const String:sName[], iUserID)
{
	decl String:sAuth[32];
	new iClient = GetClientOfUserId(iUserID);
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));
	LogToGame("\"%N<%d><%s><GunGame>\" triggered \"%s\"", iClient, iUserID, sAuth, sName);
}

RemoveWeapon(iClient, iWeapon)
{
	RemovePlayerItem(iClient, iWeapon);
	RemoveEdict(iWeapon);
}

SetFlags()
{
	decl String:sState[8];
	new iCaptureArea     = -1;
	sState               = g_bEnabled && !GetConVarBool(g_hFlags) ? "Disable" : "Enable";
	while ((iCaptureArea = FindEntityByClassname(iCaptureArea, "dod_capture_area")) != -1)
	{
		AcceptEntityInput(iCaptureArea, sState);
	}
}