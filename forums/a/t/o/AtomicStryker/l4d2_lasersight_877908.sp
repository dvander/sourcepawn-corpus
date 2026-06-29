#define PLUGIN_VERSION    "1.0.2"
#define PLUGIN_NAME       "L4D2 Laser Sights"

#include <sourcemod>

static Handle:cvarDelay							= INVALID_HANDLE;

static bool:bHasLaser[MAXPLAYERS+1]				= false;
static Float:fLastCommandUseTime[MAXPLAYERS+1]	= 0.0;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "AtomicStryker",
	description = "L4D2 Laser Sights",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=877908"
};

public OnPluginStart()
{
	CreateConVar("l4d2_lasersight_version", PLUGIN_VERSION, "Lasersight plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarDelay = CreateConVar("l4d2_lasersight_delay", "10.0", " How long do the commands 'cool down' ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_laseron", CmdLaserOn);
	RegConsoleCmd("sm_laseroff", CmdLaserOff);
	RegConsoleCmd("sm_laser", CmdLaserToggle);
}

public Action:CmdLaserOn(client, args)
{
	if (IsCommandCoolingDown(client))
	{
		ReplyToCommand(client, "You cannot use the laser on command again so quickly, wait %i seconds", RoundFloat(GetConVarFloat(cvarDelay)));
		return Plugin_Handled;
	}
	
	CheatCommand(client, "upgrade_add", "LASER_SIGHT");
	bHasLaser[client] = true;
	fLastCommandUseTime[client] = GetEngineTime();
	
	return Plugin_Handled;
}

public Action:CmdLaserOff(client, args)
{
	if (IsCommandCoolingDown(client))
	{
		ReplyToCommand(client, "You cannot use the laser off command again so quickly, wait %i seconds", RoundFloat(GetConVarFloat(cvarDelay)));
		return Plugin_Handled;
	}

	CheatCommand(client, "upgrade_remove", "LASER_SIGHT");
	bHasLaser[client] = false;
	fLastCommandUseTime[client] = GetEngineTime();
	
	return Plugin_Handled;
}

public Action:CmdLaserToggle(client, args)
{
	if (IsCommandCoolingDown(client))
	{
		ReplyToCommand(client, "You cannot use the laser toggle command again so quickly, wait %i seconds", RoundFloat(GetConVarFloat(cvarDelay)));
		return Plugin_Handled;
	}

	if (bHasLaser[client])
	{
		CheatCommand(client, "upgrade_remove", "LASER_SIGHT");
		bHasLaser[client] = false;
		fLastCommandUseTime[client] = GetEngineTime();
	}
	else
	{
		CheatCommand(client, "upgrade_add", "LASER_SIGHT");
		bHasLaser[client] = true;
		fLastCommandUseTime[client] = GetEngineTime();
	}
	fLastCommandUseTime[client] = GetEngineTime();
	
	return Plugin_Handled;
}

static bool:IsCommandCoolingDown(any:client)
{
	if (fLastCommandUseTime[client] == 0.0) 
	{
		return false;
	}
	return ((GetEngineTime() - fLastCommandUseTime[client]) < GetConVarFloat(cvarDelay));
}

stock CheatCommand(client, const String:command[], const String:arguments[])
{
    if (!client) return;
    new admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, admindata);
}