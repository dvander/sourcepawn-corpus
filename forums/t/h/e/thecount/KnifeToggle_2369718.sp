#include <sourcemod>
#include <sdktools>
#include <cstrike>

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
		CS_DropWeapon(client, wep, false);
		CreateTimer(0.1, Post_Drop, wep);
	}
	return Plugin_Handled;
}

public Action:Post_Drop(Handle:timer, any:wep){
	AcceptEntityInput(wep, "Kill");
	return Plugin_Handled;
}