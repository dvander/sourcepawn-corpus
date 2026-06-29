 //////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Base  - DoD TeamManager Source
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define MAXBONUSROUNDTIME 60.0

public Plugin:myinfo = 
{
	name = "[DoD TMS] Base  - DoD TeamManager Source", 
	author = "FeuerSturm, modif Micmacx", 
	description = "All-in-One TeamManager for DoD:Source", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net"
}

new Handle:AutoTeamJoin = INVALID_HANDLE
new Handle:JoinControlPlDiff = INVALID_HANDLE
new Handle:JoinControlON = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new Handle:SpecLock = INVALID_HANDLE
new Handle:SpecDeath = INVALID_HANDLE
new Handle:LimitTeams = INVALID_HANDLE
new Handle:AllowSpectators = INVALID_HANDLE
new Handle:NoSwitchDeath = INVALID_HANDLE
new Handle:BonusRoundTime = INVALID_HANDLE
new Handle:BanningSystem = INVALID_HANDLE
new Handle:CustBanCommand = INVALID_HANDLE
new Handle:g_OnDoDTMSRoundEnd = INVALID_HANDLE
new Handle:g_OnDoDTMSRoundActive = INVALID_HANDLE
new Handle:g_OnDoDTMSMenuReady = INVALID_HANDLE
new Handle:g_OnDoDTMSDeleteCfg = INVALID_HANDLE
new Handle:SMRootMenu = INVALID_HANDLE
new TopMenuObject:DoDTMSMenu = INVALID_TOPMENUOBJECT
new PlayerMixed[MAXPLAYERS + 1]
new g_MixedWehrmacht = 0, g_MixedArmy = 0
new g_autoswitch_lock[MAXPLAYERS + 1], g_smoothswitch[MAXPLAYERS + 1], g_IsFakeCmd[MAXPLAYERS + 1]
new g_TeamScore[4], g_InBonusRound = 0
new OpTeam[4] =  { UNASSIGNED, RANDOM, AXIS, ALLIES }
new String:TeamName[5][] =  { "Random", "Spectators", "U.S. Army", "Wehrmacht", "U.S. Army & Wehrmacht" }
new g_adminteam = 0, g_autobalance = 0
new Float:g_SpawnPosition[MAXPLAYERS + 1][3]
new Float:g_CurrentPosition[MAXPLAYERS + 1][3]
new String:TMSWhiteList[] =  { "cfg/dod_teammanager_source/dod_tms_whitelist.cfg" }
new String:TMSBlackList[] =  { "cfg/dod_teammanager_source/dod_tms_blacklist.cfg" }
new String:WLFeature[] =  { "tmsbase" }
new bool:IsWhiteListed[MAXPLAYERS + 1]
new bool:IsBlackListed[MAXPLAYERS + 1]
new String:SlaySound[] =  { "weapons/explode4.wav" }
new SlaySprite

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else 
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	CreateNative("TMSSwapTeams", NativeTMSSwapTeams)
	CreateNative("TMSMessage", NativeTMSMessage)
	CreateNative("TMSHintMessage", NativeTMSHintMessage)
	CreateNative("TMSCenterMessage", NativeTMSCenterMessage)
	CreateNative("TMSChangeToTeam", NativeTMSChangeToTeam)
	CreateNative("TMSKick", NativeTMSKick)
	CreateNative("TMSBan", NativeTMSBan)
	CreateNative("TMSSound", NativeTMSSound)
	CreateNative("TMSMixTeams", NativeTMSMixTeams)
	CreateNative("TMSAdminTeam", NativeTMSAdminTeam)
	CreateNative("TMSSlay", NativeTMSSlay)
	CreateNative("TMSRegAddon", NativeTMSRegAddon)
	CreateNative("TMSGetClientSpawnArea", NativeGetClientSpawnArea)
	CreateNative("TMSIsWhiteListed", NativeTMSIsWhiteListed)
	CreateNative("TMSIsBlackListed", NativeTMSIsBlackListed)
	RegPluginLibrary("DoDTeamManagerSource")
	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3 
	return APLRes_Success;
	#else 
	return true;
	#endif
}

