/*
 * Hidden:SourceMod - Physics Vs ...
 *
 * Description:
 *  Allows the Physics Vs mode where IRIS are restricted to a certain weapon or weapons and hidden can only use phyics props.
 *  The knife remains for use on props etc but does no damage.
 *
 * Assoicated Cvars:
 *  hsm_pv_mode [0~2]           : Physics Vs mode. 0: Disabled, 1: Enabled, 2: Automatic. Default: 0.
 *  hsm_pv_amax [2~9]           : Maximum IRIS players for automatic mode. Default: 1.
 *  hsm_pv_primaries [weapon]   : The Primary weapon number. 0: Fn2000, 1: P90, 2: Shotgun, 3: Fn303, 4: None. 5: Any. Default: 4.
 *  hsm_pv_secondaries [weapon] : The secondary weapon number. 0; FiveseveN, 1: FNP9, 2: None, 3: Any. Default: 3.
 *  hsm_pv_regen [0~1]          : Fraction of damage to restore to hidden as health. 0: None. 1: 100%. Default 0.25.
 *
 * Assocated Commands:
 *  hsm_pv [options] : Shows or adjusts Physics vs mode.
 *                     [m(ode) #|a(utomax) #|p(rimary) #|s(econdary) #]
 *
 * Changelog:
 *  V1.0.0
 *   Initial Release.
 */

#define PLUGIN_VERSION		"1.0.0"
#define TEAM_IRIS 2
#define TEAM_HIDDEN 3

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:cvarMode		= INVALID_HANDLE;
new Handle:cvarAMax		= INVALID_HANDLE;
new Handle:cvarPrime	= INVALID_HANDLE;
new Handle:cvarSecond	= INVALID_HANDLE;
new Handle:cvarRegen	= INVALID_HANDLE;
new Handle:cvarPigShove = INVALID_HANDLE;

new String:g_sModes[][] = {
	"Off",
	"On",
	"Automatic"
};

new String:g_sPrimes[][] = {
	"FN2000",
	"P90",
	"Shotgun",
	"Fn303",
	"None",
	"Any"
};

new String:g_sPrimes_full[][] = {
	"weapon_fn2000",
	"weapon_p90",
	"weapon_shotgun",
	"weapon_Fn303"
};

new String:g_sSecons[][] = {
	"FiveseveN",
	"FNP9",
	"None",
	"Any"
};

new String:g_sSecons_full[][] = {
	"weapon_pistol",
	"weapon_pistol2"
};

new g_iPrimeAmmo[] = {
	2,
	2,
	24,
	4
}; // The amount of ammo to restore to clients for each weapon. These are not the default falues

new g_iSecondAmmo[] = {
	3,
	3
}; // The amount of ammo to restore to clients for each weapon. These are not the default falues

new g_iHidden			= -1;
new g_osPrimeAmmo[4]	= { -1, ... };
new g_osSecondAmmo[2]	= { -1, ... };
new bool:g_bActive		= false;
new bool:g_bPigShove	= false;

