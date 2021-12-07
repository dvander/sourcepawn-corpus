
/* AutoGungame created by BDeep. This plugin is designed to automate the transition between reular CSS and Gungame.
*  Usage: This will exec a config file based on the map prefixes. If a map begins with de_ or cs_ it will exec one 
* config and any other prefix it will exec the other config. I use one master server.cfg with rcon, bot info and Fast DL Server info.
* Two other cfgs for the CSS and GG cvarsj*/

#include <sourcemod>
#include <sdktools>



new Handle:cvar_csMapPrefix = INVALID_HANDLE;
new Handle:cvar_deMapPrefix = INVALID_HANDLE;
new Handle:cvar_asMapPrefix = INVALID_HANDLE;
new Handle:cvar_csscfg = INVALID_HANDLE;
new Handle:cvar_ggcfg = INVALID_HANDLE;
new Handle:cvar_ascfg = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "AutoGunGame",
	author = "BDeep",
	description = "Automatcally turn on/off SM_Gungame based on current map prefix. If map does not begin with de_ or cs_ then gungame is assumed",
	version = "1.0",
	url = "http://seriousgroup.net"
}

public OnPluginStart()
{
	CreateConVar("AutoGunGame Version", "1.0", "AutoGunGame Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	cvar_csMapPrefix = CreateConVar("sm_autogungame_csMapPrefix", "cs_", "The prefix of a hostage map.", FCVAR_PLUGIN);
	cvar_deMapPrefix = CreateConVar("sm_autogungame_deMapPrefix", "de_", "The prefix of a defuse map.", FCVAR_PLUGIN);
	cvar_asMapPrefix = CreateConVar("sm_autogungame_asMapPrefix", "as_", "The prefix of a VIP MOD map.", FCVAR_PLUGIN);
	cvar_csscfg = CreateConVar("sm_autogungame_csscfg", "", "A CFG File to run for NON Gungame Maps. Example EXEC CSS.CFG", FCVAR_PLUGIN);
	cvar_ggcfg = CreateConVar("sm_autogungame_ggcfg", "", "A CFG File to run for Gungame Maps. Example EXEC GG.CFG", FCVAR_PLUGIN);
	cvar_ascfg = CreateConVar("sm_autogungame_ascfg", "", "A CFG File to run for VIP Mod Maps. Example EXEC AS.CFG", FCVAR_PLUGIN);
	AutoExecConfig(true, "autogungame");
}

public OnMapStart() 
{
	new String:csMapPrefix[5];
	new String:deMapPrefix[5];
	new String:asMapPrefix[5];
	new String:CurrentMapName[50];	
	new String:GGCFG[50];		
	new String:CSSCFG[50];
	new String:ASCFG[50];
	GetConVarString(cvar_csMapPrefix, csMapPrefix,5);
	GetConVarString(cvar_deMapPrefix, deMapPrefix,5);
	GetConVarString(cvar_asMapPrefix, asMapPrefix,5);
	GetConVarString(cvar_csscfg, CSSCFG,50);
	GetConVarString(cvar_ggcfg, GGCFG,50);
	GetConVarString(cvar_ascfg, ASCFG,50);

	GetCurrentMap(CurrentMapName,50);
	if (StrContains(CurrentMapName,csMapPrefix,false) > -1)
	{
		ServerCommand(CSSCFG);
	}
	else if (StrContains(CurrentMapName,deMapPrefix,false) > -1)
	{
		ServerCommand(CSSCFG);
	}
	else if (StrContains(CurrentMapName,asMapPrefix,false) > -1)
	{
		ServerCommand(ASCFG);
	}
	else if ((StrContains(CurrentMapName,deMapPrefix,false)) == -1 && (StrContains(CurrentMapName,csMapPrefix,false)) == -1 && (StrContains(CurrentMapName,asMapPrefix,false)) == -1)
	{
		ServerCommand(GGCFG);
	}
	return Plugin_Handled;
}
