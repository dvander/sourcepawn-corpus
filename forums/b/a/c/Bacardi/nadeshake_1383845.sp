#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define AMP_SHAKE		50.0
#define DUR_SHAKE		1.0
#define PL_VERSION		"1.0.2.1"

new Handle:g_Cvar_nsEnabled				= INVALID_HANDLE;
new bool:g_nsEnabled;
new Handle:g_Cvar_nsEnabledDmg			= INVALID_HANDLE;
new Handle:g_color		= INVALID_HANDLE;
new Handle:g_color_r			= INVALID_HANDLE;
new Handle:g_color_b			= INVALID_HANDLE;
new Handle:g_color_g			= INVALID_HANDLE;
new Handle:g_color_a			= INVALID_HANDLE;
new Handle:g_color_multi		= INVALID_HANDLE;

new String:Weapon[30];

public Plugin:myinfo =
{
	name		= "NadeShake with damage color",
	author		= "Vogon, messed by Bacardi",
	description	= "HEGrenades shake screen when blowing up, fade color effect.",
	version		= PL_VERSION,
	url			= "www.twkgaming.com"
}


public OnPluginStart()
{
	g_Cvar_nsEnabled = CreateConVar("sm_nadeshake_enable", "1", "Enable NadeShake");
	g_Cvar_nsEnabledDmg = CreateConVar("sm_nadeshake_nadedmg", "1", "Enable NadeShake by damage inflicted.");

	g_color = CreateConVar("sm_nadeshake_color", "0", "Enable NadeShake fade damage color.");
	g_color_r = CreateConVar("sm_nadeshake_color_r", "255", "NadeShake color RED.", _, true, 0.0, true, 255.0);
	g_color_b = CreateConVar("sm_nadeshake_color_b", "0", "NadeShake color BLUE.", _, true, 0.0, true, 255.0);
	g_color_g = CreateConVar("sm_nadeshake_color_g", "0", "NadeShake color GREEN.", _, true, 0.0, true, 255.0);
	g_color_a = CreateConVar("sm_nadeshake_color_a", "180", "NadeShake color ALPHA.", _, true, 0.0, true, 255.0);
	g_color_multi = CreateConVar("sm_nadeshake_color_duration", "10", "NadeShake color fade duration multiplier.", _, true, 1.0, true, 100.0);

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
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	GetEventString(event,"weapon",Weapon,30);
	if(StrEqual(Weapon,"hegrenade"))
	{
		if(g_Cvar_nsEnabledDmg)
		{
			new Float:damage = GetEventFloat(event, "dmg_health");
			Shake(client, damage, DUR_SHAKE);
			if(GetConVarInt(g_color) == 1)
			{
				new damagecol = RoundToNearest(damage)*GetConVarInt(g_color_multi); // Float to integer * cvar value
				PerformFade(client, damagecol);
			}
		}
		else
		{
			Shake(client, AMP_SHAKE, DUR_SHAKE);
			if(GetConVarInt(g_color) == 1)
			{
				PerformFade(client, GetConVarInt(g_color_multi));
			}
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

// http://forums.alliedmods.net/showpost.php?p=1187349&postcount=3
#define FFADE_IN 0x0001
#define FFADE_OUT 0x0002
#define FFADE_MODULATE 0x0004
#define FFADE_STAYOUT 0x0008
#define FFADE_PURGE 0x0010

PerformFade(client, duration)
{

	new Handle:hFadeClient=StartMessageOne("Fade", client);
	BfWriteShort(hFadeClient, duration);
	BfWriteShort(hFadeClient, 2);
	BfWriteShort(hFadeClient, (FFADE_PURGE|FFADE_IN));
	BfWriteByte(hFadeClient, GetConVarInt(g_color_r));
	BfWriteByte(hFadeClient, GetConVarInt(g_color_g));
	BfWriteByte(hFadeClient, GetConVarInt(g_color_b));
	BfWriteByte(hFadeClient, GetConVarInt(g_color_a));
	EndMessage();
}