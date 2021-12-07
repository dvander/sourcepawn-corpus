#include <sourcemod>
#include <admin>

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[Any] Admin Flags",
	author = "Mitch",
	description = "Modifys admins/flags/immunity/overrides in the admin cache.",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:gAdd = INVALID_HANDLE;
new Handle:gDel = INVALID_HANDLE;
new Handle:gInv = INVALID_HANDLE;
new Handle:gImm = INVALID_HANDLE;
new Handle:gOver =INVALID_HANDLE;
new Handle:gUnover = INVALID_HANDLE;
new Handle:gCadmin = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_adminflag_version", VERSION, "SM ADMINFLAG Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gAdd = CreateConVar("sm_addflag_disable", "0", "Disable/Enable(1/0) Enable or disable sm_addflag", FCVAR_PLUGIN|FCVAR_NOTIFY);
	gDel = CreateConVar("sm_delflag_disable", "0", "Disable/Enable(1/0) Enable or disable sm_delflag", FCVAR_PLUGIN|FCVAR_NOTIFY);
	gInv = CreateConVar("sm_invalidate_disable", "0", "Disable/Enable(1/0) Enable or disable sm_invalidate", FCVAR_PLUGIN|FCVAR_NOTIFY);
	gImm = CreateConVar("sm_immunity_disable", "0", "Disable/Enable(1/0) Enable or disable sm_immunity", FCVAR_PLUGIN|FCVAR_NOTIFY);
	gOver = CreateConVar("sm_override_disable", "0", "Disable/Enable(1/0) Enable or disable sm_override", FCVAR_PLUGIN|FCVAR_NOTIFY);
	gUnover = CreateConVar("sm_unoverride_disable", "0", "Disable/Enable(1/0) Enable or disable sm_unoverride", FCVAR_PLUGIN|FCVAR_NOTIFY);
	gCadmin = CreateConVar("sm_createadmin_disable", "0", "Disable/Enable(1/0) Enable or disable sm_createadmin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_addflag", Command_Addflag, ADMFLAG_ROOT, "Adds a specific admin flag to an admin.");
	RegAdminCmd("sm_delflag", Command_Delflag, ADMFLAG_ROOT, "Removes a specific admin flag to an admin.");
	RegAdminCmd("sm_listflags", Command_Listflags, ADMFLAG_BAN, "Lists all of the admin flags used in this plugin.");
	RegAdminCmd("sm_invalidate", Command_Invalidate, ADMFLAG_ROOT, "Invalidates an admin's admin id.");
	RegAdminCmd("sm_setimmunity", Command_Setimmunity, ADMFLAG_ROOT, "Sets an admin's immunity.");
	RegAdminCmd("sm_getimmunity", Command_Getimmunity, ADMFLAG_BAN, "Finds an admin's immunity level.");
	RegAdminCmd("sm_override", Command_Override, ADMFLAG_ROOT, "Overrides a command to a specific flag.");
	RegAdminCmd("sm_unoverride", Command_Unoverride, ADMFLAG_ROOT, "Unsets a command override.");
	RegAdminCmd("sm_createadmin", Command_Createadmin, ADMFLAG_ROOT, "Creates an admin.");
	//sm_who <name> can be used to find the flags that someone currently has.
	//sm_reloadamdins and/or a map change will undo anything done with this plugin.
}

