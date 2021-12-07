#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "v1.01"

#define YER 			225	
#define WANGA_PRICK 	574 
#define DEAD_RINGER	 59	

#define PRETTYPISTOL		 773 
#define GUILLOTINE_PROMO 812	
#define GUILLOTINE		 833	
#define ATOMIZER			450
#define SANDMAN			 44 	

#define MANTREADS			  444 
#define PANIC_ATTACK		 1153 
#define BASE_JUMPER		1101 

#define DARWINS_SHIELD 	231 
#define RAZORBACK 		57 	
#define VITASAW 			173 

#define GRU 				239 
#define GRU_FESTIVE 		1084 
#define EVICTION_NOTICE 426 
#define FISTSSTEEL		331 

#define RESCUE_RANGER 997

public Plugin myinfo =
{
	name = "Balance Fortress (TF2 Balance Changes)",
	author = "JugadorXEI",
	description = "Plugin that balances TF2 weapons based on the Balance Changes blog post on teamfortess.com.",
	version = PLUGIN_VERSION,
}

/*
	Notes:
	
	Razorback buffs cannot entirely be done: The razorback break event (player_shield_blocked) is broken.
	Due to limitations, I can only apply Fists of Steel's nerfs on wearer rather than on active. 
	Abby changes cannot really be done as the spread change is rooted deep within code.
	I cannot force a fixed weapon spread on the Panic Attack, but it works nicely with random pellet spread disabled.
	The event that tracks the damage avoided through Bonk ("player_damage_dodged") doesn't work, so I can't do the Bonk! nerf
	Related to meter: cannot do anything about the flying guillotine and sandman, so rip.
	Similarly, I dunno how could to reduce the max time of a sandman ball.
	Cannot do anything about the crit-a-cola. ;_;

*/

ConVar g_bEnablePlugin;
ConVar g_bDisplayInfoOnSpawn;
ConVar g_bFirstTimeInfoOnSpawn;
bool bFirstSpawn[MAXPLAYERS+1] = false;
bool bDontShowWeaponHelpToggle[MAXPLAYERS+1] = false;
Handle g_WeaponHelpToggleCookie = INVALID_HANDLE;

int iRescueRangerHeal_Object = -1;
int iRescueRangerHeal_Enginner = -1;
int iRescueRangerHeal_Amount = -1;

// bool bMedigunChangedBuffs[MAXPLAYERS+1] = false;
int iMedigunBuffedTarget[MAXPLAYERS+1] = -1;
int iMedigunTargetWeapon[MAXPLAYERS+1] = -1;

bool bVitasawMedicDead[MAXPLAYERS+1] = false;
int iVitasawMedicOrgansObtained[MAXPLAYERS+1];
float fVitasawMedicUberAfterDeath[MAXPLAYERS+1] = 0.00;
int iOrganNumberSecondsAlive[2048];

bool bYERSpyGracePeriod[MAXPLAYERS+1] = false;

int iCyclesUsingSpeedyGloves[MAXPLAYERS+1];
bool bCycleStatusUsingSpeedyGloves[MAXPLAYERS+1] = false;
float fTotalHealthLostUsingSpeedyGloves[MAXPLAYERS+1];

int iPanicAttackConstantShots[MAXPLAYERS+1] = 1;
bool iPanicAttackShooting[MAXPLAYERS+1] = false;

bool bAirdashedOnce[MAXPLAYERS+1] = false;

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_BalanceChanges);
	HookEvent("post_inventory_application", Event_BalanceChanges);
	
	// Rescue Ranger - building_healed happens first, then arrow_impact.
	HookEvent("building_healed", RescueRangerHealNerf_Heal);
	HookEvent("arrow_impact", RescueRangerHealNerf_Bolt, EventHookMode_Pre);
	
	// Vita-saw and YER
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHit);
	
	g_bEnablePlugin = CreateConVar("sm_tfbalance_enable", "1", "Enables/Disables the plugin. Default = 1", FCVAR_DONTRECORD|FCVAR_PROTECTED);
	g_bDisplayInfoOnSpawn = CreateConVar("sm_tfbalance_infoonspawn", "1", "Displays weapons' information on spawn. Default = 1", FCVAR_DONTRECORD|FCVAR_PROTECTED);
	g_bFirstTimeInfoOnSpawn = CreateConVar("sm_tfbalance_firsttimeinfo", "1", "Displays on the first player's spawn information about the modifications done to the weapons. Default = 1", FCVAR_DONTRECORD|FCVAR_PROTECTED);
	
	g_WeaponHelpToggleCookie = RegClientCookie("weaponhelptoggle", "Remembers weapon help visibility for the player", CookieAccess_Private);
	
	RegConsoleCmd("sm_info", WeaponHelp, "Displays info for the updated weapons");
	RegConsoleCmd("sm_information", WeaponHelp, "Displays info for the updated weapons");
	RegConsoleCmd("sm_changes", WeaponHelp, "Displays info for the updated weapons");
	
	RegConsoleCmd("sm_infotoggle", WeaponHelpToggle, "Toggles info for the updated weapons whenever you spawn");
	RegConsoleCmd("sm_informationtoggle", WeaponHelpToggle, "Toggles info for the updated weapons whenever you spawn");
	RegConsoleCmd("sm_changestoggle", WeaponHelpToggle, "Toggles info for the updated weapons whenever you spawn");
}

public void OnMapStart()
{
	PrecacheModel("models/player/gibs/random_organ.mdl", true);
	for (int i = 1; i <= 7; i++)
	{
		char cSounds[128];
		Format(cSounds, sizeof(cSounds), "physics/body/body_medium_impact_soft%i.wav", i);
		PrecacheSound(cSounds, true);
	}
}

public void OnEntityCreated(int iEntity, const char[] cClassname)
{
	if (StrEqual(cClassname, "tf_dropped_weapon", false) && g_bEnablePlugin.BoolValue)
	{
		AcceptEntityInput(iEntity, "kill");
	}
}

public Action WeaponHelp(int iClient, int iArgs)
{
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && g_bEnablePlugin.BoolValue)
	{
		CreateBalanceMenu(iClient);
	}
}

public Action WeaponHelpToggle(int iClient, int iArgs)
{
	if (IsValidClient(iClient) && g_bEnablePlugin.BoolValue)
	{
		char cPreference[32];
		
		if (bDontShowWeaponHelpToggle[iClient])
		{
			bDontShowWeaponHelpToggle[iClient] = false;
			CPrintToChat(iClient, "{community}Help will now display now on spawn.");
		}
		else if (!bDontShowWeaponHelpToggle[iClient])
		{
			bDontShowWeaponHelpToggle[iClient] = true;
			CPrintToChat(iClient, "{community}Help will not display now on spawn.");
		}
		
		Format(cPreference, sizeof(cPreference), "%i", bDontShowWeaponHelpToggle[iClient]);
		SetClientCookie(iClient, g_WeaponHelpToggleCookie, cPreference);
	}
	else CPrintToChat(iClient, "{community}You are an invalid client, sorry!");
}

public void OnClientCookiesCached(int iClient)
{
	char cValue[8];
	GetClientCookie(iClient, g_WeaponHelpToggleCookie, cValue, sizeof(cValue));
	
	int iValue = StringToInt(cValue);
	bDontShowWeaponHelpToggle[iClient] = view_as<bool>(iValue);
}

