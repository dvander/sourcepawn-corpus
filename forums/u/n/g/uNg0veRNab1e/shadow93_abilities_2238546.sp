// ALL BOSS RAGES:
//rage_kritzkrieg = kritzkrieg effect
//	arg0 = ability slot
// 	arg1 = duration
//
//rage_hidden_uber = hidden ubercharge
//	arg0 = ability slot
// 	arg1 = duration
//
//rage_taunt_slide = the good old taunt sliding animation killed in FF2 1.10.x
//	arg0 = ability slot
//
//rage_invisbility_spell = mode matters if you are a knife-based spy boss as mode 0 uncloaked when attacking, and mode 1 recloaks you.
//	arg0 = ability slot
// 	arg1 = type (0 = TFCond_Stealthed, 1 = TFCond_StealthedUserBuffFade)
//	arg2 = duration
//
//rage_vaccinator = become resistant to bullet damage
//	arg0 = ability slot
// 	arg1 = resistance type (0 = all types, 1 = bullet resistance, 2 = blast resistance, 3 = fire resistance)
//	arg2 = duration
//
//effect_classreaction = voice reactions from non-boss team
//	arg0 = ability slot
//	arg1 = enable? 1 = yes, 2 = no
//
//rage_swimming_curse = Submerge everyone.
//	arg0 =  ability slot
//	arg1 =	Duration
//
//rage_meleeonly = Force to melee
//	arg0 = Ability slot
//	arg1 = 0 = Players restricted to melee, 1 = Boss & Players restricted to melee
//	arg2 = Duration
//
//rage_bumpercars = Bumper cars!
//	arg0 = Ability slot
//	arg1 = 0 = Boss only, 1 = Boss & Players
//	arg2 = Duration
//
//rage_minify = Minify Spell
//	arg0 = Ability slot
//	arg1 = 0 = Boss, 1 = Players, 2 = Boss & Players restricted to melee
//	arg2 = Duration
//
//rage_giants = Giant Spell
//	arg0 = Ability slot
//	arg1 = 0 = Boss, 1 = Players, 2 = Boss & Players restricted to melee
//	arg2 = Duration
//
//rage_salmon = modified charge_salmon for use as rage, can be used for any boss however
//	arg0 = ability slot
//	arg1 = sound
//	arg2 = summon per rage
//	arg3 = uber protection
//	arg4 = notification
//



#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#define MB 3
#define ME 2048

#undef REQUIRE_PLUGIN
#include <updater>

#define MANN_SND "ambient/siren.wav"
#define ENGY_SND "ui/message_update.wav"
#define SCOUT_R1 "vo/Scout_sf13_magic_reac03.wav"
#define SCOUT_R2 "vo/Scout_sf13_magic_reac07.wav"
#define SOLLY_R1 "vo/Soldier_sf13_magic_reac03.wav"
#define PYRO_R1 "vo/Pyro_autodejectedtie01.wav"
#define DEMO_R1	"vo/Demoman_sf13_magic_reac05.wav"
#define HEAVY_R1 "vo/Heavy_sf13_magic_reac01.wav"
#define HEAVY_R2 "vo/Heavy_sf13_magic_reac03.wav"
#define ENGY_R1 "vo/Engineer_sf13_magic_reac01.wav"
#define ENGY_R2 "vo/Engineer_sf13_magic_reac02.wav"
#define MEDIC_R1 "vo/Medic_sf13_magic_reac01.wav"
#define MEDIC_R2 "vo/Medic_sf13_magic_reac02.wav"
#define MEDIC_R3 "vo/Medic_sf13_magic_reac03.wav"
#define MEDIC_R4 "vo/Medic_sf13_magic_reac04.wav"
#define MEDIC_R5 "vo/Medic_sf13_magic_reac07.wav"
#define SNIPER_R1 "vo/Sniper_sf13_magic_reac01.wav"
#define SNIPER_R2 "vo/Sniper_sf13_magic_reac02.wav"
#define SNIPER_R3 "vo/Sniper_sf13_magic_reac04.wav"
#define SPY_R1 "vo/Spy_sf13_magic_reac01.wav"
#define SPY_R2 "vo/Spy_sf13_magic_reac02.wav"
#define SPY_R3 "vo/Spy_sf13_magic_reac03.wav"
#define SPY_R4 "vo/Spy_sf13_magic_reac04.wav"
#define SPY_R5 "vo/Spy_sf13_magic_reac05.wav"
#define SPY_R6 "vo/Spy_sf13_magic_reac06.wav"

