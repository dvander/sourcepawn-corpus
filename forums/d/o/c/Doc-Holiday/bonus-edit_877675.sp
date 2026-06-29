/*
* Plugin: Bomb Bonus'
* Author: David (NcB_Sav)
* Vesion: 1.0
* 
* Description:	Get extra cash for Attempting to plant the bomb, planting the bomb, picking it up, blowing it up, Defusing, and Attempting to defuse it.
* 				T's lose cash for the bomb being defused, or droping it.
* 				CT's Lose cash for the bomb blowing up.
* 				You can turn any part of the plugin on or off
* 
* Credits:
* Greyscale for Reviewing and fixing code
* TESLA-X4 For fixing errors
* Apollyon for testing
* 
*/

#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION    "2.0"

new Handle:bomb, Handle:plant, Handle:defat, Handle:defuse, Handle:plat, Handle:gPrintType, Handle:Switch;
new Handle:bomb2, Handle:plant2, Handle:defat2, Handle:def, Handle:plat2, Handle:pikup, Handle:gPrintType2;
new defatt = 0;
new platt = 0;
new MoneyOffset;


public Plugin:myinfo = 
{
	name = "Bomb Bouns",
	author = "=(GrG)=",
	description = "Gives cash for pickup up and planting the bomb.",
	version = PLUGIN_VERSION,
	url = "http://GrGaming.com"
}

public OnPluginStart()
{
	//Public Var
	CreateConVar("bb_version", PLUGIN_VERSION, "Version of Bomb Bonus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	//Get Money Offset
	MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	//Event Hooks
	HookEvent("bomb_dropped", Event_Bomb_Drop); //Droped
	HookEvent("bomb_pickup", Event_Bomb_PickUp); //Picked Up
	HookEvent("bomb_planted", Event_Bomb_Planted); //Planted
	HookEvent("bomb_defused", Event_Bomb_Defused);
	HookEvent("bomb_begindefuse", Event_Bomb_Being_Defsued); //Defuse Attempt
	HookEvent("player_spawn", Event_player_spawn); //Player Spawn
	HookEvent("bomb_beginplant", Event_Bomb_Being_Plant); //Plant Attempt
	
	bomb = CreateConVar("bb_bombbonus", "500"); //Default for droping and picking up the bomb
	plant = CreateConVar("bb_plantbonus", "1000"); // Default for planting the bomb
	def = CreateConVar("bb_defusebonus", "1000"); // Default for defusing the bomb
	defat = CreateConVar("bb_defatt", "500"); //Default for Defuse Attempt
	plat = CreateConVar("bb_platt", "500"); // Default for Plant attempt
	
	
	//Switch Cvars
	bomb2 = CreateConVar("bb_dropon", "1") // Turns drop deduction on and off
	pikup = CreateConVar("bb_pikupon", "1") //Turns Bomb Pickup bonus on and off
	plant2 = CreateConVar("bb_planton", "1") //Turns plant bonus on and off
	defuse = CreateConVar("bb_defon", "1") //Turns Defuse bonus on and off
	defat2 = CreateConVar("bb_defaton", "1") //Turns defuse attempt bonus on and off
	plat2 = CreateConVar("bb_platon", "1") //Turns Plant attempt bonus on and off
	
	//Print Type
	gPrintType = CreateConVar("bb_print", "1", "0=Off | 1=Hint Box | 2=Chat | 3=Center Text", FCVAR_NONE,false,0.0,true,3.0); //Selects the print type for the display messages
	gPrintType2 = CreateConVar("bb_print2", "3", "0=Off | 1=Hint Box | 2=Chat | 3=Center Text", FCVAR_NONE,false,0.0,true,3.0); // Must Be different from the first one. This shows who is defusing and planting the bomb
	
	//On off Toggle
	Switch = CreateConVar("bb_toggle", "1"); //turns the plugin on and off
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	defatt = 0; //So You can get money for Defuse attempt on new round
	platt = 0; //So you can get money for Plant Attempt on new round
}

public Action:Event_Bomb_Drop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new cash = GetConVarInt(bomb);
	new playercash = GetEntData(client, MoneyOffset, 4);
	
	if(GetConVarInt(Switch) && GetConVarInt(bomb2) && IsClientInGame(client))
	{
		SetEntData(client, MoneyOffset, playercash - cash, 4, true)
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintText( client, "[SM] You have been fined %d for dropping the bomb!", cash);
			case 2:	PrintToChat(client, "\x03[SM] You have been fined %d for dropping the bomb!", cash);
			case 3:	PrintCenterText(client, "[SM] You have been fined %d for dropping the bomb!", cash);
		}
	}
}

