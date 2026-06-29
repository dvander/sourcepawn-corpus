#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required  

public Plugin myinfo = 
{
	name = "Bot Toggle",
	author = "decowboy",
	description = "Allow players to enable/disable bots with a simple chat command",
	version = "1.0.1",
	url = "https://forums.alliedmods.net/showthread.php?p=2353510"
}


Handle g_Cvar_BotQuota = INVALID_HANDLE; // handle for cvar bot_quota
Handle g_Cvar_BotQuotaMode = INVALID_HANDLE; // handle for cvar bot command

int botQuota = 0; // desired bot quota according to cvar
int botQuotaMode = -1; // bot quota mode according to cvar
int botEnabled = true; // whether bots are currently toggled on
int humanCount = 0; // current number of human players

int botMemory = -1; // value of the bot_quota cvar before overriding it
int currentGeneration = 0; // current generation of timers

int toggleStamp = 0; // timestamp of last toggle

char toggleCommand[33]; // current bot command

ConVar sm_bot_toggle = null;
ConVar sm_bot_toggle_default = null;
ConVar sm_bot_toggle_command = null;
ConVar sm_bot_toggle_chat = null;
ConVar sm_bot_toggle_announce = null;
ConVar sm_bot_toggle_rounds = null;
ConVar sm_bot_toggle_cooldown = null;
ConVar sm_bot_toggle_flag = null;

#define TOGGLE_ACTIVE 1
#define TOGGLE_DISABLED 0
#define TOGGLE_INACTIVE -1
#define TOGGLE_EXPIRED -2

#define MODE_FILL 1
#define MODE_NORMAL 0
#define MODE_DISABLED -1

#define MAX_INT 2147483647



// Main function
public void OnPluginStart()
{
	
	// Get and store the bot_quota and bot_quota_mode cvars
	g_Cvar_BotQuota = FindConVar("bot_quota");
	botQuota = GetConVarInt(g_Cvar_BotQuota);
	
	g_Cvar_BotQuotaMode = FindConVar("bot_quota_mode");
	char mode[33];
	GetConVarString(g_Cvar_BotQuotaMode, mode, sizeof(mode));
	setQuotaMode(mode);
	
	// Keep track of future cvar bot_quota and bot_quota_mode changes
	HookConVarChange(g_Cvar_BotQuota, BotQuotaChanged);
	HookConVarChange(g_Cvar_BotQuotaMode, BotQuotaModeChanged);
	
	// Hook up to round start events
	HookEvent("round_start", Event_RoundStart);
	
	// Hook up to (post) player team switch
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post); 
	
	// Hook up to bot add commands
	RegServerCmd("bot_add", BotAdd);
	RegServerCmd("bot_add_t", BotAdd);
	RegServerCmd("bot_add_ct", BotAdd);
	
	// Register all plugin cvars
	sm_bot_toggle = CreateConVar("sm_bot_toggle", "1", "Should players be allowed to toggle bots? (0/1)");
	sm_bot_toggle_default = CreateConVar("sm_bot_toggle_default", "1", "Should bots automatically spawn when a new map is loaded? (0/1)");
	sm_bot_toggle_command = CreateConVar("sm_bot_toggle_command", "bots", "Command for players to toggle bots with (do *not* prepend with exclamation mark or slash; max. 32 characters)");
	sm_bot_toggle_chat = CreateConVar("sm_bot_toggle_chat", "0", "Should the use of the toggle command in chat without an exclamation mark or slash in front of it be allowed? (0/1)");
	sm_bot_toggle_announce = CreateConVar("sm_bot_toggle_announce", "1", "Announce the toggle command to players in chat? (0/1)");
	sm_bot_toggle_rounds = CreateConVar("sm_bot_toggle_rounds", "2", "Only allow players to toggle bots during the first x rounds of the match (-1 or 0 = always allow)");
	sm_bot_toggle_cooldown = CreateConVar("sm_bot_toggle_cooldown", "6", "Do not allow players to toggle bots for x seconds after the previous toggle (-1 or 0 = always allow)");
	sm_bot_toggle_flag = CreateConVar("sm_bot_toggle_flag", "generic", "Allow admins with this flag to toggle even if other players can't (e.g. \"kick\" for admin kick flag; max. 32 characters; leave empty to disable)");
	
	// Keep track of future cvar bot command changes
	HookConVarChange(sm_bot_toggle_command, BotCommandChanged);
	
	// Execute the config-file
	AutoExecConfig(true, "plugin_bot_toggle");
	
	// Get the command set by cvar
	GetConVarString(sm_bot_toggle_command, toggleCommand, sizeof(toggleCommand));
	
	// And register that command
	RegConsoleCmd(toggleCommand, Command_Toggle);
	
	// Check whether the admin flag set by cvar exists
	IsAdmin(-1);
	
}


