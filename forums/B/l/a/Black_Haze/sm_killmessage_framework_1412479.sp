#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new Handle:_atCleanTimer[MAXPLAYERS+1] = INVALID_HANDLE
new Handle:_hTimerLength;
new Float:_dTimerLength;

public Plugin:myinfo = 
{
	name = "Kill Message Overlays Framework",
	author = "Siang Chun & Black Haze",
	description = "Framework for Kill Message Overlays",
	version = PLUGIN_VERSION,
	url = "bslw.co.uk & beernweed.com"
}

public OnPluginStart()
{	
	_hTimerLength = CreateConVar("sm_killmessage_overlays_length", "3.0", "Length of time an overlay is showed", FCVAR_PLUGIN|FCVAR_REPLICATED, true, 1.0);
	_dTimerLength = GetConVarFloat(_hTimerLength);
	
	RegServerCmd("sm_killmessage_show", ShowKillMessage);
	RegServerCmd("sm_killmessage_prepare", PrepareOverlay);
}

public Action:ShowKillMessage(args)
{
	if (args < 2)
	{
		return Plugin_Handled;
	}
	
	decl String: client_id[192];
	GetCmdArg(1, client_id, sizeof(client_id));
	new client = GetClientOfUserId(StringToInt(client_id));
	
	if(client>0)
	{
		decl String: sOverLay[192];
		GetCmdArg(2, sOverLay, sizeof(sOverLay));
		
		if(_atCleanTimer[client] !=INVALID_HANDLE)
		{
			KillTimer(_atCleanTimer[client]);
			_atCleanTimer[client] =INVALID_HANDLE;
		}
		
		_atCleanTimer[client] = CreateTimer(_dTimerLength,CleanTimer,client);
		
		ClearScreen(client);
		ClientCommand(client, "r_screenoverlay \"killmessages/%s.vtf\"",sOverLay);
	}
	return Plugin_Handled;
}

public ClearScreen(client)
{
	if(client>0)
	{
		ClientCommand(client, "r_screenoverlay \"\"");
	}
}

public Action:CleanTimer(Handle:Timer, any:client)
{
	_atCleanTimer[client] = INVALID_HANDLE;
	ClearScreen(client);
}

public Action:PrepareOverlay(args)
{
	if (args < 1)
	{
		return Plugin_Handled;
	}
	
	decl String: sOverLay[192];
	GetCmdArg(1, sOverLay, sizeof(sOverLay));
	
	new String:overlays_file[64];
	new String:overlays_dltable[64];
	
	Format(overlays_file,sizeof(overlays_file),"killmessages/%s.vtf",sOverLay);
	PrecacheDecal(overlays_file,true);
	Format(overlays_dltable,sizeof(overlays_dltable),"materials/killmessages/%s.vtf",sOverLay);
	AddFileToDownloadsTable(overlays_dltable);
	Format(overlays_file,sizeof(overlays_file),"killmessages/%s.vmt",sOverLay);
	PrecacheDecal(overlays_file,true);
	Format(overlays_dltable,sizeof(overlays_dltable),"materials/killmessages/%s.vmt",sOverLay);
	AddFileToDownloadsTable(overlays_dltable);
	
	return Plugin_Handled;
}