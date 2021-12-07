/*
==========================================================================
	
	Change Log:
	
	v1.1 (1-Mar-2019)
	 - corrected mismatched config and selection values for primary and melee weapons.
	 - shortened primary weapon cvar descriptions so all values will print in cfg file.
	 
	v1.2 (5-Mar-2019)
	 - Added cvar to choose which weapon is active after items are given.
	 - Added code to change game cvar "survivor_respawn_with_guns" value to "0"
	 - Added chat message that prints if the knife is selected but knife unlock plugin is not running
	 - Removed duplicate chainsaw entries in l4d2_weapon_stocks_sis.inc so sIs will compile on sm 1.10

==========================================================================
*/


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_weapon_stocks_sis>
#pragma newdecls required

#define PLUGIN_VERSION "1.2"

public Plugin myinfo =
{
	name = "[L4D2] Smart Item Selector",
	author = "Patriot Games, based on [L4D & L4D2] Round Start Items Giver by kwski43.",
	description = "Selectively gives items to survivors and inlcudes VIP/admin options.",
	version = PLUGIN_VERSION
}

#define TEAM_SURVIVOR 2
#define TAG_SIS			"\x04|\x03sIs\x04|\x01 "

#define L4D2_WEPUPGFLAG_NONE            (0 << 0)
#define L4D2_WEPUPGFLAG_INCENDIARY      (1 << 0)
#define L4D2_WEPUPGFLAG_EXPLOSIVE       (1 << 1)
#define L4D2_WEPUPGFLAG_LASER 			(1 << 2)

#define RESPAWN_PISTOL_ONLY true

ConVar g_cvSmartItemEnable;
ConVar g_cvSendInfoMessage;
ConVar g_cvVipFlags;
ConVar g_cvRemovePistol;
ConVar g_cvLastSlot;
ConVar g_cvRespawnWithGuns;

ConVar g_cvPrimaryChoice;
ConVar g_cvSecondaryChoice;
ConVar g_cvHealthChoice;
ConVar g_cvThrowableChoice;
ConVar g_cvMedsChoice;
ConVar g_cvUpgradeChoice;

ConVar g_cvVipPrimaryChoice;
ConVar g_cvVipSecondaryChoice;
ConVar g_cvVipHealthChoice;
ConVar g_cvVipThrowableChoice;
ConVar g_cvVipMedsChoice;
ConVar g_cvVipUpgradeChoice;

ConVar g_cvRandomPrimary;
ConVar g_cvRandomSecondary;
ConVar g_cvRandomHealth;
ConVar g_cvRandomThrowable;
ConVar g_cvRandomMeds;
ConVar g_cvRandomUpgrade;
ConVar g_cvKnifeUnlockFound;

