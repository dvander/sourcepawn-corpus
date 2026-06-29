#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"
#define DEVELOPER_INFO false

new timercount = 0;
new IsFinale = 0;

public Plugin:myinfo = 
{
	name = "[L4D] Special Infected spawns fix",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("finale_escape_start", Event_FinaleEscapeStart);
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("round_start_post_nav", Event_RoundStart);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("tank_killed", Event_TankKilled);
	RegAdminCmd("sm_timer", Command_StartTimer, ADMFLAG_KICK, "");
	RegAdminCmd("sm_fixtank", Command_FixTank, ADMFLAG_KICK, "");
}

public SpawnTank()
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				new flags = GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
				FakeClientCommand(i, "z_spawn tank auto");
				SetCommandFlags("z_spawn", flags);
#if DEVELOPER_INFO				
				PrintToChatAll("\x04[DEVINFO]: \x03FixTank ( \x01Tank spawned?\x03 )");
#endif				
				return;
			}
		}
	}
}

public FixTank()
{
	if (IsTankAlive())
	{
#if DEVELOPER_INFO	
		PrintToChatAll("\x04[DEVINFO]: \x03FixTank ( \x01Tank is Alive\x03 )");
#endif		
		return;
	}
		
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				KickClient(i);
			}
			else
			{
#if DEVELOPER_INFO	
			PrintToChatAll("\x04[DEVINFO]: \x03FixTank() Player \x01%N\x03 Team \x01#%d", i, GetClientTeam(i));
#endif			
			}
		}
	}

	SpawnTank();
}

public Action:NextTimer(Handle:timer, any:client)
{
	if (timercount == -1)
	{
		timercount = 0;
		return;
	}

	if (timercount > 200)
	{
		PrintToChatAll("\x04[DEVINFO]: \x03Timer ( \x01%i\x03 )", timercount);
		FixTank();
	}
	
	if (timercount < 0)
		return;

	timercount++;
#if DEVELOPER_INFO		
	PrintToChatAll("\x04[DEVINFO]: \x03Timer ( \x01%i\x03 )", timercount);
#endif	
	CreateTimer(1.0, NextTimer);
}

public Action:Command_StartTimer(client, args)
{
	CreateTimer(1.0, NextTimer);
}

public Action:Command_FixTank(client, args)
{
	FixTank();
}

public Action:Event_FinaleEscapeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01finale_escape_start\x03 )");
#endif	
}

public Action:Event_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01finale_start\x03 )");
#endif	
	timercount = 0;
	IsFinale = 1;
	CreateTimer(1.0, NextTimer);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01round_start_post_nav\x03 )");
#endif	
	timercount = -1;
	IsFinale = 0;
}

public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01tank_spawn\x03 )");
#endif	
	timercount = -1;
}

public Action:Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01tank_killed\x03 )");
#endif	
	if (IsFinale)
	{
		timercount = 0;
		CreateTimer(1.0, NextTimer);
	}
}

stock IsTankAlive()
{
	decl String:ClientSteamID[12];
	decl String:ClientName[20];
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAuthString(i, ClientSteamID, sizeof(ClientSteamID));
			if (StrEqual(ClientSteamID, "BOT", false))
			{
				if (IsFakeClient(i))
				{
					if (GetClientName(i, ClientName, sizeof(ClientName)))
					{
						if (StrEqual(ClientName, "Tank", false) && GetClientHealth(i) > 1)
						{
							return 1;
						}
					}
				}
			}
		}
	}
	return 0;
}

stock GetPlayersFromTeam(const Team)
{
	new players_count = 0;
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == Team)
			{
				players_count++;
			}
		}
	}
	return players_count;
}			

public KickSpecialInfected()
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			decl String:ClientName[20];
			GetClientName(i, ClientName, sizeof(ClientName));
			if (!StrEqual(ClientName, "Tank", false))
			{
				KickClient(i);
				return 1;
			}
		}
	}
	return 0;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	decl String:ClientAuth[20];
//	decl String:ClientName[20];
	GetClientAuthString(client, ClientAuth, sizeof(ClientAuth));
	if (StrEqual(ClientAuth, "BOT", false) && GetPlayersFromTeam(3) > 4)
	{
#if DEVELOPER_INFO	
		PrintToChatAll("\x04[DEVINFO]: \x03OnClientConnect ( \x01Too many special infecteds here\x03 )");
#endif		
		KickSpecialInfected();
//		GetClientName(client, ClientName, sizeof(ClientName));
	}
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03OnClientConnect( \x01%N\x03 ); Infecteds count ( \x01%d\03 )", client, GetPlayersFromTeam(3));
#endif	
	return true;
}