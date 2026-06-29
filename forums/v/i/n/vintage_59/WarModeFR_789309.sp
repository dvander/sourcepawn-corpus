/**
* 
* =============================================================================
* War Mode (C)2009 Puopjik.  All rights reserved.
* =============================================================================
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License, version 3.0, as published by the
* Free Software Foundation.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program.  If not, see <http://www.gnu.org/licenses/>.
*
* As a special exception, Puopjik gives you permission to link the
* code of this program (as well as its derivative works) to "Half-Life 2," the
* "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
* by the Valve Corporation.  You must obey the GNU General Public License in
* all respects for all other code used.  Additionally, Puopjik grants this
* exception to all derivative works.
*
*
* <http://baronettes.verygames.net/> 
*/

#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "WarModeFR",
	author = "Puopjik",
	description = "Auto-War plugin for SourceMod",
	version = PLUGIN_VERSION,
	url = "http://baronettes.verygames.net/"
};





////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//Globals Declaration
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


new scores[4];
new String:matchislive[3]
new String:mapchoosen[32]
new itemchoosen

new Handle:kv = INVALID_HANDLE
new Handle:results = INVALID_HANDLE
new Handle:g_MapMenu = INVALID_HANDLE
new Handle:g_MapChooseMenu = INVALID_HANDLE
new Handle:g_MainMenu = INVALID_HANDLE
new Handle:g_NbOfMapsMenu = INVALID_HANDLE
new Handle:g_RoundTimeMenu = INVALID_HANDLE
new Handle:g_TeamsMenu = INVALID_HANDLE

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//Plugin init
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


public OnPluginStart()
{
	HookEvent("dod_team_scores", Event_TeamScores);
	HookEvent("dod_tick_points", Event_TickPoints);
	HookEvent("dod_restart_round", Event_RestartRound);
	HookEvent("dod_round_win", Event_dod_round_win);
	HookEvent("dod_game_over", Event_dod_game_over);
	HookEvent("dod_warmup_begins", Event_dod_warmup_begins)
	HookEvent("dod_warmup_ends", Event_dod_warmup_ends)
	
	
	//RegServerCmd("readkey",sv_ReadKeyValue);
	//RegServerCmd("writekey",sv_WriteKeyValue)
	RegAdminCmd("war_islive", sv_WarIsLive, ADMFLAG_SLAY, "Mettre 1 lance le match, 0 le stoppe.")
	RegAdminCmd("war_scores", sv_DispScores, ADMFLAG_SLAY, "Affiche les scores en cours.")
	
	RegAdminCmd("war_configfile", sv_WarConfigFile, ADMFLAG_SLAY, "Enregistre le fichier config War à charger.")
	RegAdminCmd("war_tvfile", sv_WarTvFile, ADMFLAG_SLAY, "Enregistre le fichier config SourceTV à charger.")
	RegAdminCmd("war_mapfile", sv_WarMapFile, ADMFLAG_SLAY, "Enregistre le fichier Maplist à charger.")
	
	RegAdminCmd("war_tagA", sv_WarTagA, ADMFLAG_SLAY, "Enregistre le Tag de la team A.")
	RegAdminCmd("war_tagB", sv_WarTagB, ADMFLAG_SLAY, "Enregistre le Tag de la team B.")
	
	RegAdminCmd("war_allies", sv_WarAllies, ADMFLAG_SLAY, "Enregistre l'équipe qui jouera Allies pour le premier round.")	
	RegAdminCmd("war_axis", sv_WarAxis, ADMFLAG_SLAY,  "Enregistre l'équipe qui jouera Axes pour le premier round.")	
	
	RegAdminCmd("war_map1", sv_WarMap1, ADMFLAG_SLAY, "Enregistre la Première Map du Match.")
	RegAdminCmd("war_map2", sv_WarMap2, ADMFLAG_SLAY, "Enregistre la Deuxième Map du Match.")	
	RegAdminCmd("war_map3", sv_WarMap3, ADMFLAG_SLAY, "Enregistre la Troisième Map du Match.")	
	
	RegAdminCmd("war_reset", sv_WarReset, ADMFLAG_SLAY, "Reset des réglages par défaut. Stoppe aussi le Match.")
	
	RegAdminCmd("war_rr", sv_WarRestartRound, ADMFLAG_SLAY, "Relance le round si besoin.")
	RegAdminCmd("war_numberofmaps", sv_WarNumberOfMaps, ADMFLAG_SLAY, "Enregistre le Nombre de Maps à jouer.")
	RegAdminCmd("war_roundtime", sv_WarRoundTime, ADMFLAG_SLAY, "Enregistre la Durée des rounds.")
	
	RegAdminCmd("war_menu", sv_WarMenu, ADMFLAG_SLAY, "Affiche le Menu du Plugin Match.")
	RegAdminCmd("war_help", sv_WarHelp, ADMFLAG_SLAY, "Affiche l'aide du Plugin Match.")
	RegAdminCmd("war_summary", sv_WarSummary, ADMFLAG_SLAY, "Affiche les réglages enregistrés.")
	
	CreateConVar("sm_warmode_version", PLUGIN_VERSION , "War Mode Plugin for DOD:S version number", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Build menus
	g_MapMenu = BuildMapMenu()
	g_MainMenu = BuildMainMenu()
	g_RoundTimeMenu = BuildRoundTimeMenu()
	g_NbOfMapsMenu = BuildNbOfMapsMenu()
	g_TeamsMenu = BuildTeamsMenu()
	
	
}



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//Map init & term
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public OnMapStart()
{
	
	LoadTranslations("WarMode.phrases")
	
	kv = CreateKeyValues("mymatch");
	new bool:kvexist = FileToKeyValues(kv, "mymatch.txt");
	
	if(!kvexist)
	{
		CreateMatchKeyValues()
	}
	
	//results = OpenFile("match_results.txt", "r");
	
	
	//Build menus
	/*	g_MapMenu = BuildMapMenu()
	g_MainMenu = BuildMainMenu()
	g_RoundTimeMenu = BuildRoundTimeMenu()
	g_NbOfMapsMenu = BuildNbOfMapsMenu()
	g_TeamsMenu = BuildTeamsMenu()
	*/	
	g_MapChooseMenu = BuildMapChooseMenu()
	
	
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		
		//Reset Temp Scores
		scores[0]= 0;
		scores[1]= 0;
		scores[2]= 0;
		scores[3]= 0;	
		
		new String:roundnumber[3];
		new String:numberofmaps[3];
		new String:nextmap[64];
		new String:buffer[16]
		
		ReadKeyValue(kv, "MatchState", "RoundNumber", roundnumber, sizeof(roundnumber))
		ReadKeyValue(kv, "MatchState", "NumberOfMaps", numberofmaps, sizeof(numberofmaps))
		
		if(StringToInt(roundnumber)<= 2*StringToInt(numberofmaps))
		{
			new String:mapnumber[3];
			ReadKeyValue(kv, "MatchState", "MapNumber", mapnumber, sizeof(mapnumber))
			Format(buffer, sizeof(buffer), "map%s", mapnumber)
			ReadKeyValue(kv, "Maps", buffer, nextmap, sizeof(nextmap))
			
			
			if(StrEqual("error",nextmap)) strcopy(nextmap, sizeof(nextmap), "dod_flash")
			
			ServerCommand("sm_nextmap %s", nextmap)
			ServerCommand("ma_setnextmap %s", nextmap)  //If Mani is used for map changing
			LoadConfig()
		}
		else
		{
			WriteFinalResults()
			WarIsLive(0)
		}
	}
}