char g_sVipFlags[22];
bool g_bKnifeUnlockFound = false;
bool g_bLast[MAXPLAYERS+1];
bool g_bKnifeWarningPrinted[MAXPLAYERS+1];


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_cvKnifeUnlockFound = FindConVar("l4d2_knife_unlock_version");
	if (g_cvKnifeUnlockFound != null)
	{
		g_bKnifeUnlockFound = true;
	}
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_smart_item.phrases");
	
	/* Item Supply Settings */
	g_cvSmartItemEnable = CreateConVar("l4d2_sis_enable", "1", "Is the Smart Item Selector plugin enabled? 0=Plugin off, 1=Plugin on.", FCVAR_NOTIFY);
	g_cvSendInfoMessage = CreateConVar("l4d2_sis_info_message", "0", "Send each player a message informing them which item(s) they recieved?. 0=off, 1=on.", FCVAR_NOTIFY);
	g_cvVipFlags = CreateConVar("l4d2_sis_vip_flags", "a", "Survivors with any of these flags will receive VIP/admin items.\n[example admin flags: a=Reservation, b=Generic, c=Kick, d=Ban, o=custom1, etc.]");
	g_cvRemovePistol = CreateConVar("l4d2_sis_remove_pistol", "1", "Remove the default pistol before giving another secondary weapon?. 0=No, 1=Yes.", FCVAR_NOTIFY);
	g_cvLastSlot = CreateConVar("l4d2_sis_lastslot", "1", "Weapon slot to equip after all weapons/items are given.\n1=primary, 2=secondary, 3=throwable, 4=healthkit, 5=meds", _, true, 1.0, true, 5.0);
	
	/* Item Supply */
	g_cvPrimaryChoice = CreateConVar("l4d2_sis_primary_choice", "0", "Give survivors a Primary Weapon?\n0=disable, 1=pump shotgun, 2=chrome shotgun, 3=spas shotgun, 4=autoshotgun, 5=smg, 6=smg silenced, 7=smg mp5, 8=M16, 9=AK47, 10=Desert rifle, 11=SG552, 12=Hunting rifle, 13=Scout sniper, 14=Military sniper, 15=AWP sniper", FCVAR_NOTIFY);
	g_cvSecondaryChoice = CreateConVar("l4d2_sis_secondary_choice", "0", "Give survivors a Secondary Weapon?\n0=disable, 1=magnum pistol, 2=knife (requires [L4D2]Knife Unlock plugin), 3=frying pan, 4=tonfa, 5=crowbar, 6=cricket bat, 7=baseball bat, 8=machete, 9=katana, 10=golf club, 11=fire axe, 12=electric guitar", FCVAR_NOTIFY);
	g_cvHealthChoice = CreateConVar("l4d2_sis_health_choice", "0", "Give survivors a Health Item? 0=disable, 1=medkit, 2=defib", FCVAR_NOTIFY);
	g_cvThrowableChoice = CreateConVar("l4d2_sis_throwable_choice", "0", "Give survivors a Throwable? 0=disable, 1=pipe bomb, 2=molotov, 3=bile jar", FCVAR_NOTIFY);
	g_cvMedsChoice = CreateConVar("l4d2_sis_meds_choice", "0", "Give survivors Meds? 0=disable, 1=pills, 2=adrenaline", FCVAR_NOTIFY);
	g_cvUpgradeChoice = CreateConVar("l4d2_sis_upgrade_choice", "0", "Give survivors an Upgrade? 0=disable, 1=laser, 2=incendiary ammo, 3=explosive ammo", FCVAR_NOTIFY);
	
	/* Random Item Supply */
	g_cvRandomPrimary = CreateConVar("l4d2_sis_random_primary", "0", "Give survivors a random Primary Weapon? Overrides previous primary weapon setting. 0=disable, 1=enable.", FCVAR_NOTIFY);
	g_cvRandomSecondary = CreateConVar("l4d2_sis_random_secondary", "0", "Give survivors a random Secondary Weapon? Overrides previous secondary weapon setting. 0=disable, 1=enable.", FCVAR_NOTIFY);
	g_cvRandomHealth = CreateConVar("l4d2_sis_random_health", "0", "Give survivors a random Health item? Overrides previous health item setting. 0=disable, 1=enable.", FCVAR_NOTIFY);
	g_cvRandomThrowable = CreateConVar("l4d2_sis_random_throwable", "0", "Give survivors a random Throwable? Overrides previous throwable setting. 0=disable, 1=enable.", FCVAR_NOTIFY);
	g_cvRandomMeds = CreateConVar("l4d2_sis_random_meds", "0", "Give survivors random Meds? Overrides previous meds setting. 0=disable, 1=enable.", FCVAR_NOTIFY);
	g_cvRandomUpgrade = CreateConVar("l4d2_sis_random_upgrade", "0", "Give survivors a random Upgrade? Overrides previous upgrade settings. 0=disable, 1=enable.", FCVAR_NOTIFY);

	/* VIP Item Supply */
	g_cvVipPrimaryChoice = CreateConVar("l4d2_sis_vip_primary_choice", "0", "Give VIPs a Primary Weapon?\n0=disable, 1=pump shotgun, 2=chrome shotgun, 3=spas shotgun, 4=autoshotgun, 5=smg, 6=smg silenced, 7=smg mp5, 8=M16, 9=AK47, 10=Desert rifle, 11=SG552, 12=Hunting rifle, 13=Scout sniper, 14=Military sniper, 15=AWP sniper", FCVAR_NOTIFY);
	g_cvVipSecondaryChoice = CreateConVar("l4d2_sis_vip_secondary_choice", "0", "Give VIPs a Secondary Weapon?\n0=disable, 1=magnum pistol, 2=knife (requires [L4D2]Knife Unlock plugin), 3=frying pan, 4=tonfa, 5=crowbar, 6=cricket bat, 7=baseball bat, 8=machete, 9=katana, 10=golf club, 11=fire axe, 12=electric guitar", FCVAR_NOTIFY);
	g_cvVipHealthChoice = CreateConVar("l4d2_sis_vip_health_choice", "0", "Give VIPs a Health Item? Overrides ALL health item settings. 0=disable, 1=medkit, 2=defib", FCVAR_NOTIFY);
	g_cvVipThrowableChoice = CreateConVar("l4d2_sis_vip_throwable_choice", "0", "Give VIPs a Throwable? Overrides ALL throwable settings. 0=disable, 1=pipe bomb, 2=molotov, 3=bile jar", FCVAR_NOTIFY);
	g_cvVipMedsChoice = CreateConVar("l4d2_sis_vip_meds_choice", "0", "Give VIPs Meds? Overrides ALL meds settings. 0=disable, 1=pills, 2=adrenaline", FCVAR_NOTIFY);
	g_cvVipUpgradeChoice = CreateConVar("l4d2_sis_vip_upgrade_choice", "0", "Give VIPs an Upgrade? Overrides ALL upgrade settings. 0=disable, 1=laser, 2=incendiary ammo, 3=explosive ammo", FCVAR_NOTIFY);
	
	g_cvRespawnWithGuns = FindConVar("survivor_respawn_with_guns"); // we'll change this default cvar so primary weapons are not blocked for respawned survivors
	
	CreateConVar("l4d2_smart_item_selector_version", PLUGIN_VERSION, "Smart Item Selector plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d2_smart_item_selector");
		
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnConfigsExecuted()
{
	#if RESPAWN_PISTOL_ONLY
		g_cvRespawnWithGuns.IntValue = 0;
	#endif
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvSmartItemEnable.BoolValue)
	{
		int UserId = GetEventInt(event,"userid");
		int client = GetClientOfUserId(UserId);
		if (IsLivingSurvivor(client))
		{
			CreateTimer(3.0, Timer_CheckForItems, UserId, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_CheckForItems(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if (IsLivingSurvivor(client))
	{
		CheckForItems(client, false);
	}
}

static void CheckForItems(int client, bool bIsVip)
{
	if (IsLivingSurvivor(client))
	{
		g_bLast[client] = false;
		g_cvVipFlags.GetString(g_sVipFlags, sizeof(g_sVipFlags));
		int iVipFlags = ReadFlagString(g_sVipFlags);
		
		if (CheckCommandAccess(client, "sis_vip", iVipFlags))
		{
			bIsVip = true;
		}
		if(!g_bKnifeUnlockFound && (g_cvSecondaryChoice.IntValue == 2 || g_cvVipSecondaryChoice.IntValue == 2))
		{
			PrintKnifeMessage(client, bIsVip);
		}
		if (g_cvPrimaryChoice.IntValue > 0 || g_cvRandomPrimary.BoolValue || g_cvVipPrimaryChoice.IntValue > 0)
		{
			int iEntPrimaryWeapon = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Primary));
			WeaponId iPrimWepId = IdentifyWeapon(iEntPrimaryWeapon);
			WeaponId choice = view_as<WeaponId>(PrimarySelectId(g_cvVipPrimaryChoice.IntValue));
			
			if (iEntPrimaryWeapon == -1 || !IsValidEntity(iEntPrimaryWeapon) || (bIsVip && g_cvVipPrimaryChoice.IntValue > 0 && (iPrimWepId != choice)))
			{
				SelectPrimary(client, bIsVip);
			}
		}
		if (g_cvSecondaryChoice.IntValue > 0 || g_cvRandomSecondary.BoolValue || g_cvVipSecondaryChoice.IntValue > 0)
		{
			int iEntSecondaryWeapon = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Secondary));
			WeaponId iSecdondWepId = IdentifyWeapon(iEntSecondaryWeapon);
			MeleeWeaponId iMeleeWepId = IdentifyMeleeWeapon(iEntSecondaryWeapon);
			WeaponId iVipSecondaryChoice = view_as<WeaponId>(MagnumSelectId(g_cvVipSecondaryChoice.IntValue));
			MeleeWeaponId iVipMeleeChoice = view_as<MeleeWeaponId>(MeleeSelectId(g_cvVipSecondaryChoice.IntValue));
			
			if (iEntSecondaryWeapon == -1 || !IsValidEntity(iEntSecondaryWeapon) || iSecdondWepId == WEPID_PISTOL)
			{
				if( iEntSecondaryWeapon != -1 && g_cvRemovePistol.BoolValue)
				{
					RemovePlayerItem(client, iEntSecondaryWeapon);
					AcceptEntityInput(iEntSecondaryWeapon, "kill");
				}
				SelectSecondary(client, bIsVip);
			}
			else if (bIsVip && g_cvVipSecondaryChoice.IntValue == 1 && iSecdondWepId != iVipSecondaryChoice)
			{
				SelectSecondary(client, bIsVip);
			}
			else if (bIsVip && g_cvVipSecondaryChoice.IntValue > 1 && iMeleeWepId != iVipMeleeChoice && (!g_bKnifeUnlockFound && iMeleeWepId == WEPID_MELEE_NONE))
			{
				SelectSecondary(client, bIsVip);
			}
		}
		if (g_cvHealthChoice.IntValue > 0 || g_cvRandomHealth.BoolValue || g_cvVipHealthChoice.IntValue > 0)
		{
			int iEntHealth = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_HeavyHealthItem));
			WeaponId iHealthId = IdentifyWeapon(iEntHealth);
			WeaponId choice = view_as<WeaponId>(HealthSelectId(g_cvVipHealthChoice.IntValue));
			
			if (iEntHealth == -1 || !IsValidEntity(iEntHealth) || iHealthId == (WEPID_INCENDIARY_AMMO | WEPID_FRAG_AMMO) || (bIsVip && g_cvVipHealthChoice.IntValue > 0 && iHealthId != choice))
			{
				SelectHealth(client, bIsVip);
			}
		}
		if (g_cvThrowableChoice.IntValue > 0 || g_cvRandomThrowable.BoolValue || g_cvVipThrowableChoice.IntValue > 0)
		{
			int iEntThrowable = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Throwable));
			WeaponId iThrowId = IdentifyWeapon(iEntThrowable);
			WeaponId choice = view_as<WeaponId>(ThrowableSelectId(g_cvVipThrowableChoice.IntValue));
			
			if (iEntThrowable == -1 || !IsValidEntity(iEntThrowable) || (bIsVip && g_cvVipThrowableChoice.IntValue > 0 && (iThrowId != choice)))
			{
				SelectThrowable(client, bIsVip);
			}
		}
		
		if (g_cvMedsChoice.IntValue > 0 || g_cvRandomMeds.BoolValue || g_cvVipMedsChoice.IntValue > 0)
		{
			int iEntMeds = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_LightHealthItem));
			WeaponId iMedId = IdentifyWeapon(iEntMeds);
			WeaponId choice = view_as<WeaponId>(MedsSelectId(g_cvVipMedsChoice.IntValue));
			
			if (iEntMeds == -1 || !IsValidEntity(iEntMeds) || (bIsVip && g_cvVipMedsChoice.IntValue > 0 && (iMedId != choice)))
			{
				SelectMeds(client, bIsVip);
			}
		}
		if (g_cvUpgradeChoice.IntValue > 0 || g_cvRandomUpgrade.BoolValue || g_cvVipUpgradeChoice.IntValue > 0)
		{
			int iEntPrimaryWeapon = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Primary));
			if (iEntPrimaryWeapon == -1 || !IsValidEntity(iEntPrimaryWeapon))
			{
				return;
			}
			int iExistingUpgrd = GetUpgrdType(client);
			if (iExistingUpgrd == L4D2_WEPUPGFLAG_NONE)
			{
				SelectUpgrd(client, bIsVip);
			}
			else
			{
				int iVipUpgrdChoiceBv = UpgdChoiceBitVec(g_cvVipUpgradeChoice.IntValue);
				int iUpgrdChoiceBv = UpgdChoiceBitVec(g_cvUpgradeChoice.IntValue);
				bool bHasAmmoUpgrd = view_as<bool>(iExistingUpgrd & (L4D2_WEPUPGFLAG_INCENDIARY | L4D2_WEPUPGFLAG_EXPLOSIVE));
				
				if (bIsVip && iVipUpgrdChoiceBv > 0  && !(iVipUpgrdChoiceBv & iExistingUpgrd) && (iVipUpgrdChoiceBv == L4D2_WEPUPGFLAG_LASER || !bHasAmmoUpgrd))
				{
					SelectUpgrd(client, bIsVip);
				}	
				else if (iUpgrdChoiceBv > 0 && !(iUpgrdChoiceBv & iExistingUpgrd) && (iUpgrdChoiceBv == L4D2_WEPUPGFLAG_LASER || !bHasAmmoUpgrd))
				{
					SelectUpgrd(client, bIsVip);
				}
			}
		}
	}
	g_bLast[client] = true;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& iActiveWeapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!IsLivingSurvivor(client) || !g_bLast[client])
    {
            g_bLast[client] = false;
            return Plugin_Continue;
    }

    if (g_bLast[client])
    {
            g_bLast[client] = false;
            iActiveWeapon = GetPlayerWeaponSlot(client, g_cvLastSlot.IntValue - 1);
    }
    return Plugin_Continue;
}

