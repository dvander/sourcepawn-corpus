#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define AMP_SHAKE        50.0
#define DUR_SHAKE        1.0
#define PL_VERSION    "1.0.2"

new Handle:g_Cvar_nsEnabled             = INVALID_HANDLE;
new bool:g_nsEnabled;
new Handle:g_Cvar_nsEnabledDmg          = INVALID_HANDLE;

new String:Weapon[30];

public Plugin:myinfo =
{
	name        = "NadeShake",
	author      = "Vogon",
	description = "HEGrenades shake screen when blowing up.",
	version     = PL_VERSION,
	url         = "www.twkgaming.com"
}


public OnPluginStart()
{
	g_Cvar_nsEnabled = CreateConVar("sm_nadeshake_enable", "1", "Enable NadeShake");
	g_Cvar_nsEnabledDmg = CreateConVar("sm_nadeshake_nadedmg", "1", "Enable NadeShake by damage inflicted.");
	g_nsEnabled = GetConVarBool(g_Cvar_nsEnabled);
	CreateConVar("sm_nadeshake_version", PL_VERSION, "Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "sm_nadeshake");
	
	HookConVarChange(g_Cvar_nsEnabled, CvarChanged);
	
	if ( g_nsEnabled ) 
	{
	StartHook();
	}

}

public CvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{
	if ( cvar == g_Cvar_nsEnabled ) 
	{         
		if ( g_nsEnabled == GetConVarBool(g_Cvar_nsEnabled) ) 
		{
			return;
		}
		g_nsEnabled = !g_nsEnabled;
		if ( g_nsEnabled ) 
		{
			StartHook();
		} else 
		{
			StopHook();
		}
		return;
	}
}


StartHook() 
{
	HookEvent("player_hurt", player_hurt);
}
StopHook()
{
	UnhookEvent("player_hurt", player_hurt);
}



public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	GetEventString(event,"weapon",Weapon,30);
	if(StrEqual(Weapon,"hegrenade"))
    
	{
        if(g_Cvar_nsEnabledDmg)
		{
		new clientid = GetEventInt(event,"userid");
		new client = GetClientOfUserId(clientid);
		new Float:damage = GetEventFloat(event, "dmg_health");
		Shake(client, damage, DUR_SHAKE);
		}
		else
        {	
		new clientid = GetEventInt(event,"userid");
		new client = GetClientOfUserId(clientid);
		Shake(client, AMP_SHAKE, DUR_SHAKE);
		}		
	}
	return Plugin_Continue;
}


stock Shake(client, Float:flAmplitude, Float:flDuration)
{
	new Handle:hBf=StartMessageOne("Shake", client);
	if(hBf!=INVALID_HANDLE)
	
	BfWriteByte(hBf,  0);
	BfWriteFloat(hBf, flAmplitude);
	BfWriteFloat(hBf, 1.0);
	BfWriteFloat(hBf, flDuration);
	EndMessage();
}