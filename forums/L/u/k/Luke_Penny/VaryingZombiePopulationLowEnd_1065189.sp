//Varying Zombie Population
//This plugin works on Left 4 Dead 1 and 2! It does the very same thing in both. Will not work in any other game.
//
//Varying Zombie Population: This is my first plugin, and most likely has some bad coding habits or problems in it!
//The default values of this plugin are balanced, so zombies can have up to 40 less health than usual and 40 more health than usual
//Zombies can also have up to 50 more speed or 50 less speed. You can change these values down in the code, read the comments!
//
//Future planned updates: 
//
//Cvars for the minimum and maximum values of zombie health and speed
//Forcing the director to use a random value, instead of constantly changing the value he uses on a timer (somehow)
//Making this apply to Special Infected as well

#include <sourcemod>
 
public Plugin:myinfo =
{
	name = "Varying Zombie Population",
	author = "Luke Penny",
	description = "Randomizes zombies individual health and speed between set values, to create a Varying and changing population and difficulty",
	version = "1.0.0",
	url = "http://forums.alliedmods.net/showthread.php?t=116515"
};

new Handle:g_zHealth
new Handle:g_zSpeed
new Float:RandomHealth
new Float:RandomSpeed

//Here we create what intervals for the values to change
//The values that are set on the second a zombie spawns is what values that zombie will get
//Because the director constantly spawns and removes infected to adjust the population, and because hordes are spawned very quickly,
//A quicker interval will mean a more Varying population. Anything above 3-5 seconds will cause different areas of population to have
//different values, instead of individual zombies.

public OnPluginStart()
{
	CreateTimer(1.6, HealthInterval, _, TIMER_REPEAT)
	CreateTimer(1.9, SpeedInterval, _, TIMER_REPEAT)
	g_zHealth = FindConVar("z_health")
	g_zSpeed = FindConVar("z_speed")
	PrintToServer("Zombie health and speed is being set randomly")
}
 
//The timer for changing zombies health. Change the minimum and maximum values of the GetRandomInt to change the minimum and maximum
//health that zombies can have. For example, GetRandomInt(50, 150) will make zombies health between 50 and 150. 
//The default zombie health is 50, in all difficulties and gamemodes
 
public Action:HealthInterval(Handle:timer)
{	
        static NumPrinted = 0
	if (NumPrinted++ <= 2)
	{
			RandomHealth = GetRandomInt(10, 90)
			SetConVarInt(g_zHealth, RandomHealth)
			NumPrinted = 0
	}
	return Plugin_Continue
}

//The timer for changing zombies speed. Again, chance the minimum and maximum values of the GetRandomInt to change the minimum and
//maximum speed that zombies can have. For example, GetRandomInt(200,300) will make zombies speed between 200 and 300.
//The default zombies speed is 250, in all difficulties and gamemodes

public Action:SpeedInterval(Handle:timer)
{	
        static NumPrinted = 0
	if (NumPrinted++ <= 2)
	{
			RandomSpeed = GetRandomInt(200, 300)
			SetConVarInt(g_zSpeed, RandomSpeed)
			NumPrinted = 0
	}
	return Plugin_Continue
}

//That's it! Please give feedback, comments, or suggestions!