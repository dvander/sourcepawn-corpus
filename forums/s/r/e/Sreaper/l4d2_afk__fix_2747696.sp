#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

public Plugin myinfo =  {
	name = "[L4D(2)] AFK Manager", 
	author = "Matthias Vance", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "http://www.matthiasvance.com/"
};

float advertiseInterval = 300.0;
Handle advertiseTimer = null;

float specTime[MAXPLAYERS + 1];
float afkTime[MAXPLAYERS + 1];

float checkInterval = 10.0;
float maxAfkSpecTime = 40.0;
float maxAfkKickTime = 480.0;
float joinTeamInterval = 60.0;
float timeLeftInterval = 5.0;

float lastMessage[MAXPLAYERS + 1];

float clientPos[MAXPLAYERS + 1][3];
float clientAngles[MAXPLAYERS + 1][3];

int messageLevel = 3;
int iTimeAfk;

public void OnPluginStart()
{
	CreateConVar("l4d_afkmanager_version", PLUGIN_VERSION, "[L4D(2)] AFK Manager", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	SetConVarString(FindConVar("l4d_afkmanager_version"), PLUGIN_VERSION);
	
	char temp[12];
	
	FloatToString(advertiseInterval, temp, sizeof(temp)); (CreateConVar("afk_adinterval", temp, "Interval in which the plugin will advertise the 'idle' command.")).AddChangeHook(convar_AdvertiseTime);
	FloatToString(maxAfkSpecTime, temp, sizeof(temp)); (CreateConVar("afk_spectime", temp, "AFK time after which you will be moved to the Spectator team.")).AddChangeHook(convar_AfkSpecTime);
	FloatToString(maxAfkKickTime, temp, sizeof(temp)); (CreateConVar("afk_kicktime", temp, "AFK time after which you will be kicked.")).AddChangeHook(convar_AfkKickTime);
	(CreateConVar("afk_messages", "3", "Control spec/kick messages. (0 = disable, 1 = spec, 2 = kick, 3 = spec + kick")).AddChangeHook(convar_Messages);
	FloatToString(joinTeamInterval, temp, sizeof(temp)); (CreateConVar("afk_joinmsg_time", temp)).AddChangeHook(convar_JoinMsgTime);
	FloatToString(timeLeftInterval, temp, sizeof(temp)); (CreateConVar("afk_warning_time", temp)).AddChangeHook(convar_WarningTime);
	
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	CreateTimer(1.0, MapStart);
	advertiseTimer = CreateTimer(advertiseInterval, timer_Advertise, _, TIMER_REPEAT);
	CreateTimer(checkInterval, timer_Check, _, TIMER_REPEAT);
	
	//AutoExecConfig(true, "l4d_afkmanager");
	
	// Register Console Commands
	RegConsoleCmd("sm_idle", Idle, "Switches yourself to spectate mode if you are alive");
}

public Action MapStart(Handle timer)
{
	OnMapStart();
}

public void OnMapStart()
{
	iTimeAfk = GetTime();
}

public void convar_JoinMsgTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	joinTeamInterval = StringToFloat(newValue);
}

public void convar_WarningTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	timeLeftInterval = StringToFloat(newValue);
}

public void convar_Messages(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (messageLevel <= 0)
	{
		convar.SetInt(0);
		return;
	}
	if (messageLevel >= 3)
	{
		convar.SetInt(3);
		return;
	}
	messageLevel = convar.IntValue;
}

public Action timer_Check(Handle timer)
{
	float currentPos[3];
	float currentAngles[3];
	
	int team;
	bool isAFK;
	int client, index;
	
	for (client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			team = GetClientTeam(client);
			if (team == 1)
			{
				specTime[client] += checkInterval;
				if (specTime[client] >= maxAfkKickTime)
				{
					
					if (GetRealClientCount() > 25)
					{
						
						if (!IsVip(client))
						{
							KickClient(client, "You were AFK for too long.");
							if (messageLevel >= 2)
								PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 was kicked.", client);
						}
					}
					
					if (GetClientCount(false) >= 30 && !IsRoot(client))
					{
						KickClient(client, "You were AFK for too long.");
						if (messageLevel >= 2)
							PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 was kicked.", client);
					}
					else
						specTime[client] = (specTime[client] - checkInterval - 1);
				}
				else
				{
					if (GetClientTime(client) - lastMessage[client] >= timeLeftInterval)
					{
						if (!IsRoot(client))
							PrintToChat(client, "\x04[\x05AFK Manager\x04]\x01 You can spectate for \x04%d\x01 more seconds before you will be kicked.", RoundToFloor(maxAfkKickTime - specTime[client]));
						lastMessage[client] = GetClientTime(client);
					}
					if (GetClientTime(client) - lastMessage[client] >= joinTeamInterval)
					{
						if (!IsRoot(client))
							PrintToChat(client, "\x04[\x05AFK Manager\x04]\x01 Say \x05!join\x01 to join game.");
						lastMessage[client] = GetClientTime(client);
					}
				}
			}
			else if (IsPlayerAlive(client) && (team == 2 || team == 3))
			{
				GetClientAbsOrigin(client, currentPos);
				GetClientAbsAngles(client, currentAngles);
				
				isAFK = true;
				for (index = 0; index < 3; index++)
				{
					if (currentPos[index] != clientPos[client][index])
					{
						isAFK = false;
						break;
					}
				}
				if (isAFK)
				{
					for (index = 0; index < 3; index++)
					{
						if (currentAngles[index] != clientAngles[client][index])
						{
							isAFK = false;
							break;
						}
					}
				}
				if (isAFK)
				{
					afkTime[client] += checkInterval;
					if (afkTime[client] >= maxAfkSpecTime)
					{
						if (GetClientCount(false) >= 30)
						{
							KickClient(client, "Sorry, no open slots for spectators.");
							if (messageLevel >= 2)
								PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 was kicked. No open slots for spectators.", client);
						}
						else
							ClientAFK(client);
					}
				}
				else
					afkTime[client] = 0.0;
				
				for (index = 0; index < 3; index++)
				{
					clientPos[client][index] = currentPos[index];
					clientAngles[client][index] = currentAngles[index];
				}
			}
		}
	}
	return Plugin_Continue;
}

