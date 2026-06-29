#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <dbi>
#include <roleplay>
#include <regex>
#include <smlib>
#include <roleplaying>

public Plugin:myinfo =
{
	name = "Roleplay",
	author = "belou",
	description = "plugin private",
	version = "1.0.2",
	url = ""
}
//------
// ENUM
//------
enum Roleplay_Joueur
{
	Id,
	String:Steamid[64],
	String:Prenom[64],
	String:Nom[64],
	Argent,
	Banque,
	Age,
	NiveauCut,
	String:Metier[32],
	FirstJoin,
	LastJoin,
	Vie,
	TempsJail,
	HasCB,
	HasRib,
	Permis,
	Kills,
	Deaths,
	String:Skin[128],
	Group
};

//------
// HANDLE
//------
new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:g_fDBConnected = INVALID_HANDLE;
new Handle:g_fPPFetched = INVALID_HANDLE;

//-----
// VARS
//-----
new g_ePlayers[MAXPLAYERS+1][Roleplay_Joueur];
new g_iProfilePhase[MAXPLAYERS+1] = {0, ...};

//-----
// BOOL
//-----
new bool:g_bLateLoad = false;

public OnPluginStart()
{
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("mp_limitteams 0");
	
	SQL_InitDatabase();
	Events_Init();
	Cvars_Init();
	Commands_Init();
	
	g_fDBConnected = CreateGlobalForward("Database_Connected", ET_Event, Param_Cell, Param_Cell);
	g_fPPFetched = CreateGlobalForward("Player_ProfileFetched", ET_Event, Param_Cell);
	
	// COMMANDES
	
	// BLOCK COMMANDES
	//RegConsoleCmd("jointeam", Block_CMD);
	RegConsoleCmd("explode", Block_CMD);
	RegConsoleCmd("kill", Block_CMD);
	RegConsoleCmd("coverme", Block_CMD);
	RegConsoleCmd("takepoint", Block_CMD);
	RegConsoleCmd("holdpos", Block_CMD);
	RegConsoleCmd("regroup", Block_CMD);
	RegConsoleCmd("followme", Block_CMD);
	RegConsoleCmd("takingfire", Block_CMD);
	RegConsoleCmd("go", Block_CMD);
	RegConsoleCmd("fallback", Block_CMD);
	RegConsoleCmd("sticktog", Block_CMD);
	RegConsoleCmd("getinpos", Block_CMD);
	RegConsoleCmd("stormfront", Block_CMD);
	RegConsoleCmd("report", Block_CMD);
	RegConsoleCmd("roger", Block_CMD);
	RegConsoleCmd("enemyspot", Block_CMD);
	RegConsoleCmd("needbackup", Block_CMD);
	RegConsoleCmd("sectorclear", Block_CMD);
	RegConsoleCmd("inposition", Block_CMD);
	RegConsoleCmd("reportingin", Block_CMD);
	RegConsoleCmd("getout", Block_CMD);
	RegConsoleCmd("negative", Block_CMD);
	RegConsoleCmd("enemydown", Block_CMD);
	//RegConsoleCmd("jointeam", cmd_jointeam);
	CreateTimer(5.0, CheckCT, _, 0);
}

public Action:CheckCT(Handle:timer){
	for(new i = 1; i<= MaxClients;i++){
		if(GetClientTeam(i) == 3 && !IsPlayerAlive(i) && strcmp(g_ePlayers[i][Nom], "")==0){
			CreateTimer(10.0, RespawnDead, i);
			PrintToChat(i, "[Roleplay] Vous allez revivre dans 10 secondes");
			ChangeClientTeam(i, 2);
		}
	}
}

/*public Action:cmd_jointeam(client, args) {
	ChangeClientTeam(client, CS_TEAM_T);
}*/

public OnMapStart(){
	/*new index = -1;
	while ((index = FindEntityByClassname(index, "light_environment")) != -1){
		DispatchKeyValue(index, "_light", "255 255 255 200");
		DispatchKeyValue(index, "_ambiant", "255 255 255 200");
	}
	while ((index = FindEntityByClassname(index, "env_fog_controller")) != -1){
		DispatchKeyValue(index, "fogstart", "40000");
		DispatchKeyValue(index, "fogend", "50000");
		DispatchKeyValue(index, "fogcolor", "255 255 255 200");
		DispatchKeyValue(index, "fogcolor2", "255 255 255 200");
	}*/
}

