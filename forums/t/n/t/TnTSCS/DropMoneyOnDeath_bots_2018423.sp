/*
* 
* 						Drop Money On Death SourceMOD Plugin
* 						Copyright (c) 2008  SAMURAI
* 
* 						Visit http://www.cs-utilz.net
*
* Special thanks to Bacardi for his Healthkit From Dead (HFD) plugin which I (TnTSCS) used as a guide for this one
* 
* CHANGELOG:
*
*	Version 0.2.1	-	My initial fix and release (albeit in the original authors thread
*
*	*** Thanks to SAMURAI for the original plugin - too many changes have been made and you're banned, time to rerelease it as its own plugin instead of a fixed version of yours.
*	Version 0.3.0	-	My release in its own thread
*					*	I changed from using a datapack to using a Trie Array (I think that's more efficient and lighter of a code)
*					*	Took out the $16,000 hard set max cash - put in a variable for it (defaulted to $16,000)
*	
*	Version 0.3.1	-	Added CVar for dropping a set amount of cash and player who dropped it does not lose their money and if the chat messages should be printed
*					*	Requested by Fearts (http://forums.alliedmods.net/member.php?u=43017) - http://forums.alliedmods.net/showpost.php?p=1602483&postcount=6
*				-	Fixed a few bugs with messaging clients when entity index was 0
*	
*	Version 0.3.2	-	Changed EntityByName from prop_physics_override to prop_physics_multiplayer (credit to Bacardi for the way he created his healthpack entity)
*					*	report_entities now shows the increased number of prop_physics_multiplayer entities
*
* 	Version 0.3.3	-	Fixed bug where dead players could pick up money
* 				-	Added CVar for Updater plugin - defaulted to not auto-update
* 				-	Added flag FCVAR_DONTRECORD to sm_DropMoneyOnDeath_version CVar
* 				-	Fixed the description for CVar sm_DropMoneyOnDeath_maxcash
* 	
* 	Version 0.3.4	-	Enhanced the sm_DropMoneyOnDeath_losemoney CVar for if a player should lose their money the moment they die or not.
* 					* Set to 0 to have the player lose the money upon death, or set to 1 to have the player lose the money only if someone picks it up
* 				-	Fixed the CVar descriptions - some had 1=YES 2=NO... should be 1=YES and 0=NO
* 
* 	Version 0.3.5	-	Added a CVar so drop immunity can be configured
* 
* 	Version 0.3.6	-	Changed the m_CollisionGroup and m_usSolidFlags values
* 				-	Added a message to users who already have max cash and cannot pick up anymore cash. (updated translation file)
* 
* 	Version 0.3.7	-	Added optional notification to player if set to lose money on death
* 				-	Combined the two advertise CVars into one - now you select the mode you want for advertising (Options are a combination of the new modes)
* 				-	Changed the CVar for losemoney, options are 1 (don't lose), 2 (lose on death), or 3 (lose when picked up).
* 				-	Removed smlib\clients include and just put in the needed components from SMLib (saved 1.5KB compiled size and 1.4 seconds compile time)
* 
* 	Version 0.3.8	-	Added ability to define the model used for the money.
* 
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION 				"0.3.8"
#define UPDATE_URL 					"http://dl.dropbox.com/u/3266762/DropMoneyOnDeath.txt"
#define MAX_FILE_LEN 				256

// From SMLib entities.inc
#define FSOLID_TRIGGER				8  // This is something may be collideable but fires touch functions
#define COLLISION_GROUP_WEAPON		11 // for any weapons that need collision detection

#define _DEBUG						1	// Set to 1 for debug spew to log file
#define _DEBUG_CHAT					1	// Set to 1 for debug spew to in-game chat

new MaxCash;
new DropAmount;
new LosersMoney;
new PercentOfMoney;

new LoseMoney;
new AdvertiseMode;
new bool:ClientConnected;
new bool:TeamAttackDeath;
new bool:NoAttackerDeath;
new bool:UseUpdater = false; // Should this plugin be updated by Updater
new bool:DropImmunity = false; // Should players have drop money immunity?
new bool:UseCustomModel;
new String:MoneyModel[PLATFORM_MAX_PATH];
new bool:PlayerNotDrop[MAXPLAYERS+1];

new Handle:h_Trie;

enum MoneyAttributes
{
AMOUNT,
WHO
};

public Plugin:myinfo = 
{
	name = "Drop Money on Death",
	author = "TnTSCS aka ClarkKent",
	description = "When a player dies, they will drop a portion of their money",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd().
 *
 * If any run-time error is thrown during this callback, the plugin will be marked 
 * as failed.
 *
 * It is not necessary to close any handles or remove hooks in this function.  
 * SourceMod guarantees that plugin shutdown automatically and correctly releases 
 * all resources.
 *
 * @noreturn
 */
