#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.2"

new bool:g_Flashed[MAXPLAYERS+1]={false,...};
new Handle:g_cDur=INVALID_HANDLE;
new Handle:g_cEnabled=INVALID_HANDLE;
new Handle:g_cPrintToAdmins=INVALID_HANDLE;
new Float:g_Dur;
new bool:g_Enabled;
new bool:g_PrintToAdmins;
public Plugin:myinfo =
{
 name = "TeamFlash Announce",
 author = "Snach`", 
 description = "TeamFlash Announce",
 version = PLUGIN_VERSION,
 url = "https://forums.alliedmods.net/member.php?u=187211"
}

public OnPluginStart()
{
	HookEvent("player_blind", Event_PlayerBlind);
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	CreateConVar("sm_tfannounce_version", PLUGIN_VERSION, "tfannounce version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cDur=CreateConVar("sm_tfannounce_mintime","1.5","Minimum flash duration for announcements",0,true,0.0);
	g_cEnabled=CreateConVar("sm_tfannounce_enabled","1","1 To enable TeamFlash announcements, 0 to disabled them",0,true,0.0,true,1.0);
	g_cPrintToAdmins=CreateConVar("sm_tfannounce_print_to_admins","1","1 To enable TeamFlash announcements in console for admins, 0 to disabled them",0,true,0.0,true,1.0);
	g_Dur=GetConVarFloat(g_cDur);
	g_Enabled=GetConVarBool(g_cEnabled);
	HookConVarChange(g_cDur,DurationChange);
	HookConVarChange(g_cEnabled,StatusChange);
	HookConVarChange(g_cPrintToAdmins,PrintToAdminsChange);
	AutoExecConfig();
	PrintToChatAll("\x04[Snach's] \x03TeamFlash Announce has been \x04Loaded.");
}

public OnPluginEnd()
{
	PrintToChatAll("\x04[Snach's] \x03TeamFlash Announce has been \x04Unloaded.");
}

public DurationChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_Dur=StringToFloat(newValue);
}

public StatusChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_Enabled=(StringToInt(newValue)==1);
}

public PrintToAdminsChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_PrintToAdmins=(StringToInt(newValue)==1);
}

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_Enabled)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetEntPropFloat(client, Prop_Send, "m_flFlashDuration")>=g_Dur)
		g_Flashed[client]=true;
}

public Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_Enabled)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:time;
	new bool:first=true;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_Flashed[i])
		{
			time = GetEntPropFloat(i, Prop_Send, "m_flFlashDuration");
			if (i == client)
			{
				g_Flashed[i] = false;
				continue;
			}
			else if (GetClientTeam(i) == GetClientTeam(client) && IsPlayerAlive(i))
			{
				PrintToChat(i,"\x03[TeamFlash] \x04You were TeamFlashed by: \x03%N \x04for \x03%.2f \x04Seconds",client,time);
				if(first)
				{
					first=false;
					PrintToAdminsConsole("---------------------------------------------------");
				}
				if(g_PrintToAdmins)
					PrintToAdminsConsole("[TeamFlash] %N was TeamFlashed by: %N for %.2f Seconds",i,client,time);
			}
			
			g_Flashed[i] = false;
		}
	}
	if(!first)
		PrintToAdminsConsole("---------------------------------------------------");
}

public PrintToAdminsConsole(String:format[], any:...)
{
	decl String:message[256];
	VFormat(message,sizeof(message),format,2);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientConnected(i)&&GetUserAdmin(i)!=INVALID_ADMIN_ID)
		{
			PrintToConsole(i,"%s",message);
		}
	}
}