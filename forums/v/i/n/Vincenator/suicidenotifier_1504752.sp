#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

 
public Plugin:myinfo =
{
	name = "Suicide Notifier",
	author = "Vincenator",
	description = "Prints a (humorous!) message when someone suicides",
	version = "1.0",
	url = ""
}
 
new train_kills
new victorypit_kills
new saw_kills
new train_temp_kills
new Handle:pluginEnabled = INVALID_HANDLE

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath)
	LoadTranslations( "suicidenotifier.phrases" )
	pluginEnabled = CreateConVar("suicidenotifier_enabled", "1", "Whether or not the Suicide Notifier is enabled. 0 is off, 1 is on.", FCVAR_PLUGIN|FCVAR_NOTIFY)
}

public OnMapStart()
{
	train_kills=0
	saw_kills=0
	victorypit_kills=0
}
 

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(pluginEnabled)==1)
	{
		new victim_id = GetEventInt(event, "userid")
		new attacker_id = GetEventInt(event, "attacker")

		new victim = GetClientOfUserId(victim_id)
		new attacker = GetClientOfUserId(attacker_id)

		new feign_death = GetEventInt(event, "death_flags")&TF_DEATHFLAG_DEADRINGER;

		new String:victim_name[MAX_NAME_LENGTH]
		GetClientName(victim, victim_name, sizeof(victim_name))

		new String:attacker_name[MAX_NAME_LENGTH]
		GetClientName(attacker, attacker_name, sizeof(attacker_name))

		new String:mapName[255]
		new bool:isHightower=false
		new bool:isOffblast=false
		new bool:isPayload=false
		new bool:isHoodoo=false
		new bool:isThunder=false

		GetCurrentMap(mapName, sizeof(mapName))

		if (StrContains(mapName, "plr_hightower", true) != -1)
		{
			isHightower=true
		}
		if (StrContains(mapName, "arena_offblast", true) != -1)
		{
			isOffblast=true
		}
		if (StrContains(mapName, "pl_", true) != -1 || StrContains(mapName, "plr_", true) != -1)
		{
			isPayload=true
		}
		if (StrContains(mapName, "hoodoo", true) != -1)
		{
			isHoodoo=true
		}
		if (StrContains(mapName, "pl_thundermountain", true) != -1)
		{
			isThunder=true
		}

		if (victim_id==attacker_id)
		{
			new damagebits = GetEventInt(event, "damagebits")
			if (damagebits==0 && isPayload==true)
			{
				PrintToChatAll("\x03%t", "Payload Death", victim_name)
			}
			else
			{
				PrintToChatAll("\x03%t", "Suicide", victim_name)
			}
		}
		else if (!attacker_id)
		{
			// start keeping track of the toal numbers of kills each thing has
			new damagebits = GetEventInt(event, "damagebits")
			if (damagebits==65536)
			{
				saw_kills++;
				PrintToChatAll("\x03%t", "Sawmill Sawblades", victim_name)
				if (saw_kills%5==0)
				{
					   PrintToChatAll("\x03%t","Sawmill Sawblade Kills", saw_kills)
				}
			}else if (damagebits==1 && isHightower==true){
				PrintToChatAll("\x03%t", "Gravity", victim_name)	
			}
			else if (damagebits==16 || damagebits==1)
			{
				if(!feign_death){
					train_kills++;
					train_temp_kills+=1;
					CreateTimer(3.0, CheckForTrainKills) // three seconds is about how long it takes for a train's front to pass through the playable area
					PrintToChatAll("\x03%t", "Trains", victim_name)
					if (train_kills>1)
					{
						PrintToChatAll("\x03%t", "Train Kills", train_kills)
					}else{
						PrintToChatAll("\x03%t", "Train First Kill")
					}
				}
			}
			else if (damagebits==32)
			{
				PrintToChatAll("\x03%t", "Gravity", victim_name)
			}
			else if (damagebits==16384)
			{
				PrintToChatAll("\x03%t", "Drown", victim_name)
			}
			else if (damagebits==8 && isPayload==true) // for Thundermountain
			{
				PrintToChatAll("\x03%t", "Payload Death", victim_name)
			}
			else if (damagebits==0)
			{
				if (isThunder==true || (isOffblast==true && !feign_death))
				{
					PrintToChatAll("\x03%t", "Gravity", victim_name)
				}
				else if (isHoodoo==true)
				{
					PrintToChatAll("\x03%t", "Payload Death", victim_name)
				}
				else
				{
					if(!feign_death){
						victorypit_kills++;
						PrintToChatAll("\x03%t", "Lumberyard Pit", victim_name)
						if (victorypit_kills%5==0)
						{
							PrintToChatAll("\x03%t", "Lumberyard Pit Kills", victorypit_kills)
						}
					}
				}
			}
			else
			{
				PrintToChatAll("\x03%t", "Other", victim_name)
				// PrintToChatAll("%s was killed by the server %i.", victim_name, GetEventInt(event, "damagebits")) // tells damagebit if unexpected one, for finding new types of death
   			}
   		}
	}
}

public Action:CheckForTrainKills(Handle:timer)
{
	if (GetConVarInt(pluginEnabled)==1)
	{
		if (train_temp_kills==2)
		{
			PrintToChatAll("\x03%t", "Train Double Kill")
		 }
		else if (train_temp_kills==3)
		{
			PrintToChatAll("\x03%t", "Train Triple Kill")
		 }
		else if (train_temp_kills==4)
		{
			PrintToChatAll("\x03%t", "Train Quadruple Kill")
		}
		else if (train_temp_kills>4)
		{
			PrintToChatAll("\x03%t", "Train Multi Kill")
		}
		train_temp_kills=0
	}
}