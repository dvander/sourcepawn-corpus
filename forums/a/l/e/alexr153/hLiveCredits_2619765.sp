#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.0.1"
#define CHAT_TAGS "[\x04hLiveCredits\x01]"

#define SPECMODE_NONE            0 
#define SPECMODE_FIRSTPERSON    4 
#define SPECMODE_3RDPERSON        5 
#define SPECMODE_FREELOOK        6 

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <store>

ConVar sm_hud_x;
ConVar sm_hud_y;
ConVar sm_hud_holdTime;
ConVar sm_hud_r;
ConVar sm_hud_g;
ConVar sm_hud_b;
ConVar sm_hud_alpha;
ConVar sm_hud_effect;
ConVar sm_hud_fxTime;
ConVar sm_hud_fadein;
ConVar sm_hud_fadeOut;
ConVar sm_hud_VIPFlag;


Handle g_hClientCookie;
Handle g_hTimer[MAXPLAYERS + 1];

int g_iClientCredits[MAXPLAYERS + 1];
bool g_bHud[MAXPLAYERS + 1];

#pragma newdecls required

public Plugin myinfo = 
{
	name = "hLiveCredits", 
	author = PLUGIN_AUTHOR, 
	description = "Shows credits updating in live time zephrus store", 
	version = PLUGIN_VERSION, 
	url = "NUN"
};

public void OnPluginStart()
{
	g_hClientCookie = RegClientCookie("CHud", "Saves the value for enabling or disabling the hud", CookieAccess_Private);
	
	sm_hud_x = CreateConVar("sm_hud_x", "0.45", "The value of the text in x cordinate plaine", _, true, 0.0, true, 1.0);
	sm_hud_y = CreateConVar("sm_hud_y", "1.0", "The value of the text in y cordinate plaine", _, true, 0.0, true, 1.0);
	sm_hud_holdTime = CreateConVar("sm_hud_holdTime", "1.0", "The amount of time the text should be there");
	sm_hud_r = CreateConVar("sm_hud_r", "255", "The value for color in RGB format. This ConVar sets the R value", _, true, 0.0, true, 255.0);
	sm_hud_g = CreateConVar("sm_hud_g", "255", "The value for color in RGB format. This ConVar sets the G value", _, true, 0.0, true, 255.0);
	sm_hud_b = CreateConVar("sm_hud_b", "255", "The value for color in RGB format. This ConVar sets the B value", _, true, 0.0, true, 255.0);
	sm_hud_alpha = CreateConVar("sm_hud_alpha", "1.0", "The value to set alpha", _, true, 0.0, true, 1.0);
	sm_hud_effect = CreateConVar("sm_hud_effect", "0", "The effect to use for the text. (0 and 1 fade in and out. 2 Flicker the text)", _, true, 0.0, true, 2.0);
	sm_hud_fxTime = CreateConVar("sm_hud_fxTime", "0", "The amount of time the FX should display", _, true, 0.0, true, 60.0);
	sm_hud_fadein = CreateConVar("sm_hud_fadein", "0.0", "The amount of time the text should fade in", _, true, 0.0, true, 60.0);
	sm_hud_fadeOut = CreateConVar("sm_hud_fadeOut", "0.0", "The amound of time the text should fade out", _, true, 0.0, true, 60.0);
	sm_hud_VIPFlag = CreateConVar("sm_hud_VIPFlag", "t", "The flag you have for VIP");
	
	RegConsoleCmd("sm_chud", CMD_CHud, "Enables or disables the hud text");
	
	AutoExecConfig(true, "plugin.hLiveCredits");
	
	SetHudTextParams(sm_hud_x.FloatValue, sm_hud_y.FloatValue, sm_hud_holdTime.FloatValue, sm_hud_r.IntValue, sm_hud_g.IntValue, sm_hud_b.IntValue, sm_hud_alpha.IntValue, sm_hud_effect.IntValue, sm_hud_fxTime.FloatValue, sm_hud_fadein.FloatValue, sm_hud_fadeOut.FloatValue);
}

public void OnClientCookiesCached(int client)
{
	char cookieValue[32];
	GetClientCookie(client, g_hClientCookie, cookieValue, 32);
	int value = StringToInt(cookieValue);
	
	if (value == 1)g_bHud[client] = true;
	else g_bHud[client] = false;
}

public Action CMD_CHud(int client, int args)
{
	char enabled[32];
	
	g_bHud[client] = !g_bHud[client];
	PrintToChat(client, CHAT_TAGS..." You have %s credits on the hud", (g_bHud[client]) ? "\x02disabled\x01":"\x04enabled\x01");
	
	if (g_bHud[client])
		Format(enabled, 32, "1");
	else
		Format(enabled, 32, "0");
		
	SetClientCookie(client, g_hClientCookie, enabled);
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	g_hTimer[client] = CreateTimer(1.0, ShowLiveCredits, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action ShowLiveCredits(Handle timer, int client)
{
	if (g_bHud[client])
		return Plugin_Handled;
	
	g_iClientCredits[client] = Store_GetClientCredits(client);
	char flagString[32];
	GetConVarString(sm_hud_VIPFlag, flagString, 32);
	int flag = ReadFlagString(flagString);
	
	int SpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if (SpecMode == SPECMODE_FIRSTPERSON || SpecMode == SPECMODE_3RDPERSON)
	{
		int Target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (IsValidClient(Target))
		{
			if (GetUserFlagBits(Target) & flag) ShowHudText(client, 5, "Credits: [%i] - VIP", g_iClientCredits[Target]);
			else ShowHudText(client, 5, "Credits: [%i]", g_iClientCredits[Target]);
			return Plugin_Handled;
		}
	}
	
	if (GetUserFlagBits(client) & flag) ShowHudText(client, 5, "Credits: [%i] - VIP", g_iClientCredits[client]);
	else ShowHudText(client, 5, "Credits: [%i]", g_iClientCredits[client]);
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (IsFakeClient(client))
		return false;
	
	return true;
}
