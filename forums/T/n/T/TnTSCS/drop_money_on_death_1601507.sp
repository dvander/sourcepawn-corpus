/*
* 
* 						Drop Money On Death SourceMOD Plugin
* 						Copyright (c) 2008  SAMURAI
* 
* 						Visit http://www.cs-utilz.net
*
* Special thanks to Bacardi for his Healthkit From Dead (HFD) plugin which I (TnTSCS) used as a guide for this one
* 
*/
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION "0.2.1"
#define MoneyModel "models/props/cs_assault/money.mdl"

#define 	SOLID_VPHYSICS	6
#define	DAMAGE_NO			0
#define	MAX_CSS_CASH		16000

new PercentOfMoney;
new Handle:h_Pack[2049];
new bool:PluginEnabled = true;

public Plugin:myinfo = 
{
	name = "Drop Money on Death",
	author = "SAMURAI, fixed by TnTSCS",
	description = "",
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
	CreateConVar("sm_DropMoneyOnDeath_version", PLUGIN_VERSION, "The version of 'Drop Money on Death'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	new Handle:hRandom;// KyleS Hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_DropMoneyOnDeath_enabled", "1", 
	"1=Enabled, 0=Disabled", _, true, 0.0, true, 1.0)), EnabledChanged);
	PluginEnabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_DropMoneyOnDeath_percent", "50", 
	"Percent of money to drop when player dies", _, true, 1.0, true, 100.0)), PercentChanged);
	PercentOfMoney = GetConVarInt(hRandom);
	
	CloseHandle(hRandom);
	
	// Load translation file
	LoadTranslations("DropMoneyOnDeath.phrases");
	
	HookEvent("player_death", Event_PlayerDeath);
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
	PrecacheModel(MoneyModel, true);
}

/**
*	"player_death"				// a game event, name may be 32 characters long	
*	{
*		// this extents the original player_death by a new fields
*		"userid"		"short"   	// user ID who died				
*		"attacker"		"short"	 // user ID who killed
*		"weapon"		"string" 	// weapon name killer used 
*		"headshot"	"bool"	// singals a headshot
*		"dominated"	"short"	// did killer dominate victim with this kill
*		"revenge"		"short"	// did killer get revenge on victim with this kill
*	}
*/
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!PluginEnabled)
		return;
		
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// Do not process if the player killed themselves, there was no attacker, or the player has the proper flag (defaulted to CUSTOM1)
	if(client == attacker || attacker == 0 || !attacker || CheckCommandAccess(client, "no_dropmoneyondeath", ADMFLAG_CUSTOM4))
		return;
	
	/**
	* Figure out if this is a team kill, if so, do not drop any money
	*/
	new team1 = GetClientTeam(client);
	new team2 = GetClientTeam(attacker);
	if(team1 == team2)
		return;
	
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
	
	if((ent = CreateEntityByName("prop_physics_override")) != -1)
	{
		new Float:origin[3];
		GetClientEyePosition(client, origin);// Get a higher position (eye level)
		
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);//Teleport money
		
		decl String:targetname[100];
		Format(targetname, sizeof(targetname), "money_%i", ent); // Create name for entity
		
		// Set some of the Key Values of the newly created entity
		DispatchKeyValue(ent, "model", MoneyModel); // Set the model key's name
		DispatchKeyValue(ent, "physicsmode", "2"); // Non-Solid, Server-side
		DispatchKeyValue(ent, "massScale", "10.0"); // A scale multiplier for the object's mass.  Needed to increase it otherwise it was too light
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		DispatchSpawn(ent); // Spawn
		
		// Set the entity as solid and unable to take damage
		SetEntProp(ent, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
		SetEntProp(ent, Prop_Data, "m_takedamage", DAMAGE_NO);
		
		// Get the current cash amount of the client
		new clientCash = GetEntProp(client, Prop_Send, "m_iAccount");
		
		// Figure out the percentage we should be dropping
		new amount = (clientCash * PercentOfMoney / 100);
		
		// Get the UserID of the client (player/victim)
		new UserID = GetClientUserId(client);
		
		// Need to store the amount interger as a String for the DataPack
		new String:sAmount[10];
		IntToString(amount, sAmount, sizeof(sAmount));
		
		// Create the datapack for the entity with the UserID of the player who dropped the cash and the cash amount
		h_Pack[ent] = CreateDataPack();
		
		WritePackCell(h_Pack[ent], UserID);
		WritePackString(h_Pack[ent], sAmount);
		
		// Hook the entity to know when a player touches it
		SDKHook(ent, SDKHook_StartTouch, StartTouch);
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
	decl String:model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	
	// Make sure "other" is a valid client/player
	if(other > 0 && other <= MaxClients && StrEqual(model, MoneyModel))
	{
		HandleMoney(entity, other);		
	}
}

HandleMoney(entity, other)
{
	//if(StrEqual(model, MoneyModel))
	//{
	ResetPack(h_Pack[entity]);
	
	// Retrieve the UserID from the DataPack
	new UserID = ReadPackCell(h_Pack[entity]);
	new client = GetClientOfUserId(UserID);// Returns 0 if invalid userid.
	
	// Retrieve the cash amount from the DataPack
	decl String:sAmount[10];			
	ReadPackString(h_Pack[entity], sAmount, sizeof(sAmount));			
	
	new CashAmount = StringToInt(sAmount);			
	
	// Done with DataPack - reset and close it
	ResetPack(h_Pack[entity], true);
	
	CloseHandle(h_Pack[entity]);
	
	// Termporarliy set the PlayerName string to "a Disconnected player" in case the owner of the money entity disconnected before someone picked up the cash
	decl String:PlayerName[MAX_NAME_LENGTH];
	Format(PlayerName, sizeof(PlayerName), "a Disconnected player");
	
	// If the player who dropped the money is still in the server
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client))
	{
		// Since the player who dropped the money is still in game, set the player name
		GetClientName(client, PlayerName, sizeof(PlayerName));
		
		// Adjust the player's money who dropped the cash
		new LosersMoney = GetEntProp(client, Prop_Send, "m_iAccount");
		SetEntProp(client, Prop_Send, "m_iAccount", LosersMoney - CashAmount);				
		
		// Advise player their money was picked up
		CPrintToChat(client, "%t", "Someone Picked Up", PlayerName, CashAmount);				
	}
	
	// Adjust the player's money who picked up the cash
	new PlayersMoney = GetEntProp(other, Prop_Send, "m_iAccount");
	new NewMoney = CashAmount + PlayersMoney;
	
	// Advise player that they picked up money and who it belonged to
	CPrintToChat(other, "%t", "You Picked Up", PlayerName, CashAmount);
	
	// Make sure we don't set the money beyond $16,000
	if(NewMoney >= MAX_CSS_CASH)
	{
		SetEntProp(other, Prop_Send, "m_iAccount", MAX_CSS_CASH);
	}
	else
	{			
		SetEntProp(other, Prop_Send, "m_iAccount", NewMoney);
	}
	
	// Get rid of the entity and Unhook it from SDKHook_StartTouch
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
		SDKUnhook(entity, SDKHook_StartTouch, StartTouch);
	}
	//}
}

public EnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	PluginEnabled = GetConVarBool(cvar);
}
	
public PercentChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	PercentOfMoney = GetConVarInt(cvar);
}