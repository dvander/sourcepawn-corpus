#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <adminmenu>


#define PLUGIN_VERSION "0.3"

#define YELLOW               0x01
#define NAME_TEAMCOLOR       0x02
#define TEAMCOLOR            0x03
#define GREEN                0x04 

public Plugin:myinfo =
{
	name = "Смена команды",
	author = "https://l4d2noob.ru/",
	description = "Смена команды игрока через админку",
	version = PLUGIN_VERSION,
	url = "https://l4d2noob.ru/topic/374-peremeschenie-igroka-v-druguyu-komandu-swapper/"
};

// Array for end round swaps
new NewTeam[64];

// Handle to top menu
new Handle:hTopMenu;

// Handles to change models
new Handle:hGameConf;
new Handle:hSetModel;

// Handle to drop weapons
new Handle:hDrop;

// Teams
new TEAM1,TEAM2;
new game;

new String:t_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/t_phoenix.mdl",
	"models/player/t_leet.mdl",
	"models/player/t_arctic.mdl",
	"models/player/t_guerilla.mdl"
};

new String:ct_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/ct_urban.mdl",
	"models/player/ct_gsg9.mdl",
	"models/player/ct_sas.mdl",
	"models/player/ct_gign.mdl"
};

// Team names
new String:teams[4][16] = 
{
	"N/A",
	"SPEC",
	"T",
	"CT"
};

public void OnClientPutInServer(int iClient)
{
   if(IsFakeClient(iClient) && !IsClientSourceTV(iClient)) KickClient(iClient);
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.swapper");

	decl String:gdir[PLATFORM_MAX_PATH];
	GetGameFolderName(gdir, sizeof(gdir));
	if (StrEqual(gdir,"cstrike",false)) game = 0;
	else if (StrEqual(gdir,"dod",false)) game = 1;
	else if (StrEqual(gdir,"hl2mp",false)) game = 2;
	else if (StrEqual(gdir,"Insurgency",false)) game = 3;
	else if (StrEqual(gdir,"tf",false)) game = 4;
	else game = 5;

	TEAM1 = 2;
	TEAM2 = 3;
	
	// Loading SetModel & WeaponDrop for CS:S
	if (!game)
	{
		hGameConf = LoadGameConfigFile("swapper.gamedata");
	
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		hSetModel = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "DropWeapon");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hDrop = EndPrepSDKCall();
	}

	RegAdminCmd("sm_swap", Swap, ADMFLAG_GENERIC);
	RegAdminCmd("sm_swapround", SwapRound, ADMFLAG_GENERIC);
	RegAdminCmd("sm_exch", Exchange, ADMFLAG_GENERIC);
	RegAdminCmd("sm_exchround", ExchangeRound, ADMFLAG_GENERIC);

	if (game) HookEvent("player_death",PlayerDeath);

	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("round_end",RoundEnd);
}

public OnMapStart()
{
	// Getting team names for mods other than cstrike
	if (game)
	{
		GetTeamName(TEAM1,teams[TEAM1],16);
		GetTeamName(TEAM2,teams[TEAM2],16);
	}
}

public PrintToChatAllEx(from,const String:format[], any:...)
{
	decl String:message[256];
	VFormat(message,sizeof(message),format,3);
	
	if (game == 1)
	{
		PrintToChatAll(message);
		return;
	}

	new Handle:hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}

public ChangeClientTeamEx(client,team)
{
	if (game)
	{
		ChangeClientTeam(client,team);
		return;
	}

	new oldTeam = GetClientTeam(client);
	CS_SwitchTeam(client,team);

	decl String:model[PLATFORM_MAX_PATH],String:newmodel[PLATFORM_MAX_PATH];
	GetClientModel(client,model,sizeof(model));
	newmodel = model;

	if (oldTeam == TEAM1)
	{
		new c4 = GetPlayerWeaponSlot(client,CS_SLOT_C4);
		if (c4 != -1) SDKCall(hDrop,client,c4,true,false);

		if (StrContains(model,t_models[0],false)) newmodel = ct_models[0];
		if (StrContains(model,t_models[1],false)) newmodel = ct_models[1];
		if (StrContains(model,t_models[2],false)) newmodel = ct_models[2];
		if (StrContains(model,t_models[3],false)) newmodel = ct_models[3];		
	} else
	if (oldTeam == TEAM2)
	{
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0, 1);

		if (StrContains(model,ct_models[0],false)) newmodel = t_models[0];
		if (StrContains(model,ct_models[1],false)) newmodel = t_models[1];
		if (StrContains(model,ct_models[2],false)) newmodel = t_models[2];
		if (StrContains(model,ct_models[3],false)) newmodel = t_models[3];		
	}

	SDKCall(hSetModel, client, newmodel);
}

public SwapPlayer(client,target)
{
	if (GetClientTeam(target) == TEAM1) ChangeClientTeamEx(target,TEAM2); else
	if (GetClientTeam(target) == TEAM2) ChangeClientTeamEx(target,TEAM1);
}

