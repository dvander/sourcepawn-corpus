/*
As Otokiru has quit development of Freak Fortress 2 Plugins, he has given me the green light to take over development.
I will continue to update these rages as long as people continue to use the bosses originally equipped with them.

rage_sandman, rage_giftwrap, rage_nurse_bowrage, rage_pyrogas are deprecated and we highly recommend switching to rage_new_weapon as soon as you can.

charge_salmon will continue to be supported, even though charge_summon_minions from the SALMON SUMMON SYSTEM is its successor, but we highly recommend switching to the new plugin for more customization options
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
//#tryinclude <freak_fortress_2_extras>
#define PEDO_SND "player/taunt_wormshhg.wav"
#define PYROGAS_SND "ambient/halloween/thunder_02.wav"
#define SCT_SND "weapons/ball_buster_break_01_crowd.wav"
#define ZEPH_SND "ambient/siren.wav"
#define POL_SND "misc/taps_02.wav"
#define GENTLEMEN_START "replay\\exitperformancemode.wav"
#define GENTLEMEN_EXIT "replay\\enterperformancemode.wav"

#pragma newdecls required

int AlivePlayerCount;
Handle jumpHUD;
Handle OnHaleJump = null;
int SummonerIndex[MAXPLAYERS+1];
int bEnableSuperDuperJump[MAXPLAYERS+1];

bool RScout_AMSMode[MAXPLAYERS+1];
bool RNurse_AMSMode[MAXPLAYERS+1];
bool RGift_AMSMode[MAXPLAYERS+1];
bool RPedo_AMSMode[MAXPLAYERS+1];
bool RPyro_AMSMode[MAXPLAYERS+1];
bool RSpy_AMSMode[MAXPLAYERS+1];
bool RGen_AMSMode[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "Freak Fortress 2: Saxtoner Ability Pack",
	author = "Otokiru, updated by SHADow93",
	version = "1.7",
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("arena_win_panel", Event_RoundEnd);
	
	jumpHUD = CreateHudSynchronizer();
	
	PrecacheSound(GENTLEMEN_START,true);
	PrecacheSound(GENTLEMEN_EXIT,true);
	PrecacheSound(PEDO_SND,true);
	PrecacheSound(PYROGAS_SND,true);
	PrecacheSound(SCT_SND,true);
	PrecacheSound(ZEPH_SND,true);
	PrecacheSound(POL_SND,true);
	
	
	if(FF2_GetRoundState()==1)
	{
		HookAbilities();
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	OnHaleJump = CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	HookAbilities();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client))
			continue;
		SummonerIndex[client]=-1;
		bEnableSuperDuperJump[client]=false;
		RScout_AMSMode[client]=false;
		RNurse_AMSMode[client]=false;
		RGift_AMSMode[client]=false;
		RPedo_AMSMode[client]=false;
		RPyro_AMSMode[client]=false;
		RSpy_AMSMode[client]=false;
		RGen_AMSMode[client]=false;
	}
}

public void HookAbilities()
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client))
			continue;
		SummonerIndex[client]=-1;
		bEnableSuperDuperJump[client]=false;
		RScout_AMSMode[client]=false;
		RNurse_AMSMode[client]=false;
		RGift_AMSMode[client]=false;
		RPedo_AMSMode[client]=false;
		RPyro_AMSMode[client]=false;
		RSpy_AMSMode[client]=false;
		RGen_AMSMode[client]=false;
		int boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, "charge_salmon"))
			{
				char fileName[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(boss, this_plugin_name, "charge_salmon", 7, fileName, sizeof(fileName)); // custom translations file?
				if(!fileName[0])
				{
					Format(fileName, sizeof(fileName), "ff2_otokiru.phrases"); // load default if none specified
				}
				LoadTranslations(fileName);
			}
			
			if(FF2_HasAbility(boss, this_plugin_name, "rage_scout"))
			{
				RScout_AMSMode[client]=AMS_IsSubabilityReady(boss, this_plugin_name, "rage_scout");
				if(RScout_AMSMode[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, "rage_scout", "SCT");
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, "rage_nurse_bowrage"))
			{
				RNurse_AMSMode[client]=AMS_IsSubabilityReady(boss, this_plugin_name, "rage_nurse_bowrage");
				if(RNurse_AMSMode[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, "rage_nurse_bowrage", "NUR");
				}
			}	
			if(FF2_HasAbility(boss, this_plugin_name, "rage_giftwrap"))
			{
				RGift_AMSMode[client]=AMS_IsSubabilityReady(boss, this_plugin_name, "rage_giftwrap");
				if(RGift_AMSMode[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, "rage_giftwrap", "GFT");
				}
			}	
			if(FF2_HasAbility(boss, this_plugin_name, "rage_pedo"))
			{
				RPedo_AMSMode[client]=AMS_IsSubabilityReady(boss, this_plugin_name, "rage_pedo");
				if(RPedo_AMSMode[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, "rage_pedo", "PDO");
				}
			}		
			if(FF2_HasAbility(boss, this_plugin_name, "rage_pyrogas"))
			{
				RPyro_AMSMode[client]=AMS_IsSubabilityReady(boss, this_plugin_name, "rage_pyrogas");
				if(RPyro_AMSMode[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, "rage_pyrogas", "PYR");
				}
			}	
			if(FF2_HasAbility(boss, this_plugin_name, "rage_abstractspy"))
			{
				RSpy_AMSMode[client]=AMS_IsSubabilityReady(boss, this_plugin_name, "rage_abstractspy");
				if(RSpy_AMSMode[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, "rage_abstractspy", "SPY");
				}
			}			
			if(FF2_HasAbility(boss, this_plugin_name, "rage_gentlemen"))
			{
				RGen_AMSMode[client]=AMS_IsSubabilityReady(boss, this_plugin_name, "rage_gentlemen");
				if(RGen_AMSMode[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, "rage_gentlemen", "MEN");
				}
			}				
		}
	}
}
 
// rage_scout

public bool SCT_CanInvoke(int client)
{
	return true;
}

void Rage_Scout(int client)
{
	if(RScout_AMSMode[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
		{
			RScout_AMSMode[client]=false;
		}
		else
		{
			return;
		}
	}	
	SCT_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void SCT_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	char attributes[768], defattrib[48];
	int var1=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_scout", 1);	//mode
	int var2=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_scout", 2);	//sound
	int var3=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_scout", 3);	//ammo
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_scout", 4, attributes, sizeof(attributes)); //attributes
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	
	// Because Scouts are only supposed to get +1 caprate, not +2 caprate. Also set the built-in attributes for Sandman rage
	Format(defattrib, sizeof(defattrib), TF2_GetPlayerClass(client)==TFClass_Scout ? "2 ; 3 ; 37 ; 0 ; 38 ; 1 ; 68 ; 1 ; 134 ; 17" : "2 ; 3 ; 37 ; 0 ; 38 ; 1 ; 68 ; 2 ; 134 ; 17");
	
	if(attributes[0]!='\0') // Now we equip up to 9 more user-specified attributes
	{
		Format(attributes, sizeof(attributes), var1==1 ? "350 ; 1 ; %s ; %s" : "%s ; %s", defattrib, attributes);
	}
	else // Or we just equip the default attributes
	{
		Format(attributes, sizeof(attributes), var1==1 ? "350 ; 1 ; %s" : "%s", defattrib);
	}
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat_wood", 44, 100, 5, attributes, FF2_GetAbilityArgument(boss,this_plugin_name,"rage_scout", 5)));
	SetAmmo(client, TFWeaponSlot_Melee,var3);
	if(var2)
	{
		EmitSoundToAll(SCT_SND);
		EmitSoundToAll(SCT_SND);
	}
}

// rage_giftwrap

public bool GFT_CanInvoke(int client)
{
	return true;
}

void Rage_Giftwrap(int client)
{
	if(RGift_AMSMode[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
		{
			RGift_AMSMode[client]=false;
		}
		else
		{
			return;
		}
	}	
	GFT_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void GFT_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	char attributes[768], defattrib[48];
	int var1=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_giftwrap", 1);	//mode
	int var2=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_giftwrap", 2);	//sound
	int var3=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_giftwrap", 3);	//ammo
	FF2_GetAbilityArgumentString(boss, this_plugin_name,"rage_giftwrap", 4, attributes, sizeof(attributes)); //attributes
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	
	// Because Scouts are only supposed to get +1 caprate, not +2 caprate. Also set the built-in attributes for Wrap Assassin rage
	Format(defattrib, sizeof(defattrib), TF2_GetPlayerClass(client)==TFClass_Scout ? "2 ; 3 ; 37 ; 0 ; 38 ; 1 ; 68 ; 1 ; 134 ; 17" : "2 ; 3 ; 37 ; 0 ; 38 ; 1 ; 68 ; 2 ; 134 ; 17");
	
	if(attributes[0]!='\0') // Now we equip up to 9 more user-specified attributes
	{
		Format(attributes, sizeof(attributes), var1==1 ? "350 ; 1 ; %s ; %s" : "%s ; %s", defattrib, attributes);
	}
	else // Or we just equip the default attributes
	{
		Format(attributes, sizeof(attributes), var1==1 ? "350 ; 1 ; %s" : "%s", defattrib);
	}
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat_giftwrap", 648, 100, 5, attributes,FF2_GetAbilityArgument(boss,this_plugin_name,"rage_scout", 5)));
	SetAmmo(client, TFWeaponSlot_Melee,var3);
	if(var2)
	{
		EmitSoundToAll(SCT_SND);
		EmitSoundToAll(SCT_SND);
	}
}

// rage_nurse

public bool NUR_CanInvoke(int client)
{
	return true;
}

void Rage_Nurse(int client)
{
	if(RNurse_AMSMode[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
		{
			RNurse_AMSMode[client]=false;
		}
		else
		{
			return;
		}
	}	
	NUR_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void NUR_Invoke(int client) // Crusader's Crossbow RAGE
{
	int boss=FF2_GetBossIndex(client);
	char attributes[64];
	int var1=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_nurse_bowrage", 1);	//mode
	int var2=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_nurse_bowrage", 2);	//sound
	int var3=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_nurse_bowrage", 3);	//ammo
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	
	// We set whether crossbow turns players into gold or not.
	Format(attributes, sizeof(attributes), var1==1 ? "6 ; 0.5 ; 37 ; 0.0 ; 2 ; 3.0 ; 150 ; 1 ; 134 ; 19 ; 37 ; 0.0" : "6 ; 0.5 ; 37 ; 0.0 ; 2 ; 3.0 ; 134 ; 19 ; 37 ; 0.0");
	
	// Now we spawn the weapon
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_crossbow", 305, 100, 5, attributes, FF2_GetAbilityArgument(boss,this_plugin_name,"rage_scout", 5)));
	SetAmmo(client, TFWeaponSlot_Primary,var3);
	if(var2)
	{
		EmitSoundToAll(POL_SND);
		EmitSoundToAll(POL_SND);
	}
}

// rage_pedo

public bool PDO_CanInvoke(int client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Dazed)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_DeadRingered)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_Stealthed)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade)) return false;
	return true;
}

void Rage_Pedo(int client)
{
	if(RPedo_AMSMode[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
		{
			RPedo_AMSMode[client]=false;
		}
		else
		{
			return;
		}
	}	
		
	PDO_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void PDO_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	float pos[3], pos2[3];
	int var1=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_pedo", 1);	//mode
	int var2=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_pedo", 2);	//sound
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	float ragedist=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"rage_pedo",3,FF2_GetRageDist(boss,this_plugin_name,"rage_pedo")); // user-specified distance (or use FF2's ragedist)
	if(var2)
	{
		EmitSoundToAll(PEDO_SND);
		EmitSoundToAll(PEDO_SND);
	}
	for(int target=1;target<=MaxClients;target++)
	{
		if(IsValidLivingClient(target) && GetClientTeam(target)!=FF2_GetBossTeam())
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos2);
			if(!var1)
			{
				if(GetVectorDistance(pos,pos2)<ragedist && !TF2_IsPlayerInCondition(target,TFCond_Ubercharged))
					FakeClientCommand(target, "taunt");
			}
			else
			{
				if(GetVectorDistance(pos,pos2)<ragedist)
					FakeClientCommand(target, "taunt");
			}
		}
	}
}

// rage_pyrogas

public bool PYR_CanInvoke(int client)
{
	return true;
}

void Rage_Pyrogas(int client)
{
	if(RPyro_AMSMode[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
		{
			RPyro_AMSMode[client]=false;
		}
		else
		{
			return;
		}
	}	
		
	PYR_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void PYR_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	int var1=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_pyrogas", 1);	//sound
	int var2=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_pyrogas", 2);	//ammo
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_flaregun", 351, 100, 5, "2 ; 3.0 ; 25 ; 0.0 ; 207 ; 2 ; 144 ; 1 ; 99 ; 5 ; 134 ; 1"), FF2_GetAbilityArgument(boss,this_plugin_name,"rage_scout", 5));
	SetAmmo(client, TFWeaponSlot_Secondary,var2);
	if(var1)
	{
		EmitSoundToAll(PYROGAS_SND);
		EmitSoundToAll(PYROGAS_SND);
	}
}

// rage_gentlemen

public bool MEN_CanInvoke(int client)
{
	// if any of these is true, cancel activation of the force team switch event
	if(TF2_IsPlayerInCondition(client, TFCond_Dazed)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_DeadRingered)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_Stealthed)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade)) return false;
	// otherwise, start the process
	return true;
}

void Rage_Gentlemen(int client)
{
	if(RGen_AMSMode[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
		{
			RGen_AMSMode[client]=false;
		}
		else
		{
			return;
		}
	}	
		
	MEN_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void MEN_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	float pos[3], pos2[3];
	char message[256];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	float duration=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"rage_gentlemen",1,6.0);
	float ragedist=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"rage_gentlemen",2,FF2_GetRageDist(boss,this_plugin_name,"rage_gentlemen")); // user-specified distance (or use FF2's ragedist)
	FF2_GetAbilityArgumentString(boss,this_plugin_name,"rage_gentlemen",3,message, sizeof(message)); // message
	for(int target=1;target<=MaxClients;target++)
	{
		if(IsValidLivingClient(target) && GetClientTeam(target)!=FF2_GetBossTeam())
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos2);
			if (GetVectorDistance(pos,pos2)<ragedist && !TF2_IsPlayerInCondition(target,TFCond_Ubercharged))
			{
				EmitSoundToAll(GENTLEMEN_START, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
				FF2_SetFF2flags(target,FF2_GetFF2flags(target)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
				SummonerIndex[target]=boss;
				SetEntProp(target, Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(target, FF2_GetBossTeam());
				SetEntProp(target, Prop_Send, "m_lifeState", 0);
				if(GetEntProp(target, Prop_Send, "m_bDucked"))
				{
					float collisionvec[3];
					collisionvec[0] = 24.0;
					collisionvec[1] = 24.0;
					collisionvec[2] = 62.0;
					SetEntPropVector(target, Prop_Send, "m_vecMaxs", collisionvec);
					SetEntProp(target, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(target, FL_DUCKING);
				}
				TF2_AddCondition(target, TFCond_Ubercharged, 1.0);
				if(!IsNullString(message))
				{
					ShowGameText(client, _, FF2_GetBossTeam(), message, sizeof(message));
				}
			}
			CreateTimer(duration, Back2Karkan, target);
		}
	}

	float pos_2[3];
	int target, pingas;
	bool MercPlayers;
	for(int ii=1;ii<=MaxClients;ii++)
		if(IsValidEdict(ii) && IsValidLivingClient(ii) && GetClientTeam(ii)!=FF2_GetBossTeam())
		{
			MercPlayers=true;
			break;
		}
	do
	{
		pingas++;
		target=GetRandomInt(1,MaxClients);
		if (pingas==100)
			return;
	}
	while (MercPlayers && (!IsValidEdict(target) || (target==client) || !IsPlayerAlive(target)));
	
	if (IsValidEdict(target))
	{
		GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos_2);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos_2);
		if (GetEntProp(target, Prop_Send, "m_bDucked"))
		{
			float collisionvec[3];
			collisionvec[0] = 24.0;
			collisionvec[1] = 24.0;
			collisionvec[2] = 62.0;
			SetEntPropVector(client, Prop_Send, "m_vecMaxs", collisionvec);
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(client, FL_DUCKING);
		}
		TeleportEntity(client, pos_2, NULL_VECTOR, NULL_VECTOR);
	}
}

// rage_abstractspy

public bool SPY_CanInvoke(int client)
{
	return true;
}

void Rage_AbstractSpy(int client)
{
	if(RSpy_AMSMode[client]) // Prevent normal 100% RAGE activation if using AMS
	{
		if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
		{
			RSpy_AMSMode[client]=false;
		}
		else
		{
			return;
		}
	}	
		
	SPY_Invoke(client); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void SPY_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	float duration=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"rage_abstractspy",1,18.0);
	if(IsValidLivingClient(client))
	{
		TF2_DisguisePlayer(client, (FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (TFTeam_Red) : (TFTeam_Blue), view_as<TFClassType>(GetRandomInt(1,9)));
		if(duration)
		{
			CreateTimer(duration, RemoveDisguise, client);
		}
	}
}

public void FF2_OnAbility2(int boss,const char[] plugin_name,const char[] ability_name,int action)
{
	int slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if (!strcmp(ability_name,"rage_nurse_bowrage"))
		Rage_Nurse(client);						//Polish Nurse' Bow Rage
	else if (!strcmp(ability_name,"rage_scout"))
		Rage_Scout(client);						//Scout Rage
	else if (!strcmp(ability_name,"rage_giftwrap"))
		Rage_Giftwrap(client);					//giftwrap Rage		
	else if (!strcmp(ability_name,"rage_pedo"))	
		Rage_Pedo(client);						//Pedo Rage
	else if (!strcmp(ability_name,"rage_pyrogas"))	
		Rage_Pyrogas(client);					//Pyrogas Rage
	else if (!strcmp(ability_name,"charge_salmon"))
		Charge_Salmon(ability_name,boss,client,slot,action);			//Zep Mann
	else if (!strcmp(ability_name,"rage_abstractspy"))
		Rage_AbstractSpy(client);				//AbstractSpy Rage
	else if (!strcmp(ability_name,"rage_gentlemen"))
		Rage_Gentlemen(client);					//Gentlemen Rage
}

#if !defined _FF2_Extras_included
stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute, int visible = 1, bool preserve = false)
{
	if(StrEqual(name,"saxxy", false)) // if "saxxy" is specified as the name, replace with appropiate name
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Soldier: ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
			case TFClass_Pyro: ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan: ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy: ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
			case TFClass_Engineer: ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic: ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper: ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy: ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
		}
	}
	
	if(StrEqual(name, "tf_weapon_shotgun", false)) // If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Soldier:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
		}
	}

	Handle weapon = TF2Items_CreateItem((preserve ? PRESERVE_ATTRIBUTES : OVERRIDE_ALL) | FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2 = 0;
		for(int i = 0; i < count; i += 2)
		{
			int attrib = StringToInt(attributes[i]);
			if (attrib == 0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if (weapon == INVALID_HANDLE)
	{
		PrintToServer("[SpawnWeapon] Error: Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", client, name, index, attribute);
		return -1;
	}

	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	
	if(!visible)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	
	if (StrContains(name, "tf_wearable")==-1)
	{
		EquipPlayerWeapon(client, entity);
	}
	else
	{
		Wearable_EquipWearable(client, entity);
	}
	
	return entity;
}

Handle S93SF_equipWearable = INVALID_HANDLE;
stock void Wearable_EquipWearable(int client, int wearable)
{
	if(S93SF_equipWearable==INVALID_HANDLE)
	{
		Handle config=LoadGameConfigFile("equipwearable");
		if(config==INVALID_HANDLE)
		{
			LogError("[FF2] EquipWearable gamedata could not be found; make sure /gamedata/equipwearable.txt exists.");
			return;
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "EquipWearable");
		CloseHandle(config);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		if((S93SF_equipWearable=EndPrepSDKCall())==INVALID_HANDLE)
		{
			LogError("[FF2] Couldn't load SDK function (CTFPlayer::EquipWearable). SDK call failed.");
			return;
		}
	}
	SDKCall(S93SF_equipWearable, client, wearable);
}
#endif

stock int SetAmmo(int client, int slot, int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(weapon))
	{
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

public Action Back2Karkan(Handle timer,any target)
{
	if(IsValidLivingClient(target))
	{
		EmitSoundToAll(GENTLEMEN_EXIT, _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
		SetEntProp(target, Prop_Send, "m_lifeState", 2);
		SummonerIndex[target]=-1;
		ChangeClientTeam(target, (FF2_GetBossTeam()==(view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue))));
		SetEntProp(target, Prop_Send, "m_lifeState", 0);
		if (GetEntProp(target, Prop_Send, "m_bDucked"))
		{
			float collisionvec[3];
			collisionvec[0] = 24.0;
			collisionvec[1] = 24.0;
			collisionvec[2] = 62.0;
			SetEntPropVector(target, Prop_Send, "m_vecMaxs", collisionvec);
			SetEntProp(target, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(target, FL_DUCKING);
		}
		FF2_SetFF2flags(target, FF2_GetFF2flags(target) & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM);
	}
}

public Action RemoveDisguise(Handle timer, any boss)
{
	if(IsValidLivingClient(boss))
		TF2_RemovePlayerDisguise(boss);
}

void Charge_Salmon(const char[] ability_name, int boss, int client, int slot, int action)
{
	float charge=FF2_GetBossCharge(boss,slot);
	int var3=FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, 3);	//sound
	int var4=FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, 4);	//summon_per_rage
	float duration=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name,5,3.0); //uber_protection

	switch(action)
	{
		case 1:
		{
			SetHudTextParams(-1.0, slot==1 ? 0.88 : 0.93, 0.15, 255, 255, 255, 255);
			ShowSyncHudText(client, jumpHUD, "%t","salmon_status_2",-RoundFloat(charge));
		}	
		case 2:
		{
			SetHudTextParams(-1.0, slot==1 ? 0.88 : 0.93, 0.15, 255, 255, 255, 255);
			if (bEnableSuperDuperJump[client])
			{
				SetHudTextParams(-1.0, slot==1 ? 0.88 : 0.93, 0.15, 255, 64, 64, 255);
				ShowSyncHudText(client, jumpHUD,"%t","super_duper_jump");
			}	
			else
				ShowSyncHudText(client, jumpHUD, "%t","salmon_status",RoundFloat(charge));
		}
		case 3:
		{
			Action act = Plugin_Continue;
			int super = bEnableSuperDuperJump[client];
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(super);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return;
			if (act == Plugin_Changed) bEnableSuperDuperJump[client] = super;
			
			if (bEnableSuperDuperJump[client])
			{
				float vel[3], rot[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
				GetClientEyeAngles(client, rot);
				vel[2]=750.0+500.0*charge/70+2000;
				vel[0]+=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*500;
				vel[1]+=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*500;
				bEnableSuperDuperJump[client]=false;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
			}
			else
			{
				if(charge<100)
				{
					CreateTimer(0.1, Timer_ResetCharge, boss*10000+slot);
					return;					
				}
				
				if(var3)
				{
					EmitSoundToAll(ZEPH_SND);
					EmitSoundToAll(ZEPH_SND);
				}
				
				int ii;
				for(int i=0; i<(var4==-1 ? GetAlivePlayerCount((FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue))) : var4); i++)
				{
					ii = GetRandomDeadPlayer();
					if(ii != -1)
					{
						FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
						ChangeClientTeam(ii,FF2_GetBossTeam());
						TF2_RespawnPlayer(ii);
						SummonerIndex[ii]=boss;
						TF2_AddCondition(ii, TFCond_Ubercharged, duration);
					}
				}
			}			
		}
	}
}

stock int GetRandomDeadPlayer()
{
	int[] clients = new int[MaxClients+1];
	int clientCount;
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsValidEdict(i) && IsValidClient(i) && !IsPlayerAlive(i) && !IsValidBoss(i) && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

public Action Timer_ResetCharge(Handle timer, any boss)
{
	int slot=boss%10000;
	boss/=1000;
	FF2_SetBossCharge(boss,slot,0.0);
}

public Action FF2_OnTriggerHurt(int boss,int triggerhurt,float &damage)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!bEnableSuperDuperJump[client])
	{
		bEnableSuperDuperJump[client]=true;
	}
	if(FF2_GetBossCharge(boss,1)<0)
	{
		FF2_SetBossCharge(boss,1,0.0);
	}
	return Plugin_Continue;
}


stock int GetAlivePlayerCount(int team) // gets the number of alive players
{
	AlivePlayerCount=0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidLivingClient(client) && GetClientTeam(client) == team)
		{
			AlivePlayerCount++;
		}
	}
	return AlivePlayerCount;
}

stock bool IsValidClient(int client) // Checks if a client is valid
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}

stock bool IsValidLivingClient(int client) // Checks if a client is a valid living one.
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool IsValidBoss(int client) // Checks if boss is valid
{
	if (FF2_GetBossIndex(client) == -1) return false;
	return true;
}

stock bool IsValidMinion(int client) // Checks if minion is valid
{
	if (GetClientTeam(client)!=FF2_GetBossTeam()) return false;
	if (FF2_GetBossIndex(client) != -1) return false;
	if (SummonerIndex[client] == -1) return false;
	return true;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(event.GetInt("userid"));
	int boss=FF2_GetBossIndex(client);
	
	if(IsValidMinion(client) && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		SummonerIndex[client]=-1;
		ChangeClientTeam(client, (FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
	}
	
	if(boss!=-1 && FF2_HasAbility(boss, this_plugin_name, "charge_salmon") && !FF2_GetAbilityArgument(boss, this_plugin_name, "charge_salmon", 6) && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		for(int clone=1; clone<=MaxClients; clone++)
		{
			if(SummonerIndex[clone]==boss && IsValidClient(clone) && IsValidMinion(clone) && IsPlayerAlive(clone))
			{
				SummonerIndex[clone]=-1;
				ChangeClientTeam(clone, (FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
			}
		}
	}
}

stock bool ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(!client)
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}

	if(bf == null)
		return false;

	static char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	bf.WriteString(message);
	bf.WriteString(icon);
	bf.WriteByte(color);
	EndMessage();
	return true;
}