public OnPluginStart()
{
	CreateConVar("dod_tms_version", PLUGIN_VERSION, "DoD TeamManager Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD | FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_tms_version"), PLUGIN_VERSION)
	CreateConVar("dod_tms_addons", "", "[DoD TMS] Addons (DO NOT CHANGE!)", FCVAR_DONTRECORD | FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_tms_addons"), "")
	AutoTeamJoin = CreateConVar("dod_tms_autoteamjoin", "1", "<1/0> = enable/disable AutoTeamJoining if selected Team is full", _, true, 0.0, true, 1.0)
	JoinControlPlDiff = CreateConVar("dod_tms_joincontrolpldiff", "1", "<#> = max allowed team difference for selecting teams", _, true, 1.0)
	JoinControlON = CreateConVar("dod_tms_joincontrol", "1", "<1/0> = enable/disable Team selection manager", _, true, 0.0, true, 1.0)
	ClientImmunity = CreateConVar("dod_tms_baseimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions", _, true, 0.0, true, 1.0)
	SpecLock = CreateConVar("dod_tms_speclock", "1", "<1/2/0> = set locking team Spectators for public players - 1 always lock - 2 lock in bonusround - 0 disabled", _, true, 0.0, true, 2.0)
	SpecDeath = CreateConVar("dod_tms_specdeath", "1", "<1/0> = enable/disable killing players when they join Spectators", _, true, 0.0, true, 1.0)
	NoSwitchDeath = CreateConVar("dod_tms_noswitchdeath", "1", "<1/0> = enable/disable smooth team switching (no death on scoreboard)", _, true, 0.0, true, 1.0)
	BanningSystem = CreateConVar("dod_tms_banningsystem", "0", "<1/0> = enable/disable using custom ban command instead of native banning", _, true, 0.0, true, 1.0)
	CustBanCommand = CreateConVar("dod_tms_custombancmd", "sm_ban", "<command> = custom ban command to use for banning", _)
	LimitTeams = FindConVar("mp_limitteams")
	AllowSpectators = FindConVar("mp_allowspectators")
	BonusRoundTime = FindConVar("dod_bonusroundtime")
	RegAdminCmd("jointeam", cmd_jointeam, 0)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	HookEventEx("dod_round_win", RoundEnd, EventHookMode_Post)
	HookEventEx("dod_round_active", RoundActive, EventHookMode_Post)
	HookEvent("player_team", Surpress_TeamMSG, EventHookMode_Pre)
	g_OnDoDTMSRoundEnd = CreateGlobalForward("OnDoDTMSRoundEnd", ET_Event, Param_Cell)
	g_OnDoDTMSRoundActive = CreateGlobalForward("OnDoDTMSRoundActive", ET_Event)
	g_OnDoDTMSDeleteCfg = CreateGlobalForward("OnDoDTMSDeleteCfg", ET_Event)
	g_OnDoDTMSMenuReady = CreateGlobalForward("OnDoDTMSMenuReady", ET_Ignore, Param_Cell)
	PrecacheSound("common/weapon_denyselect.wav")
	PrecacheSound("player/american/us_gogogo.wav")
	PrecacheSound("player/german/ger_gogogo2.wav")
	AutoExecConfig(true, "dod_teammanager_base", "dod_teammanager_source")
	new Handle:SourceModMenu
	if (LibraryExists("adminmenu") && ((SourceModMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(SourceModMenu)
	}
	if (!FileExists(TMSWhiteList, true))
	{
		LogError("[DoD TMS] WhiteList NOT found!")
	}
	if (!FileExists(TMSBlackList, true))
	{
		LogError("[DoD TMS] BlackList NOT found!")
	}
	LoadTranslations("dod_teammanager_source.txt")
	SetConVarBounds(BonusRoundTime, ConVarBound_Upper, true, MAXBONUSROUNDTIME)
}

public OnClientPostAdminCheck(client)
{
	if (TMSIsWhiteListed(client, WLFeature))
	{
		IsWhiteListed[client] = true
	}
	else
	{
		IsWhiteListed[client] = false
	}
	if (TMSIsBlackListed(client, WLFeature))
	{
		IsBlackListed[client] = true
	}
	else
	{
		IsBlackListed[client] = false
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		SMRootMenu = INVALID_HANDLE
	}
}

public Action:cmdVersionCheck(client)
{
	new String:CheckTMSVersion[256]
	Format(CheckTMSVersion, sizeof(CheckTMSVersion), "http://www.dodsourceplugins.net/teammanager/check.php?version=%s", PLUGIN_VERSION)
	ShowMOTDPanel(client, "DoDTMS", CheckTMSVersion, MOTDPANEL_TYPE_URL)
	return Plugin_Handled
}

public OnAdminMenuReady(Handle:SourceModMenu)
{
	if (SourceModMenu == SMRootMenu)
	{
		return 
	}
	SMRootMenu = SourceModMenu
	DoDTMSMenu = AddToTopMenu(SMRootMenu, "dod_tms_menu", TopMenuObject_Category, Handle_DoDTMSMenu, INVALID_TOPMENUOBJECT)
	if (DoDTMSMenu == INVALID_TOPMENUOBJECT)
	{
		return 
	}
	AddToTopMenu(SMRootMenu, "TMSPluginCommands", TopMenuObject_Item, Handle_TMSPluginCommands, DoDTMSMenu, "TMSPluginCommands", ADMFLAG_ROOT)
	Call_StartForward(g_OnDoDTMSMenuReady)
	Call_PushCell(SourceModMenu)
	Call_Finish()
}

public Handle_TMSPluginCommands(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		decl String:menuitem[256]
		Format(menuitem, sizeof(menuitem), "%T", "PluginCmdMenu", param)
		Format(buffer, maxlength, menuitem)
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ShowPluginCmds(param)
	}
}

ShowPluginCmds(client)
{
	new Handle:DoDTMSCmdMenu = INVALID_HANDLE
	DoDTMSCmdMenu = CreateMenu(Handle_PluginCommands)
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "[DoD TMS] %T", "PluginCmdMenu Title", client)
	SetMenuTitle(DoDTMSCmdMenu, menutitle)
	decl String:menuitem[256]
	Format(menuitem, sizeof(menuitem), "%T", "CheckVersion", client)
	AddMenuItem(DoDTMSCmdMenu, "dod_tms_versioncheck", menuitem)
	Format(menuitem, sizeof(menuitem), "%T", "RecreateCfgs", client)
	AddMenuItem(DoDTMSCmdMenu, "dod_tms_createconfig", menuitem)
	SetMenuExitBackButton(DoDTMSCmdMenu, true)
	SetMenuExitButton(DoDTMSCmdMenu, true)
	DisplayMenu(DoDTMSCmdMenu, client, MENU_TIME_FOREVER)
}

