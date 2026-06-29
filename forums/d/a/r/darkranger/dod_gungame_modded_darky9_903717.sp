#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.9beta3"
#define MAXCLASSES 12
#define MAXWEAPONS 18

public Plugin:myinfo = {
	name        = "DoD:S GunGame",
	author      = "Tsunami - extended by Feuersturm and Darkranger",
	description = "DoD:S GunGame for SourceMod extended",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new g_iAmount[MAXPLAYERS + 1];
new g_ggWinner = -1
new g_iAmmo[MAXPLAYERS + 1];
new g_iClip;
new g_iLevel[MAXPLAYERS + 1]    = {1, ...};
new g_iLevels;
new g_iMaxClients;
new g_iOffset;
new g_iOldLevel[MAXPLAYERS + 1] = {1, ...};
new g_iWeapon[MAXPLAYERS + 1]   = {-1, ...};
new bool:g_bEnabled             = true;
new Handle:g_hEnabled;
new Handle:g_hFlags;
new Handle:g_hHandicap;
new Handle:g_hNextMap;
new Handle:g_hSpades;
new Handle:g_hSpadePro;
new Handle:g_hTurbo;
new Handle:g_nades;
new Handle:g_bonustime;
new String:g_sPrefix[24]        = "\x06[] \x04GunGame \x06[] \x01";
new String:g_sSoundJoin[PLATFORM_MAX_PATH];
new String:g_sSoundLevelUp[PLATFORM_MAX_PATH];
new String:g_sSoundLevelDown[PLATFORM_MAX_PATH];
new String:g_sSoundLevelSteal[PLATFORM_MAX_PATH];
new String:g_sSoundWin[PLATFORM_MAX_PATH];
new String:g_sWeapon[MAXPLAYERS + 1][16];
//new String:ClassCmd[MAXCLASSES][] =
//{
//	"cls_garand", "cls_tommy", "cls_bar", "cls_spring", "cls_30cal", "cls_bazooka",
//	"cls_k98", "cls_mp40", "cls_mp44", "cls_k98s", "cls_mg42", "cls_pschreck"
//};
new String:g_Weapon[MAXWEAPONS][] =
{
	"weapon_amerknife", "weapon_spade", "weapon_colt", "weapon_p38", "weapon_m1carbine", "weapon_c96",
	"weapon_garand", "weapon_k98", "weapon_thompson", "weapon_mp40", "weapon_bar", "weapon_mp44",
	"weapon_spring", "weapon_k98_scoped", "weapon_30cal", "weapon_mg42", "weapon_bazooka", "weapon_pschreck"
}
new g_ClassDisplay[MAXWEAPONS] =
{
	0, 0, 1, 1, 5, 5, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5
}
new bool:g_PluginClassSelect[MAXPLAYERS+1] = false;

public OnPluginStart()
{
	CreateConVar("sm_gungame_version", PL_VERSION, "DoD:S GunGame for SourceMod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_gungame_enabled",  "1", "Enable/disable DoD:S GunGame.",                   FCVAR_PLUGIN);
	g_hFlags    = CreateConVar("sm_gungame_flags",    "0", "Enable/disable flags in DoD:S GunGame.",          FCVAR_PLUGIN);
	g_hHandicap = CreateConVar("sm_gungame_handicap", "1", "Enable/disable Handicap mode in DoD:S GunGame.",  FCVAR_PLUGIN);
	g_hSpades   = CreateConVar("sm_gungame_spades",   "1", "Enable/disable spades in DoD:S GunGame.",         FCVAR_PLUGIN);
	g_hSpadePro = CreateConVar("sm_gungame_spadepro", "1", "Enable/disable Spade Pro mode in DoD:S GunGame.", FCVAR_PLUGIN);
	g_hTurbo    = CreateConVar("sm_gungame_turbo",    "1", "Enable/disable Turbo mode in DoD:S GunGame.",     FCVAR_PLUGIN);
	g_nades    = CreateConVar("sm_gungame_maxnades",    "10", "How much Frag Grenades are allowed! standard: 10",     FCVAR_PLUGIN);
	g_bonustime    = CreateConVar("sm_gungame_bonustime",    "15", "Length of Bonusround! standard: 15",     FCVAR_PLUGIN);
	g_iClip     = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iOffset   = FindSendPropInfo("CDODPlayer",       "m_iAmmo");
	HookConVarChange(g_hEnabled, ConVarChange_Enabled);
	HookConVarChange(g_hFlags,   ConVarChange_Flags);
	HookEvent("dod_round_start", Event_RoundStart);
	HookEvent("player_death",    Event_PlayerDeath);
	HookEvent("player_spawn",    Event_PlayerSpawn);
//	HookEvent("player_team", Surpress_ClassMenu, EventHookMode_Pre);
	RegConsoleCmd("drop", Command_Drop, "Block weapons from being dropped");
//	for(new i = 0; i < MAXCLASSES; i++)
//	{
//		RegAdminCmd(ClassCmd[i], cmd_ClassSelect, 0);
//	}
//	RegAdminCmd("joinclass", cmd_ClassSelect, 0);
//	RegAdminCmd("cls_random", cmd_ClassSelect, 0);
	LoadTranslations("gungame.phrases");
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
					SetEntPropFloat(i, Prop_Send, "m_flStamina", 100.0)
				}
			}
		}
	}
}

