#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


static Given[33];





public Plugin:myinfo =
{
	name = "Powerups",
	author = "benjamin1995",
	description = "You got Powerups",
	version = SOURCEMOD_VERSION,
	url = "http://www.bfs-server.de"
};




//Initation:
public OnPluginStart()
{



   	//Events:
	  HookEvent("player_death", EventDeath);
	  HookEvent("player_spawn", EventSpawn, EventHookMode_Pre);
	  CreateConVar("Powerup_version", "1.0", "PowerUp Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

		//Clear Overlay:
public Action:powerup(Handle:Timer, any:Client){

				new String:sname[80];
				GetClientName(Client, sname, 80);	
				
				new random = GetRandomInt(1,301);
				if(random >= 250 && random <= 300 && Given[Client] == 0)
				{
	
					PrintToChatAll("\x04%s got a Speed Powerup +33%.\x04", sname);
					PrintToChat(Client, "\x04You got a Speed Powerup +33%.\x04");
					SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", 1.25);

					Given[Client] == 1;
				} else if(random >= 200 && random <= 250 && Given[Client] == 0)
				{

					PrintToChatAll("\x04%s got a Armor Powerup +200.\x04", sname);
					PrintToChat(Client, "\x04You got a Armor Powerup +200 Suit.\x04");
			    SetEntProp(Client, Prop_Data, "m_ArmorValue", 200, 200);

			    Given[Client] = 1;

				} else if(random >= 150 && random <= 200 && Given[Client] == 0)
				{

					PrintToChatAll("\x04%s got a Health Powerup +150hp.\x04", sname);
					PrintToChat(Client, "\x04You got a Health Powerup +150hp.\x04");
					SetEntityHealth(Client, 150);

				  Given[Client] = 1;
				} else if(random >= 100 && random <= 150 && Given[Client] == 0)
				{

					PrintToChatAll("\x04%s got a Health Powerup +200hp.\x04", sname);
					PrintToChat(Client, "\x04You got a Health Powerup +200hp.\x04");
					SetEntityHealth(Client, 200);
					  					
					Given[Client] = 1;
				} else if(random > 0 && random < 100 && Given[Client] == 0)
				{
				


				} 
  			  					return Plugin_Handled;
}
	
//Death:
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	decl Client, Attacker;
	
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	
	if(Attacker == 0)
	{
  
  					return Plugin_Handled;
  }
  
CreateTimer(0.5, powerup, Attacker);

	}



//Spawn:
public EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	

	//Declare:
	decl Client;
	
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
Given[Client] = 0;
	
	
	}

