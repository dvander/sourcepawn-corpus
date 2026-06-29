#include <sourcemod>

#define PLUGIN_VERSION "1.0"

#define MAX_SURVIVORS 4

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define NUM_ACHIEVEMENTS 4

// L4D internal codes for damage types
#define ZOMBIE_DAMAGE 128
#define WITCH_DAMAGE 4

// Status of whether or not this achievement has been prevented
new bool:achievement_prevented[NUM_ACHIEVEMENTS];

// Names of all the achievements this plugin will track
new String:achievement_names[][] = {
	"Safety First",
	"Stomach Upset",
	"Untouchables",
	"Nothing Special"
};

// Achievements that require starting from the first map of the campaign
new String:achievement_entire_campaign[][] = {
	"Safety First",
	"Stomach Upset",
	"Nothing Special"
};

// Achievements that can be acquired in a single round, without playing the entire campaign
new String:achievement_single_round[][] = {
	"Untouchables"
};

// Is this map campaign or versus
new bool:isCampaignMap = false;

// Are starting a new level or transitioning through the same campaign
new EndRoundCounter = 0;

// Have we hooked events that need unhooking?
new bool:hookedEvents = false;

// Keep track of condition variables that are required for achievements
new bool:hasContactedRescue = false;
new playersCurrentlyVomitted[MAX_SURVIVORS];

// Console variables
new Handle:cvPluginEnabled;
new Handle:cvShowConnectMessage;

public Plugin:myinfo =
{
	name = "Left 4 Dead Achievement Notifier",
	author = "Fexii",
	description = "Displays notifications about achievement status changes",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead",false)) SetFailState("This plugin is for left4dead only.");

	LoadTranslations("achievementnotifier.phrases");
	
	CreateConVar("achievement_notifier_version", PLUGIN_VERSION, "Achievement Notifier", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvPluginEnabled = CreateConVar("sm_achievement_notify", "1", "Toggle achievement tracking by this plugin. Requires map restart after changing this cvar.");
	cvShowConnectMessage = CreateConVar("sm_achievement_notify_connect_message", "1", "Show a message to users who connect that notifies them about the !achievements command.");
	
	RegConsoleCmd("sm_achievements", Command_DisplayAchievements, "Displays achievement progress for the current game.");
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}
 
public Action:Command_DisplayAchievements(client, args)
{ 
	if (GetConVarBool(cvPluginEnabled))
		DisplayAchievements(client);
	
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	if (GetConVarBool(cvPluginEnabled) &&
	    GetConVarBool(cvShowConnectMessage) &&
		IsClientInGame(client) &&
		isCampaignMap)
		PrintToChat(client, "[L4D] %t", "Connect Message");
}

/** Called whenever a new round starts **/
public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvPluginEnabled))
		return;

	decl String:map[32];
	GetCurrentMap(map, sizeof(map));
	
	// Determine whether this is a campaign map or not
	decl String:gamemode[32];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	
	if (!StrEqual(gamemode, "coop"))
		isCampaignMap = false;
	else
	{
		isCampaignMap = true;
		
		// Hook events needed for tracking achievements
		if (!hookedEvents)
		{
			HookEventEx("map_transition", OnRoundEnd, EventHookMode_PostNoCopy);
			HookEventEx("player_now_it", OnVomit, EventHookMode_Post);
			HookEventEx("player_no_longer_it", OnVomitEnd, EventHookMode_Post);
			HookEventEx("finale_start", OnRescueSummoned, EventHookMode_PostNoCopy);
			HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post);
			HookEventEx("player_incapacitated", OnPlayerHurt, EventHookMode_Post);
			hookedEvents = true;
		}
	
		// Reset achievements that restart every round
		hasContactedRescue = false;
		for (new i = 0; i < NUM_ACHIEVEMENTS; ++i)
			for (new j = 0; j < sizeof(achievement_single_round); ++j)
				if (StrEqual(achievement_names[i], achievement_single_round[j]))
				{
					achievement_prevented[i] = false;
					break;
				}
		
		// If we are at the first stage of the campaign, reset all achievements
		if (StrContains(map, "01") != -1)
		{
			EndRoundCounter = 0;
			for (new i = 0; i < NUM_ACHIEVEMENTS; ++i) achievement_prevented[i] = false;
		}		
		// If we are not on the first stage and didn't beat the previous stage
		else if ( ((StrContains(map, "02") != -1) && (EndRoundCounter != 1))
				|| ((StrContains(map, "03") != -1) && (EndRoundCounter != 2))
				|| ((StrContains(map, "04") != -1) && (EndRoundCounter != 3))
				|| ((StrContains(map, "05") != -1) && (EndRoundCounter != 4)))
		{
		
			// Then prevent achievements that require being present the entire campaign
			for (new i = 0; i < NUM_ACHIEVEMENTS; ++i)
				for (new j = 0; j < sizeof(achievement_entire_campaign); ++j)
					if (StrEqual(achievement_names[i], achievement_entire_campaign[j]))
					{
						achievement_prevented[i] = true;
						break;
					}
		}
	}
}

