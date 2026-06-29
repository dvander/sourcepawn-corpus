#define PLUGIN_VERSION 		"1.7"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Pipebomb Shove
*	Author	:	SilverShot
*	Descrp	:	Attaches an activated pipebomb to infected when shoved by players holding pipebombs.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=188066

========================================================================================
	Change Log:

1.7 (07-Jul-2015)
	- Added cvar "l4d_pipebomb_reload" to make the "Reload" key attach the pipebomb.

1.6 (21-Jun-2015)
	- Fixed "GetEntPropEnt" error - Thanks to "Danny_l4d" for reporting.

1.5 (07-Oct-2012)
	- Fixed tank attachment and tank related cvars in L4D1 - Thanks to "disawar1" for fixing.
	- Changed the Witch attachment point from her mouth to her eye!

1.4 (03-Jul-2012)
	- Fixed errors by adding some checks - Thanks to "gajo0650" for reporting.

1.3 (30-Jun-2012)
	- Fixed the plugin not working in L4D1.
	- Fixed sticking the pipebomb into common infected which have just died.

1.2 (23-Jun-2012)
	- Fixed the last update breaking the plugin.

1.1 (22-Jun-2012)
	- Added cvars "l4d_pipebomb_shove_damage" and "l4d_pipebomb_shove_distance".

