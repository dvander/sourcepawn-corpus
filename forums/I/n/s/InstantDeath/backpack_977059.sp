/*
* Backpack  By: InstantDeath
*
* Allows a player to hold more than one primary weapon by storing one weapon in the "backpack"
*
* Currently this plugin is only available for CS:S. If there is enough demand for another mod, I will
* add support for it, if possible.
*
* Command to swap/insert weapon into backpack: swap_primary
*
*/
#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "2.11"

/*
* Author Notes:
* 1.0 initial release
*
* 2.0
*	fixed backpack not being able to switch back if player only carried 1 weapon.
* 
*/

new PlayerWeapon[MAXPLAYERS+1][2][3];
new bool: PlayerisSwapping[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "Backpack",
	author = "InstantDeath",
	description = "Allows the player to carry more than one primary weapon.",
	version = PLUGIN_VERSION,
	url = "http://www.xpgaming.net"
}

public OnPluginStart()
{
	CreateConVar("sm_backpack_version", PLUGIN_VERSION, "Backpack version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("swap_primary", Command_SwapPrimary);
	
	HookEvent("player_death", BeforePlayerDeath, EventHookMode_Pre);
	
}


public Action:Displayinfo(Handle:timer, any:index)
{
	if(IsClientInGame(index))
		PrintToChat(index, "[SM] Command to use backpack: swap_primary");
	return Plugin_Stop;
}

public OnClientPutInServer(client)
{
	for(new a = 0; a < 3; a++)
	{
		PlayerWeapon[client][0][a] = -1;
		PlayerWeapon[client][1][a] = -1;
	}
	CreateTimer(60.0,Displayinfo,client,TIMER_FLAG_NO_MAPCHANGE);
}

public Action:BeforePlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// get players entity ids
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponname[32];
	
	if(IsClientInGame(victim))
	{
		if(PlayerWeapon[victim][0][0] != -1)
		{
			GetWeaponByID(PlayerWeapon[victim][0][0], weaponname, sizeof(weaponname));
			GivePlayerItem(victim, weaponname);
			PlayerWeapon[victim][0][0] = -1;
			PlayerWeapon[victim][0][1] = -1;
			PlayerWeapon[victim][0][2] = -1;
			
			//PrintToConsole(client, "Weapon: %s", weaponname);
		}
		if(PlayerWeapon[victim][1][0] != -1)
		{
			GetWeaponByID(PlayerWeapon[victim][1][0], weaponname, sizeof(weaponname));
			GivePlayerItem(victim, weaponname);
			
			PlayerWeapon[victim][1][0] = -1;
			PlayerWeapon[victim][1][1] = -1;
			PlayerWeapon[victim][1][2] = -1;
		}
		PlayerisSwapping[victim] = false;
	}
	return Plugin_Continue;
}

//transfers weapon to and from backpack

public Action:TimedWeaponSwap(Handle: timer, any:client)
{

	new String:weaponname[32];
	new weaponid;
	//PrintToConsole(client, "[SM] Ran TimedWeaponSwap");
	weaponid = GetPlayerWeaponSlot(client, 0);
	if(PlayerWeapon[client][0][0] != -1)
	{
		//PrintToConsole(client, "[SM] backpack is not empty");
		GetWeaponByID(PlayerWeapon[client][0][0], weaponname, sizeof(weaponname));
		GivePlayerItem(client, weaponname);
		//PrintToConsole(client, "Weapon: %s", weaponname);
		weaponid = GetPlayerWeaponSlot(client, 0);
		SetPrimaryAmmo(client, weaponid, PlayerWeapon[client][0][1]);
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		SetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname), PlayerWeapon[client][0][2]);
		
		PlayerWeapon[client][0][0] = PlayerWeapon[client][1][0];
		PlayerWeapon[client][0][1] = PlayerWeapon[client][1][1];
		PlayerWeapon[client][0][2] = PlayerWeapon[client][1][2];
		PlayerWeapon[client][1][0] = -1;
		PlayerWeapon[client][1][1] = -1;
		PlayerWeapon[client][1][2] = -1;
		
		PlayerisSwapping[client] = false;
	}
	else if(PlayerWeapon[client][0][0] == -1)
	{
		if(PlayerWeapon[client][1][0] != -1)
		{
			PlayerWeapon[client][0][0] = PlayerWeapon[client][1][0];
			PlayerWeapon[client][0][1] = PlayerWeapon[client][1][1];
			PlayerWeapon[client][0][2] = PlayerWeapon[client][1][2];
			PlayerWeapon[client][1][0] = -1;
			PlayerWeapon[client][1][1] = -1;
			PlayerWeapon[client][1][2] = -1;
			//PrintToConsole(client, "[SM] backpack is not empty");
			GetWeaponByID(PlayerWeapon[client][0][0], weaponname, sizeof(weaponname));
			GivePlayerItem(client, weaponname);
			//PrintToConsole(client, "Weapon: %s", weaponname);
			weaponid = GetPlayerWeaponSlot(client, 0);
			SetPrimaryAmmo(client, weaponid, PlayerWeapon[client][0][1]);
			GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
			SetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname), PlayerWeapon[client][0][2]);
			PlayerWeapon[client][0][0] = -1;
			PlayerWeapon[client][0][1] = -1;
			PlayerWeapon[client][0][2] = -1;
		}
	}
			
	return Plugin_Stop;
}


