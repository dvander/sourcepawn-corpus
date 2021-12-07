#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "2.0.0"

#pragma semicolon 1

new bool:allow[MAXPLAYERS+1];
new Float:checkpoint[MAXPLAYERS+1][3];
new tele_saved[MAXPLAYERS+1];
new Handle:sm_bhopcommands_weapons = INVALID_HANDLE;

 
public Plugin:myinfo =
{
	name = "Bunnyhop Commands",
	author = "TimeBomb",
	description = "Bunnyhop Commands.",
	version = PLUGIN_VERSION,
	url = ""
};
 
public OnPluginStart()
	{
	RegConsoleCmd("sm_superlowgrav", Command_SuperLowgravity, "Super Low Gravity for Client.");
	RegConsoleCmd("sm_lowgrav", Command_Lowgravity, "Low Gravity for Client.");
	RegConsoleCmd("sm_highgrav", Command_Highgravity, "High Gravity for Client..");
	RegConsoleCmd("sm_normalgrav", Command_Normalgravity, "Normal Gravity for Client.");
	RegConsoleCmd("sm_superlowgravity", Command_SuperLowgravity, "Super Low Gravity for Client.");
	RegConsoleCmd("sm_lowgravity", Command_Lowgravity, "Low Gravity for Client.");
	RegConsoleCmd("sm_highgravity", Command_Highgravity, "High Gravity for Client.");
	RegConsoleCmd("sm_normalgravity", Command_Normalgravity, "Normal Gravity for Client.");
	RegConsoleCmd("sm_slg", Command_SuperLowgravity, "Super Low Gravity for Client.");
	RegConsoleCmd("sm_lg", Command_Lowgravity, "Low Gravity for Client.");
	RegConsoleCmd("sm_hg", Command_Highgravity, "High Gravity for Client.");
	RegConsoleCmd("sm_ng", Command_Normalgravity, "Normal Gravity for Client.");
	RegConsoleCmd("sm_r", Command_reviver, "Respawning Client, Usable for Restarting the Map.");
	RegConsoleCmd("sm_restart", Command_reviver, "Respawning Client, Usable for Restarting the Map.");
	RegConsoleCmd("sm_commands", Command_Commands, "Commands Menu.");
	RegConsoleCmd("sm_comms", Command_Commands, "Commands Menu.");
	RegConsoleCmd("sm_guns", Command_Guns, "Guns Menu.");
	RegConsoleCmd("sm_knife", Command_knife, "Spawns a Knife, Usable to Maps without Knifes.");
	RegConsoleCmd("sm_kn", Command_knife, "Spawns a Knife, For a Fat lazy Man, Usable to Maps without Knifes.");
	RegConsoleCmd("sm_usp", Command_usp, "Spawns a Usp Pistol.");
	RegConsoleCmd("sm_awp", Command_awp, "Spawns a AWP Sniper Rifle.");
	RegConsoleCmd("sm_deagle", Command_deagle, "Spawns a Desert Eagle Pistol.");
	RegConsoleCmd("sm_scout", Command_scout, "Spawns a Scout Sniper Rifle.");
	RegConsoleCmd("sm_save", Command_save, "Saving a Checkpoint on The Client Position.");
	RegConsoleCmd("sm_tele", Command_tele, "Teleport to your Saved Checkpoint.");
	RegConsoleCmd("sm_s", Command_save, "Saving a Checkpoint on The Client Position.");
	RegConsoleCmd("sm_t", Command_tele, "Teleport to your Saved Checkpoint.");
	RegConsoleCmd("sm_gravitycommands", Command_gravity, "Gravity Commands.");
	RegConsoleCmd("sm_grav", Command_gravity, "Gravity Commands.");
	sm_bhopcommands_weapons = CreateConVar("sm_bhopcommands_weapons", "1", "Enable Weapon Spawning? [1 - True] [0 - False].");
	CreateConVar("sm_bhopcommands_version", PLUGIN_VERSION, "Bunnyhop Commands Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ServerCommand("sv_enablebunnyhopping 1");
	ServerCommand("sv_enableboost 1");
	}
	
public OnMapStart()
{	
	for(new i = 0; i <= MAXPLAYERS; i++){
		allow[i]=true;
	}
	
}	
	
public Action:Command_Lowgravity(client, args)
{
	PrintToChat(client, "\x04[SM]\x01 You have Just Changed Your Gravity Lower!");
	SetEntityGravity(client, 0.5);
}
	
public Action:Command_Highgravity(client, args)
{
	PrintToChat(client, "\x04[SM]\x01 You have Just Changed Your Gravity Higher!");
	SetEntityGravity(client, 1.5);
}
	
public Action:Command_Normalgravity(client, args)
{
	PrintToChat(client, "\x04[SM]\x01 You have Just Changed Your Gravity to Normal!");
	SetEntityGravity(client, 1.0);
}
	
public Action:Command_SuperLowgravity(client, args)
{
	PrintToChat(client, "\x04[SM]\x01 You have Just Changed Your Gravity to \x03SUPERLOWGRAVITYYY!");
	SetEntityGravity(client, 0.2);
}
	
public Action:Command_Commands(client, args)
{
	PrintToChat(client, "\x04[SM]\x02 Commands!");
	PrintToChat(client, "");
	PrintToChat(client, "\x04[SM]\x01 !commands / !comms");
	PrintToChat(client, "\x04[SM]\x01 !gravitycommands / !grav - Gravity Menu!");
	PrintToChat(client, "\x04[SM]\x01 !r / !restart - Reviving Yourself, Usable to Restart the Map!");
	PrintToChat(client, "\x04[SM]\x01 !save / !s - Saving a Checkpoint!");
	PrintToChat(client, "\x04[SM]\x01 !tele / !t - Teleporting to a Checkpoint!");
	PrintToChat(client, "\x04[SM]\x01 !guns - Guns Menu!");
}
	
public Action:Command_reviver(client, args)
{
	PrintToChat(client, "\x04[SM]\x01 Have Fun!");
	CS_RespawnPlayer(client);
}
	
public Action:Command_Guns(client, args)
{
	PrintToChat(client, "\x04[SM]\x02 Guns Menu!");
	PrintToChat(client, "\x04[SM]\x01 !scout - Spawns an Scout Sniper Rifle.");
	PrintToChat(client, "\x04[SM]\x01 !awp - Spawns an Magnum Sniper Rifle [Awp].");
	PrintToChat(client, "\x04[SM]\x01 !deagle - Spawns an Desert Eagle.");
	PrintToChat(client, "\x04[SM]\x01 !usp - Spawns an USP.");
	PrintToChat(client, "\x04[SM]\x01 !kn / knife - Map Without Knifes? Spawn one!");
}
	
public Action:Command_gravity(client, args)
{
	PrintToChat(client, "\x04[SM]\x01 !lowgrav / !lowgravity / !lg - Low Gravity");
	PrintToChat(client, "\x04[SM]\x01 !highgrav / !highgravity / !hg - High Gravity");
	PrintToChat(client, "\x04[SM]\x01 !normalgrav / !normalgravity / !ng - Normal Gravity");
	PrintToChat(client, "\x04[SM]\x01 !superlowgrav / !superlowgravity / !slg - \x03SUPER LOW GRAVITYYY");
}
	
public Action:Command_knife(client,args)
{
	if(GetConVarBool(sm_bhopcommands_weapons))
	{
		if(allow[client]==true)
		{
		GivePlayerItem(client, "weapon_knife");
		allow[client]=false;
		CreateTimer(30.0, Action_weaponspawner, client);
		}
		else
		{
		PrintToChat(client, "\x04[SM]\x01 You must wait 30 seconds between Spawning Weapons, Abuse will get you banned.");
		}
		
	}
	else
	{
	PrintToChat(client, "\x04[SM]\x01 Weapon Spawning is not Enabled!");
	}
}
	
public Action:Command_usp(client,args)
{
	if(GetConVarBool(sm_bhopcommands_weapons))
	{
		if(allow[client]==true)
		{
		GivePlayerItem(client, "weapon_usp");
		allow[client]=false;
		CreateTimer(30.0, Action_weaponspawner, client);
		}
		else
		{
		PrintToChat(client, "\x04[SM]\x01 You must wait 30 seconds between Spawning Weapons, Abuse will get you banned.");
		}
		
	}
	else
	{
	PrintToChat(client, "\x04[SM]\x01 Weapon Spawning is not Enabled!");
	}
}

public Action:Command_deagle(client,args)
{
	if(GetConVarBool(sm_bhopcommands_weapons))
	{
		if(allow[client]==true)
		{
		GivePlayerItem(client, "weapon_deagle");
		allow[client]=false;
		CreateTimer(30.0, Action_weaponspawner, client);
		}
		else
		{
		PrintToChat(client, "\x04[SM]\x01 You must wait 30 seconds between Spawning Weapons, Abuse will get you banned.");
		}
		
	}
	else
	{
	PrintToChat(client, "\x04[SM]\x01 Weapon Spawning is not Enabled!");
	}
}

public Action:Command_awp(client,args)
{
	if(GetConVarBool(sm_bhopcommands_weapons))
	{
		if(allow[client]==true)
		{
		GivePlayerItem(client, "weapon_awp");
		allow[client]=false;
		CreateTimer(30.0, Action_weaponspawner, client);
		}
		else
		{
		PrintToChat(client, "\x04[SM]\x01 You must wait 30 seconds between Spawning Weapons, Abuse will get you banned.");
		}
		
	}
	else
	{
	PrintToChat(client, "\x04[SM]\x01 Weapon Spawning is not Enabled!");
	}
}

public Action:Command_scout(client,args)
{
	if(GetConVarBool(sm_bhopcommands_weapons))
	{
		if(allow[client]==true)
		{
		GivePlayerItem(client, "weapon_scout");
		allow[client]=false;
		CreateTimer(30.0, Action_weaponspawner, client);
		}
		else
		{
		PrintToChat(client, "\x04[SM]\x01 You must wait 30 seconds between Spawning Weapons, Abuse will get you banned.");
		}
		
	}
	else
	{
	PrintToChat(client, "\x04[SM]\x01 Weapon Spawning is not Enabled!");
	}
}

public Action:Action_weaponspawner(Handle:timer, any:client)
{
	allow[client]=true;
}

public Action:Command_save(client, args)
{
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", checkpoint[client]);
	tele_saved[client] = 1;
	PrintToChat(client, "\x04[SM]\x01 CheckPoint Saved.");
}

public Action:Command_tele(client, args)
{
	TeleportEntity(client, checkpoint[client], NULL_VECTOR, NULL_VECTOR);
	PrintToChat(client, "\x04[SM]\x01 Teleported to Checkpoint.");
}