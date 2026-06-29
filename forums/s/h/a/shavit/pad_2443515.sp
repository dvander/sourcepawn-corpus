#include <sourcemod>
#include <bhopstats>

#pragma newdecls required
#pragma semicolon 1

bool gB_PadEnabled[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Scroll Pad",
	author = "shavit",
	description = "Adds `sm_pad` that shows you the amount of scrolls you had per jump.",
	version = BHOPSTATS_VERSION,
	url = "https://github.com/shavitush/bhopstats"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_pad", Command_Pad, "Toggle scroll pad.");
}

public Action Command_Pad(int client, int args)
{
	gB_PadEnabled[client] = !gB_PadEnabled[client];

	ReplyToCommand(client, "Pad %s.", (gB_PadEnabled[client])? "enabled":"disabled");

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	gB_PadEnabled[client] = false;
}

public void Bunnyhop_OnJumpPressed(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !gB_PadEnabled[i])
		{
			continue;
		}

		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");

		if(i == client || (IsClientObserver(i) && (iObserverMode >= 3 || iObserverMode <= 5) && GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client))
		{
			PrintCenterText(i, "%d", BunnyhopStats.GetScrollCount(client));
		}
	}
}
