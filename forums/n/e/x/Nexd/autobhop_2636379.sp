#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <clientprefs>

Handle gh_AutoBhop = INVALID_HANDLE;
Handle g_hClientBhopCookie = INVALID_HANDLE;

bool g_bToggle[MAXPLAYERS+1] = false, g_bAutoBhop[MAXPLAYERS+1];


public Plugin myinfo =
{
	name = "[CSGO] Per Player Bhop Toggle",
	author = "Cruze, edited by Nexd",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_bhop", CMD_Bhop, "Toggle Bhop.");
	gh_AutoBhop = FindConVar("sv_autobunnyhopping");
	SetConVarBool(gh_AutoBhop, false);
	g_hClientBhopCookie = RegClientCookie("Autobhop", "Client Sided Autobhop", CookieAccess_Private);
	for (int i = MaxClients; i > 0; --i)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        
        OnClientCookiesCached(i);
    }
	if(GetEngineVersion() != Engine_CSGO) 
		SetFailState("[AUTOBHOP] This plugin supports CSGO game only.");
}

public void OnClientCookiesCached(int client) 
{
	char sValue[8];
	GetClientCookie(client, g_hClientBhopCookie, sValue, sizeof(sValue));
	
	g_bToggle[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public void OnClientPostAdminCheck(int client)
{
	if(g_bToggle[client] && IsClientValid(client) && !IsFakeClient(client))
		SendConVarValue(client, gh_AutoBhop, "0");
}

public Action CMD_Bhop(int client, int args)
{
	if(!IsClientValid(client) || !IsClientInGame(client) || !g_bAutoBhop)
	{
		return Plugin_Handled;
	}
	if(!g_bToggle[client] && CheckCommandAccess(client, "sm_auto_bhop", ADMFLAG_CUSTOM5))
	{
		SendConVarValue(client, gh_AutoBhop, "1");
		SetClientCookie(client, g_hClientBhopCookie, "1");
		PrintToChat(client, " \x04[\x06VIP\x04] \x01You have enabled the auto-bhop");
		g_bToggle[client] = true;
	}
	else if(CheckCommandAccess(client, "sm_auto_bhop", ADMFLAG_CUSTOM5))
	{
		SendConVarValue(client, gh_AutoBhop, "0");
		SetClientCookie(client, g_hClientBhopCookie, "0");
		PrintToChat(client, " \x04[\x06VIP\x04] \x01You have disabled the auto-bhop");
		g_bToggle[client] = false;
	}
	else
	{
		PrintToChat(client, "\x04[\x06VIP\x04] \x01You need to be VIP!");
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (g_bToggle[client] && IsPlayerAlive(client))
    {
        if (buttons & IN_JUMP)
        {
            if (!(GetEntityFlags(client) & FL_ONGROUND))
            {
                if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
                {
                    if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
                    {
                        buttons &= ~IN_JUMP;
                    }
                }
            }
        }
    }
}

bool IsClientValid(int client)
{
	return ((client > 0) && (client <= MaxClients));
}