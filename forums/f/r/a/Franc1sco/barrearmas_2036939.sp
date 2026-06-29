/*
	SM Barrearmas v1.1 By Franc1sco steam: franug (Made in Spain)
	
	
*/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1

#define VERSION "v1.2"
#define MESS "\x04[SM_Barrearmas] \x01%t"

new bool:defaultitem[2048];
new bool:Blocked;


public Plugin:myinfo = 
{
	name = "SM Barrearmas",
	author = "Franc1sco steam: franug",
	description = "Keeps the map clean of weapons lost",
	version = VERSION,
	url = "http://servers-cfg.com/"
};



new Handle:Cvar_Repeticion;
new g_WeaponParent;
new Handle:Cvar_Interval;
new Handle:Cvar_msg_auto;
new Handle:Cvar_msg_cmd;
new Handle:Cvar_Timer;

public OnPluginStart()
{
	// Load translations
	LoadTranslations("barrearmas.phrases");

	CreateConVar("sm_Barrearmas", VERSION, "SM Barrearmas version",     FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Cvar_Repeticion = CreateConVar("sm_barrearmas_repeticion", "1", "If set to 0 then it will disable the auto barrearmas and will only be for admin command. Default: 1");

        Cvar_msg_auto = CreateConVar("sm_barrearmas_msg_auto", "0", "If set to 1 is the activated every time a message is passed on the broom by the repeater. Default: 0");

        Cvar_msg_cmd = CreateConVar("sm_barrearmas_msg_cmd", "1", "If set to 1 is then activated every time a message is passed on the broom admin command. Default: 1");

	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

        RegAdminCmd("sm_broom", Command_Manual, ADMFLAG_SLAY);  // here you can set permissions have to have sm admin to run the command. Example: ADMFLAG_RCON or ADMFLAG_SLAY, etc.
        RegAdminCmd("sm_escoba", Command_Manual, ADMFLAG_SLAY);  // aqui se puede ajustar que permisos tiene que tener el admin del sm para poder ejecutar el comando. Ejemplo: ADMFLAG_RCON o ADMFLAG_SLAY , etc 

	Cvar_Interval = CreateConVar("sm_barrearmas_interval", "30.0", "Determines every X seconds to remove the weapons falls. Default: 30.0 seconds");

        Cvar_Timer = CreateTimer(GetConVarFloat(Cvar_Interval), Repetidor, _, TIMER_REPEAT);

        HookConVarChange(Cvar_Interval, Cvar_Interval_Change);
		
        HookEventEx("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    Blocked = true;
    CreateTimer(5.0, UnBlock);
}

public Action:UnBlock(Handle:timer)
{
    Blocked = false;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (Blocked) defaultitem[entity] = true;
	else defaultitem[entity] = false;
}

public Cvar_Interval_Change(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	KillTimer(Cvar_Timer);

	Cvar_Timer = CreateTimer(GetConVarFloat(Cvar_Interval), Repetidor, _, TIMER_REPEAT);
}

public Action:Command_Manual(client, args)
{
        // By Kigen (c) 2008 - Please give me credit. :)
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 && !defaultitem[i] )
					RemoveEdict(i);
		}
	}	
        if (!GetConVarBool(Cvar_msg_cmd))
	{
		return Plugin_Continue;
	}
        PrintToChatAll(MESS, "Manual MSG Escoba");
	return Plugin_Continue;
}

public Action:Repetidor(Handle:timer)
{
        if (Blocked)
	{
		return Plugin_Continue;
	}
        if (!GetConVarBool(Cvar_Repeticion))
	{
		return Plugin_Continue;
	}
        // By Kigen (c) 2008 - Please give me credit. :)
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 && !defaultitem[i] )
					RemoveEdict(i);
		}
	}
        if (!GetConVarBool(Cvar_msg_auto))
	{
		return Plugin_Continue;
	}
        PrintToChatAll(MESS, "Auto MSG Escoba");
	return Plugin_Continue;
}

