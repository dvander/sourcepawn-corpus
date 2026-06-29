#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <clientprefs>

Handle gh_AutoBhop = INVALID_HANDLE;
Handle g_hClientBhopCookie = INVALID_HANDLE;

bool g_bToggle[MAXPLAYERS+1] = false;


public Plugin myinfo =
{
	name = "[CSGO] Per Player Bhop Toggle",
	author = "Cruze",
	description = "",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_bhop", CMD_Bhop, "Toggle Bhop.");
	RegConsoleCmd("sm_on", CMD_On, "Toggle Bhop On.");
	RegConsoleCmd("sm_off", CMD_Off, "Toggle Bhop Off.");
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
		SendConVarValue(client, gh_AutoBhop, "1");
}

public Action CMD_Bhop(int client, int args)
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if(!CheckCommandAccess(client, "", ADMFLAG_CUSTOM5))
	{
		PrintToChat(client, " \x04[\x06AB\x04] \x01You need to be VIP to use this command.");
		return Plugin_Handled;
	}
	if(!g_bToggle[client])
	{
		SendConVarValue(client, gh_AutoBhop, "1");
		SetClientCookie(client, g_hClientBhopCookie, "1");
		PrintToChat(client, " \x04[\x06AB\x04] \x01Enabled Autobhop for you");
		g_bToggle[client] = true;
	}
	else
	{
		SendConVarValue(client, gh_AutoBhop, "0");
		SetClientCookie(client, g_hClientBhopCookie, "0");
		PrintToChat(client, " \x04[\x06AB\x04] \x01Disabled Autobhop for you");
		g_bToggle[client] = false;
	}
	return Plugin_Handled;
}

public Action CMD_On(int client, int args)
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if(!CheckCommandAccess(client, "", ADMFLAG_CUSTOM5))
	{
		PrintToChat(client, " \x04[\x06AB\x04] \x01You need to be VIP to use this command.");
		return Plugin_Handled;
	}
	if(!g_bToggle[client])
	{
		SendConVarValue(client, gh_AutoBhop, "1");
		SetClientCookie(client, g_hClientBhopCookie, "1");
		PrintToChat(client, " \x04[\x06AB\x04] \x01Enabled Autobhop for you");
		g_bToggle[client] = true;
	}
	else
	{
		PrintToChat(client, " \x04[\x06AB\x04] \x01Autobhop is already enabled for you");
	}
	return Plugin_Handled;
}

public Action CMD_Off(int client, int args)
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if(!CheckCommandAccess(client, "", ADMFLAG_CUSTOM5))
	{
		PrintToChat(client, " \x04[\x06AB\x04] \x01You need to be VIP to use this command.");
		return Plugin_Handled;
	}
	if(g_bToggle[client])
	{
		SendConVarValue(client, gh_AutoBhop, "0");
		SetClientCookie(client, g_hClientBhopCookie, "0");
		PrintToChat(client, " \x04[\x06AB\x04] \x01Disabled Autobhop for you");
		g_bToggle[client] = false;
	}
	else
	{
		PrintToChat(client, " \x04[\x06AB\x04] \x01Autobhop is already disabled for you");
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