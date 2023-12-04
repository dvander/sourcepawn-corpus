//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - TK Revenge
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - TK Revenge",
	author = "FeuerSturm, modif Micmacx",
	description = "Auto TK Revenge Addon for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:TKRStatus = INVALID_HANDLE
new Handle:TKRUseForgiveMenu = INVALID_HANDLE
new Handle:TKRForgiveMenuLayout = INVALID_HANDLE
new Handle:TKRForgiveMenuTime = INVALID_HANDLE
new Handle:TKRRespawnSlay = INVALID_HANDLE
new Handle:TKRMaxTKs = INVALID_HANDLE
new Handle:TKRAction = INVALID_HANDLE
new Handle:TKRTAEqTK = INVALID_HANDLE
new Handle:TKRSpawnTA = INVALID_HANDLE
new Handle:TKRSpawnArea = INVALID_HANDLE
new Handle:TKRMeleeTA = INVALID_HANDLE
new Handle:TKRSlayFX = INVALID_HANDLE
new Handle:TKRAdminAutoSorry = INVALID_HANDLE
new Handle:TKRNoVictimDeath = INVALID_HANDLE
new Handle:TKRShowTKCount = INVALID_HANDLE
new Handle:TKRSpawnTKCount = INVALID_HANDLE
new Handle:TKRMeleeTKCount = INVALID_HANDLE
new Handle:TKRRampageTKCount = INVALID_HANDLE
new Handle:TKRRampageTime = INVALID_HANDLE
new Handle:TKRGrenadeTKCount = INVALID_HANDLE
new Handle:TKRKarmaReduceTK = INVALID_HANDLE
new Handle:TKRScoreKarma = INVALID_HANDLE
new Handle:TKRKillKarma = INVALID_HANDLE
new Handle:TKRMaxPrevKick = INVALID_HANDLE
new Handle:TKRMaxPrevKickBT = INVALID_HANDLE
new Handle:TKRMaxPrevBan = INVALID_HANDLE
new Handle:TKRSaveTKs = INVALID_HANDLE
new Handle:TKRBanTime = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new String:TKRFile[] = { "cfg/dod_teammanager_source/dod_tms_tkfile.cfg" }
new Handle:CreateTKRFile = INVALID_HANDLE
new String:WLFeature[] = { "tkrevenge" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]
new Float:LastTimeTK[MAXPLAYERS+1]
new PrevKicks[MAXPLAYERS+1]
new PrevBans[MAXPLAYERS+1]
new bool:TKKicked[MAXPLAYERS+1]
new bool:TKPreKickBanned[MAXPLAYERS+1]
new bool:TKPreBanBanned[MAXPLAYERS+1]
new bool:TKBanned[MAXPLAYERS+1]
new TKCount[MAXPLAYERS+1]
new TACount[MAXPLAYERS+1]
new KarmaCount[MAXPLAYERS+1]
new TeamKiller[MAXPLAYERS+1]
new RespawnSlay[MAXPLAYERS+1]

