#include <sourcemod>
#include <clientprefs>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.0"

bool g_bReceivedHit[MAXPLAYERS + 1];
bool g_bHit[MAXPLAYERS + 1];

bool g_bEnabled_ReceivedHit;
bool g_bEnabled_Hit;

Handle g_hReceivedHitCookie = INVALID_HANDLE;
Handle g_hHitCookie = INVALID_HANDLE;

Handle g_hEnabled_ReceivedHit;
Handle g_hEnabled_Hit;

char aFlag[AdminFlags_TOTAL];
ConVar g_cvVipFlag;

public Plugin myinfo = 
{
	name = "Advanced Bullet Damage", 
	author = "Nocky", 
	description = "", 
	version = VERSION, 
	url = "wasd.cz"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_receivedhit", recievedhit_cmd);
	RegConsoleCmd("sm_hit", hit_cmd);
	
	g_hReceivedHitCookie = RegClientCookie("abd_receivedhit", "Shows received damage hit", CookieAccess_Private);
	g_hHitCookie = RegClientCookie("abd_hit", "Shows damage hit", CookieAccess_Private);
	
	g_hEnabled_ReceivedHit = CreateConVar("sm_abd_receivedhit", "1", "1 = Enabled / 0 = Disabled - (Showing received damage hit)", 0, true, 0.0, true, 1.0);
	g_hEnabled_Hit = CreateConVar("sm_abd_hit", "1", "1 = Enabled / 0 = Disabled - (Showing damage hit)", 0, true, 0.0, true, 1.0);
	
	g_cvVipFlag = CreateConVar("sm_abd_flag", "", "Necessary flag for VIP , blank = for all");
	
	HookEvent("player_hurt", Event_PlayerHurt);
	
	HookConVarChange(g_hEnabled_ReceivedHit, OnCvarChanged);
	HookConVarChange(g_hEnabled_Hit, OnCvarChanged);
	HookConVarChange(g_cvVipFlag, OnCvarChanged);
	
	
	
	g_bEnabled_ReceivedHit = GetConVarBool(g_hEnabled_ReceivedHit);
	g_bEnabled_Hit = GetConVarBool(g_hEnabled_Hit);
	
	AutoExecConfig(true, "AdvancedBulletDamage");
	
	for (int i = MaxClients; i > 0; --i)
	{
		if (!AreClientCookiesCached(i))
		{
			g_bReceivedHit[i] = true;
			g_bHit[i] = true;
			continue;
		}
		
		OnClientCookiesCached(i);
	}
}

public void OnCvarChanged(Handle convar, const char[] oldVal, const char[] newVal)
{
	if (convar == g_cvVipFlag)
	{
		g_cvVipFlag.GetString(aFlag, sizeof(aFlag));
	}
	if (convar == g_hEnabled_ReceivedHit)
	{
		g_bEnabled_ReceivedHit = GetConVarBool(g_hEnabled_ReceivedHit);
	}
	if (convar == g_hEnabled_Hit)
	{
		g_bEnabled_Hit = GetConVarBool(g_hEnabled_Hit);
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sValue[8];
	GetClientCookie(iClient, g_hReceivedHitCookie, sValue, sizeof(sValue));
	GetClientCookie(iClient, g_hHitCookie, sValue, sizeof(sValue));
	
	g_bReceivedHit[iClient] = view_as<bool>(StringToInt(sValue));
	g_bHit[iClient] = view_as<bool>(StringToInt(sValue));
}

public Action recievedhit_cmd(int iClient, int iArgs)
{
	int valueint;
	if (IsPlayerVIP(iClient))
	{
		if (g_bReceivedHit[iClient])
		{
			g_bReceivedHit[iClient] = false;
			CPrintToChat(iClient, " \x02[!]{default} Showing received damage has been {green}enabled{default}!");
			valueint = 0;
		}
		else
		{
			g_bReceivedHit[iClient] = true;
			CPrintToChat(iClient, " \x02[!]{default} Showing received damage has been {green}disabled{default}!");
			valueint = 1;
		}
		
		char value[512];
		Format(value, sizeof(value), "%i", valueint);
		SetClientCookie(iClient, g_hReceivedHitCookie, value);
	}
	else
	{
		CPrintToChat(iClient, " \x02[!]{default} You must be a {yellow}VIP{default}!");
	}
}

public Action hit_cmd(int iClient, int args)
{
	int valueint;
	if (IsPlayerVIP(iClient))
	{
		if (g_bHit[iClient])
		{
			g_bHit[iClient] = false;
			CPrintToChat(iClient, " \x02[!]{default} Showing hit damage has been {green}enabled{default}!");
			valueint = 0;
		}
		else
		{
			g_bHit[iClient] = true;
			CPrintToChat(iClient, " \x02[!]{default} Showing hit damage has been {green}disabled{default}!");
			valueint = 1;
		}
		
		char value[512];
		Format(value, sizeof(value), "%i", valueint);
		SetClientCookie(iClient, g_hHitCookie, value);
	}
	else
	{
		CPrintToChat(iClient, " \x02[!]{default} You must be a {yellow}VIP{default}!");
	}
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (iAttacker < 1 || iAttacker > MaxClients || !IsClientInGame(iAttacker) || IsFakeClient(iAttacker))
		return;
	
	int iDamage = GetEventInt(event, "dmg_health");
	int iHitgroup = GetEventInt(event, "hitgroup");
	
	if (g_bEnabled_Hit)
	{
		if (!g_bHit[iAttacker])
		{
			if (IsPlayerVIP(iAttacker))
			{
				if (iHitgroup == 1)
				{
					SetHudTextParams(-1.0, 0.45, 1.0, 255, 235, 20, 200, 1);
				}
				else
				{
					SetHudTextParams(-1.0, 0.45, 1.0, 0, 153, 255, 200, 1);
				}
				ShowHudText(iAttacker, 1, "%i", iDamage);
				
			}
		}
	}
	
	if (g_bEnabled_ReceivedHit)
	{
		if (!g_bReceivedHit[iClient])
		{
			if (IsPlayerVIP(iClient))
			{
				SetHudTextParams(-1.0, -0.45, 1.0, 255, 0, 0, 200, 1);
				ShowHudText(iClient, 2, "%i", iDamage);
			}
		}
	}
}

stock bool IsPlayerVIP(int iClient)
{
	g_cvVipFlag.GetString(aFlag, sizeof(aFlag));
	
	if (StrEqual(aFlag, "") || StrEqual(aFlag, " "))
	{
		return true;
	}
	else
	{
		if (CheckCommandAccess(iClient, "abd_vip_flag", ReadFlagString(aFlag), true))
		{
			return true;
		}
		else
		{
			return false;
		}
	}
} 