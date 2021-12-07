#include <sourcemod>  
#include <sdkhooks>
#include <morecolors>

#define MIN			512.0
#define PLUGIN_VERSION		"1.4"

//fall off handles
ConVar rl_falloff;
ConVar arrow_falloff;
ConVar pomson_falloff;
ConVar shotgun_falloff;
ConVar minigun_falloff;
ConVar rifle_falloff;
ConVar revolver_falloff;
ConVar gl_falloff;
ConVar pistol_falloff;
ConVar sticky_falloff;
ConVar smg_falloff;
ConVar scatter_falloff;
ConVar sentry_falloff;
ConVar cannon_falloff;
ConVar cleaver_falloff;
ConVar flare_falloff;
ConVar primary_pistol_falloff;
ConVar syringe_falloff;
//ramp up handles
ConVar rl_rampup;
ConVar arrow_rampup;
ConVar pomson_rampup;
ConVar shotgun_rampup;
ConVar minigun_rampup;
ConVar rifle_rampup;
ConVar revolver_rampup;
ConVar gl_rampup;
ConVar pistol_rampup;
ConVar sticky_rampup;
ConVar smg_rampup;
ConVar scatter_rampup;
ConVar sentry_rampup;
ConVar cannon_rampup;
ConVar cleaver_rampup;
ConVar flare_rampup;
ConVar primary_pistol_rampup;
ConVar syringe_rampup;
ConVar timer;

public Plugin myinfo =
{
	name = "Adjust Damage over distances",  
	author = "Assyrian + TAZ",  
	description = "let's you adjust the damage fall off and ramp up of weapons",  
	version = PLUGIN_VERSION,  
	url = "http://steamcommunity.com/groups/acvsh"  
};

