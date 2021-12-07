#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo = {
	name = "CheckPoint",
	author = "The Count",
	description = "Players can save a checkpoint to return to.",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new Float:info[MAXPLAYERS + 1][3];

public OnPluginStart(){
	RegConsoleCmd("sm_tele", Cmd_Tele, "Save a checkpoint.");
	HookEvent("player_death", Evt_Death);
}

public Evt_Death(Handle:event, const String:name[], bool:dontB){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(info[client][0] == 0.0){ return; }
	CS_RespawnPlayer(client);
	TeleportEntity(client, info[client], NULL_VECTOR, NULL_VECTOR);
}

public Action:Cmd_Tele(client, args){
	new Handle:menu = CreateMenu(TMenu);
	SetMenuTitle(menu, "Tele");
	AddMenuItem(menu, "save", "Save Location");
	AddMenuItem(menu, "teleport", "Teleport");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 48);
	return Plugin_Handled;
}

public TMenu(Handle:menu, MenuAction:action, client, choice){
	if(action == MenuAction_Select){
		new String:inform[22];
		GetMenuItem(menu, choice, inform, sizeof(inform));
		if(StrEqual(inform, "save", false)){
			if(IsPlayerAlive(client)){
				GetClientAbsOrigin(client, info[client]);
				PrintToChat(client, "\x01[SM]\x04 Location saved.");
			}else{
				PrintToChat(client, "[SM] You must be alive to do that.");
			}
		}
		if(StrEqual(inform, "teleport", false) && info[client][0] != 0.0){
			if(IsPlayerAlive(client)){
				TeleportEntity(client, info[client], NULL_VECTOR, NULL_VECTOR);
			}else{
				PrintToChat(client, "[SM] You must be alive to do that.");
			}
		}
	}
	CloseHandle(menu);
}

public OnClientPutInServer(client){
	info[client][0] = 0.0;info[client][1] = 0.0;info[client][2] = 0.0;
}