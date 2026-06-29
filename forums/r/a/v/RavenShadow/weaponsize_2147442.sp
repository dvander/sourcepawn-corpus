#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define VERSION "1.0"
public Plugin:myinfo =
{
	name		= "Change Weapon Size",
	author	  	= "Master Xykon edited by RavenShadow for admin commands",
	description = "Change the size of weapons.",
	version	 	= VERSION,
	url		 	= ""
};

public OnPluginStart()
{
	CreateConVar("sm_weaponsize_version", VERSION, "Change the Size of Weapons", FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_weaponsize", WeaponSize);
	RegConsoleCmd("sm_ws", WeaponSize);
	RegAdminCmd("sm_weaponsizer", WeaponSizer, ADMFLAG_KICK);
	RegAdminCmd("sm_resetsize", ResetSize, ADMFLAG_KICK);
	HookEvent("post_inventory_application", OnPlayerInv);
}
public Action:WeaponSize(client, args)
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[WeaponSize] You must be alive");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		new String:cmdName[22];
		GetCmdArg(0, cmdName, sizeof(cmdName));
		ReplyToCommand(client, "[WeaponSize] Usage: %s #", cmdName);
		return Plugin_Handled;
	}
	if (args > 1)
	{
		new String:cmdName[22];
		GetCmdArg(0, cmdName, sizeof(cmdName));
		ReplyToCommand(client, "[WeaponSize] Usage: %s #", cmdName);
		return Plugin_Handled;
	}
	new String:cmdArg[22];
	GetCmdArg(1, cmdArg, sizeof(cmdArg));
	new Float:fArg = StringToFloat(cmdArg);
	if(fArg == 0.0)
	{
		ReplyToCommand(client, "[WeaponSize] No crash with 0.0 size");
		return Plugin_Handled;
	}
	if(fArg < -5.0 || fArg > 5.0)
	{
		ReplyToCommand(client, "[WeaponSize] Only Between -5.0 and 5.0 please");
		return Plugin_Handled;
	}
	new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(ClientWeapon, Prop_Send, "m_flModelScale", fArg);
	
	return Plugin_Handled;
}
public Action:ResetSize(client, args)
{
	new String:target[PLATFORM_MAX_PATH];
	GetCmdArg(1, target, PLATFORM_MAX_PATH);
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;	
	if ((target_count = ProcessTargetString(
	target,
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
	if (args < 1)
	{
		ReplyToCommand(client, "[WeaponSize] Usage: sm_resetsize <target>");
		return Plugin_Handled;
	}
	if (args > 1)
	{
		ReplyToCommand(client, "[WeaponSize] Usage: sm_resetsize <target>");
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new primarytarget = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Primary);
		new secondarytarget = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Secondary);
		new meleetarget = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Melee);
		SetEntPropFloat(primarytarget, Prop_Send, "m_flModelScale", 1.0);
		SetEntPropFloat(secondarytarget, Prop_Send, "m_flModelScale", 1.0);
		SetEntPropFloat(meleetarget, Prop_Send, "m_flModelScale", 1.0);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:WeaponSizer(client, args)
{
	new String:target[PLATFORM_MAX_PATH];
	new String:cmdArg2[22];
	GetCmdArg(1, target, PLATFORM_MAX_PATH);
	GetCmdArg(2, cmdArg2, sizeof(cmdArg2));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count;
	new Float:fArg2 = StringToFloat(cmdArg2);
	new bool:tn_is_ml;	
	if ((target_count = ProcessTargetString(
	target,
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
	
	if (args < 1)
	{
		ReplyToCommand(client, "[WeaponSize] Usage: sm_weaponsizer <target> <size>");
		return Plugin_Handled;
	}
	if (args > 2)
	{
		ReplyToCommand(client, "[WeaponSize] Usage: sm_weaponsizer <target> <size>");
		return Plugin_Handled;
	}
	if(fArg2 == 0.0)
	{
		ReplyToCommand(client, "[WeaponSize] No 0.0 due to crash");
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new TargetWeapon = GetEntPropEnt(target_list[i], Prop_Send, "m_hActiveWeapon");
		SetEntPropFloat(TargetWeapon, Prop_Send, "m_flModelScale", fArg2);
	}
	return Plugin_Handled;
}
public OnPlayerInv(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
    {
		new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(primary != -1)
		{	
			SetEntPropFloat(primary, Prop_Send, "m_flModelScale", 1.0);
		}
		if(secondary != -1)
		{	
			SetEntPropFloat(secondary, Prop_Send, "m_flModelScale", 1.0);
		}
		if(melee != -1)
		{	
			SetEntPropFloat(melee, Prop_Send, "m_flModelScale", 1.0);
		}
	}
}