#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name = "NoFire",
	author = "Negratius",
	description = "No clicking m1 button",
	version = "1.0",
};


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    // Check if the player is attacking (+attack)
    if (buttons & IN_ATTACK)
    {
        // If so, block their attacking (+attack)
        buttons &= ~IN_ATTACK;
	// Blocks attacking but let's other commands run
	// if the return is Plugin_Handled all other commands would be blocked when attacking;
 	return Plugin_Continue;
    }
 
    // We must return Plugin_Continue to let the changes be processed.
    // Otherwise, we can return Plugin_Handled to block the commands
    // If the player is not attacking, the other commands won't be blocked with Plugin_Continue
    return Plugin_Continue;
}