public OnPluginStart()
{
	new bool:appended;
	
	AutoExecConfig_SetFile("DropMoneyOnDeath.plugin");
	
	new Handle:hRandom;// KyleS Hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_DropMoneyOnDeath_version", PLUGIN_VERSION, 
	"The version of 'Drop Money on Death'", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_enabled", "1", 
	"1=Enabled, 0=Disabled", _, true, 0.0, true, 1.0)), EnabledChanged);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_percent", "50", 
	"Percent of money to drop when player dies", _, true, 1.0, true, 100.0)), PercentChanged);
	PercentOfMoney = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_maxcash", "16000", 
	"Maximum cash a player is allowed to carry (usually 16000)", _, true, 1.0)), MaxCashChanged);
	MaxCash = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_losemoney", "3", 
	"How should a player lose the money they drop (pick one option)?\n1 = Players never lose the money they drop\n2 = Players lose the money upon death\n3 = Players only lose the money if another player picks it up.", _, true, 1.0, true, 3.0)), LoseMoneyChanged);
	LoseMoney = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_dropamount", "1500", 
	"The hard set amount of cash to drop when the player dies\nSet to '0' to just use the percentage.", _, true, 0.0)), DropAmountChanged);
	DropAmount = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_advertise", "6", 
	"Mode for how to advertise to players (add options)\n0 = Disable all notifications\n1 = When player drops money\n2 = When someone picks up their dropped money\n4 = When player picks up money\nExample: sm_DropMoneyOnDeath_advertise \"6\" (4+2)", _, true, 0.0, true, 7.0)), AdvertiseModeChanged);
	AdvertiseMode = GetConVarInt(hRandom);
	SetAppend(appended);
	
	/*
	* 0 = Disable advertisement
	* 1 = Adverstise to the player when they drop money (usually only if you have losemoney set to 0)
	* 2 = Advertise to the player when someone picks up their dropped money
	* 4 = Advertise to players when they pick up money
	*/
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_teamattackdeath", "0", 
	"Players drop money when they're team attacked\n1 = YES\n0 = NO", _, true, 0.0, true, 1.0)), TeamAttackDeathChanged);
	TeamAttackDeath = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_noattackerdeath", "0", 
	"Players drop money when they kill themselves or there is no attacker?\n1 = YES\n0 = NO", _, true, 0.0, true, 1.0)), NoAttackerDeathChanged);
	NoAttackerDeath = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update Drop Money On Death when updates are published?\n1 = YES\n0 = NO", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_dropimmunity", "0", 
	"Should players have drop money on death immunity?\n1 = YES\n0 = NO", _, true, 0.0, true, 1.0)), OnDropImmunityChanged);
	DropImmunity = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_custom_model", "0", 
	"Use your own model for the money?  One that's not included with your game.\n1 = YES\n0 = NO\nIf you're using a game model, just put the .mdl path in the _model CVar and leave this set to 0", _, true, 0.0, true, 1.0)), OnCustomModelChanged);
	UseCustomModel = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_DropMoneyOnDeath_model", "models/props/cs_assault/money.mdl", 
	"If _custom_model is set to 1, type the path of the .mdl file here and make sure you add all other files in the configs/money.ini file so they can be added to the download table")), OnModelChanged);
	GetConVarString(hRandom, MoneyModel, sizeof(MoneyModel));
	SetAppend(appended);
	
	CloseHandle(hRandom);
	
	HookEvent("player_death", Event_PlayerDeath);
	
	// Load translation file
	LoadTranslations("DropMoneyOnDeath.phrases");
	
	h_Trie = CreateTrie();
	
	// Cleaning is an expensive operation and should be done at the end
	if (appended)
	{
		AutoExecConfig_CleanFile();
	}
}