//public Action:Surpress_ClassMenu(Handle:event, const String:name[], bool:dontBroadcast)
//{
//	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	new team = GetEventInt(event, "team");
//	if(team > 1)
//	{
//		g_PluginClassSelect[client] = true;
//		if(team == 2)
//		{
//			FakeClientCommandEx(client, "%s", ClassCmd[GetRandomInt(0, 5)]);
//		}
//		else
//		{
//			FakeClientCommandEx(client, "%s", ClassCmd[GetRandomInt(6, 11)]);
//		}
//		return Plugin_Handled;
//	}
//	return Plugin_Continue;
//}
//
//public Action:cmd_ClassSelect(client, args)
//{
//	if(g_PluginClassSelect[client])
//	{
//		g_PluginClassSelect[client] = false;
//		ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_ger" : "class_us", INVALID_HANDLE, false);
//		return Plugin_Continue;
//	}
//	else
//	{
//		PrintToChat(client, "%sNo need to change class in GunGame!", g_sPrefix);
//		return Plugin_Handled;
//	}
//}

public OnMapStart()
{
	g_hNextMap    = FindConVar("sm_nextmap");
	g_iMaxClients = GetMaxClients();
	g_ggWinner = -1
	LoadConfig();
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled && g_ggWinner == -1 && !StrEqual(g_sSoundJoin, ""))
	{
		EmitSoundToClient(client, g_sSoundJoin);
	}
	new iClients  = GetTeamClientCount(2) + GetTeamClientCount(3), iLevel = 0;
	if(GetConVarBool(g_hHandicap) && iClients > 0)
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
	g_PluginClassSelect[client] = false;
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled  = StrEqual(newValue, "1");
	ServerCommand("mp_clan_restartround 1");
	decl iLevel[MAXPLAYERS + 1] = {1, ...};
	g_iLevel = iLevel;
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
	if(g_bEnabled && g_ggWinner == -1)
	{
		PrintToChat(client, "%sSorry, you cannot drop a weapon!", g_sPrefix);
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled && g_ggWinner == -1)
	{
		decl String:sWeapon[16];
		new iAttackerID = GetEventInt(event, "attacker");
		new iClientID = GetEventInt(event, "userid");
		new iAttacker = GetClientOfUserId(iAttackerID);
		new iClient = GetClientOfUserId(iClientID);
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if(IsValidEntity(g_iWeapon[iClient]))
		{
			RemoveWeapon(iClient, g_iWeapon[iClient]);
		}
		if(iAttacker == 0 || iAttacker == iClient)
		{
			if(g_iLevel[iClient] > 1)
			{
				g_iLevel[iClient]--;
				PrintToChatAll("%s%t", g_sPrefix, "Suicide", 4, iClient, 1);
				LogEvent("gg_leveldown",    iClientID);
				if (!StrEqual(g_sSoundLevelDown, ""))
				{
					EmitSoundToClient(iClient, g_sSoundLevelDown);
				}
			}
		}
		else if(GetClientTeam(iAttacker) != GetClientTeam(iClient) && (StrEqual(sWeapon, g_sWeapon[GetLevel(iAttacker)]) || StrEqual(sWeapon, "spade")))
		{
			if(g_iLevel[iAttacker]++ < g_iLevels)
			{
				if (GetConVarBool(g_hSpades)   && GetConVarBool(g_hSpadePro) && StrEqual(sWeapon, "spade") && g_iLevel[iClient] > 1)
				{
					g_iLevel[iClient]--;
					PrintToChatAll("%s%t", g_sPrefix, "Steal", 4, iAttacker, 1, 4, iClient, 1);
					LogEvent("gg_levelsteal", iAttackerID);
					LogEvent("gg_leveldown",  iClientID);
					if (!StrEqual(g_sSoundLevelSteal, ""))
					{
						EmitSoundToClient(iAttacker, g_sSoundLevelSteal);
					}
					if (!StrEqual(g_sSoundLevelDown, ""))
					{
						EmitSoundToClient(iClient,   g_sSoundLevelDown);
					}
				}
				else
				{
					LogEvent("gg_levelup", iAttackerID);
					if (!StrEqual(g_sSoundLevelUp, ""))
					{
						EmitSoundToClient(iAttacker, g_sSoundLevelUp);
					}
				}
				new iLeader  = GetLeader(), iLevel = g_iLevel[iAttacker];
				if (IsPlayerAlive(iAttacker))
				{
					PrintToChat(iAttacker, "%s%t", g_sPrefix, "Weapon", 4, g_sWeapon[iLevel]);
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
					GiveWeapons(iAttacker);
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
					g_ggWinner = iAttacker
					decl String:sNextMap[32];
					GetConVarString(g_hNextMap, sNextMap, sizeof(sNextMap));
					PrintToChatAll("%s%t", g_sPrefix, "Win", 4, iAttacker, 1, 4, sNextMap);
					Show_ggWinner(iAttacker)
					LogEvent("gg_win", iAttackerID);
					CreateTimer(GetConVarFloat(g_bonustime), Timer_EndGame);
					if (!StrEqual(g_sSoundWin, ""))
					{
						EmitSoundToAll(g_sSoundWin);
					}
					for(new i = 1; i < MaxClients; i++)
					{
						if(IsClientInGame(i) && IsPlayerAlive(i))
						{
							SetEntProp(i, Prop_Data, "m_takedamage", 0, 1)
						}
					}
					ServerCommand("sm_fireworks_start")
				}
			}
		}
	}
}

