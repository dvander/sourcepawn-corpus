#define PLUGIN_NAME "[L4D2] Mighty Stomp Foot"
#define PLUGIN_AUTHOR "AtomicStryker, Shadowysn (New syntax and common kill method)"
#define PLUGIN_DESC "Crush downed Commons"
#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=1185478"
#define PLUGIN_NAME_SHORT "Mighty Stomp Foot"
#define PLUGIN_NAME_TECH "l4d2_mightystompfoot"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define AUTOEXEC_CFG "l4d2_mightystompfoot"

#define TEST_DEBUG			0
#define TEST_DEBUG_LOG		0

#define CLASS_STRINGLENGTH	32
#define L4D2_MAX_PLAYERS	32

#define ANIM_SEQUENCES_DOWNED_BEGIN		128
#define ANIM_SEQUENCES_DOWNED_END		132
#define ANIM_SEQUENCE_WALLED			138
#define DOWNED_ANIM_MIN_CYCLE			0.27
#define DOWNED_ANIM_MAX_CYCLE			0.53
#define STOMP_MOVE_PENALTY				0.25

#define STOMP_SOUND_PATH		"player/survivor/hit/rifle_swing_hit_infected9.wav"
#define CLASSNAME_INFECTED		"infected"
#define ENTPROP_ANIM_SEQUENCE	"m_nSequence"
#define ENTPROP_ANIM_CYCLE		"m_flCycle"
#define SPEED_MODIFY_ENTPROP	"m_flVelocityModifier"

static Handle cvarSlowSurvivor = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{ return APLRes_Success; }
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = "L4D2 Mighty Stomp Foot",
	author = "AtomicStryker, Shadowysn (New syntax and common kill method)",
	description = "Crush downed Commons",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1185478"
}

public void OnPluginStart()
{
	char temp_str[128];
	Format(temp_str, sizeof(temp_str), "%s version.", PLUGIN_NAME_SHORT);
	char desc_str[1024];
	Format(desc_str, sizeof(desc_str), "%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(desc_str, PLUGIN_VERSION, temp_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(temp_str, sizeof(temp_str), "%s_stompslow", PLUGIN_NAME_TECH);
	cvarSlowSurvivor = CreateConVar(temp_str, "0.0", "Does Stomping slow down Survivors momentarily?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_StartTouch, _MF_Touch);
	SDKHook(client, SDKHook_Touch, 		_MF_Touch);
}

Action _MF_Touch(int entity, int other)
{
	if (other < L4D2_MAX_PLAYERS || !IsValidEntity(other)) return Plugin_Continue;
	
	char classname[CLASS_STRINGLENGTH];
	GetEdictClassname(other, classname, sizeof(classname));
	
	if (StrEqual(classname, CLASSNAME_INFECTED))
	{
		int i = GetEntProp(other, Prop_Data, ENTPROP_ANIM_SEQUENCE);
		float f = GetEntPropFloat(other, Prop_Data, ENTPROP_ANIM_CYCLE);
		DebugPrintToAll("Touch fired on Infected, Sequence %i, Cycle %f", i, f);
		
		if ((i >= ANIM_SEQUENCES_DOWNED_BEGIN && i <= ANIM_SEQUENCES_DOWNED_END) || i == ANIM_SEQUENCE_WALLED)
		{
			if (f >= DOWNED_ANIM_MIN_CYCLE && f <= DOWNED_ANIM_MAX_CYCLE)
			{
				DebugPrintToAll("Infected found downed. STOMPING HIM!!!");
				SmashInfected(other, entity);
				
				if (GetConVarBool(cvarSlowSurvivor))
				{
					SetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP, GetEntPropFloat(entity, Prop_Data, SPEED_MODIFY_ENTPROP) - STOMP_MOVE_PENALTY);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

void SmashInfected(int zombie, int client)
{
	EmitSoundToAll(STOMP_SOUND_PATH, zombie, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);

	AcceptEntityInput(zombie, "BecomeRagdoll");
	SetEntProp(zombie, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(zombie, Prop_Data, "m_iHealth", 1);
	SDKHooks_TakeDamage(zombie, client, client, 10000.0, DMG_GENERIC);
}

void DebugPrintToAll(const char[] format, any ...)
{
	#if TEST_DEBUG	|| TEST_DEBUG_LOG
	char buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[STOMP] %s", buffer);
	PrintToConsole(0, "[STOMP] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}