#include <sourcemod>
#include <sdktools>


new Handle:HudHintTimers[MAXPLAYERS+1];
new Float:lastPosition[MAXPLAYERS + 1][3];
new g_jumps[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "SM jumps and velocity",
	author = "Franc1sco steam: franug",
	version = "1.2",
	description = "jumps and velocity",
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_jumpsandvelocity", "1.2", "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    	HookEvent("player_jump", PlayerJump);

	HookEvent("round_start", Event_RoundStart);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

		for(new i=1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				g_jumps[i] = 0;
}

public Action:PlayerJump(Handle:event, const String:name[], bool:dontBroadcast) 
{
      	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	++g_jumps[client];

}

public OnClientPostAdminCheck(client)
{
	g_jumps[client] = 0;
	CreateHudHintTimer(client);
}

public OnClientDisconnect(client)
{
	KillHudHintTimer(client);
}


CreateHudHintTimer(client)
{
	HudHintTimers[client] = CreateTimer(0.5, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

KillHudHintTimer(client)
{
	if (HudHintTimers[client] != INVALID_HANDLE)
	{
		KillTimer(HudHintTimers[client]);
		HudHintTimers[client] = INVALID_HANDLE;
	}
}

public Action:Timer_UpdateHudHint(Handle:timer, any:client)
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;

	new Float:newPosition[3], Float:distance, Float:speed;
	GetClientAbsOrigin (client, newPosition);
	distance = GetVectorDistance (lastPosition[client], newPosition);
	speed = distance / 20 * 2;
	lastPosition[client] = newPosition;

	decl String:szText[254];
	
	Format(szText, sizeof(szText), "______________\nSpeed: %d km/h\nJumps: %i\n______________", RoundToNearest(speed), g_jumps[client]);

//	on the right side		
/*	
	// Send our message
	new Handle:hBuffer = StartMessageOne("KeyHintText", client); 
	BfWriteByte(hBuffer, 1); 
	BfWriteString(hBuffer, szText); 
	EndMessage();
*/

	// on hint box
	PrintHintText(client, szText);
	
	return Plugin_Continue;
}