public OnMapEnd()
{
	KvRewind(kv)
	KeyValuesToFile(kv, "mymatch.txt")
	CloseHandle(kv)	
	
	CloseHandle(g_MapChooseMenu)
	/*	CloseHandle(g_MapMenu)
	CloseHandle(g_MainMenu)
	CloseHandle(g_RoundTimeMenu)
	CloseHandle(g_NbOfMapsMenu)
	CloseHandle(g_TeamsMenu)
	*/
}






////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//Console Functions
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

public Action:sv_WarMenu(client,argc)
{
	if(client == 0)
	{
		PrintToServer("Les Menus ne peuvent pas s'afficher sur le serveur!")
	}
	else
	{
		DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)
	}
	return Plugin_Handled
}

public Action:sv_WarSummary(client,argc)
{
	WarSummary(client)
	return Plugin_Handled
}

public Action:sv_WarHelp(client,argc)
{
	if(client == 0)
	{
		PrintToServer("War Mode Plugin par Puopjik: Liste des commandes:\n")
		PrintToServer("\"war_menu\"\n - Affiche le Menu Principal du Plugin.")
		PrintToServer("\"war_help\"\n - Affiche l'aide du Plugin.")
		PrintToServer("\"war_islive\"\n - Mettre à 1 lance le match, 0 le stoppe.")
		PrintToServer("\"war_rr\"\n - Relance le round si besoin.")
		PrintToServer("\"war_map1\"\n - Enregistre la Première Map du Match.")
		PrintToServer("\"war_map2\"\n - Enregistre la Deuxième Map du Match.")
		PrintToServer("\"war_map3\"\n - Enregistre la Troisième Map du Match.")
		PrintToServer("\"war_tagA\"\n - Enregistre le Tag de la team A.")
		PrintToServer("\"war_tagB\"\n - Enregistre le Tag de la team B.")
		PrintToServer("\"war_allies\"\n - Enregistre l'équipe qui jouera Allies pour le premier round.")
		PrintToServer("\"war_axis\"\n - Enregistre l'équipe qui jouera Axes pour le premier round.")
		PrintToServer("\"war_roundtime\"\n - Enregistre la Durée des rounds.")
		PrintToServer("\"war_numberofmaps\"\n - Enregistre le Nombre de Maps à jouer.")
		PrintToServer("\"war_scores\"\n - Affiche les scores en cours.")
		PrintToServer("\"war_summary\"\n - Affiche les réglages enregistrés.")
		PrintToServer("\"war_reset\"\n - Reset des réglages par défaut. Stoppe aussi le Match.")
		PrintToServer("\"war_configfile\"\n - Enregistre le fichier config War à charger.")
		PrintToServer("\"war_tvfile\"\n - Enregistre le fichier config SourceTV à charger.")
		PrintToServer("\"war_mapfile\"\n - Enregistre le fichier Maplist à charger.")
	}
	else
	{
		PrintToConsole(client,"War Mode Plugin par Puopjik: Liste des commandes:\n")
		PrintToConsole(client,"\"war_menu\"\n - Affiche le Menu Principal du Plugin.")
		PrintToConsole(client,"\"war_help\"\n - Affiche l'aide du Plugin.")
		PrintToConsole(client,"\"war_islive\"\n - Mettre à 1 lance le match, 0 le stoppe.")
		PrintToConsole(client,"\"war_rr\"\n - Relance le round si besoin.")
		PrintToConsole(client,"\"war_map1\"\n - Enregistre la Première Map du Match.")
		PrintToConsole(client,"\"war_map2\"\n - Enregistre la Deuxième Map du Match.")
		PrintToConsole(client,"\"war_map3\"\n - Enregistre la Troisième Map du Match.")
		PrintToConsole(client,"\"war_tagA\"\n - Enregistre le Tag de la team A.")
		PrintToConsole(client,"\"war_tagB\"\n - Enregistre le Tag de la team B.")
		PrintToConsole(client,"\"war_allies\"\n - Enregistre l'équipe qui jouera Allies pour le premier round.")
		PrintToConsole(client,"\"war_axis\"\n - Enregistre l'équipe qui jouera Axes pour le premier round.")
		PrintToConsole(client,"\"war_roundtime\"\n - Enregistre la Durée des rounds.")
		PrintToConsole(client,"\"war_numberofmaps\"\n - Enregistre le Nombre de Maps à jouer.")
		PrintToConsole(client,"\"war_scores\"\n - Affiche les scores en cours.")
		PrintToConsole(client,"\"war_summary\"\n - Affiche les réglages enregistrés.")
		PrintToConsole(client,"\"war_reset\"\n - Reset des réglages par défaut. Stoppe aussi le Match.")
		PrintToConsole(client,"\"war_configfile\"\n - Enregistre le fichier config War à charger.")
		PrintToConsole(client,"\"war_tvfile\"\n - Enregistre le fichier config SourceTV à charger.")
		PrintToConsole(client,"\"war_mapfile\"\n - Enregistre le fichier Maplist à charger.")
	}
	return Plugin_Handled
}


public Action:sv_WarReset(client, argc)
{
	WriteKeyValue(kv, "MatchState", "MatchIsLive", "0");
	WriteKeyValue(kv, "MatchState", "RoundNumber", "1");
	WriteKeyValue(kv, "MatchState", "RoundTime", "15");
	WriteKeyValue(kv, "MatchState", "MapNumber", "1");
	WriteKeyValue(kv, "MatchState", "NumberOfMaps", "2");
	WriteKeyValue(kv, "teams", "2", "A");
	WriteKeyValue(kv, "teams", "3", "B");
	KvRewind(kv)
	KeyValuesToFile(kv, "mymatch.txt")
	LoadConfig()
	
	if(client == 0)
	{
		PrintToServer("Les réglages Match ont été remis aux valeurs par défaut")
	}
	else
	{
		PrintToChat(client,"%T", "Match settings have been reset.", client)
	}
	return Plugin_Handled
}

public Action:sv_WarMap1(client, argc)
{
	new String:mapname[64]
	if(argc > 0)
	{
		GetCmdArg(1,mapname,sizeof(mapname))
		MapsSet(1,mapname)
	}
	
	ReadKeyValue(kv, "Maps", "map1", mapname, sizeof(mapname))
	if(client == 0)
	{
		PrintToServer("La Première Map enregistrée est %s.\n", mapname)
	}
	else
	{
		PrintToChat(client,"La Première Map enregistrée est %s.\n", mapname)
	}
	
	return Plugin_Handled
}

public Action:sv_WarMap2(client, argc)
{
	new String:mapname[64]
	if(argc > 0)
	{
		GetCmdArg(1,mapname,sizeof(mapname))
		MapsSet(2,mapname)
	}
	
	ReadKeyValue(kv, "Maps", "map2", mapname, sizeof(mapname))
	if(client == 0)
	{
		PrintToServer("La Deuxième Map enregistrée est %s.\n", mapname)
	}
	else
	{
		PrintToChat(client,"La Deuxième Map enregistrée est %s.\n", mapname)
	}
	
	return Plugin_Handled
}

