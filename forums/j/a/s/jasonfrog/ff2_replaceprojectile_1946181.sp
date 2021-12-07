#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new bool:g_Enabled = false;
new Float:g_ProjectileScale = 1.0;
new String:g_ProjectileModel[PLATFORM_MAX_PATH];
new String:g_Projectile[PLATFORM_MAX_PATH];
static const Float:nullVec[] = {0.0,0.0,0.0};

public Plugin:myinfo = {
	name = "Freak Fortress 2: Replace Projectile",
	description = "Replaces projectiles",
	author = "frog, friagram",
	version = "1.0.2"
};

public OnMapStart()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (g_Enabled)
	{
		if (strcmp(classname, g_Projectile) == 0) 
		{
			SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawned);
		}
	}
}

public ProjectileSpawned(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (owner > 0 && owner <= MaxClients)
	{
		if (!IsClientInGame(owner))
		{
			return;
		}
		if (FF2_GetBossIndex(owner) > -1)
		{
			CreateTimer(0.0, Timer_ProjectileModel, EntIndexToEntRef(entity));
		}
	}
}

public Action:Timer_ProjectileModel(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE)
	{
			SetEntityModel(entity, g_ProjectileModel);
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_ProjectileScale);
			SetEntPropVector(entity, Prop_Send, "m_vecMins", nullVec);
			SetEntPropVector(entity, Prop_Send, "m_vecMaxs", nullVec);
	}
} 

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Enabled = false;
	if (FF2_IsFF2Enabled())
	{
		new Boss = GetClientOfUserId(FF2_GetBossUserId(0));
		if (Boss>0)
		{
			if (FF2_HasAbility(0, this_plugin_name, "replace_projectile"))
			{
				FF2_GetAbilityArgumentString(0, this_plugin_name, "replace_projectile", 1, g_Projectile, PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "replace_projectile", 2, g_ProjectileModel, PLATFORM_MAX_PATH);
				g_ProjectileScale = FF2_GetAbilityArgumentFloat(0, this_plugin_name, "replace_projectile", 3);
				if (g_ProjectileScale <= 0)
				{
					g_ProjectileScale = 1.0;
				}
				PrecacheModel(g_ProjectileModel);
				g_Enabled = true;
			}
		}
	}
}

// not used but required.
public OnPluginStart2(){}
public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], action){}