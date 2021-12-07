#define		AUTOLOAD_EXTENSIONS
#define		REQUIRE_EXTENSIONS
#include	<steamworks>

#include	<sdktools>
#include	<tf2_stocks>
#include	<f2br_reloaded>

#pragma		semicolon	1
#pragma		newdecls	required

bool HasClientChangedName[MAXPLAYERS+1]=false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)	{
	CreateNative("TF2_IsPlayerPremium", Native_TF2_IsPlayerPremium);
	return	APLRes_Success;
}

//For the natives only.
bool IsPlayerPremium[MAXPLAYERS+1]=false;

public void OnMapStart()	{
	for(int i = 1; i < MaxClients; i++)	{
		if(!IsValidClient(i))
			continue;
		
		CheckStatus(i);
	}
}

void CheckStatus(int client)	{
	//F2P Returns 1.	//P2P Returns 0.
	switch(SteamWorks_HasLicenseForApp(client, 459))	{
		case	0:	IsPlayerPremium[client]=true;
		case	1:	IsPlayerPremium[client]=false;
	}
}

int Native_TF2_IsPlayerPremium(Handle plugin, int params)	{
	if(IsPlayerPremium[GetNativeCell(1)] == true)
		return	true;
	return	false;
}

public	Plugin	myinfo	=	{
	name		=	"[TF2] Free2BeRenamed: Reloaded",
	author		=	"Tk /id/Teamkiller324",
	description	=	"New remade version of Free2BeRenamed from scratch",
	version		=	"1.1.0",
	url			=	"https://steamcommmunity.com/id/Teamkiller324"
}

char	F2PPrefix[64],
		F2PSuffix[64],
		P2PPrefix[64],
		P2PSuffix[64],
		GetReason[64];

ConVar	KickPlayer, KickType, KickReason;

bool	ClientHasTagAlready[MAXPLAYERS+1];

public void OnPluginStart()	{
	ConVar	F2P_Prefix	=	CreateConVar("tf_f2p_prefix",	"[F2P]",	"Free-To-Plays Prefix");
	ConVar	F2P_Suffix	=	CreateConVar("tf_f2p_suffix",	"",			"Free-To-Plays Suffix");
	ConVar	P2P_Prefix	=	CreateConVar("tf_p2p_prefix",	"[P2P]",	"Premium-To-Play Prefix");
	ConVar	P2P_Suffix	=	CreateConVar("tf_p2p_suffix",	"",			"Premium-To-Play Suffix");
	
	KickPlayer	=	CreateConVar("tf_f2br_kick",		"0",	"Should the player be kicked upon joining when they're Premium/F2P? \n0 = No One Will Be Kicked \n1 = Free-to-Play \n2 = Premium",	_, true, 0.0, true, 2.0);
	KickType	=	CreateConVar("tf_f2br_kicktype",	"1",	"How should the player be kicked? \n1 = As soon you connect \n2 = When you get into the server.", _, true, 1.0, true, 2.0);
	KickReason	=	CreateConVar("tf_f2br_kickreason",	"Place a reason here.",	"The kick reason when the user connects");
	
	F2P_Prefix.GetString(F2PPrefix, sizeof(F2PPrefix));
	F2P_Suffix.GetString(F2PSuffix, sizeof(F2PSuffix));
	P2P_Prefix.GetString(P2PPrefix, sizeof(P2PPrefix));
	P2P_Suffix.GetString(P2PSuffix, sizeof(P2PSuffix));
	KickReason.GetString(GetReason, sizeof(GetReason));
	
	AutoExecConfig(true, "free2berenamed_reloaded");
}

public void OnClientAuthorized(int client)	{
	CheckStatus(client);
	if(KickType.IntValue == 1 && !CheckCommandAccess(client, "f2br_kick_immunity", ADMFLAG_SLAY, true))	{
		switch(KickPlayer.IntValue)	{
			case	1:	{
				if(!TF2_IsPlayerPremium(client))
					KickClient(client, GetReason);
			}
			case	2:	{
				if(TF2_IsPlayerPremium(client))
					KickClient(client, GetReason);
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)	{
	if(KickType.IntValue == 2 && !CheckCommandAccess(client, "f2br_kick_immunity", ADMFLAG_SLAY, true))	{
		switch(KickPlayer.IntValue)	{
			case	1:	{
				if(!TF2_IsPlayerPremium(client))
					KickClient(client, GetReason);
			}
			case	2:	{
				if(TF2_IsPlayerPremium(client))
					KickClient(client, GetReason);
			}
		}
	}
	HasClientChangedName[client] = false;
	ClientHasTagAlready[client] = false;
	CreateTimer(0.2, F2BR_SetClientNameTimer, client);
}

Action F2BR_SetClientNameTimer(Handle timer, any client)	{
	if(!IsValidClient(client))
		return;
	
	char getname[MAXPLAYERS+1][256];
	GetClientInfo(client, "name", getname[client], sizeof(getname[]));
	F2BR_SetClientName(client, getname[client]);
	HasClientChangedName[client] = false;
}

public void OnClientSettingsChanged(int client)	{
	if(!IsValidClient(client))
		return;
	
	HasClientChangedName[client] = true;
	char getname[MAXPLAYERS+1][256];
	GetClientInfo(client, "name", getname[client], sizeof(getname[]));
	//Make the name be changed correctly for the correct target.
	
	//Make sure to not spam the tag.
	if(StrContains(getname[client], F2PPrefix, false) != -1)
		ClientHasTagAlready[client] = true;
	else if(StrContains(getname[client], P2PPrefix, false) != -1)
		ClientHasTagAlready[client] = true;
	else
		ClientHasTagAlready[client] = false;
	
	if(HasClientChangedName[client])
		F2BR_SetClientName(client, getname[client]);
	
	//Make sure to not make it go in a loop.
	HasClientChangedName[client] = false;
}

void F2BR_SetClientName(int client, char[] name)	{
	if(!IsValidClient(client))
		return;
		
	char	f2p_newname[96], p2p_newname[96];
	
	//Making sure the name wont turn weird.
	if(StrEqual(F2PSuffix, ""))
		FormatEx(f2p_newname, sizeof(f2p_newname), "%s %s", F2PPrefix, name);
	else
		FormatEx(f2p_newname, sizeof(f2p_newname), "%s %s %s", F2PPrefix, name, F2PSuffix);
	
	if(StrEqual(P2PSuffix, ""))
		FormatEx(p2p_newname, sizeof(p2p_newname), "%s %s", P2PPrefix, name);
	else
		FormatEx(p2p_newname, sizeof(p2p_newname), "%s %s %s", P2PPrefix, name, P2PSuffix);
	
	switch(TF2_IsPlayerPremium(client))	{		
		case	true:	{
			if(!StrEqual(P2PPrefix, "") || !ClientHasTagAlready[client])
				SetClientInfo(client, "name", p2p_newname);
		}
		case	false:	{
			if(!StrEqual(F2PPrefix, "") || !ClientHasTagAlready[client])
				SetClientInfo(client, "name", f2p_newname);
		}
	}
}

stock bool IsValidClient(int client)	{
	if(!IsClientInGame(client))
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(IsFakeClient(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	return	true;
}