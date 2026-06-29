#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>


#define PLUGIN_VERSION				"1.1"
#define PLUGIN_PREFIX_PLAIN			"[Highfive Power 1.1]"
#define PLUGIN_PREFIX				"{strange}[Highfive Power]{default}"

#define MAX_CONDITION_COUNT			16
#define MAX_CONDITION_LENGTH 		22

#define TFCond_Minicrits			16
#define TFCond_AmputatorHeal		55
#define TFCond_ResistBullet			58
#define TFCond_UberResistBullet		61
#define TFCond_BotBuildingIgnore	66
#define TFCond_Giant				74
#define TFCond_Tiny					75

public Plugin:myinfo = 
{
	name = "Highfive Power",
	author = "Aderic",
	description = "Gives people with highfives special powers.",
	version = PLUGIN_VERSION
}

new clientCooldowns[MAXPLAYERS];
new conditionIds[MAX_CONDITION_COUNT];
new Float:conditionDurations[MAX_CONDITION_COUNT];
new conditionCount = 0;

new Handle:CVAR_cooldown;
new Handle:CVAR_conditions;
new Handle:CVAR_pluginVersion;

new Handle:knownConditions;

public OnPluginStart()
{
	if (GetEngineVersion() != Engine_TF2) {
		SetFailState("Incompatible game engine: This plugin was designed for TF2.");
	}
	
	HookEvent("player_connect",					OnPlayerConnect);
	HookEvent("post_inventory_application", 	OnPlayerResupply);
	
	//HookEvent("player_highfive_success", 		OnHighfived); TF2 broke the highfive hooks like a bunch of tards.
	
	knownConditions = CreateTrie();
	
	//player/recharge.wav
	
	// Write in our known values.
	SetTrieValue(knownConditions, "minicrits",				  TFCond_Minicrits);
	SetTrieValue(knownConditions, "crits",   	  		    TFCond_CritCanteen);
	SetTrieValue(knownConditions, "uber", 		 		    TFCond_Ubercharged);
	SetTrieValue(knownConditions, "speed", 				  TFCond_SpeedBuffAlly);
	SetTrieValue(knownConditions, "healing",		 	  TFCond_AmputatorHeal);
	SetTrieValue(knownConditions, "quickhealing",	 TFCond_HalloweenQuickHeal);
	SetTrieValue(knownConditions, "defense",    		  TFCond_DefenseBuffed);
	SetTrieValue(knownConditions, "resistfire", 		TFCond_SmallFireResist);
	SetTrieValue(knownConditions, "resistblast", 	   TFCond_SmallBlastResist);
	SetTrieValue(knownConditions, "resistbullet", 	 	   TFCond_ResistBullet);
	SetTrieValue(knownConditions, "uberresistfire", 	 TFCond_UberFireResist);
	SetTrieValue(knownConditions, "uberresistblast",	TFCond_UberBlastResist);
	SetTrieValue(knownConditions, "uberresistbullet",  TFCond_UberResistBullet);
	SetTrieValue(knownConditions, "ignored", 	 	  TFCond_BotBuildingIgnore);
	SetTrieValue(knownConditions, "giant", 	 	  				  TFCond_Giant);
	SetTrieValue(knownConditions, "tiny", 	 	  				   TFCond_Tiny);
	
	CVAR_cooldown =   	  CreateConVar("sm_highfiveCooldown", 	"60", 						"How long it takes before your mighty high five powers can be reactivated.", 									  FCVAR_NONE);
	CVAR_conditions =	  CreateConVar("sm_highfiveConditions", "crits 11.0;speed 15.0;healing 1.25", 	"List of conditions to add, each condition should have a time value. Refer to plugin page for more information.", FCVAR_NONE);
	
	RegAdminCmd("sm_highfiveHelp", Command_ConditionHelp, ADMFLAG_ROOT, "Enables or disables the objectives on this map.");
	
	new String:conditionString[MAX_CONDITION_COUNT*MAX_CONDITION_LENGTH];
	GetConVarString(CVAR_conditions, conditionString, MAX_CONDITION_COUNT*MAX_CONDITION_LENGTH);
	ParseConditions(conditionString, true);
	
	HookConVarChange(CVAR_conditions, 		OnConditionCVARChanged);
	CPrintToChatAll("%s Highfive a friend to gain power! You can do this every {orange}%.f{default} seconds.", PLUGIN_PREFIX, GetConVarFloat(CVAR_cooldown));
	
	AutoExecConfig(true, "highfive_power");
}
public OnConfigsExecuted() {
	CVAR_pluginVersion =  CreateConVar("sm_highfiveVersion", 	PLUGIN_VERSION, 		"Current version of the plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	HookConVarChange(CVAR_pluginVersion,    OnPluginVersionChanged);
}

// Blocks changing of the plugin version.
public OnPluginVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (StrEqual(newVal, PLUGIN_VERSION, false) == false) {
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public Action:Command_ConditionHelp(client, args) {
	ReplyToCommand(client, "|||||||||||||||||||||||||||||||||||||||||||");
	ReplyToCommand(client, "|| Available conditions for version %s. ||", PLUGIN_VERSION);
	ReplyToCommand(client, "|||||||||||||||||||||||||||||||||||||||||||");
	ReplyToCommand(client, "|| minicrits                             ||");
	ReplyToCommand(client, "|| crits                                 ||");
	ReplyToCommand(client, "|| uber                                  ||");
	ReplyToCommand(client, "|| speed                                 ||");
	ReplyToCommand(client, "|| healing                               ||");
	ReplyToCommand(client, "|| quickhealing                          ||");
	ReplyToCommand(client, "|| defense                               ||");
	ReplyToCommand(client, "|| resistfire                            ||");
	ReplyToCommand(client, "|| resistblast                           ||");
	ReplyToCommand(client, "|| resistbullet                          ||");
	ReplyToCommand(client, "|| uberresistfire                        ||");
	ReplyToCommand(client, "|| uberresistblast                        \\\\");
	ReplyToCommand(client, "|| uberresistbullet                        \\\\");
	ReplyToCommand(client, "|| ignored (Bots and Sentryguns ignore you.)||");
	ReplyToCommand(client, "|| giant                                   //");
	ReplyToCommand(client, "|| tiny                                   //");
	ReplyToCommand(client, "|||||||||||||||||||||||||||||||||||||||||||");
	ReplyToCommand(client, "If you know any condition codes you may use their numeric value instead!");
	ReplyToCommand(client, "The format to use these conditions is:");
	ReplyToCommand(client, "<id> <duration>;<id> <duration>;<id> <duration> and so on..");
	ReplyToCommand(client, "Example:");
	ReplyToCommand(client, "crits 11;speed 15.0;healing 1.25");
	ReplyToCommand(client, "Would give 11 seconds of crit, 15 seconds of speed, and 1.25 second of healing.");
}

// Blocks changing of the plugin version.
public OnConditionCVARChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	ParseConditions(newVal, false);
}

// Fires when the client respawns or touches a supply locker.
public Action:OnPlayerResupply(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (clientCooldowns[client] == 0) {
		CPrintToChat(client, "%s Highfive a friend to gain power! You can do this every {orange}%.f{default} seconds.", PLUGIN_PREFIX, GetConVarFloat(CVAR_cooldown));
		clientCooldowns[client] = 1;
	}
}
public ParseConditions(const String:conditionVal[], const bool:quiet) {
	new oldConditionCount = conditionCount;
	
	conditionCount = 0;
	new cvarLen = strlen(conditionVal);
	
	if (cvarLen == 0) {
		if (quiet == false) {
			CPrintToChatAll("%s Highfive is now {orange}disabled{default}.", PLUGIN_PREFIX);
		}
		return;
	}
	
	if (StrContains(conditionVal, " ") == -1) {
		PrintToServer("%s The condition CVAR is malformed! Each condition requires a duration.", PLUGIN_PREFIX_PLAIN);
		return;
	}
	
	// Make local copy.
	new String:conditionString[cvarLen];
	strcopy(conditionString, cvarLen+1, conditionVal);
	
	// Trim trailing semicolon if there is one.
	if (conditionString[cvarLen-1] == ';') {
		conditionString[cvarLen-1] = 0;
	}
	
	// We are working with multiple conditions.
	new String:conditions[MAX_CONDITION_COUNT][MAX_CONDITION_LENGTH];
	
	new retrievalCount = ExplodeString(conditionString, ";", conditions, MAX_CONDITION_COUNT, MAX_CONDITION_LENGTH);
	
	for (new localIndex = 0; localIndex < retrievalCount; localIndex++) {
		new breakPos = StrContains(conditions[localIndex], " ");
		
		if (breakPos == -1) {
			PrintToServer("%s The condition CVAR is malformed!", PLUGIN_PREFIX_PLAIN);
			return;
		}
		else {
			new Float:duration = StringToFloat(conditions[localIndex][breakPos+1]);
			conditions[localIndex][breakPos] = 0;
			new conditionId = FindCondition(conditions[localIndex]);
			
			if (duration == 0.0 || conditionId == -1)
			{   // Reject condition.
				PrintToServer("%s The condition CVAR is malformed! Condition name or duration is incorrect.", PLUGIN_PREFIX_PLAIN);
				conditionCount = 0;
				return;
			}
			
			// Accept condition.
			conditionIds[localIndex] = 		 conditionId;
			conditionDurations[localIndex] = duration;
			if (quiet == false) PrintToServer("%s Successfully loaded condition %i with duration %.f.", PLUGIN_PREFIX_PLAIN, conditionId, duration);
			conditionCount++;
		}
	}
	
	// Our check to see if it was disabled.
	if (oldConditionCount == 0 && conditionCount > 0) {
		CPrintToChatAll("%s Highfive a friend to gain power! You can do this every {orange}%.f{default} seconds.", PLUGIN_PREFIX, GetConVarFloat(CVAR_cooldown));
	}
}


public Action:OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
	clientCooldowns[GetClientOfUserId(GetEventInt(event, "userid"))] = 0;
}

