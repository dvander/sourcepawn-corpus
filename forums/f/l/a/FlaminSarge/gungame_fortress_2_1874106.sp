#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <tf2_stocks>
#include <tf2items_giveweapon>
#include <morecolors>

#define PLUGIN_NAME		 	"GunGame Fortress 2"
#define PLUGIN_AUTHOR	   	"Erreur 500, fixes by FlaminSarge"
#define PLUGIN_DESCRIPTION	"GunGame for TF2"
#define PLUGIN_VERSION	  	"2.031"
#define PLUGIN_CONTACT	  	"erreur500@hotmail.fr"
#define FILENAME 			"gungame_levels.cfg"
#define MAX_LINE_WIDTH 		60

new bool:gg_Announcement[MAXPLAYERS+1] 		= { false, ... };
new bool:gg_AnnouncementFinal[MAXPLAYERS+1] = { false, ... };
new bool:EnterSound[MAXPLAYERS+1] 			= { false, ... };
new gg_iRank[MAXPLAYERS+1] 					= { 0, ... };
new AssisterRank[MAXPLAYERS+1] 				= { 0, ... };
new gg_iDeathCount[MAXPLAYERS+1] 			= { 0, ... };
new gg_iBonus[MAXPLAYERS+1] 				= { 0, ... };

new bool:EndTime 		= true;
new bool:Pause 			= false;

new Handle:c_level		= INVALID_HANDLE;
new Handle:c_ggmap		= INVALID_HANDLE;
new Handle:c_assister	= INVALID_HANDLE;
new Handle:cvarEnabled;
new Handle:clientCookie;

new String:currentmap[99];
new String:g_Filename[PLATFORM_MAX_PATH];
new String:classString[PLATFORM_MAX_PATH];
new item[PLATFORM_MAX_PATH];
new TFClassType:WeaponClass[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author	  	= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version	 	= PLUGIN_VERSION,
	url		 	= PLUGIN_CONTACT
};


