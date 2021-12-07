#include <sourcemod>
#include <tf2_stocks>
#pragma semicolon 1

// pack two 16-bit digits to one 32-bit. Max value of each argument is 65535
#define PACK_16(%1,%2)	( ((%1)<<16) | (%2) )
// unpack left-side bits
#define UNPACK_16_FIRST(%3) ( (%3)>>16 )
// unpack right-side bits
#define UNPACK_16_SECOND(%3) ( (%3) & 0xFFFF )

public Plugin:myinfo =
{
	name = "Basic Weapon Disabler",
	author = "Spumer",
	description = "You can't choose blocked weapon",
	version = "1.2",
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
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if( !client || bAlreadyBlock[client] ) return Plugin_Continue;
	
	KvRewind(g_hBWD);
	
	decl String:buffer[32], index;
	IntToString(_:TF2_GetPlayerClass(client), buffer, sizeof(buffer));
	if(KvJumpToKey(g_hBWD, buffer)) {
		// check weapon list
		if(KvJumpToKey(g_hBWD, "weapon"))
		if(KvGotoFirstSubKey(g_hBWD)) {
			do {
				KvGetSectionName(g_hBWD, buffer, sizeof(buffer));
				index = GetPlayerWeaponSlot(client, StringToInt(buffer));
				if(IsValidEntity(index)){
					index = GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex");
					IntToString(index, buffer, sizeof(buffer));
					if(KvJumpToKey(g_hBWD, buffer))
					{
						SpawnBlock(PACK_16(userid, client)); 
						return Plugin_Continue;
					}
				}
			} while(KvGotoNextKey(g_hBWD));
			KvGoBack(g_hBWD);
		}
		// check wearable list
		if(KvJumpToKey(g_hBWD, "wearable"))
		if(KvGotoFirstSubKey(g_hBWD)) {
			new wearable= -1;
			while ((wearable = FindEntityByClassname(wearable, "tf_wearable")) != -1) {
				if(GetEntSendPropOffs(wearable, "m_hOwnerEntity") > -1) { // Has entity that property?
					index = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
					if(index == client) {
						index = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
						IntToString(index, buffer, sizeof(buffer));
						if(KvJumpToKey(g_hBWD, buffer))
						{
							SpawnBlock(PACK_16(userid, client)); 
							break;
						}
					} // if == client
				} // if has property
			} // while
		}
	}
	return Plugin_Continue;
}

stock SpawnBlock(data) {
	new client = UNPACK_16_SECOND(data);
	decl String:sWeaponName[32];
	
	bAlreadyBlock[client] = true;
	CreateTimer(5.0, Timer_Respawn, data);
	
	KvGetString(g_hBWD, "desc", sWeaponName, sizeof(sWeaponName));
	PrintToChat(client, "\x04You weapon is blocked: %s. Use default or other.", sWeaponName);
}

public Action:Timer_Respawn(Handle:hTimer, any:data)
{
	new userid = UNPACK_16_FIRST(data);
	new client = UNPACK_16_SECOND(data);

	if(GetClientOfUserId(userid) > 0) {
		new team = GetClientTeam(client);
		ChangeClientTeam(client, 1);
		ShowVGUIPanel(client, team == _:TFTeam_Blue ? "class_blue" : "class_red");
		ChangeClientTeam(client, team);
	}
	bAlreadyBlock[client] = false;
	return Plugin_Handled;
}
