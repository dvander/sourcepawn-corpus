#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PERCENT      "%"

public Plugin:myinfo = 
{
	name = "Automatic Classrush",
	author = "Facksy",
	description = "Automatic Classrush votes",
	version = "1",
	url = "http://steamcommunity.com/id/iamfacksy"
}

Handle g_hCvarVshDrServer;
Handle g_hCvarEnable;
Handle g_hCvarTimer;

float The_Time;
int The_Menu_Time;

new TFClassType:class = TFClass_Unknown;

int iState = 0;

bool IsOffensive;
bool IsDefensive;
bool IsSupport;

int i1_ForCR = 0;
int i1_Count = 0;
int i1_End= 0;

int i2_Off = 0;
int i2_Def = 0;
int i2_Sup = 0;
int i2_Count = 0;
int i2_End= 0;

int i3_Scout = 0;
int i3_Soldier = 0;
int i3_Pyro = 0;
int i3_Demoman = 0;
int i3_Heavy = 0;
int i3_Engineer = 0;
int i3_Medic = 0;
int i3_Sniper = 0;
int i3_Spy = 0;
int i3_Count = 0;
int i3_End= 0;

public OnPluginStart()
{
	RegAdminCmd("sm_autoclassrush", Cmd_AutoClassrush, ADMFLAG_SLAY);
	RegAdminCmd("sm_autorush", Cmd_AutoClassrush, ADMFLAG_SLAY);
	RegAdminCmd("sm_acr", Cmd_AutoClassrush, ADMFLAG_SLAY);
	
	HookEvent("teamplay_round_start", OnTeamplayRoundStart);
	HookEvent("arena_round_start", OnArenaRoundStart);
	
	g_hCvarEnable = CreateConVar("sm_acr_enable", "1", "Set to 1 if its a vsh or dr server");
	g_hCvarVshDrServer = CreateConVar("sm_acr_vshdr_server", "0", "Set to 1 if its a vsh or dr server");
	g_hCvarTimer = CreateConVar("sm_acr_timer", "15.0", "Time in seconds to wait once a menu is displayed");
	
	The_Time = GetConVarFloat(g_hCvarTimer);
	The_Menu_Time = GetConVarInt(g_hCvarTimer) - 1;
}

//******Commands*****//

public Action:Cmd_AutoClassrush(client, args)
{
	if(!GetConVarInt(g_hCvarEnable))
	{
		PrintToChat(client, "[SM] Plugin is disabled");
		return Plugin_Handled;
	}
	if(iState == 0)
	{
		ClassrushMenu();
		iState = 1;
	}
	else if(iState == 1)
	{
		PrintToChat(client, "[SM] Vote already in progress...");
		return Plugin_Handled;
	}
	else if(iState == 2)
	{
		PrintToChat(client, "[SM] Class has already been chosed");
		return Plugin_Handled;
	}
	return Plugin_Handled;	
}

///*****Menu*****////

ClassrushMenu()
{
	new Handle:menu = CreateMenu(Menu_Handler);
	SetMenuTitle(menu, "Classrush?");
	AddMenuItem(menu, "T", "Yes");
	AddMenuItem(menu, "F", "No");
	
	SetMenuExitButton(menu, true);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			DisplayMenu(menu, i, The_Menu_Time);
		}
	}
	CreateTimer(The_Time, PreCharge1It);
}

ChooseTypeMenu()
{
	new Handle:menu = CreateMenu(Menu_Handler);
	SetMenuTitle(menu, "Class?");
	AddMenuItem(menu, "1", "Offensive");
	AddMenuItem(menu, "2", "Defensive");
	AddMenuItem(menu, "3", "Support");
	
	SetMenuExitButton(menu, true);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			DisplayMenu(menu, i, The_Menu_Time);
		}
	}
	CreateTimer(The_Time, PreCharge2It);
}

