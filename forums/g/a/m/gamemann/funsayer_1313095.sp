#include <sourcemod>
#include <sdktools>

//error codes
/*

L 10/01/2010 - 11:28:07: [SM] Native "CreateConVar" reported: Convar "sm_cvar" was not created. A console command with the same might already exist.
L 10/01/2010 - 11:28:07: [SM] Displaying call stack trace for plugin "funsayer.smx":
L 10/01/2010 - 11:28:07: [SM]   [0]  Line 27, B:\Steam\steamapps\common\left 4 dead 2\left4dead2\addons\sourcemod\scripting\funsayer.sp::OnPluginStart()
[SM] Loaded plugin funsayer.smx successfully.
*/

//all error codes are from the past but are fixed!


public Plugin:myinfo = {
	name = "fun_sayer",
	author = "gamemann",
	description = "says stuff to make fun of ppl",
	version = "1",
	url = "http://games223.com/"
};

new Handle:PlayerD = INVALID_HANDLE;
new Handle:Smoked = INVALID_HANDLE;
new Handle:Pounced = INVALID_HANDLE;
new Handle:Ride = INVALID_HANDLE;
new Handle:Spitted = INVALID_HANDLE;
new Handle:Pauked = INVALID_HANDLE;
new Handle:Charge = INVALID_HANDLE;
new Handle:HT = INVALID_HANDLE;
new Handle:PT = INVALID_HANDLE;

public OnPluginStart()
{
	//sm_cvar
	CreateConVar("sm_cvar_version", "1.1", "the plugins version");
	//convars
	PlayerD = CreateConVar("player_death_txt", "you just got owned!", "what it says when the client dies");
	Smoked = CreateConVar("player_smoked", "you just got smoked!", "what it says when a player gets smoked!");
	Pounced = CreateConVar("player_pounced", "you just got pounced!", "what it says when a player gets pounced by a hunter");
	Ride = CreateConVar("player_rided_txt", " you are gettin killed by a jockey ride!", "what it says for a jockey ride");
	Spitted = CreateConVar("player_spitted", "you are in a guey place and getting owned!", "what it says when a spitted is spitten!");
	Pauked = CreateConVar("player_pauked_on", "eww nobody likes you, pauk person!", "what txt u get for being pauked on by the boomer");
	Charge = CreateConVar("player_charged", "You Are flyen in the air hahahahah", "what txt comes up when a charger charges you!");
	HT = CreateConVar("say_in_hint_txt", "1", "allow the words to be in hint txt");
	PT = CreateConVar("say_in_print_txt", "1", "allow the words to be in print txt");

	//events
	HookEvent("player_death", PlayerDeath);
	HookEvent("jockey_ride", Jockey);
	HookEvent("charger_carry_start", Charger);
	HookEvent("entered_spit", Spitter);
	HookEvent("lunge_pounce", Hunter);
	HookEvent("tongue_grab", Smoker);
	HookEvent("fatal_vomit", Boomer);
	//now to execute the cfg
	AutoExecConfig(true, "funsayer");
}


//player death
public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{

		new userid = GetEventInt(event, "victim")
		if (userid)
		{
			if (PT)
			{
				decl String:wow[128];
				GetConVarString(PlayerD, wow, 128);
				PrintToChat(i, "%s", PlayerD);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(PlayerD, wow, 128);
				PrintHintText(i, "%s", PlayerD);
			}
		}
	}
}

//jockey
public Jockey(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{

		new userid = GetEventInt(event, "victim")
		if (userid)
		{
			if (PT)
			{
				decl String:wow[128];
				GetConVarString(Ride, wow, 128);
				PrintToChat(i, "%s", Ride);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(Ride, wow, 128);
				PrintHintText(i, "%s", Ride);
			}
		}
	}
}

//charger
public Charger(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{

		new userid = GetEventInt(event, "victim")
		if (userid)
		{
			if (PT)
			{
				decl String:wow[128];
				GetConVarString(Charge, wow, 128);
				PrintToChat(i, "%s", Charge);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(Charge, wow, 128);
				PrintHintText(i, "%s", Charge);
			}
		}
	}
}

//spitter
public Spitter(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{

		new userid = GetEventInt(event, "victim")
		if (userid)
		{
			if (PT)
			{
				decl String:wow[128];
				GetConVarString(Spitted, wow, 128);
				PrintToChat(i, "%s", Spitted);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(Spitted, wow, 128);
				PrintHintText(i, "%s", Spitted);
			}
		}
	}
}

//hunter
public Hunter(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{

		new userid = GetEventInt(event, "victim")
		if (userid)
		{
			if (PT)
			{
				decl String:wow[128];
				GetConVarString(Pounced, wow, 128);
				PrintToChat(i, "%s", Pounced);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(Pounced, wow, 128);
				PrintHintText(i, "%s", Pounced);
			}
		}
	}
}

//smoker
public Smoker(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{

		new userid = GetEventInt(event, "victim")
		if (userid)
		{
			if (PT)
			{
				decl String:wow[128];
				GetConVarString(Smoked, wow, 128);
				PrintToChat(i, "%s", Smoked);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(Smoked, wow, 128);
				PrintHintText(i, "%s", Smoked);
			}
		}
	}
}

//boomer
public Boomer(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{

		new userid = GetEventInt(event, "victim")
		if (userid)
		{
			if (PT)
			{
				decl String:wow[128];
				GetConVarString(Pauked, wow, 128);
				PrintToChat(i, "%s", Pauked);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(Pauked, wow, 128);
				PrintHintText(i, "%s", Pauked);
			}
		}
	}
}




	 



