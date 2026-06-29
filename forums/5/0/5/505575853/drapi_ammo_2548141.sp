/*       <DR.API AMMO> (c) by <De Battista Clint - (http://doyou.watch)      */
/*                                                                           */
/*                      <DR.API AMMO> is licensed under a                    */
/* Creative Commons Attribution-NonCommercial-NoDerivs 4.0 Unported License. */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*  work.  If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.  */
//***************************************************************************//
//***************************************************************************//
//********************************DR.API AMMO********************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.3.1"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[AMMO] -"
#define MAX_WEAPONS						48

//***********************************//
//*************INCLUDE***************//
//***********************************//
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <autoexec>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_ammo_dev;

Handle cvar_ammo_338mag_max;
Handle cvar_ammo_357sig_max;
Handle cvar_ammo_357sig_min_max;
Handle cvar_ammo_357sig_p250_max;
Handle cvar_ammo_357sig_small_max;
Handle cvar_ammo_45acp_max;
Handle cvar_ammo_50AE_max;
Handle cvar_ammo_556mm_box_max;
Handle cvar_ammo_556mm_max;
Handle cvar_ammo_556mm_small_max;
Handle cvar_ammo_57mm_max;
Handle cvar_ammo_762mm_max;
Handle cvar_ammo_9mm_max;
Handle cvar_ammo_buckshot_max;
Handle cvar_ammo_taser;

Handle trie_WeaponsAmmo 					= INVALID_HANDLE;

//Bool
bool B_cvar_active_ammo_dev					= false;

//Customs
int C_ammo_338mag_max;
int C_ammo_357sig_max;
int C_ammo_357sig_min_max;
int C_ammo_357sig_p250_max;
int C_ammo_357sig_small_max;
int C_ammo_45acp_max;
int C_ammo_50AE_max;
int C_ammo_556mm_box_max;
int C_ammo_556mm_max;
int C_ammo_556mm_small_max;
int C_ammo_57mm_max;
int C_ammo_762mm_max;
int C_ammo_9mm_max;
int C_ammo_buckshot_max;
int C_ammo_taser;

