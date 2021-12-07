#pragma semicolon 1

#include <sdktools>

#define VERSION "1.1"
 
public Plugin:myinfo =
{
	name		= "[CSS/CSGO] Flash teleport",
	author		= "Pypsikan & iNex",
	description	= "Teleport entity or client to flash explose, Just for Admin.",
	version		= VERSION,
	url			= "http://sourcemod.net"
}

new Handle:g_hFlashWarp = INVALID_HANDLE;
new Handle:g_hFlashWarp_admin = INVALID_HANDLE;
new Handle:g_hFlashWarp_bot = INVALID_HANDLE;

new sm_flashwarp = 1;
new sm_flashwarp_admin = 0;
new sm_flashwarp_bot = 0;
 
public OnPluginStart()
{
	HookEvent("flashbang_detonate", FlashDetonate);
	
	CreateConVar("sm_flashteleport_version", VERSION, "Flash teleport plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hFlashWarp = CreateConVar("sm_flashwarp","1","Enable/disable plugin?");
	g_hFlashWarp_admin = CreateConVar("sm_flashwarp_admin","0","Only admins can use flash teleport?");
	g_hFlashWarp_bot = CreateConVar("sm_flashwarp_bot","0","Bots can use flash-teleport?");
	
	HookConVarChange(g_hFlashWarp, Hooksm_flashwarp);
	HookConVarChange(g_hFlashWarp_admin, Hooksm_flashwarp_admin);
	HookConVarChange(g_hFlashWarp_bot, Hooksm_flashwarp_Bot);
	
	AutoExecConfig(true,"flash_teleport");
}

public Hooksm_flashwarp(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	sm_flashwarp = StringToInt(newValue);
}

public Hooksm_flashwarp_admin(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	sm_flashwarp_admin = StringToInt(newValue);
}

public Hooksm_flashwarp_Bot(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	sm_flashwarp_bot = StringToInt(newValue);
}
 
public Action:FlashDetonate(Handle:event,String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!sm_flashwarp || (IsFakeClient(client) && !sm_flashwarp_bot)) return Plugin_Handled;
	
	new Float:Tel[3];
	GetClientAbsOrigin(client, Tel);
	Tel[0] = GetEventFloat(event, "x");
	Tel[1] = GetEventFloat(event, "y");
	Tel[2] = GetEventFloat(event, "z");
	
	if (sm_flashwarp_admin && (GetAdminFlag(GetUserAdmin(client), Admin_Slay) || GetAdminFlag(GetUserAdmin(client), Admin_Root)))
	{
		TeleportEntity(client, Tel, NULL_VECTOR, NULL_VECTOR);
	}
	else if(!sm_flashwarp_admin)
	{
		TeleportEntity(client, Tel, NULL_VECTOR, NULL_VECTOR);
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
	
	return Plugin_Handled;
}