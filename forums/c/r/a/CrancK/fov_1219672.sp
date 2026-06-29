#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "0.0.1"

#define MAX_PLAYERS 33

public Plugin:myinfo = {
	name = "TF2 Fov",
	author = "CrancK",
	description = "Fov Changer",
	version = PLUGIN_VERSION,
	url = ""
};

new offsFOV = -1;
new offsDefaultFOV = -1;
new fov[MAX_PLAYERS+1];

new Handle:g_fovEnabled = INVALID_HANDLE;
new Handle:cvFovMax = INVALID_HANDLE;

public OnPluginStart() 
{
	CreateConVar("sm_fov_version", PLUGIN_VERSION, "fov Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_fovEnabled = CreateConVar("sm_fovEnabled", "1.0", "allows changing of fov", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvFovMax = CreateConVar("sm_fovmax", "160", "set's the max limit for the fov command", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_fov", Command_fov, "Set your FOV.");
	offsFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	offsDefaultFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
}

public OnClientPutInServer(client) 
{
	fov[client] = GetEntData(client, offsFOV, 4);
}

public Action:Command_fov(client, args) 
{
	if(GetConVarInt(g_fovEnabled) == 1) {
		if(args>0) {
			new String:arg[32];
			GetCmdArg(1, arg, sizeof(arg));
			for(new i=0;i<strlen(arg);i++) {
				if(!IsCharNumeric(arg[i])) {
					ReplyToCommand(client, "Value must be an integer.");
					return Plugin_Handled;
				}
			}
			if(StringToInt(arg)<=0 || StringToInt(arg)>GetConVarInt(cvFovMax)) {
				ReplyToCommand(client, "Value must be between 1 and %i.", GetConVarInt(cvFovMax));
				return Plugin_Handled;
			}
			
			fov[client] = StringToInt(arg);
			SetEntData(client, offsFOV, fov[client], 4, true);
			SetEntData(client, offsDefaultFOV, fov[client], 4, true);
			ReplyToCommand(client, "FOV set to %i.", fov[client]);
		} else {
			ReplyToCommand(client, "FOV: %i", fov[client]);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