EnableOffensive()
{
	IsOffensive = true;
	new Handle:menu = CreateMenu(Menu_Handler2);
	SetMenuTitle(menu, "Class?");
	AddMenuItem(menu, "Scout", "Scout");
	AddMenuItem(menu, "Soldier", "Soldier");
	AddMenuItem(menu, "Pyro", "Pyro");
	
	SetMenuExitButton(menu, true);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			DisplayMenu(menu, i, The_Menu_Time);
		}
	}
	CreateTimer(The_Time, PreCharge3It);
}

EnableDefensive()
{
	IsDefensive = true;
	new Handle:menu = CreateMenu(Menu_Handler2);
	SetMenuTitle(menu, "Class?");
	AddMenuItem(menu, "Demoman", "Demoman");
	AddMenuItem(menu, "Heavy", "Heavy");
	AddMenuItem(menu, "Engineer", "Engineer");
	
	SetMenuExitButton(menu, true);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			DisplayMenu(menu, i, The_Menu_Time);
		}
	}
	CreateTimer(The_Time, PreCharge3It);
}

EnableSupport()
{
	IsSupport = true;
	new Handle:menu = CreateMenu(Menu_Handler2);
	SetMenuTitle(menu, "Class?");
	AddMenuItem(menu, "Medic", "Medic");
	AddMenuItem(menu, "Sniper", "Sniper");
	AddMenuItem(menu, "Spy", "Spy");
	
	SetMenuExitButton(menu, true);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			DisplayMenu(menu, i, The_Menu_Time);
		}
	}
	CreateTimer(The_Time, PreCharge3It);
}

//,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,


public Action:PreCharge1It(Handle Timer)
{
	Charge1It();
}

public Action:PreCharge2It(Handle Timer)
{
	Charge2It();
}

public Action:PreCharge3It(Handle Timer)
{
	Charge3It();
}

Charge1It()
{	
	if(i1_Count == 0)
	{
		PrintToChatAll("[SM] No one voted...");
		iState = 0;
		return false;
	}
	
	i1_End = i1_ForCR / i1_Count *100;
	if(i1_End >= 50)
	{
		PrintToChatAll("[SM] Vote successful. (Received %i%s of %i votes)", i1_End, PERCENT, i1_Count);
		ChooseTypeMenu();
	}
	if(i1_End < 50)
	{
		PrintToChatAll("[SM] Vote failed. (Received %i%s of %i votes)", i1_End, PERCENT, i1_Count);
	}
	
	i1_ForCR = 0;
	i1_Count = 0;
	i1_End = 0;
	return true;
}

Charge2It()
{
	if(i2_Count == 0)
	{
		PrintToChatAll("[SM] No one voted...");
		iState = 0;
		return false;
	}
	
	if(i2_Off > i2_Def && i2_Off > i2_Sup)
	{
		i2_End = i2_Off / i2_Count *100;
		PrintToChatAll("[SM] Vote successful, Offensive Class Win. (Received %i%s of %i votes)", i2_End, PERCENT, i2_Count);
		EnableOffensive();
	}
	if(i2_Def > i2_Off && i2_Def > i2_Sup)
	{
		i2_End = i2_Def / i2_Count *100;
		PrintToChatAll("[SM] Vote successful, Defensive Class Win. (Received %i%s of %i votes)", i2_End, PERCENT, i2_Count);
		EnableDefensive();
	}
	if(i2_Sup > i2_Off && i2_Sup > i2_Def)
	{
		i2_End = i2_Sup / i2_Count *100;
		PrintToChatAll("[SM] Vote successful, Support Class Win. (Received %i%s of %i votes)", i2_End, PERCENT, i2_Count);
		EnableSupport();
	}
	
	if(i2_Off > 0 && i2_Def > 0 && i2_Off == i2_Def)
	{
		PrintToChatAll("[SM]Equality, so I choose Defensive");
		EnableDefensive();
	}
	if(i2_Def > 0 && i2_Sup > 0 && i2_Def == i2_Sup)
	{
		PrintToChatAll("[SM]Equality, so I choose Support");
		EnableSupport();
	}
	if(i2_Sup > 0 && i2_Off > 0 && i2_Sup == i2_Off)
	{
		PrintToChatAll("[SM]Equality, so I choose Offensive");
		EnableOffensive();
	}
	
	i2_Off = 0;
	i2_Def = 0;
	i2_Sup = 0;
	i2_Count = 0;
	i2_End = 0;
	return true;
}

