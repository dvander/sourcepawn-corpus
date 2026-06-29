#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_direct>

#define PLUGIN_VERSION "1.0"

static bool:g_bIsBusy[MAXPLAYERS+1] = false;

#define CLASS_STRINGLENGHT 32
static const L4D2_MAX_PLAYERS = 32;

static const ANIM_SEQUENCES_DOWNED_BEGIN = 128;
static const ANIM_SEQUENCES_DOWNED_END = 132;
static const ANIM_SEQUENCE_WALLED = 138;
static const Float:DOWNED_ANIM_MIN_CYCLE = 0.27;
static const Float:DOWNED_ANIM_MAX_CYCLE = 0.53;
static const Float:STOMP_MOVE_PENALTY = 0.25;

static const String:STOMP_SOUND_PATH[] = "player/survivor/hit/rifle_swing_hit_infected9.wav";
static const String:CLASSNAME_INFECTED[] = "infected";
static const String:ENTPROP_ANIM_SEQUENCE[] = "m_nSequence";
static const String:ENTPROP_ANIM_CYCLE[] = "m_flCycle";
static const String:ENT_INPUT_TO_KILL[] = "BecomeRagdoll";
static const String:SPEED_MODIFY_ENTPROP[] = "m_flVelocityModifier";

static Handle:cvarSlowSurvivor = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[L4D2] Mighty Stomp Foot",
	author = "AtomicStryker (Edited by:DeathChaos25",
	description = "Crush Downed Common Infected With Your Foot.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1185478"
};

public OnPluginStart()
{
	decl String:game_name[CLASS_STRINGLENGHT];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrContains(game_name, "left4dead", false) < 0)
	{
		SetFailState("[MSF] Plugin Supports L4D2 Only!");
	}
	
	CreateConVar("msfoot-l4d2_version", PLUGIN_VERSION, "Mighty Stomp Foot Version", FCVAR_REPLICATED|FCVAR_DONTRECORD);
	cvarSlowSurvivor = CreateConVar("msfoot-l4d2_slowdown", "1", "Enable/Disable Slowdown When Stomping", FCVAR_NOTIFY);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_StartTouch, _MF_Touch);
	SDKHook(client, SDKHook_Touch, _MF_Touch);
}

public Action:_MF_Touch(entity, other)
{
	if (other < L4D2_MAX_PLAYERS || !IsValidEdict(other) || !IsValidEntity(other))
	{
		return Plugin_Continue;
	}
	
	decl String:classname[CLASS_STRINGLENGHT];
	GetEdictClassname(other, classname, sizeof(classname));
	if (StrEqual(classname, CLASSNAME_INFECTED))
	{
		if (IsValidEdict(entity) && IsValidEntity(entity))
		{
			new i = GetEntProp(other, Prop_Data, ENTPROP_ANIM_SEQUENCE);
			new Float:f = GetEntPropFloat(other, Prop_Data, ENTPROP_ANIM_CYCLE);
			
			if ((i >= ANIM_SEQUENCES_DOWNED_BEGIN && i <= ANIM_SEQUENCES_DOWNED_END) || i == ANIM_SEQUENCE_WALLED)
			{
				if (f >= DOWNED_ANIM_MIN_CYCLE && f <= DOWNED_ANIM_MAX_CYCLE)
				{
					CreateTimer(0.42, SMASH, other);
					L4D2Direct_DoAnimationEvent(entity, 37);
					g_bIsBusy[entity] = true;
					CreateTimer(1.0, RESETBUSY, entity);
					GotoThirdPerson(entity);
					if (GetConVarBool(cvarSlowSurvivor))
					{
						SetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP, GetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP) - STOMP_MOVE_PENALTY);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

static SmashInfected(any:zombie)
{
	for (new j = 1; j <= MaxClients; j++)
	{
		if (IsClientInGame(j) && !IsFakeClient(j))
		{
			EmitSoundToClient(j, STOMP_SOUND_PATH, zombie, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
	}
	
	AcceptEntityInput(zombie, ENT_INPUT_TO_KILL);
}

public Action:SMASH(Handle:Timer, any:other)
{
	SmashInfected(other);
}

public Action:RESETBUSY(Handle:Timer, any:client)
{
	g_bIsBusy[client] = false;
	GotoFirstPerson(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
	if (IsSurvivor(client) && IsPlayerAlive(client) && g_bIsBusy[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

GotoThirdPerson(client)
{
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
}

GotoFirstPerson(client)
{
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
}

