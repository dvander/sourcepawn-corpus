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

new String:wirecolours[4][128] = {"Blue","Yellow","Red","Green"}

public Plugin:myinfo = 
{
	name = "QuickDefuse",
	author = "pRED*, G-Phoenix (translations mod)",
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
	LoadTranslations("QuickDefuse.phrases")
}

public Event_Plant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	wire = 0;
	//let the planter choose a wire
	
	if (GetConVarInt(cvar_tchoice))
	{	
		new String:stringt1[128]
		new String:stringt2[128]
		new String:stringt3[128]
		new String:stringt4[128]
		Format(stringt1,127, "%t", "t1")
		Format(stringt2,127, "%t", "t2")
		Format(stringt3,127, "%t", "t3")
		Format(stringt4,127, "%t", "t4")
		Format(wirecolours[0],127, "%t", "Blue")
		Format(wirecolours[1],127, "%t", "Yellow")
		Format(wirecolours[2],127, "%t", "Red")
		Format(wirecolours[3],127, "%t", "Green")
		new Handle:panel = CreatePanel()
	
		SetPanelTitle(panel, stringt1 )
	
		DrawPanelText(panel, " ")
		
		DrawPanelText(panel, stringt2)
		DrawPanelText(panel, stringt3)
		
		DrawPanelText(panel, " ")
		
		DrawPanelItem(panel,wirecolours[0])
		DrawPanelItem(panel,wirecolours[1])
		DrawPanelItem(panel,wirecolours[2])
		DrawPanelItem(panel,wirecolours[3])
		
		
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, stringt4)
		
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
	new String:stringct1[128]
	new String:stringct2[128]
	new String:stringct3[128]
	new String:stringct4[128]
	new String:stringct5[128]
	new String:stringct6[128]
	new String:stringct7[128]
	new String:stringct8[128]
	new String:stringct9[128]
	new String:stringct10[128]
	new String:stringct11[128]
	Format(stringct1,127, "%t", "ct1")
	Format(stringct2,127, "%t", "ct2")
	Format(stringct3,127, "%t", "ct3")
	Format(stringct4,127, "%t", "ct4")
	Format(stringct5,127, "%t", "ct5")
	Format(stringct6,127, "%t", "ct6")
	Format(stringct7,127, "%t", "ct7")
	Format(stringct8,127, "%t", "ct8")
	Format(stringct9,127, "%t", "ct9")
	Format(stringct10,127, "%t", "ct10")
	Format(stringct11,127, "%t", "ct11")
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	new bool:kit = GetEventBool(event, "haskit")
	
	//show a menu to the client offering a choice to pull/cut the wire
			
	new Handle:panel = CreatePanel()

	SetPanelTitle(panel, stringct1 )
	DrawPanelText(panel, stringct2)

	DrawPanelText(panel, " ")
	
	DrawPanelText(panel, stringct3)
	DrawPanelText(panel, stringct4)
	
	
	if (!kit)
	{
		DrawPanelText(panel, stringct5)
		DrawPanelText(panel, stringct6)
	}
	

	DrawPanelText(panel, " ")
	
	DrawPanelItem(panel,stringct7)
	DrawPanelItem(panel,stringct8)
	DrawPanelItem(panel,stringct9)
	DrawPanelItem(panel,stringct10)
	
	
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, stringct11)
	
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
		PrintToChat(param1,"\x01\x04[QuickDefuse]\x01 %t", "Wire Choice",wirecolours[param2-1])
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
				PrintToChatAll("\x01\x04[QuickDefuse]\x01 %t", "Correct Cut",name,wirecolours[param2-1])
			}
			else
			{	
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				PrintToChatAll("\x04[QuickDefuse]\x01 %t", "Incorrect Cut",name,wirecolours[param2-1],wirecolours[wire-1])
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
				PrintToChatAll("\x04[QuickDefuse]\x01 %t", "Correct Pull",name,wirecolours[param2-1])
			}
			else
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				if (param2 != wire)
					PrintToChatAll("\x04[QuickDefuse]\x01 %t", "Incorrect Pull",name,wirecolours[param2-1],wirecolours[wire-1])
				else
					PrintToChatAll("\x04[QuickDefuse]\x01 %t", "Correct Pull with No Kit",name,wirecolours[param2-1])
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