1.0 (21-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY

#define PARTICLE_FUSE		"weapon_pipebomb_fuse"
#define PARTICLE_LIGHT		"weapon_pipebomb_blinking_light"
#define MAX_GRENADES		32

static	Handle:g_hMPGameMode, Handle:g_hCvarAllow, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, bool:g_bCvarAllow,
		Handle:g_hCvarDamage, Handle:g_hCvarDistance, Handle:g_hCvarInfected, Handle:g_hCvarReload,
		Float:g_fCvarDamage, Float:g_fCvarDistance, g_iCvarInfected, g_iCvarReload,
		bool:g_bLeft4Dead2, Handle:sdkActivatePipe, g_iClients[MAX_GRENADES], g_iGrenades[MAX_GRENADES];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Pipebomb Shove",
	author = "SilverShot",
	description = "Attaches an activated pipebomb to infected when shoved by players holding pipebombs.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=188066"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:hGameConf = LoadGameConfigFile("l4d_pipebomb_shove");
	if( hGameConf == INVALID_HANDLE )
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CPipeBombProjectile_Create") == false )
		SetFailState("Could not load the \"CPipeBombProjectile_Create\" gamedata signature.");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkActivatePipe = EndPrepSDKCall();
	if( sdkActivatePipe == INVALID_HANDLE )
		SetFailState("Could not prep the \"CPipeBombProjectile_Create\" function.");

	g_hCvarAllow = CreateConVar(	"l4d_pipebomb_shove_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarDamage = CreateConVar(	"l4d_pipebomb_shove_damage",		"25",			"0=Default. Other values sets the explosion damage.", CVAR_FLAGS );
	g_hCvarDistance = CreateConVar(	"l4d_pipebomb_shove_distance",		"400",			"0=Default. Other value sets the explosion damage range.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d_pipebomb_shove_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d_pipebomb_shove_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarModesTog = CreateConVar(	"l4d_pipebomb_shove_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarInfected = CreateConVar(	"l4d_pipebomb_shove_infected",		"511",			"1=Common, 2=Witch, 4=Smoker, 8=Boomer, 16=Hunter, 32=Spitter, 64=Jockey, 128=Charger, 256=Tank, 511=All.", CVAR_FLAGS );
	g_hCvarReload = CreateConVar(	"l4d_pipebomb_reload",				"0",			"0=Off, 1=Trigger with reload key, 2=Only trigger with reload key.", CVAR_FLAGS );
	CreateConVar(					"l4d_pipebomb_shove_version",		PLUGIN_VERSION,	"Pipebomb Shove plugin version", CVAR_FLAGS|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	AutoExecConfig(true,			"l4d_pipebomb_shove");

	g_hMPGameMode = FindConVar("mp_gamemode");
	if( g_bLeft4Dead2 )
		HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarDamage,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarDistance,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarInfected,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarReload,			ConVarChanged_Cvars);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	g_fCvarDamage = GetConVarFloat(g_hCvarDamage);
	g_fCvarDistance = GetConVarFloat(g_hCvarDistance);
	g_iCvarInfected = GetConVarInt(g_hCvarInfected);
	g_iCvarReload = GetConVarInt(g_hCvarReload);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("entity_shoved", Event_EntityShoved);
		HookEvent("player_shoved", Event_PlayerShoved);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("entity_shoved", Event_EntityShoved);
		UnhookEvent("player_shoved", Event_PlayerShoved);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	if( g_bLeft4Dead2 )
	{
		new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
		if( iCvarModesTog != 0 )
		{
			g_iCurrentMode = 0;

			new entity = CreateEntityByName("info_gamemode");
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			AcceptEntityInput(entity, "PostSpawnActivate");
			AcceptEntityInput(entity, "Kill");

			if( g_iCurrentMode == 0 )
				return false;

			if( !(iCvarModesTog & g_iCurrentMode) )
				return false;
		}
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	if( userid )
	{
		new client = GetClientOfUserId(userid);
		if( client )
		{
			MatchClients(client);
		}
	}
	else
	{
		new common = GetEventInt(event, "entityid");
		if( common )
		{
			MatchClients(common);
		}
	}
}

MatchClients(client)
{
	for( new i = 0; i < MAX_GRENADES; i++ )
	{
		if( g_iClients[i] == client )
		{
			new entity = g_iGrenades[i];
			g_iClients[i] = 0;
			g_iGrenades[i] = 0;

			if( IsValidEntity(entity) )
			{
				SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
				AcceptEntityInput(entity, "ClearParent");
			}
		}
	}
}

public Event_EntityShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iCvarReload != 2 )
	{
		new infected = g_iCvarInfected & (1 << 0);
		new witch = g_iCvarInfected & (1 << 1);
		if( infected || witch )
		{
			new client = GetClientOfUserId(GetEventInt(event, "attacker"));

			new weapon = CheckWeapon(client);
			if( weapon )
			{
				new target = GetEventInt(event, "entityid");

				decl String:sTemp[32];
				GetEntityClassname(target, sTemp, sizeof(sTemp));

				if( (infected && strcmp(sTemp, "infected") == 0 ) )
				{
					if( GetEntProp(target, Prop_Data, "m_iHealth") >= 1 )
					{
						HurtPlayer(target, client, weapon, 0);
						RemovePlayerItem(client, weapon);
						AcceptEntityInput(weapon, "Kill");
					}
				}
				else if( (witch && strcmp(sTemp, "witch") == 0) )
				{
					HurtPlayer(target, client, weapon, -1);
				}
			}
		}
	}
}

public Event_PlayerShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iCvarInfected && g_iCvarReload != 2 )
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		new target = GetClientOfUserId(GetEventInt(event, "userid"));

		if( GetClientTeam(target) == 3 )
		{
			new weapon = CheckWeapon(client);
			if( weapon )
			{
				new class = GetEntProp(target, Prop_Send, "m_zombieClass") + 1;
				if( class == 9 || class == 6 && g_bLeft4Dead2 == false ) class = 8;
				if( g_iCvarInfected & (1 << class) )
				{
					HurtPlayer(target, client, weapon, class -1);
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if( g_bCvarAllow && g_iCvarReload != 0 )
	{
		if( buttons & IN_RELOAD )
		{
			new target = GetClientAimTarget(client, false);
			if( target != -1)
			{
				DoKey(client, target);
			}
		}
	}
}

static Float:fLastUse;
DoKey(client, target)
{
	new Float:fNow = GetEngineTime();
	if( fNow - fLastUse > 0.2 )
	{
		fLastUse = GetEngineTime();

		new weapon = CheckWeapon(client);
		if( weapon )
		{
			if( target > MaxClients )
			{
				new infected = g_iCvarInfected & (1 << 0);
				new witch = g_iCvarInfected & (1 << 1);
				if( infected || witch )
				{
					decl String:sTemp[32];
					GetEntityClassname(target, sTemp, sizeof(sTemp));

					if( (infected && strcmp(sTemp, "infected") == 0 ) )
					{
						if( GetEntProp(target, Prop_Data, "m_iHealth") >= 1 )
						{
							HurtPlayer(target, client, weapon, 0);
							RemovePlayerItem(client, weapon);
							AcceptEntityInput(weapon, "Kill");
						}
					}
					else if( (witch && strcmp(sTemp, "witch") == 0) )
					{
						HurtPlayer(target, client, weapon, -1);
					}
				}
			} else {
				if( GetClientTeam(target) == 3 )
				{
					new class = GetEntProp(target, Prop_Send, "m_zombieClass") + 1;
					if( class == 9 || class == 6 && g_bLeft4Dead2 == false ) class = 8;
					if( g_iCvarInfected & (1 << class) )
					{
						HurtPlayer(target, client, weapon, class -1);
					}
				}
			}
		}
	}
}

CheckWeapon(client)
{
	if( client )
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon > 0 && IsValidEntity(weapon) )
		{
			decl String:sTemp[32];
			GetEntityClassname(weapon, sTemp, sizeof(sTemp));
			if( strcmp(sTemp, "weapon_pipe_bomb") == 0 )
				return weapon;
		}
	}
	return 0;
}

