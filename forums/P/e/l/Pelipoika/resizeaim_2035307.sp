#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.5"

public Plugin:myinfo =
{
	name = "Resize aim",
	author = "Pelipoika",
	description = "Resize things you point at",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_resizeaim", Command_Aim, ADMFLAG_ROOT);
}

public Action:Command_Aim(client, args)
{
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if(args == 0)
	{
		ReplyToCommand(client, "Usage: sm_resizeaim <size>");
	}
	
	new target = GetClientAimTarget(client, false);
	
	if(IsValidEntity(target) && args != 0)
	{
		SetEntPropFloat(target, Prop_Send, "m_flModelScale", StringToFloat(arg1));
	}
	else
	{
		ReplyToCommand(client, "Not a Valid target");
	}
}
