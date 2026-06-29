#pragma		semicolon	1

#include	<sourcemod>
#include	<sdktools>

#define		PLUGIN_VERSION		"1.0.1"

/********************************************************************************************
*
*	Plugin			: [L4D/L4D2] Character Select Menu Lite
*	Version			: 1.0.1
*	Author (orig)	: MI 5
*	Author (Lite)	: Dirka_Dirka
*
*	Purpose		: Allows survivors to change their in game character or model.
*
*	Version 1.0 - Changes from v1.8 of CSM
*		- Removed all infected csm bits - this is now CSM Lite
*		- Reduced # of calls on global convar lookups
*		- Added hooks to several convars (it is noted in config file which aren't)
*		- Improved the hook on change limit to account for already used changes
*		- Reduced the # of convars for determining how to change character to 1
*		- Removed the OnClientDisconnect() call.. not needed
*		- Removed IsClientConnected() check(s).. not needed
*		- Removed global checking of admin - changed sm_csm to either be a console command or an admin command
*			Uses generic admin flag for access
*		- Fixed the menu command to not allow console access
*			Also uses ReplyToCommand now to properly respond to invalid usage
*		- Replaced PlayerIsAlive() with sourcemod function IsPlayerAlive()
*			Was this because of the infected stuff I removed?..
*		- Removed a useless timer
*		- Removed several hooks to events that are not required
*		- Now resets limits to all players on enable convar change.
*		- Other code clean-up bits I forgot to mention.
*		- Changed the convars and config file to represent that this is the "lite" version (cmsl instead of csm)
*
*	Version 1.0.1
*		- Added a hook to the l4d1 character convar
*		- Added back in OnMapEnd for the above hook
*		- Attempt at fixing glitchy weapon
*		- Removed page 2 of the menu when there is 8 options to select from (eg: characters + models - l4d1)
*		- Expanded the announcement based upon the available options (change model, character, both).
*		- Added a message informing clients when they only have 5 or less changes left.. this has a #define if you want to tweak it.
*		- Fixed memory leak when menu is canceled
*		- Added more precaching checks for the l4d1 survivors to prevent crashing
*
**********************************************************************************************/

//#define		TEAM_SPECTATOR				1
//#define		TEAM_SURVIVORS				2
#define		TEAM_INFECTED 				3
#define		CSM_MODEL_ONLY				1
#define		CSM_CHARACTER_ONLY			2
#define		CSM_MODEL_AND_CHARACTER	3

#define		CSM_CHANGE_MESSAGE			5		// when there are this many changes or less, alert the client

// DONT CHANGE THESE VALUES - YOU WILL GET SCREWY RESULTS
#define		NICK		0
#define		ROCHELLE	1
#define		COACH		2
#define		ELLIS		3
#define		BILL		4
#define		ZOEY		5
#define		FRANCIS		6
#define		LOUIS		7
#define		NICK_MODEL		8
#define		ROCHELLE_MODEL	9
#define		COACH_MODEL	10
#define		ELLIS_MODEL	11
#define		BILL_MODEL		12
#define		ZOEY_MODEL		13
#define		FRANCIS_MODEL	14
#define		LOUIS_MODEL	15
// DONT CHANGE THE ORDER OF THE FOLLOWING STRINGS - YOU CAN HOWEVER REWRITE THEM TO YOUR LANGUAGE
static	const	String:	g_sCharacters[][] = {
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill",
	"Zoey",
	"Francis",
	"Louis",
	"Nick (Model)",
	"Rochelle (Model)",
	"Coach (Model)",
	"Ellis (Model)",
	"Bill (Model)",
	"Zoey (Model)",
	"Francis (Model)",
	"Louis (Model)"
};

static	bool:	g_bEnabled;
static			g_iChangeLimit;			// max # of changes per life/map
static			g_iClientChangeLimit[MAXPLAYERS+1];
static			g_iSurvivorModels;		// used to determine if clients can change model &/or character
static	bool:	g_bL4D1Survivors;		// allow l4d1 survivors in l4d2?
static	bool:	g_bAnnounce;
static	bool:	g_bIsL4D2 = false;
static	bool:	g_bL4D1Precached = false;