HurtPlayer(target, client, weapon, special)
{
	new index = -1;

	for( new i = 0; i < MAX_GRENADES; i++ )
	{
		if( g_iClients[i] == 0 || g_iGrenades[i] == 0 || EntRefToEntIndex(g_iGrenades[i]) == INVALID_ENT_REFERENCE )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )	return;

	RemovePlayerItem(client, weapon);
	AcceptEntityInput(weapon, "Kill");

	new Float:vAng[3], Float:vPos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", vPos);
	vPos[2] += 40.0;

	new entity = SDKCall(sdkActivatePipe, vPos, vAng, vAng, vAng, client, 2.0);

	g_iClients[index] = target;
	g_iGrenades[index] = EntIndexToEntRef(entity);

	CreateParticle(entity, 0);
	CreateParticle(entity, 1);

	if( g_fCvarDistance )	SetEntPropFloat(entity, Prop_Data, "m_DmgRadius", g_fCvarDistance);
	if( g_fCvarDamage )		SetEntPropFloat(entity, Prop_Data, "m_flDamage", g_fCvarDamage);

	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
	SetEntityMoveType(entity, MOVETYPE_NONE);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);

	if( special == -1 )
		SetVariantString("leye");
	else if( special == 1 )
		SetVariantString("smoker_mouth");
	else if( special == 3 || special == 5  || special == 6)
		SetVariantString(GetRandomInt(0, 1) ? "rhand" : "lhand");
	else
		SetVariantString("mouth");

	AcceptEntityInput(entity, "SetParentAttachment", target);
	TeleportEntity(entity, NULL_VECTOR, Float:{ 90.0, 0.0, 0.0 }, NULL_VECTOR);
}

CreateParticle(target, type)
{
	new entity = CreateEntityByName("info_particle_system");
	if( type == 0 )	DispatchKeyValue(entity, "effect_name", PARTICLE_FUSE);
	else			DispatchKeyValue(entity, "effect_name", PARTICLE_LIGHT);

	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);

	if( type == 0 )	SetVariantString("fuse");
	else			SetVariantString("pipebomb_light");
	AcceptEntityInput(entity, "SetParentAttachment", target);
}