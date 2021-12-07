#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#undef REQUIRE_PLUGIN
#tryinclude <ff2_dynamic_defaults>
#define REQUIRE_PLUGIN

public Plugin myinfo = {
	name	= "Freak Fortress 2: The Witch Doctor",
	author	= "Deathreus",
	version = "1.0"
};

#define IsEmptyString(%1) (%1[0]==0)
#define FAR_FUTURE 100000000.0

#define HUD_INTERVAL 0.2
#define HUD_LINGER 0.01
#define HUD_ALPHA 192
#define HUD_R_OK 255
#define HUD_G_OK 255
#define HUD_B_OK 255
#define HUD_R_ERROR 225
#define HUD_G_ERROR 64
#define HUD_B_ERROR 64

int MJT_ButtonType;		// Shared between Magic Jump and Magic Teleport as 4th argument, or Jump Manager as 2nd

/* Rage_SkeleSummon */
int SkeleNumberOfSpawns[MAXPLAYERS+1];				// 1

/* Charge_MagicJump */			// Intended for gaining height
float MJ_ChargeTime[MAXPLAYERS+1];					// 1
float MJ_Cooldown[MAXPLAYERS+1];					// 2
float MJ_OnCooldownUntil[MAXPLAYERS+1];				// Internal, set by arg3
float MJ_CrouchOrAltFireDownSince[MAXPLAYERS+1];	// Internal

bool MJ_EmergencyReady[MAXPLAYERS+1];				// Internal

/* Charge_MegicTele */			// Intended for catching fast players
float MT_ChargeTime[MAXPLAYERS+1];					// 1
float MT_Cooldown[MAXPLAYERS+1];					// 2
float MT_OnCooldownUntil[MAXPLAYERS+1];				// Internal, set by arg3
float MT_CrouchOrAltFireDownSince[MAXPLAYERS+1];	// Internal

bool MT_EmergencyReady[MAXPLAYERS+1];				// Internal

/* Special_JumpManager */
int JM_ButtonType;									// 1

bool JM_AbilitySwitched[MAXPLAYERS+1];				// Internal

float WitchDoctorUpdateHUD[MAXPLAYERS+1];			// Internal

Handle witchdoctorHUD;

/* Special_SpellAttack */
float SS_CoolDown[MAXPLAYERS+1];					// 1

/* Ability_Management_System */
bool Orb_TriggerAMS[MAXPLAYERS+1];
bool Meteor_TriggerAMS[MAXPLAYERS+1];
bool Monoculus_TriggerAMS[MAXPLAYERS+1];
bool Invis_TriggerAMS[MAXPLAYERS+1];
bool Minify_TriggerAMS[MAXPLAYERS+1];
bool Bats_TriggerAMS[MAXPLAYERS+1];
bool Horde_TriggerAMS[MAXPLAYERS+1];
bool Meras_TriggerAMS[MAXPLAYERS+1];
bool Horse_TriggerAMS[MAXPLAYERS+1];
bool Fireball_TriggerAMS[MAXPLAYERS+1];

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_Post);
	
	witchdoctorHUD = CreateHudSynchronizer();
	
	if(FF2_GetRoundState()==1)	// Late-load
	{
		HookAbilities();
	}
}

public void Event_RoundStart(Event hEvent, const char[] strName, bool bDontBroadcast)
{	
	int iBoss;
	for(int iIndex = 0; (iBoss=GetClientOfUserId(FF2_GetBossUserId(iIndex)))>0; iIndex++)
	{
		if(FF2_HasAbility(iIndex, this_plugin_name, "special_jumpmanager"))
		{
			JM_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "special_jumpmanager", 1);	// Button for activation, 1 = reload, 2 = special attack, 3 = secondary attack
			MJT_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "special_jumpmanager", 2);		// Button for activation, 1 = secondary attack, 2 = reload, 3 = special attack
			
			MJ_ChargeTime[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 3);		// Time it takes to charge
			MJ_Cooldown[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 4);		// Time it takes to refresh
			MJ_OnCooldownUntil[iBoss] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 5);	// Time before first use
			
			MT_ChargeTime[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 6);		// Time it takes to charge
			MT_Cooldown[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 7);		// Time it takes to refresh
			MT_OnCooldownUntil[iBoss] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 8);	// Time before first use
			
			MJ_CrouchOrAltFireDownSince[iBoss] = FAR_FUTURE;
			MT_CrouchOrAltFireDownSince[iBoss] = FAR_FUTURE;
			
			SpawnWeapon(iBoss, "tf_weapon_spellbook", 1069, 0, 0, "");
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "charge_magicjump"))
		{
			MJ_ChargeTime[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magicjump", 1);		// Time it takes to charge
			MJ_Cooldown[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magicjump", 2);		// Time it takes to refresh
			MJ_OnCooldownUntil[iBoss] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magicjump", 3);	// Time before first use
			MJT_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "charge_magicjump", 4);	// Button for activation, 1 = secondary attack, 2 = reload, 3 = special attack
			
			MJ_CrouchOrAltFireDownSince[iBoss] = FAR_FUTURE;
			
			SpawnWeapon(iBoss, "tf_weapon_spellbook", 1069, 0, 0, "");
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "charge_magictele"))
		{
			MT_ChargeTime[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magictele", 1);		// Time it takes to charge
			MT_Cooldown[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magictele", 2);		// Time it takes to refresh
			MT_OnCooldownUntil[iBoss] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magictele", 3);	// Time before first use
			MJT_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "charge_magictele", 4);	// Button for activation, 1 = secondary attack, 2 = reload, 3 = special attack
			
			MT_CrouchOrAltFireDownSince[iBoss] = FAR_FUTURE;
			
			SpawnWeapon(iBoss, "tf_weapon_spellbook", 1069, 0, 0, "");
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "special_spellattack"))
		{
			SS_CoolDown[iBoss] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_spellattack", 1);
			
			for(int i=1; i<=MaxClients; i++) if(IsValidClient(i))
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_bats"))
		{
			Bats_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_bats", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Bats_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_bats", "BATS"); // Important function to tell AMS that this subplugin supports it
			}
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_orb"))
		{
			Orb_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_orb", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Orb_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_orb", "ORB"); // Important function to tell AMS that this subplugin supports it
			}
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_meteor"))
		{
			Meteor_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_meteor", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Meteor_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_meteor", "MET"); // Important function to tell AMS that this subplugin supports it
			}
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_invis"))
		{
			Invis_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_invis", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Invis_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_invis", "INV"); // Important function to tell AMS that this subplugin supports it
			}
			SpawnWeapon(iBoss, "tf_weapon_spellbook", 1069, 0, 0, "");
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_minify"))
		{
			Minify_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_minify", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Minify_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_minify", "MINI"); // Important function to tell AMS that this subplugin supports it
			}
			SpawnWeapon(iBoss, "tf_weapon_spellbook", 1069, 0, 0, "");
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_mono"))
		{
			Monoculus_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_mono", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Monoculus_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_mono", "MONO"); // Important function to tell AMS that this subplugin supports it
			}
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_horde"))
		{
			Horde_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_horde", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Horde_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_horde", "HORD"); // Important function to tell AMS that this subplugin supports it
			}
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_meras"))
		{
			Meras_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_meras", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Meras_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_meras", "MERA"); // Important function to tell AMS that this subplugin supports it
			}
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_horse"))
		{
			Horse_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_horse", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Horse_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_horse", "HORS"); // Important function to tell AMS that this subplugin supports it
			}
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_fireball"))
		{
			Fireball_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_fireball", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Fireball_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_fireball", "FIRE"); // Important function to tell AMS that this subplugin supports it
			}
		}
		
		SDKHook(iBoss, SDKHook_OnTakeDamage, CheckEnvironmentalDamage);
	}
}