public OnPluginStart()
{
	TKRStatus = CreateConVar("dod_tms_tkrevenge", "1", "<1/0> = enable/disable TK Revenge Addon", _, true, 0.0, true, 1.0)
	TKRUseForgiveMenu = CreateConVar("dod_tms_tkrenabletkmenu", "1", "<1/0> = enable/disable displaying a Menu with punishments on TK", _, true, 0.0, true, 1.0)
	ClientImmunity = CreateConVar("dod_tms_tkrimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions", _, true, 0.0, true, 1.0)
	TKRSaveTKs = CreateConVar("dod_tms_tkrsavetks", "1", "<1/0> = enable/disable saving player's TK count to file and load it on next connection", _, true, 0.0, true, 1.0)
	TKRBanTime = CreateConVar("dod_tms_tkrbantime", "1440", "<#/0> = set time in minutes to ban team killers  -  0 = permanent", _, true, 0.0)
	TKRMaxTKs = CreateConVar("dod_tms_tkrmaxtkcount", "6", "<#> = set max TK count for kicking/banning", _, true, 1.0, true, 12.0)
	TKRTAEqTK = CreateConVar("dod_tms_tkrtasequaltk", "10", "<#> = set number of TAs that count as a TK", _, true, 1.0, true, 20.0)
	TKRSpawnTKCount = CreateConVar("dod_tms_tkrspawntkcount", "3", "<#> = set number of TKs that are added to the count for spawn TKs", _, true, 1.0, true, 5.0)
	TKRSpawnArea = CreateConVar("dod_tms_tkrspawnarea", "800", "<#> = set size of player's spawn area", _, true, 400.0, true, 1000.0)
	TKRMeleeTKCount = CreateConVar("dod_tms_tkrmeleetkcount", "2", "<#> = set number of TKs that are added to the count for melee TKs", _, true, 1.0, true, 5.0)
	TKRRampageTKCount = CreateConVar("dod_tms_tkrrampagetkcount", "3", "<0/#> = set number of TKs that are added to the count for continued TKing within X seconds  -  0 = disable rampage check", _, true, 0.0, true, 5.0)
	TKRRampageTime = CreateConVar("dod_tms_tkrrampagetimespan", "10", "<#> = time in seconds that continuous TKing counts as Rampage", _, true, 0.0, true, 15.0)
	TKRMaxPrevKick = CreateConVar("dod_tms_tkrkickstoban", "2", "<#> = set number of previous Kicks that result in a temp Ban", _, true, 2.0, true, 5.0)
	TKRMaxPrevKickBT = CreateConVar("dod_tms_tkrkickstobantime", "10080", "<#> = time in minutes to ban Xtimes kicked TeamKillers", _, true, 1.0)
	TKRMaxPrevBan = CreateConVar("dod_tms_tkrbanstopermban", "2", "<#> = set number of previous temp Bans that result in a permanent Ban", _, true, 2.0, true, 10.0)
	TKRAction = CreateConVar("dod_tms_tkraction", "1", "<0/1> = action to take when max TK count is reached  -  0 = kick  -  1 = ban", _, true, 0.0, true, 1.0)
	TKRSpawnTA = CreateConVar("dod_tms_tkrspawntaaction", "3", "<0/1/2/3> = action to take for SpawnTAs/TKs  -  0 = disabled  -  1 = slay attacker  -  2 = slay attacker & health for victim  -  3 = mirror damage  -  4 = only health for victim", _, true, 0.0, true, 4.0)
	TKRMeleeTA = CreateConVar("dod_tms_tkrmeleetaaction", "3", "<0/1/2/3> = action to take for MeleeTAs/TKs  -  0 = disabled  -  1 = slay attacker  -  2 = slay attacker & health for victim  -  3 = mirror damage -  4 = only health for victim", _, true, 0.0, true, 4.0)
	TKRGrenadeTKCount = CreateConVar("dod_tms_tkrcountnadetks", "1", "<1/0> = count grenade TKs as normal TKs  -  1 = raise TK count  -  0 = ignore grenade TKs", _, true, 0.0, true, 1.0)
	TKRKarmaReduceTK = CreateConVar("dod_tms_tkrkarmareducetk", "10", "<#> = set number of KarmaPoints to reduce the TK count by one", _, true, 1.0)
	TKRScoreKarma = CreateConVar("dod_tms_tkrscorekarma", "2", "<#> = set number of KarmaPoints to add for fulfilling objectives", _, true, 1.0)
	TKRKillKarma = CreateConVar("dod_tms_tkrkillkarma", "1", "<#> = set number of KarmaPoints to add for killing enemies", _, true, 1.0)
	TKRSlayFX = CreateConVar("dod_tms_tkrslayfx", "1", "<1/0> = enable/disable explosion sound/effects for slaying players", _, true, 0.0, true, 1.0)
	TKRShowTKCount = CreateConVar("dod_tms_tkrshowtkcount", "1", "<1/0> = enable/disable showing team killer's TK count on increase/decrease", _, true, 0.0, true, 1.0)
	TKRNoVictimDeath = CreateConVar("dod_tms_tkrnovictimdeath", "1", "<1/0> = enable/disable removing deaths caused by TKs from the scoreboard", _, true, 0.0, true, 1.0)
	TKRAdminAutoSorry = CreateConVar("dod_tms_tkradminsorry", "1", "<1/0> = enable/disable making admins automatically saying 'Sorry' for TKs", _, true, 0.0, true, 1.0)
	TKRForgiveMenuLayout = CreateConVar("dod_tms_tkrtkmenulayout", "abcd", "<options> = define TK Menu Layout:  a = Forgive! - b = DON'T Forgive! - c = Slap to 1hp! - d = Slay!", _)
	TKRForgiveMenuTime = CreateConVar("dod_tms_tkrtkmenutime", "20", "<#/0> = time in seconds the menu stays open until an automatic choice is made  -  0 = stay open until manual choice", _, true, 0.0, true, 60.0)
	TKRRespawnSlay = CreateConVar("dod_tms_tkrrespawnslay", "1", "<1/0> = enable/disable slaying team killer after respawn if 'Slay!' was chosen on dead player", _, true, 0.0, true, 1.0)
	HookEventEx("dod_stats_player_damage", OnPlayerDamage, EventHookMode_Post)
	HookEventEx("dod_stats_player_killed", OnPlayerDeath, EventHookMode_Post)
	HookEventEx("dod_point_captured", OnPointCaptured, EventHookMode_Post)
	HookEventEx("dod_capture_blocked", OnCaptureBlocked, EventHookMode_Post)
	HookEventEx("dod_bomb_planted", OnBombScore, EventHookMode_Post)
	HookEventEx("dod_bomb_exploded", OnBombScore, EventHookMode_Post)
	HookEventEx("dod_bomb_defused", OnBombScore, EventHookMode_Post)
	HookEventEx("dod_kill_planter", OnBombKill, EventHookMode_Post)
	HookEventEx("dod_kill_defuser", OnBombKill, EventHookMode_Post)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	HookEventEx("player_death", OnPlayerKilled, EventHookMode_Pre)
	AutoExecConfig(true,"addon_dodtms_tkrevenge", "dod_teammanager_source")
	LoadTranslations("dodtms_tkrevenge.txt")
	if(!FileExists(TKRFile, true))
	{
		CreateTKRFile = OpenFile(TKRFile, "a")
		if(CreateTKRFile != INVALID_HANDLE)
		{
			WriteFileString(CreateTKRFile, "\"DoDTMS_TKFile\"\r{\r}", false)
			CloseHandle(CreateTKRFile)
		}
	}
}

