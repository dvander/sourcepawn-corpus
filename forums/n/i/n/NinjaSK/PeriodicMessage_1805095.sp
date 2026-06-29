#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "PeriodicMessage",
	author = "NinjaSK",
	description = "Sends a message to everyone in the server periodically",
	version = "1.0"
}

new String:PeriodicMessage0[] = "\x04[MyServer]\x01 Thanks for playing.";
new String:PeriodicMessage1[] = "\x04[MyServer]\x01 If you need help type !admins to see who can assist you.";
new String:PeriodicMessage2[] = "\x04[MyServer]\x01 Make love, not war.";

public OnPluginStart(){

	CreateTimer(250.0, PrintText, 0, TIMER_REPEAT);
	CreateTimer(150.0, PrintText, 1, TIMER_REPEAT);
	CreateTimer(600.0, PrintText, 2, TIMER_REPEAT);

}

public Action:PrintText(Handle:timer, any:numOfMessage){

	switch(numOfMessage){
		case 0:
			PrintToChatAll("%s", PeriodicMessage0);
		case 1:
			PrintToChatAll("%s", PeriodicMessage1);
		case 2:
			PrintToChatAll("%s", PeriodicMessage2);
		}
	return Plugin_Continue;

}