public Plugin:myinfo =
{
	name		= "H:SM - Physics Vs ...",
	author		= "Paegus",
	description	= "Allows the Physics Vs ... mode",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_pv_version",
		PLUGIN_VERSION,
		"H:SM - Physics vs version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarMode = CreateConVar(
		"hsm_pv_mode",
		"0",
		"Physics Vs mode. 0: Disabled, 1: Enabled, 2: Automatic.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0,
		true, 2.0
	);

	cvarAMax = CreateConVar(
		"hsm_pv_amax",
		"1",
		"Maximum IRIS players for automatic mode.",
		FCVAR_PLUGIN,
		true, 2.0,
		true, 9.0
	);

	cvarPrime = CreateConVar(
		"hsm_pv_primaries",
		"4",
		"The Primary weapon number. 0: Fn2000, 1: P90, 2: Shotgun, 3: Fn303, 4: None. 5: Any.",
		FCVAR_PLUGIN,
		true, 0.0,
		true, 5.0
	);

	cvarSecond = CreateConVar(
		"hsm_pv_secondaries",
		"3",
		"The secondary weapon number. 0; FiveseveN, 1: FNP9, 2: None, 3: Any.",
		FCVAR_PLUGIN,
		true, 0.0,
		true, 3.0
	);

	cvarRegen = CreateConVar(
		"hsm_pv_regen",
		"0.25",
		"Fraction of damage to restore to hidden as health. 0: None. 1: 100%.",
		FCVAR_PLUGIN,
		true, 0.0,
		true, 1.0
	);

	cvarPigShove = FindConVar("hsm_pigstick");
	if (cvarPigShove != INVALID_HANDLE)
		if (GetConVarBool(cvarPigShove))
			g_bPigShove = true;


	RegAdminCmd(
		"hsm_pv",
		cmd_PV,
		ADMFLAG_GENERIC,
		"Shows or adjusts Physics vs mode.",
		_,
		FCVAR_PLUGIN
	);

	if (GetConVarInt(cvarMode) > 0) // Is Physics vs ... enabled?
	{
		g_bActive = true;
		HookEvent("game_round_start", event_RoundStart);
		HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);
	}

	HookConVarChange(cvarMode, convar_Mode);

	new osAmmo			= FindSendPropOffs("CSDKPlayer","m_iAmmo");		// base Ammo offset
	g_osPrimeAmmo[0]	= osAmmo + 4 * 3;								// FN2000  @ m_iAmmo.003
	g_osPrimeAmmo[1]	= osAmmo + 4 * 2;								// P90     @ m_iAmmo.002
	g_osPrimeAmmo[2]	= osAmmo + 4 * 6;								// Shotgun @ m_iAmmo.006
	g_osPrimeAmmo[3]	= osAmmo + 4 * 7;								// FN303   @ m_iAmmo.007
	g_osSecondAmmo[0]	= osAmmo + 4 * 4;								// FN57    @ m_iAmmo.004
	g_osSecondAmmo[1]	= osAmmo + 4 * 5;								// FN-P9   @ m_iAmmo.005

	// Late loads
	SetHidden();
	CheckLoadout();
}

