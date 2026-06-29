#pragma semicolon 1

#include <sdktools>
#pragma newdecls required

#define PLUGIN_AUTHOR "SM9 (xCoderx)"
#define PLUGIN_VERSION "0.1"

public Plugin myinfo = 
{
	name = "Timeleft As RoundTime", 
	author = PLUGIN_AUTHOR, 
	version = PLUGIN_VERSION, 
};

public void OnPluginStart() {
	CreateConVar("tlrt_version", PLUGIN_VERSION, "Version of Timeleft As RoundTime", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
}

public void OnMapTimeLeftChanged()
{
	int iTimeLeft;
	
	if (GetMapTimeLeft(iTimeLeft) && GameRules_GetProp("m_iRoundTime") -1 != iTimeLeft) {
		GameRules_SetProp("m_iRoundTime", iTimeLeft -1);
	}
}