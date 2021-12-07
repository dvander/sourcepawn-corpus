
/* AutoGungame created by BDeep. This plugin is designed to automate the transition between reular CSS and Gungame.
*  Usage: This will exec a config file based on the map prefixes. If a map begins with de_ or cs_ it will exec one 
* config and any other prefix it will exec the other config. I use one master server.cfg with rcon, bot info and Fast DL Server info.
* Two other cfgs for the CSS and GG cvarsj*/

#include <sourcemod>
#include <sdktools>



new Handle:cvar_csMapPrefix = INVALID_HANDLE;
new Handle:cvar_deMapPrefix = INVALID_HANDLE;
new Handle:cvar_csscfg = INVALID_HANDLE;
new Handle:cvar_ggcfg = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "AutoGunGame",
	author = "BDeep",
	description = "Automatcally turn on/off SM_Gungame based on current map prefix. If map does not begin with de_ or cs_ then gungame is assumed",
	version = "1.4",
	url = "http://seriousgroup.net"
}

public OnPluginStart()
{
	CreateConVar("sm_auto_gungame_version", "1.4", "sm_auto_gungame_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	cvar_csMapPrefix = CreateConVar("sm_autogungame_csMapPrefix", "cs_", "The prefix of a hostage map.", FCVAR_PLUGIN);
	cvar_deMapPrefix = CreateConVar("sm_autogungame_deMapPrefix", "de_", "The prefix of a defuse map.", FCVAR_PLUGIN);
	cvar_csscfg = CreateConVar("sm_autogungame_csscfg", "", "A CFG File to run for NON Gungame Maps. Example EXEC CSS.CFG", FCVAR_PLUGIN);
	cvar_ggcfg = CreateConVar("sm_autogungame_ggcfg", "", "A CFG File to run for Gungame Maps. Example EXEC GG.CFG", FCVAR_PLUGIN);
	AutoExecConfig(true, "autogungame");
}

public OnMapStart() 
{
	new String:csMapPrefix[5];
	new String:deMapPrefix[5];		
	new String:CurrentMapName[50];	
	new String:GGCFG[50];		
	new String:CSSCFG[50];
	GetConVarString(cvar_csMapPrefix, csMapPrefix,5);
	GetConVarString(cvar_deMapPrefix, deMapPrefix,5);
	GetConVarString(cvar_csscfg, CSSCFG,50);
	GetConVarString(cvar_ggcfg, GGCFG,50);

	GetCurrentMap(CurrentMapName,50);
	if (strncmp(CurrentMapName, csMapPrefix, 3,false) == 0)
	{
		ServerCommand(CSSCFG);
	}
	else if (strncmp(CurrentMapName,deMapPrefix,3,false) == 0)
	{
		ServerCommand(CSSCFG);
	}
	else if (StrContains(CurrentMapName, "gg_", false) == 0) 
	{
		if ((StrContains(CurrentMapName,deMapPrefix,false)) == 3 || (StrContains(CurrentMapName,csMapPrefix,false)) == 3)
		{
			ServerCommand(GGCFG);
		}
	}	
	return Plugin_Handled;
}
