#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sourcemod>
#include <sdktools>
#include <tf2items>

#pragma semicolon 1
#pragma tabsize 0

//*								CREDITS										*//
//*																			*//
//*			Shadow93 - For the FOG											*//
//*			Deathreus - The New Weapon ability itself, Timed new weapon.	*//
//*			Sarysa - taken the Host timescale/global sounds code.			*//
//*																			*//
//*			No fucking clue when i will make my own Weapon ability lol.		*//

#define INACTIVE 100000000.0

float WeaponTime[MAXPLAYERS+1];
bool Enabled = false;

int envFog=-1;
float fogDuration[MAXPLAYERS+1]=INACTIVE;

Handle cvarTimeScale = INVALID_HANDLE;
Handle cvarCheats = INVALID_HANDLE;

float duration;
float finish_delay;
float hp_check;
float slowmo;

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))
#define MAX_SOUND_LENGTH	80	// Maximum Sound Filepath
#define MAX_SOUND_FILE_LENGTH 80

public void OnMapStart()
{
}

public void OnPluginStart2() 
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
	
	HookEvent("player_hurt", OnPlayerHurt);
	//HookEvent("player_death", OnPlayerDeath);
	
	cvarTimeScale = FindConVar("host_timescale");
	cvarCheats = FindConVar("sv_cheats");
	
	LoadTranslations("freak_fortress_2.phrases");
}

public void FF2_OnAbility2(int iIndex, const char[] pluginName, const char[] abilityName, int iStatus) 
{
	int boss;
	iIndex = GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!strcmp(abilityName, "special_finisher_heavy"))	
	{
		static String:soundFile[MAX_SOUND_FILE_LENGTH];
		ReadSound(boss, "special_finisher_heavy", 16, soundFile);
		if (strlen(soundFile) > 3)
			EmitSoundToAll(soundFile);
			
		special_finish(iIndex, abilityName);
	}
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast) 
{
	for(int client = 1; client <=MaxClients; client++)
	{				
		if (IsValidClient(client))
		{
			int boss = FF2_GetBossIndex(client);
			if (boss>=0)
			{
				if (FF2_HasAbility(boss, this_plugin_name, "special_finisher_heavy"))
				{
					duration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 13, 1.5);
					finish_delay = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 14, 1.5);
					slowmo = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 15, 0.2);
					hp_check = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 18, 340.0);
				}
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	KillFog(envFog);

	for(int client=MaxClients;client;client--)
	{
		if(client<=0||client>MaxClients||!IsClientInGame(client))
		{
			continue;
		}
		
		if(fogDuration[client]!=INACTIVE)
		{
			fogDuration[client]=INACTIVE;
			SDKUnhook(client, SDKHook_PreThinkPost, FogTimer);
		}			
	}
	envFog=-1;
}


void special_finish(int iBIndex, const char[] ability_name)
{
	int iBoss = GetClientOfUserId(FF2_GetBossUserId(iBIndex));
	Enabled = true;
	static char sAttributes[256], sClassname[96];
	WeaponTime[iBoss] = FF2_GetAbilityArgumentFloat(iBIndex, this_plugin_name, ability_name, 1, 10.0);

	// Weapons classname
	FF2_GetAbilityArgumentString(iBIndex, this_plugin_name, ability_name, 2, sClassname, 96);
	// Attributes to apply to the weapon
	FF2_GetAbilityArgumentString(iBIndex, this_plugin_name, ability_name, 4, sAttributes, 256);

	// Slot of the weapon 0=Primary(Or sapper), 1=Secondary(Or spies revolver), 2=Melee, 3=PDA1(Build tool, disguise kit), 4=PDA2(Destroy tool, cloak), 5=Building
	int iSlot = FF2_GetAbilityArgument(iBIndex, this_plugin_name, ability_name, 5);
	TF2_RemoveWeaponSlot(iBoss, iSlot);
	
	int iIndex = FF2_GetAbilityArgument(iBIndex, this_plugin_name, ability_name, 3);
	
	bool bHide = FF2_GetAbilityArgument(iBIndex, this_plugin_name, ability_name, 6, 0) != 0;

	int iWep = SpawnWeapon(iBoss, sClassname, iIndex, 100, 5, sAttributes, bHide);
	
	// Make them equip it?
	if (FF2_GetAbilityArgument(iBIndex, this_plugin_name, ability_name, 7))
		SetEntPropEnt(iBoss, Prop_Send, "m_hActiveWeapon", iWep);
						
	if(WeaponTime[iBoss] > 0.0)
	{
		// Duration to keep the weapon, set to 0 or -1 to keep the weapon
		WeaponTime[iBoss] += GetEngineTime();
		SDKHook(iBoss, SDKHook_PreThink, Boss_Think);
	}
}