public void Event_RoundEnd(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		MJ_EmergencyReady[iClient] = false;
		MT_EmergencyReady[iClient] = false;
		JM_AbilitySwitched[iClient] = false;
		
		Orb_TriggerAMS[iClient] = false;
		Meteor_TriggerAMS[iClient] = false;
		Monoculus_TriggerAMS[iClient] = false;
		Invis_TriggerAMS[iClient] = false;
		Minify_TriggerAMS[iClient] = false;
		Bats_TriggerAMS[iClient] = false;
		Horde_TriggerAMS[iClient] = false;
		Meras_TriggerAMS[iClient] = false;
		Horse_TriggerAMS[iClient] = false;
		Fireball_TriggerAMS[iClient] = false;
		
		if(IsValidClient(iClient))
		{
			SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(iClient, SDKHook_OnTakeDamage, CheckEnvironmentalDamage);
		}
	}
}

public void HookAbilities()
{
	for(int iClient=1; iClient <= MaxClients; iClient++)
	{
		if(!IsValidClient(iClient))
			return;
		
		Orb_TriggerAMS[iClient] = false;
		Meteor_TriggerAMS[iClient] = false;
		Monoculus_TriggerAMS[iClient] = false;
		Invis_TriggerAMS[iClient] = false;
		Minify_TriggerAMS[iClient] = false;
		Bats_TriggerAMS[iClient] = false;
		Horde_TriggerAMS[iClient] = false;
		Meras_TriggerAMS[iClient] = false;
		Horse_TriggerAMS[iClient] = false;
		Fireball_TriggerAMS[iClient] = false;
		
		int iIndex = FF2_GetBossIndex(iClient);
		if(iIndex>=0)
		{
			if(FF2_HasAbility(iIndex, this_plugin_name, "special_jumpmanager"))
			{
				JM_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "special_jumpmanager", 1);	// Button for activation, 1 = reload, 2 = special attack, 3 = secondary attack
				MJT_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "special_jumpmanager", 2);		// Button for activation, 1 = secondary attack, 2 = reload, 3 = special attack
			
				MJ_ChargeTime[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 3);		// Time it takes to charge
				MJ_Cooldown[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 4);		// Time it takes to refresh
				MJ_OnCooldownUntil[iClient] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 5);	// Time before first use
			
				MT_ChargeTime[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 6);		// Time it takes to charge
				MT_Cooldown[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 7);		// Time it takes to refresh
				MT_OnCooldownUntil[iClient] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_jumpmanager", 8);	// Time before first use
			
				SpawnWeapon(iClient, "tf_weapon_spellbook", 1069, 0, 0, "");
			}
		
			if(FF2_HasAbility(iIndex, this_plugin_name, "charge_magicjump"))
			{
				MJ_ChargeTime[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magicjump", 1);		// Time it takes to charge
				MJ_Cooldown[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magicjump", 2);		// Time it takes to refresh
				MJ_OnCooldownUntil[iClient] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magicjump", 3);	// Time before first use
				MJT_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "charge_magicjump", 4);	// Button for activation, 1 = secondary attack, 2 = reload, 3 = special attack
			
				SpawnWeapon(iClient, "tf_weapon_spellbook", 1069, 0, 0, "");
			}
		
			if(FF2_HasAbility(iIndex, this_plugin_name, "charge_magictele"))
			{
				MT_ChargeTime[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magictele", 1);		// Time it takes to charge
				MT_Cooldown[iClient] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magictele", 2);		// Time it takes to refresh
				MT_OnCooldownUntil[iClient] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "charge_magictele", 3);	// Time before first use
				MJT_ButtonType = FF2_GetAbilityArgument(iIndex, this_plugin_name, "charge_magictele", 4);	// Button for activation, 1 = secondary attack, 2 = reload, 3 = special attack
			
				SpawnWeapon(iClient, "tf_weapon_spellbook", 1069, 0, 0, "");
			}
		
			if(FF2_HasAbility(iIndex, this_plugin_name, "special_spellattack"))
			{
				SS_CoolDown[iClient] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_spellattack", 1);
			
				for(int i=1; i<=MaxClients; i++)
					SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_orb"))
			{
				Orb_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_orb", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Orb_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_orb", "ORB"); // Important function to tell AMS that this subplugin supports it
				}
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_meteor"))
			{
				Meteor_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_meteor", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Meteor_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_meteor", "MET"); // Important function to tell AMS that this subplugin supports it
				}
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_mono"))
			{
				Monoculus_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_mono", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Monoculus_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_mono", "MONO"); // Important function to tell AMS that this subplugin supports it
				}
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_invis"))
			{
				Invis_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_invis", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Invis_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_invis", "INV"); // Important function to tell AMS that this subplugin supports it
				}
				SpawnWeapon(iClient, "tf_weapon_spellbook", 1069, 0, 0, "");
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_minify"))
			{
				Minify_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_minify", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Minify_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_minify", "MINI"); // Important function to tell AMS that this subplugin supports it
				}
				SpawnWeapon(iClient, "tf_weapon_spellbook", 1069, 0, 0, "");
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_bats"))
			{
				Bats_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_bats", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Bats_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_bats", "BATS"); // Important function to tell AMS that this subplugin supports it
				}
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_horde"))
			{
				Horde_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_horde", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Horde_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_horde", "HORDE"); // Important function to tell AMS that this subplugin supports it
				}
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_meras"))
			{
				Meras_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_meras", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Meras_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_meras", "MERAS"); // Important function to tell AMS that this subplugin supports it
				}
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_horse"))
			{
				Horse_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_horse", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Horse_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_horse", "HORSE"); // Important function to tell AMS that this subplugin supports it
				}
			}
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_fireball"))
			{
				Fireball_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_fireball", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Fireball_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_fireball", "FIRE"); // Important function to tell AMS that this subplugin supports it
				}
			}
		
			SDKHook(iClient, SDKHook_OnTakeDamage, CheckEnvironmentalDamage);
		}
	}
}