static void SelectPrimary(int client, bool bIsVip)
{
	if (IsLivingSurvivor(client))
	{
		int iCase = -1;
		if (g_cvPrimaryChoice.IntValue > 0)
		{
			iCase = g_cvPrimaryChoice.IntValue;
		}
		if (g_cvRandomPrimary.BoolValue)
		{
			iCase = GetRandomInt(1, 15);
		} 
		if (bIsVip && g_cvVipPrimaryChoice.IntValue > 0)
		{
			iCase = g_cvVipPrimaryChoice.IntValue;
		}
		switch (iCase)
		{
			case 1: GiveItem(client, "pumpshotgun");
			case 2: GiveItem(client, "shotgun_chrome");
			case 3: GiveItem(client, "shotgun_spas");
			case 4: GiveItem(client, "autoshotgun");
			case 5: GiveItem(client, "smg");
			case 6: GiveItem(client, "smg_silenced");
			case 7: GiveItem(client, "smg_mp5");
			case 8: GiveItem(client, "rifle");
			case 9: GiveItem(client, "rifle_ak47");
			case 10: GiveItem(client, "rifle_desert");
			case 11: GiveItem(client, "rifle_sg552");
			case 12: GiveItem(client, "hunting_rifle");
			case 13: GiveItem(client, "sniper_scout");
			case 14: GiveItem(client, "sniper_military");
			case 15: GiveItem(client, "sniper_awp");
		}
	}
}		