public void Boss_Think(int iBoss)
{	
	if(GetEngineTime() >= WeaponTime[iBoss])
	{
		RemoveWeapons(iBoss);
		ApplyDefaultWeapons(iBoss);
		
		SDKUnhook(iBoss, SDKHook_PreThink, Boss_Think);
		Enabled = false;

	}
}

stock void RemoveWeapons(int iClient)
{
	if (IsValidClient(iClient, true, true))
	{
		
		if(GetPlayerWeaponSlot(iClient, 2) != -1)
			TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Melee);
		
		SwitchtoSlot(iClient, TFWeaponSlot_Melee);
	}
}

// Just saying, the fog doesnt work in the first round, im too lazy to fix it lol.
// Also this Ability is really good, you keep your Main weapon that is set in the config of the hale
public int OnPlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker || !IsClientInGame(client) || !IsClientInGame(attacker))
		return;
	
	int boss = FF2_GetBossIndex(attacker);
	attacker = GetClientOfUserId(FF2_GetBossUserId(boss));
	if(boss >= 0)
	{
		if(FF2_HasAbility(boss, this_plugin_name, "special_finisher_heavy"))
		{		
			if(Enabled)
			{
				// Telling you, im pretty new to coding, if theres any less complicated way to make this hit me up im up to learn new things
				if (TF2_GetPlayerClass(client) == TFClass_Heavy)
				{	
					if(GetEntProp(client, Prop_Data, "m_iHealth") > hp_check)		// Just in case that the heavy is above 340 health to get oneshotted
					{						
							
						if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged))	// Make it not go through when Ubercharged
							return;
						
						if (TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen))	// Make it not go through when Ubercharged
							return;
						
						if (TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden))	// Make it not go through when Ubercharged
							return;
						
						DSD_UpdateClientCheatValue(1);
						SetConVarFloat(cvarTimeScale, slowmo);
							
						RemoveWeapons(attacker);
						ApplyDefaultWeapons(attacker);
											
						SDKUnhook(attacker, SDKHook_PreThink, Boss_Think);
						AttachParticle(client, "flash_doomsday");
						FOG_Invoke(attacker, -1);
										
						if (duration > 0.0)
							TF2_StunPlayer(client, duration, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
							
						CreateTimer(finish_delay, finish_user, client, TIMER_FLAG_NO_MAPCHANGE);	
					}
				}
			}
		}
	}			
}

public Action finish_user(Handle timer, int client)
{
	SetConVarFloat(cvarTimeScale, 1.0);
	DSD_UpdateClientCheatValue(0);
	
	if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged))	// Just in case if the person is ubercharged earlier, letting the Medic or something else save the Heavy from the Finisher.
		return;
	
	if (TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen))	// Just in case if the person is ubercharged earlier, letting the Medic or something else save the Heavy from the Finisher.
		return;
	
	if (TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden))	// Just in case if the person is ubercharged earlier, letting the Medic or something else save the Heavy from the Finisher.
		return;
	
	FakeClientCommand(client, "kill");
	
	int boss;
	client = GetClientOfUserId(FF2_GetBossUserId(boss));	
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(boss, "special_finisher_heavy", 17, soundFile);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);	
}

stock ReadSound(boss, const String:ability_name[], argInt, String:soundFile[MAX_SOUND_FILE_LENGTH])
{
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, argInt, soundFile, MAX_SOUND_FILE_LENGTH);
	if (strlen(soundFile) > 3)
		PrecacheSound(soundFile);
}