public Handle_PluginCommands(Handle:DoDTMSCmdMenu, MenuAction:action, client, itemNum)
{
	if (client < 1)
	{
		return 
	}
	if (action == MenuAction_Select)
	{
		decl String:MenuChoice[256]
		GetMenuItem(DoDTMSCmdMenu, itemNum, MenuChoice, sizeof(MenuChoice))
		if (strcmp(MenuChoice, "dod_tms_versioncheck", true) == 0)
		{
			cmdVersionCheck(client)
			return 
		}
		if (strcmp(MenuChoice, "dod_tms_createconfig", true) == 0)
		{
			decl String:configfile[256]
			Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/dod_teammanager_base.cfg")
			if (FileExists(configfile))
			{
				DeleteFile(configfile)
			}
			Call_StartForward(g_OnDoDTMSDeleteCfg)
			Call_Finish()
			decl String:message[256]
			Format(message, sizeof(message), "%T", "Configs Deleted", client)
			TMSMessage(client, message)
			return 
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (itemNum == MenuCancel_ExitBack)
		{
			if (GetClientMenu(client))
			{
				CancelClientMenu(client)
			}
			DisplayTopMenu(SMRootMenu, client, TopMenuPosition_LastCategory)
		}
	}
}

public Handle_DoDTMSMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (param < 1)
	{
		return 
	}
	switch (action)
	{
		case TopMenuAction_DisplayTitle:
		{
			Format(buffer, maxlength, "DoD TeamManager Source:")
		}
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "DoD TeamManager Source")
		}
	}
}

