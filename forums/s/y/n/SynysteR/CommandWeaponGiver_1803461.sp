#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new weaponIndex;

#define MAX_WEAPONS	25	

public Plugin:myinfo =
{
	name = "Weapon Give By command",
	author = "SynysteR",
	description = "type in chat for example: !awp and you will get an awp, works for all weapons",
	version = PLUGIN_VERSION
}

new const String:weaponList[MAX_WEAPONS][]={
	"\x04[SM]\x03 The weapon commands are:", "sm_awp", "sm_m4a1", "sm_ak47", "sm_aug", "sm_famas", "sm_g3sg1", "sm_galil", "sm_m249", "sm_m3", "sm_xm1014", "sm_mac10", "sm_mp5", "sm_p90", "sm_scout", "sm_sg550", "sm_sg552", "sm_tmp", "sm_ump45", "sm_deagle", "sm_usp", "sm_elite", "sm_fiveseven", "sm_glock", "sm_p228"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_awp", Command_Awp,"Gives player an awp.");
	RegConsoleCmd("sm_m4a1", Command_M4A1, "Gives player an m4a1.");
	RegConsoleCmd("sm_ak47", Command_Ak47,"Gives player an ak47");
	RegConsoleCmd("sm_deagle", Command_Deagle,"Gives player a deagle.");
	RegConsoleCmd("sm_aug", Command_Aug, "Gives player an aug.");
	RegConsoleCmd("sm_elite", Command_Elite, "Gives player an elite pistols.");
	RegConsoleCmd("sm_famas", Command_Famas, "Gives player a famas.");
	RegConsoleCmd("sm_fiveseven", Command_FiveSeven, "Gives player a fiveseven pistol.");
	RegConsoleCmd("sm_g3sg1", Command_G3sg1, "Gives player a g3sg1 (auto-sniper).");
	RegConsoleCmd("sm_galil", Command_Galil, "Gives player a galil.");
	RegConsoleCmd("sm_glock", Command_Glock, "Gives player a glock.");
	RegConsoleCmd("sm_m249", Command_M249, "Gives player a m249.");
	RegConsoleCmd("sm_m3", Command_M3, "Gives player a m3.");
	RegConsoleCmd("sm_mac10", Command_Mac10, "Gives player a mac10.");
	RegConsoleCmd("sm_mp5", Command_Mp5, "Gives player a mp5navy.");
	RegConsoleCmd("sm_p228", Command_P228, "Gives player a p228.");
	RegConsoleCmd("sm_p90", Command_P90, "Gives player a p90.");
	RegConsoleCmd("sm_scout", Command_Scout, "Gives player a scout.");
	RegConsoleCmd("sm_sg550", Command_Sg550, "Gives player a sg550.");
	RegConsoleCmd("sm_sg552", Command_Sg552, "Gives player a sg552.");
	RegConsoleCmd("sm_tmp", Command_Tmp, "Gives player a tmp.");
	RegConsoleCmd("sm_ump45", Command_Ump45, "Gives player an ump45.");
	RegConsoleCmd("sm_usp", Command_Usp, "Gives player a usp.");
	RegConsoleCmd("sm_xm1014", Command_Xm1014, "Gives player an xm1014.");
	RegConsoleCmd("sm_weaponlist", Command_weaponList);
}
enum WeaponsSlot
{
	Slot_Invalid = -1, /** Invalid weapon (slot). */
	Slot_Primary = 0, /** Primary weapon slot. */
	Slot_Secondary = 1, /** Secondary weapon slot. */
	Slot_Melee = 2, /** Melee (knife) weapon slot. */
	Slot_Projectile = 3, /** Projectile (grenades, flashbangs, etc) weapon slot. */
	Slot_Explosive = 4, /** Explosive (c4) weapon slot. */
}