public Plugin:myinfo = {
	name			= "[L4D/L4D2] Character Select Menu Lite",
	author			= "Dirka_Dirka",
	description	= "Allows survivors to change their character or model",
	version			= PLUGIN_VERSION,
	url				= "http://forums.alliedmods.net/showpost.php?p=1259450&postcount=268"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure;
	if (StrEqual(GameName, "left4dead2", false))
		g_bIsL4D2 = true;
	
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar(
		"l4d_csml_version", PLUGIN_VERSION,
		"Version of L4D Character Select Menu Lite plugin.",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	
	new Handle:Enabled = CreateConVar(
		"l4d_csml_enable", "1",
		"Toggles the CSM plugin functionality.",
		FCVAR_PLUGIN|FCVAR_SPONLY,
		true, 0.0, true, 1.0 );
	g_bEnabled = GetConVarBool(Enabled);
	HookConVarChange(Enabled, _ConVarChange__Enable);
	
	new Handle:AdminsOnly = CreateConVar(
		"l4d_csml_admins_only", "0",
		"Changes access to the sm_csm command. 1 = Admin access only (generic flag). (restart plugin if this is changed)",
		FCVAR_PLUGIN|FCVAR_SPONLY,
		true, 0.0, true, 1.0 );
	if (!GetConVarBool(AdminsOnly))
		RegConsoleCmd("sm_csm", PlayerMenuActivator, "Brings up a menu to select a different character");
	else
		RegAdminCmd("sm_csm", PlayerMenuActivator, ADMFLAG_GENERIC, "Brings up a menu to select a different character");
	
	new Handle:SurvivorModels = CreateConVar(
		"l4d_csml_model_access", "1",
		"1 = change to character (you become a clone). 2 = Re-skin (you are a doppleganger - look like the new character, but still yourself). 3 = Allow both 1 and 2.",
		FCVAR_PLUGIN|FCVAR_SPONLY,
		true, 1.0, true, 3.0 );
	g_iSurvivorModels = GetConVarInt(SurvivorModels);
	HookConVarChange(SurvivorModels, _ConVarChange__SurvivorModels);
	
	new Handle:Announce = CreateConVar(
		"l4d_csml_announce", "1",
		"Toggles the announcement of sm_csm command availability. (restart plugin if this is changed)",
		FCVAR_PLUGIN|FCVAR_SPONLY,
		true, 0.0, true, 1.0 );
	g_bAnnounce = GetConVarBool(Announce);
	
	if (g_bIsL4D2) {
		new Handle:L4D1Survivors = CreateConVar(
			"l4d_csml_l4d1_survivors", "0",
			"Toggles access to L4D1 Survivors in L4D2. Does nothing if game is L4D1. (won't work until next OnMapStart())",
			FCVAR_PLUGIN|FCVAR_SPONLY,
			true, 0.0, true, 1.0 );
		g_bL4D1Survivors = GetConVarBool(L4D1Survivors);
		if (g_bL4D1Survivors)
			SetConVarInt(FindConVar("precache_l4d1_survivors"), 1, true, true);
		HookConVarChange(L4D1Survivors, _ConVarChange__L4D1Survivors);
	}
	
	new Handle:ChangeLimit = CreateConVar(
		"l4d_csml_change_limit", "9999",
		"Sets the number of times clients can change their character per life/map.",
		FCVAR_PLUGIN|FCVAR_SPONLY,
		true, 0.0 );
	g_iChangeLimit = GetConVarInt(ChangeLimit);
	HookConVarChange(ChangeLimit, _ConVarChange__ChangeLimit);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AutoExecConfig(true, "plugin.l4d.csml");
}

public _ConVarChange__Enable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(convar);
	new value = 0;
	if (g_bEnabled)
		value = g_iChangeLimit;
	for (new i=1; i<=MaxClients; i++)
		g_iClientChangeLimit[i] = value;
}

public _ConVarChange__SurvivorModels(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iSurvivorModels = GetConVarInt(convar);
}

