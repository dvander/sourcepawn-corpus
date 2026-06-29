#include <sourcemod>
#include <tf2_stocks>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Basic Weapon Disabler",
	author = "Spumer",
	description = "You can't choose blocked weapon",
	version = "1.1",
	url = "http://forums.alliedmods.net/member.php?u=151387"
}

static Handle:g_hBWD = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	decl String:buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/bwd.cfg");
	g_hBWD = CreateKeyValues("g_hBWD");
	if(!FileToKeyValues(g_hBWD, buffer)) SetFailState("Can't load config: %s", buffer);
}

public OnPluginEnd()
{
	if(g_hBWD != INVALID_HANDLE) CloseHandle(g_hBWD);
}

new bool:bAlreadyBlock[MAXPLAYERS + 1];
public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(bAlreadyBlock[client]) return Plugin_Continue;
	
	decl String:buffer[32];
	IntToString(_:TF2_GetPlayerClass(client), buffer, sizeof(buffer));
	if(KvJumpToKey(g_hBWD, buffer) && KvGotoFirstSubKey(g_hBWD)) {
		do {
			KvGetSectionName(g_hBWD, buffer, sizeof(buffer));
			new weapon = GetPlayerWeaponSlot(client, StringToInt(buffer));
			if(IsValidEntity(weapon)){
				weapon = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				IntToString(weapon, buffer, sizeof(buffer));
				if(KvJumpToKey(g_hBWD, buffer))
				{
					bAlreadyBlock[client] = true;
					CreateTimer(5.0, Timer_Respawn, client);
					KvGetString(g_hBWD, "desc", buffer, sizeof(buffer));
					PrintToChat(client, "\x04You weapon is blocked: %s. Use default or other.", buffer); // EN
					break;
				}
			}
		} while(KvGotoNextKey(g_hBWD));
		KvRewind(g_hBWD);
	}
	return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:hTimer, any:client)
{
	if(IsClientInGame(client)) {
		new team = GetClientTeam(client);
		ChangeClientTeam(client, 1);
		ShowVGUIPanel(client, team == _:TFTeam_Blue ? "class_blue" : "class_red");
		ChangeClientTeam(client, team);
	}
	bAlreadyBlock[client] = false;
	return Plugin_Handled;
}
