/*
 * Hidden:SourceMod - Beta 5 Physics
 *
 * Description:
 *  Moderates high damage physics hits in Hidden:Source.
 *  100 & 500 damage physics hits are reduced to 75.
 *  If the victim's health was less than 75 then they receive full damage allowing for gib-hits.
 *
 *  DO NOT USE IN CONJUNCTION WITH Hidden:SourceMod - Red-Aura Physics plugin
 *
 * Associated Cvars:
 *  hsm_b5physics_shaker [0/1/2/3] : Impact shaker mode. 0: Off, 1: On for target only, 2: Everyone scaled to range, 3: On for EVERYONE, EVERYWHERE in the universer! Default 2.
 *  hsm_b5physics_range [range]    : Impact shaker range scaler if hsm_b5phys_shaker is 2. Default: 2000
 *
 * Changelog:
 *  v1.1.0
 *   Added optional screen shake on high damage hits.
 *  v1.0.2
 *   Added bounce detection to curb rebounding damage causing instant kills
 *  v1.0.1
 *   Altered the way the damage is handled due to bug from log fix
 *  v1.0.0
 *   Initial Release
 *
 */

#define PLUGIN_VERSION		"1.1.0"
#define TEAM_IRIS 2
#define TEAM_HIDDEN 3
#define MAX_PHYS_HURT 75

#include <sourcemod>

#pragma semicolon 1

new bool:g_bBounceBuffer = false;
new Handle:cvarMode  = INVALID_HANDLE;
new Handle:cvarRange = INVALID_HANDLE;

public Plugin:myinfo =
{
	name		= "H:SM - B5 Physics",
	author		= "Paegus",
	description	= "Moderates physics kills to emulate Beta 5 change log",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_b5physics_version",
		PLUGIN_VERSION,
		"H:SM - Beta 5 Physics version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarMode = CreateConVar(
		"hsm_b5physics_shaker",
		"2",
		"Impact shaker mode. 0: Off, 1: On for target only, 2: Everyone scaled to range, 3: On for EVERYONE, EVERYWHERE in the universer!",
		FCVAR_PLUGIN,
		true, 0.0,
		true, 3.0
	);

	cvarRange = CreateConVar(
		"hsm_b5physics_range",
		"2000",
		"Impact shaker range scaler if hsm_b5phys_shaker is 2.",
		FCVAR_PLUGIN,
		true, 1.0,
		false
	);


	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);

}

public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));		// Get Victim
	new iHealth = GetClientHealth(iVictim);
	new iDamage = GetEventInt(event, "damage");							// Get damage done.

	if (g_bBounceBuffer && iHealth <= 0) // Still in bounce buffer time and health is sub-zero
	{
		iHealth += iDamage;
		SetEventInt(event, "damage", 0);	// Alter the damage done
		SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), iHealth, 4, true); // Set their adjusted health
		return;
	}

	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));	// Get attacker.
	if (!iAttacker) // world:0
		return;

	new iAttackerTeam = GetClientTeam(iAttacker); // Get attacker's team.

	if (iAttackerTeam != 3) // Hidden didn't attack
		return;

	if (iDamage < 100 || iDamage > 500) // Not an instant-Physics kill but not a pigstick.
		return;

	// These dont work if i declare them globally? WTH?!!
	new Float:fShakeAmp = 16.0;
	new Float:fShakeFreq = 64.0;
	new Float:fShakeDur = 0.75;

	new iMode = GetConVarInt(cvarMode);

	if (iMode == 3) // Shake EVERYONE!
	{
		env_Shake(0, fShakeAmp, fShakeFreq, fShakeDur);
	}
	else if (iMode == 2) // Shake RANGE
	{
		// Calculate range from impact and scale frequency and duration accordingly
		new Float:vVictimPos[3];
		new Float:vClientPos[3];
		new Float:fRange;
		GetClientAbsOrigin(iVictim, vVictimPos);

		new iMaxClients = GetMaxClients();

		for (new iClient = 1; iClient <= iMaxClients; iClient++)
		{
			if (IsClientInGame(iClient))
			{
				if (IsPlayerAlive(iClient))
				{
					GetClientAbsOrigin(iClient, vClientPos);

					fRange = GetVectorDistance(vClientPos, vVictimPos);

					if (fRange < 1.0) // Presumably the victim in question.
						fRange = 1.0;

					env_Shake(
						iClient,
						GetConVarFloat(cvarRange)/fRange,
						fShakeFreq,
						fShakeDur
					);
				}
				// else // they're dead.
			}
			// else // they're not connected
		}
	}
	else if (iMode == 1) // Shake TARGET
	{
		env_Shake(iVictim, fShakeAmp, fShakeFreq, fShakeDur);
	}

	iHealth += iDamage - MAX_PHYS_HURT;	// Get victim's adjusted health.

	if (iHealth > 0) // They should have survived
	{
		SetEventInt(event, "damage", MAX_PHYS_HURT);	// Alter the damage done
		SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), iHealth, 4, true); // Set their adjusted health
		BounceBuffer();
	}
}

BounceBuffer()
{
	g_bBounceBuffer = true;
	CreateTimer(0.2, tBounceBuffer);
}

public Action:tBounceBuffer(Handle:timer)
{
	g_bBounceBuffer = false;
}

stock env_Shake(target, Float:amp, Float:freq, Float:dur)
{
	if (amp > 100.0) // Cap amplitude
		amp = 100.0;

	if (freq > 100.0) // Cap frequency
		freq = 100.0;

	if (dur > 5.0) // Cap duration
		dur = 5.0;

	//LogToGame("[B5Phys] Shaking %i at %f/%f for %fs", target, amp, freq, dur);

	new Handle:ShakeAnBake = INVALID_HANDLE;

	if (target == 0) // Everyone
		ShakeAnBake=StartMessageAll("Shake");
	else // Specific
		ShakeAnBake=StartMessageOne("Shake", target);

	if(ShakeAnBake!=INVALID_HANDLE)
	{
		BfWriteByte(ShakeAnBake, 0);
		BfWriteFloat(ShakeAnBake, amp);
		BfWriteFloat(ShakeAnBake, freq);
		BfWriteFloat(ShakeAnBake, dur);
		EndMessage();
	}

	//CreateTimer(2.5, tStopShake, target);
}