public OnPluginStart()
{
	CreateConVar("gg_version", PLUGIN_VERSION, "GunGame version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled 	= CreateConVar("gg_enabled", "1", "Enable/disable GunGame Fortress 2", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_level 		= CreateConVar("gg_level", "26", "Number of levels/ranks", FCVAR_PLUGIN);
	c_ggmap 		= CreateConVar("gg_gungame_map", "1", "If 0, gg works on any map, else only on maps in gungame_maps.cfg", FCVAR_PLUGIN);
	c_assister 		= CreateConVar("gg_assist", "1", "Enable/disable assister rank", FCVAR_PLUGIN);
	RegAdminCmd("gg_reload", Cmd_ReloadLevels, ADMFLAG_ROOT);
	clientCookie = RegClientCookie("gg_numwins1", "Number of GunGame Fortress wins", CookieAccess_Protected);
	AutoExecConfig(true, "GunGame_Fortress2");
	
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("teamplay_round_win", EventRoundEnd);
	HookEvent("post_inventory_application", EventPlayerInventory);
	HookEvent("teamplay_round_active", EventRoundActive);
	HookEvent("teamplay_round_start", EventRoundStart);
}
public Action:Cmd_ReloadLevels(client, args)
{
	if (!LoadGGLevels())
	{
		ReplyToCommand(client, "[GGF2] Could not load levels config.");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[GGF2] Reloaded levels config. If number of ranks has changed, please set gg_level to new number of ranks and use gg_reload again.");
	return Plugin_Handled;
}
public bool:LoadGGLevels()
{
	new MaxRank = GetConVarInt(c_level);

	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/%s", FILENAME);
	if (!FileExists(g_Filename))
	{
		SetFailState("[GunGame Fortress 2] Could not find %s for level definitions, disabling plugin.", g_Filename);
		return false;
	}
	new Handle:kv = CreateKeyValues("GunGame Weapons");
	FileToKeyValues(kv, g_Filename);
	if (!KvGotoFirstSubKey(kv))
	{
		SetFailState("[GunGame Fortress 2] Could not read weapons file: %s", g_Filename);
		return false;
	}
	for (new i = 0; i <= MaxRank; i++)
	{
		KvGotoFirstSubKey(kv);
		KvGetString(kv, "class", classString, sizeof(classString));

		WeaponClass[i] = TF2_GetClass(classString);

		item[i] = KvGetNum(kv, "index", 0);

		KvGotoNextKey(kv);
	}
	CloseHandle(kv);
	LogMessage("GunGame Fortress 2 levels config %s loaded.", g_Filename);
	return true;
}
public OnConfigsExecuted()
{
	LoadGGLevels();
}

//Does not work
/*public Action:OnGetGameDescription(String:gameDesc[64])
{
	new bool:Enabled = GetConVarBool(cvarEnabled);
	new bool:EnabledMap = GetConVarBool(c_ggmap);

	if(Enabled && (IsGunGameMap() || !EnabledMap))
	{
		Format(gameDesc, sizeof(gameDesc), "GunGame Fortress 2");
		return Plugin_Changed;
	}
	else
	{
		Format(gameDesc, sizeof(gameDesc), "Team Fortress");
		return Plugin_Changed;
	}
}*/

public OnMapStart()
{
	new bool:Enabled = GetConVarBool(cvarEnabled);
	new bool:EnabledMap = GetConVarBool(c_ggmap);
	new bool:ggmap = IsGunGameMap(true);
	if (Enabled && (ggmap || !EnabledMap))
	{
		AddFileToDownloadsTable("sound/gungame_erreur_500/running.mp3");
		PrecacheSound("gungame_erreur_500/running.wav", true);
		AddFileToDownloadsTable("sound/gungame_erreur_500/level_up.wav");
		PrecacheSound("gungame_erreur_500/level_up.wav", true);
		AddFileToDownloadsTable("sound/gungame_erreur_500/level_down.wav");
		PrecacheSound("gungame_erreur_500/level_down.wav", true);
		AddFileToDownloadsTable("sound/gungame_erreur_500/bonus.wav");
		PrecacheSound("gungame_erreur_500/bonus.wav", true);
		AddFileToDownloadsTable("sound/gungame_erreur_500/warning.mp3");
		PrecacheSound("gungame_erreur_500/warning.mp3", true);

		GunGameReset();
		LogMessage("GunGame Fortress 2 Initialized.");
	}
	else
	{
		LogMessage("GunGame Fortress 2 is disabled!");
	}
}

public OnClientPutInServer(client)
{
	gg_Announcement[client] = false;
	gg_AnnouncementFinal[client] = false;
	gg_iRank[client] = 0;
	gg_iBonus[client] = 0;
	gg_iDeathCount[client] = 0;
	EnterSound[client] = false;
}

public Action:EventRoundActive(Handle:hEvent, const String:strName[], bool:bHidden)
{
	GunGameReset();
	if (Pause == true)
	{
		LogMessage("GunGame rank enabled!")
		CPrintToChatAll("{olive}[GG] {cyan}GunGame rank enabled!")
		Pause = false;
	}
	for(new a = 1; a < MaxClients; a++)
	{
		GunGameWeapons(a);
	}
	return Plugin_Continue;
}

public Action:EventRoundStart(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if (!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	if (GetConVarBool(c_ggmap) && !IsGunGameMap()) return Plugin_Continue;
	GunGameReset();
	Pause = false;
	for(new i = 1; i < MaxClients; i++)
	{
		GunGameWeapons(i);
	}
	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if (!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	if (GetConVarBool(c_ggmap) && !IsGunGameMap()) return Plugin_Continue;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return Plugin_Continue;
	if (!EnterSound[iClient])
	{
		EnterSound[iClient] = true;
		ClientCommand(iClient, "playgamesound gungame_erreur_500/running.mp3");
	}
	GunGameWeapons(iClient);
	UpdateHud(iClient);
	return Plugin_Continue;
}

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}

public Action:EventPlayerInventory(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if (!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	if (GetConVarBool(c_ggmap) && !IsGunGameMap()) return Plugin_Continue;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return Plugin_Continue;
	if (!IsPlayerAlive(iClient)) return Plugin_Continue;
	GunGameWeapons(iClient);

	return Plugin_Continue;
}

public Action:EventPlayerDeath(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if (!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	if (GetConVarBool(c_ggmap) && !IsGunGameMap()) return Plugin_Continue;
	if(!Pause)
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		new iKiller = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		if (!IsValidClient(iClient)) return Plugin_Continue;
		GunGameDeath(iClient);
		if (!gg_Announcement[iClient])
		{
			CPrintToChat(iClient, "{olive}[GG] {purple}GunGame Fortress 2{olive} by {gold}Erreur 500{olive}!");
			gg_Announcement[iClient] = true;
		}
		if (IsValidClient(iKiller) && iKiller != iClient) UpgradePlayer(iKiller);
		if(GetConVarBool(c_assister))
		{
			new iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));
			if (!IsValidClient(iAssister)) return Plugin_Continue;
			RankAssister(iAssister);
		}
	}
	return Plugin_Continue;
}

public Action:EventRoundEnd(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if (!GetConVarBool(cvarEnabled)) return;
	if (GetConVarBool(c_ggmap) && !IsGunGameMap()) return;
	Pause = true;

	if(EndTime == true)
	{
		LogMessage("Round end, without GunGame winner player.");
		LogMessage("GunGame ranking disabled: Waiting for round start.")
		CPrintToChatAll("{olive}[GG] {cyan}GunGame ranking disabled: Waiting for round start.")

		new iMax = GetHighestPlayerRank();
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if(gg_iRank[i] == iMax)
			{
				LogMessage("Check player(s) on max level ... ");
				AddToClientWinPoints(i);
				GunGameReset();
			}
		}
	}
}

stock bool:IsGunGameMap(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:isGGMap = false;
	if (forceRecalc)
	{
		isGGMap = false;
		found = false;
	}
	if (!found)
	{
		decl String:s[PLATFORM_MAX_PATH];
		GetCurrentMap(currentmap, sizeof(currentmap));
		BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/gungame_maps.cfg");
		if (!FileExists(s))
		{
			LogError("[GunGame Fortress 2] Unable to find %s, disabling plugin.", s);
			isGGMap = false;
			found = true;
			return false;
		}
		new Handle:fileh = OpenFile(s, "r");
		if (fileh == INVALID_HANDLE)
		{
			LogError("[GunGame Fortress 2] Error reading maps from %s, disabling plugin.", s);
			isGGMap = false;
			found = true;
			return false;
		}
		new loopbreak = 0;
		while (!IsEndOfFile(fileh) && ReadFileLine(fileh, s, sizeof(s)) && (loopbreak < 100))
		{
			loopbreak++;
			if (loopbreak >= 100)
				LogError("[GunGame Fortress 2] Breaking infinite loop when trying to check the map.");
			Format(s, strlen(s)-1, s);
			if (strncmp(s, "//", 2, false) == 0) continue;
			if ((StrContains(currentmap, s, false) != -1) || (StrContains(s, "all", false) == 0))
			{
				CloseHandle(fileh);
				isGGMap = true;
				found = true;
				return true;
			}
		}
		CloseHandle(fileh);
	}
	return isGGMap;
}
UpgradePlayer(iClient)
{
	if (!IsValidClient(iClient)) return;
	new MaxRank = GetConVarInt(c_level);
	if (gg_iRank[iClient] >= MaxRank+1) return;

	gg_iRank[iClient] += 1;
	ClientCommand(iClient, "playgamesound gungame_erreur_500/level_up.wav");
	GunGameWeapons(iClient);
	GunGameBonus(iClient);
	gg_iDeathCount[iClient] = 0;

	if (gg_iRank[iClient] == MaxRank && gg_AnnouncementFinal[iClient] == false)
	{
		gg_AnnouncementFinal[iClient] = true;
		CPrintToChatAllEx(iClient, "{olive}[GG] {yellow}Warning, {teamcolor}%N {purple}is on the last weapon level!", iClient);
		for (new Client = 1; Client <= MaxClients; Client++)
		{
			if (!IsClientInGame(Client)) continue;
			ClientCommand(Client, "playgamesound gungame_erreur_500/warning.mp3");
		}
	}
	else if (gg_iRank[iClient] < MaxRank)
	{

		CPrintToChat(iClient, "{olive}[GG] {purple}You upgraded to rank: {green}%d/%d", gg_iRank[iClient]+1, MaxRank+1);
		LogMessage("%N upgraded to rank: %d/%d", iClient, gg_iRank[iClient]+1, MaxRank+1);
		new iMax = GetHighestPlayerRank();
		if (gg_iRank[iClient] == iMax && GetNumPlayersAtRank(iMax) <= 1)
		{
		   CPrintToChatAllEx(iClient, "{olive}[GG] {purple}The leader is {teamcolor}%N {purple}with rank: {green}%d/%d", iClient, iMax+1, MaxRank+1);
		}
	}

	UpdateHud(iClient);

}

GunGameWeapons(iClient)
{
	if (!IsValidClient(iClient)) return;

	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if (iClass != WeaponClass[gg_iRank[iClient]])
	{
		if (WeaponClass[gg_iRank[iClient]] > TFClassType:0 && WeaponClass[gg_iRank[iClient]] < TFClassType:10)
		{
			new iHealth = GetClientHealth(iClient);
			TF2_SetPlayerClass(iClient, WeaponClass[gg_iRank[iClient]], false);
			TF2_RegeneratePlayer(iClient);
			if (iHealth < GetClientHealth(iClient)) SetEntityHealth(iClient, iHealth);
		}
		else
		{
			LogError("Client %d had invalid player class %d at rank %d, unable to rank up.", iClient, WeaponClass[gg_iRank[iClient]], gg_iRank[iClient]);
		}
	}
	TF2_RemoveAllWeapons(iClient);
	if(item[gg_iRank[iClient]] < 0 )
	{
		LogError("Client %d had invalid rank weapon %d at rank %d, unable to rank up.", iClient, item[gg_iRank[iClient]], gg_iRank[iClient]);
	}
	else 
	{
		TF2Items_GiveWeapon(iClient, item[gg_iRank[iClient]]);
		TF2_RemoveCondition(iClient, TFCond_Zoomed);
		TF2_RemoveCondition(iClient, TFCond_Slowed);
		decl String:classname[64];
		for (new i = TFWeaponSlot_Primary; i <= TFWeaponSlot_Melee; i++)
		{
			new wep = GetPlayerWeaponSlot(iClient, i);
			if (wep > MaxClients && IsValidEntity(wep) && GetEntityClassname(wep, classname, sizeof(classname)) && strncmp(classname, "tf_weapon_", 10, false) == 0)
			{
				SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", wep);
				break;
			}
		}
	}
}

GetNumPlayersAtRank(iValue)
{
	new iCount = 0;
	for (new i = 0; i <= MaxClients; i++)
	{
		if (gg_iRank[i] == iValue)
		{
			iCount++;
		}
	}
	return iCount;
}

GetHighestPlayerRank()
{
	new iMax = -1;
	for (new i = 0; i <= MaxClients; i++)
	{
		if (gg_iRank[i] > iMax)
		{
			iMax = gg_iRank[i];
		}
	}
	return iMax;
}

RankAssister(iClient)
{
	if (!IsValidClient(iClient)) return 0;
	AssisterRank[iClient] += 1;
	if(AssisterRank[iClient] == 2)
	{
		CPrintToChat(iClient, "{olive}[GG] {purple}Your assisting rank is {green}2/2.");
		AssisterRank[iClient] = 0;
		UpgradePlayer(iClient);
	}
	else
	{
		CPrintToChat(iClient, "{olive}[GG] {purple}Your assisting rank is {green}1/2. {cyan}You need {green}1 {cyan}more kill assist to rank up!");
	}
	return AssisterRank[iClient];
}

GunGameDeath(iClient)
{
	gg_iDeathCount[iClient]++;
	gg_iBonus[iClient] = 0;
	if (gg_iDeathCount[iClient] >= 5)
	{
		gg_iDeathCount[iClient] = 0;
		if (gg_iRank[iClient] > 0)
		{
			gg_iRank[iClient] -= 1;
			new MaxRank = GetConVarInt(c_level);
			ClientCommand(iClient, "playgamesound gungame_erreur_500/level_down.wav");
			CPrintToChat(iClient, "{olive}[GG] {red}You've downgraded to rank: {green}%d/%d {red}for dying five times without a kill.", gg_iRank[iClient]+1, MaxRank+1);
			LogMessage("%N downgraded to: %d/%d", iClient, gg_iRank[iClient]+1, MaxRank+1);
		}
	}
}

GunGameBonus(iClient)
{
	gg_iBonus[iClient] += 1;
	if (gg_iDeathCount[iClient] == 0 && gg_iBonus[iClient] == 5)
	{
		CPrintToChat(iClient, "{olive}[GG] {orange}Five kill bonus! {green}+200 health!");
		LogMessage("%N win the bonus.", iClient);
		ClientCommand(iClient, "playgamesound gungame_erreur_500/bonus.wav");
		SetEntityHealth(iClient, 200);
		gg_iBonus[iClient] = 0;
	}
}

UpdateHud(iClient)
{
	if (!IsValidClient(iClient)) return;
	if (IsFakeClient(iClient)) return;
	new MaxRank = GetConVarInt(c_level);
	if (gg_iRank[iClient] >= MaxRank+1)
	{
		new Team = GetClientTeam(iClient);
		EndTime = false;
		CPrintToChat(iClient,"{olive}[GG] {lime}You're the winner!");
		PrintCenterText(iClient, "The winner is: %N!", iClient);
		PrintHintText(iClient, "The winner is: %N!", iClient);
		LogMessage("%N is the winner.", iClient);
		AddToClientWinPoints(iClient);

		if (Team == _:TFTeam_Red)
		{
			new Ent_RedWin = CreateEntityByName("game_round_win");
			if(Ent_RedWin != -1)
			{
				DispatchSpawn(Ent_RedWin);
				DispatchKeyValue(Ent_RedWin, "Team", "2");
				DispatchKeyValue(Ent_RedWin, "force_map_reset", "1");
				AcceptEntityInput(Ent_RedWin, "RoundWin");
			}

		}
		else if (Team == _:TFTeam_Blue)
		{
			new Ent_BlueWin = CreateEntityByName("game_round_win");
			if(Ent_BlueWin != -1)
			{
				DispatchSpawn(Ent_BlueWin);
				DispatchKeyValue(Ent_BlueWin, "Team", "3");
				DispatchKeyValue(Ent_BlueWin, "force_map_reset", "1");
				AcceptEntityInput(Ent_BlueWin, "RoundWin");
			}
		}
		GunGameReset();
	}

}

stock AddToClientWinPoints(client)
{
	if (!IsValidClient(client)) return;
	new points = 0;
	decl String:oldpts[64];
	if (!IsFakeClient(client) && AreClientCookiesCached(client))
	{
		GetClientCookie(client, clientCookie, oldpts, sizeof(oldpts));
		points = StringToInt(oldpts);
		points += 1;
		IntToString(points, oldpts, sizeof(oldpts));
		SetClientCookie(client, clientCookie, oldpts);
	}
	if (points <= 1) CPrintToChatAllEx(client, "{olive}[GG] {orange}The winner is: {teamcolor}%N{orange}, as their first victory!", client);
	else CPrintToChatAllEx(client, "{olive}[GG] {orange}The winner is: {teamcolor}%N{orange}, with %d wins total!", client, points);
	LogMessage("%N victory, wins: %d.", client, points);

}

public OnMapEnd()
{
	GunGameReset();
}

GunGameReset()
{
	EndTime = true;
	for(new iClnt = 0; iClnt <= MaxClients; iClnt++)
	{
		gg_Announcement[iClnt] = false;
		gg_AnnouncementFinal[iClnt] = false;
		gg_iRank[iClnt] = 0;
		gg_iBonus[iClnt] = 0;
		gg_iDeathCount[iClnt] = 0;
	}
	LogMessage("GunGame reset.");
}