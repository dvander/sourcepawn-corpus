#include <sourcemod>
#include <sdktools>

new Handle:sm_weaponnoblock_enable	 = INVALID_HANDLE;
new Collision = -1;
#define Version "1.0.1"
public Plugin:myinfo = 
{
	name 		= "[CSS] Weapon Noblock",
	author 		= "Kingo",
	description = "Noblock for weapons.",
	version 	= Version,
	url 		= "N/A"
}

public OnPluginStart()
{
	Collision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if(Collision == -1)
	{
		SetFailState("Cannot find m_CollisionGroup Offset.");
	}
	CreateConVar("sm_weaponnoblock_version", Version, "Current version of Weapon Noblock", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_weaponnoblock_enable = CreateConVar("sm_weaponnoblock_enable", "1", "Enable or disable Weapon Noblock (0 - disable, 1 - enable)");
	HookEvent("round_start", EventRoundStart);
} 

public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	new bool:CanRun = GetConVarBool(sm_weaponnoblock_enable);
	if(CanRun)
	{
		SetEntData(weaponIndex, Collision, 1, 4, true);
	}
}

public EventRoundStart(Handle:event, const String:name[], bool:doNotBroadcast) 
{
	new bool:CanRun = GetConVarBool(sm_weaponnoblock_enable);
	new Weapon = -1;
	if(CanRun)
	{
		while((Weapon = FindEntityByClassname(Weapon,"weapon_*")) != -1)
		{
			if(GetEntPropEnt(Weapon,Prop_Send,"m_hOwnerEntity") == -1)
			{
				SetEntData(Weapon, Collision, 1, 4, true);
			}
		}
	}
}