static void SelectSecondary(int client, bool bIsVip)
{
	if (IsLivingSurvivor(client))
	{
		int iCase = -1;
		if (g_cvSecondaryChoice.IntValue > 0)
		{
			iCase = g_cvSecondaryChoice.IntValue;
		}
		if (g_cvRandomSecondary.BoolValue)
		{
			iCase = GetRandomInt(1, 12);
		}
		if (bIsVip && g_cvVipSecondaryChoice.IntValue > 0)
		{
			iCase = (g_cvVipSecondaryChoice.IntValue);
		}
		switch (iCase)
		{	
			case 1: GiveItem(client, "pistol_magnum");
			case 2:
			{
				if (g_bKnifeUnlockFound)
				{
					GiveItem(client, "knife");
				}
				else
				{
					GiveItem(client, "crowbar");
				}
			}
			case 3: GiveItem(client, "frying_pan");
			case 4: GiveItem(client, "tonfa");
			case 5: GiveItem(client, "crowbar");
			case 6: GiveItem(client, "cricket_bat");
			case 7: GiveItem(client, "baseball_bat");
			case 8: GiveItem(client, "machete");
			case 9: GiveItem(client, "katana");
			case 10: GiveItem(client, "golfclub"); 
			case 11: GiveItem(client, "fireaxe");
			case 12: GiveItem(client, "electric_guitar");
		}
	}
}

