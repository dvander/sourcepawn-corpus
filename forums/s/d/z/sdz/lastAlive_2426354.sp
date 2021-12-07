#include <sourcemod>
#include <cstrike>

bool g_HUD[MAXPLAYERS + 1] = true;

public Plugin myinfo =
{
    name = "Show last alive on HUD",
    author = "Sidezz",
    description = "",
    version = "1.0",
    url = "http://www.coldcommunity.com"
}

public void OnClientPostAdminCheck(int client)
{
    CreateTimer(1.0, hudTick, client, TIMER_REPEAT);
    g_HUD[client] = true;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_alive", Command_lastAliveToggle, "Toggle display of the last alive HUD");
}

public Action Command_lastAliveToggle(int client, int args)
{
	if(g_HUD[client])
	{
		g_HUD[client] = false;
		ReplyToCommand(client, "[SM] Last Alive HUD has been disabled");
	}
	else 
	{
		g_HUD[client] = true;
		ReplyToCommand(client, "[SM] Last Alive HUD has been enabled");
	}
	return Plugin_Handled;
}

public Action hudTick(Handle timer, any client)
{
    if(!IsClientInGame(client))
    {
        KillTimer(timer);
        return Plugin_Handled;
    }

    char text[512], tAlive, ctAlive;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i))
        {
            switch(GetClientTeam(i))
            {
                case CS_TEAM_CT: ctAlive++;
                case CS_TEAM_T: tAlive++;
            }
        }
    }

    if(tAlive > 1)
    {
        Format(text, sizeof(text), "Terrorists Alive: %i", tAlive);
    }
    else if(tAlive == 1)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
            {
                Format(text, sizeof(text), "Last Terrorist: %N", i);
            }
        }
    }

    if(ctAlive > 1)
    {
        Format(text, sizeof(text), "%s\nCounter-Terrorists Alive: %i", text, ctAlive);
    }
    else if(ctAlive == 1)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
            {
                Format(text, sizeof(text), "%s\nLast Counter-Terrorist: %N", text, i);
            }
        }
    }

    if(g_HUD[client])
    {
    	SetHudTextParams(-1.0, 0.865, 1.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
    	ShowHudText(client, -1, text);
    }
    return Plugin_Handled;
}  