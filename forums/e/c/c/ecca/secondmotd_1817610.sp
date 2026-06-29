#include <sourcemod>

#pragma semicolon 1

#define VERSION "1.0"

new Handle:cvar_Contents;
new Handle:cvar_ContentType;

new bool:g_bLate = false;

new bool:g_bViewedMotd[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "[CSS] Second MOTD",
	author = "Powerlor & ecca",
	description = "Show Second MOTD after class choice",
	version = VERSION,
	url = "<- URL ->"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLate = late;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("secondmotd_version", VERSION, "Second MOTD Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cvar_Contents = CreateConVar("secondmotd_contents", "", "Second MOTD Contents. 192 bytes maximum.");
	cvar_ContentType = CreateConVar("secondmotd_contenttype", "1", "Second MOTD Type:\n0 = Plain Text\n1 = Autodetect\n2 = URL\n3 = File", FCVAR_NONE, true, 0.0, true, 3.0);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	AutoExecConfig(true, "secondmotd");
}

public OnConfigsExecuted()
{
	if (g_bLate)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				g_bViewedMotd[i] = true;
			}
		}
		g_bLate = false;
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			g_bViewedMotd[i] = false;
		}
	}
}

public OnClientDisconnect(client)
{
	g_bViewedMotd[client] = false;
}

public Action:Command_JoinTeam(client, const String:command[], argc) 
{	
	if (client < 1 || client > MaxClients || IsFakeClient(client) || g_bViewedMotd[client])
	{
		return;
	}
	
	new msgType = GetConVarInt(cvar_ContentType);
	decl String:msg[192];
	GetConVarString(cvar_Contents, msg, sizeof(msg));
	
	g_bViewedMotd[client] = true;

	ShowMOTDPanel(client, "Message Of The Day", msg, msgType);
}
