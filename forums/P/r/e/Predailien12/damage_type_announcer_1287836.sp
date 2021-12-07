#include <sourcemod>

public Plugin:myinfo =
{
	name = "데미지 확인",
	author = "Rayne",
	description = "데미지 타입 확인을 할 수 있게합니다.",
	version = "1.0.0",
	url = "",
}

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PH)
}

public Action:Event_PH(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new dmg_type = GetEventInt(event, "type")
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	PrintToChat(client, "\x03Damage Type: \x04%d", dmg_type)
}