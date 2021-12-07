/**
* 
* This plugin should stop killed players from chatting
* This could be useful in clanwars/scrims,
* or just against anoying players that like to spam when they are dead
* Dutchmeat
* 
**/

#include <sourcemod>

new Handle:cvarNDT;

public Plugin:myinfo = {
	name = "No Dead Talk Plugin",
	author = "Dutchmeat",
	description = "Stops dead players from chatting",
	version = "1.0.0.0",
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart() 
{
	RegConsoleCmd("say",          chathook);
	RegConsoleCmd("say_team",     chathook);
	cvarNDT = CreateConVar("noDeadTalk","0","If enabled, the players won't be allowed to chat when they are dead");
}


public Action:chathook(client, args)
{
	if(GetConVarInt(cvarNDT))
		return Plugin_Continue;
	
	if (client) {
		new tindex = GetClientTeam(client);
		// index 1 should be the spectators index
		if ((!IsFakeClient(client)) && (IsClientConnected(client)) && tindex != 1) {
			decl String:display_message[192];
			Format(display_message, 192, "\x01 %s", "You are not allowed to talk when you are dead!");
			
			decl Handle:hBf;
			hBf = StartMessageOne("SayText2", client);
			if (hBf != INVALID_HANDLE) {
				BfWriteByte(hBf, 1); 
				BfWriteByte(hBf, 0); 
				BfWriteString(hBf, display_message);
				EndMessage();
			}
			return Plugin_Handled;	
		}
		
		
	}
	return Plugin_Continue;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1043\\ f0\\ fs16 \n\\ par }
*/
