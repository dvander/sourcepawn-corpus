#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2attributes>

#define MAM "multiple_abilities_menu"
#define LASERBEAM "sprites/laserbeam.vmt"
#define LIGHTNING "materials/sprites/lgtning.vmt"


Handle HUDTimerMAM[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
int MenuIndex[MAXPLAYERS + 1] = 0;
float ManaNumber[MAXPLAYERS + 1][20];
float TimerManaRegen[MAXPLAYERS + 1][20];
float TimerAltAbility[MAXPLAYERS + 1][20];
float TimerRageAbility[MAXPLAYERS + 1][20];
float TimerSpecialAbility[MAXPLAYERS + 1][20];
float TimerCrtlAbility[MAXPLAYERS + 1][20];
float TimerReloadAbility[MAXPLAYERS + 1][20];
float TpPosition[MAXPLAYERS + 1][3];
float ComboMultiplier[MAXPLAYERS + 1];
float ComboTimer[MAXPLAYERS + 1];
float BaseVelocity[MAXPLAYERS + 1][3];
int ClientShield[MAXPLAYERS + 1] = -1;
int ClientShieldHp[MAXPLAYERS + 1] = 0;
float ShieldTimer[MAXPLAYERS + 1] = 0.0;
int ClientProtector[MAXPLAYERS + 1] = -1;
int ChargesAlt[MAXPLAYERS + 1][20];
int ChargesRage[MAXPLAYERS + 1][20];
int ChargesCrtl[MAXPLAYERS + 1][20];
int ChargesSpecial[MAXPLAYERS + 1][20];
int ChargesReload[MAXPLAYERS + 1][20];
float AltAbilityCharge[MAXPLAYERS + 1][20];
float RageAbilityCharge[MAXPLAYERS + 1][20];
float CrtlAbilityCharge[MAXPLAYERS + 1][20];
float SpecialAbilityCharge[MAXPLAYERS + 1][20];
float ReloadAbilityCharge[MAXPLAYERS + 1][20];
Handle SDKEquipWearable = null;

float OFF_THE_MAP[3] =
{
	1182792704.0, 1182792704.0, -964690944.0
};

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart2()
{
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_win_panel", Event_WinPanel);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	
	HookEvent("player_hurt", OnPlayerHurt);
	AddCommandListener(OnCallForMedic, "voicemenu");
	
	Handle gameData = LoadGameConfigFile("ffalex_finalpack_data");
	if(gameData == INVALID_HANDLE)
	{
		PrintToServer("cannot find equip wearable");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();

	delete gameData;
}

public OnMapStart()
{
	PrecacheModel(LIGHTNING);
	PrecacheModel(LASERBEAM);
	PrecacheSound(")items/powerup_pickup_reflect.wav");
	PrecacheSound(")weapons/bison_main_shot.wav"); 
	PrecacheSound(")weapons/sentry_finish.wav");
	PrecacheSound(")weapons/vaccinator_charge_tier_04.wav");
	PrecacheSound(")weapons/sentry_damage4.wav");
	PrecacheSound(")weapons/rescue_ranger_charge_01.wav");
	PrecacheSound(")items/powerup_pickup_uber.wav");
	PrecacheSound(")weapons/sentry_move_short2.wav");
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		PrepareAbilities(client);
	}
}

public Action Event_WinPanel(Handle event, const char[] name, bool dontBroadcast)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if (HUDTimerMAM[client] != INVALID_HANDLE)
		{
			KillTimer(HUDTimerMAM[client]);
			HUDTimerMAM[client] = INVALID_HANDLE;
		}
		
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & (~FF2FLAG_HUDDISABLED));
	}
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{

	int damage = event.GetInt("damageamount");
	if(damage <= 0)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
		return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int idBoss = FF2_GetBossIndex(attacker);
	if(idBoss!=1)
	{
		if (FF2_HasAbility(idBoss, this_plugin_name, MAM))
		{
			char argkey[64];
			Format(argkey, 64, "mana_deal_dmg%i", MenuIndex[attacker]);
			ManaNumber[attacker][MenuIndex[attacker]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey)*damage;
			
			Format(argkey, 64, "alt_charge_deal_dmg%i", MenuIndex[attacker]);
			AltAbilityCharge[attacker][MenuIndex[attacker]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
			
			Format(argkey, 64, "reload_charge_deal_dmg%i", MenuIndex[attacker]);
			ReloadAbilityCharge[attacker][MenuIndex[attacker]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
			
			Format(argkey, 64, "special_charge_deal_dmg%i", MenuIndex[attacker]);
			SpecialAbilityCharge[attacker][MenuIndex[attacker]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
			
			Format(argkey, 64, "crtl_charge_deal_dmg%i", MenuIndex[attacker]);
			CrtlAbilityCharge[attacker][MenuIndex[attacker]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
			
			Format(argkey, 64, "rage_charge_deal_dmg%i", MenuIndex[attacker]);
			RageAbilityCharge[attacker][MenuIndex[attacker]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
			
		}
	}

	idBoss = FF2_GetBossIndex(client);
	if(idBoss<-1)
		return;

	if (FF2_HasAbility(idBoss, this_plugin_name, MAM))
	{
		char argkey[64];
		Format(argkey, 64, "mana_take_dmg%i", MenuIndex[client]);
		ManaNumber[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey)*damage;
		
		Format(argkey, 64, "alt_charge_take_dmg%i", MenuIndex[client]);
		AltAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
		
		Format(argkey, 64, "reload_charge_take_dmg%i", MenuIndex[client]);
		ReloadAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
		
		Format(argkey, 64, "special_charge_take_dmg%i", MenuIndex[client]);
		SpecialAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
		
		Format(argkey, 64, "crtl_charge_take_dmg%i", MenuIndex[client]);
		CrtlAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
		
		Format(argkey, 64, "rage_charge_take_dmg%i", MenuIndex[client]);
		RageAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0)*damage;
	}
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if (!IsPlayerAlive(client) || FF2_GetRoundState()!=1)
		return Plugin_Continue;
		
	int idBoss = FF2_GetBossIndex(client);
	if (!FF2_HasAbility(idBoss, this_plugin_name, MAM) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || TF2_IsPlayerInCondition(client, TFCond_FreezeInput))
		return Plugin_Continue;
	
	int ManaCost;
	char argkey[54];
	char AbilityCheck[64], argkeycheck[64];
	Format(argkeycheck, 64, "special_name%i", MenuIndex[client]);
	FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkeycheck, AbilityCheck, sizeof(AbilityCheck));
	if (!StrEqual(AbilityCheck,NULL_STRING))
	{
		Format(argkey, 64, "special_cost%i", MenuIndex[client]);
		ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
		
		if (TimerSpecialAbility[client][MenuIndex[client]]<=0.0 && buttons & IN_ATTACK3 && ManaNumber[client][MenuIndex[client]]>=ManaCost && (ChargesSpecial[client][MenuIndex[client]]>0 || ChargesSpecial[client][MenuIndex[client]]==-1))
		{
			char AbilityName[64], PluginName[64];
			for (int i = 0; i < 10; i++)
			{
				strcopy(AbilityName, sizeof(AbilityName), NULL_STRING);
				strcopy(PluginName, sizeof(PluginName), NULL_STRING);
				Format(argkey, 64, "special_ability_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				Format(argkey, 64, "special_plugin_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, PluginName, sizeof(PluginName));
				
				Format(argkey, 64, "special_ability_slot%i-%i", MenuIndex[client],i);
				int abilityslot = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
				
				if (!StrEqual(AbilityName,NULL_STRING) && !StrEqual(PluginName,NULL_STRING))
					FF2_DoAbility(idBoss, PluginName, AbilityName, abilityslot);
				else
					break;
			}
			ManaNumber[client][MenuIndex[client]] -= ManaCost;
			Format(argkey, 64, "special_cooldown%i", MenuIndex[client]);
			TimerSpecialAbility[client][MenuIndex[client]] = FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
			
			if (ChargesSpecial[client][MenuIndex[client]]!=-1)
				ChargesSpecial[client][MenuIndex[client]] -= 1;
			
			static char sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "mam_sound_special%i", MenuIndex[client]);
			if(FF2_RandomSound(sound, sound, PLATFORM_MAX_PATH, idBoss))
				FF2_EmitVoiceToAll(sound, client);
		}
	}
	
	strcopy(AbilityCheck, sizeof(AbilityCheck), NULL_STRING);
	
	Format(argkeycheck, 64, "alt_fire_name%i", MenuIndex[client]);
	FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkeycheck, AbilityCheck, sizeof(AbilityCheck));
	if (!StrEqual(AbilityCheck,NULL_STRING))
	{
		Format(argkey, 64, "alt_fire_cost%i", MenuIndex[client]);
		ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
		
		if (TimerAltAbility[client][MenuIndex[client]]<=0.0 && buttons & IN_ATTACK2 && ManaNumber[client][MenuIndex[client]]>=ManaCost && (ChargesAlt[client][MenuIndex[client]]>0 || ChargesAlt[client][MenuIndex[client]]==-1))
		{
			char AbilityName[64], PluginName[64];
			for (int i = 0; i < 10; i++)
			{
				strcopy(AbilityName, sizeof(AbilityName), NULL_STRING);
				strcopy(PluginName, sizeof(PluginName), NULL_STRING);
				Format(argkey, 64, "alt_ability_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				Format(argkey, 64, "alt_plugin_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, PluginName, sizeof(PluginName));
				
				Format(argkey, 64, "alt_ability_slot%i-%i", MenuIndex[client],i);
				int abilityslot = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
				
				if (!StrEqual(AbilityName,NULL_STRING) && !StrEqual(PluginName,NULL_STRING))
					FF2_DoAbility(idBoss, PluginName, AbilityName, abilityslot);
				else
					break;
			}
			ManaNumber[client][MenuIndex[client]] -= ManaCost;
			Format(argkey, 64, "alt_cooldown%i", MenuIndex[client]);
			TimerAltAbility[client][MenuIndex[client]] = FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
			
			if (ChargesAlt[client][MenuIndex[client]]!=-1)
				ChargesAlt[client][MenuIndex[client]] -= 1;
			
			static char sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "mam_sound_alt%i", MenuIndex[client]);
			if(FF2_RandomSound(sound, sound, PLATFORM_MAX_PATH, idBoss))
				FF2_EmitVoiceToAll(sound, client);
		}
	}
	
	strcopy(AbilityCheck, sizeof(AbilityCheck), NULL_STRING);
	
	Format(argkeycheck, 64, "reload_name%i", MenuIndex[client]);
	FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkeycheck, AbilityCheck, sizeof(AbilityCheck));
	if (!StrEqual(AbilityCheck,NULL_STRING))
	{
		Format(argkey, 64, "reload_cost%i", MenuIndex[client]);
		ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
		
		if (TimerReloadAbility[client][MenuIndex[client]]<=0.0 && buttons & IN_RELOAD && ManaNumber[client][MenuIndex[client]]>=ManaCost && (ChargesReload[client][MenuIndex[client]]>0 || ChargesReload[client][MenuIndex[client]]==-1))
		{
			char AbilityName[64], PluginName[64];
			for (int i = 0; i < 10; i++)
			{
				strcopy(AbilityName, sizeof(AbilityName), NULL_STRING);
				strcopy(PluginName, sizeof(PluginName), NULL_STRING);
				Format(argkey, 64, "reload_ability_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				Format(argkey, 64, "reload_plugin_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, PluginName, sizeof(PluginName));
				
				Format(argkey, 64, "reload_ability_slot%i-%i", MenuIndex[client],i);
				int abilityslot = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
				
				if (!StrEqual(AbilityName,NULL_STRING) && !StrEqual(PluginName,NULL_STRING))
					FF2_DoAbility(idBoss, PluginName, AbilityName, abilityslot);
				else
					break;
			}
			ManaNumber[client][MenuIndex[client]] -= ManaCost;
			Format(argkey, 64, "reload_cooldown%i", MenuIndex[client]);
			TimerReloadAbility[client][MenuIndex[client]] = FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
			
			if (ChargesReload[client][MenuIndex[client]]!=-1)
				ChargesReload[client][MenuIndex[client]] -= 1;
			
			static char sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "mam_sound_reload%i", MenuIndex[client]);
			if(FF2_RandomSound(sound, sound, PLATFORM_MAX_PATH, idBoss))
				FF2_EmitVoiceToAll(sound, client);
		}
	}
	
	strcopy(AbilityCheck, sizeof(AbilityCheck), NULL_STRING);
	
	Format(argkeycheck, 64, "crtl_name%i", MenuIndex[client]);
	FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkeycheck, AbilityCheck, sizeof(AbilityCheck));
	if (!StrEqual(AbilityCheck,NULL_STRING))
	{
		Format(argkey, 64, "crtl_cost%i", MenuIndex[client]);
		ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
		if (TimerCrtlAbility[client][MenuIndex[client]]<=0.0 && buttons & IN_DUCK && ManaNumber[client][MenuIndex[client]]>=ManaCost && (ChargesCrtl[client][MenuIndex[client]]>0 || ChargesCrtl[client][MenuIndex[client]]==-1))
		{
			char AbilityName[64], PluginName[64];
			for (int i = 0; i < 10; i++)
			{
				strcopy(AbilityName, sizeof(AbilityName), NULL_STRING);
				strcopy(PluginName, sizeof(PluginName), NULL_STRING);
				Format(argkey, 64, "crtl_ability_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				Format(argkey, 64, "crtl_plugin_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, PluginName, sizeof(PluginName));
				
				Format(argkey, 64, "crtl_ability_slot%i-%i", MenuIndex[client],i);
				int abilityslot = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
				
				if (!StrEqual(AbilityName,NULL_STRING) && !StrEqual(PluginName,NULL_STRING))
					FF2_DoAbility(idBoss, PluginName, AbilityName, abilityslot);
				else
					break;
			}
			ManaNumber[client][MenuIndex[client]] -= ManaCost;
			Format(argkey, 64, "crtl_cooldown%i", MenuIndex[client]);
			TimerCrtlAbility[client][MenuIndex[client]] = FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
			
			if (ChargesCrtl[client][MenuIndex[client]]!=-1)
				ChargesCrtl[client][MenuIndex[client]] -= 1;
			
			static char sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "mam_sound_crtl%i", MenuIndex[client]);
			if(FF2_RandomSound(sound, sound, PLATFORM_MAX_PATH, idBoss))
				FF2_EmitVoiceToAll(sound, client);
		}
	}
	
	return Plugin_Continue;
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || FF2_GetRoundState()!=1)
		return Plugin_Continue;

	static char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
		return Plugin_Continue;


	int idBoss = FF2_GetBossIndex(client);
	if (!FF2_HasAbility(idBoss, this_plugin_name, MAM) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || TF2_IsPlayerInCondition(client, TFCond_FreezeInput))
		return Plugin_Continue;
	
	char AbilityCheck[64], argkeycheck[64];
	Format(argkeycheck, 64, "mam_rage_name%i", MenuIndex[client]);
	FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkeycheck, AbilityCheck, sizeof(AbilityCheck));
	if (!StrEqual(AbilityCheck,NULL_STRING))
	{
		char argkey[54];
		Format(argkey, 64, "mam_rage_cost%i", MenuIndex[client]);
		int ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
		if (TimerRageAbility[client][MenuIndex[client]]<=0.0 && ManaNumber[client][MenuIndex[client]]>=ManaCost && (ChargesRage[client][MenuIndex[client]]>0 || ChargesRage[client][MenuIndex[client]]==-1))
		{
			char AbilityName[64], PluginName[64];
			for (int i = 0; i < 10; i++)
			{
				strcopy(AbilityName, sizeof(AbilityName), NULL_STRING);
				strcopy(PluginName, sizeof(PluginName), NULL_STRING);
				Format(argkey, 64, "rage_ability_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				Format(argkey, 64, "rage_plugin_name%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, PluginName, sizeof(PluginName));
				
				Format(argkey, 64, "rage_ability_slot%i-%i", MenuIndex[client],i);
				int abilityslot = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
				
				if (!StrEqual(AbilityName,NULL_STRING) && !StrEqual(PluginName,NULL_STRING))
					FF2_DoAbility(idBoss, PluginName, AbilityName, abilityslot);
				else
					break;
			}
			ManaNumber[client][MenuIndex[client]] -= ManaCost;
			
			if (ChargesRage[client][MenuIndex[client]]!=-1)
				ChargesRage[client][MenuIndex[client]] -= 1;
			
			Format(argkey, 64, "rage_cooldown%i", MenuIndex[client]);
			TimerRageAbility[client][MenuIndex[client]] = FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
			
			static char sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "mam_sound_rage%i", MenuIndex[client]);
			if(FF2_RandomSound(sound, sound, PLATFORM_MAX_PATH, idBoss))
				FF2_EmitVoiceToAll(sound, client);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(FF2_GetRoundState()!=1)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return;	
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return;
	
	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsValidClient(player))
		{
			int idBoss = FF2_GetBossIndex(player);
			if(idBoss!=1)
			{
				if (FF2_HasAbility(idBoss, this_plugin_name, MAM))
				{
					if (TF2_GetClientTeam(player)==TF2_GetClientTeam(client))
					{
						char argkey[64];
						Format(argkey, 64, "mana_death_ally%i", MenuIndex[player]);
						ManaNumber[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
						
						Format(argkey, 64, "alt_charge_death_ally%i", MenuIndex[player]);
						AltAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "reload_charge_death_ally%i", MenuIndex[player]);
						ReloadAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "special_charge_death_ally%i", MenuIndex[player]);
						SpecialAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "crtl_charge_death_ally%i", MenuIndex[player]);
						CrtlAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "rage_charge_death_ally%i", MenuIndex[player]);
						RageAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
					}
					else
					{
						char argkey[64];
						Format(argkey, 64, "mana_death_enemy%i", MenuIndex[player]);
						ManaNumber[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
						
						Format(argkey, 64, "alt_charge_death_enemy%i", MenuIndex[player]);
						AltAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "reload_charge_death_enemy%i", MenuIndex[player]);
						ReloadAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "special_charge_death_enemy%i", MenuIndex[player]);
						SpecialAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "crtl_charge_death_enemy%i", MenuIndex[player]);
						CrtlAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
						
						Format(argkey, 64, "rage_charge_death_enemy%i", MenuIndex[player]);
						RageAbilityCharge[player][MenuIndex[player]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey,0.0);
					}
				}
			}
		}
	}
}