public OnAllPluginsLoaded()
{
	CreateTimer(1.0, DoDTMSRunning)
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("J")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_tkrevenge.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public OnClientDisconnect(client)
{	
	if(!IsClientImmune(client) && GetConVarInt(TKRSaveTKs) == 1 && TKCount[client] != 0)
	{
		decl String:steamid[64]
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid))
		SaveTKCount(client, steamid)
	}
	for(new i = 1; i <= MaxClients; i++)
	{
		if(TeamKiller[i] == client)
		{
			TeamKiller[i] = 0
		}
		if(RespawnSlay[i] == client)
		{
			RespawnSlay[i] = 0
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(TMSIsWhiteListed(client, WLFeature))
	{
		IsWhiteListed[client] = true
	}
	else
	{
		IsWhiteListed[client] = false
	}
	if(TMSIsBlackListed(client, WLFeature))
	{
		IsBlackListed[client] = true
	}
	else
	{
		IsBlackListed[client] = false
	}
	TKCount[client] = 0
	if(!IsClientImmune(client))
	{
		LoadTKCount(client)
	}
	TKKicked[client] = false
	TKPreKickBanned[client] = false
	TKPreBanBanned[client] = false
	TKBanned[client] = false
	KarmaCount[client] = 0
	TACount[client] = 0
	RespawnSlay[client] = 0
	LastTimeTK[client] = 0.0
	TeamKiller[client] = 0
	if(TKCount[client] != 0 && GetConVarInt(FindConVar("mp_friendlyfire")) != 0)
	{
		decl String:message[256]
		Format(message, sizeof(message), "%T", "TKCount Loaded", client, TKCount[client])
		TMSMessage(client, message)
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(TKRStatus) == 0)
	{
		return Plugin_Continue
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientImmune(client) || GetClientTeam(client) < 2 || RespawnSlay[client] == 0)
	{
		return Plugin_Continue
	}
	CreateTimer(0.1, TKSlay, client, TIMER_FLAG_NO_MAPCHANGE)
	decl String:message[256]
	Format(message, sizeof(message), "%T", "TK VictimSlayed", client, RespawnSlay[client])
	TMSMessage(client, message)
	RespawnSlay[client] = 0
	return Plugin_Continue
}

public Action:DisplayTKRevengeMenu(victim, attacker)
{
	new Handle:TKRevengeMenu = CreateMenu(Handle_TKRevengeMenu)
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "[DoD TMS] TK Revenge\n \nKiller: %N\n ", attacker)
	SetMenuTitle(TKRevengeMenu, menutitle)
	decl String:TKInfo[256]
	decl String:menulayout[64]
	GetConVarString(TKRForgiveMenuLayout, menulayout, sizeof(menulayout))
	if(StrContains(menulayout, "a", false) != -1)
	{
		Format(TKInfo, sizeof(TKInfo), "%T", "TK MenuForgive", victim)
		AddMenuItem(TKRevengeMenu, "tkr_Forgive", TKInfo, ITEMDRAW_DEFAULT)
	}
	if(StrContains(menulayout, "b", false) != -1)
	{
		Format(TKInfo, sizeof(TKInfo), "%T", "TK MenuDontForgive", victim)
		AddMenuItem(TKRevengeMenu, "tkr_DontForgive", TKInfo, ITEMDRAW_DEFAULT)
	}
	if(StrContains(menulayout, "c", false) != -1)
	{
		Format(TKInfo, sizeof(TKInfo), "%T", "TK MenuSlap", victim)
		AddMenuItem(TKRevengeMenu, "tkr_Slap", TKInfo, ITEMDRAW_DEFAULT)
	}
	if(StrContains(menulayout, "d", false) != -1)
	{
		Format(TKInfo, sizeof(TKInfo), "%T", "TK MenuSlay", victim)
		AddMenuItem(TKRevengeMenu, "tkr_Slay", TKInfo, ITEMDRAW_DEFAULT)
	}
	SetMenuExitButton(TKRevengeMenu, false)
	SetMenuExitBackButton(TKRevengeMenu, false)
	if(GetConVarInt(TKRForgiveMenuTime) == 0)
	{
		DisplayMenu(TKRevengeMenu, victim, MENU_TIME_FOREVER)
	}
	else
	{
		DisplayMenu(TKRevengeMenu, victim, GetConVarInt(TKRForgiveMenuTime))
		
	}
}

