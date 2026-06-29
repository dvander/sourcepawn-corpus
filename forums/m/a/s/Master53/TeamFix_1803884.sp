
//Includes:
#include <sourcemod>
#include <sdktools>
#include <teamfix>

//Terminate:
#pragma semicolon		1
#pragma compress		0

//Definitions:
#define PLUGINVERSION		"1.02.43"

//Plugin Info:
public Plugin:myinfo =
{
	name = "Official Team Change Fix",
	author = "Master(D)",
	description = "stuff",
	version = PLUGINVERSION,
	url = ""
};

//Misc:
static bool:CommandOverride[MAXPLAYERS + 1] = {false,...};
static String:GlobalModel[MAXPLAYERS + 1][255];
static ClientTeam[MAXPLAYERS + 1] = {false,...};

//Initation:
public OnPluginStart()
{

	//Declare:
	decl String:GameName[32];

	//Initialize:
	GetGameFolderName(GameName, sizeof(GameName));

	//Not Map:
	if(!StrEqual(GameName, "hl2mp"))
	{

		//Fail State:
		SetFailState("|RolePlay| This Plugin Only Sopports 'HL2DM'");
	}

	//Server Version:
	CreateConVar("sm_change_team_fix", PLUGINVERSION, "show the version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Command Listener:
	AddCommandListener(DisableCommand, "cl_playermodel");

	//Event Hooking:
	HookEvent("player_spawn", Eventspawn_Forward);

	//Handle:
	CreateTimer(5.0, ManageClientTeam, _, TIMER_REPEAT);

	//Chat Hooks:
	HookUserMessage(GetUserMessageId("SayText2"), UserMessageHook, true);

	HookUserMessage(GetUserMessageId("SayText"), UserMessageHook, true);

	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook, true);
}

//Is Extension Loaded:
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{

	//Natives:
	CreateNative("SetClientModel", SetClientModel_CallBack);

	CreateNative("SetClientTeam", SetClientModel_CallBack);

}
//public OnClientPutInServer(Client)
public OnClientPostAdminCheck(Client)
{

	//Timer:
	CreateTimer(1.0, GetConvarDownloader, Client);
}

//Spawn Timer:
public Action:GetConvarDownloader(Handle:Timer, any:Client)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Get CVar:
		QueryClientConVar(Client, "cl_downloadfilter", ConVarQueryFinished:ClientConVar, Client);

		//Initulize:
		ClientTeam[Client] = GetClientTeam(Client);
	}
}

public Action:DisableCommand(Client, const String:Command[], Argc)
{

	//Is Override:
	if(CommandOverride[Client] == true)
	{

		//Return::
		return Plugin_Continue;
	}

	//Return:
	return Plugin_Handled;
}

public ClientConVar(QueryCookie:cookie, Client, ConVarQueryResult:result, const String:CVarName[], const String:newValue[])
{

	//Format:
	Format(GlobalModel[Client], sizeof(GlobalModel[]), "%s", newValue);
}

//ManageTeams:
public Action:ManageClientTeam(Handle:Timer)
{

	//Loop:
	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{

		//Connected:
		if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client) && IsPlayerAlive(Client))
		{

			//Is PreCached:
			if(!IsModelPrecached(GlobalModel[Client]))
			{

				//PreCache:
				PrecacheModel(GlobalModel[Client]);
			}

			//Check:
			ChangeClientTeam(Client, ClientTeam[Client]);

			//Initulize:
			CommandOverride[Client] = true;

			//Command:
			CheatCommand(Client, "cl_playermodel", GlobalModel[Client]);

			//Initialize:
			SetEntityModel(Client, GlobalModel[Client]);

			//Command:
			CheatCommand(Client, "cl_playermodel", GlobalModel[Client]);

			//Initulize:
			CommandOverride[Client] = false;
		}
	}
}

//EventDeath Farward:
public Action:Eventspawn_Forward(Handle:Event, const String:name[], bool:dontBroadcast)
{

	//Initialize:
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	//FakeClient:
	if(IsFakeClient(Client)) return Plugin_Continue;

	//Timer:
	CreateTimer(0.5, ProccessModel, Client);

	//Return:
	return Plugin_Continue;
}

//Remove Weapons:
public Action:ProccessModel(Handle:Timer, any:Client)
{

	//Connected:
	if(Client > 0 && IsClientInGame(Client) && IsClientConnected(Client) && IsPlayerAlive(Client))
	{

		//Is PreCached:
		if(!IsModelPrecached(GlobalModel[Client]))
		{

			//PreCache:
			PrecacheModel(GlobalModel[Client]);
		}

		//Set Client Model:
		SetEntityModel(Client,  GlobalModel[Client]);
	}
}

//Bipass Cheats:
public bool:CheatCommand(Client, const String:command[], const String:arguments[])
{

	//Connected:
	if(IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Define:
		new admindata = GetUserFlagBits(Client);

		//Set Client Flag Bits:
		SetUserFlagBits(Client, ADMFLAG_ROOT);

		//Define:
		new flags = GetCommandFlags(command);

		//Set Client Flags:
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);

		//Command:
		ClientCommand(Client, "\"%s\" \"%s\"", command, arguments);

		//Set Client Flags:
		SetCommandFlags(command, flags);

		//Set Client Flag Bits:
		SetUserFlagBits(Client, admindata);

		//Return:
		return true;
	}

	//Return:
	return false;
}

public SetClientModel_CallBack(Handle:plugin, numParams)	
{

	//Get Client:
	new Client = GetNativeCell(1);

	//Declare:
	decl String:str[256];

	//Get String:
	GetNativeString(2, str, sizeof(str));

	//Format:
	Format(GlobalModel[Client], sizeof(GlobalModel[]), "%s", str);
}

public SetClientTeam_CallBack(Handle:plugin, numParams)	
{

	//Get Client:
	new Client = GetNativeCell(1);

	//Get Client:
	new Team = GetNativeCell(2);

	//Initulize:
	ClientTeam[Client] = Team;
}

public Action:UserMessageHook(UserMsg:MsgId, Handle:hBitBuffer, const iPlayers[], iNumPlayers, bool:bReliable, bool:bInit)
{

	//Get Info:
	BfReadByte(hBitBuffer);

	BfReadByte(hBitBuffer);

	//Declare:
	decl String:strMessage[1024];

	//Read UserMessage
	BfReadString(hBitBuffer, strMessage, sizeof(strMessage));

	//Check:
	if(StrContains(strMessage, "before trying to switch", false) != -1)
	{

		//Return:
		return Plugin_Handled;
	}

	//Return:
	return Plugin_Continue;
}