#define PLUGIN_VERSION "1.09.1"
#define UPDATE_URL "http://www.shadow93.info/tf2/tf2plugins/abilityplugin/update.txt"
#define DEBUG   // This will enable verbose logging. Useful for developers testing their updates. 
new bossfreak;
new BossTeam=_:TFTeam_Blue;

new bool:bSalmon = false; 

public OnMapStart()
{
	PrecacheSound(MANN_SND,true);
	PrecacheSound(SCOUT_R1,true);
	PrecacheSound(SCOUT_R2,true);
	PrecacheSound(SOLLY_R1,true);
	PrecacheSound(PYRO_R1,true);
	PrecacheSound(DEMO_R1,true);
	PrecacheSound(HEAVY_R1,true);
	PrecacheSound(HEAVY_R2,true);
	PrecacheSound(ENGY_R1,true);
	PrecacheSound(ENGY_R2,true);
	PrecacheSound(MEDIC_R1,true);
	PrecacheSound(MEDIC_R2,true);
	PrecacheSound(MEDIC_R3,true);
	PrecacheSound(MEDIC_R4,true);
	PrecacheSound(MEDIC_R5,true);
	PrecacheSound(SNIPER_R1,true);
	PrecacheSound(SNIPER_R2,true);
	PrecacheSound(SNIPER_R3,true);
	PrecacheSound(SPY_R1,true);
	PrecacheSound(SPY_R2,true);	
	PrecacheSound(SPY_R3,true);
	PrecacheSound(SPY_R4,true);
	PrecacheSound(SPY_R5,true);
	PrecacheSound(SPY_R6,true);
	PrecacheSound(ENGY_SND,true);
}


