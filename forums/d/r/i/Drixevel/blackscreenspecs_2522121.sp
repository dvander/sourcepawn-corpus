//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
//#include <sourcemod-misc>

#define HIDE_RADAR_CSGO 1<<12

//ConVars
ConVar convar_Status;
ConVar convar_Admin;

//Globals
bool g_bLate;

public Plugin myinfo = 
{
	name = "Black Screen Spectators", 
	author = "Keith Warren (Drixevel)", 
	description = "Blacks out screens for players based on their team.", 
	version = "1.0.0", 
	url = "http://www.drixevel.com/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	convar_Status = CreateConVar("sm_blackscreenspectators_status", "1", "Status of the plugin.\n1 = on, 0 = off", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Admin = CreateConVar("sm_blackscreenspectators_admin", "1", "Status for the admin flag checks.\n1 = on, 0 = off", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig();
	
	HookEvent("player_team", Event_OnPlayerTeam);
	
	RegAdminCmd("sm_blindspec", Command_BlindSpec, ADMFLAG_SLAY, "Blind players in spectator.");
}

public void OnConfigsExecuted()
{
	if (GetConVarBool(convar_Status) && g_bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SetClientFade(i, GetClientTeam(i))
			}
		}
		
		g_bLate = false;
	}
}

public void Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	if (!GetConVarBool(convar_Status) || client == 0 || client > MaxClients || (GetConVarBool(convar_Admin) && CheckCommandAccess(client, "blackscreen_spec", ADMFLAG_SLAY)))
	{
		return;
	}
	
	SetClientFade(client, GetEventInt(event, "team"));
}

void SetClientFade(int client, int team)
{
	if (!GetConVarBool(convar_Status) || client == 0 || client > MaxClients || (GetConVarBool(convar_Admin) && CheckCommandAccess(client, "blackscreen_spec", ADMFLAG_SLAY)))
	{
		return;
	}
	
	switch (team)
	{
		case 1:
		{
			ScreenEffect(client, 99999, 99999, 100, 0, 0, 0, 255);
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
		}
		case 2, 3:
		{
			ScreenEffect(client, 10, 100, 100, 255, 255, 255, 255);
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
		}
	}
}

public Action Command_BlindSpec(int client, int args)
{
	if (!GetConVarBool(convar_Status))
	{
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetConVarBool(convar_Admin) && !CheckCommandAccess(i, "blackscreen_spec", ADMFLAG_SLAY) && GetClientTeam(i) == 1))
		{
			ScreenEffect(i, 99999, 99999, 100, 0, 0, 0, 255);
			SetEntProp(i, Prop_Send, "m_iHideHUD", GetEntProp(i, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
		}
	}
	
	PrintToChat(client, "All spectators have been blinded.");
	return Plugin_Handled;
}

void ScreenEffect(int client, int duration, int hold_time, int flag, int red, int green, int blue, int alpha)
{
	Handle hFade;
	
	if (client)
	{
	   hFade = StartMessageOne("Fade", client);
	}
	else
	{
	   hFade = StartMessageAll("Fade");
	}
	
	if (hFade != null)
	{
		if (GetUserMessageType() == UM_Protobuf)
		{
			int clr[4]; clr[0]=red; clr[1]=green; clr[2]=blue; clr[3]=alpha;
			
			PbSetInt(hFade, "duration", duration);
			PbSetInt(hFade, "hold_time", hold_time);
			PbSetInt(hFade, "flags", flag);
			PbSetColor(hFade, "clr", clr);
		}
		else
		{
			BfWriteShort(hFade, duration);
			BfWriteShort(hFade, hold_time);
			BfWriteShort(hFade, flag);
			BfWriteByte(hFade, red);
			BfWriteByte(hFade, green);
			BfWriteByte(hFade, blue);	
			BfWriteByte(hFade, alpha);
		}
		
		EndMessage();
	}
}