/**
 * Called after a library is added that the current plugin references 
 * optionally. A library is either a plugin name or extension name, as 
 * exposed via its include file.
 *
 * @param name			Library name.
 */
public OnLibraryAdded(const String:name[])
{
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been 
 * executed, and all plugin configs are done executing.  This is the best
 * place to initialize plugin functions which are based on cvar data.  
 *
 * @note This will always be called once and only once per map.  It will be 
 * called after OnMapStart().
 *
 * @noreturn
 */
public OnConfigsExecuted()
{
	if (UseCustomModel)
	{
		#if _DEBUG
			DebugMessage("UseCustomModel being used, caching files...");
		#endif
		
		RunPreCache();
	}
	else
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "Using game .mdl file.  Only caching model file [%s]", MoneyModel);
			DebugMessage(dmsg);
		#endif
		
		if (!PrecacheModel(MoneyModel, true))
		{
			LogError("Unsuccessful precaching of the model %s", MoneyModel);
		}
	}
	
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}

public OnClientPostAdminCheck(client)
{
	PlayerNotDrop[client] = CheckCommandAccess(client, "no_dropmoneyondeath", ADMFLAG_CUSTOM4);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		PlayerNotDrop[client] = false;
	}
}

/**
*	"player_death"				// a game event, name may be 32 characters long	
*	{
*		// this extents the original player_death by a new fields
*		"userid"		"short"   	// user ID who died				
*		"attacker"		"short"	 // user ID who killed
*		"weapon"		"string" 	// weapon name killer used 
*		"headshot"		"bool"		// singals a headshot
*		"dominated"		"short"	// did killer dominate victim with this kill
*		"revenge"		"short"	// did killer get revenge on victim with this kill
*	}
*/
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "%L just died", client);
		DebugMessage(dmsg);
	#endif
	
	// Stop plugin if the player has the proper flag (defaulted to CUSTOM1)
	if (DropImmunity && PlayerNotDrop[client])
	{
		#if _DEBUG
			Format(dmsg, sizeof(dmsg), "%L immune from dropping money and plugin is configured to use DropImmunity", client);
			DebugMessage(dmsg);
		#endif
		
		return;
	}
		
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
	
	// Figure out if player killed themselves or there was no attacker and handle appropriately according to cfg file
	if (!NoAttackerDeath && (client == attacker || attacker == 0 || !attacker)) // If "do not drop money on self kill or no attacker"
	{
		#if _DEBUG
			Format(dmsg, sizeof(dmsg), "%L killed themselves or was not killed by another player, not dropping money.  Attacker's ClientID is %i", client, attacker);
			DebugMessage(dmsg);
		#endif
		
		// Players shouldn't drop money if they kill themselves or there is no attacker unless specified in cfg file
		return;
	}
	
	// Ensure attacker is a player
	if (attacker > 0 && attacker <= MaxClients)
	{		
		/**
		* Figure out if this is a team kill and handle appropriately according to cfg file
		*/
		if (GetClientTeam(client) == GetClientTeam(attacker) && !TeamAttackDeath) // Team attack and "do not drop money on TA" set in config file
		{
			#if _DEBUG
				Format(dmsg, sizeof(dmsg), "%L was team attacked and plugin is configured to not drop money on team attack deaths.", client);
				DebugMessage(dmsg);
			#endif
			
			return;
		}			
	}
	
	#if _DEBUG
		Format(dmsg, sizeof(dmsg), "%L will be dropping money", client);
		DebugMessage(dmsg);
	#endif
	
	// Since no stops happened, go ahead and have player who died drop money
	DropMoney(client);
}

