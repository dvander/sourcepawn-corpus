#define PLUGIN_VERSION		"0.1"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "4d_thebestthing",
    author = "Finishlast",
    description = "Download and play one custom soundfile",
    version = PLUGIN_VERSION,
    url = ""
}


EngineVersion g_Engine;

public void OnPluginStart()
{
	g_Engine = GetEngineVersion();
	RegAdminCmd("sm_thebestthing", Cmd_thebestthing, ADMFLAG_VOTE, "thebestthing" );
	if(g_Engine == Engine_Left4Dead)
		OnMapStart();
}


public void OnMapStart()
{
	char sSoundPath[PLATFORM_MAX_PATH];
	char sDLPath[PLATFORM_MAX_PATH];
	sSoundPath="random/thebestthing.mp3";
	Format(sDLPath, sizeof(sDLPath), "sound/%s", sSoundPath);
	AddFileToDownloadsTable(sDLPath);
	PrecacheSound(sSoundPath);	
}


public Action Cmd_thebestthing(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("[SM] THE BEST THING!");
	PrintToChatAll("******************************************************");
	Command_Play("random\\thebestthing.mp3");
	return Plugin_Handled;
}

public Action Command_Play(const char[] arguments)
{

	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);
	}  
}