public Action:sv_WarMap3(client, argc)
{
	new String:mapname[64]
	if(argc > 0)
	{
		GetCmdArg(1,mapname,sizeof(mapname))
		MapsSet(3,mapname)
	}
	
	ReadKeyValue(kv, "Maps", "map3", mapname, sizeof(mapname))
	if(client == 0)
	{
		PrintToServer("La Troisième Map enregistrée est %s.\n", mapname)
	}
	else
	{
		PrintToChat(client,"La Troisième Map enregistrée est %s.\n", mapname)
	}
	
	return Plugin_Handled
}

public Action:sv_WarConfigFile(client, argc)
{
	new String:confname[64]
	if(argc > 0)
	{
		GetCmdArg(1,confname,sizeof(confname))
		WriteKeyValue(kv, "MatchState", "ConfigFile", confname)
	}
	
	ReadKeyValue(kv, "MatchState", "ConfigFile", confname, sizeof(confname))
	if(client == 0)
	{
		PrintToServer("Le fichier de config Match enregistré est %s.\n", confname)
	}
	else
	{
		PrintToChat(client,"Le fichier de config Match enregistré est %s.\n", confname)
	}
	
	return Plugin_Handled
}


public Action:sv_WarTvFile(client, argc)
{
	new String:tvconfname[64]
	if(argc > 0)
	{
		GetCmdArg(1,tvconfname,sizeof(tvconfname))
		WriteKeyValue(kv, "MatchState", "TvFile", tvconfname)
	}
	
	ReadKeyValue(kv, "MatchState", "TvFile", tvconfname, sizeof(tvconfname))
	
	if(client == 0)
	{
		PrintToServer("Le fichier de config SourceTV enregistré est %s.\n", tvconfname)
	}
	else
	{
		PrintToChat(client,"Le fichier de config SourceTV enregistré est %s.\n", tvconfname)
	}
	
	
	return Plugin_Handled
}

public Action:sv_WarMapFile(client, argc)
{
	new String:mapfilename[128]
	if(argc > 0)
	{
		GetCmdArg(1,mapfilename,sizeof(mapfilename))
		WriteKeyValue(kv, "MatchState", "MapFile", mapfilename)
	}
	
	ReadKeyValue(kv, "MatchState", "MapFile", mapfilename, sizeof(mapfilename))
	
	if(client == 0)
	{
		PrintToServer("Le fichier Maplist enregistré est %s.\n", mapfilename)
	}
	else
	{
		PrintToChat(client,"Le fichier Maplist enregistré est %s.\n", mapfilename)
	}
	
	
	return Plugin_Handled
}


public Action:sv_WarRoundTime(client, argc)
{
	new String:roundtime[64]
	if(argc > 0)
	{
		GetCmdArg(1,roundtime,sizeof(roundtime))
		TimeSet(roundtime)
	}
	
	ReadKeyValue(kv, "MatchState", "RoundTime", roundtime,sizeof(roundtime))
	
	if(client == 0)
	{
		PrintToServer("La Durée des rounds enregistrée est %s min.\n", roundtime)
	}
	else
	{
		PrintToChat(client,"La Durée des rounds enregistrée est %s min.\n", roundtime)
	}
	
	return Plugin_Handled
}

public Action:sv_WarTagA(client, argc)
{
	new String:tagA[128]
	if(argc > 0)
	{
		GetCmdArg(1,tagA,sizeof(tagA))
		WriteKeyValue(kv, "teams", "tagA", tagA)
	}
	
	ReadKeyValue(kv, "teams", "tagA", tagA, sizeof(tagA))
	
	if(client == 0)
	{
		PrintToServer("Le Tag de la Team A enregistré est %s.\n",tagA)
	}
	else
	{
		PrintToChat(client,"Le Tag de la Team A enregistré est %s.\n",tagA)
	}
	
	return Plugin_Handled
}

public Action:sv_WarTagB(client, argc)
{
	new String:tagB[128]
	if(argc > 0)
	{
		GetCmdArg(1,tagB,sizeof(tagB))
		WriteKeyValue(kv, "teams", "tagB", tagB)
	}
	
	ReadKeyValue(kv, "teams", "tagB", tagB, sizeof(tagB))
	if(client == 0)
	{
		PrintToServer("Le Tag de la Team B enregistré est %s.\n",tagB)
	}
	else
	{
		PrintToChat(client,"Le Tag de la Team B enregistré est %s.\n",tagB)
	}
	
	return Plugin_Handled
}

public Action:sv_WarAllies(client, argc)
{
	new String:buffer[8]
	if(argc > 0)
	{
		GetCmdArg(1,buffer,sizeof(buffer))
		
		SetTeams(buffer, "2")
	}
	
	ReadKeyValue(kv, "teams", "2", buffer, sizeof(buffer))
	
	if(client == 0)
	{
		PrintToServer("La Team %s joue Alliés.\n",buffer)
	}
	else
	{
		PrintToChat(client,"La Team %s joue Alliés.\n",buffer)
	}
	
	
	return Plugin_Handled
}

public Action:sv_WarAxis(client, argc)
{
	new String:buffer[8]
	if(argc > 0)
	{
		GetCmdArg(1,buffer,sizeof(buffer))
		
		SetTeams(buffer, "3")
	}
	
	ReadKeyValue(kv, "teams", "3", buffer, sizeof(buffer))
	
	if(client == 0)
	{
		PrintToServer("La Team %s joue Axes.\n",buffer)
	}
	else
	{
		PrintToChat(client,"La Team %s joue Axes.\n",buffer)
	}
	
	
	return Plugin_Handled
}

public Action:sv_WarNumberOfMaps(client, argc)
{
	new String:buffer[8]
	if(argc > 0)
	{
		GetCmdArg(1,buffer,sizeof(buffer))
		if(StrContains("1 2 3", buffer)==-1)
		{
			if(client == 0)
			{
				PrintToServer("Les valeurs possibles sont : 1 2 3")
			}
			else
			{
				PrintToChat(client,"Les valeurs possibles sont : 1 2 3")
			}
		}
		else
		{		
			NbMapSet(buffer)
		}
	}
	
	ReadKeyValue(kv, "MatchState", "NumberOfMaps", buffer,sizeof(buffer))
	
	if(client == 0)
	{
		PrintToServer("Nombre de Maps programmées : %s.\n", buffer)
	}
	else
	{
		PrintToChat(client,"%T" ,"Number of maps scheduled :", client, buffer)
	}
	
	return Plugin_Handled
}

public Action:sv_WarRestartRound(client, argc)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual(matchislive,"1"))
	{
		RestartRound()
	}
	else
	{
		if(client == 0)
		{
			PrintToServer("Le match n'est pas démarré.")
		}
		else
		{
			PrintToChat(client,"%T", "War isn't live.", client)
		}
	}
	
	return Plugin_Handled
}




public Action:sv_WarIsLive(client, argc)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(argc < 1)
	{
		
		if(StrEqual("1",matchislive))
		{
			if(client == 0)
			{
				PrintToServer("\nWar is currently live!\n")
			}
			else
			{
				PrintToChat(client,"%T", "War is currently live!", client)
			}
		}
		else
		{
			if(client == 0)
			{
				PrintToServer("\nLe match est en cours!")
			}
			else
			{
				PrintToChat(client,"%T", "War isn't live.", client)
			}
		}
		
		if(client == 0)
		{
			PrintToServer("La Syntaxe est:\nwar_islive <0|1>")
		}
		else
		{
			PrintToChat(client,"La Syntaxe est:\nwar_islive <0|1>")
		}
		
		return Plugin_Handled	
	}
	
	new String:arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new islive = StringToInt(arg1)
	
	WarIsLive(islive)
	
	return Plugin_Handled
}