public void FF2_OnAbility2(int iBoss, const char[] pluginName, const char[] abilityName, int iStatus)
{
	int iClient = GetClientOfUserId(FF2_GetBossUserId(iBoss));
	if (!strcmp(abilityName, "rage_orb"))
		Rage_Orb(iClient);
	else if (!strcmp(abilityName, "rage_meteor"))
		Rage_Meteor(iClient);
	else if (!strcmp(abilityName, "rage_invis"))
		Rage_Invis(iClient);
	else if (!strcmp(abilityName, "rage_minify"))
		Rage_Minify(iClient);
	else if (!strcmp(abilityName, "rage_bats"))
		Rage_Bats(iClient);
	else if (!strcmp(abilityName, "rage_horde"))
		Rage_Horde(iClient);
	else if (!strcmp(abilityName, "rage_mono"))
		Rage_Monoculus(iClient);
	else if (!strcmp(abilityName, "rage_meras"))
		Rage_Merasmus(iClient);
	else if (!strcmp(abilityName, "rage_horse"))
		Rage_Horsemann(iClient);
	else if (!strcmp(abilityName, "rage_fireball"))
		Rage_Fireball(iClient);
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float flVel[3], float flAng[3], int &iWep)
{
	int iBoss = GetClientOfUserId(FF2_GetBossUserId(iClient));
	
	if(!IsValidClient(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	if(FF2_HasAbility(iBoss, this_plugin_name, "special_jumpmanager") && GetClientTeam(iClient) == FF2_GetBossTeam())
	{
		if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
			return Plugin_Continue;
			
		JM_Tick(iClient, iButtons, GetEngineTime());
		
		char Button;
		switch(JM_ButtonType)
		{
			case 1: Button = IN_RELOAD;
			case 2: Button = IN_ATTACK3;
			case 3: Button = IN_ATTACK2;
		}
		
		if(iButtons & Button)
		{
			if(!JM_AbilitySwitched[iClient]) 
				JM_AbilitySwitched[iClient] = true;
			else JM_AbilitySwitched[iClient] = false;
		}
	}
	
	if(FF2_HasAbility(iBoss, this_plugin_name, "charge_magicjump") && GetClientTeam(iClient) == FF2_GetBossTeam())
	{
		if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
			return Plugin_Continue;
			
		MJ_Tick(iClient, iButtons, GetEngineTime());
	}
	
	if(FF2_HasAbility(iBoss, this_plugin_name, "charge_magictele") && GetClientTeam(iClient) == FF2_GetBossTeam())
	{
		if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
			return Plugin_Continue;
			
		MT_Tick(iClient, iButtons, GetEngineTime());
	}
	
	if(FF2_HasAbility(iBoss, this_plugin_name, "special_spellattack") && GetClientTeam(iClient) == FF2_GetBossTeam())
	{
		if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
			return Plugin_Continue;
		
		if(iButtons & IN_ATTACK)
		{
			if(GetEngineTime() >= SS_CoolDown[iClient])
			{
				ShootProjectile(iClient, "tf_projectile_spellfireball");
				SS_CoolDown[iClient] = GetEngineTime() + FF2_GetAbilityArgumentFloat(iBoss, this_plugin_name, "special_spellattack", 1);
				
				float position[3];
				GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", position);
				
				char sound[PLATFORM_MAX_PATH];
				if (FF2_RandomSound("sound_ability", sound, PLATFORM_MAX_PATH, iBoss, 4))
				{
					EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
					EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);

					for (int enemy = 1; enemy < MaxClients; enemy++)
					{
						if (IsClientInGame(enemy) && enemy != iClient)
						{
							EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
							EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
						}
					}
				}
			}
			else iButtons &= ~IN_ATTACK;
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &flDamage, int &iDamagetype, int &iWeapon, float flDamageForce[3], float flDamagePosition[3], int iDamageCustom)
{	
	if (!IsValidClient(iAttacker) || GetClientTeam(iAttacker)!=FF2_GetBossTeam())
		return Plugin_Continue;	
	int iBoss = FF2_GetBossIndex(iAttacker);
	
	if(FF2_HasAbility(iBoss, this_plugin_name, "special_spellattack"))
	{
		flDamage *= 0.2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:CheckEnvironmentalDamage(int iClient, int &iAttacker, int &iInflictor, float &flDmg, int &DmgType, int &iWep, float flDmgForce[3], float flDmgPos[3], int DmgCstm)
{
	if (!IsValidClient(iClient, true))
		return Plugin_Continue;

	if (iAttacker == 0 && iInflictor == 0 && (DmgType & DMG_FALL) != 0)
		return Plugin_Continue;
		
	// ignore damage from players
	if (iAttacker >= 1 && iAttacker <= MaxClients)
		return Plugin_Continue;
	
	int iBoss = GetClientOfUserId(FF2_GetBossUserId(iClient));
	
	if (FF2_HasAbility(iBoss, this_plugin_name, "charge_magicjump") || FF2_HasAbility(iBoss, this_plugin_name, "special_jumpmanager"))
	{
		if (flDmg > 50.0)
		{
			MJ_EmergencyReady[iClient] = true;
			MJ_OnCooldownUntil[iClient] = FAR_FUTURE;
		}
	}

	if (FF2_HasAbility(iBoss, this_plugin_name, "charge_magictele") || FF2_HasAbility(iBoss, this_plugin_name, "special_jumpmanager"))
	{
		if (flDmg > 50.0)
		{
			MT_EmergencyReady[iClient] = true;
			MT_OnCooldownUntil[iClient] = FAR_FUTURE;
		}
	}
	
	return Plugin_Continue;
}

public bool BATS_CanInvoke(int iClient)
{
	return true;
}

void Rage_Bats(int iClient)
{
	if(Bats_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	BATS_Invoke(iClient);
}

public void BATS_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Bats_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_bats_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	ShootProjectile(iClient, "tf_projectile_spellbats");
}

public bool ORB_CanInvoke(int iClient)
{
	return true;
}

void Rage_Orb(int iClient)
{
	if(Orb_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	ORB_Invoke(iClient);
}

public void ORB_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Orb_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_orb_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	ShootProjectile(iClient, "tf_projectile_lightningorb");
}

public bool MET_CanInvoke(int iClient)
{
	return true;
}

void Rage_Meteor(int iClient)
{
	if(Meteor_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	MET_Invoke(iClient);
}

public void MET_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Meteor_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_meteor_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	ShootProjectile(iClient, "tf_projectile_spellmeteorshower");
}

public bool MINI_CanInvoke(int iClient)
{
	return true;
}

void Rage_Minify(int iClient)
{
	if(Minify_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	MINI_Invoke(iClient);
}

public void MINI_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Minify_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_minify_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	int spellbook = FindSpellBook(iClient);
	SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 8);
	SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
	FakeClientCommand(iClient, "use tf_weapon_spellbook");
}

public bool INV_CanInvoke(int iClient)
{
	return true;
}

void Rage_Invis(int iClient)
{
	if(Invis_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	INV_Invoke(iClient);
}

public void INV_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Invis_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_invisibility_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	int spellbook = FindSpellBook(iClient);
	SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 5);
	SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
	FakeClientCommand(iClient, "use tf_weapon_spellbook");
}

public bool MONO_CanInvoke(int iClient)
{
	return true;
}

void Rage_Monoculus(int iClient)
{
	if(Monoculus_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	MONO_Invoke(iClient);
}

public void MONO_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Monoculus_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_monoculus_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	ShootProjectile(iClient, "tf_projectile_spellspawnboss");
}

public bool HORDE_CanInvoke(int iClient)
{
	return true;
}

void Rage_Horde(int iClient)
{
	if(Horde_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	HORDE_Invoke(iClient);
}

public void HORDE_Invoke(int iClient)
{
	int iBoss = FF2_GetBossIndex(iClient);
	
	if(Horde_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_skeleton_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	SkeleNumberOfSpawns[iClient] = FF2_GetAbilityArgument(iBoss, this_plugin_name, "rage_horde", 2);
	SDKHook(ShootProjectile(iClient, "tf_projectile_spellspawnhorde"), SDKHook_StartTouch, Projectile_Touch);
}

public bool MERAS_CanInvoke(int iClient)
{
	for(int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if(iClient == iVictim || !IsValidClient(iVictim))
			continue;
			
		float flAngles[3], flOrigin[3], flEnd[3];
		GetClientEyePosition(iClient, flOrigin);
		GetClientEyeAngles(iClient, flAngles);
		
		Handle TraceRay = TR_TraceRayFilterEx(flOrigin, flAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		
		if(TR_DidHit(TraceRay))
			TR_GetEndPosition(flEnd, TraceRay);
		
		delete TraceRay;
		
		float victimOrigin[3];
		GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", victimOrigin);
		
		if(CylinderCollision(flEnd, victimOrigin, 225.0, flEnd[2] - 350.0, flEnd[2] - 0.01))
		{
			PrintCenterText(iClient, "Location blocked by player(s)!");
			return false;
		}
	}
	
	return true;
}

void Rage_Merasmus(int iClient)
{
	if(Meras_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	MERAS_Invoke(iClient);
}

public void MERAS_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Meras_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_merasmus_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	EntCreate(iClient, "merasmus");
}

public bool HORSE_CanInvoke(int iClient)
{
	for(int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if(iClient == iVictim || !IsValidClient(iVictim))
			continue;
			
		float flAngles[3], flOrigin[3], flEnd[3];
		GetClientEyePosition(iClient, flOrigin);
		GetClientEyeAngles(iClient, flAngles);
		
		Handle TraceRay = TR_TraceRayFilterEx(flOrigin, flAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		
		if(TR_DidHit(TraceRay))
			TR_GetEndPosition(flEnd, TraceRay);
		
		delete TraceRay;
		
		float victimOrigin[3];
		GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", victimOrigin);
		
		if(CylinderCollision(flEnd, victimOrigin, 225.0, flEnd[2] - 350.0, flEnd[2] - 0.01))
		{
			PrintCenterText(iClient, "Location blocked by player(s)!");
			return false;
		}
	}
	
	return true;
}

void Rage_Horsemann(int iClient)
{
	if(Horse_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	HORSE_Invoke(iClient);
}

public void HORSE_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Horse_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_horseman_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	EntCreate(iClient, "headless_hatman");
}

public Action Projectile_Touch(int iProj, int iOther)
{
	int iClient = GetEntPropEnt(iProj, Prop_Send, "m_hOwnerEntity");
	char strClassname[11];
	if((GetEntityClassname(iOther, strClassname, 11) && StrEqual(strClassname, "worldspawn")) || (iOther > 0 && iOther <= MaxClients))
	{
		float flPos[3], flAng[3];
		GetEntPropVector(iProj, Prop_Data, "m_vecAbsOrigin", flPos);
		for (int i = 0; i <= SkeleNumberOfSpawns[iClient]; i++)
		{
			flAng[0] = GetRandomFloat(-500.0, 500.0);
			flAng[1] = GetRandomFloat(-500.0, 500.0);
			flAng[2] = GetRandomFloat(0.0, 25.0);

			int iTeam = GetClientTeam(iClient);
			int iSpell = CreateEntityByName("tf_projectile_spellspawnhorde");
	
			if(!IsValidEntity(iSpell))
				return Plugin_Continue;
	
			SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", iClient);
			SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
			SetEntProp(iSpell, Prop_Send, "m_nSkin", (iTeam-2));
	
			SetVariantInt(iTeam);
			AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
			SetVariantInt(iTeam);
			AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
			DispatchSpawn(iSpell);
			TeleportEntity(iSpell, flPos, flAng, flAng);
		}
	}
	return Plugin_Continue;
}

public bool FIRE_CanInvoke(int iClient)
{
	return true;
}

void Rage_Fireball(int iClient)
{
	if(Fireball_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	FIRE_Invoke(iClient);
}

public void FIRE_Invoke(int iClient)
{
	int iBoss=FF2_GetBossIndex(iClient);
	
	if(Fireball_TriggerAMS[iClient])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_fireball_spell", sound, sizeof(sound), iBoss))
		{
			EmitSoundToAll(sound, iClient);
		}
	}
	
	ShootProjectile(iClient, "tf_projectile_spellfireball");
}

public void MJ_Tick(int iClient, int iButtons, float flTime)
{
	int Boss = FF2_GetBossIndex(iClient);
	if(FF2_HasAbility(Boss, this_plugin_name, "special_jumpmanager"))	// Prevent possible double up conflicts
		return;
	
	if (flTime >= MJ_OnCooldownUntil[iClient])
		MJ_OnCooldownUntil[iClient] = FAR_FUTURE;
		
	float flCharge = 0.0;
	if (MJ_OnCooldownUntil[iClient] == FAR_FUTURE)
	{
		// get charge percent here, used by both the HUD and the actual jump
		if (MJ_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE)
		{
			if (MJ_ChargeTime[iClient] <= 0.0)
				flCharge = 100.0;
			else
				flCharge = fmin((flTime - MJ_CrouchOrAltFireDownSince[iClient]) / MJ_ChargeTime[iClient], 1.0) * 100.0;
		}
			
		char Button;
		switch(MJT_ButtonType)
		{
			case 1: Button = IN_ATTACK2;
			case 2: Button = IN_RELOAD;
			case 3: Button = IN_ATTACK3;
		}
		
		// do we start the charging now?
		if (MJ_CrouchOrAltFireDownSince[iClient] == FAR_FUTURE && (iButtons & Button) != 0)
			MJ_CrouchOrAltFireDownSince[iClient] = flTime;
			
		// has key been released?
		if (MJ_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE && (iButtons & Button) == 0)
		{
			if (!IsInInvalidCondition(iClient))
			{
				MJ_OnCooldownUntil[iClient] = flTime + MJ_Cooldown[iClient];
					
				// taken from default_abilities, modified only lightly
				float position[3];
				float velocity[3];
				GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", position);
				GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", velocity);
				
				int spellbook = FindSpellBook(iClient);
				
				if(!IsValidEntity(spellbook))
					return;
				
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 4);
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				FakeClientCommand(iClient, "use tf_weapon_spellbook");

				// for the sake of making this viable, I'm keeping an actual jump, but half the power of a standard jump
				if (MJ_EmergencyReady[iClient])
				{
					velocity[2] = (750 + (flCharge / 4) * 13.0) + 2000 * 0.75;
					MJ_EmergencyReady[iClient] = false;
				}
				else
				{
					velocity[2] = (750 + (flCharge / 4) * 13.0) * 0.5;
				}
				SetEntProp(iClient, Prop_Send, "m_bJumping", 1);
				velocity[0] *= (1 + Sine((flCharge / 4) * FLOAT_PI / 50)) * 0.5;
				velocity[1] *= (1 + Sine((flCharge / 4) * FLOAT_PI / 50)) * 0.5;

				TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, velocity);
				char sound[PLATFORM_MAX_PATH];
				if (FF2_RandomSound("sound_magjump", sound, PLATFORM_MAX_PATH, Boss))
				{
					EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
					EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);

					for (new enemy = 1; enemy < MaxClients; enemy++)
					{
						if (IsClientInGame(enemy) && enemy != iClient)
						{
							EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
							EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
						}
					}
				}
			}
			
			// regardless of outcome, cancel the charge.
			MJ_CrouchOrAltFireDownSince[iClient] = FAR_FUTURE;
		}
	}
		
	// draw the HUD if it's time
	if (flTime >= WitchDoctorUpdateHUD[iClient])
	{
		if (!(GetClientButtons(iClient) & IN_SCORE))
		{
			if (MJ_EmergencyReady[iClient])
			{
				SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
				ShowSyncHudText(iClient, witchdoctorHUD, "Super DUPER Jump ready! Press and release %s!", GetMJTButton());
			}
			else if (MJ_OnCooldownUntil[iClient] == FAR_FUTURE)
			{
				SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_OK, HUD_G_OK, HUD_B_OK, HUD_ALPHA);
				ShowSyncHudText(iClient, witchdoctorHUD, "Magic Jump is ready. %.0f percent charged. Press and release %s!", flCharge, GetMJTButton());
			}
			else
			{
				SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
				ShowSyncHudText(iClient, witchdoctorHUD, "Magic Jump is not ready. %.1f seconds remaining.", MJ_OnCooldownUntil[iClient] - flTime);
			}
		}
		
		WitchDoctorUpdateHUD[iClient] = flTime + HUD_INTERVAL;
	}
}

public void MT_Tick(int iClient, int iButtons, float flTime)
{
	int Boss = FF2_GetBossIndex(iClient);
	if(FF2_HasAbility(Boss, this_plugin_name, "special_jumpmanager"))	// Prevent possible double up conflicts
		return;
		
	if (flTime >= MT_OnCooldownUntil[iClient])
		MT_OnCooldownUntil[iClient] = FAR_FUTURE;
		
	float flCharge = 0.0;
	if (MT_OnCooldownUntil[iClient] == FAR_FUTURE)
	{
		// get charge percent here, used by both the HUD and the actual jump
		if (MT_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE)
		{
			if (MT_ChargeTime[iClient] <= 0.0)
				flCharge = 100.0;
			else
				flCharge = fmin((flTime - MT_CrouchOrAltFireDownSince[iClient]) / MT_ChargeTime[iClient], 1.0) * 100.0;
		}
			
		char Button;
		switch(MJT_ButtonType)
		{
			case 1: Button = IN_ATTACK2;
			case 2: Button = IN_RELOAD;
			case 3: Button = IN_ATTACK3;
		}
		
		// do we start the charging now?
		if (MT_CrouchOrAltFireDownSince[iClient] == FAR_FUTURE && (iButtons & Button) != 0)
			MT_CrouchOrAltFireDownSince[iClient] = flTime;
			
		// has key been released?
		if (MT_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE && (iButtons & Button) == 0)
		{
			if (!IsInInvalidCondition(iClient))
			{
				MT_OnCooldownUntil[iClient] = flTime + MT_Cooldown[iClient];

				int spellbook = FindSpellBook(iClient);
				
				if(!IsValidEntity(spellbook))
					return;
				
				SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 6);
				SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
				FakeClientCommand(iClient, "use tf_weapon_spellbook");

				// just because I can see this becoming an immediate problem, gonna add an emergency teleport
				if (MT_EmergencyReady[iClient])
				{
					if (DD_PerformTeleport(iClient, 2.0, _, true))
					{
						MT_EmergencyReady[iClient] = false;
					}
				}
				
				float position[3];
				GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", position);
				
				char sound[PLATFORM_MAX_PATH];
				if (FF2_RandomSound("sound_magtele", sound, PLATFORM_MAX_PATH, Boss))
				{
					EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
					EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);

					for (int enemy = 1; enemy < MaxClients; enemy++)
					{
						if (IsClientInGame(enemy) && enemy != iClient)
						{
							EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
							EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
						}
					}
				}
			}
			
			// regardless of outcome, cancel the charge.
			MT_CrouchOrAltFireDownSince[iClient] = FAR_FUTURE;
		}
	}
		
	// draw the HUD if it's time
	if (flTime >= WitchDoctorUpdateHUD[iClient])
	{
		if (!(GetClientButtons(iClient) & IN_SCORE))
		{
			if (MT_EmergencyReady[iClient])
			{
				SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
				ShowSyncHudText(iClient, witchdoctorHUD, "EMERGENCY TELEPORT! Press and release %s!", GetMJTButton());
			}
			else if (MT_OnCooldownUntil[iClient] == FAR_FUTURE)
			{
				SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_OK, HUD_G_OK, HUD_B_OK, HUD_ALPHA);
				ShowSyncHudText(iClient, witchdoctorHUD, "Magic Tele is ready. %.0f percent charged. Press and release %s!", flCharge, GetMJTButton());
			}
			else
			{
				SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
				ShowSyncHudText(iClient, witchdoctorHUD, "Magic Tele is not ready. %.1f seconds remaining.", MT_OnCooldownUntil[iClient] - flTime);
			}
		}
		
		WitchDoctorUpdateHUD[iClient] = flTime + HUD_INTERVAL;
	}
}

