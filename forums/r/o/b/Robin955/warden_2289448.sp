#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_VERSION   "3.0.1"

new Warden = -1;
new Handle:g_cVar_mnotes = INVALID_HANDLE;
new Handle:g_fward_onBecome = INVALID_HANDLE;
new Handle:g_fward_onRemove = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Le wardens",
	author = "le forgot",
	description = "Jailbreak Warden script",
	version = PLUGIN_VERSION,
	url = "jau"
};

public OnPluginStart() 
{
	// Initialize our phrases
	LoadTranslations("warden.phrases");
	
	// Register our public commands
	RegConsoleCmd("sm_w", BecomeWarden);
	RegConsoleCmd("sm_warden", BecomeWarden);
	RegConsoleCmd("sm_uw", ExitWarden);
	RegConsoleCmd("sm_unwarden", ExitWarden);
	RegConsoleCmd("sm_c", BecomeWarden);
	RegConsoleCmd("sm_commander", BecomeWarden);
	RegConsoleCmd("sm_uc", ExitWarden);
	RegConsoleCmd("sm_uncommander", ExitWarden);
	
	// Register our admin commands
	RegAdminCmd("sm_rw", RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_rc", RemoveWarden, ADMFLAG_GENERIC);
	
	// Hooking the events
	HookEvent("round_start", roundStart); // For the round start
	HookEvent("player_death", playerDeath); // To check when our warden dies :)
	
	// For our warden to look some extra cool
	AddCommandListener(HookPlayerChat, "say");
	
	// May not touch this line
	CreateConVar("sm_warden_version", PLUGIN_VERSION,  "The version of the SourceMod plugin JailBreak Warden, by ecca", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cVar_mnotes = CreateConVar("sm_warden_better_notifications", "0", "0 - disabled, 1 - Will use hint and center text", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_fward_onBecome = CreateGlobalForward("warden_OnWardenCreated", ET_Ignore, Param_Cell);
	g_fward_onRemove = CreateGlobalForward("warden_OnWardenRemoved", ET_Ignore, Param_Cell);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("warden_exist", Native_ExistWarden);
	CreateNative("warden_iswarden", Native_IsWarden);
	CreateNative("warden_set", Native_SetWarden);
	CreateNative("warden_remove", Native_RemoveWarden);

	RegPluginLibrary("warden");
	
	return APLRes_Success;
}

public Action:BecomeWarden(client, args) 
{
	if (Warden == -1) // There is no warden , so lets proceed
	{
		if (GetClientTeam(client) == 3) // The requested player is on the Counter-Terrorist side
		{
			if (IsPlayerAlive(client)) // A dead warden would be worthless >_<
			{
				SetTheWarden(client);
			}
			else // Grr he is not alive -.-
			{
				PrintToChat(client, "Warden ~ %t", "warden_playerdead");
			}
		}
		else // Would be wierd if an terrorist would run the prison wouldn't it :p
		{
			PrintToChat(client, "Warden ~ %t", "warden_ctsonly");
		}
	}
	else // The warden already exist so there is no point setting a new one
	{
		PrintToChat(client, "Warden ~ %t", "warden_exist", Warden);
	}
}

public Action:ExitWarden(client, args) 
{
	if(client == Warden) // The client is actually the current warden so lets proceed
	{
		PrintToChatAll("Warden ~ %t", "warden_retire", client);
		if(GetConVarBool(g_cVar_mnotes))
		{
			PrintCenterTextAll("Warden ~ %t", "warden_retire", client);
			PrintHintTextToAll("Warden ~ %t", "warden_retire", client);
		}
		Warden = -1; // Open for a new warden
		SetEntityRenderColor(client, 255, 255, 255, 255); // Lets remove the awesome color
	}
	else // Fake dude!
	{
		PrintToChat(client, "Warden ~ %t", "warden_notwarden");
	}
}

public Action:roundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	Warden = -1; // Lets remove the current warden if he exist
}

public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); // Get the dead clients id
	
	if(client == Warden) // Aww damn , he is the warden
	{
		PrintToChatAll("Warden ~ %t", "warden_dead", client);
		if(GetConVarBool(g_cVar_mnotes))
		{
			PrintCenterTextAll("Warden ~ %t", "warden_dead", client);
			PrintHintTextToAll("Warden ~ %t", "warden_dead", client);
		}
		SetEntityRenderColor(client, 255, 255, 255, 255); // Lets give him the standard color back
		Warden = -1; // Lets open for a new warden
	}
}

public OnClientDisconnect(client)
{
	if(client == Warden) // The warden disconnected, action!
	{
		PrintToChatAll("Warden ~ %t", "warden_disconnected");
		if(GetConVarBool(g_cVar_mnotes))
		{
			PrintCenterTextAll("Warden ~ %t", "warden_disconnected", client);
			PrintHintTextToAll("Warden ~ %t", "warden_disconnected", client);
		}
		Warden = -1; // Lets open for a new warden
	}
}

public Action:RemoveWarden(client, args)
{
	if(Warden != -1) // Is there an warden at the moment ?
	{
		RemoveTheWarden(client);
	}
	else
	{
		PrintToChatAll("Warden ~ %t", "warden_noexist");
	}

	return Plugin_Handled; // Prevent sourcemod from typing "unknown command" in console
}

public Action:HookPlayerChat(client, const String:command[], args)
{
	if(Warden == client && client != 0) // Check so the player typing is warden and also checking so the client isn't console!
	{
		new String:szText[256];
		GetCmdArg(1, szText, sizeof(szText));
		
		if(szText[0] == '/' || szText[0] == '@' || IsChatTrigger()) // Prevent unwanted text to be displayed.
		{
			return Plugin_Handled;
		}
		
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3) // Typing warden is alive and his team is Counter-Terrorist
		{
			PrintToChatAll("[Warden] %N : %s", client, szText);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public SetTheWarden(client)
{
	PrintToChatAll("Warden ~ %t", "warden_new", client);
	
	if(GetConVarBool(g_cVar_mnotes))
	{
		PrintCenterTextAll("Warden ~ %t", "warden_new", client);
		PrintHintTextToAll("Warden ~ %t", "warden_new", client);
	}
	Warden = client;
	SetEntityRenderColor(client, 0, 0, 255, 255);
	SetClientListeningFlags(client, VOICE_NORMAL);
	
	Forward_OnWardenCreation(client);
}

public RemoveTheWarden(client)
{
	PrintToChatAll("Warden ~ %t", "warden_removed", client, Warden);
	if(GetConVarBool(g_cVar_mnotes))
	{
		PrintCenterTextAll("Warden ~ %t", "warden_removed", client);
		PrintHintTextToAll("Warden ~ %t", "warden_removed", client);
	}
	SetEntityRenderColor(Warden, 255, 255, 255, 255);
	Warden = -1;
	
	Forward_OnWardenRemoved(client);
}

public Native_ExistWarden(Handle:plugin, numParams)
{
	if(Warden != -1)
		return true;
	
	return false;
}

public Native_IsWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if(!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(client == Warden)
		return true;
	
	return false;
}

public Native_SetWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(Warden == -1)
	{
		SetTheWarden(client);
	}
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(client == Warden)
	{
		RemoveTheWarden(client);
	}
}

public Forward_OnWardenCreation(client)
{
	Call_StartForward(g_fward_onBecome);
	Call_PushCell(client);
	Call_Finish();
}

public Forward_OnWardenRemoved(client)
{
	Call_StartForward(g_fward_onRemove);
	Call_PushCell(client);
	Call_Finish();
}