public OnPluginEnd()
{
	for(new i=1;i<=MaxClients;++i)
		if(IsClientInGame(i))
			SQL_SavePlayerData(i);
}

public OnClientAuthorized(client, const String:auth[])
{
	SQL_GetPlayerData(client);
}

public OnClientPutInServer(client)
{
	Hooks_InitClient(client);
	if(StrEqual(g_ePlayers[client][Prenom], "")){
		ChangeClientTeam(client, CS_TEAM_T);
		Profile_Setup(client);
	}
}

public OnClientDisconnect(client)
{
	//if(g_ePlayers[client][Id]!=0)
	SQL_SavePlayerData(client);
		
	g_ePlayers[client][Id]=0;
}

public Events_Init()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Commands_Init()
{
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_Say, "say");
}

public Cvars_Init()
{
	// cvar
}

public SQL_InitDatabase()
{
	if (SQL_CheckConfig(DATABASE_NAME))
		SQL_TConnect(SQLCallback_InitDatabase, DATABASE_NAME);
	else
		SetFailState("Database config \"%s\" doesn't exist.", DATABASE_NAME);
}

public SQLCallback_InitDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		g_hDatabase = hndl;
		new String:driver[64];
		SQL_ReadDriver(g_hDatabase, driver, 64);
		if(StrEqual(driver, "sqlite")){
			SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `players` (`id` int(11) PRIMARY KEY, `steamid` varchar(32) NOT NULL, `Prenom` varchar(32) NOT NULL, `Nom` varchar(32) NOT NULL, `Argent` int(11) NOT NULL, `Banque` int(11) NOT NULL, `Age` int(11) NOT NULL, `Metier` varchar(32) NOT NULL, `FirstJoin` int(11) NOT NULL, `LastJoin` int(11) NOT NULL, `Vie` int(11) NOT NULL, `TempsJail` int(11) NOT NULL, `HasCB` int(11) NOT NULL, `HasRib` int(11) NOT NULL, `Permis` int(11) NOT NULL, `Kills` int(11) NOT NULL, `Deaths` int(11) NOT NULL, `Skin` varchar(128) NOT NULL, `Group` int(11) NOT NULL, `NiveauCut` int(11) NOT NULL)");
			//SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `portes` (`id` int(11) PRIMARY KEY, `securite` int(11) NOT NULL, `groupe` varchar(32) NOT NULL)");
			//SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `locations` (`steamid` varchar(32), `idporte` int(11) NOT NULL, `nom` varchar(32) NOT NULL, `proprio` int(11) NOT NULL, `tempsloc` int(11) NOT NULL)");
			//SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `horloge` (`minutes` int(11), `heures` int(11) NOT NULL, `jours` int(11) NOT NULL, `mois` int(11) NOT NULL, `annee` int(11) NOT NULL)");
		}
		else{
			SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `players` (`id` int(11) NOT NULL AUTO_INCREMENT, `steamid` varchar(32), `Prenom` varchar(32), `Nom` varchar(32), `Argent` int(11), `Banque` int(11), `Age` int(11), `Metier` varchar(32), `FirstJoin` int(11), `LastJoin` int(11), `Vie` int(11), `TempsJail` int(11), `HasCB` int(11), `HasRib` int(11), `Permis` int(11) , `Kills` int(11), `Deaths` int(11), `Skin` varchar(128), `Group` int(11), `NiveauCut` int(11), PRIMARY KEY (`id`)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1");
			//SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `portes` (`id` int(11) NOT NULL AUTO_INCREMENT, `securite` int(11) NOT NULL, `groupe` varchar(32) NOT NULL, PRIMARY KEY (`id`)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1");
			//SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `locations` (`steamid` varchar(32), `idporte` int(11) NOT NULL, `nom` varchar(32) NOT NULL, `proprio` int(11) NOT NULL, `tempsloc` int(11) NOT NULL) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1");
			//SQL_TQuery(g_hDatabase, SQLCallback_Init, "CREATE TABLE IF NOT EXISTS `horloge` (`minutes` int(11), `heures` int(11) NOT NULL, `jours` int(11) NOT NULL, `mois` int(11) NOT NULL, `annee` int(11) NOT NULL) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1");
		}
		
		Call_StartForward(g_fDBConnected);
		Call_PushCell(g_hDatabase);
		if(StrEqual(driver, "sqlite"))
			Call_PushCell(true);
		else
			Call_PushCell(false);
		Call_Finish();
	}
	else  
			SetFailState("DATABASE FAILURE: %s", error);
}