// This function is called when a bot is added
public Action BotAdd(int args)
{
	// If the current bot quota is zero, then this is the first bot
	
	// If the bot_quota_mode cvar is also set to fill, 
	// then we need to first normalize the value of the bot quota cvar
	// to maintain: bot quota = bot count + player count
	
	// If the bot quota mode cvar is set to normal,
	// then the server will itself maintain: bot quota = bot count
	
	if (botQuota == 0 && botQuotaMode == MODE_FILL) {
		// Set the bot_quota cvar to the amount of human players
		// This shouldn't spawn any bots
		SetConVarInt(g_Cvar_BotQuota, humanCount);
	}
	
	// A bot was added, so bots are enabled
	botEnabled = true;
	botMemory = -1;
	
	return Plugin_Continue;
}


// This function is called when the value of cvar bot_quota_mode changes
public void BotQuotaModeChanged(Handle cvar, const char[] oldValue, const char[] newValue) {
	
	setQuotaMode(newValue);
}


// Update the bot quota mode
public void setQuotaMode(const char[] value) {

	if (strcmp(value, "fill", false) == 0) {
		botQuotaMode = MODE_FILL;
	} else if (strcmp(value, "normal", false) == 0) {
		botQuotaMode = MODE_NORMAL;
	} else {
		botQuotaMode = MODE_DISABLED;
	}	
}

// This function is called when a round ends
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason) {
	
	// Check if the game is commencing
	if (reason == CSRoundEnd_GameStart) {
		
		// If bots should not spawn at map start, then set a timer to despawn them
		if (GetConVarInt(sm_bot_toggle_default) != 1) {
			
			CreateTimer(5.0, TimerDespawn);
			
		}
	}
	
}


// This timer despawns bots if possible
public Action TimerDespawn(Handle timer) {
	
	// If there are bots in the server
	if (botEnabled && botQuota > 0) {
		
		PrintToServer("[SM] Despawning bots on cvar request");
		
		// Despawn them
		botEnabled = false;
		HandleChanges();	
		
	}
	
}


// This function is called when the value of cvar bot_quota changes
public void BotQuotaChanged(Handle cvar, const char[] oldValue, const char[] newValue) {
	
	int newQuota = StringToInt(newValue);
	
	// Store the new value of the bot_quota cvar
	botQuota = newQuota;
	
	// If the value is higher than zero and the bot_mode cvar is set to 'fill',
	// then bots have been enabled by a map change, another plugin or a server admin
	if (botQuota > 0) {
		
		// So update accordingly
		botEnabled = true;
		botMemory = -1;
		
	}
	
}


// This function is called when the value of the bot toggle command cvar changes
public void BotCommandChanged(Handle cvar, const char[] oldValue, const char[] newValue) {
	
	// Register the new command
	strcopy(toggleCommand, sizeof(toggleCommand), newValue);
	RegConsoleCmd(toggleCommand, Command_Toggle);
	
}


// This function is called when a round starts
public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	
	// Announce to players if instructed to do so by cvar
	if (GetConVarInt(sm_bot_toggle_announce)) {
		AnnounceToAll();
	}
	
}


// This function is called when a player joins
public void OnClientPostAdminCheck(int client)
{
	
	// Update the number of current players
	UpdatePlayerCount();
	
	// Set timers to announce the plugin to this player
	AnnounceToPlayer(client);
	
}


// This function is called when a player leaves
public void OnClientDisconnect(int client) {
	
	// Update the number of current players
	UpdatePlayerCount();
	
}


public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{ 
	
	// Update the number of current players
	UpdatePlayerCount();
	
}