public void FOG_Invoke(int client, int index)
{
	int fogcolor[3][3];
	
	int boss=FF2_GetBossIndex(client);
	
	// fog color
	fogcolor[0][0]=FF2_GetAbilityArgument(boss, this_plugin_name, "special_finisher_heavy", 22, 255);
	fogcolor[0][1]=FF2_GetAbilityArgument(boss, this_plugin_name, "special_finisher_heavy", 23, 255);
	fogcolor[0][2]=FF2_GetAbilityArgument(boss, this_plugin_name, "special_finisher_heavy", 24, 255);
	// fog color 2
	fogcolor[1][0]=FF2_GetAbilityArgument(boss, this_plugin_name, "special_finisher_heavy", 25, 255);
	fogcolor[1][1]=FF2_GetAbilityArgument(boss, this_plugin_name, "special_finisher_heavy", 26, 255);
	fogcolor[1][2]=FF2_GetAbilityArgument(boss, this_plugin_name, "special_finisher_heavy", 27, 255);
	// fog start
	float fogstart=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 28, 64.0);
	// fog end
	float fogend=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 29, 384.0);
	// fog density
	float fogdensity=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 30, 1.0);
	
	if(fogDuration[client]!=INACTIVE)
	{
		fogDuration[client]+=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 31, 5.0);
	}
	else
	{
		envFog = StartFog(FF2_GetAbilityArgument(boss, this_plugin_name, "special_finisher_heavy", 20, 0), fogcolor[0], fogcolor[1], fogstart, fogend, fogdensity);
		fogDuration[client]=GetGameTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_finisher_heavy", 31, 5.0);
		SDKHook(client, SDKHook_PreThinkPost, FogTimer);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetVariantString("MyFog");
			AcceptEntityInput(i, "SetFogController");
		}
	}
}

public void FogTimer(int client)
{
	if(GetGameTime()>=fogDuration[client])
	{
		KillFog(envFog);
		fogDuration[client]=INACTIVE;
		SDKUnhook(client, SDKHook_PreThinkPost, FogTimer);
		envFog=-1;
	}
}

int StartFog(int fogblend, int fogcolor[3], int fogcolor2[3], float fogstart=64.0, float fogend=384.0, float fogdensity=1.0)
{
	int iFog = CreateEntityByName("env_fog_controller");

	char fogcolors[3][16];
	IntToString(fogblend, fogcolors[0], sizeof(fogcolors[]));
	FormatEx(fogcolors[1], sizeof(fogcolors[]), "%i %i %i", fogcolor[0], fogcolor[1], fogcolor[2]);
	FormatEx(fogcolors[2], sizeof(fogcolors[]), "%i %i %i", fogcolor2[0], fogcolor2[1], fogcolor2[2]);
	if(IsValidEntity(iFog)) 
	{
        DispatchKeyValue(iFog, "targetname", "MyFog");
        DispatchKeyValue(iFog, "fogenable", "1");
        DispatchKeyValue(iFog, "spawnflags", "1");
        DispatchKeyValue(iFog, "fogblend", fogcolors[0]);
        DispatchKeyValue(iFog, "fogcolor", fogcolors[1]);
        DispatchKeyValue(iFog, "fogcolor2", fogcolors[2]);
        DispatchKeyValueFloat(iFog, "fogstart", fogstart);
        DispatchKeyValueFloat(iFog, "fogend", fogend);
        DispatchKeyValueFloat(iFog, "fogmaxdensity", fogdensity);
        DispatchSpawn(iFog);
        
        AcceptEntityInput(iFog, "TurnOn");
	}
	return iFog;
}

stock bool IsEntityValid(int ent)
{
	return 	IsValidEntity(ent) && ent > MaxClients;
}

stock void KillFog(int entity)
{
	if (IsEntityValid(entity))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SetVariantString("");
				AcceptEntityInput(i, "SetFogController");
			}
		}
		AcceptEntityInput(entity, "Kill");
		entity=-1;
	}
}

public Action DeleteParticle(Handle timer, any Ent)
{
	if (!IsValidEntity(Ent)) return;
	char cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
}