public Action:Event_Bomb_PickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new cash = GetConVarInt(bomb);
	new playercash = GetEntData(client, MoneyOffset, 4);
	
	if(GetConVarInt(Switch) && GetConVarInt(pikup) && IsClientInGame(client))
	{
		SetEntData(client, MoneyOffset, playercash + cash, 4, true)
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintText(client, "[SM] You have received %d cash bonus for picking up the bomb!", cash);
			case 2:	PrintToChat(client, "\x03[SM] You have received %d cash bonus for picking up the bomb!", cash);
			case 3:	PrintCenterText(client, "[SM] You have received %d cash bonus for picking up the bomb!", cash);
		}
	}
}

public Action:Event_Bomb_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new cash = GetConVarInt(plant);
	new playercash = GetEntData(client, MoneyOffset, 4);
	
	if(GetConVarInt(Switch) && GetConVarInt(plant2) && IsClientInGame(client))
	{
		SetEntData(client, MoneyOffset, playercash + cash, 4, true)
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintText(client, "[SM] You have received %d cash bonus for planting the bomb!", cash);
			case 2:	PrintToChat(client, "\x03[SM] You have received %d cash bonus for planting the bomb!", cash);
			case 3:	PrintCenterText(client, "[SM] You have received %d cash bonus for planting the bomb!", cash);
		}
	}
}

public Action:Event_Bomb_Being_Defsued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new cash = GetConVarInt(defat);
	new playercash = GetEntData(client, MoneyOffset, 4);
	decl String:Name[ 32 ];
	GetClientName( client, Name, sizeof( Name ) - 1 );
	
	if(GetConVarInt(Switch) && GetConVarInt(defat2) && defatt == 0 && IsClientInGame(client))
	{
		SetEntData(client, MoneyOffset, playercash + cash, 4, true)
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintText(client, "[SM] You have received a %d cash bonus for attempting to defuse the bomb!", cash);
			case 2:	PrintToChat(client, "\x03[SM] You have received a %d cash bonus for attempting to defuse the bomb!", cash);
			case 3:	PrintCenterText(client, "[SM] You have received a %d cash bonus for attempting to defuse the bomb!", cash);
		}
		
		switch( GetConVarInt(gPrintType2) )
		{
			case 1: PrintHintTextToAll( "Warning! %s is defusing the BOMB!!", Name );
			case 2: PrintToChatAll( "\x03Warning! %s is defusing the BOMB!!", Name );
			case 3: PrintCenterTextAll( "Warning! %s is defusing the BOMB!!", Name );
		}
		
		defatt++; //Blocks defuse Exploit
	}
}

public Action:Event_Bomb_Being_Plant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new cash = GetConVarInt(plat);
	new playercash = GetEntData(client, MoneyOffset, 4);
	decl String:Name[ 32 ];
	GetClientName( client, Name, sizeof( Name ) - 1 );
	
	if(GetConVarInt(Switch) && GetConVarInt(plat2) && platt == 0 && IsClientInGame(client))
	{
		SetEntData(client, MoneyOffset, playercash + cash, 4, true)
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintText(client, "[SM] You have received a %d cash bonus for planting the bomb!", cash);
			case 2:	PrintToChat(client, "\x03[SM] You have received a %d cash bonus for planting the bomb!", cash);
			case 3:	PrintCenterText(client, "[SM] You have received a %d cash bonus for planting the bomb!", cash);
		}
		
		switch( GetConVarInt( gPrintType2))
		{
			case 1: PrintHintTextToAll( "Warning! %s is planting the BOMB!!", Name );
			case 2: PrintToChatAll( "\x03Warning! %s is planting the BOMB!!", Name );
			case 3: PrintCenterTextAll( "Warning! %s is planting the BOMB!!", Name );
		}
		platt++; //Blocks Plant exploit
	}
}

public Action:Event_Bomb_Defused(Handle:event, const String:namep[], bool:dontBroadcast )
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new cash = GetConVarInt(def);
	new playercash = GetEntData(client, MoneyOffset, 4);
	
	if(GetConVarInt(Switch) && GetConVarInt(defuse) && IsClientInGame(client))
	{
		SetEntData(client, MoneyOffset, playercash + cash, 4, true)
		switch( GetConVarInt( gPrintType))
		{
			case 1: PrintHintText(client, "[SM] You have recieved a %d bonus for defusing the bomb!", cash);
			case 2: PrintHintText(client, "\x03[SM] You have Recieved a %d bonus for defusing the bomb!", cash);
			case 3: PrintHintText(client, "[SM] You have recieved a %d bonus for defusing the bomb!", cash);
		}
	}
}