// This function checks whether a player is human and non-spectator
public bool IsParticipatingPlayer(int client) {
	if (client < 1 || client > MaxClients) {
		return false;
	}
	
	if (!IsClientInGame(client) || IsFakeClient(client)) {
			return false;
	}
	
	if (GetClientTeam(client) <= CS_TEAM_SPECTATOR) {
		return false;
	}
	
	return true;
}


// This function updates the number of current players
public void UpdatePlayerCount() {
	
	int newCount = 0;
	
	// Loop through players
	for (int i = 1; i <= MaxClients; i++)
	{
		
		// If the client is in-game and not a bot
		if (IsParticipatingPlayer(i)) {
			
			newCount++;
			
		}
		
	}
	
			
	// Store the updated count of human players
	humanCount = newCount;
	
}


// This function handles the toggling of bots
public void HandleChanges() {
	
	int processedChanges = false;
	
	// If bots are toggled on
	if (botEnabled) {
	
		// If the bot_quota cvar hasn't been restored yet
		if (botMemory > -1) {
			
			// Calculate the amount of bots to add based on the bot quota cvar
			int addBots = botMemory;
			
			// If the bot quota mode cvar is set to "fill", then this value
			// also includes the human players, so we should subtract that
			if (botQuotaMode == MODE_FILL) {
				addBots = addBots - humanCount;
			}
			
			// Add enough bots
			// This should raise the bot_quota cvar back to its original value
			for (int i = 1; i <= addBots; i++) {
				ServerCommand("bot_add");
			}
			
			// Remember that changes have been processed
			processedChanges = true;
			
		}
	
	} else { // If bots are toggled off
	
		// If the bot_quota hasn't been set to zero yet
		if (botQuota > 0) {
			
			// Remember the current bot_quota for later
			botMemory = botQuota;
			
			// Set the bot_quota to zero
			SetConVarInt(g_Cvar_BotQuota, botMemory);
			
			// Kick all bots
			ServerCommand("bot_kick");
			
			// Remember that changes have been processed
			processedChanges = true;
			
		}
	
	}
	
	// If we just processed any changes
	if (processedChanges) {
		
		// Update the timestamp of the last toggle to right now
		toggleStamp = GetTime();
		
		// Create timers to once more announce the plugin to all human players
		AnnounceToAll();
		
	}
	
}


// This function is called when a player gives the bot toggle command
public Action Command_Toggle(int client, int args)
{
	
	// Get the bot toggle command used
	char buffer[33];
	GetCmdArg(0, buffer, 33);
	
	// Discard if an outdated bot toggle command was used
	if (strcmp(buffer, toggleCommand) < 0) {
		return Plugin_Handled;
	}
	
	
	// Ignore commands from spectators, bots and the likes
	if (!IsParticipatingPlayer(client)) {
		
		return Plugin_Handled;
		
	}
	
	// Process this toggle
	processToggle(client);
	
	return Plugin_Handled;
	
}


// This function is called when a player sends a chat message
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	
	// Check if command without a ! or / is permitted by cvar
	// If not, we don't have to get involved with chat messages
	if (GetConVarInt(sm_bot_toggle_chat) != 1) {
		return Plugin_Continue;
	}
	
	// Ignore chats from spectators, bots and the likes
	if (!IsParticipatingPlayer(client)) {
		
		return Plugin_Continue;
		
	}
	
	// If the player is asking to toggle the bots
	if (strcmp(sArgs, toggleCommand, false) == 0)
	{
		
		// Process this toggle
		processToggle(client);
		
		// Block the message from broadcasting
		return Plugin_Handled;
		
	}
 
	// Otherwise, let the chat message continue
	return Plugin_Continue;
}


