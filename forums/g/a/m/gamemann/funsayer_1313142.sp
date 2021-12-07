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
//hint text
new Handle:PlayerDH = INVALID_HANDLE;
new Handle:SmokedH = INVALID_HANDLE;
new Handle:PouncedH = INVALID_HANDLE;
new Handle:RideH = INVALID_HANDLE;
new Handle:SpittedH = INVALID_HANDLE;
new Handle:PukedH = INVALID_HANDLE;
new Handle:ChargeH = INVALID_HANDLE;
//print text
new Handle:PlayerDP = INVALID_HANDLE;
new Handle:SmokedP = INVALID_HANDLE;
new Handle:PouncedP = INVALID_HANDLE;
new Handle:RideP = INVALID_HANDLE;
new Handle:SpittedP = INVALID_HANDLE;
new Handle:PukedP = INVALID_HANDLE;
new Handle:ChargeP = INVALID_HANDLE;
//other
new Handle:HT = INVALID_HANDLE;
new Handle:PT = INVALID_HANDLE;

public OnPluginStart()
{
	//sm_cvar
	CreateConVar("sm_cvar_version", "1.1", "the plugins version");
	//convars
	//hint text convars

	//player death
	PlayerDH = CreateConVar("player_death_ht", "you just got owned!", "what it says when the client dies HINT TEXT");

	//smoker
	SmokedH = CreateConVar("player_smoked_ht", "you just got smoked!", "what it says when a player gets smoked! HINT TEXT!");

	//hunter
	PouncedH = CreateConVar("player_pounced_ht", "you just got pounced!", "what it says when a player gets pounced by a hunter HINT TEXT!");

	//jockey
	RideH = CreateConVar("player_rided_ht", " you are gettin killed by a jockey ride!", "what it says for a jockey ride HINT TEXT");

	//spitter
	SpittedH = CreateConVar("player_spitted_ht", "you are in a guey place and getting owned!", "what it says when a spitted is spitten! HINT TEXT!");

	//boomer
	PukedH = CreateConVar("player_pauked_on_ht", "eww nobody likes you, pauk person!", "what txt u get for being pauked on by the boomer HINT TEXT!");

	//charger
	ChargeH = CreateConVar("player_charged_ht", "You Are flyen in the air hahahahah", "what txt comes up when a charger charges you! HINT TEXT!");

	//print text convars

	//player death
	PlayerDP = CreateConVar("player_death_pt", "you just got owned!", "what it says when the client dies PRINT TEXT!");

	//smoker
	SmokedP = CreateConVar("player_smoked_pt", "you just got smoked!", "what it says when a player gets smoked! PRINT TEXT!");

	//hunter
	PouncedP = CreateConVar("player_pounced_pt", "you just got pounced!", "what it says when a player gets pounced by a hunter PRINT TEXT!");

	//jockey
	RideP = CreateConVar("player_rided_pt", " you are gettin killed by a jockey ride!", "what it says for a jockey ride PRINT TEXT!");

	//spitter
	SpittedP = CreateConVar("player_spitted_pt", "you are in a guey place and getting owned!", "what it says when a spitted is spitten! PRINT TEXT!");

	//boomer
	PukedP = CreateConVar("player_pauked_on_pt", "eww nobody likes you, pauk person!", "what txt u get for being pauked on by the boomer PRINT TEXT!");

	//charger
	ChargeP = CreateConVar("player_charged_pt", "You Are flyen in the air hahahahah", "what txt comes up when a charger charges you! PRINT TEXT!");

	//other
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
				GetConVarString(PlayerDP, wow, 128);
				PrintToChat(i, " %s ", PlayerDP);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(PlayerDH, wow, 128);
				PrintHintText(i, " %s ", PlayerDH);
			}
		}
		else
		{
			//return
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
				GetConVarString(RideP, wow, 128);
				PrintToChat(i, " %s ", RideP);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(RideH, wow, 128);
				PrintHintText(i, " %s ", RideH);
			}
		}
		else
		{
			//return
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
				GetConVarString(ChargeP, wow, 128);
				PrintToChat(i, " %s ", ChargeP);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(ChargeH, wow, 128);
				PrintHintText(i, " %s ", ChargeH);
			}
		}
		else
		{
			//return
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
				GetConVarString(SpittedP, wow, 128);
				PrintToChat(i, " %s ", SpittedP);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(SpittedH, wow, 128);
				PrintHintText(i, " %s ", SpittedH);
			}
		}
		else
		{
			//return
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
				GetConVarString(PouncedP, wow, 128);
				PrintToChat(i, " %s ", PouncedP);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(PouncedH, wow, 128);
				PrintHintText(i, " %s ", PouncedH);
			}
		}
		else
		{
			//return
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
				GetConVarString(SmokedP, wow, 128);
				PrintToChat(i, " %s ", SmokedP);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(SmokedH, wow, 128);
				PrintHintText(i, " %s ", SmokedH);
			}
		}
		else
		{
			//return
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
				GetConVarString(PukedP, wow, 128);
				PrintToChat(i, " %s ", PukedP);
			}
			if (HT)
			{
				decl String:wow[128];
				GetConVarString(PukedH, wow, 128);
				PrintHintText(i, " %s ", PukedH);
			}
		}
		else
		{
			//return
		}
	}
}




	 



