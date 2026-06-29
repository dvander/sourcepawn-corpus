/*ggggggggggg,                                             ,ggg,      gg      ,gg                                                                ,ggggggggggg,                                                               
dP"""88""""""Y8,                                          dP""Y8a     88     ,8P                                                                dP"""88""""""Y8, ,dPYb,                        ,dPYb,                        
Yb,  88      `8b                                          Yb, `88     88     d8'                                                                Yb,  88      `8b IP'`Yb                        IP'`Yb                        
 `"  88      ,8P                        gg                 `"  88     88     88                                                                  `"  88      ,8P I8  8I                        I8  8I                        
     88aaaad8P"                         ""                     88     88     88                                                                      88aaaad8P"  I8  8'                        I8  8bgg,                     
     88""""Y8ba    ,gggg,gg    ,g,      gg     ,gggg,          88     88     88   ,ggg,     ,gggg,gg  gg,gggg,      ,ggggg,     ,ggg,,ggg,           88""""Y8ba  I8 dP    ,ggggg,      ,gggg,  I8 dP" "8   ,ggg,    ,gggggg, 
     88      `8b  dP"  "Y8I   ,8'8,     88    dP"  "Yb         88     88     88  i8" "8i   dP"  "Y8I  I8P"  "Yb    dP"  "Y8ggg ,8" "8P" "8,          88      `8b I8dP    dP"  "Y8ggg  dP"  "Yb I8d8bggP"  i8" "8i   dP""""8I 
     88      ,8P i8'    ,8I  ,8'  Yb    88   i8'               Y8    ,88,    8P  I8, ,8I  i8'    ,8I  I8'    ,8i  i8'    ,8I   I8   8I   8I          88      ,8P I8P    i8'    ,8I   i8'       I8P' "Yb,  I8, ,8I  ,8'    8I 
     88_____,d8',d8,   ,d8b,,8'_   8) _,88,_,d8,_    _          Yb,,d8""8b,,dP   `YbadP' ,d8,   ,d8b,,I8 _  ,d8' ,d8,   ,d8'  ,dP   8I   Yb,         88_____,d8',d8b,_ ,d8,   ,d8'  ,d8,_    _,d8    `Yb, `YbadP' ,dP     Y8,
    88888888P"  P"Y8888P"`Y8P' "YY8P8P8P""Y8P""Y8888PP           "88"    "88"   888P"Y888P"Y8888P"`Y8PI8 YY88888PP"Y8888P"    8P'   8I   `Y8        88888888P"  8P'"Y88P"Y8888P"    P""Y8888PP88P      Y8888P"Y8888P      `Y8
                                                                                                      I8                                                                                                                     
                                                                                                      I8                                                                                                                     
                                                                                                      I8                                                                                                                     
                                                                                                      I8                                                                                                                     
                                                                                                      I8                                                                                                                     
                                                                                                      I8                                                                                                                     
*/

#include <sourcemod> 
#include <sdktools> 
#include <tf2> 
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_VERSION 			"1.0.1"

new Handle:hWeaponBlocked = INVALID_HANDLE;
new bool:g_bIsDeathrun = false;
new bool:g_bIsJailbreak = false;
new bool:g_bPluginEnabled = true;

public Plugin:myinfo =
{
	name = "[TF2] Basic Weapon Blocker",
	author = "Astrak",
	description = "Block certain weapons in Team Fortress 2.",
	version = PLUGIN_VERSION,
	url = "cmmgaming.com"
};


/*_    _             _                   _____  _             _          _____      _               
 | |  | |           | |          ___    |  __ \| |           (_)        / ____|    | |              
 | |__| | ___   ___ | | _____   ( _ )   | |__) | |_   _  __ _ _ _ __   | (___   ___| |_ _   _ _ __  
 |  __  |/ _ \ / _ \| |/ / __|  / _ \/\ |  ___/| | | | |/ _` | | '_ \   \___ \ / _ \ __| | | | '_ \ 
 | |  | | (_) | (_) |   <\__ \ | (_>  < | |    | | |_| | (_| | | | | |  ____) |  __/ |_| |_| | |_) |
 |_|  |_|\___/ \___/|_|\_\___/  \___/\/ |_|    |_|\__,_|\__, |_|_| |_| |_____/ \___|\__|\__,_| .__/ 
                                                         __/ |                               | |    
                                                        |___/                                |_|    
*/