public Action:cmd_PV(iClient, argc)
{
	if (argc < 1) // No arguments, display settings only
	{
		Status(iClient);
		return Plugin_Handled;
	}

	new bool:bUsage = false;
	new iArgCount = 0;
	new iArg;
	new String:sArg[256];

	while (iArgCount++ < argc)
	{
		if (!bUsage) // Usage has not been called...
		{
			GetCmdArg(iArgCount, sArg, sizeof(sArg)); // Get the next option

			switch (sArg[0])
			{
				case 77, 109: // M(ode) or m(ode)
				{
					if (iArgCount++ < argc) // A parameter exists
					{
						GetCmdArg(iArgCount, sArg, sizeof(sArg)); // Get the parameter
						iArg = StringToInt(sArg);
						if (0 <= iArg <= 2) // Within tolerance
						{
							ReplyToCommand(
								iClient,
								"[PhysV] hsm_pv_mode set to %s",
								g_sModes[iArg]
							);
							ServerCommand("hsm_pv_mode %i", iArg);
						}
						else // outwith tolerance
						{
							bUsage = true;
						}
					}
					else // no paramter exists
					{
						bUsage = true;
					}
				}
				case 65, 97: // A(utomax) or a(utomat)
				{
					if (iArgCount++ < argc) // A parameter exists
					{
						GetCmdArg(iArgCount, sArg, sizeof(sArg)); // Get the parameter
						iArg = StringToInt(sArg);
						if (0 <= iArg <= 2) // Within tolerance
						{
							ReplyToCommand(
								iClient,
								"[PhysV] hsm_pv_mode set to %i",
								iArg
							);
							ServerCommand("hsm_pv_amax %i", iArg);
						}
						else // outwith tolerance
						{
							bUsage = true;
						}
					}
					else // no paramter exists
					{
						bUsage = true;
					}
				}
				case 80, 112: // P(rimary) or p(rimary)
				{
					if (iArgCount++ < argc) // A parameter exists
					{
						GetCmdArg(iArgCount, sArg, sizeof(sArg)); // Get the parameter
						iArg = StringToInt(sArg);

						if (0 <= iArg <= 5) // Within tolerance
						{
							ReplyToCommand(
								iClient,
								"[PhysV] hsm_pv_primaries set to %s",
								g_sPrimes[iArg]
							);
							ServerCommand("hsm_pv_primaries %i", iArg);
						}
						else // outwith tolerance
						{
							bUsage = true;
						}
					}
					else // no paramter exists
					{
						bUsage = true;
					}
				}
				case 83, 115: // S(econdary) or s(econdary)
				{
					if (iArgCount++ < argc) // A parameter exists
					{
						GetCmdArg(iArgCount, sArg, sizeof(sArg)); // Get the parameter
						iArg = StringToInt(sArg);
						if (0 <= iArg <= 3) // Within tolerance
						{
							new iPrime = GetConVarInt(cvarPrime);
							if (iArg == 2 && iPrime == 4) // Primary is none.
							{
								ReplyToCommand(
									iClient,
									"[PhysV] hsm_pv_primaries is %s, hsm_pv_secondaries cannot be %s as well. Setting to %s.",
									g_sPrimes[iPrime],
									g_sSecons[iArg],
									g_sSecons[3]
								);
								iArg = 3;
							}
							else //
							{
								ReplyToCommand(
									iClient,
									"[PhysV] hsm_pv_secondaries set to %s",
									g_sSecons[iArg]
								);
							}
							ServerCommand("hsm_pv_secondaries %i", iArg);
						}
						else // outwith tolerance
						{
							bUsage = true;
						}
					}
					else // no paramter exists
					{
						bUsage = true;
					}
				}
				default: // None of the above
				{
					bUsage = true;
				}
			}
		}
		// else usage has been called so skip it.
	}

	if (bUsage) // Usage has been called
	{
		Usage(iClient);
	}

	CheckLoadout();

	return Plugin_Handled;
}

Status(iClient)
{
	if (iClient)
	{
		PrintToConsole(
			iClient,
			"[PhysV] Status:\nMode         : %s\nAutomax      : At most %i IRIS to automatic mode.\nPrimary      : %s.\nSecondary    : %s.\nRegeneration : 1/%.2f of damage done.\n",
			g_sModes[GetConVarInt(cvarMode)],
			GetConVarInt(cvarAMax),
			g_sPrimes[GetConVarInt(cvarPrime)],
			g_sSecons[GetConVarInt(cvarSecond)],
			1.0/GetConVarFloat(cvarRegen)
		);
	}
	else // Console
	{
		LogToGame(
			"[PhysV] Status:\nMode         : %s\nAutomax      : At most %i IRIS to automatic mode.\nPrimary      : %s.\nSecondary    : %s.\nRegeneration : 1/%.2f of damage done.\n",
			g_sModes[GetConVarInt(cvarMode)],
			GetConVarInt(cvarAMax),
			g_sPrimes[GetConVarInt(cvarPrime)],
			g_sSecons[GetConVarInt(cvarSecond)],
			1.0/GetConVarFloat(cvarRegen)
		);
	}
}

