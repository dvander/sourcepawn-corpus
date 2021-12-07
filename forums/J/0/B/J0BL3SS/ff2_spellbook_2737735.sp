#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2: Spellbook"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Spooky Spells"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "5"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL "www.skyregiontr.com"

#define MAXPLAYERARRAY MAXPLAYERS+1

/*
 *	Defines "rage_spell_X"
 */
bool AMS_SPL[10][MAXPLAYERARRAY];			//Internal 	- AMS Trigger
int SPL_SpellIndex[10][MAXPLAYERARRAY];		//arg1		- Spell Index
int SPL_SpellCount[10][MAXPLAYERARRAY];		//arg2		- Spell Count
bool SPL_ForceUse[10][MAXPLAYERARRAY];		//arg3		- Force use? 			0=no, 1=yes

/*
 *	Defines "spellbook_hud"
 */
#define SPELLHUD "spellbook_hud"
Handle SpellHud;
char HudStrings[MAXPLAYERARRAY][768];
int HudColor[MAXPLAYERARRAY][4];
float HudCordinate[MAXPLAYERARRAY][2];

/*
 *	Defines "spell_caos"
 */
#define CAOS "spell_chaos"					
bool AMS_CAOS[MAXPLAYERARRAY];				//Internal 	- AMS Trigger
int CAOS_SpellCount[MAXPLAYERARRAY];		//arg1		- Spell Count
float CAOS_Cooldown[MAXPLAYERARRAY];		//arg2		- Cooldown Between Two Spell


public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
	
	SpellHud = CreateHudSynchronizer();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
	
	MainBoss_PrepareAbilities();
	CreateTimer(1.0, TimerHookSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerHookSpawn(Handle timer)
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserIdx = GetEventInt(event, "userid");
	
	if(IsValidClient(GetClientOfUserId(UserIdx)))
	{
		CreateTimer(0.3, SummonedBoss_PrepareAbilities, UserIdx, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("ERROR: Invalid client index. %s:Event_PlayerSpawn()", this_plugin_name);
	}
}

public Action SummonedBoss_PrepareAbilities(Handle timer, int UserIdx)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return;
	
	int bossClientIdx = GetClientOfUserId(UserIdx);
	if(IsValidClient(bossClientIdx))
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
	else
	{
		LogError("ERROR: Unable to find respawned player. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
	}
}


public void MainBoss_PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		LogError("ERROR: Abilitypack called when round is over or when gamemode is not FF2. %s:MainBoss_PrepareAbilities()", this_plugin_name);
		return;
	}
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
}

public void ClearEverything()
{	
	for(int i = 1; i <= MaxClients; i++)
	{
		for(int Num = 0; Num < 10; Num++)
		{
			AMS_SPL[Num][i] = false;
		}
		
		AMS_CAOS[i] = false;
		
		RemoveSpellbook(i);
	}
}

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)
	{
		char AbilityName[96], AbilityShort[96];
		for(int Num = 0; Num < 10; Num++)
		{
			Format(AbilityName, sizeof(AbilityName), "rage_spell_%i", Num);
			if(FF2_HasAbility(bossIdx, this_plugin_name, AbilityName))
			{
				AMS_SPL[Num][bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, AbilityName);
				if(AMS_SPL[Num][bossClientIdx])
				{
					Format(AbilityShort, sizeof(AbilityShort), "SPL%i", Num);
					AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, AbilityName, AbilityShort);
				}
				SpawnWeapon(bossClientIdx, "tf_weapon_spellbook", 1069, 0, 0, "138 ; 0.33 ; 15 ; 0", false);
				
				PrintToServer("Found ability \"%s\" on player %N. Hooking the ability. %s:HookAbilities()", AbilityName, bossClientIdx, this_plugin_name);
			}
		}
		if(FF2_HasAbility(bossIdx, this_plugin_name, SPELLHUD))
		{
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SPELLHUD, 1, HudStrings[bossClientIdx], 768);
			
			HudCordinate[bossClientIdx][0] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SPELLHUD, 2, -1.0);
			HudCordinate[bossClientIdx][1] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SPELLHUD, 3, 0.77);
			
			HudColor[bossClientIdx][0] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SPELLHUD, 4, 255);
			HudColor[bossClientIdx][1] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SPELLHUD, 5, 255);
			HudColor[bossClientIdx][2] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SPELLHUD, 6, 255);
			HudColor[bossClientIdx][3] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SPELLHUD, 7, 255);
			
			PrintToServer("Found ability \"%s\" on player %N. Hooking the ability. %s:HookAbilities()", SPELLHUD, bossClientIdx, this_plugin_name);
			
			CreateTimer(0.3, ShowSpellStatus, bossClientIdx, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		if(FF2_HasAbility(bossIdx, this_plugin_name, CAOS))
		{
			//AMS Triggers
			AMS_CAOS[bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, CAOS);
			if(AMS_CAOS[bossClientIdx])
			{
				AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, CAOS, "CAOS");
			}
			CAOS_SpellCount[bossClientIdx] 	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, CAOS, 1, 30);
			CAOS_Cooldown[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, CAOS, 2, 0.7);
			
			SpawnWeapon(bossClientIdx, "tf_weapon_spellbook", 1069, 0, 0, "138 ; 0.33 ; 15 ; 0", false);
			
			PrintToServer("Found ability \"%s\" on player %N. Hooking the ability. %s:HookAbilities()", CAOS, bossClientIdx, this_plugin_name);
		}
	}
}

