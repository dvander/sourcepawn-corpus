#include <sourcemod>
#include <sdktools>

new Handle:sm_reverseff_enable = INVALID_HANDLE;
new Handle:sm_reverseff_fire = INVALID_HANDLE;
new Handle:sm_reverseff_bomb = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Reciprocal Friendly Fire",
	author = "Bugzee, with modifications by Crimson_Fox and Mystik Spiral",
	description = "Reverses Friendly Fire",
	version = "0.1.1.2",
	url = "http://www.sourcemod.net/"
};

// ****************************************************************************************************
public OnPluginStart()
{
	sm_reverseff_enable = CreateConVar("sm_reverseff_enable", "1", "Enable reverse friendy fire");
	sm_reverseff_fire = CreateConVar("sm_reverseff_fire", "0", "Reverse fire-type damage");
	sm_reverseff_bomb = CreateConVar("sm_reverseff_bomb", "0", "Reverse bomb-type damage");
	AutoExecConfig(true, "sm_reverseff");

	HookEvent("player_hurt", Eventx_player_hurt);
}

// ****************************************************************************************************
public Action:Eventx_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(sm_reverseff_enable)) // Turned off in config
	{
		return Plugin_Continue;
	}

	new VictimId = GetClientOfUserId(GetEventInt(event, "userid"));
	new AttackerId = GetEventInt(event, "attackerentid");
	new VictimDmg = GetEventInt(event, "dmg_health");
	//new VictimHealth = GetEventInt(event, "health");

	new String:WeaponUsed[32];
	GetEventString(event, "weapon", WeaponUsed, 32);

	if( (!IsValidEntity(VictimId)) || (!IsValidEntity(AttackerId)) ) { return Plugin_Continue; }
	if( (strlen(WeaponUsed) <= 0) || (AttackerId == VictimId) || (GetClientTeam(VictimId) != GetClientTeam(AttackerId)) )
	{ return Plugin_Continue; }

	//PrintToServer("Weapon: %s",WeaponUsed);

	// Is fire-type damage treated normally?
	if( StrEqual(WeaponUsed, "inferno", false) ) // Damage is fire-type
	{
		if( !GetConVarBool(sm_reverseff_fire) ) // Fire damage is normal
		{
			return Plugin_Continue;
		}
	}

	// Is bomb damage treated normally?
	if( (StrContains(WeaponUsed, "pipe_bomb", false) > -1) || (StrContains(WeaponUsed, "grenade", false) > -1) || (StrContains(WeaponUsed, "blast", false) > -1) )
	{
		if( !GetConVarBool(sm_reverseff_bomb) ) // Bomb damage is normal
		{
			return Plugin_Continue;
		}
	}

	// Heal the victim
	if( IsPlayerAlive(VictimId) && IsClientInGame(VictimId) )
	{
		new VictimHealth = GetClientHealth(VictimId);
		new VictimTempHealth = GetTempHealth(VictimId);

		if( VictimTempHealth > 0 )
		{
			SetEntityHealth(VictimId, (VictimHealth + VictimDmg));
			SetTempHealth(VictimId, (VictimTempHealth + 1))
		}
		else
		{
			SetEntityHealth(VictimId, (VictimHealth + VictimDmg));
			SetTempHealth(VictimId, 0)
		}
	}

	// Punish the attacker
	if( IsPlayerAlive(AttackerId) && IsClientInGame(AttackerId) )
	{
		new AttackerHealth = GetClientHealth(AttackerId);
		new AttackerTempHealth = GetTempHealth(AttackerId);

		if( AttackerTempHealth > 0 )
		{
			if ((AttackerTempHealth - VictimDmg) > 0) SetTempHealth(AttackerId, (AttackerTempHealth - VictimDmg ));
			else SetTempHealth(AttackerId, 0)
		}
		else if (AttackerHealth > 0)
		{
			if ((AttackerHealth - VictimDmg) > 0) SetEntityHealth(AttackerId, (AttackerHealth - VictimDmg));
			else IncapPlayer(AttackerId)
		}
	}

	return Plugin_Continue;
}

GetTempHealth(client)
{
	new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
	new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	new Float:time = (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime"));
	new Float:TempHealth = buffer - (time * decay)
	if (TempHealth < 0) return 0;
	else return RoundToFloor(TempHealth);
}

SetTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	new Float:TempHealthFloat = hp * 1.0 //prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealthFloat);
}
IncapPlayer(target)
{
	new iDmgEntity = CreateEntityByName("point_hurt");
	SetEntityHealth(target, 1);
	DispatchKeyValue(target, "targetname", "bm_target");
	DispatchKeyValue(iDmgEntity, "DamageTarget", "bm_target");
	DispatchKeyValue(iDmgEntity, "Damage", "100");
	DispatchKeyValue(iDmgEntity, "DamageType", "0");
	DispatchSpawn(iDmgEntity);
	AcceptEntityInput(iDmgEntity, "Hurt", target);
	DispatchKeyValue(target, "targetname", "bm_targetoff");
	RemoveEdict(iDmgEntity);
}