public SQLCallback_Init(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("Query failed: %s", error);
	else
	{
		if(g_bLateLoad)
			for(new i=1;i<=MaxClients;++i)
				if(IsClientInGame(i))
				{
					SQL_GetPlayerData(i);
					Hooks_InitClient(i);
				}
	}
}

public SQLCallback_GetPlayerData(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetClientOfUserId(data);
	if(client==0)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else if (!SQL_GetRowCount(hndl))
	{
		new String:query[256];
		new String:authid[19];
		GetClientAuthString(client, authid, sizeof(authid));
		
		Format(query, sizeof(query), "INSERT INTO players (steamid) VALUES(\"%s\")", authid);
		SQL_TQuery(g_hDatabase, SQLCallback_CreatePlayer, query, data);

		g_ePlayers[client][Argent] = 0;
		g_ePlayers[client][Banque] = 5000;
		g_ePlayers[client][Age] = 14;
		g_ePlayers[client][NiveauCut] = 0;
		g_ePlayers[client][FirstJoin] = GetTime();
		g_ePlayers[client][LastJoin] = 0;
		g_ePlayers[client][Vie] = 100;
		g_ePlayers[client][TempsJail] = 0;
		g_ePlayers[client][HasCB] = 0;
		g_ePlayers[client][HasRib] = 0;
		g_ePlayers[client][Permis] = 0;
		g_ePlayers[client][Kills] = 0;
		g_ePlayers[client][Deaths] = 0;
		g_ePlayers[client][Group] = -1;
		strcopy(g_ePlayers[client][Skin], 128, "models/player/t_leet.mdl");
		strcopy(g_ePlayers[client][Metier], 32, "Sans emploi");
		strcopy(g_ePlayers[client][Steamid], 64, authid);
		strcopy(g_ePlayers[client][Prenom], 64, "");
		strcopy(g_ePlayers[client][Nom], 64, "");
	}
	else
	{	
		SQL_FetchRow(hndl);
		g_ePlayers[client][Id] = SQL_FetchInt(hndl, 0);
		g_ePlayers[client][Argent] = SQL_FetchInt(hndl, 4);
		g_ePlayers[client][Banque] = SQL_FetchInt(hndl, 5);
		g_ePlayers[client][Age] = SQL_FetchInt(hndl, 6);
		g_ePlayers[client][FirstJoin] = SQL_FetchInt(hndl, 8);
		g_ePlayers[client][LastJoin] = SQL_FetchInt(hndl, 9);
		g_ePlayers[client][Vie] = SQL_FetchInt(hndl, 10);
		g_ePlayers[client][TempsJail] = SQL_FetchInt(hndl, 11);
		g_ePlayers[client][HasCB] = SQL_FetchInt(hndl, 12);
		g_ePlayers[client][HasRib] = SQL_FetchInt(hndl, 13);
		g_ePlayers[client][Permis] = SQL_FetchInt(hndl, 14);
		g_ePlayers[client][Kills] = SQL_FetchInt(hndl, 15);
		g_ePlayers[client][Deaths] = SQL_FetchInt(hndl, 16);
		g_ePlayers[client][Group] = SQL_FetchInt(hndl, 18);
		g_ePlayers[client][NiveauCut] = SQL_FetchInt(hndl, 19);
		
		SQL_FetchString(hndl, 17, g_ePlayers[client][Skin], 128);
		SQL_FetchString(hndl, 7, g_ePlayers[client][Metier], 32);
		SQL_FetchString(hndl, 1, g_ePlayers[client][Steamid], 64);
		SQL_FetchString(hndl, 3, g_ePlayers[client][Nom], 64);
		SQL_FetchString(hndl, 2, g_ePlayers[client][Prenom], 64);
	}

	Call_StartForward(g_fPPFetched);
	Call_PushCell(client);
	Call_Finish()
	
	if(StrEqual(g_ePlayers[client][Prenom], "") && IsClientInGame(client))
	{
		Profile_Setup(client);
	}
	
	CreateTimer(0.0, Timer_Stats, client);
	CreateTimer(1.0, Timer_Stats, client, TIMER_REPEAT);
}

