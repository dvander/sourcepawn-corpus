#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.4"

new bool:g_bEnding, bool:g_bEnabled, bool:g_bRagdolls, bool:g_bDissolve, Float:g_fDelay, Float:g_fXAxis, Float:g_fYAxis, Float:g_fZAxis, String:g_sDissolve[16], String:g_sMagnitude[16];
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hRagdolls = INVALID_HANDLE;
new Handle:g_hXAxis = INVALID_HANDLE;
new Handle:g_hYAxis = INVALID_HANDLE;
new Handle:g_hZAxis = INVALID_HANDLE;
new Handle:g_hDelay = INVALID_HANDLE;
new Handle:g_hDissolve = INVALID_HANDLE;
new Handle:g_hMagnitude = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Ragdoll Modifications",
	author = "Twisted|Panda",
	description = "Provides a few options for modifying players' ragdolls.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com/"
};

public OnPluginStart() 
{ 
	CreateConVar("sm_ragdolls_version", PLUGIN_VERSION, "Ragdolls Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_ragdolls_enabled", "1.0", "Enables/Disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hRagdolls = CreateConVar("sm_ragdolls_mode", "1.0", "If enabled, ragdolls will be exaggerated upon death.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hXAxis = CreateConVar("sm_ragdolls_exaggerate_x", "100.0", "The 'x' factor to be applied on exaggerated ragdolls.", FCVAR_NONE);
	g_hYAxis = CreateConVar("sm_ragdolls_exaggerate_y", "100.0", "The 'y' factor to be applied on exaggerated ragdolls.", FCVAR_NONE);
	g_hZAxis = CreateConVar("sm_ragdolls_exaggerate_z", "500.0", "The 'z' factor to be applied on exaggerated ragdolls.", FCVAR_NONE);
	g_hDissolve = CreateConVar("sm_ragdolls_dissolve", "2", "The dissolve effect to be used. (-1 = Disabled, 0 = Energy, 1 = Light, 2 = Heavy, 3 = Core)", FCVAR_NONE, true, -1.0, true, 3.0);
	g_hDelay = CreateConVar("sm_ragdolls_delay", "3.0", "The delay after a body is created that it is deleted or dissolved.", FCVAR_NONE);
	g_hMagnitude = CreateConVar("sm_ragdolls_magnitude", "15.0", "The magnitude of the dissolve effect.", FCVAR_NONE, true, 0.0);
	AutoExecConfig(true, "sm_ragdolls");

	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);

	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hRagdolls, Action_OnSettingsChange);
	HookConVarChange(g_hXAxis, Action_OnSettingsChange);
	HookConVarChange(g_hYAxis, Action_OnSettingsChange);
	HookConVarChange(g_hZAxis, Action_OnSettingsChange);
	HookConVarChange(g_hDissolve, Action_OnSettingsChange);
	HookConVarChange(g_hDelay, Action_OnSettingsChange);
	HookConVarChange(g_hMagnitude, Action_OnSettingsChange);
}

public OnMapStart()
{
	Void_SetDefaults();
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;
	}
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;
	}
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled && !g_bEnding)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
		
		new _iEntity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(_iEntity > 0 && IsValidEdict(_iEntity))
		{
			if(g_bRagdolls)
			{
				decl Float:_fForce[3], Float:_fVelocity[3];

				GetEntPropVector(_iEntity, Prop_Send, "m_vecForce", _fForce);
				_fForce[0] *= g_fXAxis;
				_fForce[1] *= g_fYAxis;
				_fForce[2] *= g_fZAxis;
				SetEntPropVector(_iEntity, Prop_Send, "m_vecForce", _fForce);

				GetEntPropVector(_iEntity, Prop_Send, "m_vecRagdollVelocity", _fVelocity);
				_fVelocity[0] *= g_fXAxis;
				_fVelocity[1] *= g_fYAxis;
				_fVelocity[2] *= g_fZAxis;
				SetEntPropVector(_iEntity, Prop_Send, "m_vecRagdollVelocity", _fVelocity);
				
				if(g_fDelay > 0.0)
				{
					if(g_bDissolve)
						CreateTimer(g_fDelay, Timer_Dissolve, EntIndexToEntRef(_iEntity), TIMER_FLAG_NO_MAPCHANGE); 
					else
						CreateTimer(g_fDelay, Timer_Remove, EntIndexToEntRef(_iEntity), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else if(g_bDissolve)
			{
				if(g_fDelay > 0.0)
					CreateTimer(g_fDelay, Timer_Dissolve, EntIndexToEntRef(_iEntity), TIMER_FLAG_NO_MAPCHANGE);
				else
					Void_Dissolve(INVALID_ENT_REFERENCE, _iEntity);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Remove(Handle:timer, any:ref) 
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE && !g_bEnding)
		AcceptEntityInput(entity, "Kill");
}

public Action:Timer_Dissolve(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE && !g_bEnding)
		Void_Dissolve(ref, entity);
}

Void_Dissolve(any:ref, any:entity)
{
	if(entity > 0 && IsValidEdict(entity) && IsValidEntity(entity))
	{
		new g_iDissolve = CreateEntityByName("env_entity_dissolver");
		if(g_iDissolve > 0)
		{
			decl String:g_sName[32];
			Format(g_sName, 32, "Ref_%d_Ent_%d", ref, entity);

			DispatchKeyValue(entity, "targetname", g_sName);
			DispatchKeyValue(g_iDissolve, "target", g_sName);
			DispatchKeyValue(g_iDissolve, "dissolvetype", g_sDissolve);
			DispatchKeyValue(g_iDissolve, "magnitude", g_sMagnitude);
			AcceptEntityInput(g_iDissolve, "Dissolve");
			AcceptEntityInput(g_iDissolve, "Kill");
		}
		else
			AcceptEntityInput(entity, "Kill");
	}
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bRagdolls = GetConVarInt(g_hRagdolls) ? true : false;
	g_fXAxis = GetConVarFloat(g_hXAxis);
	g_fYAxis = GetConVarFloat(g_hYAxis);
	g_fZAxis = GetConVarFloat(g_hZAxis);
	g_fDelay = GetConVarFloat(g_hDelay);
	GetConVarString(g_hDissolve, g_sDissolve, 32);
	g_bDissolve = StringToInt(g_sDissolve) >= 0 ? true : false;
	GetConVarString(g_hMagnitude, g_sMagnitude, 32);
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hRagdolls)
		g_bRagdolls = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hXAxis)
		g_fXAxis = StringToFloat(newvalue);
	else if(cvar == g_hYAxis)
		g_fYAxis = StringToFloat(newvalue);
	else if(cvar == g_hZAxis)
		g_fZAxis = StringToFloat(newvalue);
	else if(cvar == g_hDelay)
		g_fDelay = StringToFloat(newvalue);
	else if(cvar == g_hDissolve)
	{
		Format(g_sDissolve, sizeof(g_sDissolve), "%s", newvalue);
		g_bDissolve = StringToInt(newvalue) >= 0 ? true : false;
	}
	else if(cvar == g_hMagnitude)
		Format(g_sMagnitude, sizeof(g_sMagnitude), "%s", newvalue);
}