public Action ShowSpellStatus(Handle timer, any bossClientIdx)
{
	if(!IsValidClient(bossClientIdx) || !IsPlayerAlive(bossClientIdx) || FF2_GetRoundState()!=1)
		return Plugin_Stop;
		
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		int Spellbook = FindSpellBook(iClient);
		if(Spellbook != -1)
		{	
			char HUDStatus[256];
			SetHudTextParams(HudCordinate[bossClientIdx][0], HudCordinate[bossClientIdx][1], 0.4,
			HudColor[bossClientIdx][0], 
			HudColor[bossClientIdx][1], 
			HudColor[bossClientIdx][2], 
			HudColor[bossClientIdx][3]);
			int SpellCount = GetEntProp(Spellbook, Prop_Send, "m_iSpellCharges");		//Spell Count
			if(SpellCount > 0)
			{
				int SpellIndex = GetEntProp(Spellbook, Prop_Send, "m_iSelectedSpellIndex");	//Spell Index
				char SpellName[96];
				switch(SpellIndex)
				{
					case 0:		SpellName = "Fireball";
					case 1:		SpellName = "Bat Swarm";
					case 2:		SpellName = "Healing Aura";
					case 3:		SpellName = "Pumpkin Bombs";
					case 4:		SpellName = "Blast Jump";
					case 5:		SpellName = "Invisibility";
					case 6:		SpellName = "Teleport";
					case 7: 	SpellName = "Lightning";
					case 8: 	SpellName = "Minify";
					case 9: 	SpellName = "Meteor Shower";
					case 10:	SpellName = "Monoculus";
					case 11:	SpellName = "Skeleton";
				}
				Format(HUDStatus, sizeof(HUDStatus), HudStrings[bossClientIdx], SpellCount, SpellName);
				ShowSyncHudText(iClient, SpellHud, HUDStatus);
				CloseHandle(SpellHud);
			}
		}
		else
		{
			//LogError("ERROR: Boss has no Spellbook equiped. %s:ShowSpellStatus()", this_plugin_name);
		}
			
	}
	return Plugin_Continue;
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));

	//SpellBooks
	char AbilityName[96];
	for(int Num = 0; Num < 10; Num++)
	{
		Format(AbilityName, sizeof(AbilityName), "rage_spell_%i", Num);
		if(!strcmp(ability_name, AbilityName))
		{
			if(AMS_SPL[Num][bossClientIdx])
			{
				if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
				{
					AMS_SPL[Num][bossClientIdx] = false;
				}
				else
				{
					return Plugin_Continue;
				}
			}
			if(!AMS_SPL[Num][bossClientIdx])
			{
				CastSpell(bossIdx, bossClientIdx, ability_name, Num);
			}
		}
	}
	//Spell Caos
	if(!strcmp(ability_name, CAOS))
	{
		if(AMS_CAOS[bossClientIdx])
		{
			if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
			{
				AMS_CAOS[bossClientIdx] = false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		if(!AMS_CAOS[bossClientIdx])
		{
			CAOS_Invoke(bossClientIdx);	
		}	
	}
	return Plugin_Continue;
}

public bool SPL0_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL1_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL2_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL3_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL4_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL5_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL6_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL7_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL8_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool SPL9_CanInvoke(int bossClientIdx)
{
	return true;
}

public void SPL0_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_0", 0);
}