public SQLCallback_CreatePlayer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetClientOfUserId(data);
	if(client==0)
		return;

	if (hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
	else
		g_ePlayers[client][Id] = SQL_GetInsertId(hndl);
}

public SQL_SavePlayerData(client)
{
	new String:query[512];
	Format(query, sizeof(query), "UPDATE `players` SET `Prenom`=\"%s\",`Nom`=\"%s\",`Argent`=%d,`Banque`=%d,`Age`=%d,`Metier`=\"%s\",`FirstJoin`=%d,`LastJoin`=%d,`Vie`=%d,`TempsJail`=%d,`HasCB`=%d,`HasRib`=%d,`Permis`=%d,`Kills`=%d,`Deaths`=%d,`Skin`=\"%s\",`Group`=%d,`NiveauCut`= %d WHERE id=%d",
	g_ePlayers[client][Prenom], g_ePlayers[client][Nom], g_ePlayers[client][Argent], g_ePlayers[client][Banque],
	g_ePlayers[client][Age], g_ePlayers[client][Metier], g_ePlayers[client][FirstJoin], g_ePlayers[client][LastJoin],
	g_ePlayers[client][Vie], g_ePlayers[client][TempsJail], g_ePlayers[client][HasCB], g_ePlayers[client][HasRib],
	g_ePlayers[client][Permis], g_ePlayers[client][Kills], g_ePlayers[client][Deaths], g_ePlayers[client][Skin],
	g_ePlayers[client][Group], g_ePlayers[client][NiveauCut], g_ePlayers[client][Id]);
	
	SQL_TQuery(g_hDatabase, SQLCallback_Void, query);
}

public SQL_GetPlayerData(client)
{
	new String:query[64];
	new String:auth[32];
	GetClientAuthString(client, auth, 32);
	Format(query, sizeof(query), "SELECT * FROM players WHERE steamid=\"%s\"", auth);

	SQL_TQuery(g_hDatabase, SQLCallback_GetPlayerData, query, GetClientUserId(client)); 
}

public SQLCallback_Void(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("Query failed: %s", error);
}

public Action:Block_CMD(client, Args)
{
    return Plugin_Stop;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	SetEntProp(client, Prop_Send, "m_iAccount", g_ePlayers[client][Argent]);
	
	new String:Tag[32];
	Format(Tag, sizeof(Tag), "[%s]", g_ePlayers[client][Metier]);
	CS_SetClientClanTag(client, Tag);
	
	if(GetClientTeam(client)>1){
		Client_RemoveAllWeapons(client, "", false);
		GivePlayerItem(client, "weapon_knife");
	}
		
	SetEntityHealth(client, g_ePlayers[client][Vie]);
	if(IsPlayerAlive(client) && GetClientTeam(client)>1)
		PrintToChat(client,"Bienvenue sur le roleplay Test");
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_ePlayers[client][Vie] = GetEventInt(event, "health");
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_ePlayers[client][Vie] = 100;
	dontBroadcast = true;
	CreateTimer(10.0, RespawnDead, client);
	PrintToChat(client, "[Roleplay] Vous allez revivre dans 10 secondes");
	return Plugin_Changed;
}

public Action:RespawnDead(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		CS_RespawnPlayer(client);
	}
}

