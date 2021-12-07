/** HOUSE KEEPING */
#pragma semicolon 1 //tells the compiler that a semicolon signifies the end of the line


/** IMPORTS */
#include <sourcemod> //sourcemod because this is a sourcemod plugin
#include <morecolors> //colors
#include <tf2_stocks> //other important stuff




/** DEFINITIONS */
#define PLUGIN_VERSION "1.0" //plugin version


/** DECLARATIONS */
new Counts[MAXPLAYERS+1]; //array that keeps track of each individuals kill count


/** SETS ALL HANDLES EQUAL TO INVALID_HANDLE SO THAT THE PLUGIN CAN CHECK IF A HANDLE IS INVALID LATER (IT IS ALSO JUST GOOD CODING PRACTICE FOR SOURCEPAWN)*/

//HUD channel declarations
new Handle:Display; //declaration for the channel that will display each users kill count to them
new Handle:Announcer; //declaration for the channel that will announce streaks and shutdowns

//timers
new Handle:DisplayTimer[MAXPLAYERS+1]; //declaration of the timer that updates the display to the user
new Handle:WaitTimer[MAXPLAYERS+1]; //wait for reset timer
new Handle:BuffEffectTimer[MAXPLAYERS+1]; //Mini-crit buff effect timer handle
new Handle:DeathEffectTimer[MAXPLAYERS+1]; //death symbol effect timer handle

/** ConVar Declarations */
//messages
new Handle:sm_KillStreak_Message1; //message one handle
new Handle:sm_KillStreak_Message2; //message two handle
new Handle:sm_KillStreak_Message3; //message three handle
new Handle:sm_KillStreak_Message4; //message four handle
new Handle:sm_KillStreak_Message5; //message five handle
//speed
new Handle:sm_KillStreak_UserSpeed; //user speed handle
//enabled
new Handle:sm_KillStreak_HudEnabled; //convar bool that decides wether or not to show the current kills hud
//color and location
new Handle:sm_KillStreak_red; //red value
new Handle:sm_KillStreak_green; //green value
new Handle:sm_KillStreak_blue; //blue value
new Handle:sm_KillStreak_alpha; //alpha value
new Handle:sm_KillStreak_CurrentCount_x; //Current Count x location
new Handle:sm_KillStreak_CurrentCount_y; //Current Count y location
new Handle:sm_KillStreak_Message_x; //Message x location
new Handle:sm_KillStreak_Message_y; //Message y location

//client weapon tracking variable
new g_iWeapon[MAXPLAYERS+1][3]; //keeps track of the each client's three main weapons

/** PLUGIN */

/** REQUIRED PLUGIN STUFF */
public Plugin:myinfo =
{
	name = "[TF2]Kill Streak Tracker",
	author = "Dr. McSi",
	description = "Tracks, announces and rewards users for their killing streaks",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=220825"
};

