//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - High Ping Kicker
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - High Ping Kicker",
	author = "FeuerSturm, modif Micmacx",
	description = "HighPingKicker for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:HPKON = INVALID_HANDLE
new Handle:HPKMaxPing = INVALID_HANDLE
new Handle:HPKChecks = INVALID_HANDLE
new Handle:HPKDelay = INVALID_HANDLE
new Handle:HPKStopCheck = INVALID_HANDLE
new Handle:HPKKickMinPl = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new g_Checking[MAXPLAYERS+1], g_HighPing[MAXPLAYERS+1], g_LowPing[MAXPLAYERS+1]
new String:WLFeature[] = { "highpingkicker" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]
new Ping_Offset, Scoreboard


public OnPluginStart()
{
	HPKON = CreateConVar("dod_tms_highpingkicker", "1", "<1/0> = enable/disable HighPingKicker",_, true, 0.0, true, 1.0)
	HPKMaxPing = CreateConVar("dod_tms_hpkmaxping", "100", "<#> = max allowed Ping",_, true, 20.0)
	HPKChecks = CreateConVar("dod_tms_hpkpingchecks", "6", "<#> = number of high ping checks in a row to kick",_, true, 1.0, true, 12.0)
	HPKDelay = CreateConVar("dod_tms_hpkcheckdelay", "15", "<#> = number of seconds between each ping check loop",_, true, 5.0, true, 60.0)
	HPKStopCheck = CreateConVar("dod_tms_hpkstopchecks", "20", "<#> = number of low ping checks in a row to stop checking ping",_, true, 5.0)
	HPKKickMinPl = CreateConVar("dod_tms_hpkkickminpl", "5", "<#> = minimum number of active players on the server to start kicking  -  0 = always kick!",_, true, 0.0)
	ClientImmunity = CreateConVar("dod_tms_hpkimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions",_, true, 0.0, true, 1.0)
	AutoExecConfig(true,"addon_dodtms_highpingkicker", "dod_teammanager_source")
	LoadTranslations("dodtms_highpingkicker.txt")
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.5, DoDTMSRunning)
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("E")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_highpingkicker.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public OnClientDisconnect(client)
{	
	g_Checking[client] = 0
	g_HighPing[client] = 0
	g_LowPing[client] = 0
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
	g_Checking[client] = 0
	g_HighPing[client] = 0
	g_LowPing[client] = 0
	if(GetConVarInt(HPKON) == 1)
	{
		decl String:message[256]
		if(!IsClientImmune(client))
		{
			g_Checking[client] = 1
			new Float:check_delay = GetConVarFloat(HPKDelay)
			CreateTimer(check_delay, AnalyzePing, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
			Format(message,sizeof(message),"%T", "HPK KickIf", client, GetConVarInt(HPKMaxPing))
		}
		else
		{
			Format(message,sizeof(message),"%T", "HPK Admin", client)
		}
		TMSMessage(client, message)
	}
}

public OnMapStart()
{
	Ping_Offset = FindSendPropInfo("CPlayerResource", "m_iPing")
	Scoreboard = FindEntityByClassname(-1,"dod_player_manager")
}

public Action:AnalyzePing(Handle:timer, any:client)
{
	if(g_Checking[client] == 2 || !IsClientInGame(client))
	{
		return Plugin_Stop
	}
	new Ping_Client = Ping_Offset + (client * 4)
	new Ping = GetEntData(Scoreboard, Ping_Client)
	if(Ping >= GetConVarInt(HPKMaxPing))
	{
		g_HighPing[client]++
		g_LowPing[client] = 0
	}
	else
	{
		g_LowPing[client]++
	}
	CheckPingCount(client)
	return Plugin_Continue
}

public Action:CheckPingCount(client)
{
	if(g_HighPing[client] >= GetConVarInt(HPKChecks) && GetConVarInt(HPKKickMinPl) != 0)
	{
		if((GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS)) >= GetConVarInt(HPKKickMinPl))
		{
			g_Checking[client] = 2
			decl String:message[256]
			Format(message,sizeof(message),"%T", "HPK KickNow", client, GetConVarInt(HPKMaxPing))
			TMSMessage(client, message)
			CreateTimer(5.0, KickHPClient, client, TIMER_FLAG_NO_MAPCHANGE)
			return Plugin_Handled
		}
		return Plugin_Handled
	}
	new StopCheck = GetConVarInt(HPKStopCheck)
	if(g_LowPing[client] >= StopCheck && StopCheck != 0)
	{
		g_Checking[client] = 2
		decl String:message[256]
		Format(message,sizeof(message),"%T", "HPK LowPing", client, GetConVarInt(HPKMaxPing))
		TMSMessage(client, message)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:KickHPClient(Handle:timer, any:client)
{
	if(g_Checking[client] == 2 && IsClientInGame(client))
	{
		new maxping = GetConVarInt(HPKMaxPing)
		decl String:message[256]
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message,sizeof(message),"%T", "HPK KickedPlayer", i, client, maxping)
				TMSMessage(i, message)
			}
		}
		decl String:kickmessage[256]
		Format(kickmessage,sizeof(kickmessage),"%T", "HPK KickReason", client, maxping)
		TMSKick(client, kickmessage)
		g_Checking[client] = 0
		return Plugin_Handled
	}
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