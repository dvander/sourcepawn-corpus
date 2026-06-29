//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - AutoTeamBalance
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - AutoTeamBalance",
	author = "FeuerSturm, modif Micmacx",
	description = "Addon AutoTeamBalance for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:AutoBalanceMode = INVALID_HANDLE
new Handle:AutoBalanceDelay = INVALID_HANDLE
new Handle:AutoBalancePlDiff = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new g_InAutoBalanceTimer = 0
new g_autoswitch_lock[MAXPLAYERS+1]
new String:NeedBackup[4][] = {"", "", "player/american/us_backup.wav", "player/german/ger_backup.wav"}
new OpTeam[4] = {UNASSIGNED, RANDOM, AXIS, ALLIES}
new String:TeamName[5][] = {"Random", "Spectators", "U.S. Army", "Wehrmacht", "U.S. Army & Wehrmacht"}
new String:WLFeature[] = { "autobalance" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]

public OnPluginStart()
{
	AutoBalanceMode = CreateConVar("dod_tms_autobalance", "1", "<1/2/0> = Balancing mode: 1 = on player death, 2 = after X seconds of unbalanced teams, 0 = disabled",_, true, 0.0, true, 2.0)
	AutoBalanceDelay = CreateConVar("dod_tms_autobalancedelay", "15", "<#> = time in seconds to wait before balancing (used for autobalance mode 2!)",_, true, 5.0)
	AutoBalancePlDiff = CreateConVar("dod_tms_autobalancepldiff", "1", "<#> = max allowed team difference before balancing",_, true, 1.0)
	ClientImmunity = CreateConVar("dod_tms_autobalanceimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions",_, true, 0.0, true, 1.0)
	HookEventEx("player_team", OnTeamChange, EventHookMode_Post)
	HookEventEx("player_death", OnPlayerDeath, EventHookMode_Post)
	PrecacheSound("player/american/us_backup.wav")
	PrecacheSound("player/german/ger_backup.wav")
	AutoExecConfig(true,"addon_dodtms_autobalance", "dod_teammanager_source")
	LoadTranslations("dodtms_autobalance.txt")
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.1, DoDTMSRunning)
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
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("A")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_autobalance.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public OnMapStart()
{
	g_InAutoBalanceTimer = 0
}

public OnMapEnd()
{
	g_InAutoBalanceTimer = 0
}

public OnTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, CheckAutoBalance)
}

public OnClientDisconnect_Post(client)
{
	CreateTimer(1.0, CheckAutoBalance)
}

public Action:CheckAutoBalance(Handle:timer)
{
	if(GetConVarInt(AutoBalanceMode) == 2)
	{
		if(g_InAutoBalanceTimer == 1)
		{
			return Plugin_Handled
		}
		new advteam = checkteams()
		if(advteam != EVEN)
		{
			decl String:message[256]
			Format(message,sizeof(message),"%T", "Team Advantage", LANG_SERVER, TeamName[advteam])
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == advteam)
				{
					TMSHintMessage(i, message)
					TMSMessage(i, message)
					TMSSound(i, NeedBackup[OpTeam[advteam]])
				}
			}
			g_InAutoBalanceTimer = 1
			new CheckDelay = GetConVarInt(AutoBalanceDelay)
			CreateTimer(float(CheckDelay), ReCheckTeams, _, TIMER_FLAG_NO_MAPCHANGE)
			return Plugin_Handled
		}
	}
	return Plugin_Handled
}

public Action:ReCheckTeams(Handle:timer)
{
	new advteam = checkteams()
	if(advteam != EVEN)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == advteam && g_autoswitch_lock[i] == 0 && !IsClientImmune(i))
			{
				CreateTimer(1.0, BalanceTeams, i)
				CreateTimer(1.5, ReCheckTeams, _, TIMER_FLAG_NO_MAPCHANGE)
				return Plugin_Handled
			}
		}
	}
	g_InAutoBalanceTimer = 0
	return Plugin_Handled
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(AutoBalanceMode) == 1)
	{	
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		if(IsClientImmune(client))
		{
			return Plugin_Continue
		}
		CreateTimer(1.0, CheckSwitchPlayer, client, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Continue
	}
	else if(GetConVarInt(AutoBalanceMode) == 2)
	{
		CreateTimer(1.0, CheckAutoBalance, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action:CheckSwitchPlayer(Handle:timer, any:client)
{
	if (ValidPlayer(client))
	{
		if(!IsFakeClient(client))
		{
			new plteam = GetClientTeam(client)
			if(((plteam == ALLIES && checkteams() == ALLIES) || (plteam == AXIS && checkteams() == AXIS)) && g_autoswitch_lock[client] == 0)
			{
				CreateTimer(0.5, BalanceTeams, client, TIMER_FLAG_NO_MAPCHANGE)
				return Plugin_Handled
			}
		}
		else
		{
			new plteam = GetClientTeam(client)
			if(((plteam == ALLIES && checkfaketeams() == ALLIES) || (plteam == AXIS && checkfaketeams() == AXIS)) && g_autoswitch_lock[client] == 0)
			{
				CreateTimer(0.5, BalanceTeams, client, TIMER_FLAG_NO_MAPCHANGE)
				return Plugin_Handled
			}
		}
	}
	return Plugin_Handled
}

public checkteams()
{
	new alliedteam = 0
	new axisteam = 0
	for (new x = 1; x <= MaxClients; x++)
	{
		if (ValidPlayer(x))
		{
			if(!IsFakeClient(x))
			{
				new teamtmp = GetClientTeam(x)
				if(teamtmp == ALLIES)
				{
					alliedteam++
				}
				if(teamtmp == AXIS)
				{
					axisteam++
				}
			}
		}
	}
	new advantage = 0
	new pldiff = GetConVarInt(AutoBalancePlDiff)
	if((alliedteam - axisteam) > pldiff)
	{
		advantage = ALLIES
	}
	else if((axisteam - alliedteam) > pldiff)
	{
		advantage = AXIS
	}
	else if((axisteam - alliedteam) <= pldiff || (alliedteam - axisteam) <= pldiff)
	{
		advantage = EVEN
	}
	return advantage
}


public checkfaketeams()
{
	new alliedteam = GetTeamClientCount(ALLIES)
	new axisteam = GetTeamClientCount(AXIS)
	new advantage = 0
	new pldiff = GetConVarInt(AutoBalancePlDiff)
	if((alliedteam - axisteam) > pldiff)
	{
		advantage = ALLIES
	}
	else if((axisteam - alliedteam) > pldiff)
	{
		advantage = AXIS
	}
	else if((axisteam - alliedteam) <= pldiff || (alliedteam - axisteam) <= pldiff)
	{
		advantage = EVEN
	}
	return advantage
}


public Action:BalanceTeams(Handle:timer, any:client)
{
	new currteam = GetClientTeam(client)
	if(currteam == SPEC)
	{
		return Plugin_Handled
	}
	TMSChangeToTeam(client, OpTeam[currteam])
	decl String:message[256]
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Format(message,sizeof(message),"%T", "Player Balanced", i, client, TeamName[OpTeam[currteam]])
			TMSMessage(i, message)
			if(g_autoswitch_lock[i] == 1)
			{
				g_autoswitch_lock[i] = 0
			}
		}
	}
	g_autoswitch_lock[client] = 1
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