public PrepareAbilities(int client)
{
	MenuIndex[client] = 0;
	ComboMultiplier[client] = 1.0;
	ComboTimer[client] = 0.0;
	ShieldTimer[client] = 0.0;
	BaseVelocity[client][0] = 0.0;
	BaseVelocity[client][1] = 0.0;
	BaseVelocity[client][2] = 0.0;
	ClientShieldHp[client] = 0;
	ClientShield[client] = -1;
	ClientProtector[client] = -1;
	
	for (int i = 0; i < 20; i++)
	{
		ManaNumber[client][i] = 0.0;
		TimerManaRegen[client][i] = 0.0;
		TimerAltAbility[client][i] = 0.0;
		TimerRageAbility[client][i] = 0.0;
		TimerSpecialAbility[client][i] = 0.0;
		TimerCrtlAbility[client][i] = 0.0;
		TimerReloadAbility[client][i] = 0.0;
		
		ChargesRage[client][i] = -1;
		RageAbilityCharge[client][i] = 0.0;
		ChargesAlt[client][i] = -1;
		AltAbilityCharge[client][i] = 0.0;
		ChargesSpecial[client][i] = -1;
		SpecialAbilityCharge[client][i] = 0.0;
		ChargesCrtl[client][i] = -1;
		CrtlAbilityCharge[client][i] = 0.0;
		ChargesReload[client][i] = -1;
		ReloadAbilityCharge[client][i] = 0.0;
	}
	
	if (HUDTimerMAM[client] != INVALID_HANDLE)
	{
		KillTimer(HUDTimerMAM[client]);
		HUDTimerMAM[client] = INVALID_HANDLE;
	}
	
	if (IsClientInGame(client))
	{
		GetClientAbsOrigin(client, TpPosition[client]);
		
		int idBoss = FF2_GetBossIndex(client);			
		if (FF2_HasAbility(idBoss, this_plugin_name, MAM))
		{
			char argkey[64];
			MenuIndex[client] = 0;
			
			for (int i = 0; i < 20; i++)
			{
				Format(argkey, 64, "mana_start%i", i);
				ManaNumber[client][i] = FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
				
				Format(argkey, 64, "charge_rage_start%i", i);
				ChargesRage[client][i] = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey, -1);
				
				Format(argkey, 64, "charge_crtl_start%i", i);
				ChargesCrtl[client][i] = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey, -1);
				
				Format(argkey, 64, "charge_special_start%i", i);
				ChargesSpecial[client][i] = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey, -1);
				
				Format(argkey, 64, "charge_reload_start%i", i);
				ChargesReload[client][i] = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey, -1);
				
				Format(argkey, 64, "charge_alt_start%i", i);
				ChargesAlt[client][i] = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey, -1);
			}
			
			Format(argkey, 64, "disable_rage_hud", MenuIndex[client]);
			bool UseRageHud = view_as<bool>(FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey));
			
			if (UseRageHud)
				FF2_SetFF2flags(client, FF2_GetFF2flags(client) | FF2FLAG_HUDDISABLED);
			
			HUDTimerMAM[client] = CreateTimer(0.1, Timer_Hud_Mam, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
	

public Action Timer_Hud_Mam(Handle timer, client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			int idBoss = FF2_GetBossIndex(client);			
			if (FF2_HasAbility(idBoss, this_plugin_name, MAM))
			{
				char texttoshow[2048], argkey[64], ManaName[64];
				bool UseMana = false;
				
				Format(argkey, 64, "mana_name%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, ManaName, sizeof(ManaName));
				
				if (!StrEqual(ManaName, NULL_STRING))
					strcopy(texttoshow, sizeof(texttoshow), ManaName);
				
				Format(argkey, 64, "mana_max%i", MenuIndex[client]);
				int MaxMana = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
				
				if (MaxMana>0)
				{
					Format(texttoshow, sizeof(texttoshow), "%s: %.f / %i", texttoshow, ManaNumber[client][MenuIndex[client]], MaxMana);
					UseMana = true;
				}
				
				if (UseMana && FF2_GetRoundState()==1)
				{
					Format(argkey, 64, "mana_regen%i", MenuIndex[client]);
					float ManaRegenPerTick = FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
				
					if (ManaNumber[client][MenuIndex[client]]<MaxMana && TimerManaRegen[client][MenuIndex[client]] <= 0.0)
					{
						if (ManaNumber[client][MenuIndex[client]]+ManaRegenPerTick < MaxMana)
						{
							ManaNumber[client][MenuIndex[client]]+=ManaRegenPerTick;
							Format(argkey, 64, "mana_regen_tick%i", MenuIndex[client]);
							TimerManaRegen[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
						}
						else
							ManaNumber[client][MenuIndex[client]]=MaxMana*1.0;
				
						
					}
					else if (TimerManaRegen[client][MenuIndex[client]] > 0.0)
					{
						TimerManaRegen[client][MenuIndex[client]] -= 0.1;
					}
				}
				
				Format(texttoshow, sizeof(texttoshow), "%s \n ", texttoshow);
				
				char AbilityName[64], delimeter[64];
				
				Format(argkey, 64, "first_delimeter%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, delimeter, sizeof(delimeter));
				
				if (!StrEqual(delimeter, NULL_STRING))
					Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, delimeter);
				
				strcopy(AbilityName, sizeof(AbilityName),NULL_STRING);
				strcopy(delimeter, sizeof(delimeter),NULL_STRING);
				
				Format(argkey, 64, "mam_rage_name%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				
				if (!StrEqual(AbilityName, NULL_STRING))
				{
					Format(argkey, 64, "mam_rage_cost%i", MenuIndex[client]);
					int ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, AbilityName);
					
					Format(argkey, 64, "mam_rage_charge_max%i", MenuIndex[client]);
					int MaxCharge = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					if (ChargesRage[client][MenuIndex[client]]!=-1)
					{
						Format(texttoshow, sizeof(texttoshow), "%s [%i/%i]", texttoshow, ChargesRage[client][MenuIndex[client]], MaxCharge);
						
						if (ChargesRage[client][MenuIndex[client]]<MaxCharge && FF2_GetRoundState()==1)
						{
							Format(argkey, 64, "mam_rage_charge_regen%i", MenuIndex[client]);
							RageAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
							
							if (RageAbilityCharge[client][MenuIndex[client]]>=100)
							{
								ChargesRage[client][MenuIndex[client]] += 1;
								RageAbilityCharge[client][MenuIndex[client]] = 0.0;
							}
							
							Format(texttoshow, sizeof(texttoshow), "%s [%.2f]", texttoshow, RageAbilityCharge[client][MenuIndex[client]]);
						}
						else
							RageAbilityCharge[client][MenuIndex[client]] = 0.0;
					}
					
					if (TimerRageAbility[client][MenuIndex[client]]<= 0.0)
					{
						if (ManaCost>0)
							Format(texttoshow, sizeof(texttoshow), "%s (%i)", texttoshow, AbilityName, ManaCost);
					}
					else
					{
						Format(texttoshow, sizeof(texttoshow), "%s (%.2f)", texttoshow, TimerRageAbility[client][MenuIndex[client]]);
						TimerRageAbility[client][MenuIndex[client]] -= 0.1;
					}
					
					Format(argkey, 64, "rage_delimeter%i", MenuIndex[client]);
					FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, delimeter, sizeof(delimeter));
					
					if (!StrEqual(delimeter, NULL_STRING))
						Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, delimeter);
				}
				
				strcopy(AbilityName, sizeof(AbilityName),NULL_STRING);
				strcopy(delimeter, sizeof(delimeter),NULL_STRING);
				
				Format(argkey, 64, "special_name%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				
				if (!StrEqual(AbilityName, NULL_STRING))
				{
					Format(argkey, 64, "special_cost%i", MenuIndex[client]);
					int ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, AbilityName);
					
					Format(argkey, 64, "mam_special_charge_max%i", MenuIndex[client]);
					int MaxCharge = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					if (ChargesSpecial[client][MenuIndex[client]]!=-1)
					{
						Format(texttoshow, sizeof(texttoshow), "%s [%i/%i]", texttoshow, ChargesSpecial[client][MenuIndex[client]], MaxCharge);
						
						if (ChargesSpecial[client][MenuIndex[client]]<MaxCharge)
						{
							Format(argkey, 64, "mam_special_charge_regen%i", MenuIndex[client]);
							SpecialAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
							
							if (SpecialAbilityCharge[client][MenuIndex[client]]>=100 && FF2_GetRoundState()==1)
							{
								ChargesSpecial[client][MenuIndex[client]] += 1;
								SpecialAbilityCharge[client][MenuIndex[client]] = 0.0;
							}
							
							Format(texttoshow, sizeof(texttoshow), "%s [%.2f]", texttoshow, SpecialAbilityCharge[client][MenuIndex[client]]);
						}
						else
							SpecialAbilityCharge[client][MenuIndex[client]] = 0.0;
					}
					
					if (TimerSpecialAbility[client][MenuIndex[client]]<= 0.0)
					{
						if (ManaCost>0)
							Format(texttoshow, sizeof(texttoshow), "%s (%i)", texttoshow, ManaCost);
					}
					else
					{
						Format(texttoshow, sizeof(texttoshow), "%s (%.2f)", texttoshow, TimerSpecialAbility[client][MenuIndex[client]]);
						TimerSpecialAbility[client][MenuIndex[client]] -= 0.1;
					}
					
					Format(argkey, 64, "special_delimeter%i", MenuIndex[client]);
					FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, delimeter, sizeof(delimeter));
					
					if (!StrEqual(delimeter, NULL_STRING))
						Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, delimeter);
				}
				
				strcopy(AbilityName, sizeof(AbilityName),NULL_STRING);
				strcopy(delimeter, sizeof(delimeter),NULL_STRING);
				
				Format(argkey, 64, "reload_name%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				
				if (!StrEqual(AbilityName, NULL_STRING))
				{
					Format(argkey, 64, "reload_cost%i", MenuIndex[client]);
					int ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, AbilityName);
					
					Format(argkey, 64, "mam_reload_charge_max%i", MenuIndex[client]);
					int MaxCharge = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					if (ChargesReload[client][MenuIndex[client]]!=-1)
					{
						Format(texttoshow, sizeof(texttoshow), "%s [%i/%i]", texttoshow, ChargesReload[client][MenuIndex[client]], MaxCharge);
						
						if (ChargesReload[client][MenuIndex[client]]<MaxCharge && FF2_GetRoundState()==1)
						{
							Format(argkey, 64, "mam_reload_charge_regen%i", MenuIndex[client]);
							ReloadAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
							
							if (ReloadAbilityCharge[client][MenuIndex[client]]>=100)
							{
								ChargesReload[client][MenuIndex[client]] += 1;
								ReloadAbilityCharge[client][MenuIndex[client]] = 0.0;
							}
							
							Format(texttoshow, sizeof(texttoshow), "%s [%.2f]", texttoshow, ReloadAbilityCharge[client][MenuIndex[client]]);
						}
						else
							ReloadAbilityCharge[client][MenuIndex[client]] = 0.0;
					}
					
					if (TimerReloadAbility[client][MenuIndex[client]]<= 0.0)
					{
						if (ManaCost>0)
							Format(texttoshow, sizeof(texttoshow), "%s (%i)", texttoshow, ManaCost);
					}
					else
					{
						Format(texttoshow, sizeof(texttoshow), "%s (%.2f)", texttoshow, TimerReloadAbility[client][MenuIndex[client]]);
						TimerReloadAbility[client][MenuIndex[client]] -= 0.1;
					}
					
					Format(argkey, 64, "reload_delimeter%i", MenuIndex[client]);
					FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, delimeter, sizeof(delimeter));
					
					if (!StrEqual(delimeter, NULL_STRING))
						Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, delimeter);
				}
				
				strcopy(AbilityName, sizeof(AbilityName),NULL_STRING);
				strcopy(delimeter, sizeof(delimeter),NULL_STRING);
				
				Format(argkey, 64, "crtl_name%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				
				if (!StrEqual(AbilityName, NULL_STRING))
				{
					Format(argkey, 64, "crtl_cost%i", MenuIndex[client]);
					int ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, AbilityName);
					
					Format(argkey, 64, "mam_crtl_charge_max%i", MenuIndex[client]);
					int MaxCharge = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					if (ChargesCrtl[client][MenuIndex[client]]!=-1)
					{
						Format(texttoshow, sizeof(texttoshow), "%s [%i/%i]", texttoshow, ChargesCrtl[client][MenuIndex[client]], MaxCharge);
						
						if (ChargesCrtl[client][MenuIndex[client]]<MaxCharge && FF2_GetRoundState()==1)
						{
							Format(argkey, 64, "mam_crtl_charge_regen%i", MenuIndex[client]);
							CrtlAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
							
							if (CrtlAbilityCharge[client][MenuIndex[client]]>=100)
							{
								ChargesCrtl[client][MenuIndex[client]] += 1;
								CrtlAbilityCharge[client][MenuIndex[client]] = 0.0;
							}
							
							Format(texttoshow, sizeof(texttoshow), "%s [%.2f]", texttoshow, CrtlAbilityCharge[client][MenuIndex[client]]);
						}
						else
							CrtlAbilityCharge[client][MenuIndex[client]] = 0.0;
					}
					
					if (TimerCrtlAbility[client][MenuIndex[client]]<= 0.0)
					{
						if (ManaCost>0)
							Format(texttoshow, sizeof(texttoshow), "%s (%i)", texttoshow, ManaCost);
					}
					else
					{
						Format(texttoshow, sizeof(texttoshow), "%s (%.2f)", texttoshow, TimerCrtlAbility[client][MenuIndex[client]]);
						TimerCrtlAbility[client][MenuIndex[client]] -= 0.1;
					}
					
					Format(argkey, 64, "crtl_delimeter%i", MenuIndex[client]);
					FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, delimeter, sizeof(delimeter));
					
					if (!StrEqual(delimeter, NULL_STRING))
						Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, delimeter);
				}
				
				strcopy(AbilityName, sizeof(AbilityName),NULL_STRING);
				strcopy(delimeter, sizeof(delimeter),NULL_STRING);
				
				Format(argkey, 64, "alt_fire_name%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, AbilityName, sizeof(AbilityName));
				
				if (!StrEqual(AbilityName, NULL_STRING))
				{
					Format(argkey, 64, "alt_fire_cost%i", MenuIndex[client]);
					int ManaCost = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, AbilityName);
					
					Format(argkey, 64, "mam_alt_charge_max%i", MenuIndex[client]);
					int MaxCharge = FF2_GetArgNamedI(idBoss, this_plugin_name, MAM, argkey);
					
					if (ChargesAlt[client][MenuIndex[client]]!=-1)
					{
						Format(texttoshow, sizeof(texttoshow), "%s [%i/%i]", texttoshow, ChargesAlt[client][MenuIndex[client]], MaxCharge);
						
						if (ChargesAlt[client][MenuIndex[client]]<MaxCharge && FF2_GetRoundState()==1)
						{
							Format(argkey, 64, "mam_alt_charge_regen%i", MenuIndex[client]);
							AltAbilityCharge[client][MenuIndex[client]] += FF2_GetArgNamedF(idBoss, this_plugin_name, MAM, argkey);
							
							if (AltAbilityCharge[client][MenuIndex[client]]>=100)
							{
								ChargesAlt[client][MenuIndex[client]] += 1;
								AltAbilityCharge[client][MenuIndex[client]] = 0.0;
							}
							
							Format(texttoshow, sizeof(texttoshow), "%s [%.2f]", texttoshow, AltAbilityCharge[client][MenuIndex[client]]);
						}
						else
							AltAbilityCharge[client][MenuIndex[client]] = 0.0;
					}
					
					if (TimerAltAbility[client][MenuIndex[client]]<= 0.0)
					{
						if (ManaCost>0)
							Format(texttoshow, sizeof(texttoshow), "%s (%i)", texttoshow, ManaCost);
					}
					else
					{
						Format(texttoshow, sizeof(texttoshow), "%s (%.2f)", texttoshow, TimerAltAbility[client][MenuIndex[client]]);
						TimerAltAbility[client][MenuIndex[client]] -= 0.1;
					}
					
					Format(argkey, 64, "alt_fire_delimeter%i", MenuIndex[client]);
					FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, delimeter, sizeof(delimeter));
					
					if (!StrEqual(delimeter, NULL_STRING))
						Format(texttoshow, sizeof(texttoshow), "%s %s", texttoshow, delimeter);
				}
				
				char Pos[32][32], RGB[32][32], Position[1024], RGBA[1024];
				Format(argkey, 64, "menu_color%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, RGBA, sizeof(RGBA));
				Format(argkey, 64, "menu_position%i", MenuIndex[client]);
				FF2_GetArgNamedS(idBoss, this_plugin_name, MAM, argkey, Position, sizeof(Position));
				
				ExplodeString(RGBA, " ; ", RGB, sizeof(RGB), sizeof(RGB));
				ExplodeString(Position, " ; ", Pos, sizeof(Pos), sizeof(Pos)); 
				
				float x = StringToFloat(Pos[0]);
				float y = StringToFloat(Pos[1]);
				
				int R = StringToInt(RGB[0]);
				int G = StringToInt(RGB[1]);
				int B = StringToInt(RGB[2]);
				
				ReplaceString(texttoshow, sizeof(texttoshow), "\\n", "\n");
				
				Handle hHudText1 = CreateHudSynchronizer();
				SetHudTextParams(x, y, 0.11, R, G, B, 255);
				ShowSyncHudText(client, hHudText1, texttoshow);
				CloseHandle(hHudText1);
			}
		}
		else
		{
			if (HUDTimerMAM[client]!=INVALID_HANDLE)
			{
				KillTimer(HUDTimerMAM[client]);
				HUDTimerMAM[client] = INVALID_HANDLE;
			}
		}
	}
	else
	{
		if (HUDTimerMAM[client]!=INVALID_HANDLE)
		{
			KillTimer(HUDTimerMAM[client]);
			HUDTimerMAM[client] = INVALID_HANDLE;
		}
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		return Plugin_Continue;
	}
	if (!IsValidEntity(ClientShield[client]))
	{
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		return Plugin_Continue;
	}
	
	if (damagetype & DMG_FALL)
		return Plugin_Handled;
		
	
	if (ClientShieldHp[client] - damage > 0)
	{
		ClientShieldHp[client] -= RoundToCeil(damage);
		damage = 0.0;
		
		EmitSoundToClient(client, ")weapons/bison_main_shot.wav", client, _, _, _, 0.2);
		
		return Plugin_Changed;
	}
	else
	{
		damage -= ClientShieldHp[client];
		ClientShieldHp[client] = 0;
		
		TF2_RemoveWearable(client, ClientShield[client]);
		AcceptEntityInput(ClientShield[client], "Kill");
		ClientShield[client] = -1;
		
		EmitSoundToClient(client, ")weapons/sentry_damage4.wav", client, _, _, _, 1.0);
		
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);		
		
		return Plugin_Changed;
	}
}

