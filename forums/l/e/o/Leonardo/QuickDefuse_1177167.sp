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

new String:wirecolours[5][] = {"Blue","Yellow","Red","Green","Black"}

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
	LoadTranslations("quickdefuse.phrases")
	
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
	new String:textstring[128]
	
	wire = 0;
	//let the planter choose a wire
	
	if (GetConVarInt(cvar_tchoice))
	{	
		new Handle:panel = CreatePanel()
	
		Format(textstring, sizeof(textstring), "%t:", "Choose a Wire")
		SetPanelTitle(panel, textstring )
	
		DrawPanelText(panel, " ")
		
		Format(textstring, sizeof(textstring), "%t", "Choose a Wire1")
		DrawPanelText(panel, textstring)
		Format(textstring, sizeof(textstring), "%t", "Choose a Wire2")
		DrawPanelText(panel, textstring)
		
		DrawPanelText(panel, " ")
		
		Format(textstring, sizeof(textstring), "%t", wirecolours[0])
		DrawPanelItem(panel,textstring)
		Format(textstring, sizeof(textstring), "%t", wirecolours[1])
		DrawPanelItem(panel,textstring)
		Format(textstring, sizeof(textstring), "%t", wirecolours[2])
		DrawPanelItem(panel,textstring)
		Format(textstring, sizeof(textstring), "%t", wirecolours[3])
		DrawPanelItem(panel,textstring)
		Format(textstring, sizeof(textstring), "%t", wirecolours[4])
		DrawPanelItem(panel,textstring)
		
		
		DrawPanelText(panel, " ");
		Format(textstring, sizeof(textstring), "%t", "Exit")
		DrawPanelItem(panel, textstring)
		
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
	new String:textstring[128]
	
	//show a menu to the client offering a choice to pull/cut the wire
			
	new Handle:panel = CreatePanel()

	Format(textstring, sizeof(textstring), "%t:", "Choose a Wire")
	SetPanelTitle(panel, textstring )
	Format(textstring, sizeof(textstring), "%t", "Choose a Wire3")
	DrawPanelText(panel, textstring )

	DrawPanelText(panel, " ")
	
	
	Format(textstring, sizeof(textstring), "%t", "Choose a Wire4")
	DrawPanelText(panel, textstring )
	Format(textstring, sizeof(textstring), "%t", "Choose a Wire5")
	DrawPanelText(panel, textstring )
	
	
	/*if (!kit)
	{
		Format(textstring, sizeof(textstring), "%t", "No Kit1")
		DrawPanelText(panel, textstring )
		Format(textstring, sizeof(textstring), "%t", "No Kit2")
		DrawPanelText(panel, textstring )
	}*/
	

	DrawPanelText(panel, " ")
	
	Format(textstring, sizeof(textstring), "%t", "Blue")
	DrawPanelItem(panel,textstring)
	Format(textstring, sizeof(textstring), "%t", "Yellow")
	DrawPanelItem(panel,textstring)
	Format(textstring, sizeof(textstring), "%t", "Red")
	DrawPanelItem(panel,textstring)
	Format(textstring, sizeof(textstring), "%t", "Green")
	DrawPanelItem(panel,textstring)
	Format(textstring, sizeof(textstring), "%t", "Black")
	DrawPanelItem(panel,textstring)
	
	
	DrawPanelText(panel, " ")
	Format(textstring, sizeof(textstring), "%t", "Exit")
	DrawPanelItem(panel, textstring)
	
	if (kit)
		SendPanelToClient(panel, client, PanelDefuseKit, 5)
	else
		SendPanelToClient(panel, client, PanelNoKit, 5)
		
	CloseHandle(panel)
}

public PanelPlant(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < 6) //User selected a valid wire colour
	{
		wire = param2
		PrintToChat(param1,"\x01\x04%t %t %t","T Choosen1",wirecolours[param2-1],"T Choosen2")
	}
}

public PanelDefuseKit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < 6) //User selected a valid wire colour
	{
		new bombent = FindEntityByClassname(-1,"planted_c4")
	
		if (bombent>0)
		{
			new String:name[32]
			GetClientName(param1,name,sizeof(name))
		
			if (param2 == wire)
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0)
				PrintToChatAll("\x01\x04%s %t %t %t",name,"CT Done1",wirecolours[param2-1],"CT Done2")
			}
			else
			{	
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				PrintToChatAll("\x01\x04%s %t %t %t %t",name,"CT Fail1",wirecolours[param2-1],"CT Fail2",wirecolours[wire-1])
			}
		}
	}
}

public PanelNoKit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < 6) //User selected a valid wire colour
	{
		new bombent = FindEntityByClassname(-1,"planted_c4")
	
		if (bombent>0)
		{
			new String:name[32]
			GetClientName(param1,name,sizeof(name))
			
			if (param2 == wire && GetRandomInt(0,1))
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0)
				PrintToChatAll("\x01\x04%s %t %t %t",name,"CT Done No Kit1",wirecolours[param2-1],"CT Done No Kit2")
			}
			else
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				if (param2 != wire)
					PrintToChatAll("\x01\x04%s %t %t %t %t",name,"CT Fail No Kit1a",wirecolours[param2-1],"CT Fail No Kit2a",wirecolours[wire-1])
				else
					PrintToChatAll("\x01\x04%s %t %t %t!",name,"CT Fail No Kit1b",wirecolours[param2-1],"CT Fail No Kit2b")
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