Usage(iClient)
{
	if (iClient)
	{
		PrintToConsole(
			iClient,
			"[PhysV] Usage: hsm_pv [options]\n(m)odes #      : 0: %s, 1: %s, 2: %s.\n                Automatic mode will enable or disable depending on the number of playes.\n(a)utomax #   : Number of players for automatic mode.\n(p)rimary #   : Primary weapon.\n                0: %s, 1: %s, 2: %s, 3: %s, 4: %s, 5: %s.\n(s)econdary # : Secondary weapon.\n                0: %s, 1: %s, 2: %s, 3: %s.\n",
			g_sModes[0], g_sModes[1], g_sModes[2],
			g_sPrimes[0], g_sPrimes[1], g_sPrimes[2], g_sPrimes[3], g_sPrimes[4], g_sPrimes[5],
			g_sSecons[0], g_sSecons[1], g_sSecons[2], g_sSecons[3]
		);
	}
	else // Console
	{
		LogToGame(
			"[PhysV] Usage: hsm_pv [options]\n(m)ode #      : 0: %s, 1: %s, 2: %s.\n(a)utomax #   : Number of players for automatic mode.\n(p)rimary #   : 0: %s, 1: %s, 2: %s, 3: %s, 4: %s, 5: %s.\n(s)econdary # : 0: %s, 1: %s, 2: %s, 3: %s.\n",
			g_sModes[0], g_sModes[1], g_sModes[2],
			g_sPrimes[0], g_sPrimes[1], g_sPrimes[2], g_sPrimes[3], g_sPrimes[4], g_sPrimes[5],
			g_sSecons[0], g_sSecons[1], g_sSecons[2], g_sSecons[3]
		);
	}
}

public convar_Mode(Handle:convar, const String:oldVal[], const String:newVal[])
{

	if (newVal[0] == oldVal[0]) // Does it even call this function if the value doesn't change?
		return;

	g_bActive = false;
	if (StringToInt(newVal) == 0) // Turn it off
	{
		UnhookEvent("game_round_start", event_RoundStart);
		UnhookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);

		if (cvarPigShove != INVALID_HANDLE && !g_bPigShove) // PigShove plugin found && it was off
			SetConVarBool(cvarPigShove, false);

		ServerCommand("hdn_restartround"); // Restart the round
	}
	else // Turn it on
	{
		HookEvent("game_round_start", event_RoundStart);
		HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);

		if (cvarPigShove != INVALID_HANDLE && !g_bPigShove) // PigShove plugin found && it was off
			SetConVarBool(cvarPigShove, true);

		ServerCommand("hdn_restartround"); // Retart the round
	}
}

// Check the player's loadout, stripping and restoring as required
public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvarMode) == 2 && GetTeamClientCount(TEAM_IRIS) > GetConVarInt(cvarAMax)) // Automatic Mode, and there
	{
		PrintToChatAll(
			"[PhysV] Physics Vs is in Automatic mode but there are too many players."
		);

		g_bActive = false;
		return;
	}

	PrintToChatAll(
		"[PhysV] Physics Vs is in Automatic mode."
	);

	SetHidden();
	CheckLoadout();

	new iPrimary = GetConVarInt(cvarPrime);
	new iSecondary = GetConVarInt(cvarSecond);
	new iWeapon;

	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			new iTeam = GetClientTeam(iClient);
			if (iTeam == TEAM_IRIS) // they're iris
			{
				if (iPrimary == 4) // No Primary allows, skip secondary extraction.
				{
					iWeapon = GetPlayerWeaponSlot(iClient,0);
					RemovePlayerItem(iClient, iWeapon);
					RemoveEdict(iWeapon);

					ClientCommand(iClient, "slot2");
					SetEntProp(iClient, Prop_Send, "m_iNewClass", 1);
				}
				else if (iPrimary < 4) // A Specific primary is required.
				{
					if (GetEntProp(iClient, Prop_Send, "m_iPrimary") != iPrimary) // Client has a different primary weapon
					{
						iWeapon = GetPlayerWeaponSlot(iClient,0);
						RemovePlayerItem(iClient, iWeapon);
						RemoveEdict(iWeapon);

						SetEntProp(iClient, Prop_Send, "m_iPrimary", iPrimary);
						GivePlayerItem(iClient, g_sPrimes_full[iPrimary]);
						SetEntData(iClient, g_osPrimeAmmo[iPrimary], g_iPrimeAmmo[iPrimary], 4, true);
						ClientCommand(iClient, "slot1");
					}

					SetEntProp(iClient, Prop_Send, "m_iNewClass", 1);

				}

				if (iPrimary != 4 && iSecondary == 2) // No secondary allowed
				{
					iWeapon = GetPlayerWeaponSlot(iClient,1);
					RemovePlayerItem(iClient, iWeapon);
					RemoveEdict(iWeapon);
				}
				else if (iSecondary < 2) // Specific weapon
				{
					if (GetEntProp(iClient, Prop_Send, "m_iSecondary") != iSecondary) // Client has a different secondary weapon
					{
						iWeapon = GetPlayerWeaponSlot(iClient,1);
						RemovePlayerItem(iClient, iWeapon);
						RemoveEdict(iWeapon);

						SetEntProp(iClient, Prop_Send, "m_iSecondary", iSecondary);
						GivePlayerItem(iClient, g_sSecons_full[iSecondary]);
						SetEntData(iClient, g_osSecondAmmo[iSecondary], g_iSecondAmmo[iSecondary], 4, true);
					}
				}
			}
			else if (iTeam == TEAM_HIDDEN)
			{
				// Remove Grenades
				iWeapon = GetPlayerWeaponSlot(iClient,1);
				RemovePlayerItem(iClient, iWeapon);
				RemoveEdict(iWeapon);

				// Remove Knife
				//iWeapon = GetPlayerWeaponSlot(iClient,0);
				//RemovePlayerItem(iClient, iWeapon);
				//RemoveEdict(iWeapon);
			}
		}
	}
}

