#pragma semicolon 1

public Plugin:myinfo = 
{
	name		= "Block use C4",
	author		= "Pypsikan",
	version     = "1.0",
	url         = "http://sourcemod.net"
};

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_ATTACK)
	{
		new String:classname[64];
		GetClientWeapon(client, classname, sizeof(classname));
		
		if (StrEqual(classname, "weapon_c4"))
		{
			buttons &= ~IN_ATTACK;
		}
	}
}