/*
 * SourceMod Script created and edited by SkinnyBruv
 * by:SkinnyBruv @ www.arcticgaming.net also @https://forums.alliedmods.net/member.php?u=223320
 *
 * This file was a part of [AGN] Arctic Gaming Network. But is now public and apart of alliedmods.net and sourcemod.net.
 *
 * This program is now free software; you cannot redistribute it but you may modify it and edit it.
 * Version 1.0, as published by
 * SkinnyBruv
 * 
 * See SkinnyBruv for the PGL Public General License for more information on redistributing.
 * details.
 * SkinnyBruv@arcticgaming.net
 * 
 * SkinnyBruv@Allied mods - https://forums.alliedmods.net/member.php?u=223320
 *
 * CREDITS:
 * 	- r3dw3r3w0lf - https://forums.alliedmods.net/member.php?u=59694 - For ConVar
 * 
 * KNOWN BUGS:
 * 	- None Currently
 * 
 * CHANGELOG:
 * 	
 * 	1.1
 * 		- Modified and put in command [SM] after the toggle of friendlyfire has been initiated.
 *		- Added ConVar, and log commands.
 *
 * 	1.0
 * 		- Initial release.
 */
#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_AUTHOR "SkinnyBruv"
#define PLUGIN_NAME "Turn on/off FriendlyFire"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2054051"
#define PLUGIN_DESCRIPTION "Simple plugin that allows you to type /sm_ff to turn on/off friendly fires. Comes with adminmenu_custom.txt for menu"

new Handle:ConVar = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
		RegAdminCmd("sm_ff", Command_FF, ADMFLAG_SLAY);
		ConVar = FindConVar("mp_friendlyfire");
}

public Action:Command_FF(client, args)
{
	if (!GetConVarBool(ConVar))
    {
        SetConVarBool(ConVar, true);
        CPrintToChat(client, "{lawngreen}[SM]{teamcolor} FriendlyFire is now on");
        PrintToServer("[SM] FriendlyFire has been enabled by %N", client);
        LogMessage("FriendlyFire has been enabled by %s", client);
    }
    else
    {
        SetConVarBool(ConVar, false);
        CPrintToChat(client, "{lawngreen}[SM]{teamcolor} FriendlyFire is now off");
        PrintToServer("[SM] FriendlyFire has been disabled by %s", client);
        LogMessage("FriendlyFire has been disabled by %s", client);
    }
    return Plugin_Handled;
}