//when the plugin starts
public OnPluginStart()
{
	//command for admins or donators to set streaks
	RegAdminCmd("sm_setstreak", Command_Set_Streak, ADMFLAG_SLAY); //command to set a user's kill count
	
	//hooks
	HookEvent("player_death", Event_Death); //creating a hook for the event of someone being killed
	HookEvent("player_spawn", Event_Spawn); //creating a hook for the event of someone being killed
	
	//convars
	CreateConVar("ks_version", PLUGIN_VERSION, "The convar include version", FCVAR_PLUGIN|FCVAR_NOTIFY); // the plugin version convar
	sm_KillStreak_Message1 = CreateConVar("ks_message1", "is on a killing spree", "Message showed to all players after a user reaches 5 kills (Default: NameOfUser is on a killing spree)"); //convar for the first kill streak message
	sm_KillStreak_Message2 = CreateConVar("ks_message2", "is on a killing frenzy", "Message after 10 kills(Default: NameOfUser is on a killing frenzy)"); //convar for the second kill streak message
	sm_KillStreak_Message3 = CreateConVar("ks_message3", "is on a rampage", "Message after 15 kills(Default: NameOfUser is on a rampage)"); //convar for the third kill streak message
	sm_KillStreak_Message4 = CreateConVar("ks_message4", "is a superhuman killer", "Message after 20 kills(Default: NameOfUser is a superhuman killer)"); //convar for the fourth kill streak message
	sm_KillStreak_Message5 = CreateConVar("ks_message5", "is a serial killer", "Message after 25 kills(Default: NameOfUser is a serial killer)"); //convar for the fifth kill streak message
	sm_KillStreak_UserSpeed = CreateConVar("ks_speed", "1200.0", "Speed that players on a 5 kill streak will get (Default: 1200.0)"); //convar for the speed a client will get on a 5 kill streak
	sm_KillStreak_HudEnabled = CreateConVar("ks_hud_enabled", "1", "1 = Enabled (Default), 0 = Disabled, for current kill count HUD"); //convar for current kill count hud
	sm_KillStreak_red = CreateConVar("ks_red_value", "0", "Red value in the current kill count hud, MAX = 255 (Default: 0)");	
	sm_KillStreak_green = CreateConVar("ks_green_value", "255", "Green value in the current kill count hud, MAX = 255 (Default: 255)");
	sm_KillStreak_blue = CreateConVar("ks_blue_value", "0", "Blue value in the current kill count hud, MAX = 255 (Default: 0)");
	sm_KillStreak_alpha = CreateConVar("ks_alpha_value", "255", "Alpha for the current kill count hud, MAX = 255 (Default: 255)");
	sm_KillStreak_CurrentCount_x = CreateConVar("ks_currentcount_x_location", "0.02", "X location for the current kill count hud, between 0.0 and 1.0, -1.0 = middle (Default: 0.02)");
	sm_KillStreak_CurrentCount_y = CreateConVar("ks_currentcount_y_location", "-1.0", "Y location for the current kill count hud, between 0.0 and 1.0, -1.0 = middle (Default: -1.0)");
	sm_KillStreak_Message_x = CreateConVar("ks_message_x_location", "-1.0", "X location for the hud announcer messages, between 0.0 and 1.0, -1.0 = middle (Default: -1.0)");
	sm_KillStreak_Message_y = CreateConVar("ks_message_y_location", "-1.0", "Y location for the hud announcer messages, between 0.0 and 1.0, -1.0 = middle (Default: -1.0)");
	AutoExecConfig(true, "kill_streak"); //creates a config file called kill_streak

	//HUD channels
	Display = CreateHudSynchronizer(); //setting the handle Display as a Hud channel
	Announcer = CreateHudSynchronizer(); //setting the handle Announcer as a hud channel
	
	//process target string requirement 
	LoadTranslations("common.phrases"); // ProcessTargetString requires the loading of this translation
}

/** CUSTOM PLUGIN STUFF */

public Action:Command_Set_Streak(client, args){
	if(args != 2){ //checks for the right number of command arguments
		ReplyToCommand(client, "[SM] Usage: sm_setstreak <user:id> <new kill count>"); //replies the command usage if the number of arguments for the command wasn't correct
	} else {
	
		//target
		new String:target[MAX_NAME_LENGTH]; //variable to store the command arg
		GetCmdArg(1, target, sizeof(target)); //gets the command argument
		
		//kill count
		new String:New_Count[32]; //variable to store the command argument kill count string
		GetCmdArg(2, New_Count, sizeof(New_Count)); //gets the command argument
		new Score = StringToInt(New_Count); //this does string to int to make the count string into a number amount 
		
		//Processing Target String
		new String:target_name[MAX_NAME_LENGTH]; //buffer to store the target name
		new target_list[MAXPLAYERS+1]; //variable that stores the max number of clients, **it will be full of indexes not id's**
		new target_count; //variable that stores how many targets were found
		new bool:tn_is_ml; //bool that stores wether the target string is a normal string or an ml phrase
		
		target_count = ProcessTargetString(target,client,target_list,MAXPLAYERS+1,COMMAND_FILTER_CONNECTED,target_name,sizeof(target_name),tn_is_ml); //gets all possible targets of the set streak command
		
		if(target_count <= 0) // checks that the number of found targets is more than 1
		{
			ReplyToTargetError(client, target_count); //returns an error
			return Plugin_Handled; //returns the plugin as handled
		} else {
			for(new i = 0; i < target_count; i++){ // goes through all of the targets that were found
				Counts[target_list[i]] = Score; //sets the target's kill count to the amount stored in the variable Score above
				
				//checks if the edits to a users score gave them a kill streak
				StreakCheck(target_list[i]); //checks the target to see if they are on a kill streak with their new kill count
			}
		}

		return Plugin_Handled;
	}
	
	return Plugin_Continue; //returns for the plugin to continue
}

//when someone spawns
public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast){

	new clientId = GetEventInt(event, "userid"); //getting id of the user that just joined the game
	new client = GetClientOfUserId(clientId); //getting the client index from it's user id
	Counts[client] = 0; //initializing their kill count to prevent errors and mess-ups
	
	StreakCheck(client);
	
	DisplayTimer[client] = CreateTimer(0.5,Main_Timer,any:clientId,TIMER_REPEAT); //creating the timer for the client that just joined
}

