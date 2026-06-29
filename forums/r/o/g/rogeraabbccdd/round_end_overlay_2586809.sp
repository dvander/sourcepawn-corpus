#include <sourcemod> 
#include <sdktools> 

#pragma newdecls required 

ConVar Cvar_Overlay, Cvar_Time;

char overlay_path[PLATFORM_MAX_PATH];
float overlay_time;

public Plugin myinfo =   
{ 
	name = "[CS:GO] Round Draw Overlay",  
	author = "Kento",  
	description = "Display overlay when round draw.",  
	version = "1.0",  
	url = "http://steamcommunity.com/id/kentomatoryoshika/" 
}; 

public void OnPluginStart() 
{ 
	HookEvent("round_end", Event_RoundEnd); 
	
	Cvar_Overlay = CreateConVar("sm_overlay", "", "Overlay to display, no need to add materials folder and vmt, vtf here."); 
	Cvar_Time = CreateConVar("sm_overlay_time", "5.0", "How long should overlay display?"); 
	
	AutoExecConfig();
} 

public void OnConfigsExecuted()
{
	Cvar_Overlay.GetString(overlay_path, sizeof(overlay_path));
	overlay_time = Cvar_Time.FloatValue;
}

public void OnMapStart() 
{ 
	if(!StrEqual(overlay_path, ""))
	{
		char dlpath1[1024], dlpath2[1024];
		Format(dlpath1, sizeof(dlpath1), "materials/%s.vtf", overlay_path);
		Format(dlpath2, sizeof(dlpath2), "materials/%s.vmt", overlay_path);
		AddFileToDownloadsTable(dlpath1);
		AddFileToDownloadsTable(dlpath2);
		PrecacheDecal(dlpath1, true); 
		PrecacheDecal(dlpath2, true); 
	}
} 

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) 
{ 
	char message[256]; 
	GetEventString(event, "message", message, sizeof(message));
	if(StrEqual(message, "#SFUI_Notice_Round_Draw", false))
	{
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (IsValidClient(i) && !IsFakeClient(i)) 
			{
				SetClientOverlay(i, overlay_path);
				CreateTimer(overlay_time, DeleteOverlay, i);
			}
		}
	}
} 

stock bool IsValidClient(int client) 
{ 
	if (client <= 0) return false; 
	if (client > MaxClients) return false; 
	if (!IsClientConnected(client)) return false; 
	return IsClientInGame(client); 
} 

// Code taken from csgoware  
// https://forums.alliedmods.net/showthread.php?p=2500764 
bool SetClientOverlay(int client, char[] strOverlay) 
{ 
	if (IsValidClient(client) && !IsFakeClient(client)) 
	{ 
		//int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT); 
		//SetCommandFlags("r_screenoverlay", iFlags);  
		ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay); 
		return true; 
	} 
	return false; 
} 

public Action DeleteOverlay(Handle tmr, any client) 
{ 
	if (IsValidClient(client) && !IsFakeClient(client)) 
	{ 
		SetClientOverlay(client, ""); 
	} 
	return Plugin_Handled; 
}  