

#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "1.11"


//Sourcemod Convars
new Handle:infiniteon;
//new Handle:pipeson;
//new Handle:moloson;
//new Handle:medson;
//new Handle:pillson;

//Convar Variables
//new Handle:rifle;
//new Handle:smg;
//new Handle:shotgun;
//new Handle:hrifle;
//new Handle:pipes;
//new Handle:molos;
//new Handle:meds;
//new Handle:pills;

public Plugin:myinfo = 
{
	name = "[L4D] Infinite Reserve",
	author = "(-DR-)Grammernatzi",
	description = "This plug-in gives survivors an infinite reserve of ammo. They still have to reload, but they never have to worry about running out of ammo.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
	//Is this plug-in on?
	CreateConVar("infinite_reserve_version", PLUGIN_VERSION, "Signals if this plug-in is on.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//This convar is used to determine if the plug-in is enabled or not by the server administrator.
	infiniteon = CreateConVar("infinitereserve_enabled","1","Enable/disable the infinite reserve plug-in.",FCVAR_PLUGIN,true,0.0);
	
	//Convars for infinite pills, molotovs, medkits, and pills.
	//pipeson = CreateConVar("infinitereserve_pipebombs","0","Enable/disable the infinite pipebombs.",FCVAR_PLUGIN,true,0.0);
	//moloson = CreateConVar("infinitereserve_molotovs","0","Enable/disable the infinite molotovs.",FCVAR_PLUGIN,true,0.0);
	//medson = CreateConVar("infinitereserve_enabled","1","Enable/disable the infinite reserve plug-in.",FCVAR_PLUGIN,true,0.0);
	//pillson = CreateConVar("infinitereserve_enabled","1","Enable/disable the infinite reserve plug-in.",FCVAR_PLUGIN,true,0.0);
	
	//This binds our function, ReloadAmmo, to the event weapon_reload. When the player reloads, the function will be called.
	//HookEvent("weapon_reload",ReloadAmmo);
	
	//Timer to check convar status.
	//CreateTimer(1.0,TimerUpdate, _, TIMER_REPEAT);
	
	//This function automatically makes a config file for our plug-in and executes it.
	AutoExecConfig(true,"L4DInfiniteReserve");
}

public Action:ReloadAmmo(Handle:event, String:event_name[], bool:dontBroadcast)
{
	//Who is the person that we want to fill the reserve of?
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//To prevent some rare crashes, we're going to check if the person is actually a player.
	if (client > 0 && client < 20)
	{
		//Now we are going to check if the plug-in is enabled or not.
		if(GetConVarInt(infiniteon))
		{
			//Now we need to rid the give command of its cheats flag.
			//We will first gather the current flags of the command and store them in a variable.
			new cheatsoff = GetCommandFlags("give");
			//Now we will strip the cheats flag off the give command. The ~ symbol is added when you want to destroy a flag.
			SetCommandFlags("give",cheatsoff & ~FCVAR_CHEAT);
			
			//Now we will refill the clients ammo.
			//We will do this by faking a give command in their console. This is the reason that we stripped the cheats command off of the give command.
			FakeClientCommand(client, "give ammo");
			
			//Ok, now the player has a refilled reserve. However, if we keep the cheatless give command on, then the client will be able to give himself whatever he pleases!
			//In order to stop this, we must apply the cheats flag back on to the give command. This isn't too hard. Just make its flags the same as it was before.
			SetCommandFlags("give",cheatsoff|FCVAR_CHEAT);
			
			//There! The client now has his ammo reserve refilled, and the give command is reverted back to normal. This ends the function.
		}
	}
	return Plugin_Handled;
}

/*public Action:TimerUpdate(Handle:timer)
{
	rifle = FindConVar("ammo_assaultrifle_max");
	smg = FindConVar("ammo_smg_max");
	shotgun = FindConVar("ammo_buckshot_max");
	hrifle = FindConVar("ammo_huntingrifle_max");
	pipes = FindConVar("ammo_assaultrifle_max");
	molos = FindConVar("ammo_assaultrifle_max");
	if (GetConVarBool(infiniteon))
	{
		SetConVarInt(rifle, 999999);
		SetConVarInt(smg, 999999);
		SetConVarInt(shotgun, 999999);
		SetConVarInt(hrifle, 999999);
		
		if (GetConVarBool(pipeson))
		{
			SetConVarInt(pipes, 50);
		}
		if (GetConVarBool(moloson))
		{
			SetConVarInt(molos,50);
		}
	}
	else
	{
		SetConVarInt(rifle, 360);
		SetConVarInt(smg, 180);
		SetConVarInt(shotgun, 128);
		SetConVarInt(hrifle, 180);
		SetConVarInt(pipes, 1);
		SetConVarInt(molos, 1);
	}
}*/