Charge3It()
{
	if(i3_Count == 0)
	{
		PrintToChatAll("[SM] No one voted...");
		iState = 0;
		return false;
	}
	
	if(IsOffensive)
	{
		if(i3_Scout > i3_Soldier && i3_Scout > i3_Pyro)
		{
			i3_End = i3_Scout / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Scout Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Scout;
		}
		if(i3_Soldier > i3_Scout && i3_Soldier > i3_Pyro)
		{
			i3_End = i3_Soldier / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Soldier Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Soldier;
		}
		if(i3_Pyro > i3_Soldier && i3_Pyro > i3_Scout)
		{
			i3_End = i3_Pyro / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Pyro Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Pyro;
		}
		
		if(i3_Scout > 0 && i3_Soldier > 0 && i3_Scout == i3_Soldier)
		{
			PrintToChatAll("[SM]Equality, so I choose Pyro");
			class = TFClass_Pyro;
		}
		if(i3_Soldier > 0 && i3_Pyro > 0 && i3_Soldier == i3_Pyro)
		{
			PrintToChatAll("[SM]Equality, so I choose Scout");
			class = TFClass_Scout;
		}
		if(i3_Pyro > 0 && i3_Scout > 0 && i3_Pyro == i3_Scout)
		{
			PrintToChatAll("[SM]Equality, so I choose Soldier");
			class = TFClass_Soldier;
		}
		iState = 2;
	}
	if(IsDefensive)
	{
		if(i3_Demoman > i3_Heavy && i3_Demoman > i3_Engineer)
		{
			i3_End = i3_Demoman / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Demoman Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_DemoMan;
		}
		if(i3_Heavy > i3_Demoman && i3_Heavy > i3_Engineer)
		{
			i3_End = i3_Heavy / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Heavy Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Heavy;
		}
		if(i3_Engineer > i3_Heavy && i3_Engineer > i3_Demoman)
		{
			i3_End = i3_Engineer / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Engineer Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Engineer;
		}
		
		if(i3_Demoman > 0 && i3_Heavy > 0 && i3_Demoman == i3_Heavy)
		{
			PrintToChatAll("[SM]Equality, so I choose Engineer");
			class = TFClass_Engineer;
		}
		if(i3_Heavy > 0 && i3_Engineer > 0 && i3_Heavy == i3_Engineer)
		{
			PrintToChatAll("[SM]Equality, so I choose Demoman");
			class = TFClass_DemoMan;
		}
		if(i3_Engineer > 0 && i3_Demoman > 0 && i3_Engineer == i3_Demoman)
		{
			PrintToChatAll("[SM]Equality, so I choose Heavy");
			class = TFClass_Heavy;
		}
		iState = 2;
	}
	if(IsSupport)
	{
		if(i3_Medic > i3_Sniper && i3_Medic > i3_Spy)
		{
			i3_End = i3_Medic / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Medic Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Medic;
		}
		if(i3_Sniper > i3_Medic && i3_Sniper > i3_Spy)
		{
			i3_End = i3_Sniper / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Sniper Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Sniper;
		}
		if(i3_Spy > i3_Sniper && i3_Spy > i3_Medic)
		{
			i3_End = i3_Spy / i3_Count *100;
			PrintToChatAll("[SM] Vote successful, Spy Class Win. (Received %i%s of %i votes)", i3_End, PERCENT, i3_Count);
			class = TFClass_Spy;
		}
		
		if(i3_Medic > 0 && i3_Sniper > 0 && i3_Medic == i3_Sniper)
		{
			PrintToChatAll("[SM]Equality, so I choose Spy");
			class = TFClass_Spy;
		}
		if(i3_Sniper > 0 && i3_Spy > 0 && i3_Sniper == i3_Spy)
		{
			PrintToChatAll("[SM]Equality, so I choose Medic");
			class = TFClass_Medic;
		}
		if(i3_Spy > 0 && i3_Medic > 0 && i3_Spy == i3_Medic)
		{
			PrintToChatAll("[SM]Equality, so I choose Sniper");
			class = TFClass_Sniper;
		}
		iState = 2;
	}
	i3_Scout = 0;
	i3_Soldier = 0;
	i3_Pyro = 0;
	i3_Demoman = 0;
	i3_Heavy = 0;
	i3_Engineer = 0;
	i3_Medic = 0;
	i3_Sniper = 0;
	i3_Spy = 0;
	i3_Count = 0;
	i3_End= 0;
	return true;
}