public Handle_TKRevengeMenu(Handle:TKRevengeMenu, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		decl String:message[256]
		if(TeamKiller[client] == 0 || !IsClientInGame(TeamKiller[client]) || IsClientInKickQueue(TeamKiller[client]))
		{
			Format(message, sizeof(message), "%T", "TK KillerGone", client, client)
			TMSMessage(client, message)
			return
		}
		decl String:menuchoice[256]
		GetMenuItem(TKRevengeMenu, itemNum, menuchoice, sizeof(menuchoice))
		if(strcmp(menuchoice, "tkr_Forgive", true) == 0)
		{
			Format(message, sizeof(message), "%T", "TK YouForgave", client, TeamKiller[client])
			TMSMessage(client, message)
			Format(message, sizeof(message), "%T", "TK VictimForgave", TeamKiller[client], client)
			TMSMessage(TeamKiller[client], message)
			TeamKiller[client] = 0
			return
		}
		else if(strcmp(menuchoice, "tkr_DontForgive", true) == 0)
		{
			Format(message, sizeof(message), "%T", "TK YouNotForgave", client, TeamKiller[client])
			TMSMessage(client, message)
			Format(message, sizeof(message), "%T", "TK VictimNotForgave", TeamKiller[client], client)
			TMSMessage(TeamKiller[client], message)
			TKCount[TeamKiller[client]]++
			CheckTKCount(TeamKiller[client])
			TeamKiller[client] = 0
			return
		}
		else if(strcmp(menuchoice, "tkr_Slap", true) == 0)
		{
			if(IsPlayerAlive(TeamKiller[client]))
			{
				Format(message, sizeof(message), "%T", "TK YouSlapped", client, TeamKiller[client])
				TMSMessage(client, message)
				Format(message, sizeof(message), "%T", "TK VictimSlapped", TeamKiller[client], client)
				TMSMessage(TeamKiller[client], message)
				SetEntityHealth(TeamKiller[client], 1)
				SlapPlayer(TeamKiller[client], 0, true)
			}
			else
			{
				Format(message, sizeof(message), "%T", "TK KillerDead", client, TeamKiller[client])
				TMSMessage(client, message)
			}
			TeamKiller[client] = 0
			return
		}
		else if(strcmp(menuchoice, "tkr_Slay", true) == 0)
		{
			if(IsPlayerAlive(TeamKiller[client]))
			{
				if(SlayPlayer(TeamKiller[client]))
				{
					Format(message, sizeof(message), "%T", "TK YouSlayed", client, TeamKiller[client])
					TMSMessage(client, message)
					Format(message, sizeof(message), "%T", "TK VictimSlayed", TeamKiller[client], client)
					TMSMessage(TeamKiller[client], message)
				}
			}
			else
			{
				if(GetConVarInt(TKRRespawnSlay) == 0)
				{
					Format(message, sizeof(message), "%T", "TK KillerDead", client, TeamKiller[client])
					TMSMessage(client, message)
				}
				else
				{
					Format(message, sizeof(message), "%T", "TK SlayRespawn", client, TeamKiller[client])
					TMSMessage(client, message)
					RespawnSlay[TeamKiller[client]] = client
				}		
			}
			TKCount[TeamKiller[client]]++
			CheckTKCount(TeamKiller[client])
			TeamKiller[client] = 0
			return
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(TKRevengeMenu)
	}
	return
}