public void JM_Tick(int iClient, int iButtons, float flTime)
{
	if(!JM_AbilitySwitched[iClient])
	{
		if (flTime >= MJ_OnCooldownUntil[iClient])
			MJ_OnCooldownUntil[iClient] = FAR_FUTURE;
		
		float flCharge = 0.0;
		if (MJ_OnCooldownUntil[iClient] == FAR_FUTURE)
		{
			// get charge percent here, used by both the HUD and the actual jump
			if (MJ_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE)
			{
				if (MJ_ChargeTime[iClient] <= 0.0)
					flCharge = 100.0;
				else
					flCharge = fmin((flTime - MJ_CrouchOrAltFireDownSince[iClient]) / MJ_ChargeTime[iClient], 1.0) * 100.0;
			}
			
			char Button;
			switch(MJT_ButtonType)
			{
				case 1: Button = IN_ATTACK2;
				case 2: Button = IN_RELOAD;
				case 3: Button = IN_ATTACK3;
			}
		
			// do we start the charging now?
			if (MJ_CrouchOrAltFireDownSince[iClient] == FAR_FUTURE && (iButtons & Button) != 0)
				MJ_CrouchOrAltFireDownSince[iClient] = flTime;
			
			// has key been released?
			if (MJ_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE && (iButtons & Button) == 0)
			{
				if (!IsInInvalidCondition(iClient))
				{
					MJ_OnCooldownUntil[iClient] = flTime + MJ_Cooldown[iClient];
					
					// taken from default_abilities, modified only lightly
					int Boss = FF2_GetBossIndex(iClient);
					float position[3];
					float velocity[3];
					GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", position);
					GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", velocity);
				
					int spellbook = FindSpellBook(iClient);
					
					if(!IsValidEntity(spellbook))
						return;
					
					SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 4);
					SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
					FakeClientCommand(iClient, "use tf_weapon_spellbook");

					// for the sake of making this viable, I'm keeping an actual jump, but half the power of a standard jump
					if (MJ_EmergencyReady[iClient])
					{
						velocity[2] = (750 + (flCharge / 4) * 13.0) + 2000 * 0.75;
						MJ_EmergencyReady[iClient] = false;
					}
					else
					{
						velocity[2] = (750 + (flCharge / 4) * 13.0) * 0.5;
					}
					SetEntProp(iClient, Prop_Send, "m_bJumping", 1);
					velocity[0] *= (1 + Sine((flCharge / 4) * FLOAT_PI / 50)) * 0.5;
					velocity[1] *= (1 + Sine((flCharge / 4) * FLOAT_PI / 50)) * 0.5;

					TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, velocity);
					char sound[PLATFORM_MAX_PATH];
					if (FF2_RandomSound("sound_magjump", sound, PLATFORM_MAX_PATH, Boss))
					{
						EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
						EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
	
						for (new enemy = 1; enemy < MaxClients; enemy++)
						{
							if (IsClientInGame(enemy) && enemy != iClient)
							{
								EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
								EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
							}
						}
					}
				}
			
				// regardless of outcome, cancel the charge.
				MJ_CrouchOrAltFireDownSince[iClient] = FAR_FUTURE;
			}
		}
		
		// draw the HUD if it's time
		if (flTime >= WitchDoctorUpdateHUD[iClient])
		{
			if (!(GetClientButtons(iClient) & IN_SCORE))
			{
				if (MJ_EmergencyReady[iClient])
				{
					SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
					ShowSyncHudText(iClient, witchdoctorHUD, "Super DUPER Jump ready! Press and release %s!", GetMJTButton());
				}
				else if (MJ_OnCooldownUntil[iClient] == FAR_FUTURE)
				{
					SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_OK, HUD_G_OK, HUD_B_OK, HUD_ALPHA);
					ShowSyncHudText(iClient, witchdoctorHUD, "Magic Jump is ready. %.0f percent charged. Press and release %s!\nPress %s to change.", flCharge, GetMJTButton(), GetJMButton());
				}
				else
				{
					SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
					ShowSyncHudText(iClient, witchdoctorHUD, "Magic Jump is not ready. %.1f seconds remaining.\nPress %s to change.", MJ_OnCooldownUntil[iClient] - flTime, GetJMButton());
				}
			}
		
			WitchDoctorUpdateHUD[iClient] = flTime + HUD_INTERVAL;
		}
	}
	else
	{
		if (flTime >= MT_OnCooldownUntil[iClient])
			MT_OnCooldownUntil[iClient] = FAR_FUTURE;
		
		float flCharge = 0.0;
		if (MT_OnCooldownUntil[iClient] == FAR_FUTURE)
		{
			// get charge percent here, used by both the HUD and the actual jump
			if (MT_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE)
			{
				if (MT_ChargeTime[iClient] <= 0.0)
					flCharge = 100.0;
				else
					flCharge = fmin((flTime - MT_CrouchOrAltFireDownSince[iClient]) / MT_ChargeTime[iClient], 1.0) * 100.0;
			}
			
			char Button;
			switch(MJT_ButtonType)
			{
				case 1: Button = IN_ATTACK2;
				case 2: Button = IN_RELOAD;
				case 3: Button = IN_ATTACK3;
			}
		
			// do we start the charging now?
			if (MT_CrouchOrAltFireDownSince[iClient] == FAR_FUTURE && (iButtons & Button) != 0)
				MT_CrouchOrAltFireDownSince[iClient] = flTime;
			
			// has key been released?
			if (MT_CrouchOrAltFireDownSince[iClient] != FAR_FUTURE && (iButtons & Button) == 0)
			{
				if (!IsInInvalidCondition(iClient))
				{
					MT_OnCooldownUntil[iClient] = flTime + MT_Cooldown[iClient];

					int spellbook = FindSpellBook(iClient);
					
					if(!IsValidEntity(spellbook))
						return;
					
					SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", 6);
					SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", 1);
					FakeClientCommand(iClient, "use tf_weapon_spellbook");

					// just because I can see this becoming an immediate problem, gonna add an emergency teleport
					if (MT_EmergencyReady[iClient])
					{
						if (DD_PerformTeleport(iClient, 2.0, _, true))
						{
							MT_EmergencyReady[iClient] = false;
						}
					}
				
					float position[3];
					GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", position);
				
					int Boss = FF2_GetBossIndex(iClient);
					char sound[PLATFORM_MAX_PATH];
					if (FF2_RandomSound("sound_magtele", sound, PLATFORM_MAX_PATH, Boss))
					{
						EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
						EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);

						for (int enemy = 1; enemy < MaxClients; enemy++)
						{
							if (IsClientInGame(enemy) && enemy != iClient)
							{
								EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
								EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, position, NULL_VECTOR, true, 0.0);
							}
						}
					}
				}
			
				// regardless of outcome, cancel the charge.
				MT_CrouchOrAltFireDownSince[iClient] = FAR_FUTURE;
			}
		}
		
		// draw the HUD if it's time
		if (flTime >= WitchDoctorUpdateHUD[iClient])
		{
			if (!(GetClientButtons(iClient) & IN_SCORE))
			{
				if (MT_EmergencyReady[iClient])
				{
					SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
					ShowSyncHudText(iClient, witchdoctorHUD, "EMERGENCY TELEPORT! Press and release %s!", GetMJTButton());
				}
				else if (MT_OnCooldownUntil[iClient] == FAR_FUTURE)
				{
					SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_OK, HUD_G_OK, HUD_B_OK, HUD_ALPHA);
					ShowSyncHudText(iClient, witchdoctorHUD, "Magic Tele is ready. %.0f percent charged. Press and release %s!\nPress %s to change.", flCharge, GetMJTButton(), GetJMButton());
				}
				else
				{
					SetHudTextParams(-1.0, 0.88, HUD_INTERVAL + HUD_LINGER, HUD_R_ERROR, HUD_G_ERROR, HUD_B_ERROR, HUD_ALPHA);
					ShowSyncHudText(iClient, witchdoctorHUD, "Magic Tele is not ready. %.1f seconds remaining.\nPress %s to change.", MT_OnCooldownUntil[iClient] - flTime, GetJMButton());
				}
			}
		
			WitchDoctorUpdateHUD[iClient] = flTime + HUD_INTERVAL;
		}
	}
}