static void SelectHealth(int client, bool bIsVip)
{
	if (IsLivingSurvivor(client))
	{
		int iCase = -1;
		if (g_cvHealthChoice.IntValue > 0)
		{
			iCase = g_cvHealthChoice.IntValue;
		}
		if (g_cvRandomHealth.BoolValue)
		{
			iCase = GetRandomInt(1, 2);
		}
		if (bIsVip && g_cvVipHealthChoice.IntValue > 0) 
		{
			iCase = g_cvVipHealthChoice.IntValue;
		}
		switch (iCase)
		{
			case 1: GiveItem(client, "first_aid_kit");
			case 2: GiveItem(client, "defibrillator");
		}
	}
}

static void SelectThrowable(int client, bool bIsVip)
{
	if (IsLivingSurvivor(client))
	{
		int iCase = -1;
		if (g_cvThrowableChoice.IntValue > 0)
		{
			iCase = g_cvThrowableChoice.IntValue;
		}
		if (g_cvRandomThrowable.BoolValue)
		{
			iCase = GetRandomInt(1, 3);
		}
		if (bIsVip && g_cvVipThrowableChoice.IntValue > 0 )
		{
			iCase = g_cvVipThrowableChoice.IntValue;
		}
		switch (iCase)
		{
			case 1: GiveItem(client, "pipe_bomb");
			case 2: GiveItem(client, "molotov");
			case 3:	GiveItem(client, "vomitjar");
		}
	}
}