public SwapPlayerRound(client,target)
{
	decl String:buffer[64];
	GetClientName(target,buffer,sizeof(buffer));
	if (NewTeam[target])
	{
		PrintToChatAllEx(target,"%t","Swap Cancel",YELLOW,TEAMCOLOR,buffer,YELLOW,GREEN,teams[NewTeam[target]],YELLOW);
		NewTeam[target] = 0;
		return;
	}
	if (GetClientTeam(target) == TEAM1) NewTeam[target] = TEAM2; else
	if (GetClientTeam(target) == TEAM2) NewTeam[target] = TEAM1;
	PrintToChatAllEx(target,"%t","Swap",YELLOW,TEAMCOLOR,buffer,YELLOW,GREEN,teams[NewTeam[target]],YELLOW);
}

public ExchangePlayers(client,cl1,cl2)
{
	if ((GetClientTeam(cl1) == TEAM1) && (GetClientTeam(cl2) == TEAM2))
	{
		ChangeClientTeamEx(cl1,TEAM2);
		ChangeClientTeamEx(cl2,TEAM1);
	} else
	if ((GetClientTeam(cl1) == TEAM2) && (GetClientTeam(cl2) == TEAM1))
	{
		ChangeClientTeamEx(cl1,TEAM1);
		ChangeClientTeamEx(cl2,TEAM2);
	} else
	ReplyToCommand(client,"%t","Bad targets");
}

public ExchangePlayersRound(client,cl1,cl2)
{
	if (((GetClientTeam(cl1) == TEAM1) && (GetClientTeam(cl2) == TEAM2)) || 
		((GetClientTeam(cl1) == TEAM2) && (GetClientTeam(cl2) == TEAM1)))
	{
		SwapPlayerRound(client,cl1);
		SwapPlayerRound(client,cl2);
	} else
	ReplyToCommand(client,"%t","Bad targets");
}

public Action:Swap(client,args)
{
	if (!args)
	{
		ReplyToCommand(client,"\x04sm_swap <player>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));

	new Targets[64],bool:mb;

	new count = ProcessTargetString(pattern,client,Targets,sizeof(Targets),0,buffer,sizeof(buffer),mb);

	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else
	for (new i = 0; i < count; i++) SwapPlayer(client,Targets[i]);

	return Plugin_Handled;
}

public Action:SwapRound(client,args)
{
	if (!args)
	{
		ReplyToCommand(client,"\x04sm_swapround <player>");
		return Plugin_Handled;
	}
	new String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));

	new Targets[64],bool:mb;

	new count = ProcessTargetString(pattern,client,Targets,sizeof(Targets),0,buffer,sizeof(buffer),mb);

	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else
	for (new i = 0; i < count; i++) SwapPlayerRound(client,Targets[i]);

	return Plugin_Handled;	
}

public Action:Exchange(client,args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"\x04sm_exch <player1> <player2>");
		return Plugin_Handled;
	}

	new String:p1[64],String:p2[64];
	GetCmdArg(1,p1,sizeof(p1));
	GetCmdArg(2,p2,sizeof(p2));

	new cl1 = FindTarget(client,p1);
	new cl2 = FindTarget(client,p2);

	if (cl1 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p1,YELLOW);
	if (cl2 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p2,YELLOW);

	if ((cl1 > 0) && (cl2 > 0)) ExchangePlayers(client,cl1,cl2);

	return Plugin_Handled;	
}

public Action:ExchangeRound(client,args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"\x04sm_exchround <player1> <player2>");
		return Plugin_Handled;
	}

	new String:p1[64],String:p2[64];
	GetCmdArg(1,p1,sizeof(p1));
	GetCmdArg(2,p2,sizeof(p2));

	new cl1 = FindTarget(client,p1);
	new cl2 = FindTarget(client,p2);

	if (cl1 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p1,YELLOW);
	if (cl2 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p2,YELLOW);

	if ((cl1 > 0) && (cl2 > 0)) ExchangePlayersRound(client,cl1,cl2);

	return Plugin_Handled;	
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// mystery protection
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	NewTeam[client] = 0;
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (NewTeam[client])
	{
		ChangeClientTeamEx(client,NewTeam[client]);
		NewTeam[client] = 0;
	}
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < sizeof(NewTeam); i++)
	if (NewTeam[i] && IsClientInGame(i))
	{
		ChangeClientTeamEx(i,NewTeam[i]);
		NewTeam[i] = 0;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	hTopMenu = topmenu;

	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,"sm_swap",TopMenuObject_Item,AdminMenu_Swap,player_commands,"sm_swap",ADMFLAG_GENERIC);
		AddToTopMenu(hTopMenu,"sm_swapround",TopMenuObject_Item,AdminMenu_SwapRound,player_commands,"sm_swap",ADMFLAG_GENERIC);
		AddToTopMenu(hTopMenu,"sm_exch",TopMenuObject_Item,AdminMenu_Exchange,player_commands,"sm_swap",ADMFLAG_GENERIC);
		AddToTopMenu(hTopMenu,"sm_exchround",TopMenuObject_Item,AdminMenu_ExchangeRound,player_commands,"sm_swap",ADMFLAG_GENERIC);
	}
}

