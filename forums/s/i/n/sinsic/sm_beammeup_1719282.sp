#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"



new Float:enterprise_origin[3];



new Float:enterprise_angles[3];
new Handle:sm_beammeup_version	= INVALID_HANDLE;

public Plugin:myinfo = 
	{
	name = "Beam me up, Scotty",
	author = "Sinsic",
	description = "Teleports a user to another user or to you.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() 
	{
	
	RegAdminCmd("sm_beammeup", Beam_Me, ADMFLAG_KICK, "sm_beammeup <target name> <teleporter name>");
	RegAdminCmd("sm_beamtome", Beam_Tome, ADMFLAG_KICK, "sm_beamtome <teleporter name>");
	sm_beammeup_version = CreateConVar("sm_beammeup_version", PLUGIN_VERSION, "Beam me up, Scotty Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(sm_beammeup_version, PLUGIN_VERSION);
	HookConVarChange(sm_beammeup_version, sm_beammeup_versionchange);
}


public sm_beammeup_versionchange(Handle:convar, const String:oldValue[], const String:newValue[])
	{
	SetConVarString(convar, PLUGIN_VERSION);
}


public Action:Beam_Me(client, args) 
	{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_beammeup <target name> <teleporter name>");
		return Plugin_Handled;
	}
	new String:arg1[32];
	new String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new target1 = FindTarget(client, arg1);
	GetClientName(target1, arg1, sizeof(arg1));

	new target2 = FindTarget(client, arg2);
	GetClientName(target2, arg2, sizeof(arg2));

	if (IsPlayerAlive(target1)) 
			{
			GetClientAbsOrigin(target1, enterprise_origin);
			GetClientAbsAngles(target1, enterprise_angles);

			if (IsPlayerAlive(target2)) 
				{
				TeleportEntity(target2, enterprise_origin, enterprise_angles, NULL_VECTOR);
				PrintToChatAll("\x03[SM] \x04 %N\x01 successfully beamed up!", target2);
				return Plugin_Handled;
				} else return Plugin_Handled;				
	} else return Plugin_Handled;
}

public Action:Beam_Tome(client, args) 
	{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_beamtome <teleporter name>");
		return Plugin_Handled;
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));


	new target = FindTarget(client, arg);
	GetClientName(target, arg, sizeof(arg));

	if (IsPlayerAlive(client)) 
			{
			GetClientAbsOrigin(client, enterprise_origin);
			GetClientAbsAngles(client, enterprise_angles);

			if (IsPlayerAlive(target)) 
				{
				TeleportEntity(target, enterprise_origin, enterprise_angles, NULL_VECTOR);
				PrintToChatAll("\x03[SM] \x04 %N\x01 successfully beamed up!", target);
				return Plugin_Handled;
				} else return Plugin_Handled;				
	} else return Plugin_Handled;
}