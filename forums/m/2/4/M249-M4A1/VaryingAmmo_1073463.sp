/*
________________________________________________________

Varying Gun Ammunition					
Version 1.0.0

This plugin randomly changes the amount of bullets that are in guns that you pick up. This will not change anything involving
the guns that players are holding, unless they pick up a new gun the ammo they currently have will remain the same.
________________________________________________________

ChangeLog

Version 0.1.0 - Never released, caused server lag
Version 0.5.0 - Never released, timer did not work properly, was redone for 1.0.0
Version 1.0.0 - Initial Release, working properly!

________________________________________________________

Planned Future Updates: 
Cvars controlling minimum and maximum values
Cvars controlling which guns will have ammo count changed
Cvar controlling how often the ammunition count is changed

*/

//Doing initial Plugin "Stuff"
#include sourcemod

public Plugin:myinfo =
{
        // edited by M249-M4A1
	name = "Varying Gun Ammunition",
	author = "Luke Penny",
	description = "Periodically changes the amount of ammo contained in picked up guns",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=117200"
};

//Cvar Handles
new Handle:smgammo
new Handle:shotgunammo
new Handle:rifleammo
new Handle:huntingrifleammo

// added for constistency with above, theres simpler ways to do this
new Handle:smgammo_min
new Handle:shotgunammo_min
new Handle:rifleammo_min
new Handle:huntingrifleammo_min

new Handle:smgammo_max
new Handle:shotgunammo_max
new Handle:rifleammo_max
new Handle:huntingrifleammo_max

//Create the timer that decides how often to change the gun cvars, edit the number to change the interval, it is 90 at the moment
public OnPluginStart()
{
	CreateTimer(120.0, GunTimer, _, TIMER_REPEAT)
	huntingrifleammo = FindConVar("ammo_huntingrifle_max")
	rifleammo = FindConVar("ammo_assaultrifle_max")
	shotgunammo = FindConVar("ammo_buckshot_max")
	smgammo = FindConVar("ammo_smg_max")
	PrintToServer("Varying Ammo Plugin is working")

        // min ammo (created own convar to avoid conflicts)
        huntingrifleammo_min = CreateConVar("l4d_huntingrifleammo_min", "1")
	rifleammo_min = CreateConVar("l4d_assaultrifleammo_min", "1")
        shotgunammo_min = CreateConVar("l4d_buckshotammo_min", "1")
        smgammo_min = CreateConVar("l4d_smgammo_min", "1") 

        // max ammo (created own convar to avoid conflicts)
        huntingrifleammo_max = CreateConVar("l4d_huntingrifleammo_max", "500")
	rifleammo_max = CreateConVar("l4d_assaultrifleammo_max", "500")
        shotgunammo_max = CreateConVar("l4d_buckshotammo_max", "500")
        smgammo_max = CreateConVar("l4d_smgammo_min", "500") 
}

//Now to actually get the random number in between the 2 minimum and maximum values, every time the timer reaches it's interval
public Action:GunTimer(Handle:timer)
{	
        static NumPrinted = 0
	if (NumPrinted++ <= 2)
	{
			new Shotgun = GetRandomInt(GetConVarInt(shotgunammo_min), GetConVarInt(shotgunammo_max))
			new Rifle = GetRandomInt(GetConVarInt(rifleammo_min), GetConVarInt(rifleammo_max))
			new Smg = GetRandomInt(GetConVarInt(smgammo_min), GetConVarInt(smgammo_max))
			new Huntingrifle = GetRandomInt(GetConVarInt(huntingrifleammo_min), GetConVarInt(huntingrifleammo_max))
//Now to set the ammo cvars to the new randomized values, which was just done above
			SetConVarInt(shotgunammo, Shotgun)
			SetConVarInt(rifleammo, Rifle)
			SetConVarInt(huntingrifleammo, Huntingrifle)
			SetConVarInt(smgammo, Smg)
			NumPrinted = 0
	}
	return Plugin_Continue
}

//Done!
