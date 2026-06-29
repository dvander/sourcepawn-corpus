#include <sourcemod>
#include <tf2_stocks>
#pragma semicolon 1

#define RED_TAPE 810
#define RED_TAPE_2 831

public Plugin:myinfo =
{
	name = "Red-Tape Disabler",
	author = "Spumer",
	description = "Spies can't choose red-tape recorder",
	version = "1.1",
	url = "http://forums.alliedmods.net/member.php?u=151387"
}

public OnPluginStart()
{
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
}

new bool:bAlreadyBlock[MAXPLAYERS + 1];
public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(TF2_GetPlayerClass(client) == TFClass_Spy) {
		new weapon = GetPlayerWeaponSlot(client, 1);
		if(IsValidEntity(weapon)){
			new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponIndex == RED_TAPE || weaponIndex == RED_TAPE_2) {
				if(!bAlreadyBlock[client]) {
					bAlreadyBlock[client] = true;
					CreateTimer(5.0, Timer_Respawn, client);
					//PrintToChat(client, "\x04Ваше оружие заблокировано: Откатофон | Red-Tape Recorder. Выберите другое."); // RU
					PrintToChat(client, "\x04You weapon is blocked: Red-Tape Recorder. Use default or other."); // EN
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:hTimer, any:client)
{
	if(IsClientInGame(client)) {
		new team = GetClientTeam(client);
		ChangeClientTeam(client, 1);
		ShowVGUIPanel(client, team == 3 ? "class_blue" : "class_red");
		ChangeClientTeam(client, team);
	}
	bAlreadyBlock[client] = false;
	return Plugin_Handled;
}