public Action:Command_Say(client, const String:command[], args)
{
	if(g_iProfilePhase[client]!=0)
	{
		new String:sMessage[128];
		GetCmdArg(1, sMessage, 128);
		TrimString(sMessage);
		Profile_HandlePhase(client, sMessage);
	}
	
	return Plugin_Continue;
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client) || (g_ePlayers[client][Id]!=0 && Profile_IsFilled(client)))
	{
		if(!StrEqual(g_ePlayers[client][Prenom], "")){
			if(GetTeamClientCount(3)>0){
				CreateTimer(10.0, RespawnDead, client);
				PrintToChat(client, "[Roleplay] Vous allez revivre dans 10 secondes");
			}
			SetClientScoreBoardDisplay(client);
			ChangeClientTeam(client, 2);
		}
		return Plugin_Continue;
	}

	ChangeClientTeam(client, 2);
	Profile_Setup(client);
	
	return Plugin_Stop;
}

public Hooks_InitClient(client)
{
	SDKHook(client, SDKHook_WeaponCanSwitchTo, Event_WeaponCanSwitchTo);
}

public Action:Event_WeaponCanSwitchTo(client, weapon)
{
	if(strcmp(g_ePlayers[client][Metier], "Sans emploi") == 0)
	{
		if(IsValidEdict(weapon))
		{
			new String:classname[64];
			GetEdictClassname(weapon, classname, sizeof(classname));
			if(strcmp(classname, "weapon_knife")!=0)
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Profile_Setup(client)
{
	new Handle:hPanel = CreatePanel();
	
	new String:sTmp[128];
	
	DrawPanelText(hPanel, "Creation du Profil");
	DrawPanelText(hPanel, "-------------------");
	
	if(StrEqual(g_ePlayers[client][Prenom], ""))
		Format(sTmp, 128, "%s: <%s>", "Profile_Firstname", "None");
	else
		Format(sTmp, 128, "%s: %s", "Profile_Firstname", g_ePlayers[client][Prenom]);
	
	DrawPanelItem(hPanel, sTmp);
	
	if(StrEqual(g_ePlayers[client][Nom], ""))
		Format(sTmp, 128, "%s: <%s>", "Profile_Surname", "None");
	else
		Format(sTmp, 128, "%s: %s", "Profile_Surname", g_ePlayers[client][Nom]);
	
	DrawPanelItem(hPanel, sTmp);
	
	Format(sTmp, 128, "%s", "Profile_Finish");
	DrawPanelText(hPanel, " ");
	
	if(!StrEqual(g_ePlayers[client][Prenom], "") && !StrEqual(g_ePlayers[client][Nom], ""))
		DrawPanelItem(hPanel, sTmp);
	else
		DrawPanelItem(hPanel, sTmp, ITEMDRAW_DISABLED);
	
	SendPanelToClient(hPanel, client, Profile_Handler, 0);
}

public Profile_Handler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2==1)
		{
			PrintToChat(client, "%s", "Desired_Firstname");
			g_iProfilePhase[client]=1;
		}
		else if(param2==2)
		{
			PrintToChat(client, "%s", "Desired_Surname");
			g_iProfilePhase[client]=2;
		}
		
		if(param2!=3)
			Profile_Setup(client)
		else
		{
			g_iProfilePhase[client]=0;
			SetClientScoreBoardDisplay(client);
			CreateTimer(10.0, RespawnDead, client);
			PrintToChat(client, "[Roleplay] Vous allez revivre dans 10 secondes");
		}
	} else if (action == MenuAction_Cancel) {
		Profile_Setup(client);
	}
}

public bool:Profile_IsFilled(client)
{
	if(StrEqual(g_ePlayers[client][Prenom], ""))
		return false;
	if(StrEqual(g_ePlayers[client][Nom], ""))
		return false;
		
	return true;
}

public Profile_HandlePhase(client, String:message[])
{
	if(g_iProfilePhase[client]==1)
	{
		for(new i=0;i<strlen(message);++i)
			message[i]=CharToLower(message[i]);
		if(ValidName(message))
		{
			message[0]=CharToUpper(message[0]);
			strcopy(g_ePlayers[client][Prenom], 64, message);
			g_iProfilePhase[client]=0;
			Profile_Setup(client);
		}
		else
			PrintToChat(client, "%s", "Invalid_Name");
	} else if(g_iProfilePhase[client]==2)
	{
		for(new i=0;i<strlen(message);++i)
			message[i]=CharToLower(message[i]);
		if(ValidName(message))
		{
			message[0]=CharToUpper(message[0]);
			strcopy(g_ePlayers[client][Nom], 64, message);
			g_iProfilePhase[client]=0;
			Profile_Setup(client);
		}
		else
			PrintToChat(client, "%s", "Invalid_Name");
	}
}

