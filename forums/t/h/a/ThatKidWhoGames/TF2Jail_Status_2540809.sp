#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2jail>
#include <morecolors>

public Plugin:myinfo = 
{
	name = "[TF2Jail] Status Plugin",
	author = "Sgt. Gremulock",
	description = "Allows the use of typing !status in chat to print out a list of alive rebels, non-rebels, guards, and a warden.",
	version = "1.0",
	url = "https://grem-co.com/"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_status", Command_Status);
}

public Action Command_Status(client, args)
{
	for(new i = 1; i <= MaxClients; i++)
	{
    	if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i) && TF2Jail_IsRebel(i) && GetClientTeam(i) == 2)
    	{
    		new String:rebels[MAX_NAME_LENGTH];
    		GetClientName(i, rebels, sizeof(rebels));
        	CPrintToChat(client, "%s {red}(Rebel)", rebels);
    	}
    	else if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i) && !TF2Jail_IsRebel(i) && GetClientTeam(i) == 2)
    	{
    		new String:nonrebels[MAX_NAME_LENGTH];
    		GetClientName(i, nonrebels, sizeof(nonrebels));
        	CPrintToChat(client, "%s {orange}(Non-Rebel)", nonrebels);   		
    	}
    	else if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i) && TF2Jail_IsWarden(i) && GetClientTeam(i) == 3)
    	{
    		new String:warden[MAX_NAME_LENGTH];
    		GetClientName(i, warden, sizeof(warden));
        	CPrintToChat(client, "%s {blue}(Warden)", warden);   		
    	}
    	else if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i) && !TF2Jail_IsWarden(i) && GetClientTeam(i) == 3)
    	{
    		new String:guards[MAX_NAME_LENGTH];
    		GetClientName(i, guards, sizeof(guards));
        	CPrintToChat(client, "%s {cyan}(Guard)", guards);   		
    	}
    	else if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i) && TF2Jail_IsFreeday(i) && GetClientTeam(i) == 2)
    	{
    		new String:freedays[MAX_NAME_LENGTH];
    		GetClientName(i, freedays, sizeof(freedays));
        	CPrintToChat(client, "%s {lime}(Freeday)", freedays);   		
    	}
	}
	return Plugin_Handled;
}