public Action:sv_DispScores(client, argc)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual(matchislive,"1"))
	{
		DispScores()
	}
	else
	{
		LastResults()
	}
}


/*
public Action:sv_ReadKeyValue(argc)
{
new String:arg1[128];
new String:arg2[128];			
GetCmdArg(1, arg1, sizeof(arg1));
GetCmdArg(2, arg2, sizeof(arg2));

new String:result[128];

ReadKeyValue(kv, arg1, arg2, result, sizeof(result));
PrintToChatAll("Résultat = %s\n", result);
return Plugin_Handled


}

public Action:sv_WriteKeyValue(argc)
{
new String:arg1[128];
new String:arg2[128];
new String:arg3[128];			
GetCmdArg(1, arg1, sizeof(arg1));
GetCmdArg(2, arg2, sizeof(arg2));
GetCmdArg(3, arg3, sizeof(arg3));

WriteKeyValue(kv, arg1, arg2, arg3);

return Plugin_Handled
}
*/



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//Menus
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Handle:BuildTeamsMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Teams, MenuAction_DisplayItem|MenuAction_Display);
	
	/*Add items*/
	AddMenuItem(menu, "1", "A is Ally / B is Axis")
	AddMenuItem(menu, "2", "A is Axis / B is Ally")
	
	/* Finally, set the title */
	SetMenuTitle(menu, "Choose repartition of first round.")
	
	return menu
}

public Menu_Teams(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_DisplayItem)
	{
		/* Get the display string, we'll use it as a translation phrase */
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
		
		/* Translate the string to the client's language */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", display, client);
		
		/* Override the text */
		return RedrawMenuItem(buffer);
	}
	
	if (action == MenuAction_Display)
	{
		/* Panel Handle is the second parameter */
		new Handle:panel = Handle:param2;
		
		
		/* Translate to our phrase */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Choose repartition of first round.", client);
		
		SetPanelTitle(panel, buffer);
	}
	
	if (action == MenuAction_Select)
	{
		new String:info[64]
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info))
		
		/* Store the item */
		itemchoosen = StringToInt(info)
		
		
		switch(itemchoosen)
		{
			case 1:
			{
				SetTeams("A", "2")
				Format(info, sizeof(info), "\"%T\"", "A is Ally / B is Axis", client)
				PrintToChat(client, "%T", "You selected", client, info)
			}
			case 2:
			{
				SetTeams("A", "3")
				Format(info, sizeof(info), "\"%T\"", "A is Axis / B is Ally", client)
				PrintToChat(client, "%T", "You selected", client, info)
			}
		}
	}
	
	
	DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)
	return 1
}


Handle:BuildNbOfMapsMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_NbOfMaps, MenuAction_DisplayItem|MenuAction_Display);
	
	/*Add items*/
	AddMenuItem(menu, "1", "One")
	AddMenuItem(menu, "2", "Two")
	AddMenuItem(menu, "3", "Three")
	
	/* Finally, set the title */
	SetMenuTitle(menu, "Select the number of maps.")
	
	return menu
}

public Menu_NbOfMaps(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_DisplayItem)
	{
		/* Get the display string, we'll use it as a translation phrase */
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
		
		/* Translate the string to the client's language */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", display, client);
		
		/* Override the text */
		return RedrawMenuItem(buffer);
	}
	
	if (action == MenuAction_Display)
	{
		/* Panel Handle is the second parameter */
		new Handle:panel = Handle:param2;
		
		
		/* Translate to our phrase */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Select the number of maps.", client);
		
		SetPanelTitle(panel, buffer);
	}
	
	if (action == MenuAction_Select)
	{
		new String:info[32]
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info))
		
		/* Store the item */
		itemchoosen = StringToInt(info)
		
		switch(itemchoosen)
		{
			case 1:
			{
				NbMapSet("1")
				Format(info, sizeof(info), "\"%T\"", "One", client)
				PrintToChat(client, "%T", "You selected", client, info)
			}
			case 2:
			{
				NbMapSet("2")
				Format(info, sizeof(info), "\"%T\"", "Two", client)
				PrintToChat(client, "%T", "You selected", client, info)
			}
			case 3:
			{
				NbMapSet("3")
				Format(info, sizeof(info), "\"%T\"", "Three", client)
				PrintToChat(client, "%T", "You selected", client, info)
			}
		}
	}	
	
	DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)
	return 1
}


Handle:BuildMapMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Map, MenuAction_DisplayItem|MenuAction_Display);
	
	/*Add items*/
	AddMenuItem(menu, "1", "Map 1")
	AddMenuItem(menu, "2", "Map 2")
	AddMenuItem(menu, "3", "Map 3")
	
	/* Finally, set the title */
	SetMenuTitle(menu, "Select the map to set.")
	
	return menu
}

public Menu_Map(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Display)
	{
		/* Panel Handle is the second parameter */
		new Handle:panel = Handle:param2;
		
		
		/* Translate to our phrase */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Select the map to set.", client);
		
		SetPanelTitle(panel, buffer);
	}
	
	if (action == MenuAction_Select)
	{
		new String:info[32]
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info))
		
		/* Store the item */
		itemchoosen = StringToInt(info)
		
		Format(info, sizeof(info), "\"Map %d\"", itemchoosen)
		PrintToChat(client, "%T", "You selected", client, info)
		
		DisplayMenu(g_MapChooseMenu, client, MENU_TIME_FOREVER)
		
	}
	
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)		
	}
}

Handle:BuildMapChooseMenu()
{
	/* Retrive map file name */
	new String:mapfile[128]
	ReadKeyValue(kv, "MatchState", "MapFile", mapfile, sizeof(mapfile))
	
	/* Open the file */
	new Handle:file = OpenFile(mapfile, "rt")
	if (file == INVALID_HANDLE)
	{
		return INVALID_HANDLE
	}
	
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_ChooseMap, MenuAction_DisplayItem|MenuAction_Display);
	new String:mapname[255]
	while (!IsEndOfFile(file) && ReadFileLine(file, mapname, sizeof(mapname)))
	{
		if (mapname[0] == ';')
		{
			continue
		}
		/* Cut off the name at any whitespace */
		new len = strlen(mapname)
		for (new i=0; i<len; i++)
		{
			if (IsCharSpace(mapname[i]))
			{
				mapname[i] = '\0'
				break
			}
		}
		/* Check if the map is valid */
		if (!IsMapValid(mapname))
		{
			continue
		}
		/* Add it to the menu */
		AddMenuItem(menu, mapname, mapname)
	}
	/* Make sure we close the file! */
	CloseHandle(file)
	
	/* Finally, set the title */
	SetMenuTitle(menu, "Please select a map:")
	
	return menu
}


public Menu_ChooseMap(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Display)
	{
		/* Panel Handle is the second parameter */
		new Handle:panel = Handle:param2;
		
		
		/* Translate to our phrase */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Please select a map:", client);
		
		SetPanelTitle(panel, buffer);
	}
	
	if (action == MenuAction_Select)
	{
		new String:info[32]
		
		strcopy(mapchoosen,sizeof(mapchoosen),"dod_flash")
		
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info))
		
		/* Tell the client */
		PrintToChat(client, "%T", "You selected", client, info)
		
		/* Store the map */
		MapsSet(itemchoosen,info)
	}
	
	DisplayMenu(g_MapMenu, client, MENU_TIME_FOREVER)		
}