public Action OnTakeDamageProtect(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsClientInGame(client))
	{
		ClientProtector[client] -= 1;
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageProtect);
		return Plugin_Continue;
	}
	if (!TF2_IsPlayerInCondition(client,TFCond_DefenseBuffNoCritBlock))
	{
		ClientProtector[client] -= 1;
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageProtect);
		return Plugin_Continue;
	}
	
	if (!IsValidClient(ClientProtector[client]))
	{
		ClientProtector[client] = -1;
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageProtect);
		return Plugin_Continue;
	}
	
	if (damagetype & DMG_FALL)
		return Plugin_Handled;
	
	if (ClientProtector[client]==client)
	{
		int idBoss = FF2_GetBossIndex(client);
		float PercentTakenFromDmg = FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "team_up_shield", 5, 0.3);
		damage = damage * PercentTakenFromDmg;
		return Plugin_Changed;
	}
	else
	{
		int idBoss = FF2_GetBossIndex(ClientProtector[client]);
		float PercentTakenFromDmgShare = FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "team_up_shield", 6, 0.3);
		damage = damage * (1.0-PercentTakenFromDmgShare);
		SDKHooks_TakeDamage(ClientProtector[client], attacker, inflictor, damage * PercentTakenFromDmgShare, damagetype, weapon, damageForce, damagePosition);
		
		return Plugin_Changed;
	}
}

