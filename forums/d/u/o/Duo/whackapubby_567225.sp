/*
Whack a pubby, by Addict
This script enables friendly fire and allows any admin to tk anyone that isnt an admin
If a lower level damages a higher level, it will filter the damage unless its a backstab which is insta death I can't block(thanks valve) and will in return slay the attacker
At the end of rounds, TKing will be enabled for all, because its funny
The block damage cvar is awesome for doing demoman nade jumps, but is off by default, 8 nades = zoooooooooooooooommmm
The commands "list pubbies" and "list protected" list off users, fun for finding the people to tk and who you cant kill
*/

#include <sourcemod>
#include <string>
#include <sdktools>

#pragma semicolon 1

#define PL_VERSION "1.0.0.0"

public Plugin:myinfo =
{
    name = "Whack-A-Pubby",
    author = "Addict",
    description = "Allows you to TK people lower than you resulting in comedy.",
    version = PL_VERSION,
    url = "http://www.dongdad.com/"
};

new bool:g_allTKOn;
new Handle:g_hEnabled;
new Handle:g_hEndRoundTK;
new Handle:g_BlockSelfDamage;
new Handle:g_hff;
new healthOffset;

public OnPluginStart()
{
	//Convars
	CreateConVar("sm_tf_whackapubby", PL_VERSION, "TF2 Whack-A-Pubby", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("whackapubby_enabled", "1", "Enable whack a pubby.");
	g_hEndRoundTK = CreateConVar("whackapubby_endtk", "1", "Is TK enabled for all at end of round?");
	g_BlockSelfDamage = CreateConVar("whackapubby_blockselfdamage", "0", "Block any damage applied to yourself.");
	g_allTKOn = false;
	
	//Starting CVar Values
	g_hff = FindConVar("mp_friendlyfire");
	SetConVarInt(g_hff,1);
	healthOffset = FindSendPropOffs("CTFPlayer","m_iHealth");
	HookConVarChange(g_hEnabled,pluginSwitch);
	
	//Event Hooks
	HookEvent("player_death", deathPunishmentCheck, EventHookMode_Pre);
	
	HookEvent("player_hurt", filterDamage, EventHookMode_Pre);
	
	HookEvent("teamplay_round_start", endOfRound, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", endOfRound, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate", endOfRound, EventHookMode_PostNoCopy);
	
	HookEvent("teamplay_round_active", startOfRound, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", startOfRound, EventHookMode_PostNoCopy);
	
	//Grab the says for listing command
	RegConsoleCmd("say", listUsers);
	RegConsoleCmd("team_say", listUsers);	
}

public OnPluginEnd()
{
	SetConVarInt(g_hff,0);
}

public pluginSwitch(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
		SetConVarInt(g_hff,0);
	else
		SetConVarInt(g_hff,1);

}

public Action:deathPunishmentCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_allTKOn)
		return Plugin_Continue;
		
	//Slay anyone who kills some one on their team that isnt a pubbie
	new any:userID = GetClientOfUserId(GetEventInt(event,"userid"));
	new any:attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	
	if(userID == 0 || attacker == 0)
		return Plugin_Continue;	
	
	if(GetClientTeam(userID) != GetClientTeam(attacker))
			return Plugin_Continue;		

	new AdminId:userIDAdmin = GetUserAdmin(userID);

	//If attacked is admin, dont want to punish
	if(userIDAdmin == INVALID_ADMIN_ID)
			return Plugin_Continue;			
	
	ForcePlayerSuicide(attacker);
	return Plugin_Continue;		
}

public setHealth(any:giveTo, ammount)
{
	SetEntData(
		giveTo, 
		healthOffset, 
		ammount
		);  		
}

public Action:filterDamage(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(g_allTKOn)
		return Plugin_Continue;

	new any:userID = GetClientOfUserId(GetEventInt(event,"userid"));
	new any:attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	
	//Valves faggotry is massive, and they removed the damage value from the event, so this is the closest/laziest way I can fake it, which means pubbie damage may potentially heal you or jerk friends can hurt you
	new fakeHealth = GetEntData(userID,healthOffset);
	if(fakeHealth > 0)
		fakeHealth = 0;
		
	fakeHealth += 150; //150 seems about right, right?
		
	//Check for self damage cvar
	if(GetConVarInt(g_BlockSelfDamage))
		if(userID == attacker)
		{
			setHealth(userID,fakeHealth);
			return Plugin_Continue;
		}
			
	if(GetConVarInt(g_hEnabled))
	{
		//Cant be same person or healing happens
		if(userID == attacker)
			return Plugin_Continue;			
			
		//Check to make sure they are not on opposite teams
		if(userID == 0 || attacker == 0)
			return Plugin_Continue;	
		
		if(GetClientTeam(userID) != GetClientTeam(attacker))
			return Plugin_Continue;				
		
		new AdminId:userIDAdmin = GetUserAdmin(userID);
		new AdminId:attackerAdmin = GetUserAdmin(attacker);
			
		//If userID isnt admin but attacker does, register damage
		if(userIDAdmin == INVALID_ADMIN_ID && attackerAdmin != INVALID_ADMIN_ID) 
				return Plugin_Continue;		
							
		//If still here, block damage by adding health	
		setHealth(userID,fakeHealth);
	}
	
	return Plugin_Continue;		
}

public Action:endOfRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEndRoundTK))
		g_allTKOn = true;
		
	return Plugin_Continue;
}

public Action:startOfRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_allTKOn = false;
	return Plugin_Continue;
}

public Action:listUsers(client, args)
{

	new String:sayText[64];
	new String:nameList[2048];
	new bool:listingPubbies;
	
	GetCmdArgString(sayText, 64);
		
	if(strncmp("\"list pubbies\"",sayText,14,false) == 0)
		listingPubbies = true;
	else if(strncmp("\"list protected\"",sayText,16,false) == 0)
		listingPubbies = false;
	else
		return Plugin_Continue;
		
	//Dont let the pubbies list out people
	new AdminId:clientAdmin = GetUserAdmin(client);
	if(clientAdmin == INVALID_ADMIN_ID)
		return Plugin_Continue;		
			
	new String:buffer[64];
	new AdminId:userIDAdmin;
	new bool:onFirstName = true;
	
	for (new i=1; i<=GetMaxClients(); i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		userIDAdmin = GetUserAdmin(i);
		
		if(listingPubbies)
		{
			if(userIDAdmin != INVALID_ADMIN_ID)
				continue;
		}
		else
		{
			if(userIDAdmin == INVALID_ADMIN_ID)
				continue;		
		}
		
		if(onFirstName)
			onFirstName = false;
		else
			StrCat(nameList, 1024, ", ");
		
		GetClientName(i,buffer,64);
		StrCat(nameList, 1024, buffer);
		
	}
	
	if(onFirstName)
		PrintToChat(client, "WAP: No users of that type on the server.");
	else
	{
		if(listingPubbies)
			PrintToChat(client,"WAP: Pubbies: %s", nameList);
		else
			PrintToChat(client,"WAP: Protected: %s", nameList);
	}
		
	return Plugin_Handled;
	
}