public OnMapStart()
{
	PrecacheSound(SlaySound)
	SlaySprite = PrecacheModel("materials/sprites/effect/bazookapuff.vmt")
	SetConVarInt(LimitTeams, MaxClients)
	SetConVarInt(AllowSpectators, 1)
	g_InBonusRound = 0
	g_adminteam = 0
}

public OnConfigsExecuted()
{
	CreateTimer(1.0, ExecMapConfig, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE)
}

public Action:ExecMapConfig(Handle:timer)
{
	decl String:Mapname[128]
	GetCurrentMap(Mapname, sizeof(Mapname))
	ServerCommand("exec %s.cfg", Mapname)
	return Plugin_Handled
}

public OnMapEnd()
{
	g_InBonusRound = 0
	g_adminteam = 0
}

public OnClientDisconnect(client)
{
	if (GetClientMenu(client))
	{
		CancelClientMenu(client)
	}
	g_autoswitch_lock[client] = 0
	g_smoothswitch[client] = 0
	g_IsFakeCmd[client] = 0
}

public OnClientPutInServer(client)
{
	g_autoswitch_lock[client] = 0
	g_smoothswitch[client] = 0
	g_IsFakeCmd[client] = 0
}

public Action:Surpress_TeamMSG(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (g_smoothswitch[client] == 1)
	{
		g_smoothswitch[client] = 0
		dontBroadcast = true
		return Plugin_Changed
	}
	return Plugin_Continue
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winnerteam = GetEventInt(event, "team")
	if (GetConVarInt(FindConVar("dod_bonusround")) == 1)
	{
		new BonusTime = GetConVarInt(BonusRoundTime) - 1
		g_InBonusRound = 1
		CreateTimer(float(BonusTime), RoundFinished, winnerteam, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Continue
	}
	else if (GetConVarInt(FindConVar("dod_bonusround")) == 0)
	{
		g_InBonusRound = 0
		CreateTimer(0.0, RoundFinished, winnerteam)
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action:RoundFinished(Handle:timer, any:winnerteam)
{
	if (g_InBonusRound == 1)
	{
		g_InBonusRound = 0
	}
	Call_StartForward(g_OnDoDTMSRoundEnd)
	Call_PushCell(winnerteam)
	Call_Finish()
	return Plugin_Handled
}

public Action:RoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	Call_StartForward(g_OnDoDTMSRoundActive)
	Call_Finish()
	return Plugin_Continue
}

public Action:SwapToTeam(client, newteam)
{
	new currteam = GetClientTeam(client)
	if (currteam == UNASSIGNED || currteam == SPEC || newteam == SPEC)
	{
		ChangeClientTeam(client, newteam)
		return Plugin_Handled
	}
	if (GetConVarInt(NoSwitchDeath) == 1 && IsPlayerAlive(client))
	{
		g_smoothswitch[client] = 1
		ChangeClientTeam(client, SPEC)
	}
	ChangeClientTeam(client, newteam)
	ShowVGUIPanel(client, newteam == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
	return Plugin_Handled
}

public checkteamstate()
{
	new alliedteam = GetTeamClientCount(ALLIES)
	new axisteam = GetTeamClientCount(AXIS)
	new advantage = 0
	new pldiff = GetConVarInt(JoinControlPlDiff)
	if ((alliedteam - axisteam) >= pldiff)
	{
		advantage = ALLIES
	}
	else if ((axisteam - alliedteam) >= pldiff)
	{
		advantage = AXIS
	}
	else
	{
		advantage = EVEN
	}
	return advantage
}

public Action:cmd_jointeam(client, args)
{
	if (g_IsFakeCmd[client] == 1)
	{
		g_IsFakeCmd[client] = 0
		return Plugin_Continue
	}
	if (GetConVarInt(JoinControlON) != 1)
	{
		return Plugin_Continue
	}
	decl String:teamnumber[2]
	GetCmdArg(1, teamnumber, 2)
	new team = StringToInt(teamnumber)
	new currteam = GetClientTeam(client)
	decl String:message[256]
	decl String:sound[256]
	if (team == currteam && currteam != UNASSIGNED)
	{
		Format(sound, sizeof(sound), "common/weapon_denyselect.wav")
		TMSSound(client, sound)
		Format(message, sizeof(message), "%T", "Already on Team", client, TeamName[team])
		TMSMessage(client, message)
		return Plugin_Handled
	}
	if (g_adminteam == team && g_adminteam != 0 && !IsClientImmune(client))
	{
		if (GetConVarInt(AutoTeamJoin) == 0 || currteam == OpTeam[team])
		{
			Format(message, sizeof(message), "%T", "AdminTeam Stop", client)
			TMSMessage(client, message)
			return Plugin_Handled
		}
		if (currteam == UNASSIGNED || currteam == SPEC)
		{
			Format(message, sizeof(message), "%T", "AdminTeam Auto", client, OpTeam[team])
			TMSMessage(client, message)
			TMSChangeToTeam(client, OpTeam[team])
			return Plugin_Handled
		}
	}
	if (IsClientImmune(client) && GetConVarInt(ClientImmunity) == 1 && team != RANDOM)
	{
		TMSChangeToTeam(client, team)
		return Plugin_Handled
	}
	if (team == SPEC)
	{
		if (GetConVarInt(SpecLock) == 1 || (GetConVarInt(SpecLock) == 2 && g_InBonusRound == 1))
		{
			Format(sound, sizeof(sound), "common/weapon_denyselect.wav")
			TMSSound(client, sound)
			Format(message, sizeof(message), "%T", "Team Locked", client, TeamName[team])
			TMSMessage(client, message)
			return Plugin_Handled
		}
		if (GetConVarInt(SpecDeath) == 1 && IsPlayerAlive(client))
		{
			TMSSlay(client, 0)
		}
		return Plugin_Continue
	}
	if (GetConVarInt(JoinControlON) == 0)
	{
		return Plugin_Continue
	}
	new MorePlayers = checkteamstate()
	if (team == ALLIES || team == AXIS)
	{
		if (MorePlayers == OpTeam[team])
		{
			TMSChangeToTeam(client, team)
			return Plugin_Handled
		}
		else if (MorePlayers == team)
		{
			if (GetConVarInt(AutoTeamJoin) == 0 || currteam == OpTeam[team])
			{
				Format(sound, sizeof(sound), "common/weapon_denyselect.wav")
				TMSSound(client, sound)
				Format(message, sizeof(message), "%T", "Team Full Stop", client, TeamName[team])
				TMSMessage(client, message)
				TMSCenterMessage(client, message)
				return Plugin_Handled
			}
			else
			{
				Format(message, sizeof(message), "%T", "Team Full Auto", client, TeamName[team], TeamName[OpTeam[team]])
				TMSMessage(client, message)
				TMSChangeToTeam(client, OpTeam[team])
				return Plugin_Handled
			}
		}
		else if (MorePlayers == EVEN)
		{
			if (currteam == OpTeam[team])
			{
				Format(message, sizeof(message), "%T", "Teams Balanced", client, TeamName[team])
				TMSMessage(client, message)
				return Plugin_Handled
			}
			else if (currteam == SPEC || currteam == UNASSIGNED)
			{
				return Plugin_Continue
			}
		}
	}
	else if (team == RANDOM)
	{
		if (MorePlayers == ALLIES || MorePlayers == AXIS)
		{
			if (currteam != OpTeam[MorePlayers])
			{
				TMSChangeToTeam(client, OpTeam[MorePlayers])
				return Plugin_Handled
			}
			else
			{
				return Plugin_Handled
			}
		}
		else if (MorePlayers == EVEN)
		{
			if (currteam == SPEC || currteam == UNASSIGNED)
			{
				new RandomTeam = GetRandomInt(ALLIES, AXIS)
				TMSChangeToTeam(client, RandomTeam)
				return Plugin_Handled
			}
			else
			{
				return Plugin_Handled
			}
		}
	}
	return Plugin_Continue
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > SPEC)
	{
		GetClientAbsOrigin(client, g_SpawnPosition[client])
		return Plugin_Continue
	}
	return Plugin_Continue
}

public NativeTMSMessage(Handle:plugin, numParams)
{
	decl String:message[256]
	new client = GetNativeCell(1)
	GetNativeString(2, message, sizeof(message))
	PrintToChat(client, "\x04[DoD TMS] \x01%s", message)
	return true
}

public NativeTMSCenterMessage(Handle:plugin, numParams)
{
	decl String:message[256]
	new client = GetNativeCell(1)
	GetNativeString(2, message, sizeof(message))
	if (client == 0)
	{
		PrintCenterTextAll(message)
	}
	else
	{
		PrintCenterText(client, message)
	}
	return true
}

public NativeTMSKick(Handle:plugin, numParams)
{
	decl String:kickmessage[256]
	new client = GetNativeCell(1)
	GetNativeString(2, kickmessage, sizeof(kickmessage))
	if (IsClientInGame(client))
	{
		KickClient(client, "%s", kickmessage)
		return true
	}
	return true
}

public NativeTMSBan(Handle:plugin, numParams)
{
	new client = GetNativeCell(1)
	new bantime = GetNativeCell(2)
	decl String:banreason[256]
	GetNativeString(3, banreason, sizeof(banreason))
	if (IsClientInGame(client))
	{
		if (GetConVarInt(BanningSystem) == 0)
		{
			BanClient(client, bantime, BANFLAG_AUTHID | BANFLAG_AUTO, banreason, banreason, "DoD TMS", 0)
		}
		else
		{
			new userid = GetClientUserId(client)
			decl String:BanCmd[64]
			GetConVarString(CustBanCommand, BanCmd, sizeof(BanCmd))
			ServerCommand("%s #%d %i %s", BanCmd, userid, bantime, banreason)
		}
	}
	return true
}

public NativeTMSSound(Handle:plugin, numParams)
{
	decl String:soundsample[256]
	new client = GetNativeCell(1)
	GetNativeString(2, soundsample, sizeof(soundsample))
	if (client == 0)
	{
		EmitSoundToAll(soundsample, SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
	}
	else
	{
		EmitSoundToClient(client, soundsample, SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
	}
	return true
}

public NativeTMSHintMessage(Handle:plugin, numParams)
{
	decl String:hintmessage[256]
	new client = GetNativeCell(1)
	GetNativeString(2, hintmessage, sizeof(hintmessage))
	if (client == 0)
	{
		PrintHintTextToAll("%s", hintmessage)
	}
	else
	{
		PrintHintText(client, "%s", hintmessage)
	}
	return true
}

public NativeTMSSwapTeams(Handle:plugin, numParams)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			new team = GetClientTeam(i)
			SwapToTeam(i, OpTeam[team])
		}
	}
	g_TeamScore[AXIS] = GetTeamScore(AXIS)
	g_TeamScore[ALLIES] = GetTeamScore(ALLIES)
	SetTeamScore(AXIS, g_TeamScore[ALLIES])
	SetTeamScore(ALLIES, g_TeamScore[AXIS])
	return true
}

public NativeTMSMixTeams(Handle:plugin, numParams)
{
	new TeamAllies = GetTeamClientCount(ALLIES)
	new TeamAxis = GetTeamClientCount(AXIS)
	new MixPlayersNum = 0
	if (TeamAxis > TeamAllies)
	{
		MixPlayersNum = RoundToCeil(float(TeamAllies) / 2.0)
	}
	else
	{
		MixPlayersNum = RoundToCeil(float(TeamAxis) / 2.0)
	}
	CreateTimer(0.0, MixTeams, MixPlayersNum, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
	return true
}

public Action:MixTeams(Handle:timer, any:MixPlayersNum)
{
	if ((g_MixedWehrmacht >= MixPlayersNum) && (g_MixedArmy >= MixPlayersNum))
	{
		g_MixedWehrmacht = 0
		g_MixedArmy = 0
		for (new i = 1; i <= MaxClients; i++)
		{
			PlayerMixed[i] = 0
		}
		return Plugin_Stop
	}
	new randomplayer = GetRandomInt(1, MaxClients)
	if (IsClientInGame(randomplayer))
	{
		new team = GetClientTeam(randomplayer)
		if (team == AXIS && PlayerMixed[randomplayer] == 0 && g_MixedWehrmacht < MixPlayersNum)
		{
			PlayerMixed[randomplayer] = 1
			g_MixedWehrmacht++
			TMSChangeToTeam(randomplayer, OpTeam[team])
			return Plugin_Handled
		}
		else if (team == ALLIES && PlayerMixed[randomplayer] == 0 && g_MixedArmy < MixPlayersNum)
		{
			PlayerMixed[randomplayer] = 1
			g_MixedArmy++
			TMSChangeToTeam(randomplayer, OpTeam[team])
			return Plugin_Handled
		}
	}
	return Plugin_Handled
}

public NativeTMSChangeToTeam(Handle:plugin, numParams)
{
	new client = GetNativeCell(1)
	new newteam = GetNativeCell(2)
	new currteam = GetClientTeam(client)
	if (currteam == UNASSIGNED || currteam == SPEC || newteam == SPEC)
	{
		g_IsFakeCmd[client] = 1
		FakeClientCommandEx(client, "jointeam %i", newteam)
		return true
	}
	if (GetConVarInt(NoSwitchDeath) == 1)
	{
		g_smoothswitch[client] = 1
		ChangeClientTeam(client, SPEC)
	}
	g_IsFakeCmd[client] = 1
	FakeClientCommandEx(client, "jointeam %i", newteam)
	return true
}

public NativeTMSAdminTeam(Handle:plugin, numParams)
{
	g_adminteam = GetNativeCell(1)
	if (g_adminteam != 0)
	{
		if (g_autobalance == 0)
		{
			g_autobalance = GetConVarInt(FindConVar("dod_tms_autobalance"))
			if (g_autobalance != 0)
			{
				SetConVarInt(FindConVar("dod_tms_autobalance"), 0)
			}
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == g_adminteam)
			{
				if (GetUserAdmin(i) == INVALID_ADMIN_ID)
				{
					TMSChangeToTeam(i, OpTeam[g_adminteam])
				}
			}
			else if (IsClientInGame(i) && GetClientTeam(i) == OpTeam[g_adminteam])
			{
				if (GetUserAdmin(i) != INVALID_ADMIN_ID)
				{
					TMSChangeToTeam(i, g_adminteam)
				}
			}
		}
	}
	if (g_adminteam == 0)
	{
		if (g_autobalance != 0)
		{
			SetConVarInt(FindConVar("dod_tms_autobalance"), g_autobalance)
		}
	}
	return true
}

public NativeTMSSlay(Handle:plugin, numParams)
{
	new client = GetNativeCell(1)
	new slayfx = GetNativeCell(2)
	if (slayfx == 1)
	{
		new Float:origin[3]
		GetClientAbsOrigin(client, origin)
		EmitAmbientSound(SlaySound, origin)
		TE_SetupExplosion(origin, SlaySprite, 10.0, 10, TE_EXPLFLAG_NONE, 15, 15)
		TE_SendToAll()
	}
	ForcePlayerSuicide(client)
	if (IsPlayerAlive(client))
	{
		new Team = GetClientTeam(client)
		SecretTeamSwitch(client, OpTeam[Team])
		SecretTeamSwitch(client, Team)
		return true
	}
	else
	{
		return false
	}
}

public NativeTMSRegAddon(Handle:plugin, numParams)
{
	decl String:AddonBuffer[256]
	GetNativeString(1, AddonBuffer, sizeof(AddonBuffer))
	decl String:DoDTMSAddonInfo[256]
	new Handle:DoDTMSAddonConVar
	DoDTMSAddonConVar = FindConVar("dod_tms_addons")
	new flags = GetConVarFlags(DoDTMSAddonConVar)
	flags &= ~FCVAR_NOTIFY
	SetConVarFlags(DoDTMSAddonConVar, flags)
	GetConVarString(DoDTMSAddonConVar, DoDTMSAddonInfo, sizeof(DoDTMSAddonInfo))
	StrCat(DoDTMSAddonInfo, sizeof(DoDTMSAddonInfo), AddonBuffer)
	SetConVarString(DoDTMSAddonConVar, DoDTMSAddonInfo)
	flags &= FCVAR_NOTIFY
	SetConVarFlags(DoDTMSAddonConVar, flags)
	return true
}

public NativeGetClientSpawnArea(Handle:plugin, numParams)
{
	new client = GetNativeCell(1)
	new SpawnArea = GetNativeCell(2)
	GetClientAbsOrigin(client, g_CurrentPosition[client])
	new Float:Distance = GetVectorDistance(g_SpawnPosition[client], g_CurrentPosition[client])
	if (Distance < float(SpawnArea))
	{
		return true
	}
	else
	{
		return false
	}
}

public NativeTMSIsWhiteListed(Handle:plugin, numParams)
{
	if (!FileExists(TMSWhiteList, true))
	{
		return false
	}
	new client = GetNativeCell(1)
	decl String:feature[64]
	GetNativeString(2, feature, sizeof(feature))
	new Handle:KeyValues3 = CreateKeyValues("DoDTMS_WhiteList")
	decl String:steamid[64]
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid))
	FileToKeyValues(KeyValues3, TMSWhiteList)
	if (!KvJumpToKey(KeyValues3, steamid))
	{
		CloseHandle(KeyValues3)
		return false
	}
	new immunity = KvGetNum(KeyValues3, feature, 0)
	CloseHandle(KeyValues3)
	if (immunity == 1)
	{
		return true
	}
	else
	{
		return false
	}
}

