#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION	"1.1" // somebody told me I should do this

//Note: you should really use a sourcepawn highlighter when viewing my code; it's unreadable otherwise

new Handle:eight_hours_minimum = INVALID_HANDLE;
new Handle:five_hour_energy = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "QuickNap",
	author = "kaffaljidhma",  //Props to Fyren and _pk and predcrab for telling me to rtfm
	description = "Have you had your break today",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	//Thanks MatthiasVance
	CreateConVar("QuickNap", PLUGIN_VERSION, "QuickNap Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY); //What's FCVAR replicated do
	eight_hours_minimum = CreateConVar("forty_winks", "1", "Players rest between rounds");
	five_hour_energy = CreateConVar("coffee_mug", "1", "Players can choose if they want the 50 health or not");
	//RegAdminCmd("weaponslots", Weapon_Slots, ADMFLAG_CHEATS);
	//RegAdminCmd("damagevars", Damage_Vars, ADMFLAG_CHEATS);
	HookEvent("player_transitioned", Event_player_transitioned);  //This was the soonest event I could find after the map jump
	AutoExecConfig(true);
}

/*
public Action:Damage_Vars(client,args){
	
	//PrintToChatAll("m_nPoisonDmg: %d",GetEntProp(client, Prop_Data, "m_nPoisonDmg"));
	//PrintToChatAll("m_nPoisonRestored: %d",GetEntProp(client, Prop_Data, "m_nPoisonRestored"));
	StripAndExecuteClientCommand(client, "give", "pain_pills", "", "");
	Qualifier(client);
	//PrintToChatAll("m_healthBuffer: %f",GetEntPropFloat(client, Prop_Send, "m_healthBuffer"));
	//PrintToChatAll("m_healthBufferTime: %f",GetEntPropFloat(client, Prop_Send, "m_healthBufferTime"));
	//SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 15.0);
	//SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0);
	//PrintToChatAll("m_healthBuffer: %f",GetEntPropFloat(client, Prop_Send, "m_healthBuffer"));
	//PrintToChatAll("m_healthBufferTime: %f",GetEntPropFloat(client, Prop_Send, "m_healthBufferTime"));
	//PrintToChatAll("m_iHealth: %d",GetEntProp(client, Prop_Send, "m_iHealth"));
}


public Action:Weapon_Slots(client,args){
	if(GetConVarInt(eight_hours_minimum) == 1){
		PrintToChatAll("Slot 1: %d", GetPlayerWeaponSlot(client, 0));
		PrintToChatAll("Slot 2: %d", GetPlayerWeaponSlot(client, 1));
		PrintToChatAll("Slot 3: %d", GetPlayerWeaponSlot(client, 2));
		PrintToChatAll("Slot 4: %d", GetPlayerWeaponSlot(client, 3));
		PrintToChatAll("Slot 5: %d", GetPlayerWeaponSlot(client, 4));
	}
	return Plugin_Handled;
}



//Pay no attention to this, it's a bastard function

public Action:Event_player_transitioned(Handle:event, const String:name[], bool:dontBroadcast) {	
	new client[MaxClients + 1];
	for(new count = 0; count < (MaxClients + 1); count++) {
		if(GetConVarInt(eight_hours_minimum) == 1 && IsClientConnected(client[count + 1]) && GetClientTeam(client[count + 1]) == 1){
			if((GetPlayerWeaponSlot(client[count + 1], 0) == 450 || GetPlayerWeaponSlot(client[count + 1], 0) == 200 || GetPlayerWeaponSlot(client[count + 1], 0) == -1) && GetPlayerWeaponSlot(client[count + 1], 1) == 201 && GetPlayerWeaponSlot(client[count + 1], 2) == -1 && GetPlayerWeaponSlot(client[count + 1], 3) == -1 && GetPlayerWeaponSlot(client[count + 1], 4) == -1 && GetClientHealth(client[count + 1]) < 50) {
				PrintToChat(client[count + 1], "You qualify for the health bonus");
				SetEntityHealth(client[count + 1], 50);
			}
		}
	}
	return Plugin_Continue;
}
*/

public Action:Event_player_transitioned(Handle:event, const String:name[], bool:dontBroadcast) {	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	//need to separate these if statements because I'd get a lot of errors otherwise
	if(GetConVarInt(eight_hours_minimum) == 1 && IsClientConnected(client) && GetClientTeam(client) == 2){
		new String:slot2[30];
		new String:slot1[30];
		//Passing -1 through GetEdictClassname does not very nice things
		if(GetPlayerWeaponSlot(client, 0) != -1) {
			GetEdictClassname(GetPlayerWeaponSlot(client, 0),slot1,sizeof(slot1));
		} else {
			slot1 = "no_weapon";
		}
		GetEdictClassname(GetPlayerWeaponSlot(client, 1),slot2,sizeof(slot2));
		//If statement is basically: starter weapon, single pistol, no extra items, <50 health
		//I only told you that because otherwise you'd have to h-scroll a whole lot
		if((StrEqual(slot1, "weapon_smg") || StrEqual(slot1, "weapon_pumpshotgun") || StrEqual(slot1,"no_weapon")) && StrEqual(slot2, "weapon_pistol") && GetPlayerWeaponSlot(client, 2) == -1 && GetPlayerWeaponSlot(client, 3) == -1 && GetPlayerWeaponSlot(client, 4) == -1 && GetClientHealth(client) < 50) {
			if(GetConVarInt(five_hour_energy) == 1) {
				Qualifier(client);
			} else {
				//PrintToChat(client, "You qualify for the health bonus");
				//PrintToConsole(client, "You qualify for the health bonus");
				//new healthdeficit = GetClientHealth(client) + 50;
				//IMPORTANT: Just using SetEntityHealth will mess up the health bar display
				StripAndExecuteClientCommand(client, "give", "health", "", "");
				//new health = GetClientHealth(client);
				SetEntityHealth(client, 50);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0); // Gets rid of temp and pill health
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0); // I dunno what this does
				//PrintToChat(client, "Slot 1: %s", slot1);
				//PrintToChat(client, "Slot 2: %s", slot2);
				//PrintToChat(client, "Slot 3: %d", GetPlayerWeaponSlot(client, 2));
				//PrintToChat(client, "Slot 4: %d", GetPlayerWeaponSlot(client, 3));
				//PrintToChat(client, "Slot 5: %d", GetPlayerWeaponSlot(client, 4));
				//PrintToChat(client, "Health: %d", GetClientHealth(client));
			}
		}
	}
	return Plugin_Continue;
}

//Sometimes, people want to keep their temp health.  This will allow them to do so.
public Action:Qualifier(client)
{
	new Handle:menu = CreateMenu(Qualifier_Handler);
	SetMenuTitle(menu, "Do you want the standard 50 health?");
	AddMenuItem(menu, "accept", "Accept");
	AddMenuItem(menu, "do not accept", "Dismiss");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public Qualifier_Handler(Handle:menu, MenuAction:action, client, item) {
	// Yeah, I know.  A single item switch.  I may just add upon it.  I may!
	if(action == MenuAction_Select){
		if(item == 0) {
			//IMPORTANT: Just using SetEntityHealth will mess up the health bar display
			StripAndExecuteClientCommand(client, "give", "health", "", "");
			//new health = GetClientHealth(client);
			SetEntityHealth(client, 50);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0); // Gets rid of temp and pill health
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", 0.0); // I dunno what this does
		}
	//Uncomment CloseHandle if you want the quickest way to exit left 4 dead
	//CloseHandle(menu);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3);
	SetCommandFlags(command, flags);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
