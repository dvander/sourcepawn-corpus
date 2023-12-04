#define PLUGIN_VERSION		"1.3"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define DEBUG 0
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] Name Normalizer",
	author = "Dragokas",
	description = "Removes unprinted characters from the player's nickname",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

/*
	ChangeLog:
	
	 1.0 (20-Nov-2020)
	  - Firest release.
	  
	 1.1 (29-Apr-2021)
	  - Added ConVar "sm_name_normalizer_eat_multi_space" - Eat subsequent space characters? (1 - Yes, 0 - No)
	  
	 1.2 (05-Oct-2021)
	  - Added ConVar "sm_name_normalizer_always_hide_nick_change" - to always hide nickname change notification in chat
	  - Added missing sm_name_normalizer.cfg config file.
	  
	 1.3 (15-Sep-2023)
	  - Fixed array out of bounds caused by prohibiting access to a cell beyond the array dimension in SM 1.11.
*/

const int MAXLENGTH_FLAG = 32;

bool g_Proto;
bool g_bLateload;
bool g_bEatMultiSpace;
bool g_bHideNickChange;

ConVar g_hCvarEatMultiSpace;
ConVar g_hCvarHideNickChange;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_name_normalizer_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD | CVAR_FLAGS );
	
	g_hCvarEatMultiSpace 	= CreateConVar("sm_name_normalizer_eat_multi_space",			"1",	"Eat subsequent space characters? (1 - Yes, 0 - No)", CVAR_FLAGS );
	g_hCvarHideNickChange 	= CreateConVar("sm_name_normalizer_always_hide_nick_change",	"0",	"Always hide nickname change notification in chat? (1 - Yes, 0 - No)", CVAR_FLAGS );
	
	AutoExecConfig(true, "sm_name_normalizer");
	
	GetCvars();
	
	g_hCvarEatMultiSpace.AddChangeHook(OnCvarChanged);
	g_hCvarHideNickChange.AddChangeHook(OnCvarChanged);
	
	g_Proto = CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	
	UserMsg SayText2 = GetUserMessageId("SayText2");

	if( SayText2 != INVALID_MESSAGE_ID )
	{
		HookUserMessage(SayText2, UserMessage_SayText2, true);
	}
	else {
		SetFailState("Error loading the plugin, SayText2 is unavailable.");
	}
	
	if( g_bLateload )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEatMultiSpace = g_hCvarEatMultiSpace.BoolValue;
	g_bHideNickChange = g_hCvarHideNickChange.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if( !IsFakeClient(client) )
	{
		ValidateName(client);
	}
}

void ValidateName(int client)
{
	char sName[MAX_NAME_LENGTH+1];
	char sNew[MAX_NAME_LENGTH+1];
	int i, iPrev, j, k, bytes;
	
	if( !GetClientInfo(client, "name", sName, sizeof(sName)-1) )
	{
		return;
	}
	
	#if DEBUG
		PrintToServer("NAME = %s. Len = %i", sName, strlen(sName));
		
		char sRealName[64], sRealName2[64];
		
		Format(sRealName, sizeof sRealName, "%N", client);
		PrintToServer("Real name: %s. Match? %b", sRealName, strcmp(sName, sRealName) == 0);
		
		GetClientName(client, sRealName2, sizeof sRealName2);
		PrintToServer("Real name2: %s. Match? %b", sRealName2, strcmp(sName, sRealName2) == 0);
		
		//SetClientInfo(client, "name", sName);
		
		int c;
		
		while( sName[i] )
		{
			c = sName[i];
			PrintToServer("%i = %i", i, c);
			i++;
		}
	#endif
	
	i = 0;
	while( sName[i] )
	{
		bytes = GetCharBytes(sName[i]);
		
		if( bytes > 1 )
		{
			for( k = 0; k < bytes; k++ )
			{
				sNew[j++] = sName[i++];
			}
		}
		else {
			if( g_bEatMultiSpace )
			{
				if( sName[i] == 32 && iPrev == 32 )
				{
					i++;
					continue;
				}
			}
			
			if( sName[i] >= 32 )
			{
				sNew[j++] = sName[i++];
			}
			else {
				i++;
			}
		}
		iPrev = sName[i-1];
	}
	
	if( strcmp(sName, sNew) != 0 )
	{
		SetClientInfo(client, "name", sNew);
	}
}

public Action UserMessage_SayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int iSender = g_Proto ? PbReadInt(msg, "ent_idx") : BfReadByte(msg);	
	if( iSender <= 0 )
		return Plugin_Continue;
	
	g_Proto ? PbReadBool(msg, "chat") : view_as<bool>(BfReadByte(msg)); //Chat Type
	
	static char sFlag[MAXLENGTH_FLAG];
	switch( g_Proto )
	{
		case true: PbReadString(msg, "msg_name", sFlag, sizeof(sFlag));
		case false: BfReadString(msg, sFlag, sizeof(sFlag));
	}

	if( strcmp(sFlag, "#Cstrike_Name_Change") == 0 )
	{
		RequestFrame(OnNextFrame, GetClientUserId(iSender));
		if( g_bHideNickChange )
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnNextFrame(int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if( client && IsClientInGame(client) )
	{
		ValidateName(client);
	}
}