static void SelectMeds(int client, bool bIsVip)
{
	if (IsLivingSurvivor(client))
	{
		int iCase = -1;
		if (g_cvMedsChoice.IntValue > 0)
		{
			iCase = g_cvMedsChoice.IntValue;
		}
		if (g_cvRandomMeds.BoolValue)
		{
			iCase = GetRandomInt(1, 2);
		}
		if (bIsVip && g_cvVipMedsChoice.IntValue > 0)
		{
			iCase = g_cvVipMedsChoice.IntValue;
		}
		switch (iCase)
		{
			case 1: GiveItem(client, "pain_pills");
			case 2: GiveItem(client, "adrenaline");
		}
	}
}

static void SelectUpgrd(int client, bool bIsVip)
{
	if (IsLivingSurvivor(client))
	{
		int iCase = -1;
		if (g_cvUpgradeChoice.IntValue > 0)
		{
			iCase = g_cvUpgradeChoice.IntValue;
		}
		if (g_cvRandomUpgrade.BoolValue)
		{
			iCase = GetRandomInt(1, 3);
		}
		if (bIsVip && g_cvVipUpgradeChoice.IntValue > 0)
		{
			iCase = g_cvVipUpgradeChoice.IntValue;
		}
		switch (iCase)
		{
			case 1: GiveUpgrade(client, "LASER_SIGHT");
			case 2: GiveUpgrade(client, "INCENDIARY_AMMO");
			case 3: GiveUpgrade(client, "EXPLOSIVE_AMMO");
		}
	}
}

static void GiveItem(int client, char Item[22])
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", Item);
	
	if (g_cvSendInfoMessage.BoolValue)
	{
		PrintToChat(client, "%s%t", TAG_SIS, Item);
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

static void GiveUpgrade(int client, char Upgrade[22])
{
	int flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "upgrade_add %s", Upgrade);
	
	if (g_cvSendInfoMessage.BoolValue)
	{
		PrintToChat(client, "%s%t", TAG_SIS, Upgrade);
	}
	SetCommandFlags("upgrade_add", flags|FCVAR_CHEAT);
}

