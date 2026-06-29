#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin myinfo = {
	name        = "Color & Resize weapons [RGB Colors]",
	author      = "TheUnderTaker",
	description = "Color & Resize weapons",
	version     = "1.1",
	url         = "http://steamcommunity.com/id/theundertaker007/",
};

public OnPluginStart()
{
	// Commands
	RegConsoleCmd("sm_resizeweapon", ResizeWeapon);
	RegConsoleCmd("sm_rw", ResizeWeapon);
	RegConsoleCmd("sm_colorweapon", ColorWeapon);
	RegConsoleCmd("sm_cw", ColorWeapon);
}

public Action ResizeWeapon(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "Wrong usage, Usage sm_resizeweapon <size> / sm_rw <size>");
	return Plugin_Handled;
	}
	if(client == 0)
	{
	PrintToServer("Command In-game Only!");
	}
	char sizew[32];
	GetCmdArg(1, sizew, sizeof(sizew));
	StringToFloat(sizew);
	if(StringToFloat(sizew) < 0.0)
	{
	ReplyToCommand(client, "Size too small.(0.0-4.0)");
	return Plugin_Handled;
	}
	if(StringToFloat(sizew) > 4.0)
	{
	ReplyToCommand(client, "Size too big.(0.0-4.0)");
	return Plugin_Handled;
	}
	
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(GetPlayerWeaponSlot(client, 2)) {
	SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", StringToFloat(sizew));
	PrintToChat(client, "You resized your weapon successfully.");
	}
	else {
	ReplyToCommand(client, "You can not resize weapons that aren't melee weapon.");
	}
	
	return Plugin_Handled;
}

public Action ColorWeapon(client, args)
{
	if(args != 1)
	{
	ReplyToCommand(client, "Wrong usage, Usage sm_colorweapon <none/red/green/blue> / sm_cw <none/red/green/blue");
	}
	if(client == 0)
	{
	ReplyToCommand(client, "Command In-game Only!");
	}
	
	new entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	if(StrEqual(arg, "none"))
	{
	SetEntityRenderColor(entity, 255, 255, 255, 255);
	}
	if(StrEqual(arg, "red"))
	{
	SetEntityRenderColor(entity, 255, 0, 0, 0);
	}
	if(StrEqual(arg, "green"))
	{
	SetEntityRenderColor(entity, 0, 255, 0 , 0);
	}
	if(StrEqual(arg, "blue"))
	{
	SetEntityRenderColor(entity, 0, 0, 255 ,0);
	}
}