public _ConVarChange__L4D1Survivors(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bL4D1Survivors = GetConVarBool(convar);
	if (g_bL4D1Survivors)
		SetConVarInt(FindConVar("precache_l4d1_survivors"), 1, true, true);
	else
		SetConVarInt(FindConVar("precache_l4d1_survivors"), 0, true, true);
}

public _ConVarChange__ChangeLimit(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iChangeLimit = GetConVarInt(convar);
	
	for (new i=1; i<=MaxClients; i++)  {
		if (g_iChangeLimit == 0) {						// basically disables csm
			g_iClientChangeLimit[i] = 0;
		} else {
			g_iClientChangeLimit[i] -= g_iChangeLimit - StringToInt(oldValue);
			if (g_iClientChangeLimit[i] < 1)			// give the player 1 change if he wouldn't have any left
				g_iClientChangeLimit[i] = 1;
		}
	}
}

public OnClientPutInServer(client) {
	if (!g_bEnabled || (g_iChangeLimit == 0))
		return;
	
	if ((client > 0) && (client <= MaxClients) && !IsFakeClient(client)) {
		g_iClientChangeLimit[client] = g_iChangeLimit;
		if (g_bAnnounce)
			CreateTimer(30.0, AnnounceCharSelect, client);
	}
}

public OnMapStart() {
	//Precache models here so that the server doesn't crash
	if (g_bIsL4D2 && g_bL4D1Survivors) {
		SetConVarInt(FindConVar("precache_l4d1_survivors"), 1, true, true);
		if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))	PrecacheModel("models/survivors/survivor_teenangst.mdl", true);
		if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))		PrecacheModel("models/survivors/survivor_biker.mdl", true);
		if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))	PrecacheModel("models/survivors/survivor_manager.mdl", true);
		if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))		PrecacheModel("models/survivors/survivor_namvet.mdl", true);
		g_bL4D1Precached = true;
	}
}

public OnMapEnd() {
	g_bL4D1Precached = false;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((client > 0) && (client <= MaxClients) && !IsFakeClient(client))
		g_iClientChangeLimit[client] = g_iChangeLimit;
}

