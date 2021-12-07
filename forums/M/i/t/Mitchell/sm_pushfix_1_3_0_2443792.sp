#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

ConVar hEnable;
bool bEnable;
bool bHooked;

public Plugin myinfo =
{
	name = "Trigger_Push Fix",
	author = "iEx (rewrited by Grey83)",
	description = "Fix bug with trigger_push at touch",
	version = "1.3.0",
	url = "http://steamcommunity.com/id/TheExplode/"
};

public void OnPluginStart()
{
	hEnable	= CreateConVar("sm_pushfix_enable", "1", "Enables/disables the plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	bEnable	= GetConVarBool(hEnable);
	HookConVarChange(hEnable, OnCVarChanged);
	ChangeMode();
}

public void OnCVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bEnable = view_as<bool>(StringToInt(newValue));
	ChangeMode();
}

void ChangeMode()
{
	if(bEnable && !bHooked) HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	else if(!bEnable && bHooked) UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	bHooked = bEnable;
	FixPush();
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	FixPush();
}

void FixPush()
{
	char name[64];
	for(int i; i < GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i, name, sizeof(name));
			if(strcmp(name, "trigger_push", false) == 0)
			{
				if(bEnable) HookSingleEntityOutput(i, "OnStartTouch", PushTouch);
				else UnhookSingleEntityOutput(i, "OnStartTouch", PushTouch);
			}
		}
	}
}

public void PushTouch(const char[] output, int ent, int client, float delay)
{
	if(ent != -1 && 0<client<= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && (GetEntityFlags(client) & FL_ONGROUND)) FixAltitude(client, true);
}

public Action TimerFix(Handle timer, any client)
{
	if(0<client<= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client)) FixAltitude(client);
}

void FixAltitude(int client, bool up = false)
{
	float Pushfix[3], vel[3];
	GetClientAbsOrigin(client, Pushfix);
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
	if(up) Pushfix[2] += 5.0;
	else Pushfix[2] -= 5.0;
	TeleportEntity(client, Pushfix, NULL_VECTOR, vel);
	if(up) CreateTimer(0.5, TimerFix, client);
}