/**
* Function for creating the money model and setting the amount and owner of the money entity
*
*@param client 	client index of player dropping the money (the victim of player_death)
*@noreturn
*/
DropMoney(client)
{
	new ent;
	
	if ((ent = CreateEntityByName("prop_physics")) != -1) // _multiplayer
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "Successfully created money entity [%i]", ent);
			DebugMessage(dmsg);
		#endif
		
		new Float:origin[3];
		GetClientEyePosition(client, origin); // Get a higher position (eye level)
		
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR); //Teleport money
		
		new String:targetname[100];
		
		Format(targetname, sizeof(targetname), "money_%i", ent); // Create name for entity
		
		// Set some of the Key Values of the newly created entity
		DispatchKeyValue(ent, "model", MoneyModel); // Set the model key's name
		DispatchKeyValue(ent, "physicsmode", "2"); // Non-Solid, Server-side
		DispatchKeyValue(ent, "massScale", "8.0"); // A scale multiplier for the object's mass.  Needed to increase it otherwise it was too light
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		DispatchSpawn(ent); // Spawn
		
		// Set the entity as solid and unable to take damage
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8);//FSOLID_TRIGGER);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);//COLLISION_GROUP_WEAPON);
		
		new amount;
		
		// Get the current cash amount of the client
		new clientCash = GetEntProp(client, Prop_Send, "m_iAccount");
		
		if (DropAmount == 0)// Use percentage cvar
		{
			// Figure out the percentage we should be dropping
			amount = (clientCash * PercentOfMoney / 100);
		}
		else
		{
			// Use hard set amount from config file
			amount = DropAmount;
		}
		
		#if _DEBUG
			Format(dmsg, sizeof(dmsg), "%L will be dropping %i", client, amount);
			DebugMessage(dmsg);
		#endif
		
		if (LoseMoney == 2)
		{
			new new_clientCash = clientCash - amount;
			
			if (new_clientCash <= 0)
			{
				if (AdvertiseMode > 0 && AdvertiseMode & 1)
				{
					CPrintToChat(client, "%t", "Lost Money", clientCash);
				}
				
				SetEntProp(client, Prop_Send, "m_iAccount", 0);
			}
			else
			{
				if (AdvertiseMode > 0 && AdvertiseMode & 1)
				{
					CPrintToChat(client, "%t", "Lost Money", amount);
				}
				
				SetEntProp(client, Prop_Send, "m_iAccount", new_clientCash);
			}
		}
		
		// Get the UserID of the client (player/victim) for the trie
		new UserID = GetClientUserId(client);
		
		// Begin storing entity information in a trie array
		new String:sEntity[12];
		
		IntToString(ent, sEntity, sizeof(sEntity));
		
		new MoneyDroppedInfo[MoneyAttributes];
		MoneyDroppedInfo[AMOUNT] = amount;
		MoneyDroppedInfo[WHO] = UserID;
		
		// Set trie for this entity with UserID and amount information
		SetTrieArray(h_Trie, sEntity, MoneyDroppedInfo[0], 2, true);
		
		// Hook the money entity to know when a player touches it
		SDKHook(ent, SDKHook_StartTouch, StartTouch);
	}
	else
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "There was a problem creating the money entity!!");
			DebugMessage(dmsg);
		#endif
		
		LogError("Error creating money entity");
	}
}

/**
* SDKHooks Function SDKHook_StartTouch
*
* @param entity	Entity index of entity being touched
* @param other		Entity index of entity touching param entity
* @noreturn
*/
public StartTouch(entity, other)
{
	// Retrieve and store the m_ModelName of the entity being touched
	new String:model[128];
	
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	
	// Make sure "other" is a valid client/player and that the entity being touched is the defined MoneyModel
	if (other > 0 && other <= MaxClients && IsPlayerAlive(other) && StrEqual(model, MoneyModel))
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "%L is touching money entity", other);
			DebugMessage(dmsg);
		#endif
		
		// Store the money amount of the player who touched the money
		new PlayerMoney = GetEntProp(other, Prop_Send, "m_iAccount");
		
		if (PlayerMoney >= MaxCash)
		{
			CPrintToChat(other, "%t", "Max Cash");
			return;
		}
		
		HandleMoney(entity, other);		
	}
}

