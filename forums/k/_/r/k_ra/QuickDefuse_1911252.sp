/*
 *		QuickDefuse - by pRED*
 *
 *		CT's get a menu to select a wire to cut when they defuse the bomb
 *			- Choose the right wire - Instant Defuse
 *			- Choose the wrong wire - Instant Explosion
 *
 *		T's also get the option to select the correct wire, otherwise it's random
 *
 *		Ignoring the menu's or selecting exit will let the game continue normally
 *
 */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.3"

new wire
new Handle:cvar_tchoice

new String:wirecolours[4][] = {"Bleu","Jaune","Rouge","Vert"}

public Plugin:myinfo = 
{
	name = "QuickDefuse",
	author = "pRED*",
	description = "Let's CT's choose a wire for quick defusion",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_quickdefuse_version", PLUGIN_VERSION, "Quick Defuse Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	HookEvent("bomb_begindefuse", Event_Defuse, EventHookMode_Post)
	HookEvent("bomb_beginplant", Event_Plant, EventHookMode_Post)
	HookEvent("bomb_planted", Event_Planted, EventHookMode_PostNoCopy)
	
	HookEvent("bomb_abortdefuse", Event_Abort, EventHookMode_Post)
	HookEvent("bomb_abortplant", Event_Abort, EventHookMode_Post)
	
	cvar_tchoice = CreateConVar("qd_tchoice", "1", "Sets whether Terrorists can select a wire colour (QuickDefuse)")
}

public Event_Plant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	wire = 0;
	//let the planter choose a wire
	
	if (GetConVarInt(cvar_tchoice))
	{	
		new Handle:panel = CreatePanel()
	
		SetPanelTitle(panel, "Choisi un fil :" )
	
		DrawPanelText(panel, " ")
		
		DrawPanelText(panel, "les CTs peuvent tenter de désamorçer la bombe rapidement !")
		DrawPanelText(panel, "Quitter, et le fil sera choisi au hasard !")
		
		DrawPanelText(panel, " ")
		
		DrawPanelItem(panel,wirecolours[0])
		DrawPanelItem(panel,wirecolours[1])
		DrawPanelItem(panel,wirecolours[2])
		DrawPanelItem(panel,wirecolours[3])
		
		
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, "Quitter")
		
		SendPanelToClient(panel, client, PanelPlant, 5)
			
		CloseHandle(panel)
	}
}

public Event_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (wire == 0)
		wire = GetRandomInt(1,4)		
}


public Event_Defuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	new bool:kit = GetEventBool(event, "haskit")
	
	//show a menu to the client offering a choice to pull/cut the wire
			
	new Handle:panel = CreatePanel()

	SetPanelTitle(panel, "Choisi un fil :" )
	DrawPanelText(panel, "Ignorer (normal defuse)")

	DrawPanelText(panel, " ")
	
	DrawPanelText(panel, "GG ! c'est le bon fil :D")
	DrawPanelText(panel, "Pas de chance ! :/")
	
	
	if (!kit)
	{
		DrawPanelText(panel, "Sans le defuse kit, vous avez 50% de chance de désamorcer la bombe.")
		DrawPanelText(panel, "Sauf si vous choisissez le bon fil. :)")
	}
	

	DrawPanelText(panel, " ")
	
	DrawPanelItem(panel,"Bleu")
	DrawPanelItem(panel,"Jaune")
	DrawPanelItem(panel,"Rouge")
	DrawPanelItem(panel,"Vert")
	
	
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "Quitter")
	
	if (kit)
		SendPanelToClient(panel, client, PanelDefuseKit, 5)
	else
		SendPanelToClient(panel, client, PanelNoKit, 5)
		
	CloseHandle(panel)
}

public PanelPlant(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < 5) //User selected a valid wire colour
	{
		wire = param2
		PrintToChat(param1,"\x01\x04[QuickDefuse] Vous avez choisi le fil %s",wirecolours[param2-1])
	}
}

public PanelDefuseKit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < 5) //User selected a valid wire colour
	{
		new bombent = FindEntityByClassname(-1,"planted_c4")
	
		if (bombent)
		{
			new String:name[32]
			GetClientName(param1,name,sizeof(name))
		
			if (param2 == wire)
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0)
				PrintToChatAll("\x01\x04[QuickDefuse] %s Coupe le fil %s et désamorce la bombe ! GG (1:4 odds)",name,wirecolours[param2-1])
			}
			else
			{	
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				PrintToChatAll("\x01\x04[QuickDefuse] %s Fait exploser la bombe en choisissant le fil %s (3:4 odds) Le bon fil était le %s",name,wirecolours[param2-1],wirecolours[wire-1])
			}
		}
	}
}

public PanelNoKit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < 5) //User selected a valid wire colour
	{
		new bombent = FindEntityByClassname(-1,"planted_c4")
	
		if (bombent)
		{
			new String:name[32]
			GetClientName(param1,name,sizeof(name))
			
			if (param2 == wire && GetRandomInt(0,1))
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0)
				PrintToChatAll("\x01\x04[QuickDefuse] %s Coupe le fil %s et désamorce la bombe ! GG (1:8 odds)",name,wirecolours[param2-1])
			}
			else
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				if (param2 != wire)
					PrintToChatAll("\x01\x04[QuickDefuse] %s Fait exploser la bombe en choisissant le fil %s (3:4 odds) Le bon fil était le %s",name,wirecolours[param2-1],wirecolours[wire-1])
				else
					PrintToChatAll("\x01\x04[QuickDefuse] %s choisi le bon fil (%s) mais trop tard! la bombe explose !!",name,wirecolours[param2-1])
			}
		}
	}
}



public Event_Abort(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	CancelClientMenu(client)
}