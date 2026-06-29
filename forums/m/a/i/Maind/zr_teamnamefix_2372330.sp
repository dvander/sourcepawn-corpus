#include <sourcemod>
#include <zombiereloaded>
 
public Plugin:myinfo =
{
 name = "Zombie Teamname Fix",
 author = "theSaint",
 description = "Fix mp_teamname_? command for zombiereloaded",
 version = "1.0",
 url = "http://propaganda-go.pl"
};

ConVar cvmp_teamname_1; 
ConVar cvmp_teamname_2;
char name_humans[128];
char name_zombies[128];

public void OnPluginStart()
{
	cvmp_teamname_1 = FindConVar("mp_teamname_1");
	cvmp_teamname_2 = FindConVar("mp_teamname_2");
	cvmp_teamname_1.GetString(name_humans, 128);
	cvmp_teamname_2.GetString(name_zombies, 128);
	
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{	
	//Becouse Event_RoundStart is fired after first player join team
	//This makes this player see correct names on a team choosing screen
	cvmp_teamname_2.SetString(name_humans);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Teamnames change after roundstart (No zombies - Humans in both teams)
	cvmp_teamname_2.SetString(name_humans);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{	
	//Here we change teamnames after the first infection
	if (motherInfect)
	{
		cvmp_teamname_2.SetString(name_zombies);
	}
}