public Action Timer_Heal_Self(Handle timer, int client)
{
	if (!IsClientInGame(client))
	{
		KillTimer(timer);
		return;
	}
		
	if (!IsPlayerAlive(client))
	{
		KillTimer(timer);
		return;
	}
			
	if (!TF2_IsPlayerInCondition(client, TFCond_Dazed))
	{
		KillTimer(timer);
		return;
	}
	
	int idBoss = FF2_GetBossIndex(client);
	
	int Heal = FF2_GetAbilityArgument(idBoss, this_plugin_name, "repair_healing", 4, 700);
	
	int Hp = FF2_GetBossHealth(idBoss);
	int MaxHp = FF2_GetBossMaxHealth(idBoss);
	int BossLives = FF2_GetBossLives(idBoss) - 1;
	
	if (Hp+Heal>=MaxHp)
		FF2_SetBossHealth(idBoss, MaxHp+BossLives*MaxHp);
	else
		FF2_SetBossHealth(idBoss, Hp+Heal+BossLives*MaxHp);
}

public Action Timer_Protect_Team(Handle timer, int client)
{
	if (!IsClientInGame(client))
	{
		KillTimer(timer);
		return;
	}
		
	if (!IsPlayerAlive(client))
	{
		KillTimer(timer);
		return;
	}
			
	if (!TF2_IsPlayerInCondition(client, TFCond_RuneResist))
	{
		KillTimer(timer);
		return;
	}
	
	int idBoss = FF2_GetBossIndex(client);
	
	float Radius = FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "team_up_shield", 4, 500.0);
	
	float HealRate = FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "team_up_shield", 3, 1.5);
	
	char Condition[64];
	FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "team_up_shield", 2, Condition, sizeof(Condition));
	
	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsClientInGame(player))
		{
			if (IsPlayerAlive(player) && TF2_GetClientTeam(client)==TF2_GetClientTeam(player))
			{
				float ClientOrigin[3], PlayerOrigin[3];
				GetClientAbsOrigin(client, ClientOrigin);
				GetClientAbsOrigin(player, PlayerOrigin);
				
				if (Radius >= GetVectorDistance(PlayerOrigin,ClientOrigin))
				{
					if (!StrEqual(Condition,NULL_STRING))
						SetCondition(player, Condition);
					
					if (!TF2_IsPlayerInCondition(player, TFCond_DefenseBuffNoCritBlock))
					{
						EmitSoundToClient(player, ")items/powerup_pickup_agility.wav", player);
						SDKHook(player, SDKHook_OnTakeDamageAlive, OnTakeDamageProtect);
					}
					
					TF2_AddCondition(player, TFCond_DefenseBuffNoCritBlock, HealRate+0.2);
					
					if (player!=client)
						CreateTimer(HealRate+0.2, Timer_RemoveEntity, EntIndexToEntRef(ConnectWithBeam(client, player, 50, 50, 255, 1.0, 1.0, 1.35, LASERBEAM)), TIMER_FLAG_NO_MAPCHANGE);
					
					ClientProtector[player] = client;
				}
			}
		}
	}
}

public Action Timer_Heal_Team(Handle timer, int client)
{
	if (!IsClientInGame(client))
	{
		KillTimer(timer);
		return;
	}
		
	if (!IsPlayerAlive(client))
	{
		KillTimer(timer);
		return;
	}
			
	if (!TF2_IsPlayerInCondition(client, TFCond_RuneRegen))
	{
		KillTimer(timer);
		return;
	}
	
	int idBoss = FF2_GetBossIndex(client);
	
	int Heal = FF2_GetAbilityArgument(idBoss, this_plugin_name, "team_healing", 4, 100);
	
	float Radius = FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "team_healing", 5, 500.0);
	
	float HealRate = FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "team_healing", 3, 1.5);
	
	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsClientInGame(player))
		{
			if (IsPlayerAlive(player) && TF2_GetClientTeam(client)==TF2_GetClientTeam(player))
			{
				float ClientOrigin[3], PlayerOrigin[3];
				GetClientAbsOrigin(client, ClientOrigin);
				GetClientAbsOrigin(player, PlayerOrigin);
				
				if (Radius >= GetVectorDistance(PlayerOrigin,ClientOrigin))
				{
					int BossHealed = FF2_GetBossIndex(player);
					if (BossHealed>-1)
					{
						int Hp = FF2_GetBossHealth(BossHealed);
						int MaxHp = FF2_GetBossMaxHealth(BossHealed);
						int BossLives = FF2_GetBossLives(BossHealed)-1;
						
						if (Hp+Heal>=MaxHp)
							FF2_SetBossHealth(BossHealed, MaxHp+BossLives*MaxHp);
						else
							FF2_SetBossHealth(BossHealed, Hp + Heal+BossLives*MaxHp);
						
					}
					else
					{
						int Health = GetClientHealth(player);
						int Maxhealth = TF2_GetPlayerMaxHealth(player);
										
						if(Health+Heal>=Maxhealth)
							SetEntityHealth(player, Maxhealth);
						else
							SetEntityHealth(player, Health);
						
						
					}
					
					EmitSoundToClient(player, ")weapons/vaccinator_charge_tier_04.wav", player);
					
					if (player!=client)
						CreateTimer(HealRate+0.2, Timer_RemoveEntity, EntIndexToEntRef(ConnectWithBeam(client, player, 50, 255, 50, 1.0, 1.0, 1.35, LASERBEAM)), TIMER_FLAG_NO_MAPCHANGE);
					
					TF2_AddCondition(player, TFCond_InHealRadius, FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "team_healing", 3, 500.0));
				}
			}
		}
	}
}

stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

public Action Timer_Reset_RGBA(Handle timer, int client)
{
	if (IsValidEdict(client) && IsClientInGame(client))
	{
		int idBoss = FF2_GetBossIndex(client);			
		if (FF2_HasAbility(idBoss, this_plugin_name, "tp_to_tp"))
		{
			char RGBA[64], RBGAList[32][32];
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "tp_to_tp", 6, RGBA, sizeof(RGBA));
			
			ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
			
			int R = StringToInt(RBGAList[0]);
			int G = StringToInt(RBGAList[1]);
			int B = StringToInt(RBGAList[2]);
			int A = StringToInt(RBGAList[3]);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			ColorizeAllEntityFrom(client, R, G, B, A);
		}
		
		if (FF2_HasAbility(idBoss, this_plugin_name, "quick_escape"))
		{
			char RGBA[64], RBGAList[32][32];
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "quick_escape", 6, RGBA, sizeof(RGBA));
			
			ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
			
			int R = StringToInt(RBGAList[0]);
			int G = StringToInt(RBGAList[1]);
			int B = StringToInt(RBGAList[2]);
			int A = StringToInt(RBGAList[3]);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			ColorizeAllEntityFrom(client, R, G, B, A);
		}
	}
}

public void OnEntityCreated(int ient, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_spellfireball"))
	{
		SDKHook(ient, SDKHook_SpawnPost, Change_FireBall);
	}
}

public Action Change_FireBall(int ient)
{
	if (IsValidEntity(ient))
	{
		int client = GetEntPropEnt(ient, Prop_Send, "m_hOwnerEntity");
		
		if (!IsValidClient(client))
		{
			SDKUnhook(ient, SDKHook_SpawnPost, Change_FireBall);
			return Plugin_Continue;
		}
		
		int idBoss = FF2_GetBossIndex(client);
		
		if (idBoss>0)
		{
			SDKUnhook(ient, SDKHook_SpawnPost, Change_FireBall);
			return Plugin_Continue;
		}
		
		if (!FF2_HasAbility(idBoss, this_plugin_name,"cursed_rocket"))
		{
			SDKUnhook(ient, SDKHook_SpawnPost, Change_FireBall);
			return Plugin_Continue;
		}
		
		float position[3], angle[3], velocity[3], vBuffer[3];
		GetEntPropVector(ient, Prop_Send, "m_vecOrigin", position);
		GetEntPropVector(ient, Prop_Data, "m_angRotation", angle);
		GetAngleVectors(angle, vBuffer, NULL_VECTOR, NULL_VECTOR);	
		
		AcceptEntityInput(ient, "Kill");
		
		int iSpell = CreateEntityByName("tf_projectile_rocket");
		
		if(!IsValidEntity(iSpell))
			return Plugin_Continue;
		
		float Speeed = FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "cursed_rocket", 1, 1100.0);
		
		velocity[0] = vBuffer[0]*Speeed; //Speed of a tf2 rocket.
		velocity[1] = vBuffer[1]*Speeed;
		velocity[2] = vBuffer[2]*Speeed;
		
		SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(iSpell, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(iSpell, Prop_Send, "m_nSkin", GetClientTeam(client));
		
		SetEntDataFloat(iSpell, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, FF2_GetAbilityArgumentFloat(idBoss, this_plugin_name, "cursed_rocket", 2, 100.0), true);    // Damage
		
		
		SetVariantInt(GetClientTeam(client));
		AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
		SetVariantInt(GetClientTeam(client));
		AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0);
		
		TeleportEntity(iSpell, position, angle, velocity);
		DispatchSpawn(iSpell);
		TeleportEntity(iSpell, position, angle, velocity);
		
		char Model[1024], ParticleToRocket[32];
		FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "cursed_rocket", 3, Model, sizeof(Model));
		FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "cursed_rocket", 4, ParticleToRocket, sizeof(ParticleToRocket));
		
		
		if (!StrEqual(Model,NULL_STRING))
		{
			PrecacheModel(Model);
			SetEntityModel(iSpell, Model);
		}
		
		if (!StrEqual(ParticleToRocket,NULL_STRING))
			CreateTimer(15.0, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(iSpell, ParticleToRocket, _, true)), TIMER_FLAG_NO_MAPCHANGE);
	}
	SDKUnhook(ient, SDKHook_SpawnPost, Change_FireBall);
	return Plugin_Continue;
}

