#include <sourcemod>
#include <sdktools>

new Float:Damage[MAXPLAYERS + 1];
new Float:Multiplier[MAXPLAYERS + 1];
new Float:Punishment[MAXPLAYERS + 1];
//new Handle:l4d_tk_startvote_points;
//new Handle:l4d_tk_deadline;

public Plugin:myinfo = 
{
	name = "[L4D2] Stop TK",
	author = "Jonny",
	description = "",
	version = "1.3.3",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("heal_success", Event_MedkitUsed);
	HookEvent("revive_success", Event_ReviveSuccess);
	CreateConVar("l4d_tk_deadline", "750", "TK Points needed to get banned.", FCVAR_PLUGIN);
	CreateConVar("l4d_tk_startvote_points", "200", "TK Points needed to get voteban.", FCVAR_PLUGIN);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return Plugin_Continue;

	if (client == target)
		return Plugin_Continue;

	decl String:ClientSteamID[32];
	decl String:TargetSteamID[32];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	new Float:X;

	X = (1 + (Multiplier[client] / 10));

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");

	PrintToChat(client, "\x01%N attacked %N", client, target);
	PrintToChat(client, "\x03%d (%d - voteban; 750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 200);
	PrintToChat(target, "\x01%N attacked %N", client, target);
	PrintToChat(target, "\x03%d (%d - voteban; 750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 200);
	CheckPunishmentPoints(client);

	return Plugin_Continue;
}

public Action:Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return Plugin_Continue;
	if (client == target)
		return Plugin_Continue;

	decl String:ClientSteamID[32];
	decl String:TargetSteamID[32];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	new Float:X;

	X = (10 + Multiplier[client]) / 10;

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");
	Multiplier[client]++;

	PrintToChat(client, "\x04%N attacked %N", client, target);
	PrintToChat(client, "\x03%d (%d - voteban; 750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 200);
	PrintToChat(target, "\x04%N attacked %N", client, target);
	PrintToChat(target, "\x03%d (%d - voteban; 750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 200);
	CheckPunishmentPoints(client);

	return Plugin_Continue;
}

public Action:Event_MedkitUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));

	decl String:ClientSteamID[32];
	decl String:TargetSteamID[32];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	if (client == target)
		return Plugin_Continue;

	Damage[client] = Damage[client] - 150;
	if (Damage[client] < 0.0)
	{
		Damage[client] = 0.0;
		Multiplier[client] = Multiplier[client] - 0.15;
	}
	else
	{
		Multiplier[client] = Multiplier[client] - 0.1;
	}
	new Float:X;
	X = (10 + Multiplier[client]) / 10;
	if (Multiplier[client] < 0.1)
	{
		Multiplier[client] = 0.1;
	}
	PrintToChat(client, "\x05You have cured %N and your TK points has gone down: \x04%f x %f = %d", target, Damage[client], X, RoundToZero(X * Damage[client])); 
//	PrintToChat(client, "\x04You healed somebody and lost some TK points. Now you have: \x05%f x %f = %d TK points!", Damage[client], X, RoundToZero(X * Damage[client]));

	return Plugin_Continue;
}

public Action:Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));

	decl String:ClientSteamID[32];
	decl String:TargetSteamID[32];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	Damage[client] = Damage[client] - 50;
	if (Damage[client] < 0.0)
	{
		Damage[client] = 0.0;
		Multiplier[client] = Multiplier[client] - 0.05;
	}
	else
	{
		Multiplier[client] = Multiplier[client] - 0.033333;
	}
	new Float:X;
	X = (10 + Multiplier[client]) / 10;
	if (Multiplier[client] < 0.1)
	{
		Multiplier[client] = 0.1;
	}
	PrintToChat(client, "\x05You have revived %N and your TK points has gone down: \x04%f x %f = %d", target, Damage[client], X, RoundToZero(X * Damage[client])); 

	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		Damage[client] = 0.0;
		Multiplier[client] = 1.0;
		Punishment[client] = 0.0;
	}
}

public CheckPunishmentPoints(client)
{
	new Float:TotalDamage;
	new Float:X;

	X = (10 + Multiplier[client]) / 10;

	TotalDamage = Damage[client] * X;
	
//	if (GetUserFlagBits(client) > 0)
//		return;
	
	if (TotalDamage > 200.0)
	{
		if (TotalDamage > 750.0)
		{
			if (Punishment[client] < 750.0)
			{
				decl String:ClientSteamID[32];
				GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
				ServerCommand("banid 0 %s", ClientSteamID);
				ServerCommand("writeid");
				ServerCommand("kick %N", client);
				Punishment[client] = TotalDamage;
				PrintToChatAll("\x04%N (\x05%s\x04) has has been permanently banned [\x05%d TK points!\x04]", client, ClientSteamID, RoundToZero(X * Damage[client]));
				new RND = GetRandomInt(1, 3);
				if (RND == 1)
				{
					PrintToChatAll("\x04%Ciao Bambino!");
				}
				else if (RND == 2)
				{
					PrintToChatAll("\x04%Bye! Come again!");
				}
				else if (RND == 3)
				{
					PrintToChatAll("\x04%Dirty Bastard!");
				}
				decl String:file[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, file, sizeof(file), "logs/stop_tk.log");
				LogToFileEx(file, "%N (%s) has has been permanently banned [%d TK points!]", client, ClientSteamID, RoundToZero(X * Damage[client]));
			}
		}
		else if ((TotalDamage - Punishment[client]) > 200.0)
		{
			Punishment[client] = TotalDamage;
			PrintToChatAll("\x05Autoban vote : %N (%d TK Points)", client, RoundToZero(Punishment[client])); 
			ServerCommand("sm_voteban %N", client);
			decl String:file[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, file, sizeof(file), "logs/stop_tk.log");
			LogToFileEx(file, "VoteBan Started: %N [%d TK points!]", client, RoundToZero(X * Damage[client]));
		}
	}
}