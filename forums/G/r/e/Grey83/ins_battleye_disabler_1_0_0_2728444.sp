#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "[INS] BattlEye disabler",
	version		= "1.0.0",
	description	= "Disables BattlEye at server when convar \"sv_playlist\" not equal to \"custom\"",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Insurgency) return APLRes_Success;

	FormatEx(error, err_max, "Plugin only for Insurgency (2014)");
	return APLRes_Failure;
}

public void OnPluginStart()
{

	ConVar cvar = FindConVar("sv_battleye");
	if(!cvar)
	{
		PrintToServer("\n > Unable to find convar 'sv_battleye'\n");
		return;
	}

	SetConVarBounds(cvar, ConVarBound_Lower, true, 0.0);
	SetConVarBounds(cvar, ConVarBound_Upper, true, 0.0);
	SetConVarInt(cvar, 0, true);
	PrintToServer("\n > BattlEye successfully disabled\n");
}