stock AttachParticle(entity, char[] particleType, float offset[3]={0.0,0.0,0.0}, bool attach=true)
{
	int particle=CreateEntityByName("info_particle_system");

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[0]+=offset[0];
	position[1]+=offset[1];
	position[2]+=offset[2];
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

public Action FF2_OnAbility2(boss,const char[] plugin_name,const char[] ability_name,action)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	
	if(!strcmp(ability_name, "cursed_rocket"))
	{
		int book = TF2_GetPlayerSpellBook(client);
		
		SetEntProp(book, Prop_Send, "m_iSpellCharges", 1);
		
		SetEntProp(book, Prop_Send, "m_iSelectedSpellIndex", 0);
		
		FakeClientCommand(client, "use tf_weapon_spellbook");
	}
	
	if(!strcmp(ability_name, "repair_healing"))
	{
		char Condition[64];
		float StuntDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "repair_healing", 1, 5.0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "repair_healing", 2, Condition, sizeof(Condition));
		if (!StrEqual(Condition,NULL_STRING))
			SetCondition(client, Condition);
		
		TF2_StunPlayer(client, StuntDuration, 1.0,TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_BONKSTUCK);
		
		float HealRate = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "repair_healing", 3, 1.5);
		CreateTimer(HealRate, Timer_Heal_Self, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	
	if(!strcmp(ability_name, "team_healing"))
	{
		char Condition[64];
		float StuntDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_healing", 1, 5.0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "team_healing", 2, Condition, sizeof(Condition));
		if (!StrEqual(Condition,NULL_STRING))
			SetCondition(client, Condition);
		
		TF2_AddCondition(client, TFCond_RuneRegen, StuntDuration);
		
		int Heal = FF2_GetAbilityArgument(boss, this_plugin_name, "team_healing", 4, 100);
	
		float Radius = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_healing", 5, 500.0);
		
		float HealRate = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_healing", 3, 1.5);
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)==TF2_GetClientTeam(player))
				{
					float ClientOrigin[3], PlayerOrigin[3];
					GetClientAbsOrigin(client, ClientOrigin);
					GetClientAbsOrigin(player, PlayerOrigin);
					
					if (Radius >= GetVectorDistance(PlayerOrigin,ClientOrigin))
					{
						int BossHealed = FF2_GetBossIndex(player);
						if (BossHealed>-1)
						{
							int Hp = FF2_GetBossHealth(BossHealed);
							int MaxHp = FF2_GetBossMaxHealth(BossHealed);
							int BossLives = FF2_GetBossLives(BossHealed)-1;
							
							if (Hp+Heal>=MaxHp)
								FF2_SetBossHealth(BossHealed, MaxHp+BossLives*MaxHp);
							else
								FF2_SetBossHealth(BossHealed, Hp + Heal+BossLives*MaxHp);
							
						}
						else
						{
							int Health = GetClientHealth(player);
							int Maxhealth = TF2_GetPlayerMaxHealth(player);
											
							if(Health+Heal>=Maxhealth)
								SetEntityHealth(player, Maxhealth);
							else
								SetEntityHealth(player, Health);
							
							
						}
							
						EmitSoundToClient(player, ")weapons/vaccinator_charge_tier_04.wav", player);
						
						if (player!=client)
							CreateTimer(HealRate+0.2, Timer_RemoveEntity, EntIndexToEntRef(ConnectWithBeam(client, player, 50, 255, 50, 1.0, 1.0, 1.35, LASERBEAM)), TIMER_FLAG_NO_MAPCHANGE);
						
						TF2_AddCondition(player, TFCond_InHealRadius, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_healing", 3, 500.0));
					}
				}
			}
		}
		
		CreateTimer(HealRate, Timer_Heal_Team, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	
	if(!strcmp(ability_name, "setup_tp"))
	{
		GetClientAbsOrigin(client, TpPosition[client]);
	}
	
	if(!strcmp(ability_name, "quick_escape"))
	{
		char Cond[64], EffectName[128];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "quick_escape", 1, Cond, sizeof(Cond));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "quick_escape", 2, EffectName, sizeof(EffectName));
		float Duration = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"quick_escape",3, 3.0);
		
		char RGBA[64], RBGAList[32][32], RGBAImage[64], RBGAImageList[32][32];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "quick_escape", 4, RGBAImage, sizeof(RGBAImage));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "quick_escape", 5, RGBA, sizeof(RGBA));
		
		ExplodeString(RGBAImage, " ; ", RBGAImageList, sizeof(RBGAImageList), sizeof(RBGAImageList));
		
		int RImage = StringToInt(RBGAImageList[0]);
		int GImage = StringToInt(RBGAImageList[1]);
		int BImage = StringToInt(RBGAImageList[2]);
		int AImage = StringToInt(RBGAImageList[3]);
		
		MakeAnImage(client, Duration, EffectName, RImage, GImage, BImage, AImage);
		
		if (!StrEqual(Cond,NULL_STRING))
			SetCondition(client, Cond);
			
		ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
		
		int R = StringToInt(RBGAList[0]);
		int G = StringToInt(RBGAList[1]);
		int B = StringToInt(RBGAList[2]);
		int A = StringToInt(RBGAList[3]);
		float ChangeRGBADuration = StringToFloat(RBGAList[4]);
		
		if (ChangeRGBADuration>0.0)
		{
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			CreateTimer(ChangeRGBADuration, Timer_Reset_RGBA, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		float EscapeSpeed = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"quick_escape",7, 0.0);
		if (EscapeSpeed>0.0)
		{
			TF2_AddCondition(client, TFCond_AfterburnImmune, ChangeRGBADuration);
			SDKHook(client, SDKHook_PreThink, ClientSpeed);
		}
		
		ColorizeAllEntityFrom(client, R, G, B, A);
	}
	
	if(!strcmp(ability_name, "tp_to_tp"))
	{
		char Cond[64], EffectName[128];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "tp_to_tp", 1, Cond, sizeof(Cond));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "tp_to_tp", 2, EffectName, sizeof(EffectName));
		float Duration = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"tp_to_tp",3, 3.0);
		
		char RGBA[64], RBGAList[32][32], RGBAImage[64], RBGAImageList[32][32];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "tp_to_tp", 4, RGBAImage, sizeof(RGBAImage));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "tp_to_tp", 5, RGBA, sizeof(RGBA));
		
		ExplodeString(RGBAImage, " ; ", RBGAImageList, sizeof(RBGAImageList), sizeof(RBGAImageList));
		
		int RImage = StringToInt(RBGAImageList[0]);
		int GImage = StringToInt(RBGAImageList[1]);
		int BImage = StringToInt(RBGAImageList[2]);
		int AImage = StringToInt(RBGAImageList[3]);
		
		MakeAnImage(client, Duration, EffectName, RImage, GImage, BImage, AImage);
		TeleportEntity(client, TpPosition[client], NULL_VECTOR, NULL_VECTOR);
		
		if (!StrEqual(Cond,NULL_STRING))
			SetCondition(client, Cond);
			
		ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
		
		int R = StringToInt(RBGAList[0]);
		int G = StringToInt(RBGAList[1]);
		int B = StringToInt(RBGAList[2]);
		int A = StringToInt(RBGAList[3]);
		float ChangeRGBADuration = StringToFloat(RBGAList[4]);
		
		if (ChangeRGBADuration>0.0)
		{
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			CreateTimer(ChangeRGBADuration, Timer_Reset_RGBA, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		ColorizeAllEntityFrom(client, R, G, B, A);
	}
	
	if(!strcmp(ability_name, "remove_all_debuff"))
	{
		char Condition[64];
		float Radius = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "remove_all_debuff", 1, 300.0);
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "remove_all_debuff", 2, Condition, sizeof(Condition));
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)==TF2_GetClientTeam(player))
				{
					float ClientOrigin[3], PlayerOrigin[3];
					GetClientAbsOrigin(client, ClientOrigin);
					GetClientAbsOrigin(player, PlayerOrigin);
					
					if (Radius >= GetVectorDistance(PlayerOrigin,ClientOrigin))
					{
						if (!StrEqual(Condition,NULL_STRING))
							SetCondition(player, Condition);
							
						TF2_RemoveCondition(player, TFCond_OnFire);
						TF2_RemoveCondition(player, TFCond_MarkedForDeath);
						TF2_RemoveCondition(player, TFCond_MarkedForDeathSilent);
						TF2_RemoveCondition(player, TFCond_Jarated);
						TF2_RemoveCondition(player, TFCond_Milked);
						TF2_RemoveCondition(player, TFCond_Bleeding);
						
						EmitSoundToClient(player, ")weapons/rescue_ranger_charge_01.wav", player);
					}
				}
			}
		}
	}
	
	if(!strcmp(ability_name, "aim_assister"))
	{
		TF2_AddCondition(client, TFCond_RunePrecision, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "aim_assister", 1, 10.0));
	}
	
	if(!strcmp(ability_name, "mam_change_menu"))
	{
		char argkey[64];
		Format(argkey, 64, "slot_change%i", MenuIndex[client]);
		
		MenuIndex[client] = FF2_GetArgNamedI(boss, plugin_name, "mam_change_menu", argkey);
		
		Format(argkey, 64, "mana_start_change%i", MenuIndex[client]);
		int ManaToAddChange = FF2_GetArgNamedI(boss, this_plugin_name, MAM, argkey);
		
		if (ManaToAddChange>0)
			ManaNumber[client][MenuIndex[client]] = ManaToAddChange*1.0;
		
		
		char model[PLATFORM_MAX_PATH];
		Format(argkey, 64, "boss_model%i", MenuIndex[client]);
		FF2_GetArgNamedS(boss, this_plugin_name, "mam_change_menu", argkey, model, sizeof(model));
		
		if (!StrEqual(model, NULL_STRING))
		{
			SetVariantString(model);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		}
		
		for (int i = 0; i < 10; i++)
		{
			char classname[64], attributes[64];
			
			Format(argkey, 64, "weapon_classname%i-%i", MenuIndex[client],i);
			FF2_GetArgNamedS(boss, this_plugin_name, "mam_change_menu", argkey, classname, sizeof(classname));
			
			if (!StrEqual(classname, NULL_STRING))
			{
				Format(argkey, 64, "weapon_attributes%i-%i", MenuIndex[client],i);
				FF2_GetArgNamedS(boss, this_plugin_name, "mam_change_menu", argkey, attributes, sizeof(attributes));
				
				Format(argkey, 64, "weapon_index%i-%i", MenuIndex[client],i);
				int index = FF2_GetArgNamedI(boss, plugin_name, "mam_change_menu", argkey);
				
				Format(argkey, 64, "weapon_level%i-%i", MenuIndex[client],i);
				int level = FF2_GetArgNamedI(boss, plugin_name, "mam_change_menu", argkey);
				
				Format(argkey, 64, "weapon_quality%i-%i", MenuIndex[client],i);
				int quality = FF2_GetArgNamedI(boss, plugin_name, "mam_change_menu", argkey);
				
				Format(argkey, 64, "weapon_slot%i-%i", MenuIndex[client],i);
				int weaponslot = FF2_GetArgNamedI(boss, plugin_name, "mam_change_menu", argkey);
				
				if (weaponslot == -1)
					TF2_RemoveAllWeapons(client);
				else
					TF2_RemoveWeaponSlot(client, weaponslot);
				
				int weaponid = FF2_SpawnWeapon(client, classname, index, level, quality, attributes);
				
				Format(argkey, 64, "weapon_ammo%i-%i", MenuIndex[client],i);
				int ammo = FF2_GetArgNamedI(boss, plugin_name, "mam_change_menu", argkey, -2);
				
				Format(argkey, 64, "weapon_clip%i-%i", MenuIndex[client],i);
				int clip = FF2_GetArgNamedI(boss, plugin_name, "mam_change_menu", argkey, -2);
				
				if (ammo!=2 && clip!=-2)
					FF2_SetAmmo(client, weaponid, ammo, clip);
			}
			else
				break;
		}
	}
	
	if(!strcmp(ability_name, "smash_up"))
	{
		float SmashDistance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_up", 1, 300.0);
		float Damage = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_up", 2, 400.0);
		float VelocityForce = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_up", 3, 400.0);
		float MiniDash = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_up", 4, 400.0);
		float AddCombo = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_up", 5, 2.0);
		float AddComboTimer = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_up", 6, 2.0);
		
		char ParticleName[124], ParticleAttachement[124];
		float EffectDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_up", 7, 0.0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "smash_up", 8, ParticleName, sizeof(ParticleName));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "smash_up", 9, ParticleAttachement, sizeof(ParticleAttachement));
		
		if (EffectDuration>0.0)
			CreateTimer(EffectDuration, Timer_RemoveEntity, EntIndexToEntRef(CreateParticleAttach(ParticleName, client, ParticleAttachement)), TIMER_FLAG_NO_MAPCHANGE);
		
		float VelocitySmash[3] = { 0.0, 0.0, 0.0 };
		
		static float angles[3];
		GetClientEyeAngles(client, angles);
		GetAngleVectors(angles, VelocitySmash, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(VelocitySmash, MiniDash);
		
		VelocitySmash[2] = VelocityForce;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
		
		VelocitySmash[0] = 0.0;
		VelocitySmash[1] = 0.0;
		
		int EnemyCount = 0;
		bool EnemyHit[MAXPLAYERS + 1] = false;
		bool YouHitPlayer = false;
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)!=TF2_GetClientTeam(player) && IsAbleToSee(client, player, _, SmashDistance))
				{
					EnemyCount += 1;
					EnemyHit[player] = true;
					YouHitPlayer = true;
					SDKHooks_TakeDamage(player, client, client, Damage*ComboMultiplier[client], DMG_CLUB);
					TeleportEntity(player, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
				}
			}
		}
		for (int playerdmg = 1; playerdmg <= MaxClients; playerdmg++)
		{
			if (IsClientInGame(playerdmg))
			{
				if (IsPlayerAlive(playerdmg) && EnemyHit[playerdmg])
				{
					SDKHooks_TakeDamage(playerdmg, client, client, (Damage/EnemyCount)*ComboMultiplier[client], DMG_CLUB);
				}
			}
		}
		
		if (YouHitPlayer)
		{
			if (ComboTimer[client]<=0.0)
			{
				ComboTimer[client] = AddComboTimer;
				ComboMultiplier[client] += AddCombo;
				CreateTimer(0.1, Remove_Combo_Timer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
			else
			{
				ComboTimer[client] += AddComboTimer;
				ComboMultiplier[client] += AddCombo;
			}
		}
	}
	
	if(!strcmp(ability_name, "smash_down"))
	{
		float SmashDistance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_down", 1, 300.0);
		float Damage = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_down", 2, 400.0);
		float VelocityForce = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_down", 3, 400.0);
		float MiniDash = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_down", 4, 400.0);
		float AddCombo = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_down", 5, 2.0);
		float AddComboTimer = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_down", 6, 2.0);
		
		char ParticleName[124], ParticleAttachement[124];
		float EffectDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "smash_down", 7, 0.0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "smash_down", 8, ParticleName, sizeof(ParticleName));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "smash_down", 9, ParticleAttachement, sizeof(ParticleAttachement));
		
		if (EffectDuration>0.0)
			CreateTimer(EffectDuration, Timer_RemoveEntity, EntIndexToEntRef(CreateParticleAttach(ParticleName, client, ParticleAttachement)), TIMER_FLAG_NO_MAPCHANGE);
		
		
		float VelocitySmash[3] = { 0.0, 0.0, 0.0 };
		
		static float angles[3];
		GetClientEyeAngles(client, angles);
		GetAngleVectors(angles, VelocitySmash, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(VelocitySmash, MiniDash);
		
		VelocitySmash[2] = -VelocityForce;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
		
		VelocitySmash[0] = 0.0;
		VelocitySmash[1] = 0.0;
		
		int EnemyCount = 0;
		bool EnemyHit[MAXPLAYERS + 1] = false;
		bool YouHitPlayer = false;
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)!=TF2_GetClientTeam(player) && IsAbleToSee(client, player, _, SmashDistance))
				{
					EnemyCount += 1;
					EnemyHit[player] = true;
					YouHitPlayer = true;
					SDKHooks_TakeDamage(player, client, client, Damage*ComboMultiplier[client], DMG_CLUB);
					TeleportEntity(player, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
				}
			}
		}
		for (int playerdmg = 1; playerdmg <= MaxClients; playerdmg++)
		{
			if (IsClientInGame(playerdmg))
			{
				if (IsPlayerAlive(playerdmg) && EnemyHit[playerdmg])
				{
					SDKHooks_TakeDamage(playerdmg, client, client, (Damage/EnemyCount)*ComboMultiplier[client], DMG_CLUB);
				}
			}
		}
		
		if (YouHitPlayer)
		{
			if (ComboTimer[client]<=0.0)
			{
				ComboTimer[client] = AddComboTimer;
				ComboMultiplier[client] += AddCombo;
				CreateTimer(0.1, Remove_Combo_Timer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
			else
			{
				ComboTimer[client] += AddComboTimer;
				ComboMultiplier[client] += AddCombo;
			}
		}
	}
	
	if(!strcmp(ability_name, "velocity_punch"))
	{
		float SmashDistance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "velocity_punch", 1, 300.0);
		float Damage = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "velocity_punch", 2, 400.0);
		float VelocityForce = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "velocity_punch", 3, 400.0);
		float MiniDash = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "velocity_punch", 4, 400.0);
		float AddCombo = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "velocity_punch", 5, 2.0);
		float AddComboTimer = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "velocity_punch", 6, 2.0);
		
		char ParticleName[124], ParticleAttachement[124];
		float EffectDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "velocity_punch", 7, 0.0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "velocity_punch", 8, ParticleName, sizeof(ParticleName));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "velocity_punch", 9, ParticleAttachement, sizeof(ParticleAttachement));
		
		if (EffectDuration>0.0)
			CreateTimer(EffectDuration, Timer_RemoveEntity, EntIndexToEntRef(CreateParticleAttach(ParticleName, client, ParticleAttachement)), TIMER_FLAG_NO_MAPCHANGE);
				
		
		float VelocitySmash[3] = { 0.0, 0.0, 0.0 };
		
		static float angles[3];
		GetClientEyeAngles(client, angles);
		GetAngleVectors(angles, VelocitySmash, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(VelocitySmash, VelocityForce);
		
		VelocitySmash[2] += MiniDash;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
		
		int EnemyCount = 0;
		bool EnemyHit[MAXPLAYERS + 1] = false;
		bool YouHitPlayer = false;
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)!=TF2_GetClientTeam(player) && IsAbleToSee(client, player, _, SmashDistance))
				{
					EnemyCount += 1;
					EnemyHit[player] = true;
					YouHitPlayer = true;
					SDKHooks_TakeDamage(player, client, client, Damage*ComboMultiplier[client], DMG_CLUB);
					TeleportEntity(player, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
				}
			}
		}
		for (int playerdmg = 1; playerdmg <= MaxClients; playerdmg++)
		{
			if (IsClientInGame(playerdmg))
			{
				if (IsPlayerAlive(playerdmg) && EnemyHit[playerdmg])
				{
					SDKHooks_TakeDamage(playerdmg, client, client, (Damage/EnemyCount)*ComboMultiplier[client], DMG_CLUB);
				}
			}
		}
		
		if (YouHitPlayer)
		{
			if (ComboTimer[client]<=0.0)
			{
				ComboTimer[client] = AddComboTimer;
				ComboMultiplier[client] += AddCombo;
				CreateTimer(0.1, Remove_Combo_Timer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
			else
			{
				ComboTimer[client] += AddComboTimer;
				ComboMultiplier[client] += AddCombo;
			}
		}
	}
	
	if(!strcmp(ability_name, "escape_dash"))
	{
		char Condition[64];
		float DashDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "escape_dash", 1, 0.7);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "escape_dash", 2, Condition, sizeof(Condition));
		float VelocityForce = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "escape_dash", 3, 400.0);
		float MiniDash = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "escape_dash", 4, 400.0);
		
		char ParticleName[124], ParticleAttachement[124];
		float EffectDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "escape_dash", 5, 0.0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "escape_dash", 6, ParticleName, sizeof(ParticleName));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "escape_dash", 7, ParticleAttachement, sizeof(ParticleAttachement));
		
		if (EffectDuration>0.0)
			CreateTimer(EffectDuration, Timer_RemoveEntity, EntIndexToEntRef(CreateParticleAttach(ParticleName, client, ParticleAttachement)), TIMER_FLAG_NO_MAPCHANGE);
		
		float VelocitySmash[3] = { 0.0, 0.0, 0.0 };
		
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", BaseVelocity[client]);
		
		static float angles[3];
		GetClientAbsAngles(client, angles);
		
		bool LeftAndRight = false;
		if (GetClientButtons(client) & IN_MOVELEFT)		
		{
			if (GetClientButtons(client) & IN_FORWARD)
				angles[1] += 45.0;
			else if (GetClientButtons(client) & IN_BACK)
				angles[1] += 135.0;
			else
				angles[1] += 90.0;
				
			LeftAndRight = true;
		}
		
		if (GetClientButtons(client) & IN_MOVERIGHT)		
		{
			if (GetClientButtons(client) & IN_FORWARD)
				angles[1] -= 45.0;
			else if (GetClientButtons(client) & IN_BACK)
				angles[1] -= 135.0;
			else
				angles[1] -= 90.0;
			
			if (!LeftAndRight)
				LeftAndRight = true;
			else
				LeftAndRight = false;
		}
		
		if (GetClientButtons(client) & IN_BACK && !LeftAndRight)		
		{
			angles[1] -= 180.0;
		}
		
		fixAngles(angles);
		
		GetAngleVectors(angles, VelocitySmash, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(VelocitySmash, VelocityForce);
		
		if (!StrEqual(Condition,NULL_STRING))
			SetCondition(client, Condition);
		
		VelocitySmash[2] += MiniDash;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
		
		CreateTimer(DashDuration, Remove_Velocity, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(!strcmp(ability_name, "focused_healing"))
	{
		float StartOrigin[3], Angles[3], vecPos[3];
		GetClientEyeAngles(client, Angles);
		GetClientEyePosition(client, StartOrigin);
		
		Handle TraceRay = TR_TraceRayFilterEx(StartOrigin, Angles, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceRayProp);
		if (TR_DidHit(TraceRay))
			TR_GetEndPosition(vecPos, TraceRay);
			
		delete TraceRay;
		
		int HealedBoss = FindClosestTeammateToPoint(client, vecPos);
		
		char Condition[64];
		int Heal = FF2_GetAbilityArgument(boss, this_plugin_name, "focused_healing", 1, 1000);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "focused_healing", 2, Condition, sizeof(Condition));
		
	
		int BossHealed = FF2_GetBossIndex(HealedBoss);
		if (BossHealed>-1)
		{
			int Hp = FF2_GetBossHealth(BossHealed);
			int MaxHp = FF2_GetBossMaxHealth(BossHealed);
			int BossLives = FF2_GetBossLives(BossHealed)-1;
			
			if (Hp+Heal>=MaxHp)
				FF2_SetBossHealth(BossHealed, MaxHp+BossLives*MaxHp);
			else
				FF2_SetBossHealth(BossHealed, Hp + Heal+BossLives*MaxHp);
			
		}
		else
		{
			int Health = GetClientHealth(HealedBoss);
			int Maxhealth = TF2_GetPlayerMaxHealth(HealedBoss);
							
			if(Health+Heal>=Maxhealth)
				SetEntityHealth(HealedBoss, Maxhealth);
			else
				SetEntityHealth(HealedBoss, Health);
			
			
		}
		
		EmitSoundToClient(HealedBoss, ")items/powerup_pickup_uber.wav", HealedBoss);
		
		if (!StrEqual(Condition,NULL_STRING))
			SetCondition(HealedBoss, Condition);
	}
	
	if(!strcmp(ability_name, "slam_ground"))
	{
		float SmashDistance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "slam_ground", 1, 300.0);
		float Damage = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "slam_ground", 2, 400.0);
		float VelocityForce = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "slam_ground", 3, 400.0);
		float VelocitySmash[3] = { 0.0, 0.0, 0.0 };
		
		VelocitySmash[2] = VelocityForce;
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)!=TF2_GetClientTeam(player))
				{
					float ClientPos[3], PlayerPos[3];
					GetClientAbsOrigin(client,ClientPos);
					GetClientAbsOrigin(player,PlayerPos);
					if (SmashDistance>=GetVectorDistance(PlayerPos, ClientPos))
					{
						SDKHooks_TakeDamage(player, client, client, Damage, DMG_CLUB);
						TeleportEntity(player, NULL_VECTOR, NULL_VECTOR, VelocitySmash);
					}
				}
			}
		}
	}
	
	if(!strcmp(ability_name, "team_shield"))
	{
		float MaxDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_shield", 1, 0.0);
		int ShieldHp = FF2_GetAbilityArgument(boss, this_plugin_name, "team_shield", 2, 1000);
		float Distance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_shield", 3, 400.0);
		
		char model[PLATFORM_MAX_PATH], RGBA[64], RBGAList[32][32], ShieldAttributes[64];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "team_shield", 4, model, sizeof(model));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "team_shield", 5, RGBA, sizeof(RGBA));
		
		float Size = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_shield", 6, 1.0);
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "team_shield", 7, ShieldAttributes, sizeof(ShieldAttributes));
		
		ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
		
		int R = StringToInt(RBGAList[0]);
		int G = StringToInt(RBGAList[1]);
		int B = StringToInt(RBGAList[2]);
		int A = StringToInt(RBGAList[3]);
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)==TF2_GetClientTeam(player))
				{
					float ClientPos[3], PlayerPos[3];
					GetClientAbsOrigin(client,ClientPos);
					GetClientAbsOrigin(player,PlayerPos);
					if (Distance>=GetVectorDistance(PlayerPos, ClientPos))
					{
						if (IsValidEntity(ClientShield[player]))
						{
							ClientShieldHp[player] += ShieldHp;
							ShieldTimer[player] += MaxDuration;
							
							
							
							EmitSoundToClient(player, ")weapons/sentry_move_short2.wav", player);
						}
						else
						{
							int Wearable = TF2_CreateAndEquipWearable(player, "tf_wearable", 30003, 101, 13, ShieldAttributes);
							
							SDK_EquipWearable(player, Wearable);
							
							int modelIndex = PrecacheModel(model);
							SetEntProp(Wearable, Prop_Send, "m_nModelIndex", modelIndex);
							SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 1);
							SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 2);
							SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 3);
							SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", GetEntProp(Wearable, Prop_Send, "m_nModelIndex"), _, 0);
							
							SetEntPropFloat(Wearable, Prop_Send, "m_flModelScale", Size);
							
							SetEntityRenderMode(Wearable, RENDER_TRANSCOLOR);
							SetEntityRenderColor(Wearable, R, G, B, A);
							
							if (MaxDuration>0.0)
							{
								ShieldTimer[player] = MaxDuration;
								CreateTimer(0.1, Remove_Shield_Timer, player, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
							}
							
							EmitSoundToClient(player, ")weapons/sentry_finish.wav", player);
							
							SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
							
							ClientShieldHp[player] = ShieldHp;
							ClientShield[player] = Wearable;
						}
					}
				}
			}
		}
	}
	
	if(!strcmp(ability_name, "team_up_shield"))
	{
		float Duration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_up_shield", 1, 5.0);
		
		TF2_AddCondition(client, TFCond_RuneResist, Duration);
		
		float Radius = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_up_shield", 4, 500.0);
	
		float HealRate = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_up_shield", 3, 1.5);
		
		char Condition[64];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "team_up_shield", 2, Condition, sizeof(Condition));
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)==TF2_GetClientTeam(player))
				{
					float ClientOrigin[3], PlayerOrigin[3];
					GetClientAbsOrigin(client, ClientOrigin);
					GetClientAbsOrigin(player, PlayerOrigin);
					
					if (Radius >= GetVectorDistance(PlayerOrigin,ClientOrigin))
					{
						if (!StrEqual(Condition,NULL_STRING))
							SetCondition(player, Condition);
						
						if (!TF2_IsPlayerInCondition(player, TFCond_DefenseBuffNoCritBlock))
						{
							EmitSoundToClient(player, ")items/powerup_pickup_reflect.wav", player);
							SDKHook(player, SDKHook_OnTakeDamageAlive, OnTakeDamageProtect);
						}
						
						TF2_AddCondition(player, TFCond_DefenseBuffNoCritBlock, HealRate+0.2);
						
						if (player!=client)
							CreateTimer(HealRate+0.2, Timer_RemoveEntity, EntIndexToEntRef(ConnectWithBeam(client, player, 50, 50, 255, 1.0, 1.0, 1.35, LASERBEAM)), TIMER_FLAG_NO_MAPCHANGE);
						
						ClientProtector[player] = client;
					}
				}
			}
		}
		
		CreateTimer(HealRate, Timer_Protect_Team, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	
	if(!strcmp(ability_name, "team_condition"))
	{
		float BuffDistance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "team_condition", 1, 300.0);
		char Condition[64];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "team_condition", 2, Condition, sizeof(Condition));
		
		for (int player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player) && TF2_GetClientTeam(client)==TF2_GetClientTeam(player))
				{
					float ClientPos[3], PlayerPos[3];
					GetClientAbsOrigin(client,ClientPos);
					GetClientAbsOrigin(player,PlayerPos);
					if (BuffDistance>=GetVectorDistance(PlayerPos, ClientPos))
					{
						if (!StrEqual(Condition,NULL_STRING))
							SetCondition(player, Condition);
					}
				}
			}
		}
	}
}