public FindCondition(const String:condition[]) {
	new id = -1;
	
	if (GetTrieValue(knownConditions, condition, id) == false) {
		id = StringToInt(condition);
		
		if (id == 0) id = -1;
	}
	
	return id;
}
public TF2_OnConditionAdded(client, TFCond:condition) {
	if (condition != TFCond_Taunting) 
		return;
	
	new partner = GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner");
	
	if (partner == -1) 
		return;
	
	OnHighfived(client, partner);
}

// Takes about four seconds for the animation to play out, at two seconds the hand slap happens.
public OnHighfived(initiator, partner) {
	if (conditionCount == 0)
		return;
	
	new cooldown = GetConVarInt(CVAR_cooldown);
	
	//new initiator = GetEventInt(event, "initiator_entindex");
	//new partner =  	GetEventInt(event, "partner_entindex");
	
	if (cooldown > 0) {
		if (clientCooldowns[initiator] > GetTime()) {
			return;
		}
		// Set the NEXT time they can use this taunt.
		clientCooldowns[initiator] = GetTime() + cooldown;
	}
	
	new Handle:participants;
	CreateDataTimer(2.0, Tick_HighfiveWatcher, participants);
	WritePackCell(participants, initiator);
	WritePackCell(participants, partner);
	ResetPack(participants);
}

public Action:Tick_HighfiveWatcher(Handle:timer, Handle:participants) {
	new initiator = ReadPackCell(participants);
	new partner = ReadPackCell(participants);
	
	for (new cIndex = 0; cIndex < conditionCount; cIndex++) {
		// If either the initiator or the partner try to cheat a high-five, don't give them their conditions.
		if (IsClientInGame(initiator) && TF2_IsPlayerInCondition(initiator, TFCond_Taunting)) {
			TF2_AddCondition(initiator, TFCond:conditionIds[cIndex], conditionDurations[cIndex], initiator);
		}
		
		if (IsClientInGame(partner) && TF2_IsPlayerInCondition(partner, TFCond_Taunting)) {
			TF2_AddCondition(partner, TFCond:conditionIds[cIndex], conditionDurations[cIndex], partner);
		}
	}
	
	return Plugin_Stop;
}