public Action:PlayerMenuActivator(client, args) {
	if (client == 0) {
		ReplyToCommand(client, "[CSM] Character Select Menu is in-game only.");
		return;
	}
	if ((g_iChangeLimit == 0) || !g_bEnabled) {
		ReplyToCommand(client, "[CSM] Character Select Menu is currently disabled.");
		return;
	}
	if (GetClientTeam(client) == TEAM_INFECTED) {
		ReplyToCommand(client, "[CSM] Character Select Menu is only available to survivors.");
		return;
	}
	if (!IsPlayerAlive(client)) {
		ReplyToCommand(client, "[CSM] You must be alive to use the Character Select Menu!");
		return;
	}
	if (g_iClientChangeLimit[client] < 1) {
		ReplyToCommand(client, "[CSM] You cannot change your character again until you respawn.");
		return;
	}
	
	decl String:sMenuEntry[8];
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Choose a character:");
	if (g_iSurvivorModels != CSM_MODEL_ONLY) {
		if (g_bIsL4D2) {
			IntToString(NICK, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Nick");
			IntToString(ROCHELLE, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Rochelle");
			IntToString(COACH, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Coach");
			IntToString(ELLIS, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Ellis");
			if (g_bL4D1Survivors && g_bL4D1Precached) {
				//IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
				//AddMenuItem(menu, sMenuEntry, "Bill");		// bill is not allowed because of missing elements - need a vpk
				IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Zoey");
				IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Francis");
				IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Louis");
			}
		} else {
			IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Bill");
			IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Zoey");
			IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Francis");
			IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Louis");
		}
	}
	if (g_iSurvivorModels != CSM_CHARACTER_ONLY) {
		if (g_bIsL4D2) {
			IntToString(NICK_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Nick (Model)");
			IntToString(ROCHELLE_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Rochelle (Model)");
			IntToString(COACH_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Coach (Model)");
			IntToString(ELLIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Ellis (Model)");
			if (g_bL4D1Survivors && g_bL4D1Precached) {
				IntToString(BILL_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Bill (Model)");
				IntToString(ZOEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Zoey (Model)");
				IntToString(FRANCIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Francis (Model)");
				IntToString(LOUIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Louis (Model)");
			}
		} else {
			IntToString(BILL_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Bill (Model)");
			IntToString(ZOEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Zoey (Model)");
			IntToString(FRANCIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Francis (Model)");
			IntToString(LOUIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Louis (Model)");
		}
	}
	// if not showing characters + models + l4d1, there should only be 4 or 8 options - dont paginate.
	if ((g_iSurvivorModels != CSM_MODEL_AND_CHARACTER)
		|| ((g_iSurvivorModels == CSM_MODEL_AND_CHARACTER) && !g_bL4D1Survivors))
		SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Action:AnnounceCharSelect(Handle:timer, any:client) {
	if (IsClientInGame(client)) {
		switch (g_iSurvivorModels) {
			case CSM_MODEL_ONLY:
				PrintToChat(client, "\x03[CSM]\x01 Type \x05!csm\x01 in chat to change your model (just your skin: what others see, but not hear).");
			case CSM_CHARACTER_ONLY:
				PrintToChat(client, "\x03[CSM]\x01 Type \x05!csm\x01 in chat to change your character (become a clone).");
			case CSM_MODEL_AND_CHARACTER:
				PrintToChat(client, "\x03[CSM]\x01 Type \x05!csm\x01 in chat to change your character (become a clone) or model (just your skin: what others see, but not hear).");
		}
	}
}

public CharMenu(Handle:menu, MenuAction:action, param1, param2) {
	switch (action) {
		case MenuAction_Select: {
			decl String:item[8];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			switch(StringToInt(item)) {
				case NICK:		{	SetUpSurvivor(param1, NICK);		}
				case ROCHELLE:	{	SetUpSurvivor(param1, ROCHELLE);	}
				case COACH:		{	SetUpSurvivor(param1, COACH);		}
				case ELLIS:		{	SetUpSurvivor(param1, ELLIS);		}
				case BILL:		{	SetUpSurvivor(param1, BILL);		}
				case ZOEY:		{	SetUpSurvivor(param1, ZOEY);		}
				case FRANCIS:	{	SetUpSurvivor(param1, FRANCIS);	}
				case LOUIS:		{	SetUpSurvivor(param1, LOUIS);		}
				
				case NICK_MODEL:		{	SetUpSurvivorModel(param1, NICK);			}
				case ROCHELLE_MODEL:	{	SetUpSurvivorModel(param1, ROCHELLE);	}
				case COACH_MODEL:		{	SetUpSurvivorModel(param1, COACH);		}
				case ELLIS_MODEL:		{	SetUpSurvivorModel(param1, ELLIS);		}
				case BILL_MODEL:		{	SetUpSurvivorModel(param1, BILL);			}
				case ZOEY_MODEL:		{	SetUpSurvivorModel(param1, ZOEY);			}
				case FRANCIS_MODEL:	{	SetUpSurvivorModel(param1, FRANCIS);		}
				case LOUIS_MODEL:		{	SetUpSurvivorModel(param1, LOUIS);		}
			}
		} 
		case MenuAction_Cancel, MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

stock SetUpSurvivor(param1, Survivor) {
	if (g_bIsL4D2) {
		switch(Survivor) {
			case NICK:		{	SetCharacter(param1, NICK);		}
			case ROCHELLE:	{	SetCharacter(param1, ROCHELLE);	}
			case COACH:		{	SetCharacter(param1, COACH);		}
			case ELLIS:		{	SetCharacter(param1, ELLIS);		}
			case BILL:		{	/* Cant do bill in l4d2 w/o vpk */	}
			case ZOEY:		{	SetCharacter(param1, ZOEY);		}
			case FRANCIS:	{	SetCharacter(param1, FRANCIS);	}
			case LOUIS:		{	SetCharacter(param1, LOUIS);		}
		}
	} else {
		switch(Survivor) {
			case BILL:		{	SetCharacter(param1, (BILL - 4));		}
			case ZOEY:		{	SetCharacter(param1, (ZOEY - 4));		}
			case FRANCIS:	{	SetCharacter(param1, (FRANCIS - 4));	}
			case LOUIS:		{	SetCharacter(param1, (LOUIS - 4));	}
		}
	}
	SetClientClassModel(param1, Survivor);
	FixWeapon(param1);
	g_iClientChangeLimit[param1]--;
	if (g_iClientChangeLimit[param1] <= CSM_CHANGE_MESSAGE) {
		if (g_iClientChangeLimit[param1] == 0)
			PrintToChat(param1, "\x03[CSM]\x01 Your character is now \x04%s\x01! You cannot change again until you respawn.", g_sCharacters[Survivor]);
		else if (g_iClientChangeLimit[param1] == 1)
			PrintToChat(param1, "\x03[CSM]\x01 Your character is now \x04%s\x01! You only have \x051\x01 change left.", g_sCharacters[Survivor]);
		else
			PrintToChat(param1, "\x03[CSM]\x01 Your character is now \x04%s\x01! You have \x05%i\x01 changes left.", g_sCharacters[Survivor], g_iClientChangeLimit[param1]);
	} else {
		PrintToChat(param1, "\x03[CSM]\x01 Your character is now \x04%s\x01!", g_sCharacters[Survivor]);
	}
}

stock SetUpSurvivorModel(param1, Survivor) {
	SetClientClassModel(param1, Survivor);
	FixWeapon(param1);
	g_iClientChangeLimit[param1]--;
	if (g_iClientChangeLimit[param1] <= CSM_CHANGE_MESSAGE)
		if (g_iClientChangeLimit[param1] == 0)
			PrintToChat(param1, "\x03[CSM]\x01 Your character is now \x04%s\x01! You cannot change again until you respawn.", g_sCharacters[Survivor+8]);
		else if (g_iClientChangeLimit[param1] == 1)
			PrintToChat(param1, "\x03[CSM]\x01 Your character is now \x04%s\x01! You only have \x051\x01 change left.", g_sCharacters[Survivor+8]);
		else
			PrintToChat(param1, "\x03[CSM]\x01 Your model is now \x04%s\x01! You have \x05%i\x01 changes left.", g_sCharacters[Survivor+8], g_iClientChangeLimit[param1]);
	else
		PrintToChat(param1, "\x03[CSM]\x01 Your model is now \x04%s\x01!", g_sCharacters[Survivor+8]);
}

stock SetCharacter(client, character) {
	SetEntProp(client, Prop_Send, "m_survivorCharacter", character);
}

stock SetClientClassModel(client, character) {
	switch(character) {
		case NICK:		{	SetEntityModel(client, "models/survivors/survivor_gambler.mdl");		}
		case ROCHELLE:	{	SetEntityModel(client, "models/survivors/survivor_producer.mdl");		}
		case COACH:		{	SetEntityModel(client, "models/survivors/survivor_coach.mdl");		}
		case ELLIS:		{	SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");		}
		case BILL:		{	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");		}
		case ZOEY:		{	SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");	}
		case FRANCIS:	{	SetEntityModel(client, "models/survivors/survivor_biker.mdl");		}
		case LOUIS:		{	SetEntityModel(client, "models/survivors/survivor_manager.mdl");		}
	}
}

stock FixWeapon(client) {
	// attempt at fixing the glitch gun
	decl String:sCurrentWeapon[64], String:sMelee[64];
	GetClientWeapon(client, sCurrentWeapon, sizeof(sCurrentWeapon));
	if (StrEqual(sCurrentWeapon, "weapon_melee"))
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", sMelee, sizeof(sMelee));
	
	new entity;
	for (new i=0; i<4; i++) {
		entity = GetPlayerWeaponSlot(client, i);
		if (IsValidEdict(entity)) {
			decl String:sWeaponSlot[64];
			GetEdictClassname(entity, sWeaponSlot, sizeof(sWeaponSlot));
			if (StrEqual(sCurrentWeapon, sWeaponSlot))
				break;
		}
	}
	RemovePlayerItem(client, entity);
	EquipPlayerWeapon(client, entity);
}
