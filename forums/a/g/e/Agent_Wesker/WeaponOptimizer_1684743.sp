#include <sourcemod>
#include <sdktools>

new Handle:wTimer;
new Handle:cvarEnable = INVALID_HANDLE;
new Handle:cvarTime = INVALID_HANDLE;
new Handle:cvarRemove = INVALID_HANDLE;
new Handle:cvarLimit = INVALID_HANDLE;
new Collision = -1;
new Float:g_time;
new g_WeaponParent;

#define Version "1.0"
public Plugin:myinfo = 
{
	name 		= "[CSS] Weapon Optimizer",
	author 		= "Kingo & Agent Wesker",
	description = "Disables weapon collisions and removes them.",
	version 	= Version,
	url 		= "N/A"
}

public OnPluginStart()
{
	HookEvent("round_start", SetTimerFunc, EventHookMode_Post);
	HookEvent("round_end", KillTimerFunc, EventHookMode_Post);
	Collision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	if(Collision == -1)
	{
		SetFailState("Cannot find m_CollisionGroup Offset.");
	}
	CreateConVar("sm_weaponoptimizer_version", Version, "Current version of Weapon Optimizer", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarTime = CreateConVar("sm_weaponoptimizer_time", "10", "Time delay for optimization", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 5.0, true, 600.0);
	cvarRemove = CreateConVar("sm_weaponoptimizer_remove", "1", "Enable remove all weapons", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	cvarLimit = CreateConVar("sm_weaponoptimizer_limit", "35", "Remove all weapons once the count reaches the limit", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0, true, 500.0);
	cvarEnable = CreateConVar("sm_weaponoptimizer_enable", "1", "Enable or disable Weapon Noblock (0 - disable, 1 - enable)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
} 

public SetTimerFunc(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable) || GetConVarInt(cvarRemove))
	{	
		g_time = GetConVarFloat(cvarTime);
		wTimer = CreateTimer(g_time, CountWeapons, _, TIMER_REPEAT);
	}
}

public KillTimerFunc(Handle:event, const String:name[], bool:dontBroadcast)
{
	KillTimer(wTimer);
}

public Action:CountWeapons(Handle:timer)
{
	new maxent = GetMaxEntities()
	new String:weapon[64];
	new wCount = 0;
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
			{
				wCount++;
				if (GetConVarInt(cvarEnable))
				{	
					SetEntData(i, Collision, 1, 4, true);
				}
			}
		}
	}
	if (wCount >= GetConVarInt(cvarLimit) && GetConVarInt(cvarRemove)){
		Cleanup();
	}
}

public Cleanup()
{
	new maxent = GetMaxEntities()
	new String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
			{
				RemoveEdict(i);
			}
		}
	}
	PrintToChatAll("\x04[Cleanup] Weapons Removed - %i limit reached.", GetConVarInt(cvarLimit));
}