//when someone is killed
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast){
	
	//getting victim info
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); //victim
	
	//getting attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker")); //attacker
	
	//Checking if the victim was on a killing streak
	if(Counts[victim] >= 5 && victim != attacker){ //making sure it wasn't a suicide
		new String:Message[64]; //announcement message variable
		Format(Message, sizeof(Message), "%N shutdown %N", attacker, victim); //formatting the message variable to say that the "attacker shutdown victim"
		DisplayMessage(Message); //sends the shutdown message to be displayed
		
		CPrintToChatAll("{valve}[Streak Tracker] {red} %N shutdown %N", attacker, victim); //posts a shutdown message to all users in the chat
	}
	
	//setting streak counts
	Counts[attacker]++; //adding a kill to the killer's count
	Counts[victim] = 0; //reseting the killed players kill count
	
	//checking for streaks and reseting dead players' effects
	StreakCheck(attacker); //checking if the current client is on a killing streak
	ResetPlayer(victim); //reseting the effects on the player that died
}

//when a client leaves the game
public OnClientDisconnect(client){
	Counts[client] = 0;
	if(!IsClientInGame(client) && DisplayTimer[client]){ //checks to make sure that the client is actually gone
		CloseHandle(DisplayTimer[client]); //kills their timer
	}
}

//the display timer
public Action:Main_Timer(Handle:timer,any:clientId){
	new client = GetClientOfUserId(clientId);
	if(client != 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetConVarInt(sm_KillStreak_HudEnabled) != 0){ //checks if the client is in the game
		SetHudTextParams(GetConVarFloat(sm_KillStreak_CurrentCount_x), GetConVarFloat(sm_KillStreak_CurrentCount_y), 0.5, GetConVarInt(sm_KillStreak_red),GetConVarInt(sm_KillStreak_green),GetConVarInt(sm_KillStreak_blue),GetConVarInt(sm_KillStreak_alpha)); //setting HUD paramaters for the display
		if(client != 0) ShowSyncHudText(client, Display, "Streak: %i Kills", Counts[client]); //shows that client their kill count
		
		return Plugin_Continue; //repeats
	} else { //if the client isn't in the game, this returns the plugin as finished or handled
		return Plugin_Handled; //returns plugin as handled
	}
}

