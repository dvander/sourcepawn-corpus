#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
public Plugin:myinfo =
{
    name = "Trigger_Push Fix",
    author = "iEx",
    description = "Fix bug with trigger_push at touch",
    version = "1.2",
    url = "http://steamcommunity.com/id/TheExplode/"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	FixPush();
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    FixPush();
}

FixPush()
{
    new FindMaxEntities = GetMaxEntities();
    decl String:name[64];
    for(new i = 0; i < FindMaxEntities; i++)
    {
        if(IsValidEntity(i))
        {
            GetEdictClassname(i, name, sizeof(name));
            if(!strcmp(name, "trigger_push", false))
            {
			HookSingleEntityOutput(i, "OnStartTouch", PushTouch);
            }
        }
    }
}

public PushTouch(const String:output[], ent, client, Float:delay)
{
	if(!(1<=client<= MaxClients ) || (ent == -1) || (!IsClientInGame(client)) || !IsPlayerAlive(client))
		return;
	new fixflags = GetEntityFlags(client);
	if (fixflags & FL_ONGROUND)
	{
	//SetEntityFlags(client, (fix != FL_ONGROUND)); - i dunno how make this work xD
	decl Float:Pushfix[3];
	decl Float:vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
	GetClientAbsOrigin(client, Pushfix);
	Pushfix[2] += 5.0;
	TeleportEntity(client, Pushfix, NULL_VECTOR, vel);
	CreateTimer(0.5,TimerFix,client);
	}
}
public Action:TimerFix(Handle:timer,any:client)
{
decl Float:Pushfix[3];
GetClientAbsOrigin(client, Pushfix);
decl Float:vel[3];
GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
Pushfix[2] -= 5.0;
TeleportEntity(client, Pushfix, NULL_VECTOR, vel);
}