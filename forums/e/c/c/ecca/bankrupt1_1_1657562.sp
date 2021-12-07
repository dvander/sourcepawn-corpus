#include <sourcemod>

#define PLUGIN_VERSION "1.1"

new bool:IsBankRupt[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name	= "BankRupt",
	author	= "ecca",
	description	= "Allows you to bankrupt a players money account",
	version	= PLUGIN_VERSION,
	url		= "http://sourcemod.net"
};

public OnPluginStart()
{
	RegAdminCmd("sm_bankrupt", Command_BankRupt, ADMFLAG_SLAY, "Command to Bankrupt a player");
	RegAdminCmd("sm_unbankrupt", Command_UnBankRupt, ADMFLAG_SLAY, "Command to UnBankrupt a player");
	HookEvent("player_spawn", PlayerSpawn);
	
	CreateConVar("sm_bankrupt_version", PLUGIN_VERSION,  "The version of the SourceMod plugin BankRupt, by ecca", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public Action:Command_BankRupt(client, args)
{
	if(client == 0)
	{
		PrintToServer("[BankRupt] Console is not allowed to use this command!");
		return Plugin_Handled;
	}
	
	if(args == 0 )
	{
		PrintToChat(client, "\x03[BankRupt] \x01Usage: sm_bankrupt <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	new target = FindTarget(client, arg);
	
	if( target > 0 && target <= MaxClients )
	{
		new String:user[64];
		GetClientName(target,user,sizeof(user));
		
		new String:admin[64];
		GetClientName(client,admin,sizeof(user));
		
		PrintToChatAll("\x03[SM] \x01ADMIN: %s: Set BankRupt on %s", admin, user);
		IsBankRupt[target] = true;
	}
	
	return Plugin_Handled;
}

public Action:Command_UnBankRupt(client, args)
{
	if(client == 0)
	{
		PrintToServer("[BankRupt] Console is not allowed to use this command!");
		return Plugin_Handled;
	}
	
	if(args == 0 )
	{
		PrintToChat(client, "\x03[BankRupt] \x01Usage: sm_unbankrupt <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	new target = FindTarget(client, arg);
	
	if( target > 0 && target <= MaxClients )
	{
		new String:user[64];
		GetClientName(target,user,sizeof(user));
		
		new String:admin[64];
		GetClientName(client,admin,sizeof(user));
		
		PrintToChatAll("\x03[SM] \x01ADMIN: %s: Removed the BankRupt on %s", admin, user);
		IsBankRupt[target] = false;
	}
	
	return Plugin_Handled;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	
	if(IsBankRupt[client] && IsClientInGame(client) && !IsFakeClient(client))
	{
		new g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		SetEntData(client, g_iAccount, 0);
		
		PrintToChat(client, "\x03[SM] \x01You are BankRupt and won't get any money");
	}
}