public bool TraceRayProp(int entityhit, int mask, any entity)
{
	if (entityhit > MaxClients && entityhit != entity)
	{
		return true;
	}
	
	return false;
}

public Action Remove_Velocity(Handle timer, int client)
{
	if (!IsClientInGame(client))
		return;
		
	if (!IsPlayerAlive(client))
		return;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, BaseVelocity[client]);
}

public Action Remove_Shield_Timer(Handle timer, int client)
{
	if (!IsClientInGame(client))
	{
		ClientShieldHp[client] = 0;
		
		if (IsValidEntity(ClientShield[client]))
		{
			TF2_RemoveWearable(client, ClientShield[client]);
			AcceptEntityInput(ClientShield[client], "Kill");
		}
		
		ClientShield[client] = -1;
		
		KillTimer(timer);
		return;
	}
		
	if (!IsPlayerAlive(client))
	{
		ClientShieldHp[client] = 0;
		
		if (IsValidEntity(ClientShield[client]))
		{
			TF2_RemoveWearable(client, ClientShield[client]);
			AcceptEntityInput(ClientShield[client], "Kill");
		}
		ClientShield[client] = -1;
		
		KillTimer(timer);
		return;
	}
			
	if (ShieldTimer[client]<=0.0)
	{
		ClientShieldHp[client] = 0;
		
		if (IsValidEntity(ClientShield[client]))
		{
			TF2_RemoveWearable(client, ClientShield[client]);
			AcceptEntityInput(ClientShield[client], "Kill");
			EmitSoundToClient(client, ")weapons/sentry_damage4.wav", client, _, _, _, 1.0);
		}
		ClientShield[client] = -1;
		KillTimer(timer);
		return;
	}
	
	ShieldTimer[client] -= 0.1;
}

