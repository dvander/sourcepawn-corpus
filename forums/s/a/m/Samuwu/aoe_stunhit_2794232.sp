/*
	"abilityX"
	{
		"name" "aoe_stunhit"
		"arg0" "11"
		
		// temp melee
		"arg1" "" // attr
		"arg2" "" // classname
		"arg3" "" // index
		
		// return melee
		"arg4" "" // attr
		"arg5" "" // classname
		"arg6" "" // index
		
		"arg7"  "1.5"  // hard-stun duration (can be applied to AoE too)
		"arg8"  "5.0"  // melee duration, ends upon hitting someone
		"arg9" "1.0"   // delay before giving out the melee
		
		// aoe settings
		"arg10" "1" // 1 = enable knockback | 0 = don't
		"arg11" "500" // aoe distance
		"arg12" "750" // aoe knockback force
		"arg13" "1000" // aoe minimum z elevation
		"arg14" "250" // aoe damage (has falloff)
		
		"plugin_name" "aoe_stunhit"
	}
	
	"sound_stunhitaoe"
	{
		"1" "freak_fortress_2/boss/sound.mp3"
	}
*/

#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sourcemod>
#include <sdktools>
#include <tf2items>

#pragma semicolon 1

#define STUNHIT "aoe_stunhit"

bool Enabled[MAXPLAYERS+1] = false;
bool IsAoeEnabled[MAXPLAYERS+1] = false;

Handle ability_running;

char returnattributes[MAXPLAYERS+1][255];
char returnclassname[MAXPLAYERS+1][255];
char newattributes[MAXPLAYERS+1][64];
char newclassname[MAXPLAYERS+1][64];
int index1[MAXPLAYERS+1];
int index2[MAXPLAYERS+1];
int KBToggler[MAXPLAYERS+1];

float duration_stun[MAXPLAYERS+1];
float duration_ability[MAXPLAYERS+1];
float delaybefore[MAXPLAYERS+1];
float AOEDistance[MAXPLAYERS+1];
float AOEKnockbackForce[MAXPLAYERS+1];
float AOEMinZ[MAXPLAYERS+1];
float AOEDamage[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name 		= "FF2: AoE Stunhit",
	author      = "Samuwu + UberMedicFully (original ability)",
	description	= "ff2_tempmelee, but dissappears on hit and can stun + has aoe",
	version 	= "1.1",
}

public void OnPluginStart2() 
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	//HookEvent("arena_win_panel", Event_RoundEnd);
	//HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
	
	HookEvent("player_hurt", OnPlayerHurt);
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
				if (FF2_HasAbility(boss, this_plugin_name, STUNHIT))
				{
					duration_stun[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, STUNHIT, 7, 1.5);
					duration_ability[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, STUNHIT, 8, 7.0);
					delaybefore[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, STUNHIT, 9, 0.0);
					KBToggler[client] = FF2_GetAbilityArgument(boss, this_plugin_name, STUNHIT, 10, 1);
					AOEDistance[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, STUNHIT, 11, 500);
					AOEKnockbackForce[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, STUNHIT, 12, 1000);
					AOEMinZ[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, STUNHIT, 13, 1000);
					AOEDamage[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, STUNHIT, 14, 250);

					if(KBToggler[client] == 1)
					{
						IsAoeEnabled[client] = true;
					}
				}
			}
		}
	}
}

public Action FF2_OnAbility2(index, const char[] plugin_name, const char[] ability_name, status)
{		
	int client = GetClientOfUserId(FF2_GetBossUserId(index));
	
	if(!strcmp(ability_name, STUNHIT))
		rage_stunhit(ability_name, index, client);
}

void rage_stunhit(const char[] ability_name, int index, int client)
{
	FF2_GetAbilityArgumentString(index, this_plugin_name, STUNHIT, 1, newattributes[client], 255);
	FF2_GetAbilityArgumentString(index, this_plugin_name, STUNHIT, 2, newclassname[client], 64);
	index1[client] = FF2_GetAbilityArgument(index, this_plugin_name, STUNHIT, 3);
	FF2_GetAbilityArgumentString(index, this_plugin_name, STUNHIT, 4, returnattributes[client], 255);
	FF2_GetAbilityArgumentString(index, this_plugin_name, STUNHIT, 5, returnclassname[client], 64);
	index2[client] = FF2_GetAbilityArgument(index, this_plugin_name, STUNHIT, 6);
	
	// i did this delay thing to combine it with other aoe-related abilities
	// like explosions or such
	CreateTimer(delaybefore[client], GiveMelee, client);
}

