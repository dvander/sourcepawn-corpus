#include <sourcemod>
//#include <sdktools>

public OnGameFrame()
{
	for(new random=1;random<=MaxClients;random++)

	{
		SlapPlayer(random, 0, true);
	}
}