public Action:Command_SwapPrimary(client, args)
{
	new weaponid, clip1, clip2;
	new String: weaponname[32];
	new colors[3];
	if(PlayerisSwapping[client])
		return Plugin_Handled;
	
	weaponid = GetPlayerWeaponSlot(client, 0);
	if(weaponid != -1)
	{
		colors[0] = 225;
		colors[1] = 10;
		colors[2] = 0;
		
		if(PlayerWeapon[client][0][0] != -1)
		{
			clip1 = GetPrimaryAmmo(client, weaponid);
			GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
			clip2 = GetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname));
			//PrintToConsole(client, "Got Primary Ammo: %d", clip1);
			//PrintToConsole(client, "Got Secondary Ammo: %d", clip2);
			
			
			//PrintToConsole(client, "Weapon: %s", weaponname);
			RemovePlayerItem(client, weaponid);
			weaponid = GetWeaponidByName(weaponname);
			PlayerWeapon[client][1][0] = weaponid;
			PlayerWeapon[client][1][1] = clip1;
			PlayerWeapon[client][1][2] = clip2;
			SendDialogToOne(client, colors, "Swapping primary weapons, please wait.");
			PlayerisSwapping[client] = true;
			CreateTimer(1.1,TimedWeaponSwap, client,TIMER_FLAG_NO_MAPCHANGE);
			weaponid = GetPlayerWeaponSlot(client, 1);
			if(weaponid != -1)
			{
				ClientCommand(client, "slot2");
			}
			else 
			{
				ClientCommand(client, "slot3");
			}
		}
		//PrintToConsole(client, "weapon Entity index: %d", weaponid);
		if(PlayerWeapon[client][0][0] == -1)
		{	
			if(PlayerWeapon[client][1][0] == -1)
			{
				clip1 = GetPrimaryAmmo(client, weaponid);
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				clip2 = GetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname));
				//PrintToConsole(client, "Got Primary Ammo: %d", clip1);
				//PrintToConsole(client, "Got Secondary Ammo: %d", clip2);
				
				
				//PrintToConsole(client, "Weapon: %s", weaponname);
				RemovePlayerItem(client, weaponid);
				weaponid = GetWeaponidByName(weaponname);
				PlayerWeapon[client][0][0] = weaponid;
				PlayerWeapon[client][0][1] = clip1;
				PlayerWeapon[client][0][2] = clip2;
				SendDialogToOne(client, colors, "Your primary weapon was placed in your backpack.");
				PlayerisSwapping[client] = false;
				
				weaponid = GetPlayerWeaponSlot(client, 1);
				if(weaponid != -1)
				{
					ClientCommand(client, "slot2");
				}
				else
				{
					ClientCommand(client, "slot3");
				}
			}	
		}
	}
	else if(PlayerWeapon[client][0][0] != -1)
	{
		PlayerisSwapping[client] = false;
		GetWeaponByID(PlayerWeapon[client][0][0], weaponname, sizeof(weaponname));
		GivePlayerItem(client, weaponname);
		//PrintToConsole(client, "Weapon: %s", weaponname);
		weaponid = GetPlayerWeaponSlot(client, 0);
		SetPrimaryAmmo(client, weaponid, PlayerWeapon[client][0][1]);
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		SetWeaponAmmo(client, GetWeaponAmmoOffset(weaponname), PlayerWeapon[client][0][2]);
		PlayerWeapon[client][0][0] = -1;
		PlayerWeapon[client][0][1] = -1;
		PlayerWeapon[client][0][2] = -1;
	}
	
	return Plugin_Handled;
}

