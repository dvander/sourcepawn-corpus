#include <sdktools>
#include <sdkhooks>

new Handle:mp_friendlyfire = INVALID_HANDLE;	// srcds cvar mp_friendlyfire
new bool:friendlyfire;	// friendly fire
new enable[MAXPLAYERS+1];	// Remeber who have "curse" on
new ivictim[MAXPLAYERS+1];	// Remember attackers last victim
new iheadshot[MAXPLAYERS+1];	// Did attacker shot victim head last
new C4Ent;			// Bomb planted entity
new String:weapon[32];			// What weapon attacker have

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo =
{
	name		= "Evil Admin - Mirror Damage",
	author		= "<eVa>Dog, Bacardi",
	description	= "Make a player do mirror damage",
	version		= PLUGIN_VERSION,
	url			= "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_evilmirror_version", PLUGIN_VERSION, " Evil Mirror Damage Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_evilmirrordmg", AdmCmdEvilMirrorDmg, ADMFLAG_SLAY);

	mp_friendlyfire = FindConVar("mp_friendlyfire"); // Check srcds cvar mp_friendlyfire
	HookConVarChange(mp_friendlyfire, ConVarChange); // Hook cvar change
	friendlyfire = GetConVarBool(mp_friendlyfire);

	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("bomb_planted", BombPlanted, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", PlayerDisconnect);

	LoadTranslations("common.phrases");
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	friendlyfire = GetConVarBool(mp_friendlyfire);
}

// We need SDKHook everyone who join server
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

public Action:BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	C4Ent = FindEntityByClassname(-1,"planted_c4");	// I want to know C4 index
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	weapon[0] = '\0';	// "Erase" weapon name

	for(new i = 1; i < MAXPLAYERS; i++)
	{
		ivictim[i] = 0;	// "Erase" last victim from all players
		iheadshot[i] = 0;	// "Erase" last headshots from all players
	}
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));	// Get that player who disconnected from event
	enable[attacker] = 0;	// Disable "curse" from disconnected player that another player not get it on
	ivictim[attacker] = 0; // "Erase" last victim from disconnected players
	iheadshot[attacker] = 0;	// "Erase" last headshot from disconnected players
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	// Get that attacker from event (suicide)

	if(enable[attacker] == 1 && attacker != ivictim[attacker] && ivictim[attacker] > 0)	// Attacker have "curse" and last victim is someone else than attacker himself and "world" + server
	{
		SetEventInt(event, "attacker", GetClientUserId(ivictim[attacker]));	// Set victim to attacker
		SetEventString(event, "weapon", weapon);	// Set attacker weapon
		SetEventInt(event, "userid", GetClientUserId(attacker));	// Set attacker to victim

		if(iheadshot[attacker] == 1)	// Last shot was headshot
		{
			SetEventBool(event, "headshot", true);	// Headshot true
		}

		SetEntProp(ivictim[attacker], Prop_Data, "m_iFrags", GetClientFrags(ivictim[attacker])+1);	// Victim get frag
		SetEntProp(attacker, Prop_Data, "m_iFrags", GetClientFrags(attacker)+1);	// Attacker get frag, because attacker make suicide

	}
	return Plugin_Continue;
}

public Action:AdmCmdEvilMirrorDmg(client, args)
{
	if (args < 1)	// Less arguments than 1
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilmirrordmg <#userid|name> <1|0>");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new on = 1;	// Default when not enter value

	if (args > 1)
	{
		decl String:value[2];
		GetCmdArg(2, value, sizeof(value));
		PrintToServer("%s", value);
		if(StringToInt(value) == 0)
		{
			on = 0;
		}
		else
		{
			on = 1;
		}
	}

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);	// Print error when execute target fail
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		PerformEvilMirrorDmg(client, target_list[i], on);	// Release "curse" to target
	}

	if (tn_is_ml)	// Didn't understand..
	{
		ShowActivity2(client, "[SM]", "set mirror damage on %s %i", target_name, on);	// Print all players and admins depend sm_show_activity
	}
	else
	{
		ShowActivity2(client, "[SM]", "set mirror damage on %s %i", target_name, on);	// Print all players and admins depend sm_show_activity
	}

	return Plugin_Handled;
}

PerformEvilMirrorDmg(client, target, value)
{
	enable[target] = value;	// Give "curse" to targets
	LogAction(client, target, "\"%L\" Set Evil: Mirror Damage \"%L\" to %i", client, target, value);	// Keep trace admins action, log in sourcemod logs
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(attacker != 0 && attacker != C4Ent) // Attacker is somebody else than "world" and somebody else than C4 planted
	{
		if(enable[attacker] == 1 && attacker != victim)	// Attacker have "curse" and attacker is not victim
		{
			if(!friendlyfire && GetClientTeam(attacker) != GetClientTeam(victim) || friendlyfire)	// FF off and attacker is not in same team as victim or FF on
			{
				new health = GetClientHealth(attacker);	// Get attacker health
				new dmg = RoundFloat(damage);	// How much damage attacker did

				if(health > 0 && health > dmg)	// Health left and more health than damage
				{
					//GetClientWeapon(attacker, weapon, sizeof(weapon));	// Get attacker weapon
					//ReplaceString(weapon, sizeof(weapon), "weapon_", "", false);	// Erase weapon_ from weapon name
					ivictim[attacker] = 0;	// I want to make sure about last victim, "erase"
					SetEntityHealth(attacker, health - dmg);	// Set health
					damage *= 0.0;	// Prevent damage to victim
					return Plugin_Changed;
				}
				else
				{
					ivictim[attacker] = victim;	// Attacker last victim
					GetEdictClassname(inflictor, weapon, sizeof(weapon))	// Attacking weapon

					if(StrContains(weapon, "_projectile") > 0)	// weapon was hegrenade_projectile, flashbang_projectile, smokegrenade_projectile
					{
						ReplaceString(weapon, sizeof(weapon), "_projectile", "", false);	// Erase _projectile from weapon name
						ForcePlayerSuicide(attacker);	// Force attacker suicide
						damage *= 0.0;	// Prevent damage to victim
						return Plugin_Changed;
					}
					else	// Any other weapon
					{
						GetClientWeapon(attacker, weapon, sizeof(weapon));	// Get attacker weapon
						ReplaceString(weapon, sizeof(weapon), "weapon_", "", false);	// Erase weapon_ from weapon name

						if(hitgroup == 1)
						{
							iheadshot[attacker] = 1;
						}
						else
						{
							iheadshot[attacker] = 0;
						}

						ForcePlayerSuicide(attacker);	// Force attacker suicide
						damage *= 0.0;	// Prevent damage to victim
						return Plugin_Changed;
					}
				}
			}
		}
		else if(enable[attacker] == 1 && attacker == victim)	// Attacker hurt/kill himself
		{
			ivictim[attacker] = 0;	// Make sure when player hurt/kill himself, "reset" last victim
		}
	}

	return Plugin_Continue;
}