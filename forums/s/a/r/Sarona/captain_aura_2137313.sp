#include <sourcemod>
#include <sdktools>
#include <captain>

new Handle:gactivarAura = INVALID_HANDLE;
new Handle:gactivarColor = INVALID_HANDLE;

new g_BeamSprite;
new g_HaloSprite;
new activarAura;
new activarColor;

public OnPluginStart()
{
	gactivarAura = CreateConVar( "sm_captain_aura", "1" );
	gactivarColor = CreateConVar( "sm_captain_color", "0" );
}

public OnMapStart()
{
	HookEvent("round_start", Event_Start);
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");

	CreateTimer(0.1, Temporizador, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	activarAura = GetConVarInt(gactivarAura);
	activarColor = GetConVarInt(gactivarColor);
}

public Action:Temporizador(Handle:timer)
{
	new captain = JC_GetCaptain();

	for (new i = 1; i <= MaxClients; i++)
		if(i == captain)
		{
			if(activarAura == 1)
			{
				SetupBeacon(i);
			}
			
			if(activarColor == 1)
			{
				SetEntityRenderColor(i, 60, 255, 0, 255);
			}
		}
}

SetupBeacon(client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	TE_SetupBeamRingPoint(vec, 50.0, 60.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 0.0, {255, 150, 0, 255}, 10, 0);
	TE_SendToAll();
}