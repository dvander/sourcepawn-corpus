#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin:myinfo = {
	name = "L4D No Fog",
	author = "Voiderest",
	description = "No more fog.",
	version = VERSION,
	url = "N/A"
}

new Handle:cvar_fog_override=INVALID_HANDLE;
new Handle:cvar_fog_end=INVALID_HANDLE;
new Handle:cvar_fog_endskybox=INVALID_HANDLE;

public OnPluginStart()
{
	//cvars needed to abuse for listining servers
	cvar_fog_override = FindConVar("fog_override");
	if(cvar_fog_override!=INVALID_HANDLE)
	{
		SetConVarInt(cvar_fog_override, 1, true);
	}
	cvar_fog_end = FindConVar("fog_end");
	if(cvar_fog_end!=INVALID_HANDLE)
	{
		SetConVarInt(cvar_fog_end, 1000000, true);
	}
	cvar_fog_endskybox = FindConVar("fog_endskybox");
	if(cvar_fog_endskybox!=INVALID_HANDLE)
	{
		SetConVarInt(cvar_fog_endskybox, 1000000, true);
	}
	
	RegAdminCmd("l4d_no_fog_revoke", cmdRevoke, ADMFLAG_KICK, "Removes the cheat flag for client, will bring fog back");
}

public OnClientPutInServer(client) {
	if(!IsFakeClient(client))
	{
		removeFog(client);
	}
}

removeFog(client)
{
	decl String:ipaddr[24];
	GetClientIP(client, ipaddr, sizeof(ipaddr));
	
	if (!StrEqual(ipaddr,"loopback",false))
	{
		//I learned to do this by lookig at grandwazir's blindluck plugin, http://forums.alliedmods.net/showthread.php?t=84926
		SendConVarValue(client, FindConVar("sv_cheats"), "1");
		ClientCommand(client, "fog_override 1");
		ClientCommand(client, "fog_end 1000000");
		ClientCommand(client, "fog_endskybox 1000000");
	}
}

public Action:cmdRevoke(client, args) //based off the slay command
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: l4d_no_fog_revoke <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		SendConVarValue(client, FindConVar("sv_cheats"), "0");
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Revoked target fog privileges.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Revoked target fog privileges.", "_s", target_name);
	}

	return Plugin_Handled;
}