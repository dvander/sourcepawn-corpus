#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Knife Toggle",
	author = "The Count",
	description = "",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public OnPluginStart(){ RegConsoleCmd("sm_knife", Cmd_Knife, "Toggle knife"); }

public Action:Cmd_Knife(client, args){
	if(!IsPlayerAlive(client)){ return Plugin_Handled; }
	new wep = GetPlayerWeaponSlot(client, 2);
	if(wep == -1){
		GivePlayerItem(client, "weapon_knife");
	}else{
		AcceptEntityInput(wep, "Kill");
	}
	return Plugin_Handled;
}