public GetWeaponidByName(String:Weapon[])
{
	if(StrEqual(Weapon, "weapon_ak47", false))
	{
		return 0;
	}
	else if(StrEqual(Weapon, "weapon_aug", false))
	{
		return 1;
	}
	else if(StrEqual(Weapon, "weapon_awp", false))
	{
		return 2;
	}
	else if(StrEqual(Weapon, "weapon_deagle", false))
	{	
		return 3;
	}
	else if(StrEqual(Weapon, "weapon_elite", false))
	{
		return 4;
	}
	else if(StrEqual(Weapon, "weapon_famas", false))
	{
		return 5;
	}
	else if(StrEqual(Weapon, "weapon_fiveseven", false))
	{
		return 6;
	}
	else if(StrEqual(Weapon, "weapon_flashbang", false))
	{
		return 7;
	}
	else if(StrEqual(Weapon, "weapon_g3sg1", false))
	{
		return 8;
	}
	else if(StrEqual(Weapon, "weapon_galil", false))
	{
		return 9;
	}
	else if(StrEqual(Weapon, "weapon_glock", false))
	{
		return 10;
	}
	else if(StrEqual(Weapon, "weapon_hegrenade", false))
	{
		return 11;
	}
	else if(StrEqual(Weapon, "weapon_knife", false))
	{
		return 12;
	}
	else if(StrEqual(Weapon, "weapon_m249", false))
	{
		return 13;
	}
	else if(StrEqual(Weapon, "weapon_m3", false))
	{
		return 14;
	}
	else if(StrEqual(Weapon, "weapon_m4a1", false))
	{
		return 15;
	}
	else if(StrEqual(Weapon, "weapon_mac10", false))
	{
		return 16;
	}
	else if(StrEqual(Weapon, "weapon_mp5navy", false))
	{
		return 17;
	}
	else if(StrEqual(Weapon, "weapon_p228", false))
	{
		return 18;
	}
	else if(StrEqual(Weapon, "weapon_p90", false))
	{
		return 19;
	}
	else if(StrEqual(Weapon, "weapon_scout", false))
	{
		return 20;
	}
	else if(StrEqual(Weapon, "weapon_sg550", false))
	{
		return 21;
	}
	else if(StrEqual(Weapon, "weapon_sg552", false))
	{
		return 22;
	}
	else if(StrEqual(Weapon, "weapon_smokegrenade_projectile", false))
	{
		return 23;
	}
	else if(StrEqual(Weapon, "weapon_tmp", false))
	{
		return 24;
	}
	else if(StrEqual(Weapon, "weapon_ump45", false))
	{
		return 25;
	}
	else if(StrEqual(Weapon, "weapon_usp", false))
	{
		return 26;
	}
	else if(StrEqual(Weapon, "weapon_xm1014", false))
	{
		return 27;
	}
	else if(StrEqual(Weapon, "weapon_c4", false))
	{
		return 28;
	}
	else
		return -1;
}

public GetWeaponByID(weaponid, String:WeaponName[], maxlen)
{
	if(weaponid == 0)
	{
		strcopy(WeaponName, maxlen, "weapon_ak47");
	}
	else if(weaponid == 1)
	{
		strcopy(WeaponName, maxlen, "weapon_aug");
	}
	else if(weaponid == 2)
	{
		strcopy(WeaponName, maxlen, "weapon_awp");
	}
	else if(weaponid == 3)
	{
		strcopy(WeaponName, maxlen, "weapon_deagle");
	}
	else if(weaponid == 4)
	{
		strcopy(WeaponName, maxlen, "weapon_elite");
	}
	else if(weaponid == 5)
	{
		strcopy(WeaponName, maxlen, "weapon_famas");
	}
	else if(weaponid == 6)
	{
		strcopy(WeaponName, maxlen, "weapon_fiveseven");
	}
	
	else if(weaponid == 7)
	{
		strcopy(WeaponName, maxlen, "weapon_flashbang");
	}
	else if(weaponid == 8)
	{
		strcopy(WeaponName, maxlen, "weapon_g3sg1");
	}
	else if(weaponid == 9)
	{
		strcopy(WeaponName, maxlen, "weapon_galil");
	}
	else if(weaponid == 10)
	{
		strcopy(WeaponName, maxlen, "weapon_glock");
	}
	else if(weaponid == 11)
	{
		strcopy(WeaponName, maxlen, "weapon_hegrenade");
	}
	else if(weaponid == 12)
	{
		strcopy(WeaponName, maxlen, "weapon_knife");
	}
	else if(weaponid == 13)
	{
		strcopy(WeaponName, maxlen, "weapon_m249");
	}
	else if(weaponid == 14)
	{
		strcopy(WeaponName, maxlen, "weapon_m3");
	}
	else if(weaponid == 15)
	{
		strcopy(WeaponName, maxlen, "weapon_m4a1");
	}
	else if(weaponid == 16)
	{
		strcopy(WeaponName, maxlen, "weapon_mac10");
	}
	else if(weaponid == 17)
	{
		strcopy(WeaponName, maxlen, "weapon_mp5navy");
	}
	else if(weaponid == 18)
	{
		strcopy(WeaponName, maxlen, "weapon_p228");
	}
	else if(weaponid == 19)
	{
		strcopy(WeaponName, maxlen, "weapon_p90");
	}
	else if(weaponid == 20)
	{
		strcopy(WeaponName, maxlen, "weapon_scout");
	}
	else if(weaponid == 21)
	{
		strcopy(WeaponName, maxlen, "weapon_sg550");
	}
	else if(weaponid == 22)
	{
		strcopy(WeaponName, maxlen, "weapon_sg552");
	}
	else if(weaponid == 23)
	{
		strcopy(WeaponName, maxlen, "weapon_smokegrenade");
	}
	else if(weaponid == 24)
	{
		strcopy(WeaponName, maxlen, "weapon_tmp");
	}
	else if(weaponid == 25)
	{
		strcopy(WeaponName, maxlen, "weapon_ump45");
	}
	else if(weaponid == 26)
	{
		strcopy(WeaponName, maxlen, "weapon_usp");
	}
	else if(weaponid == 27)
	{
		strcopy(WeaponName, maxlen, "weapon_xm1014");
	}
	else if(weaponid == 28)
	{
		strcopy(WeaponName, maxlen, "weapon_c4");
	}
}