int C_WeaponID[2048];
int C_WeaponAmmo[2048];
int C_WeaponClipBase[2048];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API AMMO",
	author = "Dr. Api",
	description = "DR.API AMMO by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_ammo", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_ammo_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_ammo_dev			= AutoExecConfig_CreateConVar("drapi_active_ammo_dev", 			"0", 					"Enable/Disable Dev Mod", 					DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_ammo_338mag_max			= AutoExecConfig_CreateConVar("drapi_ammo_338mag_max", 			"30", 					"AWP", 										DEFAULT_FLAGS);
	cvar_ammo_357sig_max			= AutoExecConfig_CreateConVar("drapi_ammo_357sig_max", 			"52", 					"HKP2000", 									DEFAULT_FLAGS);
	cvar_ammo_357sig_min_max		= AutoExecConfig_CreateConVar("drapi_ammo_357sig_min_max", 		"12", 					"CZ75", 									DEFAULT_FLAGS);
	cvar_ammo_357sig_p250_max		= AutoExecConfig_CreateConVar("drapi_ammo_357sig_p250_max", 	"26", 					"P250", 									DEFAULT_FLAGS);
	cvar_ammo_357sig_small_max		= AutoExecConfig_CreateConVar("drapi_ammo_357sig_small_max", 	"24", 					"USP-S", 									DEFAULT_FLAGS);
	cvar_ammo_45acp_max				= AutoExecConfig_CreateConVar("drapi_ammo_45acp_max", 			"100", 					"UMP45, MAC10",								DEFAULT_FLAGS);
	cvar_ammo_50AE_max				= AutoExecConfig_CreateConVar("drapi_ammo_50AE_max", 			"35", 					"DEAGLE", 									DEFAULT_FLAGS);
	cvar_ammo_556mm_box_max			= AutoExecConfig_CreateConVar("drapi_ammo_556mm_box_max", 		"200", 					"M249, NEGEV", 								DEFAULT_FLAGS);
	cvar_ammo_556mm_max				= AutoExecConfig_CreateConVar("drapi_ammo_556mm_max", 			"90", 					"M4A1, FAMAS, GALILAR", 					DEFAULT_FLAGS);
	cvar_ammo_556mm_small_max		= AutoExecConfig_CreateConVar("drapi_ammo_556mm_small_max", 	"40", 					"M4A1-S", 									DEFAULT_FLAGS);
	cvar_ammo_57mm_max				= AutoExecConfig_CreateConVar("drapi_ammo_57mm_max", 			"100", 					"FIVESEVEN, P90", 							DEFAULT_FLAGS);
	cvar_ammo_762mm_max				= AutoExecConfig_CreateConVar("drapi_ammo_762mm_max", 			"90", 					"AK47, SSG08, AUG, SG556, G3SG1, SCAR20", 	DEFAULT_FLAGS);
	cvar_ammo_9mm_max				= AutoExecConfig_CreateConVar("drapi_ammo_9mm_max", 			"120", 					"ELITE, TEC9, MP7, MP9, GLOCK, BIZON", 		DEFAULT_FLAGS);
	cvar_ammo_buckshot_max			= AutoExecConfig_CreateConVar("drapi_ammo_buckshot_max", 		"32", 					"MAG7, NOVA, SAWEDOFF, XM1014", 			DEFAULT_FLAGS);
	cvar_ammo_taser					= AutoExecConfig_CreateConVar("drapi_ammo_taser", 				"32", 					"TASER", 									DEFAULT_FLAGS);
	
	HookEvent("round_start", 	Event_RoundStart);
	//HookEvent("weapon_fire", 	Event_WeaponFire);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
			SDKHook(i, SDKHook_WeaponDrop, OnWeaponDrop);
		}
		i++;
	}
	
	trie_WeaponsAmmo = CreateTrie();
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
			SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
		}
		i++;
	}
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_ammo_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_ammo_338mag_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_357sig_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_357sig_min_max, 			Event_CvarChange);
	HookConVarChange(cvar_ammo_357sig_p250_max, 		Event_CvarChange);
	HookConVarChange(cvar_ammo_357sig_small_max, 		Event_CvarChange);
	HookConVarChange(cvar_ammo_45acp_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_50AE_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_556mm_box_max, 			Event_CvarChange);
	HookConVarChange(cvar_ammo_556mm_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_556mm_small_max, 		Event_CvarChange);
	HookConVarChange(cvar_ammo_57mm_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_762mm_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_9mm_max, 				Event_CvarChange);
	HookConVarChange(cvar_ammo_buckshot_max, 			Event_CvarChange);
	HookConVarChange(cvar_ammo_taser, 					Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_cvar_active_ammo_dev 					= GetConVarBool(cvar_active_ammo_dev);
	
	C_ammo_338mag_max 						= GetConVarInt(cvar_ammo_338mag_max);
	C_ammo_357sig_max 						= GetConVarInt(cvar_ammo_357sig_max);
	C_ammo_357sig_min_max 					= GetConVarInt(cvar_ammo_357sig_min_max);
	C_ammo_357sig_p250_max 					= GetConVarInt(cvar_ammo_357sig_p250_max);
	C_ammo_357sig_small_max 				= GetConVarInt(cvar_ammo_357sig_small_max);
	C_ammo_45acp_max 						= GetConVarInt(cvar_ammo_45acp_max);
	C_ammo_50AE_max 						= GetConVarInt(cvar_ammo_50AE_max);
	C_ammo_556mm_box_max 					= GetConVarInt(cvar_ammo_556mm_box_max);
	C_ammo_556mm_max 						= GetConVarInt(cvar_ammo_556mm_max);
	C_ammo_556mm_small_max 					= GetConVarInt(cvar_ammo_556mm_small_max);
	C_ammo_57mm_max 						= GetConVarInt(cvar_ammo_57mm_max);
	C_ammo_762mm_max 						= GetConVarInt(cvar_ammo_762mm_max);
	C_ammo_9mm_max 							= GetConVarInt(cvar_ammo_9mm_max);
	C_ammo_buckshot_max 					= GetConVarInt(cvar_ammo_buckshot_max);
	C_ammo_taser 							= GetConVarInt(cvar_ammo_taser);
	
	SetConVarsValve();
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_awp", C_ammo_338mag_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_hkp2000", C_ammo_357sig_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_cz75a", C_ammo_357sig_min_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_p250", C_ammo_357sig_p250_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_usp_silencer", C_ammo_357sig_small_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_ump45", C_ammo_45acp_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_mac10", C_ammo_45acp_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_deagle", C_ammo_50AE_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_m249", C_ammo_556mm_box_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_negev", C_ammo_556mm_box_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_m4a1", C_ammo_556mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_famas", C_ammo_556mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_galilar", C_ammo_556mm_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_m4a1_silencer", C_ammo_556mm_small_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_p90", C_ammo_57mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_fiveseven", C_ammo_57mm_max);

	SetTrieValue(trie_WeaponsAmmo, "weapon_ak47", C_ammo_762mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_ssg08", C_ammo_762mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_aug", C_ammo_762mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_sg556", C_ammo_762mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_g3sg1", C_ammo_762mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_scar20", C_ammo_762mm_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_elite", C_ammo_9mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_tec9", C_ammo_9mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_mp7", C_ammo_9mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_mp9", C_ammo_9mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_glock", C_ammo_9mm_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_bizon", C_ammo_9mm_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_mag7", C_ammo_buckshot_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_nova", C_ammo_buckshot_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_sawedoff", C_ammo_buckshot_max);
	SetTrieValue(trie_WeaponsAmmo, "weapon_xm1014", C_ammo_buckshot_max);
	
	SetTrieValue(trie_WeaponsAmmo, "weapon_taser", C_ammo_taser);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
} 

