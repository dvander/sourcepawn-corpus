//Author: [NotD] l0calh0st
//Website: www.notdelite.com

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define MAX_BUFF		512
#define MAX_NAME		64
#define MAX_TRACERS 80
#define MAX_COLORS 20

#define MAX_HATS 5
#define MAX_STEAMID 25
#define MAX_WEAPONS 5
#define CS_TEAM_SPEC 1
#define CS_TEAM_T  2
#define CS_TEAM_CT 3

new Handle:hDatabase = INVALID_HANDLE;

//Determines VIP
new bool:isVip[MAXPLAYERS + 1];
new bool:isLoaded[MAXPLAYERS + 1];
//Player Settings
new credits[MAXPLAYERS + 1];
new badge[MAXPLAYERS + 1];
new tracer[MAXPLAYERS + 1];
new tracerType[MAXPLAYERS + 1];
new glow[MAXPLAYERS + 1];
new weapon[MAXPLAYERS + 1];
new width[MAXPLAYERS + 1];
new render[MAXPLAYERS + 1];

//Timers
new Handle:creditTimer;

//Colors and Tracer Models
new String:g_ColorNames[MAX_COLORS][32];
new g_Colors[MAX_COLORS][4];
new String:g_TracerNames[MAX_TRACERS][32];
new g_TracerVIP[MAX_TRACERS];
new g_TracerEvent[MAX_TRACERS];
new String:g_TracerSprites[MAX_TRACERS][32];
new g_Tracers[MAX_TRACERS];
new g_SpriteModel[MAXPLAYERS + 1];

//Menu counters
new g_NumOfTracers;
new g_NumOfColors;

//Includes
#include "store/sql"
#include "store/menu"
#include "store/buymenu"

public OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	//RegServerCmd("sm_givecred", Command_GiveCred);
	//RegServerCmd("sm_givevip", Command_GiveVIP);
	//RegServerCmd("sm_giveboth", Command_GiveBoth);
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_team", PlayerTeam);
	
	StartSQL();
	HookEvent("round_end", RoundEnd);
	
	for (new index = 0; index < MAXPLAYERS; index++)
	{
		g_SpriteModel[index] = -1;
	}
}

public OnPluginEnd()
{
	CloseHandle(hDatabase);
	hDatabase = INVALID_HANDLE;
	
	if (creditTimer != INVALID_HANDLE)
		KillTimer(creditTimer);
	creditTimer = INVALID_HANDLE;
}

public Action:PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidEntity(g_SpriteModel[client]))
	{
		RemoveEdict(g_SpriteModel[client]);
	}
	g_SpriteModel[client] = -1;
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, g_Colors[glow[client]][0], g_Colors[glow[client]][1], g_Colors[glow[client]][2], 255);
	
	CreateTimer(1.0, GiveTrail, client);
	//CreateTimer(1.0, GiveHat, client);
}

public PlayerTeam(Handle:Spawn_Event, const String:Death_Name[], bool:Death_Broadcast )
{
	new client = GetClientOfUserId( GetEventInt(Spawn_Event,"userid") );
	new team = GetEventInt(Spawn_Event, "team");
	
	if (team == 1)
	{
		if (IsValidEntity(g_SpriteModel[client]))
		{
			RemoveEdict(g_SpriteModel[client]);
		}
		g_SpriteModel[client] = -1;
		
		//if (IsValidEntity(g_Hat[client]))
		//{
		//	RemoveEdict(g_Hat[client]);
		//}
		//g_Hat[client] = -1;
	}
}

public Action:PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidEntity(g_SpriteModel[client]))
	{
		RemoveEdict(g_SpriteModel[client]);
	}
	g_SpriteModel[client] = -1;
}

public Action:RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	for (new index = 0; index < MAXPLAYERS; index++)
	{
		g_SpriteModel[index] = -1;
	}
}

public Action:GiveTrail(Handle:timer, any:client)
{
	SpriteTrail(client);
}

public Action:GiveHat(Handle:timer, any:client)
{
	//Hat(client);
}