public Action Event_BalanceChanges(Handle hEvent, const char[] name, bool dontBroadcast)
{	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	TFClassType iClass = TF2_GetPlayerClass(iClient);

	char iClientName[64];
	GetClientName(iClient, iClientName, sizeof(iClientName));
	
	int iPrimary, iPrimaryIndex, iSecondary, iSecondaryIndex, iMelee, iMeleeIndex, iBuilding, iBuildingIndex = -1;
	
	if (IsValidClient(iClient) && g_bEnablePlugin.BoolValue)
	{
		// primary weapon:
		iPrimary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
		if (iPrimary != -1) iPrimaryIndex = GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex");
		
		// secondary weapon:
		iSecondary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
		if (iSecondary != -1) iSecondaryIndex = GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex");
		
		// melee weapon:
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
			
		// PrintToConsole(iClient, "iPrimary: %i (Index: %i)\niSecondary: %i (Index: %i)\niMelee: %i (Index: %i)", iPrimary, iPrimaryIndex, iSecondary, iSecondaryIndex, iMelee, iMeleeIndex);
		
		// building weapon:
		if (iClass == TFClass_Spy)
		{
			iBuilding = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Building);
			if (iBuilding != -1) iBuildingIndex = GetEntProp(iBuilding, Prop_Send, "m_iItemDefinitionIndex");
		}
		
		if (!bFirstSpawn[iClient] && g_bFirstTimeInfoOnSpawn.BoolValue)
		{
			CPrintToChat(iClient, "{unique}The weapons you'll play with have been modified with changes according to the TF2 'Balance Changes' blog post, which you can check here: http://www.teamfortress.com/post.php?id=30147\nHave fun and enjoy!");
			bFirstSpawn[iClient] = true;
		}
		
		SDKUnhook(iClient, SDKHook_OnTakeDamage, DamageStuff);
		SDKUnhook(iClient, SDKHook_OnTakeDamagePost, StunFlagChanges);
		SDKUnhook(iClient, SDKHook_PreThink, OverhealLimitHook);
		SDKUnhook(iClient, SDKHook_PreThink, SpeedyGlovesDebuff);
		SDKUnhook(iClient, SDKHook_PreThink, PanicAttackIncreaseSpread);
		SDKUnhook(iClient, SDKHook_PreThink, AtomizerMinicritBuff);
		TF2_RemoveCondition(iClient, TFCond_AfterburnImmune);
		
		SDKHook(iClient, SDKHook_OnTakeDamagePost, StunFlagChanges);
		SDKHook(iClient, SDKHook_OnTakeDamage, DamageStuff);
	
		switch (iClass)
		{
			case TFClass_Spy:
			{			
				switch (iMeleeIndex)
				{
					case YER, WANGA_PRICK: // YER, Wanga Prick
					{
						// Your Eternal Reward
						// Changes:
						// Removed: "Cannot disguise" penalty
						// Added: Non-kill disguises require (and consume) a full cloak meter
						// Backstab-based disguises are still free
						// Increased cloak drain rate by 50%
						
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Melee);
						
						Handle hNewYER = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewYER, "tf_weapon_knife");
						TF2Items_SetItemIndex(hNewYER, iMeleeIndex);
						TF2Items_SetQuality(hNewYER, 10);
						TF2Items_SetLevel(hNewYER, GetRandomInt(1, 100));	
						TF2Items_SetNumAttributes(hNewYER, 2);
						TF2Items_SetAttribute(hNewYER, 0, 154, 1.00);
						TF2Items_SetAttribute(hNewYER, 1, 156, 1.00);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewYER);
						CloseHandle(hNewYER);
						EquipPlayerWeapon(iClient, iNewIndex);
						
						TF2Attrib_SetByName(iBuilding, "cloak consume rate increased", 1.50);
					}
				}
				
				if (iBuildingIndex == DEAD_RINGER) // Dead Ringer - confirmed it works
				{
					// Dead Ringer
					// Changes:
					// Ammo kits and dispensers no longer refill the Spy's cloak meter
					
					TF2Attrib_SetByName(iBuilding, "ReducedCloakFromAmmo", 0.0);
				}
			}
			case TFClass_Scout:
			{	
				switch (iSecondaryIndex)
				{
					case PRETTYPISTOL: // PBPP - confirmed it works
					{
						// Pretty Boy's Pocket Pistol
						// Goal: Make the weapon less of a liability and focus it as a "get health quick" tool with decent burst, at the expense of total damage
						// New design:
						// +15% firing speed
						// Up to +7 hp per hit (from +5)
						// -25% clip size (9 shots)
						
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);
						
						Handle hNewPBPP = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewPBPP, "tf_weapon_handgun_scout_secondary");
						TF2Items_SetItemIndex(hNewPBPP, iSecondaryIndex);
						TF2Items_SetQuality(hNewPBPP, 10);
						TF2Items_SetLevel(hNewPBPP, GetRandomInt(1, 100));	
						TF2Items_SetNumAttributes(hNewPBPP, 3);
						TF2Items_SetAttribute(hNewPBPP, 0, 6, 0.85);
						TF2Items_SetAttribute(hNewPBPP, 1, 3, 0.75);
						TF2Items_SetAttribute(hNewPBPP, 2, 16, 7.00);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewPBPP);
						CloseHandle(hNewPBPP);
						EquipPlayerWeapon(iClient, iNewIndex);
					}
					case GUILLOTINE_PROMO, GUILLOTINE:
					{
						/* 	Flying Guillotine
						Goal: Remove the feeling of randomness, and reward accuracy
						Changes:
							Removed: Crit vs stunned players
							Removed: Mini-crits at long range
							Added: Long range hits reduce recharge (by 1.5 seconds)
								Distance considered "long range" reduced by half of the previous value when determining mini-crits
						*/
						
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);
						
						Handle hNewPBPP = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewPBPP, "tf_weapon_cleaver");
						TF2Items_SetItemIndex(hNewPBPP, iSecondaryIndex);
						TF2Items_SetQuality(hNewPBPP, 10);
						TF2Items_SetLevel(hNewPBPP, GetRandomInt(1, 100));	
						TF2Items_SetNumAttributes(hNewPBPP, 3);
						TF2Items_SetAttribute(hNewPBPP, 0, 435, 1.00);
						TF2Items_SetAttribute(hNewPBPP, 1, 15, 0.00);
						TF2Items_SetAttribute(hNewPBPP, 2, 2029, 1.00);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewPBPP);
						CloseHandle(hNewPBPP);
						EquipPlayerWeapon(iClient, iNewIndex);
					}
				}
				
				switch (iMeleeIndex)
				{
					case ATOMIZER: // Atomizer
					{
					/* The Atomizer
						Changes:
							Triple-jump is now only possible while the bat is deployed
							Removed: Self-inflicted damage when triple-jumping
							Removed: Attack speed penalty
							Added: Melee attacks done while airborne mini-crit
							Added: 50% deploy time penalty (to prevent quick-switch by-pass)
							Reduced damage penalty vs players to -15% (from -20%) */
						
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Melee);
						
						Handle hNewPBPP = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewPBPP, "tf_weapon_bat");
						TF2Items_SetItemIndex(hNewPBPP, iMeleeIndex);
						TF2Items_SetQuality(hNewPBPP, 10);
						TF2Items_SetLevel(hNewPBPP, GetRandomInt(10, 10));	
						TF2Items_SetNumAttributes(hNewPBPP, 3);
						TF2Items_SetAttribute(hNewPBPP, 0, 138, 0.85);
						TF2Items_SetAttribute(hNewPBPP, 1, 551, 1.00);
						TF2Items_SetAttribute(hNewPBPP, 2, 773, 1.50);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewPBPP);
						CloseHandle(hNewPBPP);
						EquipPlayerWeapon(iClient, iNewIndex);
						SDKHook(iClient, SDKHook_PreThink, AtomizerMinicritBuff);
					}
				}
			}
			case TFClass_Soldier:
			{
				int iMantreads = GetPlayerWearableEntityIndex(iClient, "tf_wearable", MANTREADS);
				if (iMantreads != -1) // mantreads -- confirmed it works
				{
					// Mantreads
					// Changes:
					// +75% push-force reduction now includes airblast
					// Added: +200% air control when blast jumping
					
					TF2Attrib_SetByName(iMantreads, "airblast vulnerability multiplier", 0.25);
					TF2Attrib_SetByName(iMantreads, "increased air control", 3.0);
				}
				
				switch (iSecondaryIndex)
				{
					case PANIC_ATTACK:
					{
						/* Panic Attack
					Goal: Make the weapon immediately usable, remove the large burst potential (generally hard to balance), and give the weapon a unique design space to occupy
					New design:
						50% faster switch speed
						50% more pellets
						30% less damage
						Fires a wide, fixed shot pattern (regardless of server settings)
						Shot pattern grows with successive shots (e.g. while holding down the attack button), but resets after you stop firing or reload
						*/
						
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);
						
						Handle hNewPAttack = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewPAttack, "tf_weapon_shotgun");
						TF2Items_SetItemIndex(hNewPAttack, iSecondaryIndex);
						TF2Items_SetQuality(hNewPAttack, 10);
						TF2Items_SetLevel(hNewPAttack, GetRandomInt(1, 99));	
						TF2Items_SetNumAttributes(hNewPAttack, 3);
						TF2Items_SetAttribute(hNewPAttack, 0, 547, 0.50);
						TF2Items_SetAttribute(hNewPAttack, 1, 45, 1.50);
						TF2Items_SetAttribute(hNewPAttack, 2, 1, 0.70);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewPAttack);
						CloseHandle(hNewPAttack);
						EquipPlayerWeapon(iClient, iNewIndex);
						SDKHook(iClient, SDKHook_PreThink, PanicAttackIncreaseSpread);
					}
				}
			}
			case TFClass_Sniper:
			{
				int iDarwin = GetPlayerWearableEntityIndex(iClient, "tf_wearable", DARWINS_SHIELD);
				if (iDarwin != -1) // Darwin's Danger Shield -- confirmed it works
				{
					// Darwin's Danger Shield
					// Goal: Remove the increased survivability against enemy Snipers (which invalidates the existing design).
					// New design:
					// Counter ranged burn attacks (e.g. flares), and strengthen melee fights vs Pyros
					// Afterburn immunity
					// +50% fire resist

					TF2_RemoveWearable(iClient, iDarwin);
					
					Handle hNewDarwin = TF2Items_CreateItem(OVERRIDE_ALL);
					TF2Items_SetClassname(hNewDarwin, "tf_weapon_smg");
					TF2Items_SetItemIndex(hNewDarwin, DARWINS_SHIELD);
					TF2Items_SetQuality(hNewDarwin, 10);
					TF2Items_SetLevel(hNewDarwin, GetRandomInt(1, 100));	
					TF2Items_SetNumAttributes(hNewDarwin, 4);
					TF2Items_SetAttribute(hNewDarwin, 0, 74, 0.0);
					TF2Items_SetAttribute(hNewDarwin, 1, 60, 0.50);
					TF2Items_SetAttribute(hNewDarwin, 2, 3, 0.0);
					TF2Items_SetAttribute(hNewDarwin, 3, 25, 0.001);
					TF2_AddCondition(iClient, TFCond_AfterburnImmune, TFCondDuration_Infinite, iClient);
					
					int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewDarwin);
					EquipPlayerWeapon(iClient, iNewIndex);
					CloseHandle(hNewDarwin);
				}
			}
			case TFClass_Medic:
			{
				SDKHook(iClient, SDKHook_PreThink, OverhealLimitHook);
				
				switch (iMeleeIndex)
				{
					case VITASAW:
					{
						/* Vita-Saw
						Changes:
						Added "Organs" collecting concept (... you know, hit someone with a saw, and out pops a vital organ which you then take, and hold). Each hit with the Vita-Saw harvests the victim's organs (shown on the HUD).
						Added: On-death, preserve 15% ubercharge per Organ harvested. This effect caps at 60%.
						*/
						
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Melee);
						
						Handle hNewVitaSaw = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewVitaSaw, "tf_weapon_bonesaw");
						TF2Items_SetItemIndex(hNewVitaSaw, iMeleeIndex);
						TF2Items_SetQuality(hNewVitaSaw, 10);
						TF2Items_SetLevel(hNewVitaSaw, 5);	
						TF2Items_SetNumAttributes(hNewVitaSaw, 1);
						TF2Items_SetAttribute(hNewVitaSaw, 0, 125, -10.0);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewVitaSaw);
						CloseHandle(hNewVitaSaw);	
						EquipPlayerWeapon(iClient, iNewIndex);				
						
						if (bVitasawMedicDead[iClient])
						{
							float fFormula;
							
							if (fVitasawMedicUberAfterDeath[iClient] < (iVitasawMedicOrgansObtained[iClient] * 0.15)) 
							{
								fFormula = fVitasawMedicUberAfterDeath[iClient];
							}
							else if (fVitasawMedicUberAfterDeath[iClient] > (iVitasawMedicOrgansObtained[iClient] * 0.15))
							{
								fFormula = iVitasawMedicOrgansObtained[iClient] * 0.15;
							}
							else if (fVitasawMedicUberAfterDeath[iClient] == (iVitasawMedicOrgansObtained[iClient] * 0.15))
							{
								fFormula = iVitasawMedicOrgansObtained[iClient] * 0.15;
							}
							
							if (fFormula > 60.0) fFormula = 60.0;
							if (fFormula < 0.0) fFormula = 0.0;
							
							SetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel", fFormula);
							iVitasawMedicOrgansObtained[iClient] = 0;
							bVitasawMedicDead[iClient] = false;
							fVitasawMedicUberAfterDeath[iClient] = 0.00;
						}
						
						CreateTimer(0.1, VitasawOrgansInfo, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			case TFClass_Heavy:
			{
				switch (iSecondaryIndex)
				{
					case PANIC_ATTACK:
					{
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);
						
						Handle hNewPAttack = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewPAttack, "tf_weapon_shotgun");
						TF2Items_SetItemIndex(hNewPAttack, iSecondaryIndex);
						TF2Items_SetQuality(hNewPAttack, 10);
						TF2Items_SetLevel(hNewPAttack, GetRandomInt(1, 99));	
						TF2Items_SetNumAttributes(hNewPAttack, 3);
						TF2Items_SetAttribute(hNewPAttack, 0, 547, 0.50);
						TF2Items_SetAttribute(hNewPAttack, 1, 45, 1.50);
						TF2Items_SetAttribute(hNewPAttack, 2, 1, 0.70);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewPAttack);
						CloseHandle(hNewPAttack);
						EquipPlayerWeapon(iClient, iNewIndex);
						SDKHook(iClient, SDKHook_PreThink, PanicAttackIncreaseSpread);
					}
				}
			
				switch (iMeleeIndex)
				{
					case GRU, GRU_FESTIVE: // Gloves of Running Urgently and festive variation
					{
						/*	Gloves of Running Urgently
						Speed (lack-of) is used to balance the Heavy's high health, over-heal and damage output. While we still believe it's OK to have a class of items that increases Heavy's movement speed, players have been able to easily mitigate the existing negatives.
						Changes:
							Added: Max-health is drained while item is active (-10/sec), and regenerated while holstered
								Health will regenerate only the amount drained while active - minus any damage taken during that time
								Each time the gloves are deployed, the drain rate is accelerated for a brief period of time
							Removed: Marked-For-Death effect while active
							Removed: 25% damage penalty
						*/
					
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Melee);
						
						Handle hNewGRU = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewGRU, "tf_weapon_fists");
						TF2Items_SetItemIndex(hNewGRU, iMeleeIndex);
						TF2Items_SetQuality(hNewGRU, 10);
						TF2Items_SetLevel(hNewGRU, 10);	
						TF2Items_SetNumAttributes(hNewGRU, 4);
						TF2Items_SetAttribute(hNewGRU, 0, 107, 1.3);
						TF2Items_SetAttribute(hNewGRU, 1, 128, 1.0);
						TF2Items_SetAttribute(hNewGRU, 2, 144, 2.0);
						TF2Items_SetAttribute(hNewGRU, 3, 772, 1.5);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewGRU);
						CloseHandle(hNewGRU);	
						EquipPlayerWeapon(iClient, iNewIndex);
						SDKHook(iClient, SDKHook_PreThink, SpeedyGlovesDebuff);
					}
					case EVICTION_NOTICE: // Eviction Notice
					{
						/*	 Eviction Notice
						Changes:
							Added: Max-health is drained while item is active (-5/sec), and regenerated while holstered. Health will regenerate only the amount drained while active - minus any damage taken during that time.
							Removed: 20% damage vulnerability
						*/
					
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Melee);
						
						Handle hNewEvictor = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewEvictor, "tf_weapon_fists");
						TF2Items_SetItemIndex(hNewEvictor, iMeleeIndex);
						TF2Items_SetQuality(hNewEvictor, 10);
						TF2Items_SetLevel(hNewEvictor, 10);	
						TF2Items_SetNumAttributes(hNewEvictor, 5);
						TF2Items_SetAttribute(hNewEvictor, 0, 128, 1.0);
						TF2Items_SetAttribute(hNewEvictor, 1, 1, 0.4);
						TF2Items_SetAttribute(hNewEvictor, 2, 6, 0.6);
						TF2Items_SetAttribute(hNewEvictor, 3, 107, 1.15);
						TF2Items_SetAttribute(hNewEvictor, 4, 737, 3.0);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewEvictor);
						CloseHandle(hNewEvictor);	
						EquipPlayerWeapon(iClient, iNewIndex);
						SDKHook(iClient, SDKHook_PreThink, SpeedyGlovesDebuff);
					}
				}
			}
			case TFClass_Engineer:
			{
				switch (iPrimaryIndex)
				{
					case PANIC_ATTACK:
					{
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Primary);
						
						Handle hNewPAttack = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewPAttack, "tf_weapon_shotgun");
						TF2Items_SetItemIndex(hNewPAttack, iPrimaryIndex);
						TF2Items_SetQuality(hNewPAttack, 10);
						TF2Items_SetLevel(hNewPAttack, GetRandomInt(1, 99));	
						TF2Items_SetNumAttributes(hNewPAttack, 3);
						TF2Items_SetAttribute(hNewPAttack, 0, 547, 0.50);
						TF2Items_SetAttribute(hNewPAttack, 1, 45, 1.50);
						TF2Items_SetAttribute(hNewPAttack, 2, 1, 0.70);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewPAttack);
						CloseHandle(hNewPAttack);
						EquipPlayerWeapon(iClient, iNewIndex);
						SDKHook(iClient, SDKHook_PreThink, PanicAttackIncreaseSpread);
					}
				}
			}
			case TFClass_Pyro:
			{
				switch (iSecondaryIndex)
				{
					case PANIC_ATTACK:
					{
						TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);
						
						Handle hNewPAttack = TF2Items_CreateItem(OVERRIDE_ALL);
						TF2Items_SetClassname(hNewPAttack, "tf_weapon_shotgun");
						TF2Items_SetItemIndex(hNewPAttack, iSecondaryIndex);
						TF2Items_SetQuality(hNewPAttack, 10);
						TF2Items_SetLevel(hNewPAttack, GetRandomInt(1, 99));	
						TF2Items_SetNumAttributes(hNewPAttack, 3);
						TF2Items_SetAttribute(hNewPAttack, 0, 547, 0.50);
						TF2Items_SetAttribute(hNewPAttack, 1, 45, 1.50);
						TF2Items_SetAttribute(hNewPAttack, 2, 1, 0.70);
						
						int iNewIndex = TF2Items_GiveNamedItem(iClient, hNewPAttack);
						CloseHandle(hNewPAttack);
						EquipPlayerWeapon(iClient, iNewIndex);
						SDKHook(iClient, SDKHook_PreThink, PanicAttackIncreaseSpread);
					}
				}
			}
		}
	
		if (iClass != TFClass_Medic)
		{
			iVitasawMedicOrgansObtained[iClient] = 0;
			bVitasawMedicDead[iClient] = false;
			fVitasawMedicUberAfterDeath[iClient] = 0.00;
		}
		
		iCyclesUsingSpeedyGloves[iClient] = 0;
		bCycleStatusUsingSpeedyGloves[iClient] = false;
		fTotalHealthLostUsingSpeedyGloves[iClient] = 0.0;
		TF2Attrib_RemoveByName(iClient, "max health additive bonus");
		
		// Creates a menu describing the changes done.
		if (g_bDisplayInfoOnSpawn.BoolValue && !bDontShowWeaponHelpToggle[iClient]) CreateBalanceMenu(iClient);
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int iClient, iAttacker, iMelee, iMeleeIndex, iSecondary, iMeleeAttacker, iMeleeAttackerIndex = -1;
	TFClassType iClass, iClassAttacker;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if (IsValidClient(iClient) && g_bEnablePlugin.BoolValue)
	{
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		iSecondary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
		
		iClass = TF2_GetPlayerClass(iClient); 
		
		if (iClass == TFClass_Medic && iMeleeIndex == VITASAW)
		{
			bVitasawMedicDead[iClient] = true; // Vitasaw 
			if (iSecondary != -1) fVitasawMedicUberAfterDeath[iClient] = GetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel");
		}
	}
	
	if (IsValidClient(iAttacker) && g_bEnablePlugin.BoolValue)
	{
		iMeleeAttacker = GetPlayerWeaponSlot(iAttacker, TFWeaponSlot_Melee);
		if (iMeleeAttacker != -1) iMeleeAttackerIndex = GetEntProp(iMeleeAttacker, Prop_Send, "m_iItemDefinitionIndex");
		
		iClassAttacker = TF2_GetPlayerClass(iAttacker);
		
		if (iClassAttacker == TFClass_Spy && (iMeleeAttackerIndex == YER || iMeleeAttackerIndex == WANGA_PRICK))
		{
			bYERSpyGracePeriod[iAttacker] = true;
			CreateTimer(0.25, YERSpyGraceEnded, iAttacker);
		}
	}
}