Handle:BuildRoundTimeMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_RoundTime, MenuAction_DisplayItem|MenuAction_Display);
	
	/*Add items*/
	AddMenuItem(menu, "1", "15 min")
	AddMenuItem(menu, "2", "10 min")
	AddMenuItem(menu, "3", "12 min")
	AddMenuItem(menu, "4", "20 min")
	AddMenuItem(menu, "5", "25 min")
	AddMenuItem(menu, "6", "30 min")
	/* Finally, set the title */
	SetMenuTitle(menu, "Choose round duration.")
	
	return menu
}

public Menu_RoundTime(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Display)
	{
		/* Panel Handle is the second parameter */
		new Handle:panel = Handle:param2;
		
		
		/* Translate to our phrase */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Choose round duration.", client);
		
		SetPanelTitle(panel, buffer);
	}
	
	
	
	if (action == MenuAction_Select)
	{
		new String:info[32]
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info))
		
		/* Store the item */
		itemchoosen = StringToInt(info)
		
		
		switch(itemchoosen)
		{
			case 1:
			{
				TimeSet("15")
				PrintToChat(client, "%T", "You selected", client, "\"15 min\"")
			}
			case 2:
			{
				TimeSet("10")
				PrintToChat(client, "%T", "You selected", client, "\"10 min\"")
			}
			case 3:
			{
				TimeSet("12")
				PrintToChat(client, "%T", "You selected", client, "\"12 min\"")
			}
			case 4:
			{
				TimeSet("20")
				PrintToChat(client, "%T", "You selected", client, "\"20 min\"")
			}
			case 5:
			{
				TimeSet("25")
				PrintToChat(client, "%T", "You selected", client, "\"25 min\"")
			}
			case 6:
			{
				TimeSet("30")
				PrintToChat(client, "%T", "You selected", client, "\"30 min\"")
			}
		}
	}
	DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)		
}

Handle:BuildMainMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Main, MenuAction_DisplayItem|MenuAction_Display);
	
	/*Add items*/
	AddMenuItem(menu, "1", "Choose Maps")
	AddMenuItem(menu, "2", "Number of Maps")
	AddMenuItem(menu, "3", "Round Time")
	AddMenuItem(menu, "4", "Teams")
	AddMenuItem(menu, "5", "Start War/Restart Round")
	AddMenuItem(menu, "6", "Show Scores")
	AddMenuItem(menu, "7", "Show Settings Summary")
	AddMenuItem(menu, "8", "Stop War")
	
	/* Finally, set the title */
	//decl String:buffer[255];
	//Format(buffer, sizeof(buffer), "%T", "War Mode Menu", LANG_SERVER);
	
	SetMenuTitle(menu, "War Mode Menu")
	
	return menu
}

public Menu_Main(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_DisplayItem)
	{
		/* Get the display string, we'll use it as a translation phrase */
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
		//PrintToChatAll("%s", display)
		
		/* Translate the string to the client's language */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", display, client);
		//PrintToChatAll("%s", buffer)
		
		/* Override the text */
		return RedrawMenuItem(buffer);
	}
	
	if (action == MenuAction_Display)
	{
		/* Panel Handle is the second parameter */
		new Handle:panel = Handle:param2;
		
		
		/* Translate to our phrase */
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", "War Mode Menu", client);
		
		SetPanelTitle(panel, buffer);
	}
	
	
	if (action == MenuAction_Select)
	{
		new String:info[32]
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info))
		
		/* Store the item */
		itemchoosen = StringToInt(info)
		
		switch(itemchoosen)
		{
			case 1:
			{
				DisplayMenu(g_MapMenu, client, MENU_TIME_FOREVER)
			}
			case 2:
			{
				DisplayMenu(g_NbOfMapsMenu, client, MENU_TIME_FOREVER)
			}
			case 3:
			{
				DisplayMenu(g_RoundTimeMenu, client, MENU_TIME_FOREVER)
			}
			case 4:
			{
				DisplayMenu(g_TeamsMenu, client, MENU_TIME_FOREVER)
			}
			case 5:
			{
				ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
				if(StrEqual("1", matchislive))
				{		 
					RestartRound()
				}
				else
				{
					WarIsLive(1)
				}
				
				//DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)
			}
			case 6:
			{
				ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
				if(StrEqual(matchislive,"1"))
				{
					DispScores()
				}
				else
				{
					LastResults()
				}
				
				//DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)
			}
			case 7:
			{
				WarSummary(client)
				
				DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)		
			}
			case 8:
			{
				WarIsLive(0)
				
				//DisplayMenu(g_MainMenu, client, MENU_TIME_FOREVER)
			}
		}
	}
	return 1
}




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Plugin Internal Functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

LastResults()
{
	//Last results load
	new Handle:file = OpenFile("match_results.txt", "r");
	if (file == INVALID_HANDLE)
	{
		PrintToChatAll("\x05No last results!")
		return
	}
	new String:buffer[255];
	while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		PrintToChatAll("\x05%s", buffer)
	}
	FlushFile(file);
	CloseHandle(file)
}



WarSummary(client)
{
	new String:buffer[128]
	if(client == 0)
	{
		PrintToServer("---------------------")
		ReadKeyValue(kv, "teams" , "tagA", buffer, sizeof(buffer));
		PrintToServer("Tag of the team A is %s.", buffer)
		ReadKeyValue(kv, "teams" , "tagB", buffer, sizeof(buffer));
		PrintToServer("Tag of the team B is %s.", buffer)
		ReadKeyValue(kv, "teams" , "2", buffer, sizeof(buffer));
		PrintToServer("First allied team is %s.", buffer)
		ReadKeyValue(kv, "teams" , "3", buffer, sizeof(buffer));
		PrintToServer("First axis team is %s.", buffer)
		ReadKeyValue(kv, "Maps" , "map1", buffer, sizeof(buffer));
		PrintToServer("Map 1 is %s.", buffer)
		ReadKeyValue(kv, "Maps" , "map2", buffer, sizeof(buffer));
		PrintToServer("Map 2 is %s.", buffer)
		ReadKeyValue(kv, "Maps" , "map3", buffer, sizeof(buffer));
		PrintToServer("Map 3 is %s.", buffer)
		ReadKeyValue(kv, "MatchState" , "NumberOfMaps", buffer, sizeof(buffer));
		PrintToServer("%s maps are scheduled.", buffer)
		ReadKeyValue(kv, "MatchState" , "RoundTime", buffer, sizeof(buffer));
		PrintToServer("RoundTime is %s min.", buffer)
		ReadKeyValue(kv, "MatchState" , "ConfigFile", buffer, sizeof(buffer));
		PrintToServer("War config file is %s.", buffer)
		ReadKeyValue(kv, "MatchState" , "TvFile", buffer, sizeof(buffer));
		PrintToServer("SourceTv config file is %s.", buffer)
		ReadKeyValue(kv, "MatchState" , "MapFile", buffer, sizeof(buffer));
		PrintToServer("Map file is %s.", buffer)
		
		PrintToServer("---------------------")
	}
	else
	{
		ReadKeyValue(kv, "teams" , "tagA", buffer, sizeof(buffer));
		PrintToChat(client, "%T", "Tag of the team", client, "A", buffer)
		ReadKeyValue(kv, "teams" , "tagB", buffer, sizeof(buffer));
		PrintToChat(client, "%T", "Tag of the team", client, "B", buffer)
		ReadKeyValue(kv, "teams" , "2", buffer, sizeof(buffer));
		PrintToChat(client,"%T", "First allied team", client , buffer)
		ReadKeyValue(kv, "teams" , "3", buffer, sizeof(buffer));
		PrintToChat(client, "%T", "First axis team", client, buffer)
		ReadKeyValue(kv, "Maps" , "map1", buffer, sizeof(buffer));
		PrintToChat(client, "Map 1 is %s.\n", buffer)
		ReadKeyValue(kv, "Maps" , "map2", buffer, sizeof(buffer));
		PrintToChat(client, "Map 2 is %s.\n", buffer)
		ReadKeyValue(kv, "Maps" , "map3", buffer, sizeof(buffer));
		PrintToChat(client, "Map 3 is %s.\n", buffer)
		ReadKeyValue(kv, "MatchState" , "NumberOfMaps", buffer, sizeof(buffer));
		PrintToChat(client, "%T", "maps are scheduled", client, buffer)
		ReadKeyValue(kv, "MatchState" , "RoundTime", buffer, sizeof(buffer));
		PrintToChat(client, "RoundTime is %s min.\n", buffer)
		ReadKeyValue(kv, "MatchState" , "ConfigFile", buffer, sizeof(buffer));
		PrintToChat(client, "War config file is %s.\n", buffer)
		ReadKeyValue(kv, "MatchState" , "TvFile", buffer, sizeof(buffer));
		PrintToChat(client, "SourceTv config file is %s.\n", buffer)
		ReadKeyValue(kv, "MatchState" , "MapFile", buffer, sizeof(buffer));
		PrintToChat(client, "Map file is %s.\n", buffer)
	}
}