StartSQL()
{
	SQL_TConnect(GotDatabase, "store");
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{	
		new String:currentMap[25], String:srvCmd[50];
		GetCurrentMap(currentMap, sizeof(currentMap));
		Format(srvCmd, sizeof(srvCmd), "changelevel %s", currentMap);
		LogError("Database failure: %s", error);
	} else {
		PrintToServer("Connection found!");
		hDatabase = hndl;
		LoadColors();
		LoadTracers();
	}
}

public OnMapStart()
{
	creditTimer = CreateTimer(300.0, GiveCredits, _, TIMER_REPEAT);
	
	AddFileToDownloadsTable("materials/sprites/trails/rainbow.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/rainbow.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/leaves1.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/leaves1.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/fire1.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/fire1.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/ice1.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/ice1.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/leaves21.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/leaves21.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/metallic1.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/metallic1.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/peace.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/peace.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/earth.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/earth.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/wheel.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/wheel.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/awesome.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/awesome.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/star.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/star.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/mushroom.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/mushroom.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/arrows.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/arrows.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/crackedbeam.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/crackedbeam.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/uparrow.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/uparrow.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/wings.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/wings.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/crown.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/crown.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/dna2.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/dna2.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/paintsplatter.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/paintsplatter.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/doublerainbow.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/doublerainbow.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/banknote.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/banknote.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/biohazard.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/biohazard.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/bombomb.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/bombomb.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/boo.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/boo.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/heart.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/heart.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/hellokitty.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/hellokitty.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/hypnotic.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/hypnotic.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/mario.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/mario.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/medic.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/medic.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/moneybag.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/moneybag.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/mushroom2.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/mushroom2.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/pinkribbon.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/pinkribbon.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/poker.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/poker.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/potleaf.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/potleaf.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/pretzel.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/pretzel.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/psychball.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/psychball.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/psychtriangle.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/psychtriangle.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/seprainbow.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/seprainbow.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/skullnbones.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/skullnbones.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/swirly.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/swirly.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/taco.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/taco.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/trippy.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/trippy.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/usflag.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/usflag.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/warrior.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/warrior.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/apple.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/apple.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/arrowrainbow.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/arrowrainbow.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/beermug.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/beermug.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/blade.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/blade.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/bluelightning.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/bluelightning.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/bulletbill.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/bulletbill.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/bullets.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/bullets.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/canadaflag.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/canadaflag.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/candies.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/candies.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/cocacola.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/cocacola.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/colorbolt.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/colorbolt.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/cookies.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/cookies.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/donuts.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/donuts.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/energy.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/energy.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/energyball.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/energyball.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/footprint.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/footprint.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/germanflag.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/germanflag.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/goomba.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/goomba.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/grenade.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/grenade.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/gummybears.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/gummybears.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/handgun.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/handgun.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/lightspeed.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/lightspeed.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/lol.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/lol.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/pacman.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/pacman.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/pawprint.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/pawprint.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/skull.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/skull.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/ukflag.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/ukflag.vmt");
	AddFileToDownloadsTable("materials/sprites/trails/words.vtf");
	AddFileToDownloadsTable("materials/sprites/trails/words.vmt");
}

public OnMapEnd()
{
	if (creditTimer != INVALID_HANDLE)
		KillTimer(creditTimer);
	creditTimer = INVALID_HANDLE;
	
	for (new client = 0; client < MAXPLAYERS; client++)
	{
		if (IsValidEntity(g_SpriteModel[client]))
		{
			RemoveEdict(g_SpriteModel[client]);
		}
		g_SpriteModel[client] = -1;
	}
}

