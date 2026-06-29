#include <sourcemod>

#include <tf2>


#pragma semicolon 1

#pragma newdecls required


public Plugin myinfo = 
{
	
	name        = "Scout Dodge",
	
	author      = "Mr. Random",
	
	description = "Scouts can dodge damage with a % change and gain a bonk effect",
	
	version     = "0.0.1",
	
	url         = ">:("

};

ConVar g_chance;

ConVar g_enabled;

ConVar g_effecttime;

ConVar g_minicrit;
ConVar g_crit;

char scoutIDS[MAXPLAYERS + 1] = 

{
	
	" ",
	
	" "
};

char nothing[1] =

{
	
	" "

};


public void OnPluginStart()

{
	
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
	
	HookEvent("player_spawn", Spawn, EventHookMode_Post);
	
	
	g_chance = CreateConVar("sm_dodge_chance", "10", "Scout Dodge chance", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	
	g_chance.IntValue = 10;
	g_effecttime = CreateConVar("sm_dodge_bonk_time", "0.5", "Bonk effect time after a successful dodge", FCVAR_PLUGIN, true, 0.0, false);
	
	g_effecttime.FloatValue = 0.5;
	
	g_enabled = CreateConVar("sm_dodge_enabled", "1", "If the scout dodge plugin is enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_enabled.IntValue = 10;

	g_crit = CreateConVar("sm_dodge_crits", "0", "Can scouts dodge criticals", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_crit.IntValue = 0;
	g_minicrit = CreateConVar("sm_dodge_minicrits", "1", "If the scout dodge plugin is enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_minicrit.IntValue = 0;
}

public Action PlayerHurt(Event event, const char[] name, bool dontBroadcast)

{
	
	int player = event.GetInt("userid");

	//first check if plugin is enabled
	
	if(g_enabled.IntValue == 0)
	{
		
		return Plugin_Continue;
	
	}

	//check minicrit and crit cvars
	if(event.GetBool("crit") == true && g_crit.IntValue == 0)
	{
		return Plugin_Continue;
	}
	if(event.GetBool("minicrit") == true && g_minicrit.IntValue == 0)
	{
		return Plugin_Continue;
	}	
	char playerinarray[64]; 
	playerinarray[0] = player;
	
	if(checkInArray(playerinarray) != -1) //if the person getting hurt is a scoot
	
	{
		
		//PrintToServer("A scout got hurt");
		
		//get a random number
		
		int random = GetRandomInt( 1, 100 );
		
		//if it is less than or equal to the chance
		
		if(random <= g_chance.FloatValue)
		
		{
			
			//PrintToServer("The scout dodged");
			
			//the scout dodges!!!
			
			
			//add bonk
			
			TF2_AddCondition(GetClientOfUserId(player), 14, g_effecttime.FloatValue);
			
			
			//regen the life about to be lost
			
			int currentHP = GetClientHealth(GetClientOfUserId(player));
			
			SetEntityHealth(GetClientOfUserId(player), currentHP + event.GetInt("damageamount"));
			
		
		}
	
	}
	
	
	return Plugin_Continue;

	}

//this makes sure the array is correct at all times

public Action Spawn(Event event, const char[] name, bool dontBroadcast)

{
	
	//PrintToServer("A class was changed");
	
	//get necessary variables
	
	int tfclass = event.GetInt("class");
	
	char user = event.GetInt("userid");
	
	char userinarray[1]; userinarray[0] = user;
	
	
	//if switching to scout
	
	if(tfclass == 1)
	{
		
		//if his id is in the array,
		
		if(checkInArray(userinarray) != -1)
		{
			
				//do nothing
			
				//PrintToServer("someone was already scout and switched back");
		
		}
		
		//otherwise, add his name to the array
		
		else
		
		{
			
			addIDtoArray(user);	
			
			//PrintToServer("someone just switched to scout");
		
		}
	
	}
	
	//if not switching to scout
	
	else
	
	{
		
		//if the user was a scout, replace his name in the array with nothing
		
		if(checkInArray(userinarray) != -1)
		{
			
			scoutIDS[checkInArray(userinarray)] = nothing[0];
			
			//PrintToServer("Someone switched away from scootybootyman");
			
			char name[64]; name[0] = scoutIDS[checkInArray(userinarray)];
			
			//PrintToServer("%s", name);
		
		}
	
	}
}




//checks if string is inside the scoutids array

public int checkInArray(char[] s)

{
	
	int index = 0;
	
	while(index != MAXPLAYERS)
	{
		
		if(scoutIDS[index] == s[0])
		
		{
			
			return index;
		
		}
		
		index ++;
	
	}
	
	return -1;

}

//adds a user id to the array

public void addIDtoArray(char s)

{
	
	char sInArray[1]; sInArray[0] = s;
	
	if(checkInArray(sInArray) != -1)

	{
		
		return;
	
	}
	
	int index = 0;
	
	while(scoutIDS[index] == nothing[0])
	
	{
		
		index ++;
	
	}
	
	scoutIDS[index] = s;

}