RestartRound()
{
	LoadConfig()
	ServerCommand("mp_clan_ready_signal ready; mp_clan_readyrestart 1; mp_restartwarmup 1; mp_warmup_time -1; mp_timelimit 0")
	PrintToChatAll("Le Round est redémarré")
}

NbMapSet(String:numberofmaps[])
{
	WriteKeyValue(kv,"MatchState", "NumberOfMaps", numberofmaps)
}

TimeSet(String:roundtime[])
{
	WriteKeyValue(kv,"MatchState", "RoundTime", roundtime)
}

SetTeams(String:team[], String:side[])
{
	if(StrEqual("A",team))
	{	
		if(StrEqual("2",side))
		{	
			WriteKeyValue(kv, "teams", "2", "A")
			WriteKeyValue(kv, "teams", "3", "B")
		}
		else
		{
			WriteKeyValue(kv, "teams", "2", "B")
			WriteKeyValue(kv, "teams", "3", "A")
		}
	}
	
	if(StrEqual("B",team))
	{	
		if(StrEqual("3",side))
		{	
			WriteKeyValue(kv, "teams", "2", "A")
			WriteKeyValue(kv, "teams", "3", "B")
		}
		else
		{
			WriteKeyValue(kv, "teams", "2", "B")
			WriteKeyValue(kv, "teams", "3", "A")
		}
	}
	
}




MapsSet(number, String:mapname[])
{
	new String:buffer[8]
	Format(buffer, sizeof(buffer), "map%d", number)
	WriteKeyValue(kv,"Maps", buffer, mapname)
}

LoadConfig()
{
	new String:configfile[64]
	new String:buffer[3];
	ReadKeyValue(kv, "MatchState", "MatchIsLive", buffer, sizeof(buffer))
	ReadKeyValue(kv, "MatchState", "ConfigFile", configfile, sizeof(configfile))
	
	
	if(StrEqual(buffer, "1"))
	{
		ServerCommand("exec %s", configfile)
	}
	else
	{
		ServerCommand("exec server.cfg")
	}
}

WarIsLive(islive)
{
	if((islive == 1) && StrEqual("0",matchislive))
	{
		WriteKeyValue(kv, "MatchState", "MatchIsLive", "1");
		
		new String:nextmap[64];
		ReadKeyValue(kv, "Maps", "map1" , nextmap, sizeof(nextmap))
		
		new String:tvconfigfile[64]
		ReadKeyValue(kv, "MatchState", "TvFile", tvconfigfile, sizeof(tvconfigfile))
		
		ServerCommand("tv_enable 1")
		ServerCommand("exec %s", tvconfigfile)
		
		
		ServerCommand("sm_map %s", nextmap)
		ServerCommand("ma_map %s", nextmap)
		
		//LoadConfig();
	}
	
	if((islive == 0) && StrEqual("1",matchislive))
	{
		WriteFinalResults()
		DispScores()
		
		WriteKeyValue(kv, "MatchState", "MatchIsLive", "0");
		WriteKeyValue(kv, "MatchState", "RoundNumber", "1");
		WriteKeyValue(kv, "MatchState", "MapNumber", "1");
		WriteKeyValue(kv, "MatchState", "NumberOfMaps", "2");
		WriteKeyValue(kv, "teams", "2", "A");
		WriteKeyValue(kv, "teams", "3", "B");
		
		new String:subkey[16]
		for(new i=1;i<7;i++)
		{
			Format(subkey,sizeof(subkey),"d%dA",i)
			WriteKeyValue(kv, "scores", subkey, "0");
			Format(subkey,sizeof(subkey),"d%dB",i)
			WriteKeyValue(kv, "scores", subkey, "0");
			Format(subkey,sizeof(subkey),"r%dA",i)
			WriteKeyValue(kv, "scores", subkey, "0");
			Format(subkey,sizeof(subkey),"r%dB",i)
			WriteKeyValue(kv, "scores", subkey, "0");
		}
		
		
		KvRewind(kv)
		KeyValuesToFile(kv, "mymatch.txt")
		
		ServerCommand("tv_stoprecord; tv_autorecord 0")		
		
		LoadConfig();
		ServerCommand("mp_clan_restartround 1")
	}
}


UpdateKeyValues()
{
	new String:roundnumber[3];
	ReadKeyValue(kv, "MatchState", "RoundNumber", roundnumber, sizeof(roundnumber))
	new String:buffer[32];
	
	new String:scor0[8]
	IntToString(scores[0], scor0, sizeof(scor0))
	new String:scor1[8]
	IntToString(scores[1], scor1, sizeof(scor1))
	new String:scor2[8]
	IntToString(scores[2], scor2, sizeof(scor2))
	new String:scor3[8]
	IntToString(scores[3], scor3, sizeof(scor3))
	
	
	ReadKeyValue(kv, "teams", "2", buffer, sizeof(buffer));
	if(StrEqual(buffer,"A"))
	{	
		Format(buffer, sizeof(buffer), "r%sA", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor0)
		Format(buffer, sizeof(buffer), "d%sA", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor1)
		Format(buffer, sizeof(buffer), "r%sB", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor2)
		Format(buffer, sizeof(buffer), "d%sB", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor3)
		
		WriteKeyValue(kv, "teams", "2", "B");
		WriteKeyValue(kv, "teams", "3", "A");
	}
	else
	{
		Format(buffer, sizeof(buffer), "r%sA", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor2)
		Format(buffer, sizeof(buffer), "d%sA", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor3)
		Format(buffer, sizeof(buffer), "r%sB", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor0)
		Format(buffer, sizeof(buffer), "d%sB", roundnumber)
		WriteKeyValue(kv,"scores",buffer,scor1)
		
		WriteKeyValue(kv, "teams", "2", "A");
		WriteKeyValue(kv, "teams", "3", "B");
	}
	
	new newroundn = StringToInt(roundnumber) + 1
	new mapn = newroundn/2 +1
	
	IntToString(newroundn, buffer, sizeof(buffer))
	WriteKeyValue(kv, "MatchState", "RoundNumber", buffer)
	
	IntToString(mapn, buffer, sizeof(buffer))
	WriteKeyValue(kv, "MatchState", "MapNumber", buffer)
	
}


