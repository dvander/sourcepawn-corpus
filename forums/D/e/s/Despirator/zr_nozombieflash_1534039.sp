#include <sdktools>
#include <zombiereloaded>

public Plugin:myinfo = 
{
	name = "No Zombie Flashlight",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Simple plugin that restricts flashlights for zombies",
	version = "1.0",
	url = "www.hlmod.ru"
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (ZR_IsClientZombie(client) && impulse == 100)
		impulse = 0;
}