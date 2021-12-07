#include <sourcemod>
#pragma newdecls required

#define PLUGIN_VERSION "1.0.3"	

ConVar DisableDelay, IsAnnoucementOn, glowSurvivors;

public Plugin myinfo =
{
	name = "[L4D2] Realism Name Check",
	author = "V1sual",
	description = "Allows admins to turn on names in realism versus/coop realism to catch teamkillers, cheaters and exploit users",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1174387"
};

public void OnPluginStart()
{
	char game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("This plugin will only work on L4D2");

	RegAdminCmd("sm_checkname", RealismCheck, ADMFLAG_CHAT);  
	RegAdminCmd("sm_namecheck", RealismCheck, ADMFLAG_CHAT); 
	RegAdminCmd("sm_names",     RealismCheck, ADMFLAG_CHAT);   
	
	glowSurvivors = FindConVar("sv_disable_glow_survivors");

	DisableDelay = CreateConVar("l4d2_namecheckdisabletime", "15.0", "Delay before realism name check is disabled (in seconds)", FCVAR_NOTIFY);
	IsAnnoucementOn = CreateConVar("l4d2_namecheckannounce", "1", "Should we tell players if an admin turns on names?", FCVAR_NOTIFY);
	CreateConVar("l4d2_realism_namecheck", PLUGIN_VERSION, "Realism Name Check Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d2_realism_namecheck");
}    

public Action RealismCheck(int client, int args)
{
	glowSurvivors.SetInt(0); 

	if (IsAnnoucementOn.BoolValue)
	{
		PrintToChatAll("\x05(ADMIN)\x01 Enabled player names for all survivors.");
	}

	CreateTimer(DisableDelay.FloatValue, TimerDisableDelay);
	
	return Plugin_Handled;
} 

public Action TimerDisableDelay(Handle timer)
{
	glowSurvivors.SetInt(1); 

	if (IsAnnoucementOn.BoolValue)
	{
		PrintToChatAll("\x05(ADMIN)\x01 Disabled player names for all survivors.");
	}
}  

