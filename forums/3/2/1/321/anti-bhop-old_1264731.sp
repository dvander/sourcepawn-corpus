#pragma semicolon 1

#include <sdktools>

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hAdjust = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Bunny-Hop Preventer",
	author = "Someone",
	description = "",
	version = "1.1",
	url = "www.liveteam.ru"
}

public OnPluginStart()
{
	g_hEnabled = CreateConVar("antibhop_enabled", "1", "Enable/Disable bhop preventer", _, true, 0.0, true, 1.0);
	g_hAdjust = CreateConVar("antibhop_adjust", "0.0", "+- speed limit");

	HookEvent("player_jump", Event_PlayerJump);
}

public Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_hEnabled))
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(0.0, _Event_PlayerJump, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:_Event_PlayerJump(Handle:timer, any:client)
{
	decl Float:velocity[3];

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

	new Float:speed = SquareRoot(Pow(velocity[0], 2.0) + Pow(velocity[1], 2.0));
	new Float:max_speed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") + GetConVarFloat(g_hAdjust);

	if(speed > max_speed)
	{
		new Float:scale = FloatDiv(max_speed, SquareRoot(FloatAdd(Pow(velocity[0], 2.0), Pow(velocity[1], 2.0))));

		velocity[0] = FloatMul(velocity[0], scale);
		velocity[1] = FloatMul(velocity[1], scale);

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}
}