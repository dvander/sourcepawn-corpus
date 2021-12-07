#include <sourcemod>
#include <sdkhooks>
 
#pragma semicolon 1
 
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "[L4D/L4D2]CommonInfectedModifier",
    author = "Lux",
    description = "Lets you Choose your own custom damage for Common Infected",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/id/ArmonicJourney"
};

new Handle:hCvar_DmgEnable = INVALID_HANDLE;
new Handle:hCvar_HealthEnable = INVALID_HANDLE;
new Handle:hCvar_Damage = INVALID_HANDLE;
new Handle:hCvar_IncapMulti = INVALID_HANDLE;
new Handle:hCvar_MinHp = INVALID_HANDLE;
new Handle:hCvar_MaxHp = INVALID_HANDLE;

new bool:g_DmgEnable;
new bool:g_HealthEnable;
new g_iMinHp;
new g_iMaxHp;
new Float:g_iDamage;
new Float:g_iImultiplyer;

public OnPluginStart()
{
	hCvar_DmgEnable = CreateConVar("nb_damage_enable", "1", "Should We Enable Common Damage Modifing", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_HealthEnable = CreateConVar("nb_health_enable", "1", "Should We Enable Common Health Modifing", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_Damage = CreateConVar("nb_damage", "2.0", "Damage Modifier Value", FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	hCvar_IncapMulti = CreateConVar("nb_damage_modifier", "3.0", "Incapped Damage Multiplyer Value", FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	hCvar_MinHp = CreateConVar("nb_hp_min", "40", "Incapped Damage Multiplyer Value", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
	hCvar_MaxHp = CreateConVar("nb_hp_max", "70", "Incapped Damage Multiplyer Value", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
	
	HookConVarChange(hCvar_DmgEnable, eConvarChanged);
	HookConVarChange(hCvar_HealthEnable, eConvarChanged);
	HookConVarChange(hCvar_Damage, eConvarChanged);
	HookConVarChange(hCvar_IncapMulti, eConvarChanged);
	HookConVarChange(hCvar_MinHp, eConvarChanged);
	HookConVarChange(hCvar_MaxHp, eConvarChanged);
	
	AutoExecConfig(true, "CommonInfectedModifier");
}

public OnMapStart()
{
	CvarsChanged();
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_DmgEnable = GetConVarInt(hCvar_DmgEnable) > 0;
	g_HealthEnable = GetConVarInt(hCvar_HealthEnable) > 0;
	g_iDamage = GetConVarFloat(hCvar_Damage);
	g_iImultiplyer = GetConVarFloat(hCvar_IncapMulti);
	g_iMinHp = GetConVarInt(hCvar_MinHp);
	g_iMaxHp = GetConVarInt(hCvar_MaxHp);
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, eOnTakeDamage);
}

public Action:eOnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamagetype)
{
	if(!g_DmgEnable)
		return Plugin_Continue;
   
	if(!IsClientInGame(iVictim) || GetClientTeam(iVictim) != 2)
		return Plugin_Continue;
       
	decl String:sClassName[10];
	GetEntityClassname(iAttacker, sClassName, sizeof(sClassName));
	if(sClassName[0] != 'i' || !StrEqual(sClassName, "infected"))
		return Plugin_Continue;
	
	if(IsSurvivorIncapacitated(iVictim))
	{
		fDamage = (g_iDamage * g_iImultiplyer);
		return Plugin_Changed;
	}
	else
	{
		fDamage = g_iDamage;
		return Plugin_Changed;
	}
}

bool:IsSurvivorIncapacitated(iClient)
{
	return GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1) > 0;
}

public OnEntityCreated(iEntity, const String:sClassname[])
{
	if(!g_HealthEnable)
		return;
	
	if(sClassname[0] != 'i' || !StrEqual(sClassname, "infected"))
		return;
	
	static iHealth;
	iHealth = GetRandomInt(g_iMinHp, g_iMaxHp);
	SetEntProp(iEntity, Prop_Data, "m_iHealth", iHealth);
	
}