// checks the client for a kill streak
StreakCheck(client){ //messages are set by the convars
	
	new String:Message[64]; //declaring the message string
	new String:CVarMessage[120]; //ConVar message variable
	
	new Float:SpeedControl = GetConVarFloat(sm_KillStreak_UserSpeed); //declaring the variable that keeps track of the speed boost effect
	
	if(client != 0 && IsClientInGame(client) && IsPlayerAlive(client)) {

	
		g_iWeapon[client][0] = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary); //getting the primary weapon of the client being checked
		g_iWeapon[client][1] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //getting the secondary weapon of the client being checked
		g_iWeapon[client][2] = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); //getting the melee weapon of the client being checked
		
		//int that will be checked in the switch below
		new TempCount = Counts[client];
		if(Counts[client] > 25) //checks to see if a command has set the count higher and if it has it sets the tempcount to 25 because that is the highest value with effects
			TempCount = 25;
		
		//checks if the client's kill count is in one of the reward categories
		switch(TempCount){
			case 5: //for 5 kills
			{
				//message
				GetConVarString(sm_KillStreak_Message1, CVarMessage, sizeof(CVarMessage)); //getting the message from the ConVar
				Format(Message, sizeof(Message), "%N %s", client, CVarMessage); //setting the message that will be announced to everyone
				
				//new effect
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", SpeedControl); //SPEED: sets the clients speed based on the convar setting
			}
			
			case 10: //for 10 kills
			{
				//message
				GetConVarString(sm_KillStreak_Message2, CVarMessage, sizeof(CVarMessage)); //getting the message from the ConVar
				Format(Message, sizeof(Message), "%N %s", client, CVarMessage); //setting the message that will be announced to everyone
				
				//old effect
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", SpeedControl); //SPEED: sets the clients speed based on the convar setting
				
				//new effect
				if(TF2_IsPlayerInCondition(client, TFCond_Buffed) == false)
					BuffEffectTimer[client] = CreateTimer(0.01,Buff_Timer,any:GetClientUserId(client),TIMER_REPEAT); //MINI-CRIT BUFF: give the client the buff banner effect for the duration of the current life
			}
			
			case 15: //for 15 kills
			{
				//message
				GetConVarString(sm_KillStreak_Message3, CVarMessage, sizeof(CVarMessage)); //getting the message from the ConVar
				Format(Message, sizeof(Message), "%N %s", client, CVarMessage); //setting the message that will be announced to everyone
				
				//old effects
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", SpeedControl); //SPEED: sets the clients speed based on the convar setting
				if(TF2_IsPlayerInCondition(client, TFCond_Buffed) == false)
					BuffEffectTimer[client] = CreateTimer(0.01,Buff_Timer,any:GetClientUserId(client),TIMER_REPEAT); //MINI-CRIT BUFF: give the client the buff banner effect for the duration of the current life
				
				//new effect
				if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) == false) //checks if the player has the death symbol effect condtion
					DeathEffectTimer[client] = CreateTimer(0.01,Death_Timer,any:GetClientUserId(client),TIMER_REPEAT); //DEATH SYMBOL: puts a death symbol over the user's head
			}
			
			case 20: //for 20 kils
			{
				//message
				GetConVarString(sm_KillStreak_Message4, CVarMessage, sizeof(CVarMessage)); //getting the message from the ConVar
				Format(Message, sizeof(Message), "%N %s", client, CVarMessage); //setting the message that will be announced to everyone
				
				//old effects
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", SpeedControl); //SPEED: sets the clients speed based on the convar setting
				if(TF2_IsPlayerInCondition(client, TFCond_Buffed) == false)
					BuffEffectTimer[client] = CreateTimer(0.01,Buff_Timer,any:GetClientUserId(client),TIMER_REPEAT); //MINI-CRIT BUFF: give the client the buff banner effect for the duration of the current life
				if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) == false) //checks if the player has the death symbol effect condtion
					DeathEffectTimer[client] = CreateTimer(0.01,Death_Timer,any:GetClientUserId(client),TIMER_REPEAT); //DEATH SYMBOL: puts a death symbol over the user's head
				
				//new effect
				if(IsValidEntity(g_iWeapon[client][0])) SetAmmo(client, g_iWeapon[client][0], 999); //AMMO: checks that the primary weapon gotten before the switch statement is valid and sets the ammo to 999
				if(IsValidEntity(g_iWeapon[client][1])) SetAmmo(client, g_iWeapon[client][1], 999); //AMMO: checks that the secondary weapon gotten before the switch statement is valid and sets the ammo to 999
				if(IsValidEntity(g_iWeapon[client][2])) SetAmmo(client, g_iWeapon[client][2], 999); //AMMO: checks that the melee weapon gotten before the switch statement is valid and sets the ammo to 999
			}
			
			case 25:
			{
				//message
				GetConVarString(sm_KillStreak_Message5, CVarMessage, sizeof(CVarMessage)); //getting the message from the ConVar
				Format(Message, sizeof(Message), "%N %s", client, CVarMessage); //setting the message that will be announced to everyone
				
				//old effects
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", SpeedControl); //SPEED: sets the clients speed based on the convar setting
				if(TF2_IsPlayerInCondition(client, TFCond_Buffed) == false)
					BuffEffectTimer[client] = CreateTimer(0.01,Buff_Timer,any:GetClientUserId(client),TIMER_REPEAT); //MINI-CRIT BUFF: give the client the buff banner effect for the duration of the current life
				if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) == false) //checks if the player has the death symbol effect condtion	
					DeathEffectTimer[client] = CreateTimer(0.01,Death_Timer,any:GetClientUserId(client),TIMER_REPEAT); //DEATH SYMBOL: puts a death symbol over the user's head
					
				if(IsValidEntity(g_iWeapon[client][0])) SetAmmo(client, g_iWeapon[client][0], 999); //AMMO: checks that the primary weapon gotten before the switch statement is valid and sets the ammo to 999
				if(IsValidEntity(g_iWeapon[client][1])) SetAmmo(client, g_iWeapon[client][1], 999); //AMMO: checks that the secondary weapon gotten before the switch statement is valid and sets the ammo to 999
				if(IsValidEntity(g_iWeapon[client][2])) SetAmmo(client, g_iWeapon[client][2], 999); //AMMO: checks that the melee weapon gotten before the switch statement is valid and sets the ammo to 999
				
				//new effect
				TF2_AddCondition(client, TFCond_CritOnWin, 20.0); //FULL CRITS: gives the player end of round crits for reaching the kill streak top
				
				
				//Now that the user has maxed out the kill streak, their effects are removed and their kill's count is set to 0
				WaitTimer[client] = CreateTimer(20.0, Wait_Timer, any:GetClientUserId(client)); //the timer is to wait until the full crits has ended before it resets the user
			}
			
			default: //for anything but those 4 numbers above
			{
				Format(Message, sizeof(Message), ""); //default message is nothing
			}
		}
	}
	
	//checks for default case
	if(!StrEqual(Message, "")){ //checking that the display message has content (in other words, that it wasn't the default option that was selected) 
		CPrintToChatAll("{orange}[Streak Tracker] {royalblue} %s", Message); //posts a message to all users in the chat
		DisplayMessage(Message); //displays the message from the switch statement
	}
}