SpriteTrail(client)
{
	if (tracerType[client] == 0)
		return;
	
	if (!IsPlayerAlive(client))
		return;
	
	new String:tracerPath[70], String:tracerColor[50], String:renderStr[5], String:widthStr[5];
	IntToString(width[client], widthStr, sizeof(widthStr));
	IntToString(render[client], renderStr, sizeof(renderStr));
	
	Format(tracerPath, sizeof(tracerPath), "materials/sprites/%s.vmt", g_TracerSprites[tracerType[client]]);
	PrecacheModel(tracerPath);
	Format(tracerColor, sizeof(tracerColor), "%d %d %d", g_Colors[tracer[client]][0], g_Colors[tracer[client]][1], g_Colors[tracer[client]][2]);
	g_SpriteModel[client] = CreateEntityByName("env_spritetrail");
	if (IsValidEntity(g_SpriteModel[client])) 
	{
		new String:strTargetName[MAX_NAME_LENGTH];
		GetClientName(client, strTargetName, sizeof(strTargetName));
		
		DispatchKeyValue(client, "targetname", strTargetName);
		DispatchKeyValue(g_SpriteModel[client], "parentname", strTargetName);
		DispatchKeyValue(g_SpriteModel[client], "lifetime", "1.0");
		DispatchKeyValue(g_SpriteModel[client], "endwidth", "6.0");
		DispatchKeyValue(g_SpriteModel[client], "startwidth", widthStr);
		DispatchKeyValue(g_SpriteModel[client], "spritename", tracerPath);
		DispatchKeyValue(g_SpriteModel[client], "renderamt", "255");
		DispatchKeyValue(g_SpriteModel[client], "rendercolor", tracerColor);
		DispatchKeyValue(g_SpriteModel[client], "rendermode", renderStr);
		
		DispatchSpawn(g_SpriteModel[client]);
		
		new Float:Client_Origin[3];
		GetClientAbsOrigin(client,Client_Origin);
		Client_Origin[2] += 10.0; //Beam clips into the floor without this
		
		
		TeleportEntity(g_SpriteModel[client], Client_Origin, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString(strTargetName);
		AcceptEntityInput(g_SpriteModel[client], "SetParent"); 
		SetEntPropFloat(g_SpriteModel[client], Prop_Send, "m_flTextureRes", 0.05);
	}
}

public Action:GiveCredits(Handle:timer)
{
	new maxclients = GetMaxClients();
	for (new client = 1; client < maxclients; client++)
	{
		if (!IsValidEdict(client))
			continue;
		
		if (IsFakeClient(client))
			continue;
		
		if (!IsClientInGame(client))
			continue;
			
		if (GetClientTeam(client) == CS_TEAM_SPEC)
			continue;
			
		credits[client] += 25;
		Save(client);
		
		PrintToChat(client, "\x04[STORE]\x01 You have been given 25 credits. Type !store to use them.");
	}
}

Save(client)
{
	if (isLoaded[client] == false)
		return;

	if (!IsClientInGame(client))
		return;
	
	new String:query[400], String:auth[MAX_STEAMID];
	GetClientAuthString(client, auth, sizeof(auth));
	Format(query, sizeof(query), "UPDATE settings SET credits = %d, badge = %d, tracer = %d, glow = %d, tracertype = %d, width = %d, render = %d WHERE steamid = '%s'", credits[client], badge[client], tracer[client], glow[client], tracerType[client], width[client], render[client], auth);
	
	SQL_TQuery(hDatabase, T_Save, query, client);
} 

Load(client)
{
	new String:query[400], String:auth[MAX_STEAMID];
	GetClientAuthString(client, auth, sizeof(auth));
	Format(query, sizeof(query), "SELECT * FROM settings WHERE steamid = '%s'", auth);

	SQL_TQuery(hDatabase, T_Load, query, client);
}

public OnClientPutInServer(client)
{	
	if (!IsFakeClient(client))
	{
		isVip[client] = false;
		g_SpriteModel[client] = -1;
		CheckVIP(client);
		Load(client);
	}
}

public OnClientDisconnect(client)
{
	credits[client] = 0;
	isVip[client] = false;
	tracer[client] = 0;
	glow[client] = 0;
	tracerType[client] = 0;
	weapon[client] = 0;
	badge[client] = 0;
	isLoaded[client] = false;
	
	if (IsValidEntity(g_SpriteModel[client]))
	{
		RemoveEdict(g_SpriteModel[client]);
	}
	g_SpriteModel[client] = -1;
}

public Action:Command_Say(client, const String:command[], args)
{
	if (client <  1)
		return Plugin_Handled;

	if (!IsClientConnected(client))
		return Plugin_Handled;
		
	if (!IsClientInGame(client))
		return Plugin_Handled;
		
	decl String:msg[MAX_BUFF],String:name[MAX_NAME];
	GetCmdArg(1,msg,sizeof(msg));
	GetClientName(client,name,sizeof(name));

	if (msg[0] == '@' || msg[0] == '/')
		return Plugin_Handled;
	
	if (!strcmp(msg,"!store",false) || !strcmp(msg,"store",false) || !strcmp(msg,"shop",false) || !strcmp(msg,"!shop",false))
	{
		if (isLoaded[client])
		{
			Menu_Store(client);
			return Plugin_Handled;
		}
		else
			PrintToChat(client, "\x04[STORE]\x01 You cannot use !store at this time.");
	}
	
	if (isVip[client] && strcmp(msg,"!class",false) && strcmp(msg,"!cpmenu",false) && 
							strcmp(msg,"!obj",false) && strcmp(msg,"!cpsave",false) &&
							strcmp(msg,"!cptele",false) && strcmp(msg,"!servers",false) && 
							strcmp(msg,"rpgmenu",false) && strcmp(msg,"rpgtop10",false) && 
							strcmp(msg,"!stats",false) && strcmp(msg,"!squad",false) && 
							strcmp(msg,"!rank",false) && strcmp(msg,"!cheer",false) && 
							strcmp(msg,"!bfmenu",false) && strcmp(msg,"!menu",false) && 
							strcmp(msg,"rpgrank",false) && strcmp(msg,"!models",false) &&
							strcmp(msg,"!arty",false) && strcmp(msg,"!artillery",false))
	{
		decl String:mesg[MAX_BUFF];

		if (StrEqual(command,"say")) 
			Format(mesg,sizeof(mesg),"\x04[VIP] \x03%s\x01: %s",name,msg);
		if (StrEqual(command,"say_team")) 
			Format(mesg,sizeof(mesg),"\x04[VIP] \x03%s\x01: %s",name,msg);

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (!IsPlayerAlive(i) || IsPlayerAlive(client)))
			{
				if (StrEqual(command,"say_team") && (GetClientTeam(client) != GetClientTeam(i)))
				{
 continue;
 }
 PrintToChatEx(client, i, mesg);	
			}
		}
	}
	else
		return Plugin_Continue;
	return Plugin_Handled;
}

