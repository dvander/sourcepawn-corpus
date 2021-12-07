#include <sdktools>
#include <clientprefs>

bool g_bSpecListStealth[MAXPLAYERS + 1];

bool g_bSpecListEnabled[MAXPLAYERS + 1];
Handle g_hSpecListEnabledCookie;

public Plugin myinfo =
{
	name = "[SM] Spectator List",
	description = "",
	author = "AllliedModder",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_speclist", Command_SpecList);
	RegAdminCmd("sm_stealth", Command_Stealth, ADMFLAG_KICK);
	
	g_hSpecListEnabledCookie = RegClientCookie("Speclist_Enabled", "Speclist on or off", CookieAccess_Private);
	
	// late loading
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnMapStart()
{
	CreateTimer(2.5, Timer_UpdateHudHint, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	g_bSpecListEnabled[client] = true;
	g_bSpecListStealth[client] = false;
}

public void OnClientCookiesCached(int client)
{
	char value[16];
	GetClientCookie(client, g_hSpecListEnabledCookie, value, sizeof(value));
	
	g_bSpecListEnabled[client] = (value[0] != '\0' && StringToInt(value));
}

public Action Command_Stealth(int client, int args)
{
	g_bSpecListStealth[client] = !g_bSpecListStealth[client];
	
	if(g_bSpecListStealth[client])
		ReplyToCommand(client, "\x01[\x02SM\x01] You will now be hidden from speclist.");
	else
		ReplyToCommand(client, "\x01[\x02SM\x01] You will now be shown on speclist.");
	
	return Plugin_Handled;
}

public Action Command_SpecList(int client, int args)
{
	g_bSpecListEnabled[client] = !g_bSpecListEnabled[client];
	SetClientCookie(client, g_hSpecListEnabledCookie, g_bSpecListEnabled[client] ? "1" : "0");
	ReplyToCommand(client, "\x01[\x02SM\x01] Spectator list %s.", g_bSpecListEnabled[client] ? "enabled" : "disabled");
	
	return Plugin_Handled;
}

public Action Timer_UpdateHudHint(Handle timer)
{
	static char szText[256];
	
	for(int client = 1; client <= MaxClients; client++)
	{
		bool bDisplayHint;
		szText = "";
		
		if(IsPlayerAlive(client))
		{
			// first loop, for creating the hud string
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i) || !IsClientObserver(i) || g_bSpecListStealth[i])
				{
					continue;
				}
					
				int iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				if(iSpecMode == 4 || iSpecMode == 5)
				{
					int iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
					if(client == iTarget)
					{
						if(CheckCommandAccess(iTarget, "speclist_admin_flag", ADMFLAG_KICK))
						{
							Format(szText, sizeof(szText), "%s<font color='#21618C'>%N.</font> ", szText, i)
						}
						else if(CheckCommandAccess(iTarget, "speclist_vip_flag", ADMFLAG_KICK))
						{
							Format(szText, sizeof(szText), "%s<font color='#D4AC0D'>%N.</font> ", szText, i);
						}
						else
						{
							Format(szText, sizeof(szText), "%s%N. ", szText, i);
						}
							
						bDisplayHint = true;
					}
				}
			}
			
			if(bDisplayHint)
			{
				if(g_bSpecListEnabled[client])
				{
					PrintHintText(client, "<font size='12'><u>Spectators:\n</u></font><font size='15'>%s</font>", szText);
				}
				
				// second loop, to print string to all spectators with speclist enabled
				// instead of relooping through all players for all spectators as well and remaking hud
				for(int i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i) || !IsClientObserver(i) || g_bSpecListEnabled[i])
					{
						continue;
					}
					
					int iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
					if(iSpecMode == 4 || iSpecMode == 5)
					{
						int iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
						if(client == iTarget)
						{
							PrintHintText(iTarget, "<font size='12'><u>Spectators:\n</u></font><font size='15'>%s</font>", szText);
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}