DispScores()
{
	
	new String:buffer[128];
	new String:section[]="scores";
	new String:subkey[128];
	
	new fullA,domA,fullB,domB
	
	for(new i=0;i<7;i++)
	{
		Format(subkey,sizeof(subkey),"r%dA", i);
		ReadKeyValue(kv, section, subkey, buffer, sizeof(buffer));
		fullA = fullA + StringToInt(buffer);
		Format(subkey,sizeof(subkey),"r%dB", i);
		ReadKeyValue(kv, section, subkey, buffer, sizeof(buffer));
		fullB = fullB + StringToInt(buffer);
	}
	
	ReadKeyValue(kv, "MatchState", "RoundNumber", buffer, sizeof(buffer))
	new roundnumber = (StringToInt(buffer)+1)/2;	//Retrieve the first roundnumber of the current map
	roundnumber = 2*roundnumber -1;
	
	for(new i=0;i<2;i++)
	{
		Format(subkey,sizeof(subkey),"d%dA",roundnumber + i)
		ReadKeyValue(kv, section, subkey, buffer, sizeof(buffer));
		domA = domA + StringToInt(buffer);
		Format(subkey,sizeof(subkey),"d%dB",roundnumber + i)
		ReadKeyValue(kv, section, subkey, buffer, sizeof(buffer));
		domB = domB + StringToInt(buffer);
	}
	
	new String:tagA[128];
	new String:tagB[128];
	
	ReadKeyValue(kv, "teams", "tagA", tagA, sizeof(tagA));
	ReadKeyValue(kv, "teams", "tagB", tagB, sizeof(tagB));
	
	ReadKeyValue(kv, "teams", "2", buffer, sizeof(buffer));
	if(StrEqual(buffer,"A"))
	{
		if((fullA + scores[0])== (fullB + scores[2]))
		{		
			PrintToChatAll("\x05%s\x01  %d (%d) \x04|\x01 %d (%d)  \x05%s", tagA, fullA + scores[0], domA + scores[1], fullB + scores[2], domB + scores[3], tagB)
			Format(buffer, sizeof(buffer),"%s: %d (%d) | %d (%d) :%s", tagA, fullA + scores[0], domA + scores[1], fullB + scores[2], domB + scores[3], tagB)
		}
		else
		{
			PrintToChatAll("\x05%s\x01  %d \x04|\x01 %d  \x05%s", tagA, fullA + scores[0], fullB + scores[2], tagB)
			Format(buffer, sizeof(buffer),"%s: %d | %d :%s", tagA, fullA + scores[0], fullB + scores[2], tagB)
		}
	}
	else
	{
		if((fullA + scores[2])== (fullB + scores[0]))
		{		
			PrintToChatAll("\x05%s\x01  %d (%d) \x04|\x01 %d (%d)  \x05%s", tagA, fullA + scores[2], domA + scores[3], fullB + scores[0], domB + scores[1], tagB)
			Format(buffer, sizeof(buffer),"%s: %d (%d) | %d (%d) :%s", tagA, fullA + scores[2], domA + scores[3], fullB + scores[0], domB + scores[1], tagB)
		}
		else
		{
			PrintToChatAll("\x05%s\x01  %d \x04|\x01 %d  \x05%s", tagA, fullA + scores[2], fullB + scores[0], tagB)
			Format(buffer, sizeof(buffer),"%s: %d | %d :%s", tagA, fullA + scores[2], fullB + scores[0], tagB)
		}
	}
	
	/*	
	//Show an Hud Message
	new Handle:hMessage = StartMessageAll("HintText");
	BfWriteString(hMessage, buffer); //String To Display
	EndMessage();
	*/
	
}


WriteFinalResults()
{
	new rounds[6]
	new ticks[6]
	
	new String:subkey[8]
	new String:buffer[8]
	
	for(new i=1;i<7;i++)
	{
		Format(subkey, sizeof(subkey), "r%dA", i)
		ReadKeyValue(kv, "scores", subkey, buffer, sizeof(buffer))
		rounds[(i-1)/2] = rounds[(i-1)/2] + StringToInt(buffer)
		Format(subkey, sizeof(subkey), "r%dB", i)
		ReadKeyValue(kv, "scores", subkey, buffer, sizeof(buffer))
		rounds[(i-1)/2 +3] = rounds[(i-1)/2+3] + StringToInt(buffer)
	}
	
	for(new i=1;i<7;i++)
	{
		Format(subkey, sizeof(subkey), "d%dA", i)
		ReadKeyValue(kv, "scores", subkey, buffer, sizeof(buffer))
		ticks[(i-1)/2] = ticks[(i-1)/2] + StringToInt(buffer)
		Format(subkey, sizeof(subkey), "d%dB", i)
		ReadKeyValue(kv, "scores", subkey, buffer, sizeof(buffer))
		ticks[(i-1)/2+3] = ticks[(i-1)/2+3] + StringToInt(buffer)
	}
	
	new String:snumberofmaps[3]
	ReadKeyValue(kv, "MatchState", "NumberOfMaps", snumberofmaps, sizeof(snumberofmaps))
	
	new numberofmaps = StringToInt(snumberofmaps)
	
	
	new String:map1[64]	
	new String:map2[64]
	new String:map3[64]
	
	ReadKeyValue(kv, "Maps", "map1" , map1, sizeof(map1))
	ReadKeyValue(kv, "Maps", "map2" , map2, sizeof(map2))
	ReadKeyValue(kv, "Maps", "map3" , map3, sizeof(map3))
	
	
	new String:tagA[128];
	new String:tagB[128];
	
	ReadKeyValue(kv, "teams", "tagA", tagA, sizeof(tagA));
	ReadKeyValue(kv, "teams", "tagB", tagB, sizeof(tagB));
	
	
	
	results = OpenFile("match_results.txt", "w");
	
	WriteFileLine(results, "Match %s VS %s\n", tagA, tagB)
	WriteFileLine(results,"%s", map1)
	if(rounds[0]==rounds[3])
	{
		WriteFileLine(results,"%s %d (%d) | %d (%d) %s\n", tagA, rounds[0], ticks[0], rounds[3], ticks[3], tagB)
	}
	else
	{
		WriteFileLine(results,"%s %d | %d %s\n", tagA, rounds[0], rounds[3], tagB)
	}
	
	if(numberofmaps>1)
	{
		WriteFileLine(results,"%s", map2)
		if(rounds[1]==rounds[4])
		{
			WriteFileLine(results,"%s %d (%d) | %d (%d) %s\n", tagA, rounds[1], ticks[1], rounds[4], ticks[4], tagB)
		}
		else
		{
			WriteFileLine(results,"%s %d | %d %s\n", tagA, rounds[1], rounds[4], tagB)
		}
	}
	
	if(numberofmaps>2)
	{
		WriteFileLine(results,"%s", map3)
		if(rounds[2]==rounds[5])
		{
			WriteFileLine(results,"%s %d (%d) | %d (%d) %s\n", tagA, rounds[2], ticks[2], rounds[5], ticks[5], tagB)
		}
		else
		{
			WriteFileLine(results,"%s %d | %d %s\n", tagA, rounds[2], rounds[5], tagB)
		}
	}
	
	WriteFileLine(results, "Total:")
	
	if((rounds[0]+rounds[1]+rounds[2])==(rounds[3]+rounds[4]+rounds[5]))
	{
		WriteFileLine(results,"%s %d (%d) | %d (%d) %s\n", tagA, rounds[0]+rounds[1]+rounds[2], ticks[0]+ticks[1]+ticks[2], rounds[3]+rounds[4]+rounds[5], ticks[3]+ticks[4]+ticks[5], tagB)
	}
	else
	{
		WriteFileLine(results,"%s %d | %d %s\n", tagA, rounds[0]+rounds[1]+rounds[2], rounds[3]+rounds[4]+rounds[5], tagB)
	}
	
	FlushFile(results);
	CloseHandle(results);
}



