#pragma semicolon 1

#include <sourcemod> 
#include <zombiereloaded>
#include <sdktools>
#include <morecolors>
#include <cstrike>
#include <devzones>

//#pragma newdecls required

bool OnBeacon = false;
bool g_bVipChosen = false;
bool g_bIsInfected[MAXPLAYERS+1];
bool g_bSlay;

int g_iVipClient = -1;
int g_Serial_Gen = 0;
int g_BeamSprite = -1;
int g_HaloSprite = -1;
int g_SprayBeacon[MAXPLAYERS+1] = { 0, ... };
float g_fEndRoundDelay = 5.0;

ConVar cvarVipTimer;
ConVar cvarVipEnable;


public Plugin myinfo =
{
	name		= "Very Important Person",
	description	= "If the VIP die or is infected, the round is over for humans.",
	author		= "Nano",
	version		= "1.1",
	url			= "http://steamcommunity.com/id/marianzet1"
}

public void OnConfigsExecuted() 
{
	g_fEndRoundDelay = FindConVar("mp_round_restart_delay").FloatValue;
}

public void OnPluginStart() 
{
	cvarVipTimer = CreateConVar("zr_viptimer", "20.0", "Time until a vip is chosen");
	cvarVipEnable = CreateConVar("zr_vipenable", "1", "Enable or disable the VIP function");
	
	RegConsoleCmd("sm_currentvip", Command_CurrentVIP);
	
	RegAdminCmd("sm_vipmode", Command_Enable, ADMFLAG_BAN);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
}

public Action Command_Enable(int client, int args)
{
	if (cvarVipEnable.BoolValue)
	{
		ServerCommand("zr_vipenable 0");
		ReplyToCommand(client, "[SM] You have disabled the VIPMode function");
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{cyan} %N{default} has {fullred}disabled{default} the plugin.", client);
		return Plugin_Handled;
	}
	else
	{
		ServerCommand("zr_vipenable 1");
		ReplyToCommand(client, "[SM] You have enabled the VIPMode function");
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{cyan} %N{default} has {blue}enabled{default} the plugin.", client);
		return Plugin_Handled;
	}
}

public Action Command_CurrentVIP(int client, int args)
{
	if (g_iVipClient == -1)
	{
		CPrintToChat(client, "{green}[{lightgreen}VIPMode{green}]{default} There's no current VIP!");
		return Plugin_Handled;
	}
	else
	{
		CPrintToChat(client, "{green}[{lightgreen}VIPMode{green}]{default} Current VIP:{cyan} %N", g_iVipClient);
		return Plugin_Handled;
	}
}

public void OnMapStart() 
{
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if (gameConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}
	
	char buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
	{
		g_BeamSprite = PrecacheModel(buffer);
	}
	if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
	{
		g_HaloSprite = PrecacheModel(buffer);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	g_bVipChosen = false;
	g_iVipClient = -1;
	g_bSlay = false;
	for (int i = 0; i <= MaxClients; i++) 
	{
		g_bIsInfected[i] = false;
	}

	float time = cvarVipTimer.FloatValue;
	if (time > 0.0) 
	{
		CreateTimer(time, timerVIP);
	}
}

Action timerVIP(Handle timer) 
{	
	if (!cvarVipEnable.BoolValue) 
	{
		g_bVipChosen = false;
		g_iVipClient = -1;
		
		return Plugin_Handled;
	}

	if (!g_bVipChosen) 
	{
		g_bVipChosen = true;
		if ((g_iVipClient = GetRandomPlayer(3)) < 1) 
		{
			CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} No one available as vip");
			slay();
			return Plugin_Handled;
		}
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{cyan} %N {default}is the new VIP! {green}Protect him!", g_iVipClient);
	}
	else
	{
		ToggleBeacon(g_iVipClient);
	}
	return Plugin_Handled;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn) 
{
	g_bIsInfected[client] = true;
	if (motherInfect && !g_bVipChosen && cvarVipEnable.BoolValue) 
	{
		g_bVipChosen = true;
		if ((g_iVipClient = GetRandomPlayer(3, client)) < 1) 
		{
			CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} No one available as vip");
			slay();
			return 0;
		}
		VipHasRemoved(g_iVipClient);
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{cyan} %N {default}is the new VIP! {green}Protect him!", g_iVipClient);
	}

	if (client == g_iVipClient) 
	{
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} The VIP {cyan}%N {default}has been {fullred}infected!", g_iVipClient);
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} Slaying all {blue}humans{default}...");
		g_bSlay = true;
		g_iVipClient = -1;
		slay();
	}
	return 0;
}

