#include <sourcemod>
#include <sdktools>
#include <morecolors>
new fuel[MAXPLAYERS+1]
new fuelreset[MAXPLAYERS+1]
new Handle:player[MAXPLAYERS+1]
//new Handle:g_password;
new Handle:g_fuel;
new Handle:g_fuelreset;

//new Float:Location[3];
//This plugin must not be sold!

public Plugin:myinfo = 
{
	name = "Adv Jetpack",
	author = "ShadowDragon",
	description = "a private plugin request for R@ Blackglade",
	version = "1.0",
	url = ""
	
}

public OnPluginStart()
{
	AutoExecConfig();
	RegConsoleCmd("sm_jet", Command_jet);
	//g_password = CreateConVar("sm_jetpassword", "1", "Password to run the plugin", 0, true, 0.0);
	g_fuel = CreateConVar("sm_jetfuel", "10", "The amount of time the jet pack will last", 0, true, 0.0);
	g_fuelreset = CreateConVar("sm_jetfuelreset", "30", "The amount of time it takes to refule", 0, true, 0.0);
	
	
	
}

public OnMapStart()
{
	PrecacheSound("jetpack/jetpack.wav");	
	PrecacheSound("jetpack/redalert.wav");
	PrecacheSound("jetpack/cloak.wav");
}
public OnClientPutInServer(client)
{
	
}

public Action:Command_jet(client, args)
{
	if (client && IsClientInGame(client))
	{
		//new value;
		//value = GetConVarInt(g_password)
		new peet;
		peet = GetConVarInt(g_fuel)
		
		//if(value == 1013410)
		//{
		if(fuel[client] < 2)
		{
			
			if(fuel[client] < peet)
			{
				SetEntityMoveType(client, MOVETYPE_FLY);
				
				
				CPrintToChat(client, "{darkblue}[JetPack] {cyan}Your Jet Pack Has Been Activated")
				
			}
		}
		if(fuel[client] > peet)
		{
			
			CPrintToChat(client, "{darkblue}[JetPack] {cyan}Refueling in progress!")
			
		}
		
		if(fuel[client] < 2)
		{	
			if (!IsFakeClient(client))
			{
				// 60 * 4 
				player[client] = CreateTimer(1.0, Timer_Show, client, TIMER_REPEAT);
				
			}
			
			EmitSoundToClient(client, "jetpack/jetpack.wav", client, 1);
			
			
			
		}
		
		
		
		
		
		
		//}
		else
		{
			CPrintToChat(client, "{darkblue}[JetPack] {cyan}Plugin will not start till the password is correct!")
		}
		
	}
}

/*stock spark(client)
{
new Handle:event;
Location[0] = GetEventFloat(event,"x");
Location[1] = GetEventFloat(event,"y");
Location[2] = GetEventFloat(event,"z");
TE_SetupSmoke(Location,Location,255,1);
TE_SendToClient(client);
}*/


/*public Action:fuel_f(Handle:timer, any:client)
{	

new peet;
peet = GetConVarInt(g_fuel)
if(fuel[client] == peet)
{
fuel[client] = 0;
SetEntityMoveType(client, MOVETYPE_WALK);
}
fuel[client]++;
}*/

public Action:Timer_Show(Handle:timer, any:client)
{	
	
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new peet;
		peet = GetConVarInt(g_fuel)
		new refuel;
		refuel = GetConVarInt(g_fuelreset)
		if(fuel[client] == peet)
		{
			EmitSoundToClient(client, "jetpack/redalert.wav", client, 2);
			StopSound(client, 1, "jetpack/jetpack.wav");
			CPrintToChat(client, "{darkblue}[JetPack] {cyan}Your Jet Pack Has Run Out Of Fuel!")
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		if(fuel[client] == refuel)
		{
			fuel[client] = 0;
			fuelreset[client] = 0;
			StopSound(client, 2, "jetpack/jetpack.wav");
			EmitSoundToClient(client, "jetpack/cloak.wav", client, 2);
			KillTimer(player[client]);
			CPrintToChat(client, "{darkblue}[JetPack] {cyan}Your Jet Pack Is Now Ready To Use!")
			
			
			
			
		}
		
		//spark(client);
		fuel[client]++;
		fuelreset[client]++;
		
		
		
		
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}
