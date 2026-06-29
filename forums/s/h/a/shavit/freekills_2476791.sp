// made this a while ago for my jailbreak server and it works fine
#include <sourcemod>
#include <cstrike>

#define PREFIX "[Jailbreak]"

int gI_FK_LastKiller[MAXPLAYERS+1];
bool gB_UsedFK[MAXPLAYERS+1] = {false, ...};

char gS_FK_LastKiller[MAXPLAYERS+1][MAX_NAME_LENGTH];
char gS_FK_LastKiller_Auth[MAXPLAYERS+1][32];

public void OnPluginStart()
{
	RegConsoleCmd("sm_fk", Command_Freekill, "Report a freekill, no abuses.");
	RegConsoleCmd("sm_freekill", Command_Freekill, "Report a freekill, no abuses.");

	HookEvent("player_death", Player_Death);
}

public Action Command_Freekill(int client, int args)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}

	if(IsPlayerAlive(client))
	{
		ReplyToCommand(client, "%s You have to be dead to use this command.", PREFIX);

		return Plugin_Handled;
	}

	if(GetClientTeam(client) != CS_TEAM_T)
	{
		ReplyToCommand(client, "%s You have to be a terrorist to use this command.", PREFIX);

		return Plugin_Handled;
	}

	if(gB_UsedFK[client])
	{
		ReplyToCommand(client, "%s This command cannot be used more than once per round, sorry.", PREFIX);

		return Plugin_Handled;
	}

	if((IsClientConnected(gI_FK_LastKiller[client]) && IsClientInGame(gI_FK_LastKiller[client]) && GetClientTeam(gI_FK_LastKiller[client]) != CS_TEAM_CT) || gI_FK_LastKiller[client] == client)
	{
		ReplyToCommand(client, "%s You can only report a valid freekill if a CT killed you.", PREFIX);

		return Plugin_Handled;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || !CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
		{
			continue;
		}

		for(int j = 0; j < 2; j++)
		{
			if(IsClientConnected(i) && IsClientInGame(i))
			{
				PrintToChat(i, " \x02%N\x01 reported a freekill by \x02%N\x01!!!", client, gI_FK_LastKiller[client]);
			}

			else
			{
				PrintToChat(i, " \x02%N\x01 reported a freekill by \x02%s [%s]\x01!!!", client, gS_FK_LastKiller[client], gS_FK_LastKiller_Auth[client]);
			}
		}
	}

	gB_UsedFK[client] = true;

	return Plugin_Handled;
}

public Action Player_Death(Handle event, const char[] name, bool dB)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	gI_FK_LastKiller[client] = attacker;

	if(attacker > 0)
	{
		GetClientName(attacker, gS_FK_LastKiller[client], 32);
		GetClientAuthId(attacker, AuthId_Engine, gS_FK_LastKiller_Auth[client], 32);
	}
}