public Action Remove_Combo_Timer(Handle timer, int client)
{
	if (!IsClientInGame(client))
	{
		ComboMultiplier[client] = 1.0;
		KillTimer(timer);
		return;
	}
		
	if (!IsPlayerAlive(client))
	{
		ComboMultiplier[client] = 1.0;
		KillTimer(timer);
		return;
	}
			
	if (ComboTimer[client]<=0.0)
	{
		ComboMultiplier[client] = 1.0;
		KillTimer(timer);
		return;
	}
	
	ComboTimer[client] -= 0.1;
}

stock int TF2_CreateAndEquipWearable(int client, const char[] classname, int index, int level, int quality, char[] attributes)
{
	int wearable;
	if(classname[0])
	{
		wearable = CreateEntityByName(classname);
	}
	else
	{
		wearable = CreateEntityByName("tf_wearable");
	}

	if(!IsValidEntity(wearable))
		return -1;

	SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
		
	// Allow quality / level override by updating through the offset.
	static char netClass[64];
	GetEntityNetClass(wearable, netClass, sizeof(netClass));
	SetEntData(wearable, FindSendPropInfo(netClass, "m_iEntityQuality"), quality);
	SetEntData(wearable, FindSendPropInfo(netClass, "m_iEntityLevel"), level);

	SetEntProp(wearable, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(wearable, Prop_Send, "m_iEntityLevel", level);

	if(attributes[0])
	{
		char atts[32][32];
		int count = ExplodeString(attributes, " ; ", atts, 32, 32);
		if(count > 1)
		{
			for(int i; i<count; i+=2)
			{
				TF2Attrib_SetByDefIndex(wearable, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			}
		}
	}
		
	DispatchSpawn(wearable);
	SDK_EquipWearable(client, wearable);
	return wearable;
}

stock void SDK_EquipWearable(int client, int wearable)
{
	if(SDKEquipWearable != null)
		SDKCall(SDKEquipWearable, client, wearable);
}

public void ClientSpeed(int client)
{
	if(IsClientInGame(client) && FF2_GetRoundState()==1)
	{
		if (IsPlayerAlive(client))
		{
			int idBoss = FF2_GetBossIndex(client);
			if(FF2_HasAbility(idBoss, this_plugin_name, "quick_escape") && TF2_IsPlayerInCondition(client,TFCond_AfterburnImmune))
			{
				float EscapeSpeed = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"quick_escape",7, 0.0);
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", EscapeSpeed);
				return;
			}
		}
	}
	SDKUnhook(client, SDKHook_PreThink, ClientSpeed);
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] classname, bool &result)
{
	if(IsClientInGame(client) && FF2_GetRoundState()==1)
	{
		if (IsPlayerAlive(client))
		{
			int idBoss = FF2_GetBossIndex(client);
			if(FF2_HasAbility(idBoss, this_plugin_name, "aim_assister"))
			{
				if (TF2_IsPlayerInCondition(client,TFCond_RunePrecision))
				{
					for (int weaponslotcheck = 1; weaponslotcheck < 20; weaponslotcheck++)
					{
						int indexneeded = FF2_GetAbilityArgument(idBoss,this_plugin_name,"aim_assister",(weaponslotcheck*10)+1, 0);
						if (indexneeded==GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
						{
							int bulletnumber = FF2_GetAbilityArgument(idBoss,this_plugin_name,"aim_assister",(weaponslotcheck*10)+3,-1);
							float damage = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"aim_assister",(weaponslotcheck*10)+2, 0.0);
							
							if (damage>0.0)
							{
								if (bulletnumber==-1)
								{
									for (int player = 1; player <= MaxClients; player++)
									{
										if (IsClientInGame(player))
										{
											if (IsPlayerAlive(player) && TF2_GetClientTeam(client)!=TF2_GetClientTeam(player) && IsAbleToSee(client, player, _, 5000.0))
											{
												float ClientPos[3], PlayerPos[3];
												GetClientEyePosition(client, ClientPos);
												GetClientEyePosition(player, PlayerPos);
												
												ClientPos[2] -= 45.0;
									
												TF2Attrib_SetByName(weapon, "bullets per shot bonus", 0.0);
												ShootLaser(weapon, "bullet_tracer01_red", ClientPos, PlayerPos, true);
												SDKHooks_TakeDamage(player, client, client, damage, DMG_BULLET, weapon);
											}
										}
									}
								}
								else
								{
									bool AllClear = false;
									bool PlayerTouch[MAXPLAYERS + 1] = false;
									while (!AllClear && bulletnumber>0)
									{
										float closestditence = -1.0;
										int ClosesTarget = -1;
										for (int player = 1; player <= MaxClients; player++)
										{
											if (IsClientInGame(player))
											{
												if (IsPlayerAlive(player) && TF2_GetClientTeam(client)!=TF2_GetClientTeam(player) && IsAbleToSee(client, player, _, 5000.0) && !PlayerTouch[player])
												{
													float ClientPos[3], PlayerPos[3];
													GetClientAbsOrigin(client, ClientPos);
													GetClientAbsOrigin(player, PlayerPos);
													
													if (GetVectorDistance(ClientPos,PlayerPos)<closestditence || closestditence==-1.0)
													{
														ClosesTarget = player;
														closestditence = GetVectorDistance(ClientPos, PlayerPos);
													}
												}
											}
										}
										
										if (IsValidClient(ClosesTarget))
										{
											float ClientPos[3], PlayerPos[3];
											GetClientEyePosition(client, ClientPos);
											GetClientEyePosition(ClosesTarget, PlayerPos);
											
											ClientPos[2] -= 45.0;
								
											TF2Attrib_SetByName(weapon, "bullets per shot bonus", 0.0);
											ShootLaser(weapon, "bullet_tracer01_red", ClientPos, PlayerPos, true);
											SDKHooks_TakeDamage(ClosesTarget, client, client, damage, DMG_BULLET, weapon);
											PlayerTouch[ClosesTarget] = true;
											
											bulletnumber -= 1;
										}
										else
											AllClear = true;
									}
								}
							}
						}
					}
				}
				else
					TF2Attrib_SetByName(weapon, "bullets per shot bonus", 1.0);
			}
		}
	}
}