/** Unhook events whenever the map changes **/
public OnMapEnd()
{
	if (hookedEvents)
	{
		UnhookEvent("map_transition", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("player_now_it", OnVomit, EventHookMode_Post);
		UnhookEvent("player_no_longer_it", OnVomitEnd, EventHookMode_Post);
		UnhookEvent("finale_start", OnRescueSummoned, EventHookMode_PostNoCopy);
		UnhookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
		UnhookEvent("player_incapacitated", OnPlayerHurt, EventHookMode_Post);
		hookedEvents = false;
	}
}

/** This only triggers if we are transitioning between maps in the same campaign. **/
public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	EndRoundCounter += 1;
}

/** Call when an achievement is prevented by a player **/
PreventAchievement(const String:achievement[], const String:guilty[])
{
	for (new i = 0; i < NUM_ACHIEVEMENTS; ++i)
	{
		if (StrEqual(achievement, achievement_names[i]) && !achievement_prevented[i])
		{
			decl String:coloredName[64];
			Format(coloredName, sizeof(coloredName), "\x04%s\x01", guilty);
			
			decl String:coloredAchievement[64];
			Format(coloredAchievement, sizeof(coloredAchievement), "\x05%s\x01", achievement);
			
			achievement_prevented[i] = true;
			PrintToChatAll("\x01[L4D] %T", "Prevented Achievement", LANG_SERVER, coloredName, coloredAchievement);
		}
	}
}

/** Display the current stats of all achievements to this client **/
DisplayAchievements(client)
{
	if (!isCampaignMap)
	{
		PrintToChat(client, "[L4D] %t", "Not Campaign Map");
		return;
	}
	
	for (new i = 0; i < NUM_ACHIEVEMENTS; ++i)
	{
		decl String:coloredAchievement[64];
		Format(coloredAchievement, sizeof(coloredAchievement), "\x05%s\x01", achievement_names[i]);
		
		if (achievement_prevented[i])
			PrintToChat(client, "\x01[L4D] %t", "Status Prevented", coloredAchievement);
		else
			PrintToChat(client, "\x01[L4D] %t", "Status Attainable", coloredAchievement);
	}
}

/** Detect vomit incidents **/
public Action:OnVomit(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:playerName[32];
	new userid = GetEventInt(event, "userid");
	GetClientName(GetClientOfUserId(userid), playerName, sizeof(playerName));
	PreventAchievement("Stomach Upset", playerName);
	
	/** Record who is vomitted for Nothing Special **/
	for (new i = 0; i < MAX_SURVIVORS; ++i)
	{
		if (playersCurrentlyVomitted[i] == 0)
		{
			playersCurrentlyVomitted[i] = userid;
			break;
		}
	}
	return Plugin_Continue;
}

/** Remove player from the vomitted list when vomit ends **/
public Action:OnVomitEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	for (new i = 0; i < MAX_SURVIVORS; ++i)
	{
		if (playersCurrentlyVomitted[i] == userid)
		{
			playersCurrentlyVomitted[i] = 0;
		}
	}
	return Plugin_Continue;
}
/** Detect player harmed for Untouchables, Nothing Special and Safety First **/
public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new team = GetClientTeam(client);
	if (team == TEAM_SURVIVOR)
	{
		if (hasContactedRescue)
		{
			decl String:playerName[32];
			GetClientName(client, playerName, sizeof(playerName));
			PreventAchievement("Untouchables", playerName);
		}

		new attackerid = GetEventInt(event, "attacker")
		new attackerclient = GetClientOfUserId(attackerid);
		new attackerteam;
		new bool:attackerIsFake;
		new damagetype = GetEventInt(event, "type")

		if (attackerclient != 0)
		{
			attackerIsFake = IsFakeClient(attackerclient);
			attackerteam = GetClientTeam(attackerclient);
		}
		else if (damagetype == ZOMBIE_DAMAGE)
		{
			// Attack came from a normal zombie
			for (new i = 0; i < MAX_SURVIVORS; ++i)
			{
				if (playersCurrentlyVomitted[i] == userid)
				{
					decl String:playerName[32];
					GetClientName(client, playerName, sizeof(playerName));
					PreventAchievement("Nothing Special", playerName);
				}
			}
		}
		/* Uncomment this section so damage by the witch disqualifies Nothing Special
		else if (damagetype == WITCH_DAMAGE)
		{
			decl String:playerName[32];
			GetClientName(client, playerName, sizeof(playerName));
			PreventAchievement("Nothing Special", playerName);
		} */
			

		if ((attackerIsFake) && (attackerteam == TEAM_INFECTED))
		{	
			// Attack came from a bot (Hunter, Smoker, Boomer, Tank)
			decl String:playerName[32];
			GetClientName(client, playerName, sizeof(playerName));
			PreventAchievement("Nothing Special", playerName);
		}
		else if ((client != attackerclient) && (attackerteam == TEAM_SURVIVOR))
		{
			// Attacker was another player
			decl String:attackerName[32];
			GetClientName(attackerclient, attackerName, sizeof(attackerName));
			PreventAchievement("Safety First", attackerName);
		}
	}

	return Plugin_Continue;
}

/** Detect Untouchables activation **/
public Action:OnRescueSummoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	hasContactedRescue = true;
	return Plugin_Continue;
}