public Action:Command_Addflag(client, args)
{
	if(GetConVarBool(gAdd))
	{
		ReplyToCommand(client, "[SM] sm_addflag is not enabled");
		return Plugin_Handled;
	}	
	if(args  != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addflag <#userid|name> <flag>");
		return Plugin_Handled;
	}
	
	decl String:Target[64];
	decl String:flag[20];
	decl String:name[128];	
	
	GetCmdArg(1, Target, sizeof(Target));
	GetCmdArg(2, flag, sizeof(flag));
	
	new itarget = FindTarget(client, Target, true, true);
	if(itarget == -1)
		{
			return Plugin_Handled;
		}
	new AdminId:iAdminID = GetUserAdmin(itarget);
	GetClientName(itarget, name, sizeof(name));
	
	if(StrEqual(flag, "reserved", false))
		{
			SetAdminFlag(iAdminID, Admin_Reservation, true);
		}
		else if(StrEqual(flag, "generic", false))
		{
			SetAdminFlag(iAdminID, Admin_Generic, true);
		}
		else if(StrEqual(flag, "kick", false))
		{
			SetAdminFlag(iAdminID, Admin_Kick, true);
		}
		else if(StrEqual(flag, "ban", false))
		{
			SetAdminFlag(iAdminID, Admin_Ban, true);				
		}
		else if(StrEqual(flag, "unban", false))
		{
			SetAdminFlag(iAdminID, Admin_Unban, true);
		}
		else if(StrEqual(flag, "slay", false))
		{	
			SetAdminFlag(iAdminID, Admin_Slay, true);
		}
		else if(StrEqual(flag, "changemap", false))
		{	
			SetAdminFlag(iAdminID, Admin_Changemap, true);	
		}
		else if(StrEqual(flag, "convar", false))
		{
			SetAdminFlag(iAdminID, Admin_Convars, true);	
		}
		else if(StrEqual(flag, "config", false))
		{
			SetAdminFlag(iAdminID, Admin_Config, true);
		}
		else if(StrEqual(flag, "chat", false))
		{
			SetAdminFlag(iAdminID, Admin_Chat, true);	
		}
		else if(StrEqual(flag, "vote", false))
		{
			SetAdminFlag(iAdminID, Admin_Vote, true);	
		}
		else if(StrEqual(flag, "password", false))
		{
			SetAdminFlag(iAdminID, Admin_Password, true);	
		}
		else if(StrEqual(flag, "rcon", false))
		{
			SetAdminFlag(iAdminID, Admin_RCON, true);	
		}
		else if(StrEqual(flag, "cheats", false))
		{
			SetAdminFlag(iAdminID, Admin_Cheats, true);
		}
		else if(StrEqual(flag, "root", false))
		{
			SetAdminFlag(iAdminID, Admin_Root, true);	
		}
		else if(StrEqual(flag, "custom1", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom1, true);	
		}
		else if(StrEqual(flag, "custom2", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom2, true);	
		}
		else if(StrEqual(flag, "custom3", false))
		{	
			SetAdminFlag(iAdminID, Admin_Custom3, true);
		}
		else if(StrEqual(flag, "custom4", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom4, true);
		}
		else if(StrEqual(flag, "custom5", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom5, true);	
		}
		else if(StrEqual(flag, "custom6", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom6, true);
		}
		else if(StrEqual(flag, "all", false))
		{
			SetAdminFlag(iAdminID, Admin_Reservation, true);
			SetAdminFlag(iAdminID, Admin_Generic, true);
			SetAdminFlag(iAdminID, Admin_Kick, true);
			SetAdminFlag(iAdminID, Admin_Ban, true);
			SetAdminFlag(iAdminID, Admin_Unban, true);
			SetAdminFlag(iAdminID, Admin_Slay, true);
			SetAdminFlag(iAdminID, Admin_Changemap, true);
			SetAdminFlag(iAdminID, Admin_Convars, true);
			SetAdminFlag(iAdminID, Admin_Config, true);
			SetAdminFlag(iAdminID, Admin_Chat, true);
			SetAdminFlag(iAdminID, Admin_Vote, true);
			SetAdminFlag(iAdminID, Admin_Password, true);
			SetAdminFlag(iAdminID, Admin_RCON, true);
			SetAdminFlag(iAdminID, Admin_Cheats, true);
			SetAdminFlag(iAdminID, Admin_Root, true);	
			SetAdminFlag(iAdminID, Admin_Custom1, true);	
			SetAdminFlag(iAdminID, Admin_Custom2, true);
			SetAdminFlag(iAdminID, Admin_Custom3, true);
			SetAdminFlag(iAdminID, Admin_Custom4, true);
			SetAdminFlag(iAdminID, Admin_Custom5, true);
			SetAdminFlag(iAdminID, Admin_Custom6, true);
		}
		else
		{
			ReplyToCommand(client, "[SM] Invalid flag (\"%s\")", flag);
			return Plugin_Handled;
		}
	
	LogAction(client, itarget, "%L added the %s flag to %L ", client, flag, itarget);
	ReplyToCommand(client, "[SM] Added the %s flag to %N ", flag, itarget);
	return Plugin_Handled; 
	
}


