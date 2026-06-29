#include <sourcemod>
#include <tf2>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sdkhooks>

#define PLUGIN_AUTHOR "Naydef"
#define PLUGIN_VERSION "0.4"
// All the abilities are passive
#define ABILITY_1 "ff2_falleffectsound"
/*
	Ability 1 prototype in config:
	"ability1"
	{
		"name" "ff2_falleffectsound"
		"arg0" "0"    // Ignored
		"arg1" "1500" // Sound distance
		"arg2" "2"    // Number of sounds which will be emitted randomly. Here we have 2 sounds. Every sound has GetRandomInt(1, sound_number) chance of being selected. 
		"arg3" "sound\freak_fortress_2\some_good_sound.wav"
		"arg4" "sound\freak_fortress_2\some_other_good_sound.wav"
		"plugin_name" "ff2_falleffects"
	}
*/

#define ABILITY_2 "ff2_falleffectshake"
/*
	Ability 2 prototype in config:
	"ability1"
	{
		"name" "ff2_falleffectshake"
		"arg0" "0"    // Ignored
		"arg1" "1500" // Shake distance
		"arg2" "1"    // Is the boss going to be shaked also
		"arg3" "1.0"  // Shake amplitude
		"arg4" "10.0" // Shake duration - in seconds
		"arg5" "4.5"  // frequency
		"plugin_name" "ff2_falleffects"

	}
*/
#define ABILITY_3 "ff2_falleffectdamage"
/*
	Ability 3 prototype in config:
	"ability1"
	{
		"name" "ff2_falleffectdamage"
		"arg0" "0"    // Ignored
		"arg1" "1500" // Damage distance
		"arg2" "40"   // Amount of damage (This will take a formula in future version)
		"plugin_name" "ff2_falleffects"

	}
*/
#define ABILITY_4 "ff2_falleffectparticle" // Not now!


