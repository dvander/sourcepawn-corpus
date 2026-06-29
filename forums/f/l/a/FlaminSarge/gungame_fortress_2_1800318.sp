#include <sourcemod>
#include <tf2items_giveweapon>
#include <sdktools>
#include <tf2_stocks>
#include <morecolors>
#include <clientprefs>

#define PLUGIN_NAME		 "GunGame Fortress 2"
#define PLUGIN_AUTHOR	   "Erreur 500, fixes by FlaminSarge"
#define PLUGIN_DESCRIPTION	"GunGame mod, like GunGame in CS:S but for Team Fortress 2"
#define PLUGIN_VERSION	  "2.011"
#define PLUGIN_CONTACT	  "erreur500@hotmail.fr"
#define FILENAME 			"gungame_levels.cfg"
#define MAX_LINE_WIDTH 		60

new bool:gg_Announcement[MAXPLAYERS+1] 		= { false, ... };
new bool:gg_AnnouncementFinal[MAXPLAYERS+1] = { false, ... };
new bool:FirstRespawn[MAXPLAYERS+1] 			= { true, ... };
new bool:EnterSound[MAXPLAYERS+1] 			= { false, ... };
new gg_iRank[MAXPLAYERS+1] 					= { 0, ... };
new AssisterRank[MAXPLAYERS+1] 				= { 0, ... };
new gg_iDeathCount[MAXPLAYERS+1] 			= { 0, ... };
new gg_iBonus[MAXPLAYERS+1] 				= { 0, ... };

new bool:EndTime 		= true;
new bool:First 			= true;
new bool:Pause 			= false;
new bool:RoundEnd 		= false;

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
	author	  = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version	 = PLUGIN_VERSION,
	url		 = PLUGIN_CONTACT
};