public GetWeaponAmmoOffset(String:Weapon[])
{
	if(StrEqual(Weapon, "weapon_deagle", false))
	{
		return 1;
	}
	else if(StrEqual(Weapon, "weapon_ak47", false) || StrEqual(Weapon, "weapon_aug", false) || StrEqual(Weapon, "weapon_g3sg1", false) || StrEqual(Weapon, "weapon_scout", false))
	{
		return 2;
	}
	else if(StrEqual(Weapon, "weapon_famas", false) || StrEqual(Weapon, "weapon_galil", false) || StrEqual(Weapon, "weapon_m4a1", false) || StrEqual(Weapon, "weapon_sg550", false) || StrEqual(Weapon, "weapon_sg552", false))
	{
		return 3;
	}
	else if(StrEqual(Weapon, "weapon_m249", false))
	{
		return 4;
	}
	else if(StrEqual(Weapon, "weapon_awp", false))
	{
		return 5;
	}
	else if(StrEqual(Weapon, "weapon_elite", false) || StrEqual(Weapon, "weapon_glock", false) || StrEqual(Weapon, "weapon_mp5navy", false) || StrEqual(Weapon, "weapon_tmp", false))
	{
		return 6;
	}
	else if(StrEqual(Weapon, "weapon_xm1014", false) || StrEqual(Weapon, "weapon_m3", false))
	{
		return 7;
	}
	else if(StrEqual(Weapon, "weapon_mac10", false) || StrEqual(Weapon, "weapon_ump45", false) || StrEqual(Weapon, "weapon_usp", false))
	{
		return 8;
	}
	else if(StrEqual(Weapon, "weapon_p228", false))
	{
		return 9;
	}
	else if(StrEqual(Weapon, "weapon_fiveseven", false) || StrEqual(Weapon, "weapon_p90", false))
	{
		return 10;
	}
	else if(StrEqual(Weapon, "weapon_hegrenade", false))
	{
		return 11;
	}
	else if(StrEqual(Weapon, "weapon_flashbang", false))
	{
		return 12;
	}
	else if(StrEqual(Weapon, "weapon_smokegrenade", false))
	{
		return 13;
	}
	return -1;
}

SendDialogToOne(client, color[3], String:text[], any:...)
{
	new String:message[100];
	VFormat(message, sizeof(message), text, 4);	
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", color[0], color[1], color[2], 255);
	KvSetNum(kv, "level", 2);
	KvSetNum(kv, "time", 2);
	
	CreateDialog(client, kv, DialogType_Msg);
	
	CloseHandle(kv);	
}

stock GetWeaponAmmo(client, slot)
{
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	return GetEntData(client, ammoOffset+(slot*4));
}  

stock SetWeaponAmmo(client, slot, ammo)
{
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	return SetEntData(client, ammoOffset+(slot*4), ammo);
}

stock GetPrimaryAmmo(client, weap) 
{   
	//new myweapons = FindSendPropInfo("CCSPlayer", "m_hMyWeapons");  
	//new weap = GetEntDataEnt2(client, myweapons+ (slot*4));
	if(IsValidEntity(weap))
		return GetEntData(weap, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")); 
	return 0;
}

stock SetPrimaryAmmo(client, weap, ammo) 
{     
	//new myweapons = FindSendPropInfo("CCSPlayer", "m_hMyWeapons");  
	//new weap = GetEntDataEnt2(client, myweapons+ (slot*4)); 
	if(IsValidEntity(weap))
		return SetEntData(weap, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), ammo);
	return 0;
}