 //-------------
//         _   │
//     .-./*)  │
//   _/___\/   │
//     U U     │
//--------------
//│││││││││││││││││││││││││││││││││││││
//+- Discord: donjjf -+                 
//+- https://discord.gg/JMYxUw7jap -+ 
//│││││││││││││││││││││││││││││││││││││

#include <sourcemod>
#include <clientprefs>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define CS_DMG_HEADSHOT (1 << 30)

Handle g_hOnlyHS;

bool g_HasEnabledOnlyHS[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "F-OnlyHeadShotsMod", 
	author = "DON JJF", 
	description = "1337", 
	version = "0.2", 
	url = "https://discord.gg/sFrhtPXnbF"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_onlyhs", Cmm_OnlyHsMod, "Command will turn ON or OFF only hs mod.");
	RegConsoleCmd("sm_ohs", Cmm_OnlyHsMod, "Command will turn ON or OFF only hs mod.");
	RegConsoleCmd("sm_hs", Cmm_OnlyHsMod, "Command will turn ON or OFF only hs mod.");
	
	g_hOnlyHS = RegClientCookie("OnlyHS", "", CookieAccess_Private);
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public void OnClientCookiesCached(int client)
{
	char buffer[4];
	
	GetClientCookie(client, g_hOnlyHS, buffer, sizeof buffer);
	if (StrEqual(buffer, ""))
	{
		SetClientCookie(client, g_hOnlyHS, "0");
	}
	
	g_HasEnabledOnlyHS[client] = buffer[0] == '1';
}

Action Cmm_OnlyHsMod(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("%t", "Command is in-game only");
		
		return Plugin_Handled;
	}
	
	if (!g_HasEnabledOnlyHS[client])
	{
		g_HasEnabledOnlyHS[client] = true;
		PrintToChat(client, "[\x02F\x01-\x02ONLYHS\x01] Only Headshot mod \x04ON\x01!");
		
		return Plugin_Handled;
	}
	
	g_HasEnabledOnlyHS[client] = false;
	PrintToChat(client, "[\x02F\x01-\x02ONLYHS\x01] Only Headshot mod \x02OFF\x01!");
	
	return Plugin_Handled;
}

Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype & CS_DMG_HEADSHOT)
	{
		return Plugin_Continue;
	}
	
	if (g_HasEnabledOnlyHS[attacker])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	SetClientCookie(client, g_hOnlyHS, g_HasEnabledOnlyHS[client] ? "1" : "0");
}