public Action:OnPlayerDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(TKRStatus) == 0)
	{
		return Plugin_Continue
	}
	new victim = GetClientOfUserId(GetEventInt(event, "victim"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(victim == 0 || attacker == 0 || attacker == victim || GetClientTeam(attacker) != GetClientTeam(victim) || IsClientImmune(attacker))
	{
		return Plugin_Continue
	}
	new damage = GetEventInt(event, "damage_given")
	if(TMSGetClientSpawnArea(victim, GetConVarInt(TKRSpawnArea)) && GetConVarInt(TKRSpawnTA) != 0)
	{
		new SpawnTAAction = GetConVarInt(TKRSpawnTA)
		if(SpawnTAAction != 0)
		{
			if(IsPlayerAlive(attacker))
			{
				if(SpawnTAAction < 3)
				{
					if(IsClientInGame(attacker) && !IsClientInKickQueue(attacker))
					{
						decl String:message[256]
						for(new i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i))
							{
								Format(message, sizeof(message), "%T", "SpawnTA Slay", i, attacker, victim)
								TMSMessage(i, message)
							}
						}
						CreateTimer(0.1, TKSlay, attacker, TIMER_FLAG_NO_MAPCHANGE)
					}
				}
				if(SpawnTAAction >= 2)
				{
					if(IsPlayerAlive(victim) && IsClientInGame(victim))
					{
						SetEntityHealth(victim, GetClientHealth(victim) + damage)
					}
				}
				if(SpawnTAAction == 3)
				{
					if(IsPlayerAlive(attacker) && IsClientInGame(attacker) && !IsClientInKickQueue(attacker))
					{
						new attackerhealth = GetClientHealth(attacker)
						new mirrorhealth = attackerhealth - damage
						if(mirrorhealth > 0)
						{
							SetEntityHealth(attacker, mirrorhealth)
						}
						else
						{
							decl String:message[256]
							for(new i = 1; i <= MaxClients; i++)
							{
								if(IsClientInGame(i))
								{
									Format(message, sizeof(message), "%T", "SpawnTA Slay", i, attacker, victim)
									TMSMessage(i, message)
								}
							}
							CreateTimer(0.1, TKSlay, attacker, TIMER_FLAG_NO_MAPCHANGE)
						}
					}
				}
			}
		}
	}
	else
	{
		new weapon = GetEventInt(event, "weapon")
		if(weapon == 1 || weapon == 2 || weapon == 29 || weapon == 30)
		{
			new MeleeTAAction = GetConVarInt(TKRMeleeTA)
			if(MeleeTAAction != 0)
			{
				if(IsPlayerAlive(attacker))
				{
					if(MeleeTAAction < 3)
					{
						if(IsClientInGame(attacker) && !IsClientInKickQueue(attacker))
						{
							decl String:message[256]
							for(new i = 1; i <= MaxClients; i++)
							{
								if(IsClientInGame(i))
								{
									Format(message, sizeof(message), "%T", "MeleeTA Slay", i, attacker, victim)
									TMSMessage(i, message)
								}
							}
							CreateTimer(0.1, TKSlay, attacker, TIMER_FLAG_NO_MAPCHANGE)
						}
					}
					if(MeleeTAAction >= 2)
					{
						if(IsPlayerAlive(victim) && IsClientInGame(victim))
						{
							SetEntityHealth(victim, GetClientHealth(victim) + damage)
						}
					}
					if(MeleeTAAction == 3)
					{
						if(IsPlayerAlive(attacker) && IsClientInGame(attacker) && !IsClientInKickQueue(attacker))
						{
							new attackerhealth = GetClientHealth(attacker)
							new mirrorhealth = attackerhealth - damage
							if(mirrorhealth > 0)
							{
								SetEntityHealth(attacker, mirrorhealth)
							}
							else
							{
								decl String:message[256]
								for(new i = 1; i <= MaxClients; i++)
								{
									if(IsClientInGame(i))
									{
										Format(message, sizeof(message), "%T", "MeleeTA Slay", i, attacker, victim)
										TMSMessage(i, message)
									}
								}
								CreateTimer(0.1, TKSlay, attacker, TIMER_FLAG_NO_MAPCHANGE)
							}
						}
					}
				}
			}
		}
	}
	if(IsClientInGame(attacker) && !IsClientInKickQueue(attacker))
	{
		TACount[attacker]++
		CheckTACount(attacker)
	}
	return Plugin_Continue
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(TKRStatus) == 0)
	{
		return Plugin_Continue
	}
	new victim = GetClientOfUserId(GetEventInt(event, "victim"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new weapon = GetEventInt(event, "weapon")
	if(!IsFakeClient(victim))
	{
		HandleDeath(victim, attacker, weapon)
	}
	return Plugin_Continue
}

public Action:OnPlayerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	decl String:weapon[32]
	GetEventString(event, "weapon", weapon, sizeof(weapon))
	if(strcmp(weapon, "bleeding", true) == 0 && !IsFakeClient(victim))
	{
		HandleDeath(victim, attacker, 0)
	}
	return Plugin_Continue
}

