/*
============================
Boss' abilities plugin
"powerlord_abilities"
============================

======
Rages
======
rage_transparency - Turn partly invisible
	0 - slot (def 0, rage)
	1 - Amount of transparency, percent (def 50)
	2 - Seconds to stay transparent, as a Float (def 20.0)
	3 - slot used by decloak, primarily for sounds (def 4)
Conflicts: Anything that adjusts transparency

======
Special Abilities
======
special_ragdoll - Adds the specified attribute to ragdolls for non-boss players.
	0 - Slot, unused (assumed 0)
	1 - Ragdoll mode
		0 - Gib
		1 - Burning
		2 - Electrocuted
		3 - Cloaked (YER)
		4 - Gold Statue, also plays Saxxy turn to gold sound
		5 - Ice Statue, also plays Spy-cicle freezing sound
		6 - Ash
Conflicts: special_dropprop

*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define SOUND_ICE "weapons/icicle_freeze_victim_01.wav"
#define SOUND_GOLD "weapons/saxxy_turntogold_05.wav"

#define DEFAULT_COLOR 255
#define ALPHA_OPAQUE 255

#define VERSION "2.0"

enum {
	Ragdoll_Gib = 0,
	Ragdoll_Burning,
	Ragdoll_Electrocuted,
	Ragdoll_Cloaked,
	Ragdoll_GoldRagdoll,
	Ragdoll_IceRagdoll,
	Ragdoll_BecomeAsh,
};

new Handle:g_TransparencyTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new g_LastInjured[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "Freak Fortress 2: Powerlord Abilities",
	description = "Rage Transparency and Special Ragdolls Freak Fortress Abilities.",
	author = "Powerlord",
	version = VERSION,
};

//Poot your hooks etc. here
public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("player_death", event_player_death);
}

public OnMapStart()
{
	PrecacheSound(SOUND_ICE, true);
	PrecacheSound(SOUND_GOLD, true);
	
	for (new i = 0; i < sizeof(g_LastInjured); i++)
	{
		g_LastInjured[i] = -1;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}
	
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name, "rage_transparency"))
		rage_transparency(ability_name, index);
		
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "tf_ragdoll"))
	{
		SDKHook(entity, SDKHook_Spawn, RagdollSpawn);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public Action:RagdollSpawn(entity)
{
	new player = GetEntProp(entity, Prop_Send, "m_iPlayerIndex");
	if (player >= 1 && player <= MaxClients && g_LastInjured[player] > 0)
	{
		new a_index=FF2_GetBossIndex(g_LastInjured[player]);
		if (a_index!=-1)
		{
			if (FF2_HasAbility(a_index,this_plugin_name,"special_ragdoll"))
			{
				new ragdollType = FF2_GetAbilityArgument(a_index,this_plugin_name, "special_ragdoll", 1, 0);
				
				new String:soundFile[65] = "";

				switch (ragdollType)
				{
					case Ragdoll_Gib:
					{
						SetEntProp(entity, Prop_Send, "m_bGib", 1);
					}
					
					case Ragdoll_Burning:
					{
						SetEntProp(entity, Prop_Send, "m_bBurning", 1);
					}

					case Ragdoll_Electrocuted:
					{
						SetEntProp(entity, Prop_Send, "m_bElectrocuted", 1);
					}

					case Ragdoll_Cloaked:
					{
						SetEntProp(entity, Prop_Send, "m_bCloaked", 1);
					}
					
					case Ragdoll_GoldRagdoll:
					{
						SetEntProp(entity, Prop_Send, "m_bGoldRagdoll", 1);
						strcopy(soundFile, sizeof(soundFile), SOUND_GOLD);
					}
					
					case Ragdoll_IceRagdoll:
					{
						//SetEntProp(entity, Prop_Send, "m_iDamageCustom", CUSTOMKILL_BACKSTAB);
						SetEntProp(entity, Prop_Send, "m_bIceRagdoll", 1);
						strcopy(soundFile, sizeof(soundFile), SOUND_ICE);
					}
					
					case Ragdoll_BecomeAsh:
					{
						SetEntProp(entity, Prop_Send, "m_bBecomeAsh", 1);
					}
					
				}
				
				if (strlen(soundFile) > 0)
				{
					EmitSoundToAll(soundFile, entity, SNDCHAN_BODY);
				}
				
			}
		}
	}
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (victim >= 1 && victim <= MaxClients)
	{
		g_LastInjured[victim] = attacker; // This may set to 0 or -1 if world, which is fine
	}
}

public event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < sizeof(g_LastInjured); i++)
	{
		g_LastInjured[i] = -1;
	}
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new deathflags = GetEventInt(event, "death_flags");
	if (deathflags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;

	new client = GetEventInt(event, "victim_entindex");
	
	if (g_TransparencyTimers[client] != INVALID_HANDLE)
	{
		new Handle:timer = g_TransparencyTimers[client];
		g_TransparencyTimers[client] = INVALID_HANDLE;
		KillTimer(timer);
		
		if (IsValidEntity(client))
		{
			SetClientAlpha(client, ALPHA_OPAQUE);
		}
	}
	
	return Plugin_Continue;
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && g_TransparencyTimers[i] != INVALID_HANDLE)
		{
			new Handle:timer = g_TransparencyTimers[i];
			g_TransparencyTimers[i] = INVALID_HANDLE;
			KillTimer(timer);
			
			if (IsValidEntity(i))
			{
				SetClientAlpha(i, ALPHA_OPAQUE);
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if (g_TransparencyTimers[client] != INVALID_HANDLE)
	{
		new Handle:timer = g_TransparencyTimers[client];
		g_TransparencyTimers[client] = INVALID_HANDLE;
		KillTimer(timer);
	}
}

SetClientAlpha(client, alpha)
{
	if (IsClientConnected(client) && IsValidEntity(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, DEFAULT_COLOR, DEFAULT_COLOR, DEFAULT_COLOR, alpha);
		
		// Make weapons transparent. TF2 has 6 weapon slots (0-5) according to RemoveWeaponSlot
		// Not all classes have all weapon slots
		for (new i = 0; i < 6; i++)
		{
			new entity = GetPlayerWeaponSlot(client, i);
			if (entity > -1 && IsValidEntity(entity))
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, DEFAULT_COLOR, DEFAULT_COLOR, DEFAULT_COLOR, alpha);
			}
		}
		
		// Todo (maybe): Change wearables
		// Keep in mind that this plugin *only* works on bosses, so wearables cloaking shouldn't be necessary
	}
}

rage_transparency(const String:ability_name[], index)
{
	new Float:transparencyAmount = FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 1, 50.0);
	new Float:transparencyDuration = FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 2, 20.0);
	new alphaValue = RoundToNearest(((100 - transparencyAmount) / 100) * ALPHA_OPAQUE);
	new client = GetClientOfUserId(FF2_GetBossUserId(index));

	SetClientAlpha(client, alphaValue);

	decl Handle:data;

	g_TransparencyTimers[client] = CreateDataTimer(transparencyDuration, Timer_UndoTransparency, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, client);
	WritePackString(data, ability_name);
	
}

public Action:Timer_UndoTransparency(Handle:timer, Handle:data)
{
	ResetPack(data);

	new client = ReadPackCell(data);

	// This check shouldn't be necessary, but just in case...
	if (client == 0)
		return Plugin_Continue;
	
	decl String:ability_name[MAX_NAME_LENGTH];
	ReadPackString(data, ability_name, MAX_NAME_LENGTH);
	
	g_TransparencyTimers[client] = INVALID_HANDLE;

	SetClientAlpha(client, ALPHA_OPAQUE);

	new index = FF2_GetBossIndex(client);
	
	if (index > -1)
	{
		decl String:soundFile[PLATFORM_MAX_PATH];
		new slot = FF2_GetAbilityArgument(index, this_plugin_name, "rage_transparency", 3, 4);
		TF2_RemovePlayerDisguise(client);
		if (FF2_RandomSound("sound_ability", soundFile, PLATFORM_MAX_PATH, index, slot))
			EmitSoundToAll(soundFile);
	}

	return Plugin_Continue;
}