public Plugin:myinfo = {
	name = "Freak Fortress 2: SHADoW93's Abilities Pack",
	author = "SHADoW NiNE TR3S",
	description="SHADoW NiNE TR3S'S Abilities Pack",
	version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	HookEvent("arena_round_start", event_round_start, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", event_round_end, EventHookMode_PostNoCopy);
	HookEvent("player_death", event_player_death);
	PrintToServer("SHADoW93 ABiLiTiES PACK VERSiON 1.09");
	if (LibraryExists("updater"))
    {
		Updater_AddPlugin(UPDATE_URL);
		PrintToServer("Checking for updates for shadow93_abilities.ff2");
	}
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_kritzkrieg")) 	// KRITZKRIEG
	{								
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		TF2_AddCondition(Boss,TFCond_Kritzkrieged,FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0)); // Kritzkrieg
	}
	else if (!strcmp(ability_name,"rage_hidden_uber")) 	// Hidden uber
	{			
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		TF2_AddCondition(Boss,TFCond_UberchargedHidden,FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0)); // Hidden Uber
	}
	else if (!strcmp(ability_name,"rage_taunt_slide")) 	// Taunt Sliding!!!!!
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		FakeClientCommand(Boss,"taunt");
		CreateTimer(0.1, TauntSliding);
	}
	else if(!strcmp(ability_name, "rage_invisibility_spell"))  // Mode matters if the boss is a spy-based boss using a knife (tested on Koishi)
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new cloakmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // Cloak type
		new cloakduration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2); // Cloak Duration
		if(cloakmode == 0)
			{
				TF2_AddCondition(Boss, TFCond:TFCond_Stealthed, float(cloakduration));
			}
		else if(cloakmode == 1)	
			{
				TF2_AddCondition(Boss, TFCond:TFCond_StealthedUserBuffFade, float(cloakduration));
			}
	}
	else if(!strcmp(ability_name, "rage_vaccinator"))  // Vaccinator resistances
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new vacmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // Resistance type
		if(vacmode == 0)
		{
			// All resistances
			TF2_AddCondition(Boss, TFCond_UberBulletResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); // Bullet Resistance
			TF2_AddCondition(Boss, TFCond_BulletImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); // Shield portion
			TF2_AddCondition(Boss, TFCond_UberBlastResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Blast Resistance
			TF2_AddCondition(Boss, TFCond_BlastImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Shield Portion
			TF2_AddCondition(Boss, TFCond_UberFireResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Fire Resistance
			TF2_AddCondition(Boss, TFCond_FireImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Shield Portion
		}
		else if(vacmode == 1)
		{
			// Bullet Resistance
			TF2_AddCondition(Boss, TFCond_UberBulletResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); // Bullet Resistance
			TF2_AddCondition(Boss, TFCond_BulletImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); // Shield portion
		}
		else if(vacmode == 2)
		{
			// Blast Resistance
			TF2_AddCondition(Boss, TFCond_UberBlastResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Blast Resistance
			TF2_AddCondition(Boss, TFCond_BlastImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Shield Portion
		}
		else if(vacmode == 3)
		{
			// Fire Resistance
			TF2_AddCondition(Boss, TFCond_UberFireResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Fire Resistance
			TF2_AddCondition(Boss, TFCond_FireImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Shield Portion
		}
	}
	else if (!strcmp(ability_name,"effect_classreaction"))
		Special_ClassLines(ability_name, index);						// Generic class reaction liness
	else if (!strcmp(ability_name,"rage_giant"))
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new giantmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // mode
		new duration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2); // Effect Duration
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(giantmode==0)
			{
				if(IsClientInGame(Boss) && IsPlayerAlive(Boss))
				{
					TF2_AddCondition(Boss, TFCond_HalloweenGiant, float(duration));
				}
			}
			else if(giantmode==1)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
				{
					TF2_AddCondition(i, TFCond_HalloweenGiant, float(duration));
				}
			}
			else if(giantmode==2)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					TF2_AddCondition(i, TFCond_HalloweenGiant, float(duration));
				}
			}
		}
	}
	else if (!strcmp(ability_name,"rage_minify"))						// Minify Spell
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new shrinkmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // mode
		new duration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2); // Effect Duration
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(shrinkmode==0)
			{
				if(IsClientInGame(Boss) && IsPlayerAlive(Boss))
				{
					TF2_AddCondition(Boss, TFCond_HalloweenTiny, float(duration));
				}
			}
			else if(shrinkmode==1)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
				{
					TF2_AddCondition(i, TFCond_HalloweenTiny, float(duration));
				}
			}
			else if(shrinkmode==2)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					TF2_AddCondition(i, TFCond_HalloweenTiny, float(duration));
				}
			}
		}
	}
	else if (!strcmp(ability_name,"rage_swimming_curse")) // Swimming Curse
	{
		new duration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // Effect Duration
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					TF2_AddCondition(i, TFCond_SwimmingCurse, float(duration));
				}
		}
	}
	else if (!strcmp(ability_name,"rage_salmon"))
		Rage_Salmon(ability_name, index);	// Otokiru's Charge_Salon converted to normal rage.
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:TauntSliding(Handle:hTimer,any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if(!TF2_IsPlayerInCondition(Boss, TFCond_Taunting))
	{
		TF2_RemoveCondition(Boss,TFCond_Taunting);
	}
}	

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	bSalmon = false;
	if (FF2_IsFF2Enabled())
	{
		
		bossfreak = GetClientOfUserId(FF2_GetBossUserId(0));
		if (bossfreak>0)
		{
			if (FF2_HasAbility(0, this_plugin_name, "critboost"))
			{	
				TF2_AddCondition(bossfreak, TFCond_CritCanteen, TFCondDuration_Infinite);
			}
			if (FF2_HasAbility(0, this_plugin_name, "giantboss"))
			{	
				TF2_AddCondition(bossfreak, TFCond_HalloweenGiant, TFCondDuration_Infinite);
			}
		}
	}
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsValidClient(bossfreak))
	{
		if(!TF2_IsPlayerInCondition(bossfreak, TFCond_CritCanteen))
		{
			TF2_RemoveCondition(bossfreak, TFCond_CritCanteen);
		}
		else if(!TF2_IsPlayerInCondition(bossfreak, TFCond_HalloweenGiant))
		{
			TF2_RemoveCondition(bossfreak, TFCond_HalloweenGiant);
		}
		else if(!TF2_IsPlayerInCondition(bossfreak, TFCond_HalloweenTiny))
		{
			TF2_RemoveCondition(bossfreak, TFCond_HalloweenTiny);
		}
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
			{
				if(!TF2_IsPlayerInCondition(i, TFCond_HalloweenGiant))
				{
					TF2_RemoveCondition(i, TFCond_HalloweenGiant);
				}
				else if(!TF2_IsPlayerInCondition(i, TFCond_HalloweenTiny))
				{
					TF2_RemoveCondition(i, TFCond_HalloweenTiny);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (bSalmon)
	{
		new client=GetClientOfUserId(GetEventInt(event, "userid"));
		new isBoss=FF2_GetBossIndex(client);
		if (isBoss!=-1)
		{
			for(new ii=1; ii<=MaxClients; ii++)
			{
				if(IsClientInGame(ii) && IsClientConnected(ii) && IsPlayerAlive(ii) && (GetClientTeam(ii)==BossTeam) && (FF2_GetBossIndex(client)!=-1))
				{
					ChangeClientTeam(ii,2);
				}
			}
			bSalmon = false;
		}
	}
}


// STOCKS //

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}


/////   RAGES	 /////

// Generic Class-Specific reaction lines for rage/death effect similar to rare spell reactions from Helltower

Special_ClassLines(const String:ability_name[],index)
{
	new voicelines=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // Enabled?
	if (voicelines != 0)
	{
		GetClientOfUserId(FF2_GetBossUserId(index));
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
			{
				if(TF2_GetPlayerClass(i)==TFClass_Scout)
					{
						switch (GetRandomInt(0,1))
							{
								case 0:
									EmitSoundToAll(SCOUT_R1,i);
								case 1:
									EmitSoundToAll(SCOUT_R2,i);
							}
					}
				else if(TF2_GetPlayerClass(i)==TFClass_Soldier)
					{
						EmitSoundToAll(SOLLY_R1,i);
					}
				else if(TF2_GetPlayerClass(i)==TFClass_Pyro)
					{
						EmitSoundToAll(PYRO_R1,i);
					}
				else if(TF2_GetPlayerClass(i)==TFClass_DemoMan)
					{
						EmitSoundToAll(DEMO_R1,i);
					}
				else if(TF2_GetPlayerClass(i)==TFClass_Heavy)
					{
						switch (GetRandomInt(0,1))
							{
								case 0:
									EmitSoundToAll(HEAVY_R1,i);
								case 1:
									EmitSoundToAll(HEAVY_R2,i);
							}
					}
				else if(TF2_GetPlayerClass(i)==TFClass_Engineer)
					{
						switch (GetRandomInt(0,1))
							{
								case 0:
									EmitSoundToAll(ENGY_R1,i);
								case 1:
									EmitSoundToAll(ENGY_R2,i);
							}
					}
				else if(TF2_GetPlayerClass(i)==TFClass_Medic)
					{
						switch (GetRandomInt(0,4))
							{
								case 0:
									EmitSoundToAll(MEDIC_R1,i);
								case 1:
									EmitSoundToAll(MEDIC_R2,i);
								case 2:
									EmitSoundToAll(MEDIC_R3,i);
								case 3:
									EmitSoundToAll(MEDIC_R4,i);
								case 4:
									EmitSoundToAll(MEDIC_R5,i);
							}
					}	
				else if(TF2_GetPlayerClass(i)==TFClass_Sniper)
					{
						switch (GetRandomInt(0,2))
							{
								case 0:
									EmitSoundToAll(SNIPER_R1,i);
								case 1:
									EmitSoundToAll(SNIPER_R2,i);
								case 2:
									EmitSoundToAll(SNIPER_R3,i);
							}
					}	
				else if(TF2_GetPlayerClass(i)==TFClass_Spy)
					{
						switch (GetRandomInt(0,4))
							{
								case 0:
									EmitSoundToAll(SPY_R1,i);
								case 1:
									EmitSoundToAll(SPY_R2,i);
								case 2:
									EmitSoundToAll(SPY_R3,i);
								case 3:
									EmitSoundToAll(SPY_R4,i);
								case 4:
									EmitSoundToAll(SPY_R5,i);
								case 5:
									EmitSoundToAll(SPY_R6,i);
							}								
					}
			}
	}
}


// Modified version of Otokiru's Charge_Salmon
Rage_Salmon(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new var1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//sound
	new var2=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//summon_per_rage
	new Float:duration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,3,3.0); //uber_protection
	new notify=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4);	//notification alert
	new humanorbot=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5);	//humans or bots?
	if(var1!=0)
		{
			EmitSoundToAll(MANN_SND);
			EmitSoundToAll(MANN_SND);
		}
	new ii;
	for (new i=0; i<var2; i++)
	{
		ii = GetRandomDeadPlayer();
		if(ii != -1)
		{
			bSalmon = true;
			FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
			ChangeClientTeam(ii,BossTeam);
			TF2_RespawnPlayer(ii);
			if(humanorbot==0) // Minions are humans
			{
				TF2_AddCondition(ii, TFCond_Ubercharged, duration);
			}
			else if(humanorbot==1) // Minions are robots
			{
				if(TF2_GetPlayerClass(ii)==TFClass_Scout)
				{
					SetVariantString("models/bots/scout/bot_scout.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_Soldier)
				{
					SetVariantString("models/bots/soldier/bot_soldier.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_Pyro)
				{
					SetVariantString("models/bots/pyro/bot_pyro.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_DemoMan)
				{
					SetVariantString("models/bots/demo/bot_demo.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_Heavy)
				{
					SetVariantString("models/bots/heavy/bot_heavy.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_Engineer)
				{
					SetVariantString("models/bots/engineer/bot_engineer.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_Medic)
				{
					SetVariantString("models/bots/medic/bot_medic.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_Sniper)
				{
					SetVariantString("models/bots/sniper/bot_sniper.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				else if(TF2_GetPlayerClass(ii)==TFClass_Spy)
				{
					SetVariantString("models/bots/spy/bot_spy.mdl");
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				TF2_AddCondition(ii, TFCond_UberchargedHidden, duration);
			}
		}
	}
	if(notify!=0)
	{
		PrintCenterText(Boss,"Your team has spawned, they will assist you");
	}
}			
stock GetRandomDeadPlayer()
{
	new clients[MaxClients+1], clientCount;
	for(new i=1;i<=MaxClients;i++)
	{
		if (IsValidEdict(i) && IsClientConnected(i) && IsClientInGame(i) && !IsPlayerAlive(i) && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}


// MISC //

public Action:Timer_ResetCharge(Handle:timer, any:index)
{
	new slot=index%10000;
	index/=1000;
	FF2_SetBossCharge(index,slot,0.0);
}

public Action:FF2_OnTriggerHurt(index,triggerhurt,&Float:damage)
{
	return Plugin_Continue;
}