public Action:Show_ggWinner(ggWinner)
{
	new Handle:ggWinnerMenu = INVALID_HANDLE
	ggWinnerMenu = CreatePanel()
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "DoD GunGame")
	SetPanelTitle(ggWinnerMenu, menutitle)
	DrawPanelItem(ggWinnerMenu, "", ITEMDRAW_SPACER)
	decl String:Winner[256]
	Format(Winner, sizeof(Winner), "Winner: %N! Gratulation!", ggWinner)
	DrawPanelText(ggWinnerMenu, Winner)
	DrawPanelItem(ggWinnerMenu, "", ITEMDRAW_SPACER)
	decl String:sNextMap[32];
	GetConVarString(g_hNextMap, sNextMap, sizeof(sNextMap));
	decl String:NextMap[256]
	Format(NextMap, sizeof(NextMap), "next Map is  %s!!!", sNextMap)
	DrawPanelText(ggWinnerMenu, NextMap)
	DrawPanelItem(ggWinnerMenu, "", ITEMDRAW_SPACER)
	SetPanelCurrentKey(ggWinnerMenu, 10)
	DrawPanelItem(ggWinnerMenu, "Close", ITEMDRAW_CONTROL)
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			SendPanelToClient(ggWinnerMenu, i, Handle_ggWinnerMenu, 14)
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
		if (GetClientTeam(iClient) > 1 && IsPlayerAlive(iClient))
		{
			if(g_ggWinner == -1)
			{
				CreateTimer(0.1, StripWeapons, iClient, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1)
			}
		}
	}
}

