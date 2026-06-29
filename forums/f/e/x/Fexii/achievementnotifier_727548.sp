#include <sourcemod>

#define PLUGIN_VERSION "1.0"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define NUM_ACHIEVEMENTS 3

// Status of whether or not this achievement has been prevented
new bool:achievement_prevented[NUM_ACHIEVEMENTS];

// Names of all the achievements this plugin will track
new String:achievement_names[][] = {
	"Safety First",
	"Stomach Upset",
	"Untouchables"
};

// Achievements that require starting from the first map of the campaign
new String:achievement_entire_campaign[][] = {
	"Safety First",
	"Stomach Upset"
};

// Achievements that can be acquired in a single round, without playing the entire campaign
new String:achievement_single_round[][] = {
	"Untouchables"
};

// Is this map campaign or versus
new bool:isCampaignMap = false;

// Are starting a new level or transitioning through the same campaign
new bool:isMapTransition = false;

// Have we hooked events that need unhooking?
new bool:hookedEvents = false;

// Keep track of condition variables that are required for achievements
new bool:hasContactedRescue = false;

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
	
	// Determine whether this is a campaign map or a versus map
	if (StrContains(map, "_vs_") != -1)
		isCampaignMap = false;
	else
	{
		isCampaignMap = true;
		
		// Hook events needed for tracking achievements
		if (!hookedEvents)
		{
			HookEventEx("map_transition", OnRoundEnd, EventHookMode_PostNoCopy);
			HookEventEx("friendly_fire", OnFriendlyFire, EventHookMode_Post);
			HookEventEx("player_now_it", OnVomit, EventHookMode_Post);
			HookEventEx("finale_start", OnRescueSummoned, EventHookMode_PostNoCopy);
			HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post);
			HookEventEx("vote_passed", OnVotePassed, EventHookMode_Post);
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
		
		// If we are at the first stage of the campaign
		if (StrContains(map, "01") != -1)
		{
			ResetAllAchievements();
		}
		// If we are not on the first stage and didn't beat the previous stage
		else if (!isMapTransition)
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
		
		isMapTransition = false;
	}
}

/** Unhook events whenever the map changes **/
public OnMapEnd()
{
	if (hookedEvents)
	{
		UnhookEvent("map_transition", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("friendly_fire", OnFriendlyFire, EventHookMode_Post);
		UnhookEvent("player_now_it", OnVomit, EventHookMode_Post);
		UnhookEvent("finale_start", OnRescueSummoned, EventHookMode_PostNoCopy);
		UnhookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
		UnhookEvent("vote_passed", OnVotePassed, EventHookMode_Post);
		hookedEvents = false;
	}
}

/** This only triggers if we are transitioning between maps in the same campaign. **/
public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	isMapTransition = true;
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

/** Reset the status of all achievements to attainable **/
ResetAllAchievements()
{
	for (new i = 0; i < NUM_ACHIEVEMENTS; ++i)
		achievement_prevented[i] = false;
}

/** Reset achievement stats if a vote was passed to restart the campaign */
public Action:OnVotePassed(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:details[32];
	GetEventString(event, "details", details, sizeof(details));
	
	if (StrEqual(details, "#L4D_vote_passed_restart_game"))
		ResetAllAchievements();
	
	return Plugin_Continue;
}

/** Detect friendly fire incidents **/
public Action:OnFriendlyFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:playerName[32];
	new userid = GetEventInt(event, "guilty");
	GetClientName(GetClientOfUserId(userid), playerName, sizeof(playerName));
	PreventAchievement("Safety First", playerName);
	return Plugin_Continue;
}

/** Detect vomit incidents **/
public Action:OnVomit(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:playerName[32];
	new userid = GetEventInt(event, "userid");
	GetClientName(GetClientOfUserId(userid), playerName, sizeof(playerName));
	PreventAchievement("Stomach Upset", playerName);
	return Plugin_Continue;
}

/** Detect player harmed for untouchables **/
public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hasContactedRescue)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		new team = GetClientTeam(client);
		if (team == TEAM_SURVIVOR)
		{
			decl String:playerName[32];
			GetClientName(client, playerName, sizeof(playerName));
			PreventAchievement("Untouchables", playerName);
		}
	}
	return Plugin_Continue;
}

/** Detect untouchables activation **/
public Action:OnRescueSummoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	hasContactedRescue = true;
	return Plugin_Continue;
}
