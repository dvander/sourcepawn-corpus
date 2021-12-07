#include <sdktools>

public OnPluginStart()
{
	RegAdminCmd("sm_teleportme", teleport, ADMFLAG_RESERVATION, "You go -2389.258056, -4447.823730, 307.036804");
}

public Action:teleport(client, args)
{
	if(!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	new Float:pos[] = {-2389.258056, -4447.823730, 307.036804};
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	ShowActivity2(client, "[SM]", "Teleported %0.2f %0.2f %0.2f", pos[0], pos[1], pos[2]);
	LogAction(client, -1, "%L teleported %0.2f %0.2f %0.2f", client, pos[0], pos[1], pos[2]);
	return Plugin_Handled;
}