static void PrintKnifeMessage(int client, bool bIsVip)
{
	char message[16];
	Format(message, sizeof(message), "knife_warning");
	if(bIsVip && (g_cvVipSecondaryChoice.IntValue == 2 || g_cvVipSecondaryChoice.IntValue == 0 && g_cvSecondaryChoice.IntValue == 2) || !bIsVip && g_cvSecondaryChoice.IntValue == 2)
	{
		if(!g_bKnifeWarningPrinted[client])
		{
			PrintToChat(client, "%s%t", TAG_SIS, message);
			g_bKnifeWarningPrinted[client] = true;
		}
	}
}

stock bool IsLivingSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client))
	{
		return true;
	}
	return false;
}

stock int PrimarySelectId(int item)
{
	switch (item)
	{
		case 1: return 3;	//WEPID_PUMPSHOTGUN
		case 2: return 8;	//WEPID_SHOTGUN_CHROME
		case 3: return 11;	//WEPID_SHOTGUN_SPAS
		case 4: return 4;	//WEPID_AUTOSHOTGUN
		case 5: return 2;	//WEPID_SMG
		case 6: return 7;	//WEPID_SMG_SILENCED
		case 7: return 33;	//WEPID_SMG_MP5
		case 8: return 5;	//WEPID_RIFLE (M16)
		case 9: return 26;	//WEPID_RIFLE_AK47
		case 10: return 9;	//WEPID_RIFLE_DESERT
		case 11: return 34;	//WEPID_RIFLE_SG552
		case 12: return 6;	//WEPID_HUNTING_RIFLE
		case 13: return 36;	//WEPID_SNIPER_SCOUT
		case 14: return 10;	//WEPID_SNIPER_MILITARY
		case 15: return 35;	//WEPID_SNIPER_AWP
	}
	return 0;
}

stock int MagnumSelectId(int item)
{
	switch (item)
	{
		case 1: return 32;	//WEPID_PISTOL_MAGNUM
	}
	return 0;
}

stock int MeleeSelectId(int item)
{
	switch (item)
	{
		case 2: return 1;	//WEPID_KNIFE
		case 3: return 7;	//WEPID_FRYING_PAN
		case 4: return 12;	//WEPID_TONFA
		case 5: return 4;	//WEPID_CROWBAR
		case 6: return 3;	//WEPID_CRICKET_BAT
		case 7: return 2;	//WEPID_BASEBALL_BAT
		case 8: return 10;	//WEPID_MACHETE
		case 9: return 9;	//WEPID_KATANA
		case 10: return 8;	//WEPID_GOLF_CLUB
		case 11: return 6;	//WEPID_FIREAXE
		case 12: return 5;	//WEPID_ELECTRIC_GUITAR
	}
	return 0;
}

stock int HealthSelectId(int item)
{
	switch (item)
	{
		case 1: return 12;	//WEPID_FIRST_AID_KIT
		case 2: return 24;	//WEPID_DEFIBRILLATOR
	}
	return 0;
}

stock int MedsSelectId(int item)
{
	switch (item)
	{
		case 1: return 15;	//WEPID_PAIN_PILLS
		case 2: return 23;	//WEPID_ADRENALINE
	}
	return 0;
}

stock int ThrowableSelectId(int item)
{
	switch (item)
	{
		case 1: return 14;	//WEPID_PIPE_BOMB
		case 2: return 13;	//WEPID_MOLOTOV
		case 3: return 25;	//WEPID_VOMITJAR
	}
	return 0;
}

stock int UpgdChoiceBitVec(int item)
{
	switch (item)
	{
		case 1: return L4D2_WEPUPGFLAG_LASER;
		case 2: return L4D2_WEPUPGFLAG_INCENDIARY;
		case 3: return L4D2_WEPUPGFLAG_EXPLOSIVE;
	}
	return 0;
}

stock int GetUpgrdType(int client)
{
	int iUpgrdType = L4D2_WEPUPGFLAG_NONE;
	int iEntPrimaryWeapon = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Primary));
	if (iEntPrimaryWeapon != -1 && IsValidEdict(iEntPrimaryWeapon) && HasEntProp(iEntPrimaryWeapon, Prop_Send, "m_upgradeBitVec"))
	{
		iUpgrdType = GetEntProp(iEntPrimaryWeapon, Prop_Send, "m_upgradeBitVec");
	}
	return iUpgrdType;
}
