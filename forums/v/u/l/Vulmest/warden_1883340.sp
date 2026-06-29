#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define Commander_VERSION   "1.7.0"
#define TEAM_CTS 3

new Warden = -1;

public Plugin:myinfo = {
	name = "JailBreak Warden",
	author = "ecca",
	description = "Jailbreak Warden script",
	version = Commander_VERSION,
	url = "ffac.eu"
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
	
	// Register our admin commands
	RegAdminCmd("sm_rw", RemoveWarden, ADMFLAG_GENERIC);
	
	// Hooking the events
	HookEvent("round_start", roundStart); // For the round start
	HookEvent("player_death", playerDeath); // To check when our warden dies :)
	
	// For our warden to look some extra cool
	AddCommandListener(HookPlayerChat, "say");
	
	// May not touch this line
	CreateConVar("sm_warden_version", Commander_VERSION,  "The version of the SourceMod plugin JailBreak Warden, by ecca", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
}

public Action:BecomeWarden(client, args) 
{
	if (Warden == -1) // There is no warden , so lets proceed
	{
		if (GetClientTeam(client) == TEAM_CTS) // The requested player is on the Counter-Terrorist side
		{
			if (IsPlayerAlive(client)) // A dead warden would be worthless >_<
			{
				CPrintToChatAll("{springgreen}Warden ~ {white}%t", "warden_new", client);
				Warden = client; // Set the client to warden
				SetEntityRenderColor(client, 0, 0, 255, 255); // Lets give him some special blue color
				SetClientListeningFlags(client, VOICE_NORMAL); // Will unmute the player if he is muted
			}
			else // Grr he is not alive -.-
			{
				CPrintToChat(client, "{springgreen}Warden ~ {white}%t", "warden_playerdead");
			}
		}
		else // Would be wierd if an terrorist would run the prison wouldn't it :p
		{
			CPrintToChat(client, " Warden ~ {white}%t", "warden_ctsonly");
		}
	}
	else // The warden already exist so there is no point setting a new one
	{
		CPrintToChat(client, " Warden ~ {white}%t", "warden_exist", Warden);
	}
}

public Action:ExitWarden(client, args) 
{
	if(client == Warden) // The client is actually the current warden so lets proceed
	{
		CPrintToChatAll("Warden ~ {white}%t", "warden_retire", client);
		Warden = -1; // Open for a new warden
		SetEntityRenderColor(client, 255, 255, 255, 255); // Lets remove the awesome color
	}
	else // Fake dude!
	{
		CPrintToChat(client, " Warden ~ {white}%t", "warden_notwarden");
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
		CPrintToChatAll(" Warden ~ {white}%t", "warden_dead", client);
		SetEntityRenderColor(client, 255, 255, 255, 255); // Lets give him the standard color back
		Warden = -1; // Lets open for a new warden
	}
}

public OnClientDisconnect(client)
{
	if(client == Warden) // The warden disconnected, action!
	{
		CPrintToChatAll(" Warden ~ {white}%t", "warden_disconnected");
		Warden = -1; // Lets open for a new warden
	}
}

public Action:RemoveWarden(client, args)
{
	if(Warden != -1) // Is there an warden at the moment ?
	{
		CPrintToChatAll(" Warden ~ {white}%t", "warden_removed", client, Warden);
		SetEntityRenderColor(Warden, 255, 255, 255, 255); // Give his normal color back
		Warden = -1; // Lets open for a new warden
	}
	else
	{
		CPrintToChatAll(" Warden ~ {white}%t", "warden_noexist");
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
		
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_CTS) // Typing warden is alive and his team is Counter-Terrorist
		{
			CPrintToChatAll(" [Warden]  %N: {white}%s", client, szText);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}