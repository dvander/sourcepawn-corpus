#include <sourcemod>
#include <SteamWorks>
#include <store>
#include <csgocolors>
#pragma newdecls required

ConVar	iGroupID,
		PlayerCredits,
		SpecCredits,
		group_adverts,
		CreditsTime;
Handle	TimeAuto = null;
bool	b_IsMember[MAXPLAYERS+1],
		i_advert[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Steam Group Credits",
	author = "Xines, edited by Wanheda",
	description = "Gives x amount for y seconds if player is on the defined Steam Group",
	version = "1.0",
	url = "https://skygaming.pt/"
};

public void OnPluginStart()
{
	//I Don't know why he did put this
	group_adverts = CreateConVar("sm_group_enable_adverts", "1", "Enables/Disables notifications for all in chat (1=On/0=Off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//If you wan't to disable the text "You received bla bla bla..."
	RegConsoleCmd("sm_sgc", SgcCmd, "(On/Off) Steam Group Credits, Client Announcements");
	
	//Configs
	iGroupID = CreateConVar("sm_groupid_add", "", "Steam Group ID (Replace with yours)", FCVAR_NOTIFY);
	PlayerCredits = CreateConVar("sm_group_credits", "20", "Credits to give per X time, if player is in group.", FCVAR_NOTIFY);
	SpecCredits = CreateConVar("sm_group_spec_credits", "5", "Spectate Credits to give per X time, if player is in group and spectate.", FCVAR_NOTIFY);
	CreditsTime = CreateConVar("sm_group_credits_time", "45", "Time in seconds to deal credits.", FCVAR_NOTIFY);
	
	//Don't Touch
	HookConVarChange(CreditsTime, Change_CreditsTime);
}

public void OnMapStart()
{
	TimeAuto = CreateTimer(CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckPlayers(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsValidClient(i)) addcredits(i);
	
	return Plugin_Continue;
}

void addcredits(int client)
{
	if(b_IsMember[client]) //If he's member of the steam group
	{
		//Get Player Credit Buffer!
		int pcredits = PlayerCredits.IntValue;
		
		//If he's spectating set new value of credits
		if(GetClientTeam(client) == 1) pcredits = SpecCredits.IntValue;
		
		//Give Credits
		Store_SetClientCredits(client, Store_GetClientCredits(client) + pcredits);
		
		//Print to client
		if(group_adverts.BoolValue && i_advert[client])
		CPrintToChat(client, "\x07[CREDITS] \x01You won \x07%i \x01credits for being in the Steam Group", pcredits);
	}
}

public void OnClientPostAdminCheck(int client)
{
	i_advert[client] = true;
	b_IsMember[client] = false;
	SteamWorks_GetUserGroupStatus(client, iGroupID.IntValue);
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer)
{
	int client = UserAuthGrab(authid);
	if (client != -1 && isMember) b_IsMember[client] = true;
	return;
}

int UserAuthGrab(int authid)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			char charauth[64], authchar[64];
			GetClientAuthId(i, AuthId_Steam3, charauth, sizeof(charauth));
			IntToString(authid, authchar, sizeof(authchar));
			if(StrContains(charauth, authchar) != -1) return i;
		}
	}
	
	return -1;
}

public void Change_CreditsTime(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (TimeAuto != null)
	{
		delete TimeAuto;
		TimeAuto = null;
	}

	TimeAuto = CreateTimer(CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action SgcCmd(int client, int args)
{
	if (group_adverts.BoolValue)
	{
		//Do Prints
		if(!i_advert[client]) CPrintToChat(client, "\x07[CREDITS] \x01Announcements > \x07[ON]");
		else CPrintToChat(client, "\x07[CREDITS] \x01Announcements > \x02[OFF]");
		
		//Reverse Bool
		i_advert[client] = !i_advert[client];
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}