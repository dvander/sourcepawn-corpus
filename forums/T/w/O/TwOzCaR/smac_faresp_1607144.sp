#pragma semicolon 1
/* SM Includes */
#include <sourcemod>
/* Plugin Info */
public Plugin:myinfo =
{
name = "SMAC Anti-farESP Block",
author = "GoD-Tony(coding), tw0z(compiling,idea)",
description = "Blocks farESP/Wallhacks cheats from working properly",
};
public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("UpdateRadar"), Hook_UpdateRadar, true);
}

public Action:Hook_UpdateRadar(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	return Plugin_Handled;
}
