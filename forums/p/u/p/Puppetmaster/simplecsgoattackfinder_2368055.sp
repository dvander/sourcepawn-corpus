//Attack Finder


#include <sourcemod> 
#include <cstrike>
#include <clientprefs>
#include <sdktools>
#include <geoip>
//#include <smlib>

#define PLUGIN_VERSION "0.1.1"
#define ADMFLAG_GENERIC				(1<<1)

int startPlayers = 0;
int attackPointer = 0; //current attack position

new String:charSize[1];

new String:namesTemp[32][64]; //Temp buffer to store players in.
new String:ipsTemp[32][64];
new String:steamidsTemp[32][64];
int clientTemp[32];

new String:names[64][32][64]; //Buffer to store players in post attack.
new String:ips[64][32][64];
new String:steamids[64][32][64];
new String:times[64][64];
int dropped[64][32] //0 = player didnt time out | 1 = player timed out
int totalPlayers[64] //size of each array

ConVar sm_simplecsgoattackfinder_trigger


//begin
public Plugin:myinfo =
{
	name = "SimpleCSGOAttackFinder",
	author = "Puppetmaster",
	description = "SimpleCSGOAttackFinder Addon",
	version = PLUGIN_VERSION,
	url = "https://www.gamingzoneservers.com"
};

//called at start of plugin, sets everything up.
public OnPluginStart()
{
	sm_simplecsgoattackfinder_trigger = CreateConVar("sm_simplecsgoattackfinder_trigger", "8", "Number of players lost in a single round to consider as a possible attack."); //default 8
	HookEvent("round_poststart", Event_RoundStart) //new round

	HookEvent("round_end", Event_RoundEnd) //end of round
	RegAdminCmd("simplecsgoattackfinder", dumpAttacks, ADMFLAG_GENERIC, "Outputs the attack log to the admins console", "", 0);
}

public int GetConvar()
{
	char buffer[128]
 
	sm_simplecsgoattackfinder_trigger.GetString(buffer, 128)
 
	return StringToInt(buffer)
}

public Action:Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast){
	endRound();
	return Plugin_Continue;
}

public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast){
	newRound();
	return Plugin_Continue;
}


public newRound(){
	decl String:name[64];
	new String:steamId[64];
	decl String:ip[17];
	startPlayers = 0;
	new maxclients = GetMaxClients()
	if(maxclients > 32) maxclients = 32; //We only have this much allocated space
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			//update buffer
			GetClientName(i, name, sizeof(name));
			Format(namesTemp[startPlayers], 64*sizeof(charSize), "%s", name);

			GetClientIP(i, ip, 16, true);
			Format(ipsTemp[startPlayers], 64*sizeof(charSize), "%s", ip);	

			GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
			Format(steamidsTemp[startPlayers], 64*sizeof(charSize), "%s", steamId);	

			clientTemp[startPlayers] = i; //their client id at the start of the round (ordered)		
			//
			startPlayers++;
		}
	}
}

public endRound(){
	int endPlayers = 0;
	new maxclients = GetMaxClients()
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			endPlayers++;
		}
	}
	if(startPlayers-endPlayers >= GetConvar())
	{
		new String:logAttack[260];
		totalPlayers[attackPointer%64] = startPlayers; //total number of players lost this round
		for(new i=0; i < startPlayers && clientTemp[i] != 0; i++)
		{
			if(IsClientInGame(clientTemp[i])) 
			{
				if(IsClientTimingOut(clientTemp[i])) dropped[attackPointer%64][i] = 2;
				else dropped[attackPointer%64][i] = 1;
			}
			else{
				dropped[attackPointer%64][i] = 0;
			}

			names[attackPointer%64][i] = "";
			StrCat(names[attackPointer%64][i], 64*sizeof(charSize), namesTemp[i]);

			ips[attackPointer%64][i] = "";
			StrCat(ips[attackPointer%64][i], 64*sizeof(charSize), ipsTemp[i]);

			steamids[attackPointer%64][i] = "";
			StrCat(steamids[attackPointer%64][i], 64*sizeof(charSize), steamidsTemp[i]);
		}

		//now print it out
		PrintToServer("Possible Attack Detected");	
		new String:country[45];
		
		for(new i=0; i < startPlayers; i++)
		{
			logAttack = "";
			country = "";
			GeoipCountry(ips[attackPointer%64][i], country, sizeof(country));
			if(dropped[attackPointer%64][i] == 1){
				Format(logAttack, 260*sizeof(charSize), "%s %s %s %s %s", names[attackPointer%64][i], ips[attackPointer%64][i], steamids[attackPointer%64][i], country, "Connected");
			}
			else if(dropped[attackPointer%64][i] == 2){
				Format(logAttack, 260*sizeof(charSize), "%s %s %s %s %s", names[attackPointer%64][i], ips[attackPointer%64][i], steamids[attackPointer%64][i], country, "Timed Out");
			}
			else{
				Format(logAttack, 260*sizeof(charSize), "%s %s %s %s %s", names[attackPointer%64][i], ips[attackPointer%64][i], steamids[attackPointer%64][i], country, "Dropped");			
			}
			LogMessage("%s", logAttack);
			PrintToServer("%s", logAttack);	
		}
		times[attackPointer%64] = "";
		FormatTime(times[attackPointer%64], 260*sizeof(charSize), "%F %r", GetTime());	
		attackPointer++;
	}

}

public Action:dumpAttacks(client, args){
int max = 0;
new String:country[45];
new String:logAttack[305];
if(attackPointer < 64) max = attackPointer;
else max = 64;

//now print it out
PrintToConsole(client, "Printing Log");
for(new a=0; a < max; a++)
{	
	PrintToConsole(client, "Possible Attack Detected");
	PrintToConsole(client, "Players:%d", totalPlayers[a]);
	PrintToConsole(client, "Time:%s", times[a]);
	for(new i=0; i < totalPlayers[a]; i++)
	{
		logAttack = "";
		country = "";
		GeoipCountry(ips[a][i], country, sizeof(country));
		if(dropped[a][i] == 1){
			Format(logAttack, 260*sizeof(charSize), "%s %s %s %s %s", names[a][i], ips[a][i], steamids[a][i], country, "Connected");
		}
		else if(dropped[a][i] == 2){
			Format(logAttack, 260*sizeof(charSize), "%s %s %s %s %s", names[attackPointer%64][i], ips[attackPointer%64][i], steamids[attackPointer%64][i], country, "Timed Out");
		}
		else{
			Format(logAttack, 260*sizeof(charSize), "%s %s %s %s %s", names[a][i], ips[a][i], steamids[a][i], country, "Dropped");			
		}
		PrintToConsole(client, "%s", logAttack);
		/*
		for(new b=1; b <= maxclients; b++)
		{
			if(IsClientInGame(b)) 
			{
				if(GetUserAdmin(b) != INVALID_ADMIN_ID) PrintToConsole(b, "%s", logAttack);
			}
		}*/
	}
}

}
