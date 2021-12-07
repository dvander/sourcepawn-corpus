/* Includes */
#include <sourcemod>

/* Plugin Information */
public Plugin:myinfo = 
{
	name		= "No Vote Under Supervision",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Block players ability to call votes while an Admin is present",
	version		= "1.0.0",
	url		= "mrzerodk@gmail.com"
}

/* Globals */
new bool:g_isAnyAdminOn
new bool:g_isAdmin[MAXPLAYERS + 1];

/* Plugin Functions */
public OnPluginStart()
{
	AddCommandListener(OnCallVoteCommand, "callvote")
}

public Action:OnCallVoteCommand(client, const String:command[], argc)
{
	if (g_isAnyAdminOn && !CheckCommandAccess(client, "callvote_access", ADMFLAG_GENERIC, true))
	{
		return Plugin_Handled
	}
	
	return Plugin_Continue
}

// Account for late load
public OnAllPluginsLoaded()
{
	new bool:anyAdminOn = false
	for (new i = 0; i < MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue
		}

		if (CheckCommandAccess(i, "callvote_access", ADMFLAG_GENERIC, true))
		{
			g_isAdmin[i] = true
			anyAdminOn = true
		}
	}
	g_isAnyAdminOn = anyAdminOn
}

public OnClientPostAdminCheck(client)
{
	g_isAdmin[client] = CheckCommandAccess(client, "callvote_access", ADMFLAG_GENERIC, true)
	if (g_isAdmin[client])
	{
		g_isAnyAdminOn = true
	}
}

public OnClientDisconnect(client)
{
	if (g_isAdmin[client])
	{
		g_isAdmin[client] = false
		new bool:anyAdminOn = false
		for (new i = 0; i < MaxClients; i++)
		{
			if (g_isAdmin[i])
			{
				anyAdminOn = true
				break
			}
		}
		g_isAnyAdminOn = anyAdminOn
	}
}