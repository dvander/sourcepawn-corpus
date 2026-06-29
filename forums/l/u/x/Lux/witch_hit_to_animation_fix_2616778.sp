#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

static Handle hCvar_WitchIncapDmg = null;
static Handle hCvar_RealIncapCvar = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "witch_hit_to_animation_fix",
	author = "Lux",
	description = "Tries the match the hits to the witch swiping animation on incapped survivors",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("witch_hit_to_animation_fix_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("witch_spawn", eWitchSpawn, EventHookMode_Pre);	
	
	hCvar_RealIncapCvar = FindConVar("z_witch_damage_per_kill_hit");
	if(hCvar_RealIncapCvar == null)
		SetFailState("z_witch_damage_per_kill_hit cvar missing!");
	
	
	hCvar_WitchIncapDmg = CreateConVar("z_witch_damage_per_incap_hit", "30", "damage each time witch hits while incapped", FCVAR_NOTIFY, true, 1.0);
	HookConVarChange(hCvar_WitchIncapDmg, eCvarChanged);
	HookConVarChange(hCvar_RealIncapCvar, eCvarChanged);
	AutoExecConfig(true, "witch_hit_to_animation_fix");
	CvarChanged();
}

public void eCvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	CvarChanged();
}

void CvarChanged()
{
	SetConVarInt(hCvar_RealIncapCvar, GetConVarInt(hCvar_WitchIncapDmg));
}

public Action eWitchSpawn(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	int iWitch = GetEventInt(hEvent, "witchid");
	
	if(iWitch < 1 || !IsValidEntity(iWitch))
		return;
	
	SDKHook(iWitch, SDKHook_Think, UpdateThink);
}

public void UpdateThink(int iWitch)
{
	if(GetEntProp(iWitch, Prop_Send, "m_nSequence", 2) == 32)
		if(GetEntPropFloat(iWitch, Prop_Send, "m_flCycle") > 0.2825696316262354)
			SetEntPropFloat(iWitch, Prop_Send, "m_flCycle", 1.0);
}