#include <sourcemod>
#include <sdktools>

new Handle:cvar_matrix = INVALID_HANDLE;

new Handle:Cheats = INVALID_HANDLE;
new Handle:Matrix = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "SM on end bullet time",
	author = "Franc1sco steam: franug",
	version = "1.0",
	description = "for bullet time",
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_endbullettime_version", "1.0", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvar_matrix = CreateConVar("sreb_timescale", "0.2", "bullet time value");

	HookEvent("round_end", Event_Round_End);

	HookEvent("round_start", Event_Round_Start);

	Cheats = FindConVar("sv_cheats");

	Matrix = FindConVar("host_timescale");

}


public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	SetConVarInt(Cheats, 0);
	SetConVarFloat(Matrix, 1.0);
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast) 
{
	SetConVarInt(Cheats, 1);
	SetConVarFloat(Matrix, GetConVarFloat(cvar_matrix));
}