public Action:Command_Delflag(client, args)
{
	if(GetConVarBool(gDel))
	{
		ReplyToCommand(client, "[SM] sm_delflag is not enabled");
		return Plugin_Handled;
	}	
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_delflag <#userid|name> <flag>");
		return Plugin_Handled;
	}
	
	decl String:Target[64];
	decl String:flag[20];

	GetCmdArg(1, Target, sizeof(Target));
	GetCmdArg(2, flag, sizeof(flag));
	
	new itarget = FindTarget(client, Target, true, true);
	if(itarget == -1)
		{
			return Plugin_Handled;
		}
	new AdminId:iAdminID = GetUserAdmin(itarget);
	
	if(StrEqual(flag, "reserved", false))
		{
			SetAdminFlag(iAdminID, Admin_Reservation, false);
		}
		else if(StrEqual(flag, "generic", false))
		{
			SetAdminFlag(iAdminID, Admin_Generic, false);
		}
		else if(StrEqual(flag, "kick", false))
		{
			SetAdminFlag(iAdminID, Admin_Kick, false);
		}
		else if(StrEqual(flag, "ban", false))
		{
			SetAdminFlag(iAdminID, Admin_Ban, false);				
		}
		else if(StrEqual(flag, "unban", false))
		{
			SetAdminFlag(iAdminID, Admin_Unban, false);
		}
		else if(StrEqual(flag, "slay", false))
		{	
			SetAdminFlag(iAdminID, Admin_Slay, false);
		}
		else if(StrEqual(flag, "changemap", false))
		{	
			SetAdminFlag(iAdminID, Admin_Changemap, false);	
		}
		else if(StrEqual(flag, "convar", false))
		{
			SetAdminFlag(iAdminID, Admin_Convars, false);	
		}
		else if(StrEqual(flag, "config", false))
		{
			SetAdminFlag(iAdminID, Admin_Config, false);
		}
		else if(StrEqual(flag, "chat", false))
		{
			SetAdminFlag(iAdminID, Admin_Chat, false);	
		}
		else if(StrEqual(flag, "vote", false))
		{
			SetAdminFlag(iAdminID, Admin_Vote, false);	
		}
		else if(StrEqual(flag, "password", false))
		{
			SetAdminFlag(iAdminID, Admin_Password, false);	
		}
		else if(StrEqual(flag, "rcon", false))
		{
			SetAdminFlag(iAdminID, Admin_RCON, false);	
		}
		else if(StrEqual(flag, "cheats", false))
		{
			SetAdminFlag(iAdminID, Admin_Cheats, false);
		}
		else if(StrEqual(flag, "root", false))
		{
			SetAdminFlag(iAdminID, Admin_Root, false);	
		}
		else if(StrEqual(flag, "custom1", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom1, false);	
		}
		else if(StrEqual(flag, "custom2", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom2, false);	
		}
		else if(StrEqual(flag, "custom3", false))
		{	
			SetAdminFlag(iAdminID, Admin_Custom3, false);
		}
		else if(StrEqual(flag, "custom4", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom4, false);
		}
		else if(StrEqual(flag, "custom5", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom5, false);	
		}
		else if(StrEqual(flag, "custom6", false))
		{
			SetAdminFlag(iAdminID, Admin_Custom6, false);
		}
		else if(StrEqual(flag, "all", false))
		{
			SetAdminFlag(iAdminID, Admin_Reservation, false);
			SetAdminFlag(iAdminID, Admin_Generic, false);
			SetAdminFlag(iAdminID, Admin_Kick, false);
			SetAdminFlag(iAdminID, Admin_Ban, false);
			SetAdminFlag(iAdminID, Admin_Unban, false);
			SetAdminFlag(iAdminID, Admin_Slay, false);
			SetAdminFlag(iAdminID, Admin_Changemap, false);
			SetAdminFlag(iAdminID, Admin_Convars, false);
			SetAdminFlag(iAdminID, Admin_Config, false);
			SetAdminFlag(iAdminID, Admin_Chat, false);
			SetAdminFlag(iAdminID, Admin_Vote, false);
			SetAdminFlag(iAdminID, Admin_Password, false);
			SetAdminFlag(iAdminID, Admin_RCON, false);
			SetAdminFlag(iAdminID, Admin_Cheats, false);
			SetAdminFlag(iAdminID, Admin_Root, false);	
			SetAdminFlag(iAdminID, Admin_Custom1, false);	
			SetAdminFlag(iAdminID, Admin_Custom2, false);
			SetAdminFlag(iAdminID, Admin_Custom3, false);
			SetAdminFlag(iAdminID, Admin_Custom4, false);
			SetAdminFlag(iAdminID, Admin_Custom5, false);
			SetAdminFlag(iAdminID, Admin_Custom6, false);
		}
		else
		{
			ReplyToCommand(client, "[SM] Invalid flag (\"%s\")", flag);
			return Plugin_Handled;
		}
	
	LogAction(client, itarget, "%L removed the %s flag from %L ", client, flag, itarget);
	ReplyToCommand(client, "[SM] Removed the %s flag from %N ", flag, itarget);
	return Plugin_Handled; 
	
}

