#include <sourcemod>

#define PL_VERSION "1.1"

new bool:bBlockOnNextFrame[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "BHop spam block",
	author = "sheo",
	description = "Fixes jump command spam to prevent too easy bunnyhopping",
	version = PL_VERSION,
	url = "http://steamcommunity.com/groups/b1com"
};

public OnPluginStart()
{
	decl String:gfstring[128];
	GetGameFolderName(gfstring, sizeof(gfstring));
	if (!StrEqual(gfstring, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 dead 2 only!");
	}
	CreateConVar("l4d2_bhop_spam_block_version", PL_VERSION, "BHop spam block version", FCVAR_PLUGIN | FCVAR_NOTIFY);
}

public OnClientPutInServer(client)
{
	bBlockOnNextFrame[client] = false;
}

public OnClientDisconnect(client)
{
	bBlockOnNextFrame[client] = false;
}

public Action:OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (bBlockOnNextFrame[client])
	{
		bBlockOnNextFrame[client] = false;
		SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil",  GetGameTime() + 0.4);
	}
	if ((buttons & IN_JUMP) && IsClientInGame(client) && !IsFakeClient(client) && (IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_isGhost") == 1))
	{
		if (GetGameTime() >= GetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil"))
		{
			bBlockOnNextFrame[client] = true;
		}
		else if (GetClientTeam(client) == 3)
		{
			buttons = (buttons & ~IN_JUMP);
		}
	}
	return Plugin_Continue;
}