public Action:HandleDeath(victim, attacker, weapon)
{
	if(victim == 0 || attacker == 0 || victim == attacker || !IsClientInGame(attacker) || !IsClientInGame(victim))
	{
		return Plugin_Continue
	}
	if(GetClientTeam(attacker) != GetClientTeam(victim))
	{
		if(TKCount[attacker] != 0)
		{
			KarmaCount[attacker] += GetConVarInt(TKRKillKarma)
			CheckKarmaCount(attacker)
		}
		return Plugin_Continue
	}
	if(GetConVarInt(TKRNoVictimDeath) == 1)
	{
		SetEntProp(victim, Prop_Data, "m_iDeaths", GetClientDeaths(victim) - 1)
	}
	if(IsClientImmune(attacker))
	{
		if(GetConVarInt(TKRAdminAutoSorry) == 1)
		{	
			FakeClientCommandEx(attacker, "say %T", "TK AdminAutoSorry", LANG_SERVER, victim)
		}
		return Plugin_Continue
	}
	if(IsClientInKickQueue(attacker))
	{
		return Plugin_Continue
	}
	if(TMSGetClientSpawnArea(victim, GetConVarInt(TKRSpawnArea)) && GetConVarInt(TKRSpawnTKCount) != 0)
	{
		KarmaCount[attacker] = 0
		TKCount[attacker] += GetConVarInt(TKRSpawnTKCount)
		CheckTKCount(attacker)
		return Plugin_Continue
	}
	if(GetConVarInt(TKRMeleeTKCount) != 0 && (weapon == 1 || weapon == 2 || weapon == 29 || weapon == 30))
	{
		KarmaCount[attacker] = 0
		TKCount[attacker] += GetConVarInt(TKRMeleeTKCount)
		CheckTKCount(attacker)
		return Plugin_Continue
	}
	if(GetConVarInt(TKRRampageTKCount) != 0 && GetGameTime() < LastTimeTK[attacker] + GetConVarFloat(TKRRampageTime))
	{
		KarmaCount[attacker] = 0
		TKCount[attacker] += GetConVarInt(TKRRampageTKCount)
		CheckTKCount(attacker)
		LastTimeTK[attacker] = GetGameTime()
		return Plugin_Continue
	}
	if(GetConVarInt(TKRGrenadeTKCount) == 0 && weapon >= 19 && weapon <= 28)
	{
		KarmaCount[attacker] = 0
		return Plugin_Continue
	}
	KarmaCount[attacker] = 0
	LastTimeTK[attacker] = GetGameTime()
	if(GetConVarInt(TKRUseForgiveMenu) == 1)
	{
		TeamKiller[victim] = attacker
		DisplayTKRevengeMenu(victim, attacker)
		return Plugin_Continue
	}
	TKCount[attacker]++
	CheckTKCount(attacker)
	return Plugin_Continue
}

