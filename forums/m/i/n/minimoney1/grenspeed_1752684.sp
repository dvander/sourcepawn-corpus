#include <sourcemod>
#include <sdktools>

// CVAR HANDLING

#define MAX_CVARS 32
#define CVAR_LENGTH 128

enum CVAR_TYPE
{
	TYPE_INT = 0,
	TYPE_FLOAT,
	TYPE_STRING,
	TYPE_FLAG
}

enum CVAR_CACHE
{
	Handle:hCvar,
	CVAR_TYPE:eType,
	any:aCache,
	String:sCache[CVAR_LENGTH],
	Function:fnCallback
}

new g_eCvars[MAX_CVARS][CVAR_CACHE];

new g_iCvars = 0;

RegisterConVar(String:name[], String:value[], String:description[], CVAR_TYPE:type, Function:callback=INVALID_FUNCTION, flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	new Handle:cvar = CreateConVar(name, value, description, flags, hasMin, min, hasMax, max);
	HookConVarChange(cvar, GlobalConVarChanged);
	g_eCvars[g_iCvars][hCvar] = cvar;
	g_eCvars[g_iCvars][eType] = type;
	g_eCvars[g_iCvars][fnCallback] = callback;
	CacheCvarValue(g_iCvars);
	return g_iCvars++;
}

public GlobalConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for(new i=0;i<g_iCvars;++i)
		if(g_eCvars[i][hCvar]==convar)
		{
			CacheCvarValue(i);
		
			if(g_eCvars[i][fnCallback]!=INVALID_FUNCTION)
			{
				Call_StartFunction(INVALID_HANDLE, g_eCvars[i][fnCallback]);
				Call_PushCell(i);
				Call_Finish();
			}
		
			return;
		}
	
}

public CacheCvarValue(index)
{
	if(g_eCvars[index][eType]==TYPE_INT)
		g_eCvars[index][aCache] = GetConVarInt(g_eCvars[index][hCvar]);
	else if(g_eCvars[index][eType]==TYPE_FLOAT)
		g_eCvars[index][aCache] = GetConVarFloat(g_eCvars[index][hCvar]);
	else if(g_eCvars[index][eType]==TYPE_STRING)
		GetConVarString(g_eCvars[index][hCvar], g_eCvars[index][sCache], CVAR_LENGTH);
	else if(g_eCvars[index][eType]==TYPE_FLAG)
	{
		GetConVarString(g_eCvars[index][hCvar], g_eCvars[index][sCache], CVAR_LENGTH);
		g_eCvars[index][aCache] = ReadFlagString(g_eCvars[index][sCache]);
	}
}

// GLOBALS

new g_CvarMultiplier;
new g_CvarTime;

public OnPluginStart()
{
	LoadTranslations("nadeboost.phrases");

	HookEvent("player_death", Event_PlayerDeath);
	
	g_CvarMultiplier = RegisterConVar("sm_grenspeed_multiplier", "2.0", "The speed multiplier", TYPE_FLOAT);
	g_CvarTime = RegisterConVar("sm_grenspeed_time", "5.0", "Time in seconds the effect lasts for", TYPE_FLOAT);
	
	AutoExecConfig();
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim == attacker)
		return Plugin_Continue;
		
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(strcmp(weapon, "weapon_hegreande")!=0)
		return Plugin_Continue;
	
	PrintToChat(attacker, "[SM] %t", "Nade Kill Message", victim, g_eCvars[g_CvarMultiplier][aCache], g_eCvars[g_CvarTime][aCache]);
	SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", g_eCvars[g_CvarMultiplier][aCache]);
	CreateTimer(g_eCvars[g_CvarTime][aCache], Timer_ResetSpeed, GetClientUserId(attacker));
	
	return Plugin_Continue;
}

public Action:Timer_ResetSpeed(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	return Plugin_Stop;
}