public PrintToChatEx(from,to,const String:format[],any:...)
{
	decl String:message[MAX_BUFF];
	VFormat(message,sizeof(message),format,4);
	
	if (!to)
	{
		PrintToChat(to,message);
		return;
	}

	new Handle:hBf = StartMessageOne("SayText2",to);
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}

public FindClient(client,String:Target[])
{
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return -1;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return -1;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return -1;
	}
	
	return iClients[0];
}

CheckVIP(client)
{
	new String:auth[25];
	GetClientAuthString(client, auth, sizeof(auth));
	decl String:query[255];
	Format(query, sizeof(query), "SELECT steamid FROM vip WHERE steamid = '%s'", auth);

	SQL_TQuery(hDatabase, T_CheckVIP, query, client);
}

SetOnlineStatus(client, isOnline)
{
	new String:auth[25];
	GetClientAuthString(client, auth, sizeof(auth));
	decl String:query[255];
	Format(query, sizeof(query), "UPDATE settings SET online = %d WHERE steamid = '%s'", isOnline, auth);
	
	SQL_TQuery(hDatabase, T_Save, query, client);
	
	if (isOnline == 0)
	{
		Format(query, sizeof(query), "UPDATE settings SET credits = credits + queue WHERE steamid = '%s'", isOnline, auth);
		SQL_TQuery(hDatabase, T_Queue, query, client);
	}

	
}

LoadColors()
{
	new String:query[255];
	Format(query, sizeof(query), "SELECT * FROM colors");

	SQL_TQuery(hDatabase, T_LoadColors, query, _);
}

LoadTracers()
{
	new String:query[255];
	Format(query, sizeof(query), "SELECT * FROM tracers");
	SQL_TQuery(hDatabase, T_LoadTracers, query, _);
}