// This function is called when a player requests to toggle bots
public Action processToggle(int client) {

		// Calculate the remaining cooldown if one is set by cvar
		int cooldownRemaining = GetConVarInt(sm_bot_toggle_cooldown);
		if (cooldownRemaining > 0) {
			cooldownRemaining += toggleStamp - GetTime();
		
			// Discard when we are still in cooldown from the last toggle
			// But make an exception for admins if instructed so by cvar
			if (cooldownRemaining > 0 && !IsAdmin(client)) {
				
				// Sneaky little hack.
				// If we raise the remaining time by one second, the resulting number will always be larger than 1.
				// That way our language string can be phrased in plural without it leading to "1 seconds remaining"
				// Plus, it's one second. Who will know the difference?
				
				cooldownRemaining++;
				
				
				if (botEnabled) {
						
					PrintToChat(client,"You need to wait %d seconds before disabling bots.", cooldownRemaining);
						
				} else {
						
					PrintToChat(client,"You need to wait %d seconds before enabling bots.", cooldownRemaining);
						
				}
				
				return;
				
			}
		}
		
		// If it is too late in the match to toggle bots, do not allow to toggle
		// But make an exception for admins if instructed to do so by cvar
		if (PluginActive() == TOGGLE_EXPIRED && !IsAdmin(client)) { 
				
			// Notify the player that his command was discarded
			if (botEnabled) {
				
				PrintToChat(client,"You can't disable bots this late in the match.");
				
			} else {
				
				PrintToChat(client,"You can't enable bots this late in the match.");
				
			}
				
		} else { // Or if this plugin is currently active
		
			// If bots are currently enabled
			if (botEnabled) {
				
				// Log to the server
				PrintToServer("[SM] %N just disabled the bots", client);
				
				// Notify all players that bots will be disabled
				PrintCenterTextAll("%N just disabled the bots", client);
				
				// Disable the bots
				botEnabled = false;
				
				
				
			} else { // Or if they are currently disabled
				
				// Log to the server
				PrintToServer("[SM] %N just enabled the bots", client);
			
				// Notify all players that bots will be enabled
				PrintCenterTextAll("%N just enabled the bots", client);
				
				// Enable the bots	
				botEnabled = true;
				
			}
			
			// Perform additional operations to handle the change
			HandleChanges();
		
		}
		
}


// This function checks whether a player is an admin
// May also be called to verify if the admin flag exists
public bool IsAdmin(int client) {
	
	// Get the admin flag set by cvar
	char toggleFlag[33];
	GetConVarString(sm_bot_toggle_flag, toggleFlag, sizeof(toggleFlag));
	
	// Cancel if no admin flag was set
	if (strcmp(toggleFlag, "", false) == 0) {
		
		return false;
		
	}
	
	AdminFlag flag;
	bool result = FindFlagByName(toggleFlag, flag);
	
	// If the admin flag does not exist
	if (result == false) {
		
		PrintToServer("[SM] Admin flag '%s' does not exist", toggleFlag);
		return false;
		
	}
	
	// Check whether the player is in-game and not a bot
	if (!IsParticipatingPlayer(client)) {
		
		return false;
		
	}
	
	// Check whether the player has the admin flag
 	AdminId admin = GetUserAdmin(client);
	
	if((admin != INVALID_ADMIN_ID) && (GetAdminFlag(admin, flag, Access_Real) == true))
	{
        return true;
	}
	
	return false;
	
}


// This function starts timers to announce the plugin to all players
public void AnnounceToAll() {
	
	// Prevent the timer generation counter from overflowing
	if (currentGeneration == MAX_INT) {
		currentGeneration = -1;
	}
	
	// Raise the timer generation counter
	currentGeneration++;

	// If the plugin is active, create new timers
	if (PluginActive() == TOGGLE_ACTIVE) {
		CreateTimer(getTimerIntervals(0),TimerAnnounceAll, currentGeneration);
		CreateTimer(getTimerIntervals(1),TimerAnnounceAll, currentGeneration);
	}
	
}


// This function starts timer to announce the plugin to a certain player
public void AnnounceToPlayer(int client) {
	
	// If the plugin is active, create new timers
	if (PluginActive() == TOGGLE_ACTIVE) {
		DataPack pack1;
		CreateDataTimer(getTimerIntervals(0),TimerAnnouncePlayer, pack1);
		pack1.WriteCell(client);
		pack1.WriteCell(currentGeneration);
		
		DataPack pack2;
		CreateDataTimer(getTimerIntervals(1),TimerAnnouncePlayer, pack2);
		pack2.WriteCell(client);
		pack2.WriteCell(currentGeneration);
	}
	
}


// Calculate the timer intervals
public float getTimerIntervals(int index) {
	float interval = 0.0;
	
	// Set the interval based on the index
	if (index == 0) {
		interval = 5.0;
	}
	if (index == 1) {
		interval = 30.0;
	}
	
	// The timer interval must be greater than the cooldown
	// to avoid annoucing this plugin when players can't use it
	int cooldown = GetConVarInt(sm_bot_toggle_cooldown) + 1;
	if (interval < cooldown) {
		interval = float(cooldown);
	}
	
	return interval;
}