public void OnPluginStart()
{
	//Damage Fall Off convars------------------------------------------------------------------------------------------------
	rl_falloff = CreateConVar("sm_rl_damagefalloff_percent", "53", "amount of damage fall off Rocket Launcher will have");
	arrow_falloff = CreateConVar("sm_arrow_damagefalloff_percent", "100", "amount of damage fall off Huntsman will have");
	pomson_falloff = CreateConVar("sm_pomson_damagefalloff_percent", "75", "amount of damage fall off Pomson 6k will have");
	shotgun_falloff = CreateConVar("sm_shotgun_damagefalloff_percent", "50", "amount of damage fall off Shotguns will have");
	minigun_falloff = CreateConVar("sm_minigun_damagefalloff_percent", "50", "amount of damage fall off Miniguns will have");
	rifle_falloff = CreateConVar("sm_rifle_damagefalloff_percent", "100", "amount of damage fall off Sniper Rifles will have");
	revolver_falloff = CreateConVar("sm_revolver_damagefalloff_percent", "50", "amount of damage fall off Revolvers will have");
	gl_falloff = CreateConVar("sm_gl_damagefalloff_percent", "100", "amount of damage fall off Grenade Launchers will have");
	cannon_falloff = CreateConVar("sm_cannon_damagefalloff_percent", "100", "amount of damage fall off Loose Cannon will have");
	pistol_falloff = CreateConVar("sm_pistol_damagefalloff_percent", "50", "amount of damage fall off Pistols will have");
	sticky_falloff = CreateConVar("sm_sticky_damagefalloff_percent", "50", "amount of damage fall off Stickybomb Launchers will have");
	smg_falloff = CreateConVar("sm_smg_damagefalloff_percent", "50", "amount of damage fall off SMGs will have");
	scatter_falloff = CreateConVar("sm_scattergun_damagefalloff_percent", "50", "amount of damage fall off Scatterguns will have");
	sentry_falloff = CreateConVar("sm_sentry_damagefalloff_percent", "100", "amount of damage fall off Sentries will have");
	cleaver_falloff = CreateConVar("sm_cleaver_damagefalloff_percent", "100", "amount of damage fall off Flying Guillotine will have");
	flare_falloff = CreateConVar("sm_flare_damagefalloff_percent", "100", "amount of damage fall off Flareguns will have");
	primary_pistol_falloff = CreateConVar("sm_primpistol_damagefalloff_percent", "50", "amount of damage fall off Shortstop will have");
	syringe_falloff = CreateConVar("sm_syringe_damagefalloff_percent", "50", "amount of damage fall off Syringe Guns will have");
	//Damage Ramp Up convars--------------------------------------------------------------------------------------------------
	rl_rampup = CreateConVar("sm_rl_damagerampup_percent", "125", "amount of damage ramp up Rocket Launcher will have");
	arrow_rampup = CreateConVar("sm_arrow_damagerampup_percent", "100", "amount of damage ramp up Huntsman will have");
	pomson_rampup = CreateConVar("sm_pomson_damagerampup_percent", "125", "amount of damage ramp up Pomson 6k will have");
	shotgun_rampup = CreateConVar("sm_shotgun_damagerampup_percent", "150", "amount of damage ramp up Shotguns will have");
	minigun_rampup = CreateConVar("sm_minigun_damagerampup_percent", "150", "amount of damage ramp up Miniguns will have");
	rifle_rampup = CreateConVar("sm_rifle_damagerampup_percent", "100", "amount of damage ramp up Sniper Rifles will have");
	revolver_rampup = CreateConVar("sm_revolver_damagerampup_percent", "150", "amount of damage ramp up Revolvers will have");
	gl_rampup = CreateConVar("sm_gl_damagerampup_percent", "100", "amount of damage ramp up Grenade Launchers will have");
	cannon_rampup = CreateConVar("sm_cannon_damagerampup_percent", "100", "amount of damage ramp up Loose Cannon will have");
	pistol_rampup = CreateConVar("sm_pistol_damagerampup_percent", "150", "amount of damage ramp up Pistols will have");
	sticky_rampup = CreateConVar("sm_sticky_damagerampup_percent", "115", "amount of damage ramp up Stickybomb Launchers will have");
	smg_rampup = CreateConVar("sm_smg_damagerampup_percent", "150", "amount of damage ramp up SMGs will have");
	scatter_rampup = CreateConVar("sm_scattergun_damagerampup_percent", "175", "amount of damage ramp up Scatterguns will have");
	sentry_rampup = CreateConVar("sm_sentry_damagerampup_percent", "100", "amount of damage ramp up Sentries will have");
	cleaver_rampup = CreateConVar("sm_cleaver_damagerampup_percent", "100", "amount of damage ramp up Flying Guillotine will have");
	flare_rampup = CreateConVar("sm_flare_damagerampup_percent", "100", "amount of damage ramp up Flareguns will have");
	primary_pistol_rampup = CreateConVar("sm_primpistol_damagerampup_percent", "150", "amount of damage ramp up Shortstop will have");
	syringe_rampup = CreateConVar("sm_syringe_damagerampup_percent", "120", "amount of damage ramp up Syringe Guns will have");
	timer = CreateConVar("sm_advert_timer", "45.0", "amount of time the plugin advert will pop up");

	for (int i = 1; i <= MaxClients; i++)
	{
		if ( !IsValidClient(i, false) ) continue;
		OnClientPutInServer(i);
	}

	AutoExecConfig(true, "plugin.adjustable-dmg");
	CreateTimer(timer.FloatValue, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (attacker > 0 && victim != attacker)
	{
		if (damagetype & DMG_CRIT) return Plugin_Continue;

		float vec1[3]; GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", vec1); //Spot of attacker
		float vec2[3]; GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vec2); //Spot of victim
		float dist = GetVectorDistance(vec1, vec2, false); //Calculates the distance between target and attacker

/*-----|Weapon Normal
* Crits | DMG_ACID = 1048576
* Engineer | Sentry 4098 \
* DMG_ACID is always applied to these
* damagetype: 1052802 = backstab
* damagetype: 34603010 = headshot
* * damagetype: 2097152 = headshot

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    decl String:weapon[64];
    GetEdictClassname(inflictor, weapon, sizeof(weapon));
    PrintToConsole(attacker, "weapon = %s, damagetype = %d", weapon, damagetype);
    return Plugin_Continue;
}
*/ //this is a test script to find damage types


/*
formula for sinusoidal damage fall off
y2-y1/x2-x1

y2 = damage at farthest range
y1 = base damage
x2 = farthest distance in units
x1 = starting distance

y-intercept = max ramp up percentage

y=mx+b, x = units in distance with y remainder becoming damage
*/
		char classname[64];
		if ( IsValidEdict(weapon) )	GetEdictClassname( weapon, classname, sizeof(classname) );

		float falloff, rampup;
		if ( StrContains(classname, "rocketlauncher", false) != -1 || StrContains(classname, "tf_weapon_particle_cannon", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (rl_falloff.FloatValue / 53.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (rl_rampup.FloatValue / 125.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_grenadelauncher", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (gl_falloff.FloatValue / 100.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (gl_rampup.FloatValue / 100.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_cannon", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (cannon_falloff.FloatValue / 100.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (cannon_rampup.FloatValue / 100.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_drg_pomson", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (pomson_falloff.FloatValue / 75.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (pomson_rampup.FloatValue / 125.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_shotgun_", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (shotgun_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (shotgun_rampup.FloatValue / 150.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_minigun", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (minigun_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (minigun_rampup.FloatValue / 150.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_compound_bow", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (arrow_falloff.FloatValue / 100.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (arrow_rampup.FloatValue / 100.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_sniperrifle", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (rifle_falloff.FloatValue / 100.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (rifle_rampup.FloatValue / 100.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_revolver", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (revolver_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (revolver_rampup.FloatValue / 150.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_pistol", false) != -1 || StrContains(classname, "tf_weapon_handgun_scout_secondary", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (pistol_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (pistol_rampup.FloatValue / 150.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_pipebomblauncher", false) != -1)
		{
			if (dist >= MIN)
			{
				falloff = (sticky_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (sticky_rampup.FloatValue / 115.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if (StrContains(classname, "tf_weapon_smg", false) != -1)
		{
			if (dist >= MIN)
			{
				falloff = (smg_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (smg_rampup.FloatValue / 150.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_scattergun", false) != -1 || StrContains(classname, "tf_weapon_pep_brawler_blaster", false) != -1 || StrContains(classname, "tf_weapon_soda_popper", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (scatter_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (scatter_rampup.FloatValue / 175.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_cleaver", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (cleaver_falloff.FloatValue / 100.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (cleaver_rampup.FloatValue / 100.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if (StrContains(classname, "tf_weapon_flaregun", false) != -1)
		{
			if (dist >= MIN)
			{
				falloff = (flare_falloff.FloatValue / 100.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (flare_rampup.FloatValue / 100.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if (StrContains(classname, "tf_weapon_handgun_scout_primary", false) != -1)
		{
			if (dist >= MIN)
			{
				falloff = (primary_pistol_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (primary_pistol_rampup.FloatValue / 150.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		if ( StrContains(classname, "tf_weapon_syringegun_medic", false) != -1 )
		{
			if (dist >= MIN)
			{
				falloff = (syringe_falloff.FloatValue / 50.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (syringe_rampup.FloatValue / 120.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
		char sentry[64];
		if ( IsValidEdict(inflictor) )	GetEntityClassname(inflictor, sentry, sizeof(sentry));

		if ( StrContains(sentry, "sentry", false) != -1 ) //sentry damage
		{
			if (dist >= MIN)
			{
				falloff = (sentry_falloff.FloatValue / 100.0);
				damage *= falloff;
				return Plugin_Changed;
			}
			else if (dist < MIN)
			{
				rampup = (sentry_rampup.FloatValue / 100.0);
				damage *= rampup;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Announce(Handle hTimer)
{
	CPrintToChatAll("{cyan}Adjust Distance Damage by: {red}The Assyrian/Nergal");
	return Plugin_Continue;
}

stock bool IsValidClient(int iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients) return false;
	if (!IsClientInGame(iClient)) return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient))) return false;
	return true;
}