HandleMoney(entity, other)
{
	// Store the player's name string
	new String:OtherPlayerName[MAX_NAME_LENGTH];
	
	GetClientName(other, OtherPlayerName, sizeof(OtherPlayerName));
	
	// Convert the entity to a string to search the trie (since it requires a string)
	new String:sEntity[12];
	
	IntToString(entity, sEntity, sizeof(sEntity));
	
	new GetMoneyInfo[MoneyAttributes];
	
	// Retrieves the stored information for the money entity if it exists in the array GetMoneyInfo
	if (!GetTrieArray(h_Trie, sEntity, GetMoneyInfo[0], 2))
	{
		LogMessage("****** Money Info does not exist!!!!");
		
		// Get rid of the entity and Unhook it from SDKHook_StartTouch
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
			SDKUnhook(entity, SDKHook_StartTouch, StartTouch);
		}
		
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "The money entity [%i] did not contain any information, killing the entity", entity);
			DebugMessage(dmsg);
		#endif
		
		// Since there was no information for this money, stop processing
		return;
	}
	
	new CashAmount = GetMoneyInfo[AMOUNT];// Cash amount stored in TrieArray for the dropped money
	new UserID = GetMoneyInfo[WHO];// UserID stored in TrieAray for the dropped money
	new client = GetClientOfUserId(UserID);// Will return as 0 if invalid userid (example if they left/disconnected from the server)
	
	RemoveFromTrie(h_Trie, sEntity);// Remove the information from the Trie since we've already extracted it
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "Money data: CashAmount=%i, UserID=%i", CashAmount, UserID);
		DebugMessage(dmsg);
	#endif
	
	/**
	* Termporarliy set the PlayerName (who dropped the money) string to "a Disconnected player" 
	* in case the owner of the money entity disconnected before someone picked up the cash
	*/
	new String:PlayerName[MAX_NAME_LENGTH];
	
	Format(PlayerName, sizeof(PlayerName), "a Disconnected player");
	
	// If the player who dropped the money is still in the server (if they left, their client index would be 0)
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ClientConnected = true;
		
		// Since the player who dropped the money is still in game, set the player name
		PlayerName[0] = '\0';
		GetClientName(client, PlayerName, sizeof(PlayerName));
		
		// Store the player's money
		LosersMoney = GetEntProp(client, Prop_Send, "m_iAccount");
	}
	else
	{
		ClientConnected = false;
	}
	
	// Store the player's money who picked up the cash
	new PlayersMoney = GetEntProp(other, Prop_Send, "m_iAccount");
	new NewMoney = CashAmount + PlayersMoney;
	
	// Make sure we don't set the money beyond MaxCash.  Also, set the remainder back on the dropped money
	if (NewMoney > MaxCash)
	{
		// Set player's cash to the defined maximum value according to the cvar
		SetEntProp(other, Prop_Send, "m_iAccount", MaxCash);
		
		new diffMoney = MaxCash - PlayersMoney;// if player has 15000 and MaxCash is 16000, diffmoney should be 1000	
		new NewestMoney = CashAmount - diffMoney;// if cashamount was 8000, newestmoney should be 7000 put back on the money model
		
		if (ClientConnected)
		{
			if (LoseMoney == 3)
			{
				if (LosersMoney - diffMoney < 0)
				{
					SetEntProp(client, Prop_Send, "m_iAccount", 0);
				}
				else
				{
					SetEntProp(client, Prop_Send, "m_iAccount", LosersMoney - diffMoney);
				}
			}
			
			if (AdvertiseMode > 0 && AdvertiseMode & 2)
			{
				// Advise player that someone picked up part of the cash they dropped
				CPrintToChat(client, "%t", "Someone Picked Up Partial", OtherPlayerName, diffMoney, CashAmount);
			}
		}
		
		if (AdvertiseMode > 0 && AdvertiseMode & 4)
		{
			// Advise player that they picked up part of the money and who the cash belonged to
			CPrintToChat(other, "%t", "You Picked Up Partial", PlayerName, diffMoney, CashAmount);
		}
		
		// Since not all of the money was picked up, store new entity information in a trie array
		new MoneyDroppedInfo[MoneyAttributes];
		MoneyDroppedInfo[AMOUNT] = NewestMoney;
		MoneyDroppedInfo[WHO] = UserID;
		
		// Set TrieArray for money model with new, lower cash amount
		SetTrieArray(h_Trie, sEntity, MoneyDroppedInfo[0], 2, true);
	}
	else
	{
		// For the player who picked up the cash, set their money to the new amount
		SetEntProp(other, Prop_Send, "m_iAccount", NewMoney);
		
		if (AdvertiseMode > 0 && AdvertiseMode & 4)
		{
			// Advise player that they picked up money and who the cash belonged to
			CPrintToChat(other, "%t", "You Picked Up", PlayerName, CashAmount);
		}
		
		if (ClientConnected)
		{
			if (LoseMoney == 3)
			{
				if (LosersMoney - CashAmount < 0)
				{
					SetEntProp(client, Prop_Send, "m_iAccount", 0);
				}
				else
				{
					SetEntProp(client, Prop_Send, "m_iAccount", LosersMoney - CashAmount);
				}
			}
			
			if (AdvertiseMode > 0 && AdvertiseMode & 2)
			{
				// Advise player that someone picked up the money they dropped
				CPrintToChat(client, "%t", "Someone Picked Up", OtherPlayerName, CashAmount);
			}
		}
		
		// Get rid of the entity and Unhook it from SDKHook_StartTouch
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
			SDKUnhook(entity, SDKHook_StartTouch, StartTouch);
		}
	}
}

