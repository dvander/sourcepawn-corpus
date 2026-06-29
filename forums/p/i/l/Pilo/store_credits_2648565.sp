#define PLUGIN_NAME "Store Credits"
#define PLUGIN_LERIAS ""
#define PLUGIN_AUTHOR "Pilo"
#define PLUGIN_VERSION "1.0"
#define AUTHOR_URL "https://forums.alliedmods.net/member.php?u=290157"

Handle hTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION,
	url = AUTHOR_URL
};

#include <sourcemod>
#include <sdktools>
#include <store>

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
}

public void OnClientPostAdminCheck(int client)
{
	hTimer[client] = CreateTimer(0.1, CreditsTimer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public Action CreditsTimer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	int credits = Store_GetClientCredits(client)
	{
		if (IsValidClient(client, true))
		{
		    SetHudTextParams(0.0, 0.0, 1.0, 0, 0, 255, 255, 0, 0.0, 0.0, 0.0);
		    ShowHudText(client, 1, "You have %i credits", credits);
		}
	}
}

stock bool IsValidClient(client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}