public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerReady);
	HookEvent("post_inventory_application", Event_PlayerReady);
	HookEvent("teamplay_round_start", Event_PlayerReady);

	CreateConVar("sm_weaponblock_version", PLUGIN_VERSION, "Version of the Basic Weapon Block plugin. Do not touch this.", FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public OnMapStart()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
  
	if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "vsh_dr", 6, false) == 0))
	{
		g_bIsDeathrun = true;
		g_bIsJailbreak = false;
	}
	else if (strncmp(mapname, "ba_", 3, false) == 0 || (strncmp(mapname, "jail_", 5, false) == 0))
	{
		g_bIsDeathrun = false;
		g_bIsJailbreak = true;
	}
	else
	{
		g_bPluginEnabled = false;
	}
}

/*_    _             _            _   ______               _       
 | |  | |           | |          | | |  ____|             | |      
 | |__| | ___   ___ | | _____  __| | | |____   _____ _ __ | |_ ___ 
 |  __  |/ _ \ / _ \| |/ / _ \/ _` | |  __\ \ / / _ \ '_ \| __/ __|
 | |  | | (_) | (_) |   <  __/ (_| | | |___\ V /  __/ | | | |_\__ \
 |_|  |_|\___/ \___/|_|\_\___|\__,_| |______\_/ \___|_| |_|\__|___/
*/


public Action:Event_PlayerReady(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bPluginEnabled == true)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(IsValidClient(client))
		{
			if(g_bIsDeathrun == true)
			{
				if(TF2_GetPlayerClass(client) == TFClass_Scout)
				{
					BlockWeapons(client, 45, 13, "tf_weapon_scattergun");
					BlockWeapons(client, 448, 13, "tf_weapon_scattergun");
					BlockWeapons(client, 1078, 13, "tf_weapon_scattergun");
					
					BlockWeapons(client, 46, 23, "tf_weapon_pistol_scout");
					BlockWeapons(client, 449, 23, "tf_weapon_pistol_scout");
					
					BlockWeapons(client, 325, 23, "tf_weapon_bat");
					BlockWeapons(client, 450, 23, "tf_weapon_bat");
					BlockWeapons(client, 452, 23, "tf_weapon_bat");
					
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Soldier)
				{
					TF2_RemoveWeaponSlot(client, 0);
					
					BlockWeapons(client, 1101, 10, "tf_weapon_shotgun_soldier");

					BlockWeapons(client, 447, 6, "tf_weapon_shovel");
					BlockWeapons(client, 128, 6, "tf_weapon_shovel");
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Pyro)
				{
					BlockWeapons(client, 351, 12, "tf_weapon_shotgun_pyro");
					BlockWeapons(client, 740, 12, "tf_weapon_shotgun_pyro");

					BlockWeapons(client, 214, 2, "tf_weapon_fireaxe");
				}
				else if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
				{
					TF2_RemoveWeaponSlot(client, 0);
					
					TF2_RemoveWeaponSlot(client, 1);

					BlockWeapons(client, 307, 1, "tf_weapon_stickbomb");
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Heavy)
				{	
					BlockWeapons(client, 311, 11, "tf_weapon_lunchbox");

					BlockWeapons(client, 239, 5, "tf_weapon_fists");
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Engineer)
				{	
					BlockWeapons(client, 589, 7, "tf_weapon_wrench");
					
					TF2_RemoveWeaponSlot(client, 3);
					
					TF2_RemoveWeaponSlot(client, 4);
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Medic)
				{	
					BlockWeapons(client, 412, 17, "tf_weapon_syringegun_medic");
				}
/*				if(TF2_GetPlayerClass(client) == TFClass_Sniper)
				{	

				}
*/
				else if(TF2_GetPlayerClass(client) == TFClass_Spy)
				{
					BlockWeapons(client, 225, 4, "tf_weapon_knife");
					BlockWeapons(client, 574, 4, "tf_weapon_knife");
					
					TF2_RemoveWeaponSlot(client, 3);
					
					TF2_RemoveWeaponSlot(client, 4);
				}
			}
			else if(g_bIsJailbreak == true)
			{
				if(TF2_GetPlayerClass(client) == TFClass_Scout)
				{
					BlockWeapons(client, 449, 23, "tf_weapon_pistol_scout");
					BlockWeapons(client, 46, 23, "tf_weapon_pistol_scout");
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Soldier)
				{
					BlockWeapons(client, 1101, 10, "tf_weapon_shotgun_soldier");
				}
/*				else if(TF2_GetPlayerClass(client) == TFClass_Pyro)
				{

				}
*/
				else if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
				{
					BlockWeapons(client, 307, 1, "tf_weapon_stickbomb");
				}
/*				else if(TF2_GetPlayerClass(client) == TFClass_Heavy)
				{	

				}
*/
				else if(TF2_GetPlayerClass(client) == TFClass_Engineer)
				{	
					BlockWeapons(client, 589, 7, "tf_weapon_wrench");
					
					TF2_RemoveWeaponSlot(client, 3);
					
					TF2_RemoveWeaponSlot(client, 4);
				}
/*				else if(TF2_GetPlayerClass(client) == TFClass_Medic)
				{	

				}
*/
				if(TF2_GetPlayerClass(client) == TFClass_Sniper)
				{
					BlockWeapons(client, 526, 14, "tf_weapon_sniperrifle");
					if(GetClientTeam(client) == 2)
					{
						BlockWeapons(client, 56, 14, "tf_weapon_sniperrifle");
						BlockWeapons(client, 1005, 14, "tf_weapon_sniperrifle");
						BlockWeapons(client, 1092, 14, "tf_weapon_sniperrifle");
					}
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Spy)
				{
					BlockWeapons(client, 225, 4, "tf_weapon_knife");
					BlockWeapons(client, 574, 4, "tf_weapon_knife");
					BlockWeapons(client, 649, 4, "tf_weapon_knife");
					
					TF2_RemoveWeaponSlot(client, 3);
					
					TF2_RemoveWeaponSlot(client, 4);
				}
			}
		}
	}

	return Plugin_Continue;
}