public Action:Command_Listflags(client, args)
{
	ReplyToCommand(client, "[SM] Flags: Reserved, Generic, Kick, Ban, Unban, Slay, Changemap, Convars, Config, Chat, Vote, Password, Rcon, Cheats, Root, Custom1, Custom2, Custom3, Custom4, Custom5, Custom6, All.");
	return Plugin_Handled;
}

public Action:Command_Invalidate(client, args)
{
	if(GetConVarBool(gInv))
	{
		ReplyToCommand(client, "[SM] sm_invalidate is not enabled.");
		return Plugin_Handled;
	}	
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_invalidate <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:Target[64];
	
	GetCmdArg(1, Target, sizeof(Target));
	
	new iTarget = FindTarget(client, Target, true, true);
	if(iTarget == -1)
		{
			return Plugin_Handled;
		}
	new AdminId:iAdminID = GetUserAdmin(iTarget);
	
	LogAction(client, iTarget, "%L invaladated %L's admin id.", client, iTarget);
	RemoveAdmin(iAdminID);
	ReplyToCommand(client, "[SM] Invalidated %N's admin id.", iTarget);
	
	return Plugin_Handled; 
	
}

public Action:Command_Setimmunity(client, args)
{
	if(GetConVarBool(gImm))
	{
		ReplyToCommand(client, "[SM] sm_setimmunity is not enabled.");
		return Plugin_Handled;
	}	
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setimmunity <#userid|name> <level>");
		return Plugin_Handled;
	}
	
	decl String:Target[64];
	decl String:Level[128];
	
	GetCmdArg(1, Target, sizeof(Target));
	GetCmdArg(2, Level, sizeof(Level));
	
	new iTarget = FindTarget(client, Target, true, true);
	if(iTarget == -1)
		{
			return Plugin_Handled;
		}
	new AdminId:iAdminID = GetUserAdmin(iTarget);
	new iimmune = StringToInt(Level);
	
	LogAction(client, iTarget, "%L set %L's immunity to %i.", client, iTarget, iimmune);
	SetAdminImmunityLevel(iAdminID, iimmune); 
	ReplyToCommand(client, "[SM] Set %N's immunity to %i.", iTarget, iimmune);
	
	return Plugin_Handled; 
	
}
public Action:Command_Getimmunity(client, args)
{

	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_getimmunity <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:Target[64];
	
	GetCmdArg(1, Target, sizeof(Target));
	
	new iTarget = FindTarget(client, Target, true, true);
	if(iTarget == -1)
		{
			return Plugin_Handled;
		}
	new AdminId:iAdminID = GetUserAdmin(iTarget);
	
	new level = GetAdminImmunityLevel(iAdminID); 
	ReplyToCommand(client, "[SM] %N's immunity is %i.", iTarget, level);
	
	return Plugin_Handled; 
	
}

