
#include <sourcemod>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "sm_name",
	author = "Eyal282 ( FuckTheSchool )",
	description = "Players can now change name with !name",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_name", Command_Name, "Changes your name without setinfo name \"New Name\"");
	RegConsoleCmd("sm_oname", Command_oName, "sm_oname <name/#userid> - Finds a target's steam name");
	
	CreateConVar("sm_name_version", PLUGIN_VERSION);
}

public OnClientAuthorized(client)
{
	new String:PermaName[50];
	
	if(!GetClientInfo(client, "secretname", PermaName, sizeof(PermaName)))
		return;
	
	else if(PermaName[0] == EOS)	
		return;
	
	for(new i=1;i <= MaxClients;i++)
	{	
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		else if(!CheckCommandAccess(i, "sm_kick", ADMFLAG_KICK))
			continue;
		
		PrintToChat(i, "\x03Client\x04 %N\x01 has joined with the name\x05 %s.", client, PermaName);
	}
	
	SetClientInfo(client, "name", PermaName);
	
}

public Action:Command_Name(client, args)
{
	if(args <= 0)
	{
		QueryClientConVar(client, "name", ChangeNameToSteamName);
		return Plugin_Handled;
	}
	
	new String:NewName[MAX_NAME_LENGTH];
	GetCmdArgString(NewName, sizeof(NewName));
	
	// Due to a chat bug, a single frame delay is needed.
	new Handle:DP = CreateDataPack();
	
	RequestFrame(TwoTotalFrames, DP);
	
	WritePackCell(DP, GetClientUserId(client));
	WritePackString(DP, NewName);
	
	return Plugin_Handled;
}

public TwoTotalFrames(Handle:DP)
{
	RequestFrame(ChangeName, DP);
}
public ChangeName(Handle:DP)
{
	ResetPack(DP);
	
	new client = GetClientOfUserId(ReadPackCell(DP));
	
	if(client <= 0 || client > MaxClients)
		return;
		
	else if(!IsClientInGame(client))
		return;

	new String:NewName[MAX_NAME_LENGTH];
	ReadPackString(DP, NewName, sizeof(NewName));
	
	CloseHandle(DP);
	
	SetClientInfo(client, "name", NewName);
}

public Action:Command_oName(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_oname <target>");
		return Plugin_Handled;
	}
	new String:targetarg[MAX_NAME_LENGTH];
	GetCmdArgString(targetarg, sizeof(targetarg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			targetarg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{		
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
						
			QueryClientConVar(targetclient, "name", OnSteamNameQueried, GetClientUserId(client))		
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public OnSteamNameQueried(QueryCookie:cookie, targetclient, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], UserId)
{
	new client = GetClientOfUserId(UserId);
	if(result != ConVarQuery_Okay)
	{
		PrintToChat(client, "[SM] Error: Couldn't retrieve %N's steam name", targetclient);
		return;
	}	
	
	if(client <= 0 || client > MaxClients)
		return;
		
	else if(!IsClientInGame(client))
		return;
	
	PrintToChat(client, "\x03%N\x01's Steam name is\x04 %s", targetclient, cvarValue);
}

public ChangeNameToSteamName(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if(result != ConVarQuery_Okay)
	{
		PrintToChat(client, "[SM] Error: Couldn't retrieve your steam name.");
		return;
	}	
	
	if(client <= 0 || client > MaxClients)
		return;
		
	else if(!IsClientInGame(client))
		return;
	
	SetClientInfo(client, "name", cvarValue);
}