public void OnMapEnd()
{
	if(isValidClient(g_iVipClient))
	{
		VipHasRemoved(g_iVipClient);
	}
	g_iVipClient = -1;
	BeaconKilled();
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	if(isValidClient(g_iVipClient))
	{
		VipHasRemoved(g_iVipClient);
	}

	BeaconKilled();
}

public void VipHasRemoved(int client)
{
	if(OnBeacon)
	{
		KillEffect(client);
	}
	
	OnBeacon = false;
}

public void ToggleBeacon(int client)
{
	if(OnBeacon)
	OnBeacon = false;
	else
	OnBeacon = true;

	BeaconPerform(client);
}

public void BeaconPerform(int client)
{
	if (g_SprayBeacon[client] == 0)
	{
		CreateBeacon(client);
	}
	else
	{
		KillEffect(client);
	}
}

public void OnClientDisconnect(int client) 
{
	if(OnBeacon)
	{
		KillEffect(client);
	}
	
	OnBeacon = false;
	
	if (client == g_iVipClient) 
	{
		if ((g_iVipClient = GetRandomPlayer(3, client)) < 1) 
		{
			CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} No vip available");
			slay();
			return;
		}
		OnBeacon = true;
		ToggleBeacon(g_iVipClient);
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} The VIP {cyan}%N{default} has gone! The new VIP is {cyan}%N", client, g_iVipClient);
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if (g_bSlay) 
	{
		return Plugin_Continue;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client == g_iVipClient) 
	{
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} The VIP {cyan}%N {default}is {fullred}dead!", g_iVipClient);
		CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} Slaying all {blue}humans..");
		g_iVipClient = -1;
		slay();
	}
	return Plugin_Continue;
}

void slay() 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (isValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3) 
		{
			ForcePlayerSuicide(i);
		}
	}
}

bool isValidClient(int client) 
{
	return (0 < client <= MaxClients && IsClientInGame(client));
}

public void CreateBeacon(int client)
{
	g_SprayBeacon[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_Beacon, client | (g_Serial_Gen << 7), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Beacon(Handle timer, any value)
{
	int client = value & 0x7f;
	int serial = value >> 7;

	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_SprayBeacon[client] != serial)
	{
		KillEffect(client);
		return Plugin_Stop;
	}

	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, 190.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, {0, 0, 255, 255}, 10, 0);

	TE_SendToAll();

	GetClientEyePosition(client, vec);

	return Plugin_Continue;
}

public void KillEffect(int client)
{
	g_SprayBeacon[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

public void BeaconKilled()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillEffect(i);
	}
}

int GetRandomPlayer(int team, int client = 0) 
{
	int[] clients = new int[MaxClients+1];
	int clientCount; 
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i) && i != client && !g_bIsInfected[i]) 
		{
			clients[clientCount++] = i; 
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)]; 
}

public Zone_OnClientEntry(client, String:zone[])
{
	char classname[64];
	if(client < 1 || client > MaxClients || !IsClientInGame(client)) 
	{
		if (client == g_iVipClient)
		{
			CS_TerminateRound(g_fEndRoundDelay, CSRoundEnd_CTWin, false);
			GetEdictClassname(client, classname, 64);
			CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} The entity {cyan}%i %s{default} has entered in zone {green}%s", client, classname, zone);
		}
		else
		{
			CS_TerminateRound(g_fEndRoundDelay, CSRoundEnd_CTWin, false);
			CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} The VIP{cyan} %N {default}has entered in zone {green}%s", g_iVipClient, zone);
			CPrintToChatAll("{green}[{lightgreen}VIPMode{green}]{default} The VIP is safe. {green}The round is over.");
		}
	}
}