#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Psycheat"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new String:firearms[512] = "glock usp p228 deagle elite fiveseven m3 xm1014 galil ak47 scout sg552 awp g3sg1 famas m4a1 aug sg550 mac10 tmp mp5navy ump45 p90 m249";
new Handle:sm_damageinfo;

new String:pastmessages[MAXPLAYERS + 1][4][64]; // store last 5 damage information for each client
new String:clientname[MAXPLAYERS + 1][32];
new bool:IsHuman[MAXPLAYERS + 1];
new clientteam[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Damage Information",
	author = PLUGIN_AUTHOR,
	description = "Show last 4 damage information on the bottom right keyhinttext",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	sm_damageinfo = CreateConVar("sm_damageinfo", "1.0", "Enable/Disable", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(sm_damageinfo, HurtEventChange);
	
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_team", OnPlayerChangeTeam);
	HookEvent("player_changename", OnPlayerChangeName);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public HurtEventChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		HookEvent("player_hurt", OnPlayerHurt);
		HookEvent("player_spawn", OnPlayerSpawn);
		HookEvent("player_team", OnPlayerChangeTeam);
		HookEvent("player_changename", OnPlayerChangeName);
		
		HookEvent("round_start", OnRoundStart);
		HookEvent("round_end", OnRoundEnd);
		
		ResetPastMsgAll();
	}
	else
	{
		
		UnhookEvent("player_hurt", OnPlayerHurt);
		UnhookEvent("player_spawn", OnPlayerSpawn);
		UnhookEvent("player_team", OnPlayerChangeTeam);
		UnhookEvent("player_changename", OnPlayerChangeName);
		
		UnhookEvent("round_start", OnRoundStart);
		UnhookEvent("round_end", OnRoundEnd);
		
		ResetPastMsgAll();
	}
}

public OnClientPutInServer(client)
{
	GetClientName(client, clientname[client], 32);
	IsHuman[client] = !IsFakeClient(client);
	ResetPastMsg(client);
}

public OnClientDisconnect(client)
{
	clientname[client] = NULL_STRING;
	clientteam[client] = CS_TEAM_NONE;
	IsHuman[client] = false;
	ResetPastMsg(client);
}

public Action:OnRoundStart(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	ResetPastMsgAll();
}

public Action:OnRoundEnd(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	ResetPastMsgAll();
}

public Action:OnPlayerChangeName(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "newname", clientname[client], 32);
}

public Action:OnPlayerChangeTeam(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	clientteam[client] = GetEventInt(event, "team");
	
	ResetPastMsg(client);
}

public Action:OnPlayerSpawn(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	clientteam[client] = GetClientTeam(client);
	
	ResetPastMsg(client);
}

public Action:OnPlayerHurt(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (client == 0)
	return;
	
	if (!IsHuman[client] && !IsHuman[attacker]) // if both victim and attacker are not human, no point to process further
		return;
	
	decl String:weapon[16];
	new damage = GetEventInt(event, "dmg_health");
	new hitgroup = GetEventInt(event, "hitgroup");
	GetEventString(event, "weapon", weapon, 16);
		
	CreateAndPrintMessage(client, attacker, weapon, damage, hitgroup);
}

CreateAndPrintMessage(int client, int attacker, const String:weapon[16], int damage, int hitgroup)
{
	decl String:buffermsg[512] = "";
	decl String:clientmsg[64];
	decl String:attackermsg[64];
	
	if (attacker != 0) // damage caused by players and not "world"
	{
		if (client != attacker) // damage not self inflicted
		{
			FormatMessages(clientmsg, attackermsg, client, attacker, weapon, damage, hitgroup);
			ShowMessages(client, buffermsg, clientmsg);
			ShowMessages(attacker, buffermsg, attackermsg);
		}
		else // self-inflicted damage, most likely grenade
		{
			Format(clientmsg, 64, "You hurt yourself for %d damage!", damage);
			ShowMessages(client, buffermsg, clientmsg);
		}
	}
	else // damage inflicted by "world": fall damage, drown, c4, ...
	{
		Format(clientmsg, 64, "You're hurt for %d damage!", damage);
		ShowMessages(client, buffermsg, clientmsg);
	}
}

