#pragma semicolon 1
#include <sourcemod>

new Handle:autorespawn = INVALID_HANDLE;
new Handle:respawntime = INVALID_HANDLE;
new Handle:AR_Timer = INVALID_HANDLE;
new Handle:b_displayMessage = INVALID_HANDLE;
new Handle:s_message = INVALID_HANDLE;
new String:AR_Message[192];

public OnPluginStart()
{
	autorespawn = FindConVar("sm_autorespawn_enabled");
	
	if (autorespawn == INVALID_HANDLE)
	{
		SetFailState("Unable to find \"sm_autorespawn_enabled\"");
	}
	
	respawntime = CreateConVar("sm_ar_time", "20.0", "Number of seconds to allow sm_autorespawn to remain enabled");
	b_displayMessage = CreateConVar("sm_ar_msg", "1", "Display a message when autorespawn is disabled?", _, true, 0.0, true, 1.0);
	s_message = CreateConVar("sm_ar_message", "Autorespawn is now disabled", "Message to display to users when autorespawn is disabled");
	GetConVarString(s_message, AR_Message, sizeof(AR_Message));
	
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	ClearTimer(AR_Timer);
}

public OnMapEnd()
{
	ClearTimer(AR_Timer);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearTimer(AR_Timer);
	
	SetConVarInt(autorespawn, 1);
	
	AR_Timer = CreateTimer(GetConVarFloat(respawntime), Timer_DisableAR);
}

public Action:Timer_DisableAR(Handle:timer)
{
	AR_Timer = INVALID_HANDLE;
	
	SetConVarInt(autorespawn, 0);
	
	if (GetConVarBool(b_displayMessage))
	{
		PrintToChatAll("%s", AR_Message);
	}
}

ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}