/***********************************************************/
/******************* SET CONVARS VALVE *********************/
/***********************************************************/
void SetConVarsValve()
{
	SetConVarInt(FindConVar("ammo_338mag_max"), 		C_ammo_338mag_max, false, false);
	SetConVarInt(FindConVar("ammo_357sig_max"), 		C_ammo_357sig_max, false, false);
	SetConVarInt(FindConVar("ammo_357sig_min_max"), 	C_ammo_357sig_min_max, false, false);
	SetConVarInt(FindConVar("ammo_357sig_p250_max"),	C_ammo_357sig_p250_max, false, false);
	SetConVarInt(FindConVar("ammo_357sig_small_max"), 	C_ammo_357sig_small_max, false, false);
	SetConVarInt(FindConVar("ammo_45acp_max"), 			C_ammo_45acp_max, false, false);
	SetConVarInt(FindConVar("ammo_50AE_max"), 			C_ammo_50AE_max, false, false);
	SetConVarInt(FindConVar("ammo_556mm_box_max"), 		C_ammo_556mm_box_max, false, false);
	SetConVarInt(FindConVar("ammo_556mm_max"), 			C_ammo_556mm_max, false, false);
	SetConVarInt(FindConVar("ammo_556mm_small_max"), 	C_ammo_556mm_small_max, false, false);
	SetConVarInt(FindConVar("ammo_57mm_max"), 			C_ammo_57mm_max, false, false);
	SetConVarInt(FindConVar("ammo_762mm_max"), 			C_ammo_762mm_max, false, false);
	SetConVarInt(FindConVar("ammo_9mm_max"), 			C_ammo_9mm_max, false, false);
	SetConVarInt(FindConVar("ammo_buckshot_max"), 		C_ammo_buckshot_max, false, false);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	SetCorrectAmmo();
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_WeaponFire(Handle event, char[] name, bool dontBroadcast)
{
	int client 					= GetClientOfUserId(GetEventInt(event, "userid"));
	int weapon 					= GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	char S_Weaponname[64];
	if(GetEdictClassname(weapon, S_Weaponname, sizeof(S_Weaponname)) && StrEqual(S_Weaponname, "weapon_knife") == false)
	{
		int ammo 					= GetPrimaryAmmo(client, weapon);
		int clip 					= Weapon_GetPrimaryClip(weapon);
		
		int ammoreserve				= GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		int ammoreserve2			= GetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount");
		
		// 20 + 20 - 20 - 1 = 40 - 19 = 11
		int reach = (ammo + C_WeaponClipBase[weapon]) - (C_WeaponClipBase[weapon] - clip);
		PrintToChat(client, "Ammo: %i, Clip: %i, Reach: %i, Ammo reserve: %i, %i", ammo, clip, reach, ammoreserve, ammoreserve2);
	}
}

/***********************************************************/
/********************* ON WEAPON DROP **********************/
/***********************************************************/
public Action OnWeaponDrop(int client, int weapon)
{
	if(weapon == -1) return;
	
	char S_Weaponname[64];
	
	if(GetEdictClassname(weapon, S_Weaponname, sizeof(S_Weaponname)))
	{
		int ammo;
		if(StrEqual(S_Weaponname, "weapon_taser"))
		{
			ammo = Weapon_GetPrimaryClip(weapon);
		}
		else
		{
			ammo = GetPrimaryAmmo(client, weapon);
		}
		
		C_WeaponID[weapon] 		= EntIndexToEntRef(weapon);
		C_WeaponAmmo[weapon] 	= ammo;
		
		if(B_cvar_active_ammo_dev)
		{
			int mode = GetEntProp(weapon, Prop_Send, "m_weaponMode");
			int silenceron = GetEntProp(weapon, Prop_Send, "m_bSilencerOn");
			
			PrintToChat(client, "%s ID: %i, %s: %i, Mode: %i, Silencer: %i", TAG_CHAT, EntIndexToEntRef(weapon), S_Weaponname, ammo, mode, silenceron);
		}
	}
}	

/***********************************************************/
/******************** ON WEAPON EQUIP **********************/
/***********************************************************/
public Action OnPostWeaponEquip(int client, int weapon)
{
	if(weapon == -1) return;
	
	Handle dataPackHandle;
	CreateDataTimer(0.0, Timer_SetCorrectAmmo, dataPackHandle);
	
	WritePackCell(dataPackHandle, GetClientUserId(client));
	WritePackCell(dataPackHandle, EntIndexToEntRef(weapon));
	
}

/***********************************************************/
/****************** TIMER DATA SET AMMO ********************/
/***********************************************************/
public Action Timer_SetCorrectAmmo(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	
	int client 		= GetClientOfUserId(ReadPackCell(dataPackHandle));
	int weapon 		= EntRefToEntIndex(ReadPackCell(dataPackHandle));

	if(weapon == -1) return;
	
	char S_Weaponname[64];
	if(GetEdictClassname(weapon, S_Weaponname, sizeof(S_Weaponname)))
	{
		int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch (weaponindex)
		{
			case 60: strcopy(S_Weaponname, 64, "weapon_m4a1_silencer");
			case 61: strcopy(S_Weaponname, 64, "weapon_usp_silencer");
			case 63: strcopy(S_Weaponname, 64, "weapon_cz75a");
		}
		
		if(GetEntProp(weapon, Prop_Send, "m_hPrevOwner") > 0)
		{
			if(C_WeaponID[weapon] == EntIndexToEntRef(weapon))
			{
				SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				if(StrEqual(S_Weaponname, "weapon_taser"))
				{
					Client_SetWeaponAmmoIndex(client, weapon, _, _, C_WeaponAmmo[weapon], _);
				}
				else
				{
					Client_SetWeaponAmmoIndex(client, weapon, C_WeaponAmmo[weapon], _, _, _);
				}
	
			}		
		}
		else
		{
			int value;
			if(GetTrieValue(trie_WeaponsAmmo, S_Weaponname, value))
			{
				SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				
				if(StrEqual(S_Weaponname, "weapon_taser"))
				{
					Client_SetWeaponAmmoIndex(client, weapon, _, _, value, _);
				}
				else
				{
					Client_SetWeaponAmmoIndex(client, weapon, value, _, _, _);
				}
				
				
				C_WeaponClipBase[weapon] = Weapon_GetPrimaryClip(weapon);
				if(B_cvar_active_ammo_dev)
				{
					PrintToChat(client, "%s %s: %i", TAG_CHAT, S_Weaponname, value);
				}
			}
		}
	}
}

/***********************************************************/
/******************* SET CORRECT AMMO **********************/
/***********************************************************/
void SetCorrectAmmo()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if(Client_IsIngame(i) && IsPlayerAlive(i))
		{
			int primary 				= GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
			int secondary 				= GetPlayerWeaponSlot(i, CS_SLOT_SECONDARY);
			
			if(primary != -1)
			{
				char S_Weaponname[64];
				GetEdictClassname(primary, S_Weaponname, sizeof(S_Weaponname));
				
				int weaponindex = GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex");
				switch (weaponindex)
				{
					case 60: strcopy(S_Weaponname, 64, "weapon_m4a1_silencer");
				}
				
				int value;
				if(GetTrieValue(trie_WeaponsAmmo, S_Weaponname, value))
				{
					SetEntProp(primary, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					Client_SetWeaponAmmoIndex(i, primary, value, _, _, _);
					if(B_cvar_active_ammo_dev)
					{
						PrintToChat(i, "%s RND %s: %i", TAG_CHAT, S_Weaponname, value);
					}
				}			
			}
			
			if(secondary != -1)
			{
				char S_Weaponname[64];
				GetEdictClassname(secondary, S_Weaponname, sizeof(S_Weaponname));

				int weaponindex = GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex");
				switch (weaponindex)
				{
					case 61: strcopy(S_Weaponname, 64, "weapon_usp_silencer");
					case 63: strcopy(S_Weaponname, 64, "weapon_cz75a");
				}
				
				int value;
				if(GetTrieValue(trie_WeaponsAmmo, S_Weaponname, value))
				{
					SetEntProp(secondary, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					Client_SetWeaponAmmoIndex(i, secondary, value, _, _, _);
					if(B_cvar_active_ammo_dev)
					{
						PrintToChat(i, "%s RND %s: %i", TAG_CHAT, S_Weaponname, value);
					}
				}			
			}
		}
	}
}
/***********************************************************/
/**************** CLIENT SET WEAPON AMMO *******************/
/***********************************************************/
stock bool Client_SetWeaponAmmoIndex(int client, int weapon, int primaryAmmo=-1, int secondaryAmmo=-1, int primaryClip=-1, int secondaryClip=-1)
{
	if(weapon ==-1) return false;
	if (primaryClip != -1) 
	{
		Weapon_SetPrimaryClip(weapon, primaryClip);
	}
	if(secondaryClip != -1) 
	{
		Weapon_SetSecondaryClip(weapon, secondaryClip);
	}
	Client_SetWeaponPlayerAmmoEx(client, weapon, primaryAmmo, secondaryAmmo);
	
	return true;
}

/***********************************************************/
/**************** CLIENT SET WEAPON AMMO *******************/
/***********************************************************/
stock bool Client_SetWeaponAmmo(int client, const char[] className, int primaryAmmo=-1, int secondaryAmmo=-1, int primaryClip=-1, int secondaryClip=-1)
{
	int weapon = Client_GetWeapon(client, className);
	
	if (weapon == INVALID_ENT_REFERENCE) 
	{
		return false;
	}
	
	if (primaryClip != -1) 
	{
		Weapon_SetPrimaryClip(weapon, primaryClip);
	}
	if(secondaryClip != -1) 
	{
		Weapon_SetSecondaryClip(weapon, secondaryClip);
	}
	Client_SetWeaponPlayerAmmoEx(client, weapon, primaryAmmo, secondaryAmmo);
	
	return true;
}

/***********************************************************/
/******************* CLIENT GET WEAPON *********************/
/***********************************************************/
stock int Client_GetWeapon(int client, const char[] className)
{
	int offset = Client_GetWeaponsOffset(client) - 4;
	int weapon = INVALID_ENT_REFERENCE;
	for (int i=0; i < MAX_WEAPONS; i++) 
	{
		offset += 4;
		
		weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon)) 
		{
			continue;
		}
		
		if (Entity_ClassNameMatches(weapon, className)) 
		{
			return weapon;
		}
	}

	return INVALID_ENT_REFERENCE;
}