public void SPL1_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_1", 1);
}

public void SPL2_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_2", 2);
}

public void SPL3_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_3", 3);
}

public void SPL4_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_4", 4);
}

public void SPL5_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_5", 5);
}

public void SPL6_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_6", 6);
}

public void SPL7_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_7", 7);
}

public void SPL8_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_8", 8);
}

public void SPL9_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_spell_9", 9);
}

public void CastSpell(int bossIdx, int bossClientIdx, const char[] ability_name, int Num)
{
	int Spellbook = FindSpellBook(bossClientIdx);
	if(Spellbook != -1)
	{
		SPL_SpellIndex[Num][bossClientIdx] 	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 1, -1);
		SPL_SpellCount[Num][bossClientIdx] 	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 2, 3);
		SPL_ForceUse[Num][bossClientIdx] 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 3, 0));
		
		if(AMS_SPL[Num][bossClientIdx])
		{
			char AbilitySound[128];
			Format(AbilitySound, sizeof(AbilitySound), "sound_spell_%i", Num);
			FF2_EmitRandomSound(bossClientIdx, AbilitySound);
		}
	
		if(SPL_SpellIndex[Num][bossClientIdx] == -1) {
			SPL_SpellIndex[Num][bossClientIdx] = GetRandomInt(0, 11);
		}
		if(GetEntProp(Spellbook, Prop_Send, "m_iSelectedSpellIndex") == SPL_SpellIndex[Num][bossClientIdx])
		{
			int SpellCount = GetEntProp(Spellbook, Prop_Send, "m_iSpellCharges");		//Spell Count
			SetEntProp(Spellbook, Prop_Send, "m_iSpellCharges", SPL_SpellCount[Num][bossClientIdx] + SpellCount);
		}
		else
		{
			SetEntProp(Spellbook, Prop_Send, "m_iSelectedSpellIndex", SPL_SpellIndex[Num][bossClientIdx]);	//Spell Index
			SetEntProp(Spellbook, Prop_Send, "m_iSpellCharges", SPL_SpellCount[Num][bossClientIdx]);		//Spell Count
		}
		
		
		if(SPL_ForceUse[Num][bossClientIdx])
		{
			if(!TF2_IsPlayerInCondition(bossClientIdx, TFCond_Cloaked) || !TF2_IsPlayerInCondition(bossClientIdx, TFCond_CloakFlicker))
			{
				FakeClientCommand(bossClientIdx, "use tf_weapon_spellbook"); // use first spell already
			}
			CreateTimer(0.7, UseSpell, bossClientIdx, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT); // use all the spells
		}
	}
	else
		LogError("ERROR: Boss has no Spellbook equiped. %s:CastSpell()", this_plugin_name);
}

public Action UseSpell(Handle timer, int bossClientIdx)
{
	int Spellbook = FindSpellBook(bossClientIdx);
	if(Spellbook != -1)
	{
		if(!TF2_IsPlayerInCondition(bossClientIdx, TFCond_Cloaked) || !TF2_IsPlayerInCondition(bossClientIdx, TFCond_CloakFlicker))
		{
			if(!GetEntProp(Spellbook, Prop_Send, "m_iSpellCharges")) // if has no spell
			{
				return Plugin_Stop; // quit loop
			}
			else
			{
				FakeClientCommand(bossClientIdx, "use tf_weapon_spellbook");	//Force Spell Usage
			}
		}
	}
	return Plugin_Continue;
}

public bool CAOS_CanInvoke(int bossClientIdx)
{
	return true;
}