public Action:TKSlay(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SlayPlayer(client)
	}
	return Plugin_Handled
}

stock bool:SlayPlayer(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		TMSSlay(client, GetConVarInt(TKRSlayFX))
		return true
	}
	return false
}

public Action:CheckKarmaCount(client)
{
	if(KarmaCount[client] >= GetConVarInt(TKRKarmaReduceTK))
	{
		TKCount[client]--
		KarmaCount[client] = 0
		if(GetConVarInt(TKRShowTKCount) == 1)
		{
			decl String:message[256]
			Format(message, sizeof(message), "%T", "TKCount Lowered", client, TKCount[client], GetConVarInt(TKRMaxTKs))
			TMSHintMessage(client, message)
			TMSMessage(client, message)
		}
	}
	return Plugin_Handled
}

public Action:CheckTACount(client)
{
	if(TACount[client] >= GetConVarInt(TKRTAEqTK))
	{
		TACount[client] = 0
		TKCount[client]++
		CheckTKCount(client)
	}
	return Plugin_Handled
}

public Action:CheckTKCount(client)
{
	if(GetConVarInt(TKRShowTKCount) == 1)
	{
		decl String:message[256]
		Format(message, sizeof(message), "%T", "TKCount Raised", client, TKCount[client], GetConVarInt(TKRMaxTKs))
		TMSHintMessage(client, message)
		TMSMessage(client, message)
	}
	if(TKCount[client] >= GetConVarInt(TKRMaxTKs))
	{
		decl String:kickbanmsg[256]
		if(PrevKicks[client] >= GetConVarInt(TKRMaxPrevKick))
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(kickbanmsg, sizeof(kickbanmsg), "%T", "TK PlayerBanned", i, client)
					TMSMessage(i, kickbanmsg)
				}
			}
			PrevKicks[client] = 0
			TKPreKickBanned[client] = true
			PrevBans[client]++
			new bantime = GetConVarInt(TKRMaxPrevKickBT)
			TMSBan(client, bantime, "ExcessiveTeamKilling")
			return Plugin_Handled
		}
		if(PrevBans[client] >= GetConVarInt(TKRMaxPrevBan))
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(kickbanmsg, sizeof(kickbanmsg), "%T", "TK PlayerBanned", i, client)
					TMSMessage(i, kickbanmsg)
				}
			}
			PrevBans[client] = 0
			TKPreBanBanned[client] = true
			new bantime = 0
			TMSBan(client, bantime, "ExcessiveTeamKilling")
			return Plugin_Handled
		}
		new tkaction = GetConVarInt(TKRAction)
		if(tkaction == 0)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(kickbanmsg, sizeof(kickbanmsg), "%T", "TK PlayerKicked", i, client)
					TMSMessage(i, kickbanmsg)
				}
			}
			PrevKicks[client]++
			TKKicked[client] = true
			TMSKick(client, "ExcessiveTeamKilling")
			return Plugin_Handled
		}
		else
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(kickbanmsg, sizeof(kickbanmsg), "%T", "TK PlayerBanned", i, client)
					TMSMessage(i, kickbanmsg)
				}
			}
			new bantime = GetConVarInt(TKRBanTime)
			TKBanned[client] = true
			PrevBans[client]++
			TMSBan(client, bantime, "ExcessiveTeamKilling")
			return Plugin_Handled
		}
	}
	return Plugin_Handled
}

