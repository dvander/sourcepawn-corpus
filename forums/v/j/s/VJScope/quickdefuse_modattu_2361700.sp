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
#define MAX_CHOICE_LABEL_LENGTH 16

new wire
new choiceCount
new String:wirecolours[9][MAX_CHOICE_LABEL_LENGTH]
new wiremap[sizeof(wirecolours)]
new Handle:cvar_tchoice
new Handle:cvar_kithelp
new Handle:choices[9]

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
	cvar_kithelp = CreateConVar("qd_kithelp", "2", "Set number of choices removed with kits")
	choices[0] = CreateConVar("qd_choice1", "Blue", "Label for choice 1")
	choices[1] = CreateConVar("qd_choice2", "Yellow", "Label for choice 2")
	choices[2] = CreateConVar("qd_choice3", "Red", "Label for choice 3")
	choices[3] = CreateConVar("qd_choice4", "Green", "Label for choice 4")
	choices[4] = CreateConVar("qd_choice5", "", "Label for choice 5")
	choices[5] = CreateConVar("qd_choice6", "", "Label for choice 6")
	choices[6] = CreateConVar("qd_choice7", "", "Label for choice 7")
	choices[7] = CreateConVar("qd_choice8", "", "Label for choice 8")
	choices[8] = CreateConVar("qd_choice9", "", "Label for choice 9")
}

public Event_Plant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	wire = 0;
	ReadChoices();
	//let the planter choose a wire
	
	if (GetConVarInt(cvar_tchoice))
	{	
		new Handle:panel = CreatePanel()
	
		SetPanelTitle(panel, "Choose a Wire:" )
	
		DrawPanelText(panel, " ")
		
		DrawPanelText(panel, "The CT's can try guess this for an instant defuse")
		DrawPanelText(panel, "Exit, or ignore this for a random wire")
		
		DrawPanelText(panel, " ")

		DrawDefuseSelections(panel, false)
		
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, "Exit")
		
		SendPanelToClient(panel, client, PanelPlant, 5)
			
		CloseHandle(panel)
	}
}

public ReadChoices()
{
	choiceCount = 0
	for(new i = 0; i < sizeof(choices); ++i)
	{
		new String:choice[MAX_CHOICE_LABEL_LENGTH];
		GetConVarString(choices[i], choice, sizeof(choice))
		
		if(strlen(choice) > 0)
		{
			strcopy(wirecolours[choiceCount++], MAX_CHOICE_LABEL_LENGTH, choice)
		}
	}
}

public RemoveChoices()
{
	new numremove = GetConVarInt(cvar_kithelp)
	
	if(numremove < 0)
		numremove = 0;
	
	if(numremove > choiceCount - 1) 
		numremove = choiceCount - 1
	
	for(new i = 0; i < sizeof(wiremap); ++i)
		wiremap[i] = 0
		
	for(new i = 0; i < numremove; ++i)
	{
		new index = GetIndex(GetRandomInt(1, choiceCount - 1 - i))
		if(index >= 0)
			wiremap[index] = 1
		else
			PrintToServer("[QuickDefuse ERROR] Unexpected behavior from GetIndex. No defuse choice removed. numremove:%d, random:1 to %d, wiremap:%d", numremove, choiceCount - 1 - i, sizeof(wiremap));
	}
}

public GetIndex(indexToRemove) // 1 kun poistetaan ainoa vaihtoehto
{
	new currentIndex = 1
	for(new i = 1; i <= choiceCount; ++i)
	{
		if(i == wire || CheckWireForKit(i-1)) // Ignore wire if correct wire or already removed for kit
			continue
		
		if(currentIndex++ == indexToRemove) 
			return i-1
	}
	return -1
}

public CheckWireForKit(index)
{
	return wiremap[index] == 1
}

public Event_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (wire == 0)
	{
		wire = GetRandomInt(1,choiceCount)
		RemoveChoices()
	}
}


public Event_Defuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	new bool:kit = GetEventBool(event, "haskit")
	
	//show a menu to the client offering a choice to pull/cut the wire
			
	new Handle:panel = CreatePanel()
	SetPanelTitle(panel, "Choose a Wire:" )
	DrawPanelText(panel, "Ignore this to defuse normally")

	DrawPanelText(panel, " ")
	
	DrawPanelText(panel, "Get it right and the bomb is defused")
	DrawPanelText(panel, "Get it wrong and the bomb instantly explodes")
	

	DrawPanelText(panel, " ")
	
	DrawDefuseSelections(panel, kit)
	
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "Exit")

	SendPanelToClient(panel, client, PanelDefuseKit, 5)
		
	CloseHandle(panel)
}

public DrawDefuseSelections(Handle:panel, bool:kit)
{
	for(new i = 0; i < choiceCount; ++i)
	{
		DrawPanelItem(
			panel, 
			wirecolours[i], 
			(kit && CheckWireForKit(i)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT
		)
	}
}

public PanelPlant(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < choiceCount+1) //User selected a valid wire colour
	{
		wire = param2
		RemoveChoices()
		PrintToChat(param1,"\x01\x04[QuickDefuse] You chose the %s wire",wirecolours[param2-1])
	}
}

public PanelDefuseKit(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && param2 > 0 && param2 < choiceCount+1) //User selected a valid wire colour
	{
		new bombent = FindEntityByClassname(-1,"planted_c4")
	
		if (bombent)
		{
			new String:name[32]
			GetClientName(param1,name,sizeof(name))
		
			if (param2 == wire)
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0)
				PrintToChatAll("\x01\x04[QuickDefuse] %s correctly cut the %s wire for an instant C4 defusal",name,wirecolours[param2-1])
			}
			else
			{	
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				PrintToChatAll("\x01\x04[QuickDefuse] %s detonated the C4 with an incorrect wire choice of %s. The correct wire was %s",name,wirecolours[param2-1],wirecolours[wire-1])
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