public Action:Command_Override(client, args)
{
	if(GetConVarBool(gOver))
	{
		ReplyToCommand(client, "[SM] sm_override is not enabled");
		return Plugin_Handled;
	}	
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_override <command> <flag> ");
		return Plugin_Handled;
	}
	
	decl String:command[64];
	decl String:flag[20];
	
	GetCmdArg(1, command, sizeof(command));
	GetCmdArg(2, flag, sizeof(flag));
	
	if(StrEqual(flag, "reserved", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_RESERVATION);
		}
		else if(StrEqual(flag, "generic", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_GENERIC);
		}
		else if(StrEqual(flag, "kick", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_KICK);
		}
		else if(StrEqual(flag, "ban", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_BAN);				
		}
		else if(StrEqual(flag, "unban", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_UNBAN);
		}
		else if(StrEqual(flag, "slay", false))
		{	
			AddCommandOverride(command, Override_Command, ADMFLAG_SLAY);
		}
		else if(StrEqual(flag, "changemap", false))
		{	
			AddCommandOverride(command, Override_Command, ADMFLAG_CHANGEMAP);	
		}
		else if(StrEqual(flag, "convar", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CONVARS);	
		}
		else if(StrEqual(flag, "config", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CONFIG);
		}
		else if(StrEqual(flag, "chat", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CHAT);	
		}
		else if(StrEqual(flag, "vote", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_VOTE);
		}
		else if(StrEqual(flag, "password", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_PASSWORD);	
		}
		else if(StrEqual(flag, "rcon", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_RCON);	
		}
		else if(StrEqual(flag, "cheats", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CHEATS);
		}
		else if(StrEqual(flag, "root", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_ROOT);	
		}
		else if(StrEqual(flag, "custom1", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CUSTOM1);
		}
		else if(StrEqual(flag, "custom2", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CUSTOM2);
		}
		else if(StrEqual(flag, "custom3", false))
		{	
			AddCommandOverride(command, Override_Command, ADMFLAG_CUSTOM3);
		}
		else if(StrEqual(flag, "custom4", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CUSTOM4);
		}
		else if(StrEqual(flag, "custom5", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CUSTOM5);
		}
		else if(StrEqual(flag, "custom6", false))
		{
			AddCommandOverride(command, Override_Command, ADMFLAG_CUSTOM6);
		}
		else
		{
			ReplyToCommand(client, "[SM] Invalid flag (\"%s\")", flag);
			return Plugin_Handled;
		}
	
	LogAction(client, -1, "%L overrode the (%s) command to the %s flag.", client, command, flag);
	ReplyToCommand(client, "[SM] Overrode the (%s) command to the %s flag.", command, flag);
	return Plugin_Handled; 
	
}

public Action:Command_Unoverride(client, args)
{
	if(GetConVarBool(gUnover))
	{
		ReplyToCommand(client, "[SM] sm_unoverride is not enabled");
		return Plugin_Handled;
	}	
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unoverride <command>");
		return Plugin_Handled;
	}
	
	decl String:command[64];
	
	GetCmdArgString(command, sizeof(command));
	
	LogAction(client, -1, "%L Unoverrode the %s command.", client, command);
	UnsetCommandOverride(command, OverrideType:Override_Command); 
	ReplyToCommand(client, "[SM] Unoverrode the (%s) command.", command);
	
	return Plugin_Handled; 
	
}

public Action:Command_Createadmin(client, args)
{
	if(GetConVarBool(gCadmin))
	{
		ReplyToCommand(client, "[SM] sm_createadmin is not enabled");
		return Plugin_Handled;
	}	
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_createadmin <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:Target[64];
	GetCmdArg(1, Target, sizeof(Target));
	
	new iTarget = FindTarget(client, Target, true, true);
	if(iTarget == -1)
		{
			return Plugin_Handled;
		}
	new AdminId:admin = CreateAdmin("tempadmin");
	SetUserAdmin(iTarget, admin);
	
	LogAction(client, iTarget, "%L gave %L admin access.", client, iTarget);
	ReplyToCommand(client, "[SM] Gave %N admin access.", iTarget);
	
	return Plugin_Handled; 
	
}