////*******************//

public Menu_Handler(Handle:menu, MenuAction:action, client, param2)
{	
	if(IsValidClient(client))
	{	
		if(action == MenuAction_End)
		{
			CloseHandle(menu);
		}
		if(action == MenuAction_Select)
		{
			decl String:info[12];	
			GetMenuItem(menu, param2, info, sizeof(info));	
			
			if(StrEqual(info, "T"))
			{
				i1_ForCR++;
				i1_Count++;
			}
			if(StrEqual(info, "F"))
			{
				i1_Count++;
			}
			
			/**/
			
			if(StrEqual(info, "1"))
			{
				i2_Off++;
				i2_Count++;
			}
			if(StrEqual(info, "2"))
			{
				i2_Def++;
				i2_Count++;
			}
			if(StrEqual(info, "3"))
			{
				i2_Sup++;
				i2_Count++;
			}
		}
	}
}

public Menu_Handler2(Handle:menu, MenuAction:action, client, param2)
{	
	if(IsValidClient(client))
	{	
		if(action == MenuAction_End)
		{
			CloseHandle(menu);
		}
		if(action == MenuAction_Select)
		{
			decl String:info[12];	
			GetMenuItem(menu, param2, info, sizeof(info));	
			
			if(StrEqual(info, "Scout"))
			{
				i3_Scout++;
				i3_Count++;
			}
			if(StrEqual(info, "Soldier"))
			{
				i3_Soldier++;
				i3_Count++;
			}
			if(StrEqual(info, "Pyro"))
			{
				i3_Pyro++;
				i3_Count++;
			}
			if(StrEqual(info, "Demoman"))
			{
				i3_Demoman++;
				i3_Count++;
			}
			if(StrEqual(info, "Heavy"))
			{
				i3_Heavy++;
				i3_Count++;
			}
			if(StrEqual(info, "Engineer"))
			{
				i3_Engineer++;
				i3_Count++;
			}
			if(StrEqual(info, "Medic"))
			{
				i3_Medic++;
				i3_Count++;
			}
			if(StrEqual(info, "Sniper"))
			{
				i3_Sniper++;
				i3_Count++;
			}
			if(StrEqual(info, "Spy"))
			{
				i3_Spy++;
				i3_Count++;
			}
		}
	}
}

public Action:OnTeamplayRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(class != TFClass_Unknown && !GetConVarInt(g_hCvarVshDrServer))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && TF2_GetClientTeam(i) == TFTeam_Red)
			{
				TF2_SetPlayerClass(i, class);
				TF2_RegeneratePlayer(i);
			}
		}
	}
}

public Action:OnArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(class != TFClass_Unknown)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(GetConVarInt(g_hCvarVshDrServer))
			{
				if(IsValidClient(i) && TF2_GetClientTeam(i) == TFTeam_Red)
				{
					TF2_SetPlayerClass(i, class);
					TF2_RegeneratePlayer(i);
				}
			}
			if(!GetConVarInt(g_hCvarVshDrServer))
			{
				if(IsValidClient(i))
				{
					TF2_SetPlayerClass(i, class);
					TF2_RegeneratePlayer(i);
				}
			}
		}
		class = TFClass_Unknown;
		iState = 0;
	}
}

stock bool:IsValidClient(client)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client) || !IsClientInGame(client))
	{
		return false; 
	}
	return true; 
}