public Plugin:myinfo =
{
	name = "[TF2] Freak Fortress 2: Fall Effects", 
	author = PLUGIN_AUTHOR,
	description = "Some nice effects when bosses fall from height.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(!IsTF2())
	{
		strcopy(error, err_max, "This plugin is only for Team Fortress 2. Remove the plugin!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart2()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

public Action:FF2_OnAbility2(boss,const String:plugin_name[],const String:ability_name[],action) // Not used.
{
	return Plugin_Continue;
}

public Hook_OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if(damagetype & DMG_FALL)
	{
		new bossindex=FF2_GetBossIndex(victim);
		if(bossindex==-1) return;
		if(FF2_HasAbility(bossindex, this_plugin_name, ABILITY_1))
		{
			new String:buffer[PLATFORM_MAX_PATH];
			new numberofsounds=FF2_GetAbilityArgument(bossindex, this_plugin_name, ABILITY_1, 2, -1);
			if(numberofsounds<=0)
			{
				FF2_GetBossSpecial(bossindex, buffer, sizeof(buffer), 0);
				LogError("[FF2 FallEffect Subplugin] Sounds less than 1 | Boss %s", buffer);
				return;
			}
			new random=GetRandomInt(1, numberofsounds);
			FF2_GetAbilityArgumentString(bossindex, this_plugin_name, ABILITY_1, 2+random , buffer, sizeof(buffer));
			if(!buffer[0])
			{
				FF2_GetBossSpecial(bossindex, buffer, sizeof(buffer), 0);
				LogError("[FF2 FallEffect Subplugin] Sound string is NULL! | Boss: %s", buffer);
				return;
			}
			new String:buffer1[PLATFORM_MAX_PATH];
			Format(buffer1, sizeof(buffer1), "sound/%s", buffer);
			if(!FileExists(buffer1))
			{
				FF2_GetBossSpecial(bossindex, buffer, sizeof(buffer), 0);
				LogError("[FF2 FallEffect Subplugin] Sound not found! | Sound: %s | Boss %s", buffer1, buffer);
				return;
			}
			PrecacheSound(buffer);
			new distance=FF2_GetAbilityArgument(bossindex, this_plugin_name, ABILITY_1, 1, -1);
			if(distance<=0)
			{
				EmitSoundToAll(buffer, victim, SNDCHAN_AUTO);
			}
			else
			{
				new Float:PVectorBoss[3];
				new Float:PVector[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", PVectorBoss);
				for(new i=1; i<=MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", PVector);
						if(GetVectorDistance(PVectorBoss, PVector)<=distance)
						{
							EmitSoundToAll(buffer, victim, SNDCHAN_AUTO);
						}
					}
				}
			}
		}
		if(FF2_HasAbility(bossindex, this_plugin_name, ABILITY_2))
		{
			new distance=FF2_GetAbilityArgument(bossindex, this_plugin_name, ABILITY_2, 1, -1);
			new IsBossShaked=FF2_GetAbilityArgument(bossindex, this_plugin_name, ABILITY_2, 2, -1);
			new Float:amplitude=FF2_GetAbilityArgumentFloat(bossindex, this_plugin_name, ABILITY_2, 3, -1.0);
			new Float:duration=FF2_GetAbilityArgumentFloat(bossindex, this_plugin_name, ABILITY_2, 4, -1.0);
			new Float:frequency=FF2_GetAbilityArgumentFloat(bossindex, this_plugin_name, ABILITY_2, 5, -1.0);
			if(distance<=0)
			{
				for(new i=1; i<=MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						if(i==victim)
						{
							if(IsBossShaked)
							{
								ShakeScreen(i, amplitude, duration, frequency);
							}
							else
							{
								continue;
							}
						}
						else
						{
							ShakeScreen(i, amplitude, duration, frequency);
						}
						ShakeScreen(i, amplitude, duration, frequency)
					}
				}
			}
			else
			{
				new Float:PVectorBoss[3];
				new Float:PVector[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", PVectorBoss);
				for(new i=1; i<=MaxClients; i++)
				{
					if(IsValidClient(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", PVector);
						if(GetVectorDistance(PVectorBoss, PVector)<=distance)
						{
							if(i==victim)
							{
								if(IsBossShaked)
								{
									ShakeScreen(i, amplitude, duration, frequency);
								}
								else
								{
									continue;
								}
							}
							else
							{
								ShakeScreen(i, amplitude, duration, frequency);
							}
						}
					}
				}
			}
		}
		if(FF2_HasAbility(bossindex, this_plugin_name, ABILITY_3))
		{
			new Float:PVectorBoss[3];
			new Float:PVector[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", PVectorBoss);
			new Float:damagedist=FF2_GetAbilityArgumentFloat(bossindex, this_plugin_name, ABILITY_3, 1, -1.0);
			new Float:pdamage=FF2_GetAbilityArgumentFloat(bossindex, this_plugin_name, ABILITY_3, 2, -1.0);
			if(pdamage<0.0)
			{
				new String:buffer[64];
				FF2_GetBossSpecial(bossindex, buffer, sizeof(buffer), 0);
				LogMessage("[FF2 FallEffect Subplugin] Negative damage?!?! | Boss: %s", buffer);
			}
			for(new i=1; i<=MaxClients; i++)
			{
				if(IsValidClient(i) && IsPlayerAlive(i) && FF2_GetBossIndex(i)==-1)
				{
					if(damagedist<=0)
					{
						SDKHooks_TakeDamage(i, victim, victim, pdamage, DMG_CLUB);
					}
					else
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", PVector);
						if(GetVectorDistance(PVectorBoss, PVector)<=damagedist)
						{
							SDKHooks_TakeDamage(i, victim, victim, pdamage, DMG_CLUB);
						}
					}
				}
			}
		}
		if(FF2_HasAbility(bossindex, this_plugin_name, ABILITY_4))
		{
			new String:buffer[64];
			FF2_GetBossSpecial(bossindex, buffer, sizeof(buffer), 0);
			LogError("[FF2 FallEffect Subplugin] This version of the plugin does not support \"ff2_falleffectparticle\" ability! | Boss: %s", buffer);
		}
	}
}


stock bool:IsValidClient(client, bool:replaycheck=true)//From Freak Fortress 2
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

public ShakeScreen(client, Float:amplitude, Float:duration, Float:frequency)
{
	new Handle:usermessg=StartMessageOne("Shake", client);
	if(usermessg!=INVALID_HANDLE)
	{
		BfWriteByte(usermessg, 0);
		BfWriteFloat(usermessg, amplitude);
		BfWriteFloat(usermessg, frequency);
		BfWriteFloat(usermessg, duration);
		EndMessage();
	}
}

bool:IsTF2()
{
	return (GetEngineVersion()==Engine_TF2) ?  true : false;
}