public OnPluginStart()
{
	CreateConVar("gg_version", PLUGIN_VERSION, "GunGame version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled 	= CreateConVar("gg_enabled", "1", "Enable or disable GunGame Fortress 2 ?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_level 		= CreateConVar("gg_level", "26", "Number of level", FCVAR_PLUGIN);
	c_ggmap 		= CreateConVar("gg_gungame_map", "1", "Work only in GunGame map (gg_ and dm_)", FCVAR_PLUGIN);
	c_assister 		= CreateConVar("gg_assist", "1", "Enable or disable assister rank ?", FCVAR_PLUGIN);

	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/%s", FILENAME);
	clientCookie = RegClientCookie("gg_numwins1", "Number of GunGame Fortress wins", CookieAccess_Protected);
	AutoExecConfig(true, "GunGame_Fortress2");
}

public OnConfigsExecuted()
{
	PrintToServer("[GunGame_Fortress2] Configs loaded");
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
	if(Enabled && (IsGunGameMap() || !EnabledMap))
	{
		HookEvent("player_spawn", EventPlayerSpawn);
		HookEvent("player_death", EventPlayerDeath);
		HookEvent("teamplay_round_win", EventRoundEnd);
		HookEvent("post_inventory_application", EventPlayerInventory);
		HookEvent("teamplay_waiting_ends", EventWaitingEnds);
		HookEvent("teamplay_round_active", EventRoundActive);
		HookEvent("teamplay_round_start", EventRoundStart);
		HookEvent("teamplay_setup_finished", EventSetupFinished);

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

		PrintToServer("[GunGame_Fortress2] Initialized");
		LogMessage("GunGame Fortress 2 Initialized.");
	}
	else
	{
		LogMessage("GunGame Fortress 2 disable !");
	}
}

public OnClientPutInServer(client)
{
	gg_Announcement[client] = false;
	gg_AnnouncementFinal[client] = false;
	gg_iRank[client] = 0;
	gg_iBonus[client] = 0;
	gg_iDeathCount[client] = 0;
	FirstRespawn[client] = true;
	EnterSound[client] = false;
}

public Action:EventRoundActive(Handle:hEvent, const String:strName[], bool:bHidden)
{
	GunGameReset();
	Pause = false;
	if (RoundEnd == true)
	{
		LogMessage("GunGame rank enabled !")
		CPrintToChatAll("{olive}[GG]{default} {cyan}GunGame rank enabled !")
		RoundEnd = false;
	}
	for(new a = 1; a < MaxClients; a++)
	{
		GunGameWeapons(a);
	}
	return Plugin_Continue;
}

public Action:EventWaitingEnds(Handle:hEvent, const String:strName[], bool:bHidden)
{
	GunGameReset();
	for(new i = 1; i < MaxClients; i++)
	{
		GunGameWeapons(i);
	}
	return Plugin_Continue;
}

public Action:EventRoundStart(Handle:hEvent, const String:strName[], bool:bHidden)
{
	GunGameReset();
	Pause = false;
	for(new i = 1; i < MaxClients; i++)
	{
		GunGameWeapons(i);
	}
	return Plugin_Continue;
}

public Action:EventSetupFinished(Handle:hEvent, const String:strName[], bool:bHidden)
{
	GunGameReset();
	for(new a = 1; a < MaxClients; a++)
	{
		GunGameWeapons(a);
	}
	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return Plugin_Continue;
	if (!EnterSound[iClient])
	{
		EnterSound[iClient] = true;
		ClientCommand(iClient, "playgamesound gungame_erreur_500/running.mp3");
	}
	if( FirstRespawn[iClient] == true)
	{
		gg_iRank[iClient] = 0;
		FirstRespawn[iClient] = false;
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
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return Plugin_Continue;
	if (!IsPlayerAlive(iClient)) return Plugin_Continue;
	GunGameWeapons(iClient);

	return Plugin_Continue;
}

public Action:EventPlayerDeath(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if(!Pause)
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		new iKiller = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		if (!IsValidClient(iClient)) return Plugin_Continue;
		GunGameDeath(iClient);
		if (!gg_Announcement[iClient])
		{
			CPrintToChat(iClient, "{olive}[GG]{default} {olive}Good Game with {purple}GunGame Fortress 2{olive} by {gold}Erreur 500 {olive}!");
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
	Pause = true;
	RoundEnd = true;

	if(EndTime == true)
	{
		LogMessage("Round end, without GunGame winner player.");
		LogMessage("GunGame rank bloked : Waiting round start .")
		CPrintToChatAll("{olive}[GG]{default} {cyan}GunGame rank blocked : Waiting round start .")

		new iMax = GetMaxRank();
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

stock bool:IsGunGameMap()
{
	decl Handle:fileh;
	decl String:s[PLATFORM_MAX_PATH];
	GetCurrentMap(currentmap, sizeof(currentmap));
	BuildPath(Path_SM, s, PLATFORM_MAX_PATH, "configs/gungame_maps.cfg");
	if (!FileExists(g_Filename))
	{
		LogError("[GunGame_Fortress2] Is not running! Could not find file gungame_maps.cfg");
		SetFailState("Could not find file gungame_maps.cfg");
	}
	fileh = OpenFile(s, "r");
	new pingas = 0;
	while (ReadFileLine(fileh, s, sizeof(s)) && (pingas < 100))
	{
		pingas++;
		if (pingas == 100)
			LogError("[GunGame Fortress2] Breaking infinite loop when trying to check the map.");
		Format(s, strlen(s)-1, s);
		if ((StrContains(currentmap, s, false) != -1) || (StrContains(s, "all", false) == 0))
		{
			CloseHandle(fileh);
			return true;
		}
	}
	CloseHandle(fileh);
	return false;
}

UpgradePlayer(iClient)
{
	if (!IsValidClient(iClient)) return;
	new MaxRank = GetConVarInt(c_level);
	if (gg_iRank[iClient] >= MaxRank) return;

	gg_iRank[iClient] += 1;
	ClientCommand(iClient, "playgamesound gungame_erreur_500/level_up.wav");
	GunGameWeapons(iClient);
	GunGameBonus(iClient);
	gg_iDeathCount[iClient] = 0;

	if (gg_iRank[iClient] == MaxRank-1 && gg_AnnouncementFinal[iClient] == false)
	{
		gg_AnnouncementFinal[iClient] = true;
		CPrintToChatAllEx(iClient, "{olive}[GG]{default} {maroon}Be careful,{teamcolor} %N {maroon} is on last level!!", iClient);
		for (new Client = 1; Client <= MaxClients; Client++)
		{
			if (!IsClientInGame(Client)) continue;
			ClientCommand(Client, "playgamesound gungame_erreur_500/warning.mp3");
		}
	}
	else if (gg_iRank[iClient] < MaxRank)
	{

		CPrintToChat(iClient, "{olive}[GG]{default} {olive}You upgraded to rank: {green}%d/%d", gg_iRank[iClient]+1, MaxRank);
		LogMessage("%N upgraded to rank: %d/%d", iClient, gg_iRank[iClient]+1, MaxRank);
		new iMax = GetMaxRank();
		if (gg_iRank[iClient] == iMax && GetRankCount(iMax) <= 1)
		{
		   CPrintToChatAllEx(iClient, "{olive}[GG]{default} {olive}The leader is {teamcolor}%N{olive} with rank {green} %d", iClient, iMax+1);
		}
	}

	UpdateHud(iClient);

}

GunGameWeapons(iClient)
{
	if (!IsValidClient(iClient)) return true;
	new MaxRank = GetConVarInt(c_level);

	if(First)
	{
		if (!FileExists(g_Filename))
		{
			LogError("[GunGame_Fortress2] Is not running! Could not find file %s", FILENAME);
			SetFailState("Could not find file %s", FILENAME);
		}
		new Handle:kv = CreateKeyValues("GunGame Weapons");

		FileToKeyValues(kv, g_Filename);

		if (!KvGotoFirstSubKey(kv))
		{
			SetFailState("Could not read weapons file: %s", g_Filename);
		}

		for (new i = 0; i <= MaxRank; i++)
		{
			KvGotoFirstSubKey(kv);
			KvGetString(kv, "class", classString, sizeof(classString));

			WeaponClass[i] = TF2_GetClass(classString);

			item[i] = KvGetNum(kv, "index", 0);

			KvGotoNextKey(kv);

			First = false;
		}
	}

	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if (iClass != WeaponClass[gg_iRank[iClient]])
	{
		new iHealth = GetClientHealth(iClient);
		TF2_SetPlayerClass(iClient, WeaponClass[gg_iRank[iClient]], false);
		TF2_RegeneratePlayer(iClient);
		if (iHealth < GetClientHealth(iClient)) SetEntityHealth(iClient, iHealth);
	}
	TF2_RemoveAllWeapons(iClient);
	TF2Items_GiveWeapon(iClient, item[gg_iRank[iClient]]);

	return MaxRank;
}

GetRankCount(iValue)
{
	new iCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (gg_iRank[i] == iValue)
		{
			iCount++;
		}
	}
	return iCount;
}

GetMaxRank()
{
	new iMax = -1;
	for (new i = 1; i <= MaxClients; i++)
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
		CPrintToChat(iClient, "{olive}[GG]{default} {olive}Your assister rank is {green}2/2");
		AssisterRank[iClient] = 0;
		UpgradePlayer(iClient);
	}
	else
	{
		CPrintToChat(iClient, "{olive}[GG]{default} {olive}Your assister rank is {green}1/2.{cyan} Need {green}1{cyan} more assister kill for upgrade !");
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
			CPrintToChat(iClient, "{olive}[GG]{default} {red}You've downgraded to:{green} %d/%d{red},{black} for 5 deads and never kill ! ", gg_iRank[iClient]+1, MaxRank);
			LogMessage("%N downgraded to: %d/%d", iClient, gg_iRank[iClient]+1, MaxRank);
		}
	}
}

GunGameBonus(iClient)
{
	gg_iBonus[iClient] += 1;
	if (gg_iDeathCount[iClient] == 0 && gg_iBonus[iClient] == 5)
	{
	CPrintToChat(iClient, "{olive}[GG]{default} {orange}Bonus, 5 kills in a row : {green}+200 healts !");
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
	if (gg_iRank[iClient] >= MaxRank)
	{
		new Team = GetClientTeam(iClient);
		EndTime = false;
		CPrintToChat(iClient,"{olive}[GG]{default} {lime}You're the winner!");
		PrintCenterText(iClient, "The winner is: %N!!", iClient);
		PrintHintText(iClient, "The winner is: %N!!", iClient);
		LogMessage("%N is the winner, adding points", iClient);
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
	if (points <= 1) CPrintToChatAllEx(client, "{olive}[GG]{default} {orange}The winner is: {teamcolor}%N{orange}. This is their {green}first {orange}victory!", client);
	else CPrintToChatAllEx(client, "{olive}[GG]{default} {orange}The winner is: {teamcolor}%N{orange}. They've won {green}%d {orange}times!!", client, points);
	LogMessage("%N victory, wins: %d.", client, points);

}
public Action:Load_Sounds(Handle:timer)
{
	Pause = false;
}

public OnMapEnd()
{
	UnhookEvent("player_spawn", EventPlayerSpawn);
	UnhookEvent("player_death", EventPlayerDeath);
	UnhookEvent("teamplay_round_win", EventRoundEnd);
	UnhookEvent("post_inventory_application", EventPlayerInventory);
	UnhookEvent("teamplay_waiting_ends", EventWaitingEnds);
	UnhookEvent("teamplay_round_active", EventRoundActive);
	UnhookEvent("teamplay_round_start", EventRoundStart);
	UnhookEvent("teamplay_setup_finished", EventSetupFinished);
	GunGameReset();
}

GunGameReset()
{
	EndTime = true;
	First = true;
	for(new iClnt = 1; iClnt <= MaxClients; iClnt++)
	{
		gg_Announcement[iClnt] = false;
		gg_AnnouncementFinal[iClnt] = false;
		gg_iRank[iClnt] = 0;
		gg_iBonus[iClnt] = 0;
		gg_iDeathCount[iClnt] = 0;
		FirstRespawn[iClnt] = true;
	}
	LogMessage("GunGame reset.");
}