// Check for hidden doing damage and restore that much hp to him
public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bActive) // Not Active
		return;

	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (iAttacker != g_iHidden || iAttacker == iVictim) // Wasn't the hidden or was self damage so we're done here.
		return;

	new Float:fDamage = GetEventFloat(event, "damage");

	if (fDamage == 925.000000 || fDamage == 37.000000) // They attacked with the knife
	{
		SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), GetClientHealth(iVictim) + RoundToNearest(fDamage), 4, true);
		PrintToChat(iAttacker, "[PhysV] Physics Vs mode is Active. You cannot attack with the knife.");
		PrintToConsole(iAttacker, "[PhysV] Physics Vs mode is Active. You cannot attack with the knife.");
		PrintCenterText(iAttacker, "   [PhysV]\nCannot Attack\n   w/Knife");
		SetEventFloat(event, "damage", 0.0);
		return;
	}

	new String:sAttackerName[32];
	GetClientName(iAttacker, sAttackerName, sizeof(sAttackerName));

	new String:sVictimName[32];
	GetClientName(iVictim, sVictimName, sizeof(sVictimName));

	PrintToChatAll(
		"[PhysV] %s hit %s for %i",
		sAttackerName,
		sVictimName,
		RoundToNearest(fDamage)
	);

	new iHealth = GetClientHealth(iAttacker);
	if (iHealth == 100) // Hidden has full health so we're done here.
		return;

	iHealth += RoundToNearest(fDamage * GetConVarFloat(cvarRegen));

	if (iHealth > 100) // Too much health, cap at 100
		iHealth = 100;

	SetEntProp(iAttacker, Prop_Send, "m_iHealth", iHealth);
}

// Check player's loadouts for at least 1 weapon
CheckLoadout()
{
	if(GetConVarInt(cvarPrime) == 4) // no primaries allows
	{
		if(GetConVarInt(cvarSecond) == 2) // no secondaries allows
		{
			SetConVarInt(cvarSecond, 3); // Set pistols to Any
		}
		// else a secondary is allows
	}
	// else a primary is allowed

}

stock SetHidden()
{
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
		if (IsClientInGame(iClient)) // Connected and in-game.
			if (IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3) // Alive & Hidden
				g_iHidden = iClient;
}