CreateMatchKeyValues()
{	
	KvJumpToKey(kv, "teams", true)
	WriteKeyValue(kv, "teams", "tagA", "TeamA");
	WriteKeyValue(kv, "teams", "tagB", "TeamB");
	WriteKeyValue(kv, "teams", "2", "A");
	WriteKeyValue(kv, "teams", "3", "B");
	
	KvGoBack(kv)
	KvJumpToKey(kv, "Maps", true)
	WriteKeyValue(kv, "Maps", "map1", "dod_anzio");
	WriteKeyValue(kv, "Maps", "map2", "dod_argentan");
	WriteKeyValue(kv, "Maps", "map3", "dod_flash");
	
	KvGoBack(kv)	
	KvJumpToKey(kv, "scores", true)
	new String:subkey[16]
	for(new i=1;i<7;i++)
	{
		Format(subkey,sizeof(subkey),"d%dA",i)
		WriteKeyValue(kv, "scores", subkey, "0");
		Format(subkey,sizeof(subkey),"d%dB",i)
		WriteKeyValue(kv, "scores", subkey, "0");
		Format(subkey,sizeof(subkey),"r%dA",i)
		WriteKeyValue(kv, "scores", subkey, "0");
		Format(subkey,sizeof(subkey),"r%dB",i)
		WriteKeyValue(kv, "scores", subkey, "0");
	}
	
	
	KvGoBack(kv)
	KvJumpToKey(kv, "MatchState", true)
	WriteKeyValue(kv, "MatchState", "MatchIsLive", "0");
	WriteKeyValue(kv, "MatchState", "RoundNumber", "1");
	WriteKeyValue(kv, "MatchState", "RoundTime", "15");
	WriteKeyValue(kv, "MatchState", "MapNumber", "1");
	WriteKeyValue(kv, "MatchState", "NumberOfMaps", "2");
	WriteKeyValue(kv, "MatchState", "ConfigFile", "configwar.cfg");
	WriteKeyValue(kv, "MatchState", "TvFile", "TVstart.cfg");
	WriteKeyValue(kv, "MatchState", "MapFile", "maplist.txt");
	
	
	KvRewind(kv)
	KeyValuesToFile(kv, "mymatch.txt")
}










////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//Events Actions
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


public Event_TeamScores(Handle:event, const String:name[], bool:dontBroadcast)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		
		new alliesscore = GetEventInt(event, "allies_caps");
		new axisscore = GetEventInt(event, "axis_caps");
		new alliestick = GetEventInt(event, "allies_tick");
		new axistick = GetEventInt(event, "axis_tick");
		
		scores[0]= alliesscore
		scores[1]= alliestick
		scores[2]= axisscore
		scores[3]= axistick
		
		//PrintToChatAll("dod_team_scores\n")
		//DispScores();
	}
}

public Event_TickPoints(Handle:event, const String:name[], bool:dontBroadcast)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		
		new team = GetEventInt(event, "team");
		new totalscore = GetEventInt(event, "totalscore");
		
		scores[2*team - 3]= totalscore
		//PrintToChatAll("dod_tick_points\n")
	}
}

public Event_RestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		//PrintToChatAll("dod_restart_round\n");
		scores[0]= 0;
		scores[1]= 0;
		scores[2]= 0;
		scores[3]= 0;
		DispScores();
	}
}

public Event_dod_round_win(Handle:event, const String:name[], bool:dontBroadcast)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		//PrintToChatAll("dod_round_win\n")
		new team = GetEventInt(event, "team");
		scores[2*team - 4]++;
		DispScores();
	}
}

public Event_dod_game_over(Handle:event, const String:name[], bool:dontBroadcast)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		//PrintToChatAll("dod_game_over\n")
		DispScores();
		UpdateKeyValues();
		
		new maxclients = GetMaxClients();
		decl client;
		
		for (client = 1; client <= maxclients; client++)
		{
			if (IsClientInGame(client) && !IsClientObserver(client))
			{
				ClientCommand(client, "+showscores")
				ClientCommand(client, "jpeg %s %s", "\"\"", "100")
			}
		}	
	}
}

public Event_dod_warmup_begins(Handle:event, const String:name[], bool:dontBroadcast)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		ServerCommand("mp_timelimit 0")
	}
}

public Event_dod_warmup_ends(Handle:event, const String:name[], bool:dontBroadcast)
{
	ReadKeyValue(kv, "MatchState", "MatchIsLive", matchislive, sizeof(matchislive))
	if(StrEqual("1", matchislive))
	{
		new String:roundtime[8]
		ReadKeyValue(kv, "MatchState", "RoundTime", roundtime, sizeof(roundtime))
		ServerCommand("status; mp_timelimit %s", roundtime)
	}
}




////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//Functions to manage KeyValues
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


bool:ReadKeyValue(Handle:keyv, String:section[], String:subkey[], String:result[], maxlength)
{
	KvRewind(keyv);
	if (!KvGotoFirstSubKey(keyv))
	{
		return false;
	}
	
	decl String:buffer[255];
	do
	{
		KvGetSectionName(keyv, buffer, sizeof(buffer));
		//PrintToChatAll("section = %s\n",buffer);
		if (StrEqual(buffer, section, false))
		{
			KvGetString(keyv, subkey, result, maxlength, "error");
			//PrintToChatAll("result = %s\n",result);
			KvRewind(keyv)
			return true;
		}
	} while (KvGotoNextKey(keyv));
	
	KvRewind(keyv)
	return false;
}


bool:WriteKeyValue(Handle:keyv, String:section[], String:subkey[], String:value[])
{
	KvRewind(keyv);	
	//new String:result[128];
	if (!KvGotoFirstSubKey(keyv))
	{
		return false;
	}
	
	decl String:buffer[255];
	do
	{
		KvGetSectionName(keyv, buffer, sizeof(buffer));
		//PrintToServer("section = %s\n",buffer);
		if (StrEqual(buffer, section, false))
		{
			KvSetString(keyv, subkey, value);
			//KvGetString(keyv, subkey, result, sizeof(result), "error");
			//PrintToChatAll("resultat = %s\n",result);
			KvRewind(keyv)
			return true;
		}
	} while (KvGotoNextKey(keyv));
	
	KvRewind(keyv)
	return false;
}