void ClientAFK(int client)
{
	if (!IsClientInGame(client))
		return;
	if (IsFakeClient(client))
		return;
	if (GetClientTeam(client) == 1)
		return;
	
	float fAFK = GetRandomFloat(0.1, 5.1);
	CreateTimer(fAFK, Timer_Afk, client);
}

public Action Timer_Afk(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) != 1)
			{
				int afktime = (GetTime() - iTimeAfk);
				if (afktime < 50)
					afkTime[client] = (afkTime[client] - (checkInterval + 1.0));
				else
				{
					if (GetClientCount(false) >= 30)
					{
						KickClient(client, "Sorry, no open slots for spectators.");
						if (messageLevel >= 2)
							PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 was kicked. No open slots for spectators.", client);
						return Plugin_Stop;
					}
					
					if (messageLevel == 1 || messageLevel == 3)
						PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 was moved to Spectator team.", client);
					PrintToServer("[AFK Manager] Player '%N' was moved to Spectator team.", client);
					//ServerCommand("sm_switchplayer2 #%d 1", GetClientUserId(client));
					ChangeClientTeam(client, 1);
					ForcePlayerSuicide(client);
					iTimeAfk = GetTime();
				}
			}
		}
	}
	return Plugin_Stop;
}

int GetRealClientCount()
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
				clients++;
		}
	}
	return clients;
}

public void convar_AfkSpecTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	maxAfkSpecTime = StringToFloat(newValue);
	if (maxAfkSpecTime == 0.0 || maxAfkSpecTime <= 30.0)
	{
		convar.SetFloat(30.0);
		return;
	}
}

public void convar_AfkKickTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	maxAfkKickTime = StringToFloat(newValue);
	if (maxAfkKickTime == 0.0 || maxAfkKickTime <= 60.0)
	{
		convar.SetFloat(60.0);
		return;
	}
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetEventInt(event, "team");
	switch (team)
	{
		case 1:specTime[client] = 0.0;
		case 2, 3:afkTime[client] = 0.0;
	}
	if (event.GetBool("disconnected"))
	{
		clientPos[client] = view_as<float>( { 0.0, 0.0, 0.0 } );
		clientAngles[client] = view_as<float>( { 0.0, 0.0, 0.0 } );
	}
}

public void convar_AdvertiseTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (advertiseTimer != null)
	{
		KillTimer(advertiseTimer);
		advertiseTimer = null;
	}
	advertiseInterval = StringToFloat(newValue);
	if (advertiseInterval <= 10.0)
	{
		convar.SetFloat(10.0);
		return;
	}
	if (advertiseInterval > 0.0)
		advertiseTimer = CreateTimer(advertiseInterval, timer_Advertise, _, TIMER_REPEAT);
}

public Action Idle(int client, int args)
{
	
	if (GetClientTeam(client) != 1)
	{
		if (IsPlayerAlive(client))
		{
			ChangeClientTeam(client, 1);
			ForcePlayerSuicide(client);
			PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 has moved to Spectator team (!idle).", client);
			PrintToServer("[AFK Manager] Player '%N' has moved to Spectator team (!idle).", client);
		}
		else
		{
			PrintToChat(client, "[AFK Manager] You cannot use the !idle command while dead.", client);
		}
	}
}

public Action timer_Advertise(Handle timer)
{
	PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Use \x05!idle \x01if you plan to go AFK for a while.");
	return Plugin_Continue;
}

bool IsRoot(int client)
{
	AdminId admin = GetUserAdmin(client);
	
	if (admin == INVALID_ADMIN_ID)
		return false;
	if (GetAdminFlag(admin, Admin_Root) || GetAdminFlag(admin, Admin_Password))
		return true;
	
	return true;
}

bool IsVip(int client)
{
	AdminId admin = GetUserAdmin(client);
	
	if (admin == INVALID_ADMIN_ID)
		return false;
	if (GetAdminFlag(admin, Admin_Reservation))
		return true;
	return true;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			afkTime[i] = 0.0;
		}
		i += 1;
	}
} 