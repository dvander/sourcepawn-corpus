// simple weapon giver 1.0 by charisma
#pragma semicolon 1
#define VERSION "1.0"

new Handle:gH_RemoveDrops = INVALID_HANDLE;
new bool:RemoveDrops = false;

#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo = {
	name = "Weapon Spawner",
	author = "charisma",
	description = "Allows you to spawn various weapons",
	version = VERSION
};
public OnPluginStart() {
	RegConsoleCmd("sm_usp", 		Command_GetUSP);
	RegConsoleCmd("sm_glock", 		Command_GetGlock);
	RegConsoleCmd("sm_knife", 		Command_GetKnife);
	RegConsoleCmd("sm_scout", 		Command_GetScout);
	RegConsoleCmd("sm_awp", 		Command_GetAWP);
	RegConsoleCmd("sm_ak47", 		Command_GetAK47);
	RegConsoleCmd("sm_m4a1", 		Command_GetM4A1);
	RegConsoleCmd("sm_aug", 		Command_GetAUG);
	RegConsoleCmd("sm_sg550", 		Command_GetSG550);
	RegConsoleCmd("sm_sg552", 		Command_GetSG552);
	RegConsoleCmd("sm_tmp", 		Command_GetTMP);
	RegConsoleCmd("sm_mp5", 		Command_GetMP5);
	RegConsoleCmd("sm_p90", 		Command_GetP90);
	RegConsoleCmd("sm_mac10", 		Command_GetMAC10);
	RegConsoleCmd("sm_m3", 			Command_GetM3);
	RegConsoleCmd("sm_m249", 		Command_GetM249);
	RegConsoleCmd("sm_ump", 		Command_GetUMP);
	RegConsoleCmd("sm_galil", 		Command_GetGalil);
	RegConsoleCmd("sm_famas", 		Command_GetFamas);
	RegConsoleCmd("sm_g3sg1", 		Command_GetG3SG1);
	RegConsoleCmd("sm_xm1014",	 	Command_GetXM1014);
	RegConsoleCmd("sm_p228", 		Command_GetP228);
	RegConsoleCmd("sm_fiveseven", 	Command_Get57);
	RegConsoleCmd("sm_elite", 		Command_GetElite);
	RegConsoleCmd("sm_deagle", 		Command_GetDeagle);
	CreateConVar("sm_spawner_version",VERSION,"Weapon Spawner",FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	gH_RemoveDrops = CreateConVar("sm_spawner_removedrops","1","Remove weapons when they are dropped to prevent lag", FCVAR_PLUGIN|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sm_spawner");
	
	RemoveDrops = GetConVarBool(gH_RemoveDrops);
	
	HookConVarChange(gH_RemoveDrops, DropsChanged);
}
public DropsChanged(Handle:cvar, const String:oldVal[], const  String:newVal[]) {
	RemoveDrops = GetConVarBool(cvar);
}
public Action:CS_OnCSWeaponDrop(client, weaponIndex) {
	if(RemoveDrops) {
		CS_DropWeapon(client, weaponIndex, true, true);
		AcceptEntityInput(weaponIndex, "Kill");
	}
	return Plugin_Continue;
}
public Action:Command_GetUSP(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_usp");
		GivePlayerItem(client, "weapon_usp");
	}
	return Plugin_Handled;
}
public Action:Command_GetGlock(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_glock");
		GivePlayerItem(client, "weapon_glock");
	}
	return Plugin_Handled;
}
public Action:Command_GetKnife(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, 2) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_knife");
		GivePlayerItem(client, "weapon_knife");
	}
	return Plugin_Handled;
}
public Action:Command_GetScout(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_scout");
		GivePlayerItem(client, "weapon_scout");
	}
	return Plugin_Handled;
}
public Action:Command_GetAWP(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_awp");
		GivePlayerItem(client, "weapon_awp");
	}
	return Plugin_Handled;
}
public Action:Command_GetAK47(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_ak47");
		GivePlayerItem(client, "weapon_ak47");
	}
	return Plugin_Handled;
}
public Action:Command_GetM4A1(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_m4a1");
		GivePlayerItem(client, "weapon_m4a1");
	}
	return Plugin_Handled;
}
public Action:Command_GetAUG(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_aug");
		GivePlayerItem(client, "weapon_aug");
	}
	return Plugin_Handled;
}
public Action:Command_GetSG550(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "sg550");
		GivePlayerItem(client, "weapon_sg550");
	}
	return Plugin_Handled;
}
public Action:Command_GetSG552(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_sg552");
		GivePlayerItem(client, "weapon_sg552");
	}
	return Plugin_Handled;
}
public Action:Command_GetTMP(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_tmp");
		GivePlayerItem(client, "weapon_tmp");
	}
	return Plugin_Handled;
}
public Action:Command_GetMP5(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_mp5");
		GivePlayerItem(client, "weapon_mp5");
	}
	return Plugin_Handled;
}
public Action:Command_GetP90(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_p90");
		GivePlayerItem(client, "weapon_p90");
	}
	return Plugin_Handled;
}
public Action:Command_GetMAC10(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_mac10");
		GivePlayerItem(client, "weapon_mac10");
	}
	return Plugin_Handled;
}
public Action:Command_GetM3(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_m3");
		GivePlayerItem(client, "weapon_m3");
	}
	return Plugin_Handled;
}
public Action:Command_GetM249(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_m249");
		GivePlayerItem(client, "weapon_m249");
	}
	return Plugin_Handled;
}
public Action:Command_GetUMP(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_ump45");
		GivePlayerItem(client, "weapon_ump45");
	}
	return Plugin_Handled;
}
public Action:Command_GetGalil(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_galil");
		GivePlayerItem(client, "weapon_galil");
	}
	return Plugin_Handled;
}
public Action:Command_GetFamas(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_famas");
		GivePlayerItem(client, "weapon_famas");
	}
	return Plugin_Handled;
}
public Action:Command_GetG3SG1(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_g3sg1");
		GivePlayerItem(client, "weapon_g3sg1");
	}
	return Plugin_Handled;
}
public Action:Command_GetXM1014(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_xm1014");
		GivePlayerItem(client, "weapon_xm1014");
	}
	return Plugin_Handled;
}
public Action:Command_GetP228(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_p228");
		GivePlayerItem(client, "weapon_p228");
	}
	return Plugin_Handled;
}
public Action:Command_Get57(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_fiveseven");
		GivePlayerItem(client, "weapon_fiveseven");
	}
	return Plugin_Handled;
}
public Action:Command_GetElite(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_elite");
		GivePlayerItem(client, "weapon_elite");
	}
	return Plugin_Handled;
}
public Action:Command_GetDeagle(client, args) {
	if(IsPlayerAlive(client)){
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1){
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
		}
		PrintToChat(client, "[SM] You have received a %s.", "weapon_deagle");
		GivePlayerItem(client, "weapon_deagle");
	}
	return Plugin_Handled;
}