// This timer announces the plugin to a player
public Action TimerAnnouncePlayer(Handle timer, Handle pack)
{
	
	// Parse the data pack
	ResetPack(pack);
	
	int client = ReadPackCell(pack);
	int generation = ReadPackCell(pack);
	
	// Cancel if there is a newer generation of timers
	if (!CheckGeneration(generation)) {
		return;
	}
	
	// Cancel if announcing is disabled by cvar
	if (GetConVarInt(sm_bot_toggle_announce) != 1) {
		return;
	}
	
	// Announce the plugin to the given player
	SendAnnouncement(client);
	
}


// This timer announces the plugin to all players
public Action TimerAnnounceAll(Handle timer, any generation)
{
	
	// Cancel if there is a newer generation of timers
	if (!CheckGeneration(generation)) {
		return;
	}
	
	// Cancel if announcing is disabled by cvar
	if (GetConVarInt(sm_bot_toggle_announce) != 1) {
		return;
	}
	
	// Loop through players
	for (int i = 1; i <= MaxClients; i++)
	{
		
		// If the client is in-game and not a bot
		if (IsParticipatingPlayer(i)) {
			
			// Announce the plugin to that player
			SendAnnouncement(i);
			
		}
		
	}
	
}


// Check whether a generation is still current
public bool CheckGeneration(int generation) {
	if (generation == currentGeneration) {
		return true;
	} else {
		return false;
	}
}


// This function return whether this plugin should be active
//    1 = active
//  <=0 = inactive
public int PluginActive() {
	
	// Check whether this plugin is disabled by cvar
	if (GetConVarInt(sm_bot_toggle) != 1) {
		return TOGGLE_DISABLED;
	}
	
	
	// In case the bot_quota_mode cvar is set to "fill"
	if (botQuotaMode == MODE_FILL) {
		
		// Only if the bot quota is higher than the current number of human players,
		// it is useful for the plugin to be active
		// Otherwise there wouldn't be any bots anyway, regardless of whether bots are toggled on
		
		// As consequence, this will effectively disable this plugin if the bot_quota_mode cvar is set to "fill"
		// and the bot_quota cvar is set to zero by something other than this plugin itself
		
		if (botQuota <= humanCount && botMemory <= humanCount) {
			return TOGGLE_INACTIVE;
		}
		
	}
	
	
	// If a cvar was set to only allow toggling of bots during the first x rounds, then verify that
	// This is to prevent players griefing
	
	// As an alternative, players could vote to restart the match or change the map,
	// which will trigger a new warmup round and thus allow players to toggle the bots again
	
	
	int maxRounds = GetConVarInt(sm_bot_toggle_rounds);
	if (maxRounds > 0) {
		
		// Count the number of rounds won so far
		int currentRounds = CS_GetTeamScore(CS_TEAM_CT) + CS_GetTeamScore(CS_TEAM_T);
		
		// If more rounds passed than allowed by cvar, this plugin should be inactive
		if (currentRounds >= maxRounds) {
			return TOGGLE_EXPIRED;
		}
		
	}
	
	// If none of the above, this plugin should be active
	return TOGGLE_ACTIVE;
	
}


// This function announces the plugin to a player
public void SendAnnouncement(int client)
{

	// If the client is in-game and not a bot
	if(IsParticipatingPlayer(client))
	{
		
		// If this plugin is currently active
		if (PluginActive() == TOGGLE_ACTIVE) {
				
			// Get the bot toggle command and check whether a ! or / is required
			char togglePrepend[2] = "";
			if (GetConVarInt(sm_bot_toggle_chat) != 1) {
				togglePrepend[0] = '!';
			}
				
			// If bots are currently toggled on
			if (botEnabled) {
				
				// Announce how to disable bots
				PrintToChat(client,">> Want to play without bots? Say: %s%s", togglePrepend, toggleCommand);
				
			} else {
				
				// Announce how to enable bots
				PrintToChat(client,">> Want to play with bots? Say: %s%s", togglePrepend, toggleCommand);
				
			}
			
		}
		
	}
	
	
}