public AdminMenu_Swap(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Swap Now", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplaySwapMenu(param,false);
	}
}

public AdminMenu_SwapRound(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Swap Round", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplaySwapMenu(param,true);
	}
}

public AdminMenu_Exchange(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Exchange Now", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayExchangeMenu(param,false);
	}
}

public AdminMenu_ExchangeRound(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Exchange Round", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayExchangeMenu(param,true);
	}
}

public MenuHandler_Swap(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
    else if (action == MenuAction_Cancel)
    {
        if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
    }
	else if (action == MenuAction_Select)
	{
		decl String:title[100],String:id[16],String:Round[100];
        GetMenuItem(menu, param2, id, sizeof(id));
		new target = GetClientOfUserId(StringToInt(id));

		GetMenuTitle(menu, title, sizeof(title));
		Format(Round, sizeof(Round), "%t", "Swap Round", param1);
		if (!strcmp(Round,title)) SwapPlayerRound(param1,target);
		else SwapPlayer(param1,target);

		DisplaySwapMenu(param1,!strcmp(Round,title));
	}
}

public DisplaySwapMenu(client,bool:round)
{
	new Handle:menu = CreateMenu(MenuHandler_Swap);
	SetMenuExitBackButton(menu,true);
	
	decl String:title[100],String:name[64],String:id[16];
	if (round) Format(title, sizeof(title), "%t", "Swap Round", client);
	else Format(title, sizeof(title), "%t", "Swap Now", client);
	SetMenuTitle(menu, title);

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{
		new team = GetClientTeam(i);
		if (team > CS_TEAM_SPECTATOR)
		{
			GetClientName(i,name,sizeof(name));
			if (NewTeam[i]) Format(title, sizeof(title), "[>>%s] %s",teams[NewTeam[i]],name);
			else Format(title, sizeof(title), "[%s] %s",teams[team],name);
			IntToString(GetClientUserId(i),id,sizeof(id));
			AddMenuItem(menu,id,title);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Exchange2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
    else if (action == MenuAction_Cancel)
    {
        if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
    }
	else if (action == MenuAction_Select)
	{
		decl String:id1[16],String:id2[16],String:Round[100];
        GetMenuItem(menu, 0, id1, sizeof(id1));
        GetMenuItem(menu, param2, id2, sizeof(id2));

		new cl1 = GetClientOfUserId(StringToInt(id1));
		new cl2 = GetClientOfUserId(StringToInt(id2));

		decl String:title[100];
		GetMenuTitle(menu, title, sizeof(title));
		Format(Round, sizeof(Round), "%t", "Exchange Round", param1);
		if (!strcmp(Round,title)) ExchangePlayersRound(param1,cl1,cl2);
		else ExchangePlayers(param1,cl1,cl2);
	}
}

public MenuHandler_Exchange(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
    else if (action == MenuAction_Cancel)
    {
        if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
    }
	else if (action == MenuAction_Select)
	{
		decl String:title[100],String:id[16],String:name[64];
        GetMenuItem(menu, param2, id, sizeof(id));
		new target = GetClientOfUserId(StringToInt(id));

		new team = GetClientTeam(target);

		new Handle:menu2 = CreateMenu(MenuHandler_Exchange2);
		SetMenuExitBackButton(menu2,true);
		GetMenuTitle(menu, title, sizeof(title));
		SetMenuTitle(menu2, title);

		GetClientName(target,name,sizeof(name));
		Format(title, sizeof(title), "[%s] %s",teams[team],name);
		AddMenuItem(menu2,id,title,ITEMDRAW_DISABLED);

		for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (i != target))
		{
			new team2 = GetClientTeam(i);
			if ((team2 > CS_TEAM_SPECTATOR) && (team != team2))
			{
				GetClientName(i,name,sizeof(name));
				Format(title, sizeof(title), "[%s] %s",teams[team2],name);
				IntToString(GetClientUserId(i),id,sizeof(id));
				AddMenuItem(menu2,id,title);
			}
		}
		DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
	}
}

public DisplayExchangeMenu(client,bool:round)
{
	new Handle:menu = CreateMenu(MenuHandler_Exchange);
	SetMenuExitBackButton(menu,true);
	
	decl String:title[100],String:name[64],String:id[16];
	if (round) Format(title, sizeof(title), "%t", "Exchange Round", client);
	else Format(title, sizeof(title), "%t", "Exchange Now", client);
	SetMenuTitle(menu, title);

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{
		new team = GetClientTeam(i);
		if (team > CS_TEAM_SPECTATOR)
		{
			GetClientName(i,name,sizeof(name));
			Format(title, sizeof(title), "[%s] %s",teams[team],name);
			IntToString(GetClientUserId(i),id,sizeof(id));
			AddMenuItem(menu,id,title);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