public Action:OnPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:cappers[256]
	GetEventString(event, "cappers", cappers, sizeof(cappers))
	new capperlen = strlen(cappers)
	for(new i = 0; i < capperlen; i++)
	{
		new client = cappers[i]
		if(TKCount[client] != 0 && !IsClientImmune(client))
		{
			KarmaCount[client] += GetConVarInt(TKRScoreKarma)
			CheckKarmaCount(client)
		}
	}
	return Plugin_Continue
}

public Action:OnCaptureBlocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event,"blocker")
	if(TKCount[client] != 0 && !IsClientImmune(client))
	{
		KarmaCount[client] += GetConVarInt(TKRScoreKarma)
		CheckKarmaCount(client)
	}
	return Plugin_Continue
}

public Action:OnBombScore(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"))
	if(TKCount[client] != 0 && !IsClientImmune(client))
	{
		KarmaCount[client] += GetConVarInt(TKRScoreKarma)
		CheckKarmaCount(client)
	}
	return Plugin_Continue
}

public Action:OnBombKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event,"userid"))
	new victim = GetClientOfUserId(GetEventInt(event,"victimid"))
	if(victim == 0 || attacker == 0 || victim == attacker || GetClientTeam(attacker) == GetClientTeam(victim) || IsClientImmune(attacker))
	{
		return Plugin_Continue
	}
	if(TKCount[attacker] != 0)
	{
		KarmaCount[attacker] += GetConVarInt(TKRKillKarma)
		CheckKarmaCount(attacker)
	}
	return Plugin_Continue
}

public Action:LoadTKCount(client)
{
	if(!FileExists(TKRFile, true))
	{
		TKCount[client] = 0
		return Plugin_Handled
	}
	decl String:steamid[64]
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid))
	new Handle:TKValues = CreateKeyValues("DoDTMS_TKFile")
	FileToKeyValues(TKValues, TKRFile)
	if(!KvJumpToKey(TKValues, steamid))
	{
		CloseHandle(TKValues)
		TKCount[client] = 0
		return Plugin_Handled
	}
	TKCount[client] = KvGetNum(TKValues, "tkcount", 0)
	PrevKicks[client] = KvGetNum(TKValues, "prevkicks", 0)
	PrevBans[client] = KvGetNum(TKValues, "prevbans", 0)
	CloseHandle(TKValues)
	return Plugin_Handled
}

public Action:SaveTKCount(client, String:steamid[])
{
	if(!FileExists(TKRFile, true))
	{
		return Plugin_Handled
	}
	new Handle:TKValues = CreateKeyValues("DoDTMS_TKFile")
	FileToKeyValues(TKValues, TKRFile)
	if(!KvJumpToKey(TKValues, steamid, true))
	{
		CloseHandle(TKValues)
		return Plugin_Handled
	}
	if(TKKicked[client])
	{
		KvSetNum(TKValues, "tkcount", 0)
		KvSetNum(TKValues, "prevkicks", PrevKicks[client])
		KvSetNum(TKValues, "prevbans", 0)
	}
	else if(TKPreKickBanned[client])
	{
		KvSetNum(TKValues, "tkcount", 0)
		KvSetNum(TKValues, "prevkicks", 0)
		KvSetNum(TKValues, "prevbans", PrevBans[client])
	}
	else if(TKPreBanBanned[client])
	{
		KvDeleteThis(TKValues)
	}
	else if(TKBanned[client])
	{
		if(GetConVarInt(TKRBanTime) != 0)
		{
			KvSetNum(TKValues, "tkcount", 0)
			KvSetNum(TKValues, "prevkicks", 0)
			KvSetNum(TKValues, "prevbans", PrevBans[client])
		}
		else
		{
			KvDeleteThis(TKValues)
		}
	}
	else
	{
		KvSetNum(TKValues, "tkcount", TKCount[client])
		KvSetNum(TKValues, "prevkicks", PrevKicks[client])
		KvSetNum(TKValues, "prevbans", PrevBans[client])
	}
	KvRewind(TKValues)
	KeyValuesToFile(TKValues, TKRFile)
	CloseHandle(TKValues)
	return Plugin_Handled
}

stock bool:IsClientImmune(client)
{
	if((GetUserAdmin(client) != INVALID_ADMIN_ID || IsWhiteListed[client]) && !IsBlackListed[client] && GetConVarInt(ClientImmunity) == 1)
	{
		return true
	}
	else
	{
		return false
	}
}