public void CAOS_Invoke(int bossClientIdx)
{
	if(AMS_CAOS[bossClientIdx])
	{
		FF2_EmitRandomSound(bossClientIdx, "sound_spellcaos");
	}
	if(CAOS_Cooldown[bossClientIdx] < 0.7)
		CAOS_Cooldown[bossClientIdx] = 0.7;
	
	CreateTimer(CAOS_Cooldown[bossClientIdx], SpellCaos, bossClientIdx, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action SpellCaos(Handle timer, int bossClientIdx)
{
	if(!IsValidClient(bossClientIdx) || !IsPlayerAlive(bossClientIdx) || FF2_GetRoundState()!=1)
		return Plugin_Stop;

	static int Count = 0;
	if(Count < CAOS_SpellCount[bossClientIdx])
	{
		RemoveSpellbook(bossClientIdx);
		SpawnWeapon(bossClientIdx, "tf_weapon_spellbook", 1069, 0, 0, "138 ; 0.33 ; 15 ; 0 ; 178 ; 0.00005", false);
		
		int Spellbook = FindSpellBook(bossClientIdx);
		if(Spellbook != -1)
		{
			int SpellIndex;
			switch(GetRandomInt(0,10))
			{
				case 0,1:			SpellIndex = 0; //"Fireball"
				case 2,3:			SpellIndex = 1; //"Bat Swarm"
				case 4,5:			SpellIndex = 7; //"Lightning"
				case 6,7:			SpellIndex = 3; //"Pumpkin Bombs"
				case 8:				SpellIndex = 9;	//"Meteor Shower"
				case 9:				SpellIndex = 10; //"Monoculus"
				case 10: 			SpellIndex = 11; //"Skeleton" //More than half of servers don't have nav meshs	
			}
			
			SetEntProp(Spellbook, Prop_Send, "m_iSelectedSpellIndex", SpellIndex);	//Spell Index
			SetEntProp(Spellbook, Prop_Send, "m_iSpellCharges", 1);					//Spell Count
			FakeClientCommand(bossClientIdx, "use tf_weapon_spellbook");
			Count++;
		}
	}
	else
	{
		RemoveSpellbook(bossClientIdx);	
		SpawnWeapon(bossClientIdx, "tf_weapon_spellbook", 1069, 0, 0, "138 ; 0.33 ; 15 ; 0", false);
		Count = 0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


stock bool IsValidClient(int client, bool replaycheck=true)
{
	//Borrowed from Batfoxkid
	
	if(client <= 0 || client > MaxClients)
		return false;

	if(!IsClientInGame(client) || !IsClientConnected(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

stock int FindSpellBook(int iClient)
{
	int Spellbook = -1;
	while((Spellbook = FindEntityByClassname(Spellbook, "tf_weapon_spellbook")) != -1)
	{
		if(IsValidEntity(Spellbook) && GetEntPropEnt(Spellbook, Prop_Send, "m_hOwnerEntity") == iClient)
		{
			if(!GetEntProp(Spellbook, Prop_Send, "m_bDisguiseWeapon"))
			{
				return Spellbook;
			}
		}
	}
	return -1;
}

stock void RemoveSpellbook(int iClient)
{
	int iEntity1 = -1;
	while((iEntity1 = FindEntityByClassname(iEntity1, "tf_weapon_spellbook")) != -1)
	{
 		if(GetEntPropEnt(iEntity1, Prop_Send, "m_hOwnerEntity") == iClient)
 		{
 			if(!GetEntProp(iEntity1, Prop_Send, "m_bDisguiseWeapon"))
 			{
 				TF2_RemoveWearable(iClient, iEntity1);
 			}
 		}
 	}
}

#if !defined _FF2_Extras_included
stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute, bool visible = true, bool preserve = false)
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
		
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
	}
	
	if(StrContains(name, "tf_wearable")==-1)
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

public void FF2_EmitRandomSound(int bossClientIdx, const char[] keyvalue)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	char sound[PLATFORM_MAX_PATH]; float pos[3];
	if(FF2_RandomSound(keyvalue, sound, sizeof(sound), bossIdx))
	{
		GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", pos);
		EmitSoundToAll(sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
		EmitSoundToAll(sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
					
		for(int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if(IsClientInGame(iClient) && iClient != bossClientIdx)
			{
				EmitSoundToClient(iClient, sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
				EmitSoundToClient(iClient, sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
			}
		}
	}
}