RunPreCache()
{
	#if _DEBUG
		DebugMessage("Running RunPreCache...");
	#endif
	
	if (strcmp(MoneyModel, ""))
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "Adding %s to the DownloadsTable", MoneyModel);
			DebugMessage(dmsg);
		#endif
		
		AddFileToDownloadsTable(MoneyModel);
	}
	else
	{
		SetFailState("There is something wrong with _model");
	}
	
	// Open the INI file and add everythin in it to download table
	new String:file[MAX_FILE_LEN];
	new String:buffer[MAX_FILE_LEN];
	
	BuildPath(Path_SM, file, sizeof(file), "configs/money.ini");
	
	new Handle:fileh = OpenFile(file, "r"); // List of modes - http://www.cplusplus.com/reference/clibrary/cstdio/fopen/
	
	if (fileh == INVALID_HANDLE)
	{
		SetFailState("money.ini file missing!!!");
	}
	
	// Go through each line of the file to add the needed files to the downloads table
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		TrimString(buffer);
   		
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer);
		}
		
		if (IsEndOfFile(fileh))
		{
			break;
		}
	}
	
	if (!PrecacheModel(MoneyModel, true))
	{
		LogError("Unsuccessful precaching of the model %s", MoneyModel);
	}
	else
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "Successfully precached model %s", MoneyModel);
			DebugMessage(dmsg);
		#endif
	}
}

SetAppend(&appended)
{
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
	{
		appended = true;
	}
}

#if _DEBUG
DebugMessage(const String:msg[], any:...)
{
	LogMessage("%s", msg);
	
	#if _DEBUG_CHAT
	PrintToChatAll("%s", msg);
	#endif
}
#endif

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public EnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StrEqual(newVal, "1"))
	{
		HookEvent("player_death", Event_PlayerDeath);
	}
	else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}
	
public PercentChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	PercentOfMoney = GetConVarInt(cvar);
}

public MaxCashChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MaxCash = GetConVarInt(cvar);
}

public LoseMoneyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	LoseMoney = GetConVarInt(cvar);
}

public DropAmountChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DropAmount = GetConVarInt(cvar);
}

public AdvertiseModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AdvertiseMode = GetConVarInt(cvar);
}

//public AdvertiseDropChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
//{
//	AdvertiseDrop = GetConVarBool(cvar);
//}

public TeamAttackDeathChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TeamAttackDeath = GetConVarBool(cvar);
}

public NoAttackerDeathChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NoAttackerDeath = GetConVarBool(cvar);
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

public OnDropImmunityChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DropImmunity = GetConVarBool(cvar);
}

public OnCustomModelChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseCustomModel = GetConVarBool(cvar);
}

public OnModelChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, MoneyModel, sizeof(MoneyModel));
}