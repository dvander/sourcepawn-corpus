#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION "1.0"

new Handle:g_Cvar_ShowWarmodeMessage = INVALID_HANDLE;
new Handle:g_Cvar_MessageLines = INVALID_HANDLE;
new Handle:g_Cvar_MessageDelay = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Chat Welcome Message",
	author = "Harper",
	description = "Displays a configurable welcome message on player connect.",
	version = PLUGIN_VERSION,
	url = "http://hl2dm.org"
}

public OnPluginStart()
{
	LoadTranslations("chatwelcomemessage.phrases");
	AutoExecConfig(true, "plugin.chatwelcomemessage");
	
	g_Cvar_MessageLines = CreateConVar("sm_cwm_messagelines", "3", "How many lines of the welcome message to send (set to 0 to disable plugin)", _, true, 0.0, true, 8.0);
	g_Cvar_MessageDelay = CreateConVar("sm_cwm_delay", "3.0", "How many seconds after player connect to display the welcome message", _, true, 0.0);	
	g_Cvar_ShowWarmodeMessage = CreateConVar("sm_cwm_warmode", "0", "Show warmode (alternative) welcome message", _, true, 0.0, true, 1.0);
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_MessageLines) != 0)
	{
		CreateTimer (GetConVarFloat(g_Cvar_MessageDelay), Timer_WelcomeMessage, client);
	}
}

public Action:Timer_WelcomeMessage(Handle: timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (GetConVarBool(g_Cvar_ShowWarmodeMessage))
		{
			switch(GetConVarInt(g_Cvar_MessageLines))
			{
				case 1:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
				}
				case 2:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage2", LANG_SERVER);
				}
				case 3:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage3", LANG_SERVER);
				}
				case 4:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage4", LANG_SERVER);
				}
				case 5:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage5", LANG_SERVER);
				}
				case 6:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage5", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage6", LANG_SERVER);
				}
				case 7:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage5", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage6", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage7", LANG_SERVER);
				}
				case 8:
				{
					CPrintToChat (client, "%T", "WarmodeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage5", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage6", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage7", LANG_SERVER);
					CPrintToChat (client, "%T", "WarmodeMessage8", LANG_SERVER);
				}
			}
		}
		else
		{
			switch(GetConVarInt(g_Cvar_MessageLines))
			{
				case 1:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
				}
				case 2:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage2", LANG_SERVER);
				}
				case 3:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage3", LANG_SERVER);
				}
				case 4:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage4", LANG_SERVER);
				}
				case 5:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage5", LANG_SERVER);
				}
				case 6:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage5", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage6", LANG_SERVER);
				}
				case 7:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage5", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage6", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage7", LANG_SERVER);
				}
				case 8:
				{
					CPrintToChat (client, "%T", "WelcomeMessage1", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage2", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage3", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage4", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage5", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage6", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage7", LANG_SERVER);
					CPrintToChat (client, "%T", "WelcomeMessage8", LANG_SERVER);
				}
			}
		}
	}
}	