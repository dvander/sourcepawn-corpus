#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.00"

/* ChangeLog
1.00	Release
*/

public Plugin:myinfo = {
	name = "ZPS Force Panic",
	author = "Will2Tango",
	description = "ZPS Force Panic.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("zps_forcepanic", PLUGIN_VERSION, "ZPS Server Addons", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_panic", Command_Panic, ADMFLAG_BAN, "Panic a Player.");
	RegAdminCmd("sm_drop", Command_Drop, ADMFLAG_BAN, "Make Player Drop Weapon.");
}

public Action:Command_Panic(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_panic <target>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && !IsFakeClient(targets[i]))
	{
		new target = targets[i];
		FakeClientCommandEx(target, "panic");
		FakeClientCommandEx(target, "dropweapon");
		ReplyToCommand(client, "[SM] Paniced %N.", target);

		LogAction(client, target, "\"%L\" Forced \"%L\" to Panic", client, target);
	}
	return Plugin_Handled;
}

public Action:Command_Drop(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_drop <target>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && !IsFakeClient(targets[i]))
	{
		new target = targets[i];
		FakeClientCommandEx(target, "dropweapon");
		ReplyToCommand(client, "[SM] Disarmed %N.", target);

		LogAction(client, target, "\"%L\" Forced \"%L\" to DropWeapon", client, target);
	}
	return Plugin_Handled;
}