public NativeTMSIsBlackListed(Handle:plugin, numParams)
{
	if (!FileExists(TMSBlackList, true))
	{
		return false
	}
	new client = GetNativeCell(1)
	decl String:feature[64]
	GetNativeString(2, feature, sizeof(feature))
	new Handle:KeyValues2 = CreateKeyValues("DoDTMS_BlackList")
	decl String:steamid[64]
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid))
	FileToKeyValues(KeyValues2, TMSBlackList)
	if (!KvJumpToKey(KeyValues2, steamid))
	{
		CloseHandle(KeyValues2)
		return false
	}
	new denied = KvGetNum(KeyValues2, feature, 0)
	CloseHandle(KeyValues2)
	if (denied == 1)
	{
		return true
	}
	else
	{
		return false
	}
}

stock SecretTeamSwitch(client, newteam)
{
	g_smoothswitch[client] = 1
	ChangeClientTeam(client, newteam)
	ShowVGUIPanel(client, newteam == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
}

stock bool:IsClientImmune(client)
{
	if ((GetUserAdmin(client) != INVALID_ADMIN_ID || IsWhiteListed[client]) && !IsBlackListed[client] && GetConVarInt(ClientImmunity) == 1)
	{
		return true
	}
	else
	{
		return false
	}
} 