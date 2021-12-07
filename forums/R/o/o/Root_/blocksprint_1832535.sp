#include <sourcemod>

new Handle:BlockSprint = INVALID_HANDLE

public OnPluginStart() BlockSprint = CreateConVar("dod_blocksprint", "1", "Whether or not block sprinting", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0)

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (GetConVarBool(BlockSprint) == true)
	{
		if (IsPlayerValid(client))
		{
			buttons &= ~IN_SPEED
		}
	}
	return Plugin_Continue
}

bool:IsPlayerValid(client) return (client > 0 && IsClientInGame(client)) ? true : false