/***********************************************************/
/*************** ENTITY CLASSNAME MATCHES ******************/
/***********************************************************/
stock bool Entity_ClassNameMatches(int entity, const char[] className, bool partialMatch=false)
{
	char entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));

	if (partialMatch) 
	{
		return (StrContains(entity_className, className) != -1);
	}

	return StrEqual(entity_className, className);
}

/***********************************************************/
/***************** ENTITY GET CLASSNAME ********************/
/***********************************************************/
stock int Entity_GetClassName(int entity, char[] buffer, int size)
{
	return GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);	
}

/***********************************************************/
/******************** WEAPON IS VALID **********************/
/***********************************************************/
stock int Weapon_IsValid(int weapon)
{
	if (!IsValidEdict(weapon)) 
	{
		return false;
	}
	
	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

/***********************************************************/
/*************** GET WEAPON CLIENT OFFSET ******************/
/***********************************************************/
stock int Client_GetWeaponsOffset(int client)
{
	int offset = -1;

	if (offset == -1) 
	{
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}
	
	return offset;
}

/***********************************************************/
/**************** GET PRIMARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_GetPrimaryClip(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

/***********************************************************/
/**************** GET PRIMARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_GetSecondaryClip(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip2");
}

/***********************************************************/
/**************** SET PRIMARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_SetPrimaryClip(int weapon, int value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", value);
}

/***********************************************************/
/************** SET SECONDARY CLIP WEAPON ******************/
/***********************************************************/
stock int Weapon_SetSecondaryClip(int weapon, int value)
{
	SetEntProp(weapon, Prop_Data, "m_iClip2", value);
}

/***********************************************************/
/**************** SET AMMO PLAYER WEAPON *******************/
/***********************************************************/
stock void Client_SetWeaponPlayerAmmoEx(int client, int weapon, int primaryAmmo=-1, int secondaryAmmo=-1)
{
	int offset_ammo = FindDataMapOffs(client, "m_iAmmo");

	if (primaryAmmo != -1) 
	{
		int offset = offset_ammo + (Weapon_GetPrimaryAmmoType(weapon) * 4);
		SetEntData(client, offset, primaryAmmo, 4, true);
	}

	if (secondaryAmmo != -1) 
	{
		int offset = offset_ammo + (Weapon_GetSecondaryAmmoType(weapon) * 4);
		SetEntData(client, offset, secondaryAmmo, 4, true);
	}
}

/***********************************************************/
/***************** GET PRIMARY AMMO TYPE *******************/
/***********************************************************/
stock int Weapon_GetPrimaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

/***********************************************************/
/**************** GET SECONDARY AMMO TYPE ******************/
/***********************************************************/
stock int Weapon_GetSecondaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType");
}

/***********************************************************/
/******************** GET PRIMARY AMMO *********************/
/***********************************************************/
stock int GetPrimaryAmmo(int client, int weapon)
{
    int ammotype = Weapon_GetPrimaryAmmoType(weapon);
    if(ammotype == -1) 
	{
		return -1;
	}
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) {
		return false;
	}

	return IsClientInGame(client);
} 