/*______                _   _                 
 |  ____|              | | (_)                
 | |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
 |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
 | |  | |_| | | | | (__| |_| | (_) | | | \__ \
 |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
*/


public bool:IsValidClient(client)
{
	if(IsClientInGame(client) && (!IsFakeClient(client)))
	{
		return true;
	}
	else
	{
		return false;
	}
}

BlockWeapons(client, blockid, replacementid, String:classname[])
{
	new slot1 = GetPlayerWeaponSlot(client, 0);
	new slot2 = GetPlayerWeaponSlot(client, 1);
	new slot3 = GetPlayerWeaponSlot(client, 2);

	if(IsValidEntity(slot1))
	{
		new slot1ID = GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex"); 
		if (slot1ID == blockid)
		{ 
			TF2_RemoveWeaponSlot(client, 0);
			hWeaponBlocked = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetClassname(hWeaponBlocked, classname);
			TF2Items_SetItemIndex(hWeaponBlocked, replacementid);
			TF2Items_SetQuality(hWeaponBlocked, 0);
			new iEntity = TF2Items_GiveNamedItem(client, hWeaponBlocked);
			EquipPlayerWeapon(client, iEntity);
		}
	}
	if(IsValidEntity(slot2))
	{
		new slot2ID = GetEntProp(slot2, Prop_Send, "m_iItemDefinitionIndex"); 
		if (slot2ID == blockid)
		{ 
			TF2_RemoveWeaponSlot(client, 1);
			hWeaponBlocked = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetClassname(hWeaponBlocked, classname);
			TF2Items_SetItemIndex(hWeaponBlocked, replacementid);
			TF2Items_SetQuality(hWeaponBlocked, 0);
			new iEntity = TF2Items_GiveNamedItem(client, hWeaponBlocked);
			EquipPlayerWeapon(client, iEntity);
		}
	}
	if(IsValidEntity(slot3))
	{
		new slot3ID = GetEntProp(slot3, Prop_Send, "m_iItemDefinitionIndex"); 
		if (slot3ID == blockid)
		{ 
			TF2_RemoveWeaponSlot(client, 2);
			hWeaponBlocked = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetClassname(hWeaponBlocked, classname);
			TF2Items_SetItemIndex(hWeaponBlocked, replacementid);
			TF2Items_SetQuality(hWeaponBlocked, 0);
			new iEntity = TF2Items_GiveNamedItem(client, hWeaponBlocked);
			EquipPlayerWeapon(client, iEntity);
		}
	}
}