// Take from ff2_tfcond by 93SHADoW
stock void SetCondition(int client, char[] cond)
{
	char conds[32][32];
	int count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds));
	if (count > 0)
	{
		for (int i = 0; i < count; i+=2)
		{
			TF2_AddCondition(client, view_as<TFCond>(StringToInt(conds[i])), StringToFloat(conds[i+1]));
		}
	}
}

// Take From my blightcaller plugin
public Action MakeAnImage(client, float duration, const char[] EffectName, int R, int G, int B, int A)
{
	float clientPos[3] = 0.0;
	float clientAngles[3] = 0.0;
	float clientVel[3] = 0.0;
	GetClientAbsOrigin(client, clientPos);
	GetEntPropVector(client, Prop_Send, "m_angRotation", clientAngles);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", clientVel);
	int animationentity = CreateEntityByName("prop_physics_multiplayer", -1);
	int particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEntity(animationentity))
	{
		char model[256];
		GetClientModel(client, model, 256);
		DispatchKeyValue(animationentity, "model", model);
		DispatchKeyValue(animationentity, "solid", "0");
		DispatchSpawn(animationentity);
		SetEntityMoveType(animationentity, MOVETYPE_FLYGRAVITY);
		AcceptEntityInput(animationentity, "TurnOn", animationentity, animationentity, 0);
		SetEntPropEnt(animationentity, PropType:0, "m_hOwnerEntity", client, 0);
		if (GetEntProp(client, PropType:0, "m_iTeamNum", 4, 0))
		{
			SetEntProp(animationentity, PropType:0, "m_nSkin", GetClientTeam(client) + -2, 4, 0);
		}
		else
		{
			SetEntProp(animationentity, PropType:0, "m_nSkin", GetEntProp(client, PropType:0, "m_nForcedSkin", 4, 0), 4, 0);
		}
		SetEntProp(animationentity, PropType:0, "m_nSequence", GetEntProp(client, PropType:0, "m_nSequence", 4, 0), 4, 0);
		SetEntPropFloat(animationentity, PropType:0, "m_flPlaybackRate", GetEntPropFloat(client, PropType:0, "m_flPlaybackRate", 0), 0);
		DispatchKeyValue(client, "disableshadows", "1");
		TeleportEntity(animationentity, clientPos, clientAngles, clientVel);
		TeleportEntity(particle, clientPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", "animationentity");
		DispatchKeyValue(particle, "effect_name", EffectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		
		SetEntityRenderMode(animationentity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(animationentity, R, G, B, A);
		
		CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(animationentity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RemoveEntity(Handle timer, any:entid)
{
	int entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
	}
}

stock void ColorizeAllEntityFrom(int client, int R = 255, int G = 255, int B = 255, int A = 255)
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		SetEntityRenderColor(i, R, G, B, A);
	}

	i = -1;
	while( ( i = FindEntityByClassname( i, "tf_powerup_bottle" ) ) > MaxClients )
	{
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		SetEntityRenderColor(i, R, G, B, A);
	}

	i = -1;
	while( ( i = FindEntityByClassname( i, "tf_weapon*" ) ) > MaxClients )
	{
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		SetEntityRenderColor(i, R, G, B, A);
	}
}

// Take from npc files

stock void ShootLaser(int weapon, const char[] strParticle, float flStartPos[3], float flEndPos[3], bool bResetParticles = false)
{
	int tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE) 
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, strParticle, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", strParticle);
		return;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", flStartPos[0]);
	TE_WriteFloat("m_vecOrigin[1]", flStartPos[1]);
	TE_WriteFloat("m_vecOrigin[2]", flStartPos[2]);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", weapon);
	TE_WriteNum("m_iAttachType", 2);
	TE_WriteNum("m_iAttachmentPointIndex", 0);
	TE_WriteNum("m_bResetParticles", bResetParticles);    
	TE_WriteNum("m_bControlPoint1", 1);    
	TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", 5);  
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", flEndPos[0]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", flEndPos[1]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", flEndPos[2]);
	TE_SendToAll();
}

// Take from codzpack
stock bool IsAbleToSee(entity, client, float angle=90.0, float distance=0.0)
{
    // Skip all traces if the player isn't within the field of view.
    // - Temporarily disabled until eye angle prediction is added.
    // if (IsInFieldOfView(g_vEyePos[client], g_vEyeAngles[client], g_vAbsCentre[entity]))
    
	if (IsTargetInSightRange(entity, client, angle, distance))
	{
	    float vecOrigin[3], vecEyePos[3];
	    GetClientAbsOrigin(entity, vecOrigin);
	    GetClientEyePosition(client, vecEyePos);
	    
	    // Check if centre is visible.
	    if (IsPointVisible(vecEyePos, vecOrigin))
	    {
	        return true;
	    }
	    
	    float vecEyePos_ent[3], vecEyeAng[3];
	    GetClientEyeAngles(entity, vecEyeAng);
	    GetClientEyePosition(entity, vecEyePos_ent);
	    // Check if weapon tip is visible.
	    if (IsFwdVecVisible(vecEyePos, vecEyeAng, vecEyePos_ent))
	    {
	        return true;
	    }
	    
	    float mins[3], maxs[3];
	    GetClientMins(client, mins);
	    GetClientMaxs(client, maxs);
	    // Check outer 4 corners of player.
	    if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 1.30))
	    {
	        return true;
	    }
	
	    // Check inner 4 corners of player.
	    if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 0.65))
	    {
	        return true;
	    }
	    
	    return false;
	}
	return false;
}

stock bool IsInFieldOfView(client, const float start[3], const float angles[3], float fov = 90.0)
{
    float normal[3], plane[3];
    
    float end[3];
    GetClientAbsOrigin(client, end);
    
    GetAngleVectors(angles, normal, NULL_VECTOR, NULL_VECTOR);
    SubtractVectors(end, start, plane);
    NormalizeVector(plane, plane);
    
    return GetVectorDotProduct(plane, normal) > Cosine(DegToRad(fov/2.0));
}

public bool Filter_NoPlayers(entity, mask)
{
    return (entity > MaxClients && !(0 < GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") <= MaxClients));
}

bool IsPointVisible(const float start[3], const float end[3])
{
    TR_TraceRayFilter(start, end, MASK_VISIBLE, RayType_EndPoint, Filter_NoPlayers);

    return TR_GetFraction() == 1.0;
}

bool IsFwdVecVisible(const float start[3], const float angles[3], const float end[3])
{
    float fwd[3];
    
    GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 50.0);
    AddVectors(end, fwd, fwd);

    return IsPointVisible(start, fwd);
}

bool IsRectangleVisible(const float start[3], const float end[3], const float mins[3], const float maxs[3], float scale=1.0)
{
    float ZpozOffset = maxs[2];
    float ZnegOffset = mins[2];
    float WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;

    // This rectangle is just a point!
    if (ZpozOffset == 0.0 && ZnegOffset == 0.0 && WideOffset == 0.0)
    {
        return IsPointVisible(start, end);
    }

    // Adjust to scale.
    ZpozOffset *= scale;
    ZnegOffset *= scale;
    WideOffset *= scale;
    
    // Prepare rotation matrix.
    float angles[3], fwd[3], right[3];

    SubtractVectors(start, end, fwd);
    NormalizeVector(fwd, fwd);

    GetVectorAngles(fwd, angles);
    GetAngleVectors(angles, fwd, right, NULL_VECTOR);

    float vRectangle[4][3], vTemp[3];

    // If the player is on the same level as us, we can optimize by only rotating on the z-axis.
    if (FloatAbs(fwd[2]) <= 0.7071)
    {
        ScaleVector(right, WideOffset);
        
        // Corner 1, 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vRectangle[0]);
        SubtractVectors(vTemp, right, vRectangle[1]);
        
        // Corner 3, 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vRectangle[2]);
        SubtractVectors(vTemp, right, vRectangle[3]);
        
    }
    else if (fwd[2] > 0.0) // Player is below us.
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);
        
        // Corner 1
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[0]);
        
        // Corner 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[1]);
        
        // Corner 3
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[2]);
        
        // Corner 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[3]);
    }
    else // Player is above us.
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);

        // Corner 1
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[0]);
        
        // Corner 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[1]);
        
        // Corner 3
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[2]);
        
        // Corner 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[3]);
    }

    // Run traces on all corners.
    for (new i = 0; i < 4; i++)
    {
        if (IsPointVisible(start, vRectangle[i]))
        {
            return true;
        }
    }

    return false;
}

stock bool IsTargetInSightRange(client, target, float angle=90.0, float distance=0.0, bool heightcheck=true, bool negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	if(!IsClientInGame(target) || !IsPlayerAlive(client))
		ThrowError("Client is not Alive.");
	if(!IsClientInGame(target) || !IsPlayerAlive(client))
		ThrowError("Target is not Alive.");
		
	float clientpos[3], targetpos[3], anglevector[3], targetvector[3], resultangle, resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

// Take from improved saxton
stock float fixAngle(float angle)
{
	int sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

stock fixAngles(float angles[3])
{
	for (new i = 0; i < 3; i++)
		angles[i] = fixAngle(angles[i]);
}


// Some stock from one of my private plugin
stock int FindClosestTeammateToPoint(int entity, float Pos[3] =  { 0.0, 0.0, 0.0} )
{
	float TargetDistance = 0.0; 
	int ClosestTarget = 0; 
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if (IsValidClient(i))
		{
			if (TF2_GetClientTeam(i)==view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum"))) 
			{
				float TargetLocation[3];  
				GetClientAbsOrigin( i, TargetLocation ); 
				
				
				float distance = GetVectorDistance( Pos, TargetLocation ); 
				if( TargetDistance ) 
				{
					if( distance < TargetDistance ) 
					{
						ClosestTarget = i; 
						TargetDistance = distance;          
					}
				} 
				else 
				{
					ClosestTarget = i; 
					TargetDistance = distance;
				}					
			}
		}
	}
	return ClosestTarget; 
}

stock bool IsValidClient( int client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}

// Take from rtd
stock int ConnectWithBeam(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255, float fStartWidth=1.0, float fEndWidth=1.0, float fAmp=1.35, char[] Model = "sprites/laserbeam.vmt"){
	int iBeam = CreateEntityByName("env_beam");
	if(iBeam <= MaxClients)
		return -1;

	if(!IsValidEntity(iBeam))
		return -1;

	SetEntityModel(iBeam, Model);
	char sColor[16];
	Format(sColor, sizeof(sColor), "%d %d %d", iRed, iGreen, iBlue);

	DispatchKeyValue(iBeam, "rendercolor", sColor);
	DispatchKeyValue(iBeam, "life", "0");

	DispatchSpawn(iBeam);

	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt));
	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt2), 1);

	SetEntProp(iBeam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(iBeam, Prop_Send, "m_nBeamType", 2);

	SetEntPropFloat(iBeam, Prop_Data, "m_fWidth", fStartWidth);
	SetEntPropFloat(iBeam, Prop_Data, "m_fEndWidth", fEndWidth);

	SetEntPropFloat(iBeam, Prop_Data, "m_fAmplitude", fAmp);

	SetVariantFloat(32.0);
	AcceptEntityInput(iBeam, "Amplitude");
	AcceptEntityInput(iBeam, "TurnOn");
	return iBeam;
}

// Take from my saxton hale attribute from mpvm
stock int CreateParticleAttach(const char[] sParticle, int client, const char[] Attachement)
{
	float pos[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	int entity = CreateEntityByName("info_particle_system");
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(entity, "effect_name", sParticle);
	
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client, entity, 0);
	
	SetVariantString(Attachement);
	AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
	
	char t_Name[128];
	Format(t_Name, sizeof(t_Name), "target%i", client);
	
	DispatchKeyValue(entity, "targetname", t_Name);
	
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	return entity;
}

// Take from Nosoop's stock
stock int TF2_GetPlayerSpellBook(int client) {
	int spellbook = -1;
	while ((spellbook = FindEntityByClassname(spellbook, "tf_weapon_spellbook")) != -1) {
		if (GetEntPropEnt(spellbook, Prop_Send, "m_hOwnerEntity") == client
				&& !GetEntProp(spellbook, Prop_Send, "m_bDisguiseWeapon")) {
			return spellbook;
		}
	}
	return INVALID_ENT_REFERENCE;
}