public Action GiveMelee(Handle timer, any index)
{
	int boss = GetClientOfUserId(FF2_GetBossUserId(index));
	
	// remove the old melee
	TF2_RemoveWeaponSlot(index, TFWeaponSlot_Melee);
	
	// HOPEFULLY give them a new melee, both red and blue friendly (yay, bvb stuff)
	SetEntPropEnt(index, Prop_Send, "m_hActiveWeapon", SpawnWeapon(index, newclassname[index], index1[index], 100, 8, newattributes[index]));
	
	// create a returnmelee timer on the handle so we can delete it if we hit someone
	ability_running = CreateTimer(duration_ability[index], returnmelee, index, TIMER_FLAG_NO_MAPCHANGE);
	
	// cool bool learning :)))
	Enabled[index] = true;
}

// this one is for when the ability ends without hitting someone
public Action returnmelee(Handle timer, any index)
{
	int boss = GetClientOfUserId(FF2_GetBossUserId(index));
	Enabled[index] = false;
	TF2_RemoveWeaponSlot(index, TFWeaponSlot_Melee);
	SpawnWeapon(index, returnclassname[index], index2[index], 100, 8, returnattributes[index]);
}

// this one is for when the ability ends by hitting someone
public Action returnmelee2(int index)
{
	int boss = GetClientOfUserId(FF2_GetBossUserId(index));
	Enabled[index] = false;
	TF2_RemoveWeaponSlot(index, TFWeaponSlot_Melee);
	SpawnWeapon(index, returnclassname[index], index2[index], 100, 8, returnattributes[index]);
}

public void AOE_Invoke(int bossClientIdx)
{	
	static float fBossPos[3];
	GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", fBossPos);
	
	// get distanc
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsValidClient(iClient))
		{
			if(IsPlayerAlive(iClient) && GetClientTeam(iClient) != GetClientTeam(bossClientIdx))
			{
				static float ClientPos[3];
				GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", ClientPos);
				float flDist = GetVectorDistance(ClientPos, fBossPos);
				
				if(flDist <= AOEDistance[bossClientIdx])
				{
					// knockback (if enabled)
					if(IsAoeEnabled[bossClientIdx])
					{
						static float angles[3], velocity[3];
						GetVectorAnglesTwoPoints(fBossPos, ClientPos, angles);
						GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
					
						ScaleVector(velocity, AOEKnockbackForce[bossClientIdx] - (AOEKnockbackForce[bossClientIdx] * flDist / AOEDistance[bossClientIdx]));
						if(velocity[2] < AOEMinZ[bossClientIdx])
							velocity[2] = AOEMinZ[bossClientIdx];
						TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, velocity);
					}
					
					// damage
					float damage = AOEDamage[bossClientIdx] - (AOEDamage[bossClientIdx] * flDist / AOEDistance[bossClientIdx]);
					if(damage > 0.0)
						SDKHooks_TakeDamage(iClient, bossClientIdx, bossClientIdx, damage, DMG_GENERIC | DMG_PREVENT_PHYSICS_FORCE, -1);
						
					// aoe stun
					if (duration_stun[bossClientIdx] > 0.0)
						TF2_StunPlayer(iClient, duration_stun[bossClientIdx], 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, bossClientIdx);
				}	
			}
		}
	}
}

// onhit function
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
		if(FF2_HasAbility(boss, this_plugin_name, STUNHIT))
		{		
			if(Enabled[attacker])
			{		
				// WE first off delete the timer (prevents the 1st returnmelee function from activating)
				delete ability_running;
				
				// then we activate the second returnmelee function instantly
				returnmelee2(attacker);
				
				// do the aoe thing
				AOE_Invoke(attacker);
				
				// and optionally, (it should) play a sound from "sound_stunhitaoe" on hit
				FF2_EmitRandomSound(attacker, "sound_stunhitaoe");
				
				// hardstuns the target if arg7 is more than 0
				if (duration_stun[attacker] > 0.0)
					TF2_StunPlayer(client, duration_stun[attacker], 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);							
			}
		}
	}					
}

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

// bunch of stocc
stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
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

// and finally, the spawnweapon stock from ff2_tempmelee
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