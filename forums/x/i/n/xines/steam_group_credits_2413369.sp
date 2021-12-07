#include <sourcemod>
#include <SteamWorks>
#include <store>

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
	author = "Xines",
	description = "Deals x amount of credits per x amount of secounds",
	version = "1.3",
	url = ""
};

public void OnPluginStart()
{
	//Chat print on/off for all players
	group_adverts = CreateConVar("sm_group_enable_adverts", "1", "Enables/Disables notifications for all in chat (1=On/0=Off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Chat print on/off Client
	RegConsoleCmd("sm_sgc", SgcCmd, "(On/Off) Steam Group Credits, Client Announcements");
	
	//Configs
	iGroupID = CreateConVar("sm_groupid_add", "0000000", "Steam Group ID (Replace with yours)", FCVAR_NOTIFY);
	PlayerCredits = CreateConVar("sm_group_credits", "5", "Credits to give per X time, if player is in group.", FCVAR_NOTIFY);
	SpecCredits = CreateConVar("sm_group_spec_credits", "2", "Spectate Credits to give per X time, if player is in group and spectate.", FCVAR_NOTIFY);
	CreditsTime = CreateConVar("sm_group_credits_time", "60", "Time in seconds to deal credits.", FCVAR_NOTIFY);
	
	//Don't Touch
	HookConVarChange(CreditsTime, Change_CreditsTime);
}

public void OnMapStart()
{
	TimeAuto = CreateTimer(CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT);
}

public Action CheckPlayers(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		addcredits(i);
	}
	return Plugin_Continue;
}

void addcredits(int client)
{
	if(IsClientInGame(client) && b_IsMember[client]) //ingame + member
	{
		//Get Player Credit Buffer!
		int pcredits = PlayerCredits.IntValue;
		
		//If spectate set new value of credits
		if(GetClientTeam(client) == 1) pcredits = SpecCredits.IntValue;
		
		//Give Credits
		Store_SetClientCredits(client, Store_GetClientCredits(client) + pcredits);
		
		//Print to client
		if(group_adverts.BoolValue && i_advert[client])
		{
			PrintToChat(client, "​\x01[SM] You received \x04%i\x01 credits for being member in our \x04steam group!", pcredits);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	i_advert[client] = true;
	b_IsMember[client] = false;
	if(!SteamWorks_GetUserGroupStatus(client, iGroupID.IntValue))
	{
		LogError("[SGC] Could not get user group for user: %N", client);
	}
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer)
{
	int client = UserAuthGrab(authid);
	if (client != -1 && isMember)
	{
		b_IsMember[client] = true;
	}
	return;
}

int UserAuthGrab(int authid)
{
	char charauth[64], authchar[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientAuthId(i, AuthId_Steam3, charauth, sizeof(charauth)))
		{
			IntToString(authid, authchar, sizeof(authchar));
			if(StrContains(charauth, authchar) != -1)
			{
				return i;
			}
		}
	}
	
	return -1;
}

public void Change_CreditsTime(Handle cvar, const char[] oldVal, const char[] newVal)
{
	delete TimeAuto;
	TimeAuto = CreateTimer(CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT);
}

public Action SgcCmd(int client, int args)
{
	if (group_adverts.BoolValue)
	{
		//Reverse Bool
		i_advert[client] = !i_advert[client];
		
		//Do Prints
		PrintToChat(client, "​\x04[\x01Steam Group Credits\x04] \x01Announcements \x04%s", i_advert[client] ? "[ON]":"[OFF]");
	}
	return Plugin_Handled;
}