public Action YERSpyGraceEnded(Handle timer, int iAttacker)
{
	bYERSpyGracePeriod[iAttacker] = false;
}

public Action Event_PlayerHit(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int iClient, iVictim, iMelee, iMeleeIndex, iActiveWeapon = -1;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	float fOrigin[3];
	float fVelocity[3];
	
	if (IsValidClient(iClient) && g_bEnablePlugin.BoolValue)
	{
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
		if (iMeleeIndex == VITASAW && iActiveWeapon == iMelee)
		{
			int iOrgan = CreateEntityByName("prop_physics_override");

			if (iOrgan > 0 && IsValidEntity(iOrgan))
			{
				// Here we dispatch the values
				SetEntityModel(iOrgan, "models/player/gibs/random_organ.mdl");
				SetEntProp(iOrgan, Prop_Send, "m_nSolidType", 6);
				SetEntProp(iOrgan, Prop_Send, "m_usSolidFlags", 152);
				// SetEntPropFloat(iOrgan, Prop_Send, "m_flModelScale", 2.5);
				
				// Here we get the victim's position
				GetClientAbsOrigin(iVictim, fOrigin);
				fOrigin[2] += 35.0;
				fVelocity[2] += 225.0;
				fVelocity[1] += GetRandomFloat(-359.0, 359.0);

				// Here we spawn the entity
				DispatchSpawn(iOrgan);
				
				SetEntityRenderFx(iOrgan, RENDERFX_PULSE_FAST_WIDE);
				SetEntityRenderColor(iOrgan, 255, 255, 0, 255);
				
				// This puts the organ in position
				TeleportEntity(iOrgan, fOrigin, NULL_VECTOR, fVelocity);
				
				
				SDKHook(iOrgan, SDKHook_StartTouch, OrganPickUp);
				CreateTimer(1.0, OrganDespawn, iOrgan, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action OrganDespawn(Handle timer, int iOrgan)
{	
	if (IsValidEntity(iOrgan))
	{	
		iOrganNumberSecondsAlive[iOrgan]++;
		
		if (iOrganNumberSecondsAlive[iOrgan] == 15)
		{
			char cClassname[64];
			GetEntityClassname(iOrgan, cClassname, sizeof(cClassname));
		
			if (StrEqual(cClassname, "prop_physics", false) && GetEntProp(iOrgan, Prop_Send, "m_nSolidType") == 6)
			{
				AcceptEntityInput(iOrgan, "kill");
				return Plugin_Handled;
			}
		}
	}
	else
	{
		iOrganNumberSecondsAlive[iOrgan] = 0;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action VitasawOrgansInfo(Handle timer, int iClient)
{	
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Medic) 
	{
		// melee weapon:
		int iMelee, iMeleeIndex/*, iActiveWeapon*/ = -1;
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		
		if (iMeleeIndex == VITASAW) // Vitasaw
		{
			SetHudTextParams(0.18, 0.9, 1.0, 200, 255, 200, 255);
			ShowHudText(iClient, 4, "Organs: %i", iVitasawMedicOrgansObtained[iClient]);
		}
	}
	else return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action OrganPickUp(int iOrgan, int iClient)
{
	if (IsValidEntity(iOrgan) && IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Medic)
	{
		// melee weapon:
		int iMelee, iMeleeIndex = -1;
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		
		if (iMeleeIndex == VITASAW) // Vitasaw
		{
			AcceptEntityInput(iOrgan, "kill");
			iVitasawMedicOrgansObtained[iClient]++;
			if (iVitasawMedicOrgansObtained[iClient] > 4) iVitasawMedicOrgansObtained[iClient] = 4;
			
			char cSounds[128];
			Format(cSounds, sizeof(cSounds), "physics/body/body_medium_impact_soft%i.wav", GetRandomInt(1, 7));
			EmitSoundToClient(iClient, cSounds, _, _, SNDLEVEL_GUNFIRE);
		}
	}
}

public void PanicAttackIncreaseSpread(int iClient)
{
	if (IsValidClient(iClient) && IsPlayerAlive(iClient)) 
	{
		// melee weapon:
		int iSecondary, iPrimary, iSecondaryIndex, iPrimaryIndex, iActiveWeapon, iReloadMode = -1;
		iSecondary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
		if (iSecondary != -1) iSecondaryIndex = GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex");
		iSecondary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
		if (iSecondary != -1) iSecondaryIndex = GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex");
		iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if (iSecondary != -1 || iPrimary != -1) iReloadMode = GetEntProp(iSecondary, Prop_Send, "m_iReloadMode");
		
		if ((iActiveWeapon == iPrimary || iActiveWeapon == iSecondary) &&
		(iPrimaryIndex == PANIC_ATTACK || iSecondaryIndex == PANIC_ATTACK))
		{
			int iButtons = GetClientButtons(iClient);
			
			if ((iButtons & IN_ATTACK) == IN_ATTACK && iReloadMode == 0)
			{
				if (!iPanicAttackShooting[iClient])
				{
					if (TF2_GetPlayerClass(iClient) == TFClass_Engineer) CreateTimer(0.20, IncreasePASpread, iPrimary);
					else CreateTimer(0.20, IncreasePASpread, iSecondary);
					iPanicAttackShooting[iClient] = true;
				}
			}
			else
			{
				if (TF2_GetPlayerClass(iClient) == TFClass_Engineer) TF2Attrib_RemoveByName(iPrimary, "spread penalty");
				else TF2Attrib_RemoveByName(iSecondary, "spread penalty");
				iPanicAttackConstantShots[iClient] = 1;
				iPanicAttackShooting[iClient] = false;
			}
		}
	}
	else SDKUnhook(iClient, SDKHook_PreThink, SpeedyGlovesDebuff);
}

public Action IncreasePASpread(Handle timer, int iPanicAttack)
{	
	// The client.
	int iClient = GetEntPropEnt(iPanicAttack, Prop_Send, "m_hOwner");
	
	if (IsValidClient(iClient) && IsPlayerAlive(iClient)) 
	{
		// melee weapon:
		int iIndex, iActiveWeapon = -1;
		iIndex = GetEntProp(iPanicAttack, Prop_Send, "m_iItemDefinitionIndex");
		iActiveWeapon = GetEntProp(iClient, Prop_Send, "m_hActiveWeapon");

		if (iIndex == PANIC_ATTACK || iActiveWeapon == iPanicAttack) // Panic Attack
		{
			TF2Attrib_SetByName(iPanicAttack, "spread penalty", iPanicAttackConstantShots[iClient] * 1.10);
			iPanicAttackConstantShots[iClient]++;
			iPanicAttackShooting[iClient] = false;
		}
	}
	else return Plugin_Handled;
	
	return Plugin_Continue;
}

public void SpeedyGlovesDebuff(int iClient)
{	
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Heavy) 
	{
		// melee weapon:
		int iMelee, iMeleeIndex, iActiveWeapon = -1;
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		
		if (iActiveWeapon == iMelee)
		{
			switch (iMeleeIndex)
			{
				case GRU, GRU_FESTIVE, EVICTION_NOTICE: // GRU and Festive
				{
					if (!bCycleStatusUsingSpeedyGloves[iClient])
					{
						if (iCyclesUsingSpeedyGloves[iClient] <= 5) CreateTimer(0.5, HeavyDrainHealth, iClient);
						else CreateTimer(1.0, HeavyDrainHealth, iClient);
						bCycleStatusUsingSpeedyGloves[iClient] = true;
					}
				}
			}
		}
		else
		{
			iCyclesUsingSpeedyGloves[iClient] = 0;
			switch (iMeleeIndex)
			{
				case GRU, GRU_FESTIVE, EVICTION_NOTICE:  // GRU and Festive
				{
					if(!bCycleStatusUsingSpeedyGloves[iClient])
					{
						CreateTimer(1.0, HeavyGiveHealthBack, iClient);
						bCycleStatusUsingSpeedyGloves[iClient] = true;
					}
				}
			}
		}
	}
	else SDKUnhook(iClient, SDKHook_PreThink, SpeedyGlovesDebuff);
}

public Action HeavyDrainHealth(Handle timer, int iClient)
{
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Heavy) 
	{
		// melee weapon:
		int iMelee, iMeleeIndex, iActiveWeapon, iHealth = -1;
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		iHealth = GetClientHealth(iClient);
			
		if (iActiveWeapon == iMelee)
		{
			iCyclesUsingSpeedyGloves[iClient]++;
			switch (iMeleeIndex)
			{
				case GRU, GRU_FESTIVE: // GRU and Festive
				{
					fTotalHealthLostUsingSpeedyGloves[iClient] = fTotalHealthLostUsingSpeedyGloves[iClient] - 10.0;
					if (fTotalHealthLostUsingSpeedyGloves[iClient] < -300.0) fTotalHealthLostUsingSpeedyGloves[iClient] = -300.0;
					
					TF2Attrib_SetByName(iClient, "max health additive bonus", fTotalHealthLostUsingSpeedyGloves[iClient]);
					// PrintToChat(iClient, "Max health lost: %f", fTotalHealthLostUsingSpeedyGloves[iClient]);
					
					iHealth = iHealth - 10;
					if (iHealth < 1) iHealth = 1; 
					SetEntityHealth(iClient, iHealth);
				}
				case EVICTION_NOTICE: // Eviction Notice
				{
					fTotalHealthLostUsingSpeedyGloves[iClient] = fTotalHealthLostUsingSpeedyGloves[iClient] - 5.0;
					if (fTotalHealthLostUsingSpeedyGloves[iClient] < -300.0) fTotalHealthLostUsingSpeedyGloves[iClient] = -300.0;
					
					TF2Attrib_SetByName(iClient, "max health additive bonus", fTotalHealthLostUsingSpeedyGloves[iClient]);
					// PrintToChat(iClient, "Max health lost: %f", fTotalHealthLostUsingSpeedyGloves[iClient]);		
		
					iHealth = iHealth - 5;
					if (iHealth < 1) iHealth = 1; 
					SetEntityHealth(iClient, iHealth);
				}
			}
		}
		else iCyclesUsingSpeedyGloves[iClient] = 0;
			
	}
	
	bCycleStatusUsingSpeedyGloves[iClient] = false;
}


public Action HeavyGiveHealthBack(Handle timer, int iClient)
{
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Heavy) 
	{
		// melee weapon:
		int iMelee, iMeleeIndex, iActiveWeapon, iHealth = -1;
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		iHealth = GetClientHealth(iClient);
			
		if (iActiveWeapon != iMelee && fTotalHealthLostUsingSpeedyGloves[iClient] < 0.0)
		{
			// PrintToConsole(iClient, "zoinks1");
			switch (iMeleeIndex)
			{
				case GRU, GRU_FESTIVE: // GRU and Festive
				{
					fTotalHealthLostUsingSpeedyGloves[iClient] = fTotalHealthLostUsingSpeedyGloves[iClient] + 10.0;
					if (fTotalHealthLostUsingSpeedyGloves[iClient] > 0.0) fTotalHealthLostUsingSpeedyGloves[iClient] = 0.0;
					
					TF2Attrib_SetByName(iClient, "max health additive bonus", fTotalHealthLostUsingSpeedyGloves[iClient]);
					// PrintToChat(iClient, "Max health lost: %f", fTotalHealthLostUsingSpeedyGloves[iClient]);
					
					iHealth = iHealth + 10;
					if (iHealth > 300) iHealth = 300; 
					SetEntityHealth(iClient, iHealth);
				}
				case EVICTION_NOTICE: // Eviction Notice
				{
					fTotalHealthLostUsingSpeedyGloves[iClient] = fTotalHealthLostUsingSpeedyGloves[iClient] + 5.0;
					if (fTotalHealthLostUsingSpeedyGloves[iClient] > 300.0) fTotalHealthLostUsingSpeedyGloves[iClient] = 300.0;
					
					TF2Attrib_SetByName(iClient, "max health additive bonus", fTotalHealthLostUsingSpeedyGloves[iClient]);
					// PrintToChat(iClient, "Max health lost: %f", fTotalHealthLostUsingSpeedyGloves[iClient]);		
		
					iHealth = iHealth + 5;
					if (iHealth > 300) iHealth = 300; 
					SetEntityHealth(iClient, iHealth);
				}
			}
		}			
	}
	
	bCycleStatusUsingSpeedyGloves[iClient] = false;
}

public void AtomizerMinicritBuff(int iClient)
{
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Scout) 
	{
		// melee weapon:
		int iMelee, iMeleeIndex, iActiveWeapon = -1;
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		
		// PrintCenterText(iClient, "Deployed? %i", GetEntProp(iMelee, Prop_Send, "m_iReloadMode"));
		
		if (iActiveWeapon == iMelee && iMeleeIndex == ATOMIZER)
		{
			if ((GetEntityFlags(iClient) & FL_ONGROUND) != FL_ONGROUND)
			{
				TF2_AddCondition(iClient, TFCond_Buffed, TFCondDuration_Infinite, iClient);
				
				if (GetEntProp(iClient, Prop_Send, "m_iAirDash") == 1)
				{
					if (bAirdashedOnce[iClient] == false) SetEntProp(iClient, Prop_Send, "m_iAirDash", 0);
					bAirdashedOnce[iClient] = true;
				}
			}
			else
			{
				TF2_RemoveCondition(iClient, TFCond_Buffed);
				bAirdashedOnce[iClient] = false;				
			}
		}
		else
		{
			TF2_RemoveCondition(iClient, TFCond_Buffed);
			if (bAirdashedOnce[iClient] == true) SetEntProp(iClient, Prop_Send, "m_iAirDash", 1);
			bAirdashedOnce[iClient] = false;
		}
	}
	else SDKUnhook(iClient, SDKHook_PreThink, AtomizerMinicritBuff);
}

public Action RescueRangerHealNerf_Bolt(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int iBolt, iObject, iEngineer = -1;
	iBolt = GetEventInt(hEvent, "projectileType");
	iObject = GetEventInt(hEvent, "attachedEntity");
	iEngineer = GetEventInt(hEvent, "shooter");
	
	// Here we verify the engineer and object are the same in arrow_impact, and if the bolt is 18
	// (which is the rescue ranger's bolt)
	if (IsValidClient(iEngineer) && iRescueRangerHeal_Object == iObject &&
	iRescueRangerHeal_Enginner == iEngineer && TF2_GetPlayerClass(iEngineer) == TFClass_Engineer &&
	iBolt == 18  && g_bEnablePlugin.BoolValue)
	{
		/*	Rescue Ranger
			Changes:
			Ranged repairs now consume metal (at a 4-to-1 health-to-metal ratio, e.g. repairing 60 damage costs 15 metal) */
		
		// We get the engineer's metal, the amount to deduct based on the amount healed,
		// and then we subtract it.
		int iMetalReserve, iMetalToDeduct, iTotalMetal;
		iMetalReserve =	GetEntData(iEngineer, FindDataMapInfo(iEngineer, "m_iAmmo") + (3 * 4), 4);
		iMetalToDeduct = RoundToNearest(iRescueRangerHeal_Amount / 4.00);
		iTotalMetal = iMetalReserve - iMetalToDeduct;
		
		// We have sure we don't give the engi a negative metal value.
		if (iTotalMetal < 0) iTotalMetal = 0;
		// Here we give the metal.
		SetEntData(iEngineer, FindDataMapInfo(iEngineer, "m_iAmmo") + (3 * 4), iTotalMetal, 4);
		
		// We reset stuff.
		iRescueRangerHeal_Object = -1;
		iRescueRangerHeal_Enginner = -1;
		iRescueRangerHeal_Amount = -1;
	}
	else
	{
		iRescueRangerHeal_Object = -1;
		iRescueRangerHeal_Enginner = -1;
		iRescueRangerHeal_Amount = -1;
	}
}

public Action RescueRangerHealNerf_Heal(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int iObject, iEngineer, iAmount = -1;
	iObject = GetEventInt(hEvent, "building");
	iEngineer = GetEventInt(hEvent, "healer");
	iAmount = GetEventInt(hEvent, "amount");

	// From the bulding_healed event, we get the object repaired, the engineer and the amount healed.
	// We use this for verification purposes.
	if (IsValidClient(iEngineer) && g_bEnablePlugin.BoolValue)
	{
		iRescueRangerHeal_Object = iObject;
		iRescueRangerHeal_Enginner = iEngineer;
		iRescueRangerHeal_Amount = iAmount;
	}
	else
	{
		iRescueRangerHeal_Object = -1;
		iRescueRangerHeal_Enginner = -1;
		iRescueRangerHeal_Amount = -1;
	}
}

public void OverhealLimitHook(int iClient)
{
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Medic)
	{
		// medigun weapon, if it's healing, who we're healing and if we're holding the mouse button.
		int iMedigun,  /*iHealing,*/ iHealingTarget, /*iAttacking,*/ iMelee, iMeleeIndex, iActiveWeapon = -1;
		iMedigun = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
		// iHealing = GetEntProp(iMedigun, Prop_Send, "m_bHealing");
		iHealingTarget = GetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget");
		// iAttacking = GetEntProp(iMedigun, Prop_Send, "m_bAttacking");
		
		// PrintCenterText(iClient, "iHealingTarget: %i\niHealing: %i\niAttacking: %i", iHealingTarget, iHealing, iAttacking);
		
		if (IsValidClient(iHealingTarget)) // we verify we're healing a good boy or gal
		{
			TF2Attrib_RemoveByName(iMedigun, "overheal penalty");
			TF2Attrib_RemoveByName(iMedigun, "heal rate penalty");
			
			int iNumHealers = GetEntProp(iHealingTarget, Prop_Send, "m_nNumHealers");
		
			if (TF2_GetPlayerClass(iHealingTarget) == TFClass_Heavy)
			{
				// melee weapon, item definition index of melee and target's active weapon.
				iMelee = GetPlayerWeaponSlot(iHealingTarget, TFWeaponSlot_Melee);
				if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
				iActiveWeapon = GetEntPropEnt(iHealingTarget, Prop_Send, "m_hActiveWeapon");
				
				// Fists of Steel and we make sure it's the active melee.
				if (iMeleeIndex == FISTSSTEEL) 
				{
					/* Fist of Steel
					Changes:
					Added: 40% overheal reduction while active
					Added: 40% healing rate penalty while active */
					
					// We set the attributes.
					TF2Attrib_SetByName(iMedigun, "overheal penalty", 0.60);
					TF2Attrib_SetByName(iMedigun, "heal rate penalty", 0.60);
				}
			}
			else if (TF2_GetPlayerClass(iHealingTarget) == TFClass_Sniper)
			{
				int iRazorback = GetPlayerWearableEntityIndex(iHealingTarget, "tf_wearable", RAZORBACK); // Razorback, of course.
				
				/* Razorback
				Added: -100% overheal penalty */
				if (iRazorback != -1) TF2Attrib_SetByName(iMedigun, "overheal penalty", 0.00);
			}
			
			// We make sure the buffs (or rather, nerfs) are properly applied:
			// 1.- The first time, when the bool is false, we set it to true while we reapply the healing target.
			// 2.- Later, we compare the last with the current healing target to reapply the healing target.
			// We do this because we want to apply the attributes put on the medigun, else it won't work.
			if (/* !bMedigunChangedBuffs[iClient] ||*/ iMedigunBuffedTarget[iClient] != iHealingTarget ||
			iMedigunTargetWeapon[iClient] != iActiveWeapon)
			{	
				// PrintToConsole(iClient, "buffs applied. %i = %i. %i = %i.", iMedigunBuffedTarget[iClient], iHealingTarget, iMedigunTargetWeapon[iClient], iActiveWeapon);
				
				iMedigunBuffedTarget[iClient] = iHealingTarget; // We save the healing target.
				iMedigunTargetWeapon[iClient] = iActiveWeapon;
				
				// We say no no to heals for now until 0.1 seconds later.
				SetEntProp(iMedigun, Prop_Send, "m_bAttacking", 0);
				SetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget", 0);
				SetEntProp(iMedigun, Prop_Send, "m_bHealing", 0);
				SetEntProp(iHealingTarget, Prop_Send, "m_nNumHealers", iNumHealers - 1);
				TF2_RemoveCondition(iMedigunBuffedTarget[iClient], TFCond_Healing);
				
				// For the timer which will reapply the healing target to be the same one, we
				// take the medigun entindex with us which later gets us the client.
				CreateTimer(0.1, RehealTarget, iMedigun); // magic (check timer comments).
				
				// For the first heal we set this to true until we don't heal anybody.
				//bMedigunChangedBuffs[iClient] = true; 
			}
		}
		//else bMedigunChangedBuffs[iClient] = false; // if not healing a good boye
		// then we cannot (and won't) change the medigun based on target, so it's false.
	}
	else
	{
		iMedigunBuffedTarget[iClient] = -1;
		iMedigunTargetWeapon[iClient] = -1;
	}
}

public Action RehealTarget(Handle timer, int iMedigun)
{
	// The client.
	int iClient = GetEntPropEnt(iMedigun, Prop_Send, "m_hOwner");
	
	if (IsValidClient(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Medic) // Validation, of course.
	{	
		// We set it to be the same player again. 
		TF2_AddCondition(iMedigunBuffedTarget[iClient], TFCond_Healing, _, iClient);
		SetEntProp(iMedigun, Prop_Send, "m_bHealing", 1);
		SetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget", iMedigunBuffedTarget[iClient]);
		SetEntProp(iMedigun, Prop_Send, "m_bAttacking", 1);
	}
}

public void StunFlagChanges(int iClient, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float fDamageForce[3], const float fDamagePosition[3], int iDamageCustom)
{
	if (IsValidClient(iClient) && IsValidClient(iAttacker))
	{	
		if (iDamageCustom == TF_CUSTOM_BASEBALL)
		{
			int iStunFlags = GetEntProp(iClient, Prop_Send, "m_iStunFlags");
			if ((iStunFlags & TF_STUNFLAG_THIRDPERSON) == TF_STUNFLAG_THIRDPERSON) iStunFlags &= ~TF_STUNFLAG_THIRDPERSON;
			if ((iStunFlags & TF_STUNFLAG_BONKSTUCK) == TF_STUNFLAG_BONKSTUCK) iStunFlags &= ~TF_STUNFLAG_BONKSTUCK;
			SetEntProp(iClient, Prop_Send, "m_iStunFlags", iStunFlags);
		}
	}
}

public Action DamageStuff(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iWeapon, float fDamageForce[3], float fDamagePosition[3], int iDamageCustom)
{
	if (IsValidClient(iClient) && IsValidClient(iAttacker))
	{	
		if (iDamageCustom == TF_CUSTOM_BASEBALL)
		{	
			int iStunFlags = GetEntProp(iClient, Prop_Send, "m_iStunFlags");
			if ((iStunFlags & TF_STUNFLAG_CHEERSOUND) == TF_STUNFLAG_CHEERSOUND) fDamage *= 1.5;	
		}
		if (iDamageCustom == TF_CUSTOM_CLEAVER_CRIT && !TF2_IsPlayerInCondition(iAttacker, TFCond_Buffed))
			fDamage *= 0.74;
	}
	
	return Plugin_Changed;
}

public void TF2_OnConditionAdded(int iClient, TFCond iCondition)
{
	if (IsValidClient(iClient) && g_bEnablePlugin.BoolValue)
	{
		switch (iCondition)
		{
			case TFCond_Parachute:
			{
				// B.A.S.E Jumper
				// Changes:
				// Reduced amount of air control while deployed by 50%
				// Removed the ability to re-deploy the parachute once retracted (until the player lands on the ground again)
				TF2Attrib_SetByName(iClient, "increased air control", 0.50); // meant to be 50 percent less
			}
			case TFCond_Disguised:
			{
				// melee weapon:
				int iMelee, iMeleeIndex = -1;
				iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
				if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
				
				float fCloak = GetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter");
				
				// Your Eternal Reward
				// Changes:
				// Added: Non-kill disguises require (and consume) a full cloak meter
					
				if (!bYERSpyGracePeriod[iClient])
				{
					if ((iMeleeIndex == YER || iMeleeIndex == WANGA_PRICK) && fCloak >= 100.0)
					{
						SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", 0.000001);
					}
					else TF2_RemoveCondition(iClient, TFCond_Disguised);
				}
			}
		}
	}
}

public void TF2_OnConditionRemoved(int iClient, TFCond iCondition)
{
	if (IsValidClient(iClient) && g_bEnablePlugin.BoolValue)
	{
		switch (iCondition)
		{
			case TFCond_Parachute:
			{
				if ((GetEntityFlags(iClient) & FL_ONGROUND) != FL_ONGROUND)
				{
					TF2_AddCondition(iClient, TFCond_Parachute, TFCondDuration_Infinite, iClient);
				}
				else TF2Attrib_RemoveByName(iClient, "increased air control"); // We reset the attribute given to the client
			}
		}
	}
}

public Action CreateBalanceMenu(int iClient)
{
	Handle hMenu = CreatePanel();

	char cChanges[2000] = "Here are the changes done to your weapons:\n(You can display this menu with /info or toggle its appareance with /infotoggle)\n";
	
	if (IsValidClient(iClient) && IsPlayerAlive(iClient))
	{
		int iPrimary, iPrimaryIndex, iSecondary, iSecondaryIndex, iMelee, iMeleeIndex, iBuilding, iBuildingIndex = -1;
		
		TFClassType iClass = TF2_GetPlayerClass(iClient);
		
		// primary weapon:
		iPrimary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
		if (iPrimary != -1) iPrimaryIndex = GetEntProp(iPrimary, Prop_Send, "m_iItemDefinitionIndex");
		
		// secondary weapon:
		iSecondary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
		if (iSecondary != -1) iSecondaryIndex = GetEntProp(iSecondary, Prop_Send, "m_iItemDefinitionIndex");
		
		// melee weapon:
		iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
		if (iMelee != -1) iMeleeIndex = GetEntProp(iMelee, Prop_Send, "m_iItemDefinitionIndex");
		
		// building weapon:
		if (iClass == TFClass_Spy)
		{
			iBuilding = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Building);
			if (iBuilding != -1) iBuildingIndex = GetEntProp(iBuilding, Prop_Send, "m_iItemDefinitionIndex");
		}
		
		switch (iPrimaryIndex)
		{
			case RESCUE_RANGER:
			{
				StrCat(cChanges, sizeof(cChanges), "Rescue Ranger:\n- Ranged repairs now consume metal (at a 4-to-1 health-to-metal ratio)\n");
			}
			case PANIC_ATTACK:
			{
				StrCat(cChanges, sizeof(cChanges), "Panic Attack:\n- 50% faster switch to speed\n- 50% more pellets\n- 30% less damage\n- Shot pattern grows with succesive shots.\n");
			}
			/*
			default:
			{
				Format(cChanges, sizeof(cChanges), "%sYour primary weapon has no changes.\n", cChanges);
			}
			*/
		}
		if (GetPlayerWearableEntityIndex(iClient, "tf_weapon_parachute", 1101) != -1)
		{
			StrCat(cChanges, sizeof(cChanges), "B.A.S.E. Jumper:\n- Reduced amount of air control while deployed by 50%\n- Removed the ability to re-deploy the parachute once retracted.\n");		
		}
		
		switch (iSecondaryIndex)
		{
			case PANIC_ATTACK:
			{
				StrCat(cChanges, sizeof(cChanges), "Panic Attack:\n- 50% faster switch to speed\n- 50% more pellets\n- 30% less damage\n- Shot pattern grows with succesive shots.\n");			
			}
			case PRETTYPISTOL:
			{
				StrCat(cChanges, sizeof(cChanges), "Pretty Boy's Pocket Pistol:\n- +15% firing speed\n- Up to +7 hp per hit\n- -25% clip size (9 shots).\n");				
			}
			case GUILLOTINE, GUILLOTINE_PROMO:
			{
				StrCat(cChanges, sizeof(cChanges), "Flying Guillotine: Removed crits vs. stunned players and mini-crits at long range (sort of).\n");		
			}
			/*
			default:
			{
				Format(cChanges, sizeof(cChanges), "Your secondary weapon has no changes.\n", cChanges);
			}
			*/
		}

		if (GetPlayerWearableEntityIndex(iClient, "tf_weapon_parachute", BASE_JUMPER) != -1)
		{
			StrCat(cChanges, sizeof(cChanges), "B.A.S.E. Jumper:\n- Reduced amount of air control while deployed by 50%\n- Removed the ability to re-deploy the parachute once retracted.\n");			
		}
		else if (GetPlayerWearableEntityIndex(iClient, "tf_wearable", MANTREADS) != -1)
		{
			StrCat(cChanges, sizeof(cChanges), "Mantreads:\n- +75% push-force reduction now includes airblast\n- +200% air control when blast jumping.\n");				
		}
		else if (GetPlayerWearableEntityIndex(iClient, "tf_wearable", DARWINS_SHIELD) != -1)
		{
			StrCat(cChanges, sizeof(cChanges), "Darwin's Danger Shield:\n- Afterburn immunity\n- +50% fire resist.\n");	
		}
		else if (GetPlayerWearableEntityIndex(iClient, "tf_wearable", RAZORBACK) != -1)
		{
			StrCat(cChanges, sizeof(cChanges), "Razorback: -100% overheal penalty.\n");			
		}
		
		switch (iMeleeIndex)
		{
			case YER, WANGA_PRICK:
			{
				StrCat(cChanges, sizeof(cChanges), "YER/Wanga Prick:\n- Removed 'cannot disguise' penalty\n- Non-kill disguises require (and consume) a full meter, but backstab-based disguises are still free\n- Increased cloak drain rate by 50%.\n");				
			}
			case SANDMAN:
			{
				StrCat(cChanges, sizeof(cChanges), "Sandman:\n- Long-range ball impacts no longer remove the victim's ability to fire their weapon (but the victim is still slowed)\n- Max range balls now do 50% increased damage.\n");				
			}
			case ATOMIZER:
			{
				StrCat(cChanges, sizeof(cChanges), "Atomizer:\n- Triple jump is now only possible while the bat is deployed\n- Removed attack speed penalty and self-inflicted damage when triple-jumping\n- Melee attacks done while airborne mini-crit\n- 50% deploy time penalty\n- Reduced damage penalty vs players to -15%.\n");			
			}
			case VITASAW:
			{
				StrCat(cChanges, sizeof(cChanges), "Vita-saw:\n- Each hit with the Vita-Saw spawns an organ which you can collect.\n- For each organ, on-death, preserve 15% ubercharge (caps at 60%).\n");		
			}
			case GRU, GRU_FESTIVE:
			{
				StrCat(cChanges, sizeof(cChanges), "GRU:\n- Max health is drained while item is active (-10/sec) and regenerated while holstered.\n- Health will regenerate only the amount drained while active, minus damage taken during that time.\n- Each time the gloves are deployed, the drain rate is accelerated for a brief period of time.\n- Removed Marked-For-Death effect while active and 25% damage penalty.\n");					
			}
			case EVICTION_NOTICE:
			{
				StrCat(cChanges, sizeof(cChanges), "Eviction Notice: Max health is drained while item is active (-5/sec) and regenerated while holstered.\n- Health will regenerate only the amount drained while active, minus damage taken during that time.\n- Each time the gloves are deployed, the drain rate is accelerated for a brief period of time.\n- Removed 20% damage vulnerability.\n");					
			}
			case FISTSSTEEL:
			{
				StrCat(cChanges, sizeof(cChanges), "Fists of Steel: Added 40% overheal reduction and healing rate penalty on wearer.\n");
			}
			/*
			default:
			{
				StrCat(cChanges, sizeof(cChanges), "Your melee weapon has no changes.\n");				
			}
			*/
		}
		
		if (iBuildingIndex == DEAD_RINGER)
		{
			StrCat(cChanges, sizeof(cChanges), "Dead Ringer: Ammo kits and dispensers no longer refill the Spy's cloak meter.\n");		
		}
	}

	if (!StrEqual(cChanges, "Here are the changes done to your weapons:\n(You can display this menu with /info or toggle its appareance with /infotoggle)\n", false))
	{
		DrawPanelText(hMenu, cChanges);
		cChanges = "Got it";
		DrawPanelItem(hMenu, cChanges);
		
		SendPanelToClient(hMenu, iClient, BalancePanel, 30);	
	}

	CloseHandle(hMenu);
	return Plugin_Continue;
}

public int BalancePanel(Handle hMenu, MenuAction maAction, int param1, int param2)
{
	if (!IsValidClient(param1)) return;
	if (maAction == MenuAction_Select || (maAction == MenuAction_Cancel && param2 == MenuCancel_Exit)) return;
	return;
}

stock int GetPlayerWearableEntityIndex(int iClient, const char[] cClassname, int iWearable)
{
	int WearableItem = -1;
	
	while((WearableItem = FindEntityByClassname(WearableItem, cClassname)) != -1)
	{
		int WearableIndex = GetEntProp(WearableItem, Prop_Send, "m_iItemDefinitionIndex");
		int WearableOwner = GetEntPropEnt(WearableItem, Prop_Send, "m_hOwnerEntity");
		if(WearableOwner == iClient && WearableIndex == iWearable) return WearableItem;
	}
	
	return WearableItem;
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}