public KeyHintText(client, String:message[])
{
	new Handle:bf = StartMessageOne("KeyHintText", client)
	BfWriteByte(bf, 1);
	BfWriteString(bf, message);
	EndMessage();
}

SetClientScoreBoardDisplay(client)
{
	new String:sName[130];
	Format(sName, 130, "%s %s - %d ans", g_ePlayers[client][Prenom], g_ePlayers[client][Nom], g_ePlayers[client][Age]);
	SetClientInfo(client, "name", sName);
	SetEntPropString(client, Prop_Data, "m_szNetname", sName);
	CS_SetClientClanTag(client, "");
}

public ValidName(String:name[])
{
	if(strlen(name)<2)
		return false;
	for(new i=0;i<strlen(name);++i)
		if(name[i]>122 || name[i]<97)
			return false;
	return true;
}

bool:GetEntDistance(ent1, ent2)
{
	decl Float:orig1[3], Float:orig2[3];
	new vecOrigin;
	GetEntDataVector(ent1, vecOrigin, orig1);
	GetEntDataVector(ent2, vecOrigin, orig2);
	
	return GetVectorDistance(orig1, orig2);
}

public Action:Timer_Stats(Handle:timer, any:client)
{
	if(!IsClientConnected(client))
		return Plugin_Stop;
	if(!IsClientInGame(client))
		return Plugin_Continue;
	//if(!IsPlayerAlive(client))
	//	return Plugin_Continue;
	if(g_ePlayers[client][Id]==0)
		return Plugin_Continue;
	
	new String:stats[256];
	
	new String:zone[64], String:tag[64];
	Tagger_GetClientZone(client, zone, 64, tag, 64)
	if(StrEqual(zone, ""))
		zone = "Exterieur";
	
	new String:PermisJoueur[32];
	if(g_ePlayers[client][Permis] == 0)
		strcopy(PermisJoueur, 32, "Sans Permis");
	else if(g_ePlayers[client][Permis] == 1)
		strcopy(PermisJoueur, 32, "Permis leger");
	else if(g_ePlayers[client][Permis] == 2)
		strcopy(PermisJoueur, 32, "Permis lourd");
	/*
		Vendredi 15 Juin 2013 - 16;54
		Zone: Exterieur
		=============================
		Argent: 5000
		Banque: 3750
		Metier: Sans emploi
		Permis: Aucuns	
	*/
	if(!IsPlayerAlive(client))
		Format(stats, sizeof(stats), "LA DATE A FAIRE\nZone: %s\n-------------------\nArgent: %d\nBanque: %d\nMetier: %s\nPermis: %s\nVous Etes Mort !", 
	zone,g_ePlayers[client][Argent],g_ePlayers[client][Banque],g_ePlayers[client][Metier],PermisJoueur);
	else if(IsPlayerAlive(client))
		Format(stats, sizeof(stats), "LA DATE A FAIRE\nZone: %s\n-------------------\nArgent: %d\nBanque: %d\nMetier: %s\nPermis: %s", 
	zone,g_ePlayers[client][Argent],g_ePlayers[client][Banque],g_ePlayers[client][Metier],PermisJoueur);
	KeyHintText(client, stats);
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new iClientTarget = GetClientAimTarget(client);
	if (iClientTarget > 0 && GetEntDistance(client, iClientTarget))
	{
		decl String:targetName[32];
		if (GetClientName(iClientTarget, targetName, sizeof(targetName)))
			PrintHintText(client, "%s %s\n %d$ Age: %d\n%s [%d]", g_ePlayers[iClientTarget][Nom], g_ePlayers[iClientTarget][Prenom], g_ePlayers[iClientTarget][Argent], g_ePlayers[iClientTarget][Metier], g_ePlayers[iClientTarget][Vie]);
	}
	
	return Plugin_Changed;
}