public Action Timer_SwitchToSlot(Handle hTimer, any iClient)
{
	if(IsValidClient(iClient, true))
		SwitchtoSlot(iClient, 2);
}

stock int SpawnWeapon(int iClient, char[] strClassname, int iIndex, int iLevel, int iQuality, const char[] strAttribute = "", bool bShow = true, bool bEquip = false)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon == null)
		return -1;
	TF2Items_SetClassname(hWeapon, strClassname);
	TF2Items_SetItemIndex(hWeapon, iIndex);
	TF2Items_SetLevel(hWeapon, iLevel);
	TF2Items_SetQuality(hWeapon, iQuality);
	char strAttributes[32][32];
	int count=ExplodeString(strAttribute, ";", strAttributes, 32, 32);
	if (count % 2)
		--count;
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i < count; i += 2)
		{
			int attrib = StringToInt(strAttributes[i]);
			if (!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", strAttributes[i], strAttributes[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}
			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(strAttributes[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	int iEntity = TF2Items_GiveNamedItem(iClient, hWeapon);
	delete hWeapon;
	EquipPlayerWeapon(iClient, iEntity);
	
	if(bEquip)
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iEntity);
	
	if (!bShow)
	{
		SetEntProp(iEntity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 0.001);
	}
	return iEntity;
}

stock int FindEntityByClassname2(int startEnt, const char[] strClassname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, strClassname);
}

int ShootProjectile(int iClient, char strEntname[48] = "")
{
	float flAng[3]; // original
	float flPos[3]; // original
	GetClientEyeAngles(iClient, flAng);
	GetClientEyePosition(iClient, flPos);
	
	int iTeam = GetClientTeam(iClient);
	int iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
		return -1;
	
	float flVel1[3];
	float flVel2[3];
	
	GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
	
	flVel1[0] = flVel2[0]*1100.0; //Speed of a tf2 rocket.
	flVel1[1] = flVel2[1]*1100.0;
	flVel1[2] = flVel2[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", iClient);
	SetEntProp(iSpell, Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, flPos, flAng, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, flVel1);
	
	return iSpell;
}

public void EntCreate(iClient, char[] strEntity)
{
	int flags = GetCommandFlags("ent_create");
	SetCommandFlags("ent_create", flags & ~FCVAR_CHEAT);
	ClientCommand(iClient, "ent_create %s", strEntity);
	SetCommandFlags("ent_create", flags);
}

stock bool IsValidClient(int iClient, bool bAlive = false, bool bTeam = false)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;
	
	if(bTeam && GetClientTeam(iClient) != FF2_GetBossTeam())
		return false;

	return true;
}

public bool IsInInvalidCondition(iClient)
{
	return TF2_IsPlayerInCondition(iClient, TFCond_Dazed) || TF2_IsPlayerInCondition(iClient, TFCond_Taunting) || GetEntityMoveType(iClient)==MOVETYPE_NONE;
}

stock float fmin(float n1, float n2)
{
	return n1 < n2 ? n1 : n2;
}

stock char GetJMButton()
{
	char strBuffer[18];
	switch(JM_ButtonType)
	{
		case 1: strBuffer = "Reload";
		case 2: strBuffer = "Special Attack";
		case 3: strBuffer = "Secondary Attack";
	}
	return strBuffer;
}

stock char GetMJTButton()
{
	char strBuffer[18];
	switch(MJT_ButtonType)
	{
		case 1: strBuffer = "Secondary Attack";
		case 2: strBuffer = "Reload";
		case 3: strBuffer = "Special Attack";
	}
	return strBuffer;
}

stock int FindSpellBook(int iClient)
{
	int spellbook = -1;
	while ((spellbook = FindEntityByClassname(spellbook, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(spellbook) && GetEntPropEnt(spellbook, Prop_Send, "m_hOwnerEntity") == iClient)
			if(!GetEntProp(spellbook, Prop_Send, "m_bDisguiseWeapon"))
				return spellbook;
	}
	
	return -1;
}

void SwitchtoSlot(int iClient, int iSlot)
{
	if (iSlot >= 0 && iSlot <= 5 && IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		char strClassname[64];
		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		if (iWeapon > MaxClients && IsValidEdict(iWeapon) && GetEdictClassname(iWeapon, strClassname, sizeof(strClassname)))
		{
			FakeClientCommandEx(iClient, "use %s", strClassname);
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		}
	}
}

public bool TraceEntityFilterPlayer(int iEntity, int contentsMask)
{
	return (iEntity > GetMaxClients() || !iEntity);
}

stock bool CylinderCollision(float cylinderOrigin[3], float colliderOrigin[3], float maxDistance, float zMin, float zMax)
{
	if (colliderOrigin[2] < zMin || colliderOrigin[2] > zMax)
		return false;

	static float tmpVec1[3];
	tmpVec1[0] = cylinderOrigin[0];
	tmpVec1[1] = cylinderOrigin[1];
	tmpVec1[2] = 0.0;
	static float tmpVec2[3];
	tmpVec2[0] = colliderOrigin[0];
	tmpVec2[1] = colliderOrigin[1];
	tmpVec2[2] = 0.0;
	
	return GetVectorDistance(tmpVec1, tmpVec2, true) <= maxDistance * maxDistance;
}

// call AMS from epic scout's subplugin via reflection:
stock Handle FindPlugin(char[] plugin_name)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	Handle iter = GetPluginIterator();
	Handle pl = INVALID_HANDLE;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		Format(path, sizeof(path), "%s.ff2", plugin_name);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, path, false) >= 0)
			break;
		else
			pl = INVALID_HANDLE;
	}
	
	delete iter;

	return pl;
}

// this will tell AMS that the abilities listed on PrepareAbilities() supports AMS
stock void AMS_InitSubability(int iBoss, int iClient, const char[] plugin_name, const char[] ability_name, const char[] prefix)
{
	Handle plugin = FindPlugin("ff2_sarysapub3");
	if (plugin != INVALID_HANDLE)
	{
		Function func = GetFunctionByName(plugin, "AMS_InitSubability");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(iBoss);
			Call_PushCell(iClient);
			Call_PushString(plugin_name);
			Call_PushString(ability_name);
			Call_PushString(prefix);
			Call_Finish();
		}
		else
			LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability()");
	}
	else
		LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability(). Make sure this plugin exists!");

}