public Action:Command_Awp(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_awp");
		PrintToChat(client, "\x04[SM] \x03You gained Awp.");
	}
	return Plugin_Handled;
}
public Action:Command_M4A1(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_m4a1");
		PrintToChat(client, "\x04[SM]\x03 You gained M4a1.");
	}
	return Plugin_Handled;
}
public Action:Command_Ak47(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_ak47");
		PrintToChat(client,"\x04[SM]\x03 You gained Ak47.");
	}
	return Plugin_Handled;
}
public Action:Command_Deagle(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{		
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_deagle");
		PrintToChat(client,"\x04[SM]\x03 You gained Deagle.");
	}
	return Plugin_Handled;
}
public Action:Command_Aug(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_aug");
		PrintToChat(client,"\x04[SM]\x03 You gained Aug.");
	}
	return Plugin_Handled;
}
public Action:Command_Elite(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_elite");
		PrintToChat(client,"\x04[SM]\x03 You gained Elite Pistols.");
	}
	return Plugin_Handled;
}
public Action:Command_Famas(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_famas");
		PrintToChat(client,"\x04[SM]\x03 You gained Famas.");
	}
	return Plugin_Handled;
}
public Action:Command_FiveSeven(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_fiveseven");
		PrintToChat(client,"\x04[SM]\x03 You gained FIve-Seven.");
	}
	return Plugin_Handled;
}
public Action:Command_G3sg1(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_g3sg1");
		PrintToChat(client,"\x04[SM]\x03 You gained g3sg1.");
	}
	return Plugin_Handled;
}
public Action:Command_Galil(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_galil");
		PrintToChat(client,"\x04[SM]\x03 You gained Galil.");
	}
	return Plugin_Handled;
}
public Action:Command_Glock(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_glock");
		PrintToChat(client,"\x04[SM]\x03 You gained Glock.");
	}
	return Plugin_Handled;
}
public Action:Command_M249(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_m249");
		PrintToChat(client,"\x04[SM]\x03 You gained M249.");
	}
	return Plugin_Handled;
}
public Action:Command_M3(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_m3");
		PrintToChat(client,"\x04[SM]\x03 You gained M3.");
	}
	return Plugin_Handled;
}
public Action:Command_Mac10(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_mac10");
		PrintToChat(client,"\x04[SM]\x03 You gained Mac10.");
	}
	return Plugin_Handled;
}
public Action:Command_Mp5(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_mp5navy");
		PrintToChat(client,"\x04[SM]\x03 You gained Mp5.");
	}
	return Plugin_Handled;
}
public Action:Command_P228(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_p228");
		PrintToChat(client,"\x04[SM]\x03 You gained P228.");
	}
	return Plugin_Handled;
}
public Action:Command_P90(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_p90");
		PrintToChat(client,"\x04[SM]\x03 You gained P90.");
	}
	return Plugin_Handled;
}
public Action:Command_Scout(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_scout");
		PrintToChat(client,"\x04[SM]\x03 You gained Scout.");
	}
	return Plugin_Handled;
}
public Action:Command_Sg550(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_sg550");
		PrintToChat(client,"\x04[SM]\x03 You gained sg550.");
	}
	return Plugin_Handled;
}
public Action:Command_Sg552(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_sg552");
		PrintToChat(client,"\x04[SM]\x03 You gained sg552.");
	}
	return Plugin_Handled;
}
public Action:Command_Tmp(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_tmp");
		PrintToChat(client,"\x04[SM]\x03 You gained tmp.");
	}
	return Plugin_Handled;
}
public Action:Command_Ump45(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_ump45");
		PrintToChat(client,"\x04[SM]\x03 You gained Ump45.");
	}
	return Plugin_Handled;
}
public Action:Command_Usp(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 1)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_usp");
		PrintToChat(client,"\x04[SM]\x03 You gained Usp.");
	}
	return Plugin_Handled;
}
public Action:Command_Xm1014(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[SM] \x03 You can't use this command while you are dead.");
	else
	{	
		if ((weaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			RemovePlayerItem(client, weaponIndex);
			
		GivePlayerItem(client, "weapon_xm1014");
		PrintToChat(client,"\x04[SM]\x03 You gained Xm1014.");
	}
	return Plugin_Handled;
}
public Action:Command_weaponList(client, args)
{
	new i;
	for(i = 0; i < MAX_WEAPONS; ++i)
		ReplyToCommand(client, "%s", weaponList[i]);
	return Plugin_Handled;
}