public Action:Event_RoundStart(Handle:event,  const String:name[], bool:dontBroadcast)
{
	SetFlags();
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

public Action:GiveWeapons(client)
{
	if (IsPlayerAlive(client))
	{
		GiveWeapon(client);
	}
}

public Action:StripWeapons(Handle:timer, any:client)
{
	for(new i = 0; i < 5; i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
		}
	}
	new iLevel = g_iLevel[client];
	g_iWeapon[client] = -1;
	PrintToChat(client, "%s%t", g_sPrefix, "Level", 4, iLevel, 1, 4, g_sWeapon[iLevel]);
	GiveWeapon(client);
	if(GetConVarBool(g_hSpades) && !StrEqual(g_sWeapon[iLevel], "amerknife") && !StrEqual(g_sWeapon[iLevel], "spade"))
	{
		GivePlayerItem(client, "weapon_spade");
	}
}

GetLeader()
{
	new iLeader = 0;
	for (new i  = 1; i <= g_iMaxClients; i++)
	{
		if(IsClientInGame(i) && g_iLevel[i] > g_iLevel[iLeader])
		{
			iLeader = i;
		}
	}
	return iLeader;
}

GetLevel(iClient)
{
	if(GetConVarBool(g_hTurbo))
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
	if(IsValidEntity(g_iWeapon[iClient]))
	{
		RemoveWeapon(iClient, g_iWeapon[iClient]);
	}
	if(GetConVarBool(g_hSpades) && (iWeapon = GetPlayerWeaponSlot(iClient, 2)) != -1 && (StrEqual(g_sWeapon[iLevel], "amerknife") || StrEqual(g_sWeapon[iLevel], "spade")))
	{
		RemoveWeapon(iClient, iWeapon);
	}
	g_iWeapon[iClient] = GivePlayerItem(iClient, sWeapon);
	if(StrEqual(g_sWeapon[iLevel], "frag_ger") || StrEqual(g_sWeapon[iLevel], "frag_us"))
	{

		SetEntData(iClient, g_iAmmo[iLevel], GetConVarInt(g_nades), _, true);
		PrintHintText(iClient, "REMEMBER :You have only %d Grenades!", GetConVarInt(g_nades))
		PrintToChat(iClient, "REMEMBER :You have only %d Grenades!", GetConVarInt(g_nades))
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
	CreateTimer(1.0, SetPlayerClass, iClient, TIMER_FLAG_NO_MAPCHANGE)
}

public Action:SetPlayerClass(Handle:timer, any:iClient)
{
	decl String:curweapon[32]
	GetClientWeapon(iClient, curweapon, sizeof(curweapon))
	new weaponid = -1
	for(new i=0; i < MAXWEAPONS; i++)
	{
		if(strcmp(curweapon, g_Weapon[i]) == 0)
		{
			weaponid = i
		}
	}
	if(weaponid != -1)
	{
		SetEntProp(iClient, Prop_Send, "m_iPlayerClass", g_ClassDisplay[weaponid])
	}
	return Plugin_Handled
}

LoadConfig()
{
	decl String:sLevel[4], String:sPath[PLATFORM_MAX_PATH], String:sWeapon[16];
	decl String:sWeapons[22][16] =
	{
		"colt", "p38", "c96", "garand", "k98", "k98_scoped", "m1carbine", "spring",
		"thompson", "mp40", "mp44", "bar", "30cal", "mg42", "bazooka", "pschreck",
		"frag_us", "frag_ger", "smoke_us", "smoke_ger", "riflegren_us", "riflegren_ger"
	};
	new iLevel = 1;
	new iOffsets[22] = { 4, 8, 12, 16, 20, 20, 24, 28, 32, 32, 32, 36, 40, 44, 48, 48, 52, 56, 68, 72, 84, 88 };
	new Handle:hConfig = CreateKeyValues("GunGame");
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
		if (!StrEqual(g_sSoundJoin, ""))
		{
			LoadSound(g_sSoundJoin);
		}
		if (!StrEqual(g_sSoundLevelUp, ""))
		{
			LoadSound(g_sSoundLevelUp);
		}
		if (!StrEqual(g_sSoundLevelDown, ""))
		{
			LoadSound(g_sSoundLevelDown);
		}
		if (!StrEqual(g_sSoundLevelSteal, ""))
		{
			LoadSound(g_sSoundLevelSteal);
		}
		if (!StrEqual(g_sSoundWin, ""))
		{
			LoadSound(g_sSoundWin);
		}
		g_iLevels  = --iLevel;
		for (new i = 1, j; i <= g_iLevels; i++)
		{
			for (j = 0; j < sizeof(sWeapons); j++)
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