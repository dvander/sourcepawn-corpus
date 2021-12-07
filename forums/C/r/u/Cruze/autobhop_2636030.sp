#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <clientprefs>

Handle gh_AutoBhop = INVALID_HANDLE;
Handle g_hClientBhopCookie = INVALID_HANDLE;
ConVar g_VIPFLAG;

bool g_bToggle[MAXPLAYERS+1] = false, g_bAutoBhop[MAXPLAYERS+1];


public Plugin myinfo =
{
	name = "[CSGO] Per Player Bhop Toggle",
	author = "Cruze",
	description = "",
	version = "1.0",
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
	g_VIPFLAG = CreateConVar("sm_autobhop_flag", "a", "Flag for autobhop command.");
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
	GetFlags(client);
	if(!IsClientValid(client) || !IsClientInGame(client) || !g_bAutoBhop)
	{
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
	GetFlags(client);
	if(!IsClientValid(client) || !IsClientInGame(client) || !g_bAutoBhop)
	{
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
	GetFlags(client);
	if(!IsClientValid(client) || !IsClientInGame(client) || !g_bAutoBhop)
	{
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

public void GetFlags(int client)
{
	if (IsClientInGame(client))
	{
		char flag[8];
		int g_hFlag;
		GetConVarString(g_VIPFLAG, flag, sizeof(flag));
		if (StrEqual(flag, "a")) g_hFlag = ADMFLAG_RESERVATION;
		else if (StrEqual(flag, "b")) g_hFlag = ADMFLAG_GENERIC;
		else if (StrEqual(flag, "c")) g_hFlag = ADMFLAG_KICK;
		else if (StrEqual(flag, "d")) g_hFlag = ADMFLAG_BAN;
		else if (StrEqual(flag, "e")) g_hFlag = ADMFLAG_UNBAN;
		else if (StrEqual(flag, "f")) g_hFlag = ADMFLAG_SLAY;
		else if (StrEqual(flag, "g")) g_hFlag = ADMFLAG_CHANGEMAP;
		else if (StrEqual(flag, "h")) g_hFlag = ADMFLAG_CONVARS;
		else if (StrEqual(flag, "i")) g_hFlag = ADMFLAG_CONFIG;
		else if (StrEqual(flag, "j")) g_hFlag = ADMFLAG_CHAT;
		else if (StrEqual(flag, "k")) g_hFlag = ADMFLAG_VOTE;
		else if (StrEqual(flag, "l")) g_hFlag = ADMFLAG_PASSWORD;
		else if (StrEqual(flag, "m")) g_hFlag = ADMFLAG_RCON;
		else if (StrEqual(flag, "n")) g_hFlag = ADMFLAG_CHEATS;
		else if (StrEqual(flag, "z")) g_hFlag = ADMFLAG_ROOT;
		else if (StrEqual(flag, "o")) g_hFlag = ADMFLAG_CUSTOM1;
		else if (StrEqual(flag, "p")) g_hFlag = ADMFLAG_CUSTOM2;
		else if (StrEqual(flag, "q")) g_hFlag = ADMFLAG_CUSTOM3;
		else if (StrEqual(flag, "r")) g_hFlag = ADMFLAG_CUSTOM4;
		else if (StrEqual(flag, "s")) g_hFlag = ADMFLAG_CUSTOM5;
		else if (StrEqual(flag, "t")) g_hFlag = ADMFLAG_CUSTOM6;
		else
		{
			SetFailState("The given flag in sm_autobhop_flag is invalid");
		}
		
		int flags = GetUserFlagBits(client);		
		if (flags & g_hFlag)
		{
			g_bAutoBhop[client] = true;
		}
		else
		{
			g_bAutoBhop[client] = false;
		}
	}
}

bool IsClientValid(int client)
{
	return ((client > 0) && (client <= MaxClients));
}