stock bool AttachParticle(int Ent, char[] particleType, bool cache=false) // from L4D Achievement Trophy
{
	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return false;
	char tName[128];
	float f_pos[3];
	if (cache) f_pos[2] -= 3000;
	else
	{
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", f_pos);
		f_pos[2] += 60;
	}
	TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", Ent);
	DispatchKeyValue(Ent, "targetname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(10.0, DeleteParticle, particle);
	return true;
}

stock void SwitchtoSlot(int iClient, int iSlot)
{
	if (iSlot >= 0 && iSlot <= 5 && IsValidClient(iClient, true))
	{
		char sClassname[96];
		int iWep = GetPlayerWeaponSlot(iClient, iSlot);
		if (iWep > MaxClients && IsValidEdict(iWep) && GetEdictClassname(iWep, sClassname, sizeof(sClassname)))
		{
			FakeClientCommandEx(iClient, "use %s", sClassname);
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWep);
		}
	}
}

stock bool IsValidClient(int iClient, bool bAlive = false, bool bTeam = false)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;
	
	return true;
}

stock int FindEntityByClassname1(int EntStrt, const char[] sClassname)
{
	while (EntStrt > -1 && !IsValidEntity(EntStrt)) EntStrt--;
	return FindEntityByClassname(EntStrt, sClassname);
}

// From ff2_sarysapub3

// By Mecha the Slag, lifted from 1st set abilities and tweaked
DSD_UpdateClientCheatValue(valueInt)
{
	if (cvarCheats == INVALID_HANDLE)
		return;

	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (IsClientInGame(clientIdx) && !IsFakeClient(clientIdx))
		{
			static String:valueS[2];
			IntToString(valueInt, valueS, sizeof(valueS));
			SendConVarValue(clientIdx, cvarCheats, valueS);
		}
	}
}

stock int SpawnWeapon(int iClient, char[] sClassname, int iIndex, int iLevel, int iQuality, const char[] sAttribute = "", bool bHide = false)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon == INVALID_HANDLE)
		return -1;
		
	TF2Items_SetClassname(hWeapon, sClassname);
	TF2Items_SetItemIndex(hWeapon, iIndex);
	TF2Items_SetLevel(hWeapon, iLevel);
	TF2Items_SetQuality(hWeapon, iQuality);
	
	char sAttributes[32][32];
	int countf = ExplodeString(sAttribute, " ; ", sAttributes, 32, 32);
	if (countf % 2)
		--countf;
		
	if (countf > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, countf/2);
		int i2;
		for(int i; i < countf; i += 2)
		{
			int iAttrib = StringToInt(sAttributes[i]);
			if (!iAttrib)
			{
				delete hWeapon;
				return -1;
			}
			TF2Items_SetAttribute(hWeapon, i2, iAttrib, StringToFloat(sAttributes[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
		
	int iEntity = TF2Items_GiveNamedItem(iClient, hWeapon);
	EquipPlayerWeapon(iClient, iEntity);
	delete hWeapon;
	
	if (bHide)
	{
		SetEntProp(iEntity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 0.0001);
	}
	
	return iEntity;
}

void ApplyDefaultWeapons(int iClient)
{
	if(!IsValidClient(iClient))
	{
		return;
	}
	Enabled = false;
	TF2_RemoveAllWeapons(iClient);
	int boss=FF2_GetBossIndex(iClient);

	char weapon[64], attributes[256];
	static KeyValues config;
	config = view_as<KeyValues>(FF2_GetSpecialKV(boss));
	
	for(int j=1; ; j++)
	{
		config.Rewind();
		Format(weapon, 10, "weapon%i", j);

		if(config.JumpToKey(weapon))
		{
			config.GetString("name", weapon, sizeof(weapon));
			config.GetString("attributes", attributes, sizeof(attributes));
			if(attributes[0]!='\0')
			{

				Format(attributes, sizeof(attributes), "68 ; 2.0 ; 2 ; 3.1 ; %s", attributes);
					//68: +2 cap rate
					//2: x3.1 damage
			}
			else
			{
				Format(attributes, sizeof(attributes), "68 ; 2.0 ; 2 ; 3.1");
					//68: +2 cap rate
					//2: x3.1 damage
			}

			int BossWeapon=SpawnWeapon(iClient, weapon, config.GetNum("index"), 101, 5, attributes);
			if(!config.GetNum("show", 0))
			{
				SetEntProp(BossWeapon, Prop_Send, "m_iWorldModelIndex", -1);
				SetEntPropFloat(BossWeapon, Prop_Send, "m_flModelScale", 0.0001);
			}
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", BossWeapon);
		}
		else
		{
			break;
		}
	}
}