//displays message though the tf2 HUD system
DisplayMessage(String:Message[]){
	for(new i = 1; i <= GetMaxClients(); i++){ //for the number of clients in the game
		if(IsClientInGame(i)){	//checks if the client is real, in game an d a real index
			SetHudTextParams(GetConVarFloat(sm_KillStreak_Message_x), GetConVarFloat(sm_KillStreak_Message_y), 3.0, 0,0,255,255); //setting HUD paramaters for the display
			ShowSyncHudText(i, Announcer, "%s", Message); //shows that player the message
		}
	}
}

//timer for the mini-crit buff effect
public Action:Buff_Timer(Handle:timer,any:clientId){
	new client = GetClientOfUserId(clientId);
	if(IsClientInGame(client) && client != 0){ //checks that the client is in game
		TF2_AddCondition(client, TFCond_Buffed, 0.5); //adds the mini-crit buff condition
	} else {
		if(BuffEffectTimer[client] != INVALID_HANDLE) CloseHandle(BuffEffectTimer[GetClientUserId(client)]); //closes the buff effect timer
	}
}

//timer for the death symbol effect
public Action:Death_Timer(Handle:timer,any:clientId){
	new client = GetClientOfUserId(clientId);
	if(IsClientInGame(client) && client != 0){ //checks that the client is in the game
		TF2_AddCondition(client, TFCond_MarkedForDeath, 0.5); //adds the death symbol to the client
	} else {
		if(DeathEffectTimer[client] != INVALID_HANDLE) CloseHandle(DeathEffectTimer[client]); //closes the death effect timer
	
	}
}

//sets the ammo amount for the weapon of client that is passed
SetAmmo(client, weapon, ammo){
	if(IsClientInGame(client) && IsPlayerAlive(client) && client > 0){
		new AmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); //gets the type of ammo for the weapon
		if(IsValidEntity(AmmoType)) SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, AmmoType); //checks that the ammo is a real kind and sets the ammo amount for that weapon
	}
}

//timer that waits 20 seconds before it resets the user's effects
public Action:Wait_Timer(Handle:timer, any:clientId){
	new client = GetClientOfUserId(clientId);
	if(IsClientInGame(client) && client != 0){ //checks that the client is in game
		ResetPlayer(client); //resets the player
		if(WaitTimer[client] != INVALID_HANDLE) CloseHandle(WaitTimer[client]); //closes the wait timer
		WaitTimer[client] = INVALID_HANDLE; //setting invalid to stop errors
	}
}

//reseting the player's effects
ResetPlayer(client){ 
	
	if(client != 0){ //checks that player isn't rcon
		//buff effect
		if(BuffEffectTimer[client] != INVALID_HANDLE) {
			KillTimer(BuffEffectTimer[client]); //checks for invalidness and closes the timer
			BuffEffectTimer[client] = INVALID_HANDLE; //resets the buff effect timer so that it is invalid
		}
		if(TF2_IsPlayerInCondition(client, TFCond_Buffed)) //checks if the player has the buff effect condition
			TF2_RemoveCondition(client, TFCond_Buffed); //removes the buff effect condition
		
		if(DeathEffectTimer[client] != INVALID_HANDLE) {
			KillTimer(DeathEffectTimer[client]); //checks for invalidness and closes the timer
			DeathEffectTimer[client] = INVALID_HANDLE; //closes and resets the death effect timer so that it is invalid
		}
		if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath)) //checks if the player has the death symbol effect condtion
			TF2_RemoveCondition(client, TFCond_MarkedForDeath); //removes the death symbol condition
			
		if(TF2_IsPlayerInCondition(client, TFCond_CritOnWin)) //checks for and removes the round end crits condtion 
			TF2_RemoveCondition(client, TFCond_CritOnWin);
			
		//ammo	
		if(IsValidEntity(g_iWeapon[client][0])) SetAmmo(client, g_iWeapon[client][0], 50); //sets the primary weapon ammo amount to 50
		if(IsValidEntity(g_iWeapon[client][1])) SetAmmo(client, g_iWeapon[client][1], 50); //sets the secondary weapon ammo amount to 50
		if(IsValidEntity(g_iWeapon[client][2])) SetAmmo(client, g_iWeapon[client][2], 1); //sets the melee weapon ammo ammount to 1
		
		//kill count
		Counts[client] = 0; //sets their kill count to 0
	}
}