FormatMessages(String:clientmsg[64], String:attackermsg[64], int client, int attacker, const String:weapon[16], int damage, int hitgroup)
{
	decl String:team[2][4];
	GetTeamString(team, client, attacker);
	
	if (StrContains(firearms, weapon) != -1)
	{
		decl String:bodypart[16];
		GetBodyPart(bodypart, hitgroup);
		Format(clientmsg, 64, "%s<%s> shot you: <%s><%s><%d>", clientname[attacker], team[1], weapon, bodypart, damage);
		Format(attackermsg, 64, "You shot %s<%s>: <%s><%s><%d>", clientname[client], team[0], weapon, bodypart, damage);
	}
	else if (StrEqual(weapon, "knife"))
	{
		Format(clientmsg, 64, "%s<%s> knifed you! <%d>", clientname[attacker], team[1], damage);
		Format(attackermsg, 64, "%You knifed %s<%s>! <%d>", clientname[client], team[0], damage);
	}
	else if (StrEqual(weapon, "hegrenade"))
	{
		Format(clientmsg, 64, "Grenade! <%d><%s><%s>", damage, clientname[attacker], team[1]);
		Format(attackermsg, 64, "You blast %s<%s> for %d health!", clientname[client], team[0], damage);
	}
	else
	{
		Format(clientmsg, 64, "%s<%s> hurt you for %d health!", clientname[attacker], team[1], damage);
		Format(attackermsg, 64, "You hurt %s<%s> for %d health!", clientname[client], team[0], damage);
	}
}

GetTeamString(String:team[2][4], int client, int attacker)
{
	switch (clientteam[client])
	{
		case CS_TEAM_T:team[0] = "T";
		case CS_TEAM_CT:team[0] = "CT";
	}
	
	switch (clientteam[attacker])
	{
		case CS_TEAM_T:team[1] = "T";
		case CS_TEAM_CT:team[1] = "CT";
	}
}

GetBodyPart(String:bodypart[16], int hitgroup)
{
	switch (hitgroup)
	{
		case 0:Format(bodypart, 16, "body");
		case 1:Format(bodypart, 16, "headshot");
		case 2:Format(bodypart, 16, "chest");
		case 3:Format(bodypart, 16, "stomach");
		case 4:Format(bodypart, 16, "left arm");
		case 5:Format(bodypart, 16, "right arm");
		case 6:Format(bodypart, 16, "left leg");
		case 7:Format(bodypart, 16, "right leg");
	}
}

ShiftMessages(int client)
{
	for (new i = 0; i < 3; i++)
		pastmessages[client][i] = pastmessages[client][i + 1];
}

AppendMessages(String:buffermsg[512], int client)
{
	for (new i = 0; i <= 3; i++)
	{
		decl String:buffer[64];
		Format(buffer, 64, "%s\n", pastmessages[client][i]);
		StrCat(buffermsg, 512, buffer);
	}
}

PrintKeyHintText(int client, const String:message[])
{
	new Handle:buffer = StartMessageOne("KeyHintText", client);
	if (buffer != INVALID_HANDLE)
	{
		BfWriteByte(buffer, 1);
		BfWriteString(buffer, message);
		EndMessage();
	}
}

ShowMessages(int client, String:buffermsg[512], const String:message[64])
{
	if (IsClientInGame(client) && IsHuman[client])
	{
		ShiftMessages(client);
		pastmessages[client][3] = message;
		AppendMessages(buffermsg, client);
		PrintKeyHintText(client, buffermsg);
	}
}

stock ResetPastMsg(int client)
{
	for (new i = 0; i <= 3; i++)
		pastmessages[client][i] = "";
}

stock ResetPastMsgAll()
{
	for (new i = 1; i <= MaxClients; i++)
		ResetPastMsg(i);
}