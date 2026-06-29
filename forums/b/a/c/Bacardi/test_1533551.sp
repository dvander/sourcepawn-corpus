#include <sdktools>
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(impulse != 0)
	{
		PrintToChat(client, "Blocked impulse %i", impulse);
		impulse = 0;
	}
	return Plugin_Continue;
}