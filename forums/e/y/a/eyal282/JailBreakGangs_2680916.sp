#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define UPDATE_URL "https://raw.githubusercontent.com/eyal282/SourceMod-GameData-Updater/master/Offsets/PlayerMaxSpeed/updatefile.txt"

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)

#define PREFIX " \x07[\x0BJB Gangs\x07]\x01"
#define MENU_PREFIX "[JB Gangs]"
new String:NET_WORTH_ORDER_BY_FORMULA[512];

new bool:dbFullConnected = false;

new Handle:dbGangs = INVALID_HANDLE;

new Handle:hcv_HonorPerKill = INVALID_HANDLE;

#define GANG_COSTCREATE 10000

#define GANG_HEALTHCOST 7500
#define GANG_HEALTHMAX 5
#define GANG_HEALTHINCREASE 3

#define GANG_SPEEDCOST 8000
#define GANG_SPEEDMAX 8
#define GANG_SPEEDINCREASE 3.5

#define GANG_NADECOST 5000
#define GANG_NADEMAX 10
#define GANG_NADEINCREASE 1.5

#define GANG_GETCREDITSCOST 6000
#define GANG_GETCREDITSMAX 10
#define GANG_GETCREDITSINCREASE 15

#define GANG_INITSIZE 4
#define GANG_SIZEINCREASE 1
#define GANG_SIZECOST 6500
#define GANG_SIZEMAX 3

#define GANG_NULL ""

#define RANK_NULL -1
#define RANK_MEMBER 0
#define RANK_OFFICER 1
#define RANK_ADMIN 2
#define RANK_MANAGER 3
#define RANK_COLEADER 4
#define RANK_LEADER 420

new const String:const_GameDataFile[] = "PlayerMaxSpeedOffset";

// Variables about the client's gang.

new ClientHonor[MAXPLAYERS+1];
new String:ClientGang[MAXPLAYERS+1][32], ClientRank[MAXPLAYERS+1], String:ClientMotd[MAXPLAYERS+1][32], bool:ClientLoadedFromDb[MAXPLAYERS+1], String:ClientTag[MAXPLAYERS+1][32];

new ClientHealthPerkT[MAXPLAYERS+1], ClientSpeedPerkT[MAXPLAYERS+1], ClientNadePerkT[MAXPLAYERS+1], ClientHealthPerkCT[MAXPLAYERS+1], ClientSpeedPerkCT[MAXPLAYERS+1], ClientGetHonorPerk[MAXPLAYERS+1], ClientGangSizePerk[MAXPLAYERS+1];

// ClientAccessManage basically means if the client can either invite, kick, upgrade, promote or MOTD.
new ClientAccessManage[MAXPLAYERS+1], ClientAccessInvite[MAXPLAYERS+1], ClientAccessKick[MAXPLAYERS+1], ClientAccessPromote[MAXPLAYERS+1], ClientAccessUpgrade[MAXPLAYERS+1], ClientAccessMOTD[MAXPLAYERS+1];

// Extra Variables.
new bool:GangAttemptLeave[MAXPLAYERS+1], bool:GangAttemptDisband[MAXPLAYERS+1], bool:GangAttemptStepDown[MAXPLAYERS+1], GangStepDownTarget[MAXPLAYERS+1], bool:MotdShown[MAXPLAYERS+1], ClientGangHonor[MAXPLAYERS+1], CanGetHonor[MAXPLAYERS+1], ClientActionEdit[MAXPLAYERS+1];
new String:GangCreateName[MAXPLAYERS+1][32], String:GangCreateTag[MAXPLAYERS+1][10];
new ClientMembersCount[MAXPLAYERS+1];
new ClientGlow[MAXPLAYERS+1], bool:CachedSpawn[MAXPLAYERS+1];

new Handle:DHook_PlayerMaxSpeed = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "JB Gangs",
    author = "Eyal282 ( FuckTheSchool )",
    description = "Gang System for JailBreak",
    version = "1.0",
    url = "NULL"
};

public OnPluginStart()
{	
			
	Format(NET_WORTH_ORDER_BY_FORMULA, sizeof(NET_WORTH_ORDER_BY_FORMULA), "%i + GangHonor + GangHealthPerkT*0.5*%i*(GangHealthPerkT+1) + GangHealthPerkCT*0.5*%i*(GangHealthPerkCT+1) + GangSpeedPerkT*0.5*%i*(GangSpeedPerkT+1) + GangSpeedPerkCT*0.5*%i*(GangSpeedPerkCT+1) + GangNadePerkT*0.5*%i*(GangNadePerkT+1) + GangGetHonorPerk*0.5*%i*(GangGetHonorPerk+1) + GangSizePerk*0.5*%i*(GangSizePerk+1)", GANG_COSTCREATE, GANG_HEALTHCOST, GANG_HEALTHCOST, GANG_SPEEDCOST, GANG_SPEEDCOST, GANG_NADECOST, GANG_GETCREDITSCOST, GANG_SIZECOST);
		
	dbFullConnected = false;
	
	dbGangs = INVALID_HANDLE;
	
	ConnectDatabase();
	
	AddCommandListener(CommandListener_Say, "say");
	AddCommandListener(CommandListener_Say, "say_team");

	RegConsoleCmd("sm_donategang", Command_DonateGang);
	RegConsoleCmd("sm_motdgang", Command_MotdGang);
	RegConsoleCmd("sm_creategang", Command_CreateGang);
	RegConsoleCmd("sm_gangtag", Command_CreateGangTag);
	RegConsoleCmd("sm_confirmleavegang", Command_LeaveGang);
	RegConsoleCmd("sm_confirmdisbandgang", Command_DisbandGang);
	RegConsoleCmd("sm_confirmstepdowngang", Command_StepDown);
	RegConsoleCmd("sm_gang", Command_Gang);
	RegConsoleCmd("sm_gethonor", Command_GC);
	RegConsoleCmd("sm_gc", Command_GC);
	
	RegAdminCmd("sm_breachgang", Command_BreachGang, ADMFLAG_ROOT, "Breaches into a gang as a member.");
	RegAdminCmd("sm_breachgangrank", Command_BreachGangRank, ADMFLAG_ROOT, "Sets your rank within your gang.");
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	new const String:HonorPerKillCvarName[] = "gang_system_honor_per_kill";
	
	hcv_HonorPerKill = CreateConVar(HonorPerKillCvarName, "100", "Amount of honor you get per kill as T");
	
	ServerCommand("sm_cvar protect %s", HonorPerKillCvarName);
	
	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	HandleGameData();
}

public OnLibraryAdded(const String:name[])
{
	#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public OnPluginEnd()
{
	for(new i=1;i < MAXPLAYERS+1;i++)
	{
		TryDestroyGlow(i);
	}
}

HandleGameData()
{	
	new String:FileName[300], Handle:hGameConf;

	BuildPath(Path_SM, FileName, sizeof(FileName), "gamedata/%s.txt", const_GameDataFile);
	if( !FileExists(FileName) )
	{
		if(!Updater_ForceUpdate())
			SetFailState("Could not find offset PlayerMaxSpeedOffset.");
			
		return;
	}
	
	
	hGameConf = LoadGameConfigFile(const_GameDataFile);
	
	new PlayerMaxSpeedOffset = GameConfGetOffset(hGameConf, "PlayerMaxSpeedOffset");
	
	DHook_PlayerMaxSpeed = DHookCreate(PlayerMaxSpeedOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, CCSPlayer_GetPlayerMaxSpeed);
	
	if(DHook_PlayerMaxSpeed == INVALID_HANDLE)
	{
		if(!Updater_ForceUpdate())
			SetFailState("Could not DHook PlayerMaxSpeed");
			
		return;
	}	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		DHookEntity(DHook_PlayerMaxSpeed, true, i);
		
		LoadClientGang(i);
	}
}

public MRESReturn:CCSPlayer_GetPlayerMaxSpeed(client, Handle:hReturn, Handle:hParams)
{	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return MRES_Ignored;
	
	else if(GetAliveTeamCount(CS_TEAM_T) <= 1)
		return MRES_Ignored;
	
	new Float:Maxspeed = DHookGetReturn(hReturn);
	
	if(Maxspeed < 1.0)
		return MRES_Ignored;
	
	switch(GetClientTeam(client))
	{
		case CS_TEAM_T: Maxspeed += (ClientSpeedPerkT[client] * GANG_SPEEDINCREASE);
		case CS_TEAM_CT: Maxspeed += (ClientSpeedPerkCT[client] * GANG_SPEEDINCREASE);
	}

	DHookSetReturn(hReturn, Maxspeed);
	return MRES_Supercede;
}

public Updater_OnPluginUpdated()
{
	new String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));

	ServerCommand("changelevel %s", MapName);
}

public LastRequest_OnLRStarted(Prisoner, Guard)
{
///	SDKUnhook(Prisoner, SDKHook_PostThink, Event_PreThinkT);
//	SDKUnhook(Prisoner, SDKHook_PostThink, Event_PreThinkCT);
	//SDKUnhook(Guard, SDKHook_PreThink, Event_PreThinkT);
	//SDKUnhook(Guard, SDKHook_PreThink, Event_PreThinkCT);
}

public Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
	CachedSpawn[client] = false;
	RequestFrame(Event_PlayerSpawnPlusFrame, GetEventInt(hEvent, "userid"));
}
public Event_PlayerSpawnPlusFrame(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(CachedSpawn[client])
		return;
		
	else if(!IsValidPlayer(client))
		return;
		
	else if(!IsPlayerAlive(client))
		return;
	
	else if(!IsClientGang(client))
		return;
	
	CachedSpawn[client] = true;
	
	TryDestroyGlow(client);
	
	switch(GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			if(ClientHealthPerkT[client] > 0)	
			{
				SetEntityHealth(client, GetEntityHealth(client) + (ClientHealthPerkT[client] * GANG_HEALTHINCREASE));
				SetEntityMaxHealth(client, GetEntityMaxHealth(client) + (ClientHealthPerkT[client] * GANG_HEALTHINCREASE));
			}
			
			if(ClientNadePerkT[client] > 0)
			{
				if(GetRandomFloat(0.0, 100.0) <= (float(ClientNadePerkT[client]) * GANG_NADEINCREASE))
				{
					switch(GetRandomInt(0, 3))
					{
						case 0: GivePlayerItem(client, "weapon_incgrenade");
						case 1: GivePlayerItem(client, "weapon_flashbang");
						case 2: GivePlayerItem(client, "weapon_hegrenade");
						case 3: GivePlayerItem(client, "weapon_decoy");
					}
					
					PrintToChat(client, "You spawned with a random nade for being in a gang!");
				}
			}
			
			CreateGlow(client);
		}
		case CS_TEAM_CT:
		{
			if(ClientHealthPerkCT[client] > 0)	
			{
				SetEntityHealth(client, GetEntityHealth(client) + (ClientHealthPerkCT[client] * GANG_HEALTHINCREASE));
				SetEntityMaxHealth(client, GetEntityMaxHealth(client) + (ClientHealthPerkCT[client] * GANG_HEALTHINCREASE));
			}
		}
	}
}

CreateGlow(client)
{
	if(ClientGlow[client] != 0)
	{
		TryDestroyGlow(client);
		ClientGlow[client] = 0;
	}	
	new String:Model[PLATFORM_MAX_PATH];
	new Float:Origin[3], Float:Angles[3];

	// Get the original model path
	GetEntPropString(client, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	// Find the location of the weapon
	GetClientEyePosition(client, Origin);
	Origin[2] -= 75.0;
	GetClientEyeAngles(client, Angles);
	new GlowEnt = CreateEntityByName("prop_dynamic_glow");
	
	DispatchKeyValue(GlowEnt, "model", Model);
	DispatchKeyValue(GlowEnt, "disablereceiveshadows", "1");
	DispatchKeyValue(GlowEnt, "disableshadows", "1");
	DispatchKeyValue(GlowEnt, "solid", "0");
	DispatchKeyValue(GlowEnt, "spawnflags", "256");
	DispatchKeyValue(GlowEnt, "renderamt", "0");
	SetEntProp(GlowEnt, Prop_Send, "m_CollisionGroup", 11);
		
	// Spawn and teleport the entity
	DispatchSpawn(GlowEnt);
	
	new fEffects = GetEntProp(GlowEnt, Prop_Send, "m_fEffects");
	SetEntProp(GlowEnt, Prop_Send, "m_fEffects", fEffects|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);

	// Give glowing effect to the entity
	SetEntProp(GlowEnt, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(GlowEnt, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(GlowEnt, Prop_Send, "m_flGlowMaxDist", 10000.0);

	// Set glowing color
	SetVariantColor({255, 255, 255, 255});
	AcceptEntityInput(GlowEnt, "SetGlowColor");

	// Set the activator and group the entity
	SetVariantString("!activator");
	AcceptEntityInput(GlowEnt, "SetParent", client);
	
	SetVariantString("primary");
	AcceptEntityInput(GlowEnt, "SetParentAttachment", GlowEnt, GlowEnt, 0);
	
	AcceptEntityInput(GlowEnt, "TurnOn");
	
	SetEntPropEnt(GlowEnt, Prop_Send, "m_hOwnerEntity", client);
	
	new String:iName[32];

	FormatEx(iName, sizeof(iName), "Gang-Glow %i", GetClientUserId(client));
	SetEntPropString(GlowEnt, Prop_Data, "m_iName", iName);
	
	SDKHook(GlowEnt, SDKHook_SetTransmit, Hook_ShouldSeeGlow);
	ClientGlow[client] = GlowEnt;

}


public Action:Hook_ShouldSeeGlow(glow, viewer)
{
	if(!IsValidEntity(glow))
		return Plugin_Continue;
		
	new client = GetEntPropEnt(glow, Prop_Send, "m_hOwnerEntity");
	
	if(client == viewer)
		return Plugin_Handled;
		
	else if(!AreClientsSameGang(client, viewer))
		return Plugin_Handled;
		
	else if(GetClientTeam(viewer) != GetClientTeam(client))
		return Plugin_Handled;
	
	new ObserverTarget = GetEntPropEnt(viewer, Prop_Send, "m_hObserverTarget"); // This is the player the viewer is spectating. No need to check if it's invalid ( -1 )
	
	if(ObserverTarget == client)
		return Plugin_Handled;

	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	TryDestroyGlow(victim);
	
	new ent = -1; // Some bugs don't fix themselves...
	while((ent = FindEntityByClassname(ent, "prop_dynamic_glow")) != -1)
	{
		
		new String:iName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", iName, sizeof(iName));
		
		if(strncmp(iName, "Gang-Glow", 9) != 0)
			continue;
		
		new String:dummy_value[1], String:sUserId[11], pos;
		pos = BreakString(iName, dummy_value, 0);
		
		BreakString(iName[pos], sUserId, sizeof(sUserId));
		
		new i = GetClientOfUserId(StringToInt(sUserId));
		
		if(i == 0 || !IsPlayerAlive(i))
			AcceptEntityInput(i, "Kill");
	}
	
	if(IsPlayer(attacker) && attacker != victim && (GetClientTeam(victim) == CS_TEAM_CT || GetAliveTeamCount(CS_TEAM_T) == 0))
	{
		new honor = GetConVarInt(hcv_HonorPerKill);
		
		new bool:IsVIP = CheckCommandAccess(attacker, "sm_null_command", ADMFLAG_CUSTOM2, true);
		
		if(IsVIP)
			honor *= 2;
			
		PrintToChat(attacker, "%s \x03You gained %i%s honor for your kill.", PREFIX, GetConVarInt(hcv_HonorPerKill), IsVIP ? " x 2" : "");
		
		
		GiveClientHonor(attacker, honor);
	}
}
public Action:Event_RoundEnd(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		CanGetHonor[i] = true;
	}
}
TryDestroyGlow(client)
{
	if(ClientGlow[client] != 0 && IsValidEntity(ClientGlow[client]))
	{
		AcceptEntityInput(ClientGlow[client], "Kill");
		ClientGlow[client] = 0;
	}
}

public OnClientSettingsChanged(client)
{	
	if(IsValidPlayer(client))
		StoreClientLastInfo(client);
}

public ConnectDatabase()
{
	new String:error[256];
	new Handle:hndl = INVALID_HANDLE;
	if((hndl = SQLite_UseDatabase("JB_Gangs", error, sizeof(error))) == INVALID_HANDLE)
		SetFailState(error);

	else
	{
		dbGangs = hndl;
		
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_Members (GangName VARCHAR(32) NOT NULL, AuthId VARCHAR(32) NOT NULL UNIQUE, GangRank INT(20) NOT NULL, GangDonated INT(20) NOT NULL, LastName VARCHAR(32) NOT NULL, GangInviter VARCHAR(32) NOT NULL, GangJoinDate INT(20) NOT NULL, LastConnect INT(20) NOT NULL)", 0, DBPrio_High);
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_Gangs (GangName VARCHAR(32) NOT NULL UNIQUE, GangTag VARCHAR(10) NOT NULL UNIQUE, GangMotd VARCHAR(100) NOT NULL, GangHonor INT(20) NOT NULL, GangHealthPerkT INT(20) NOT NULL, GangSpeedPerkT INT(20) NOT NULL, GangNadePerkT INT(20) NOT NULL, GangHealthPerkCT INT(20) NOT NULL, GangSpeedPerkCT INT(20) NOT NULL, GangGetHonorPerk INT(20) NOT NULL, GangSizePerk INT(20) NOT NULL)", 1, DBPrio_High);
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_Honor (AuthId VARCHAR(32) NOT NULL UNIQUE, Honor INT(11) NOT NULL)", 2, DBPrio_High);
		SQL_TQuery(dbGangs, SQLCB_Error, "CREATE TABLE IF NOT EXISTS GangSystem_upgradelogs (GangName VARCHAR(32) NOT NULL, AuthId VARCHAR(32) NOT NULL, Perk VARCHAR(32) NOT NULL, BValue INT NOT NULL, AValue INT NOT NULL, timestamp INT NOT NULL)", 3, DBPrio_High); 
		
		new String:sQuery[512];
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankInvite INT(11) NOT NULL DEFAULT %i", RANK_OFFICER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);

		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankKick INT(11) NOT NULL DEFAULT %i", RANK_OFFICER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankPromote INT(11) NOT NULL DEFAULT %i", RANK_MANAGER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankUpgrade INT(11) NOT NULL DEFAULT %i", RANK_COLEADER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "ALTER TABLE GangSystem_Gangs ADD COLUMN GangMinRankMOTD INT(11) NOT NULL DEFAULT %i", RANK_MANAGER);
		SQL_TQuery(dbGangs, SQLCB_ErrorIgnore, sQuery, _, DBPrio_High);
		
		dbFullConnected = true;
		
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsValidPlayer(i))
				continue;
		
			else if(!IsClientAuthorized(i))
				continue;
				
			LoadClientGang(i);
		}
	}
}

public SQLCB_Error(Handle:owner, Handle:hndl, const char[] Error, QueryUniqueID) 
{ 
    /* If something fucked up. */ 
	if (hndl == null) 
		SetFailState("%s --> %i", Error, QueryUniqueID); 
} 

public SQLCB_ErrorIgnore(Handle:owner, Handle:hndl, const char[] Error, Data) 
{ 
} 

public OnClientPutInServer(client)
{
	DHookEntity(DHook_PlayerMaxSpeed, true, client);	
	
	ClientGlow[client] = 0;
}

public OnClientConnected(client)
{	
	ResetVariables(client);
	
	CanGetHonor[client] = false;
} 

ResetVariables(client, bool:login=true)
{
	ClientHonor[client] = 0;
	ClientHealthPerkT[client] = 0;
	ClientSpeedPerkT[client] = 0;
	ClientNadePerkT[client] = 0;
	ClientHealthPerkCT[client] = 0;
	ClientSpeedPerkCT[client] = 0;
	
	ClientAccessManage[client] = RANK_LEADER;
	ClientAccessInvite[client] = RANK_LEADER;
	ClientAccessKick[client] = RANK_LEADER;
	ClientAccessPromote[client] = RANK_LEADER;
	ClientAccessUpgrade[client] = RANK_LEADER;
	ClientAccessMOTD[client] = RANK_LEADER;
	
	if(login)
	{
		GangAttemptLeave[client] = false;
		GangAttemptDisband[client] = false;
		GangAttemptStepDown[client] = false;
		GangStepDownTarget[client] = -1;
		ClientGang[client] = GANG_NULL;
		ClientRank[client] = RANK_NULL;
		ClientGangHonor[client] = 0;
	}
	ClientMotd[client] = "";
	ClientTag[client] = "";
	ClientLoadedFromDb[client] = false;
}

public OnClientDisconnect(client)
{
	new String:AuthId[35], String:Name[64];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	Format(Name, sizeof(Name), "%N", client);
	
	StoreAuthIdLastInfo(AuthId, Name); // Safer
	
	TryDestroyGlow(client);
}

public OnClientPostAdminCheck(client)
{
	if(!dbFullConnected)
		return;
		
	MotdShown[client] = false;
		
	CanGetHonor[client] = false;
	
	LoadClientGang(client);
}

LoadClientGang(client, LowPrio=false)
{
	new String:AuthId[35]
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE AuthId = '%s'", AuthId);
	
	if(!LowPrio)
		SQL_TQuery(dbGangs, SQLCB_LoadClientGang, sQuery, GetClientUserId(client));
	
	else
		SQL_TQuery(dbGangs, SQLCB_LoadClientGang, sQuery, GetClientUserId(client), DBPrio_Low);
		
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Honor WHERE AuthId = '%s'", AuthId);
	
	if(!LowPrio)
		SQL_TQuery(dbGangs, SQLCB_LoadClientHonor, sQuery, GetClientUserId(client));
	
	else
		SQL_TQuery(dbGangs, SQLCB_LoadClientHonor, sQuery, GetClientUserId(client), DBPrio_Low);
}	

public SQLCB_LoadClientGang(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if(hndl == null)
	{
		SetFailState(error);
	}

	new client = GetClientOfUserId(data);
	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		StoreClientLastInfo(client);
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			ClientRank[client] = SQL_FetchInt(hndl, 2);
			
			new String:sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE GangName = '%s'", ClientGang[client]);
			SQL_TQuery(dbGangs, SQLCB_LoadGangByClient, sQuery, GetClientUserId(client), DBPrio_High);
		}
		else
		{
			ClientLoadedFromDb[client] = true;
		}
	}
}

public SQLCB_LoadGangByClient(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if(hndl == null)
	{
		SetFailState(error);
	}

	new client = GetClientOfUserId(data);
	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			SQL_FetchString(hndl, 1, ClientTag[client], sizeof(ClientTag[]));
			SQL_FetchString(hndl, 2, ClientMotd[client], sizeof(ClientMotd[]));
			ClientGangHonor[client] = SQL_FetchInt(hndl, 3);
			ClientHealthPerkT[client] = SQL_FetchInt(hndl, 4);
			ClientSpeedPerkT[client] = SQL_FetchInt(hndl, 5);
			ClientNadePerkT[client] = SQL_FetchInt(hndl, 6);
			ClientHealthPerkCT[client] = SQL_FetchInt(hndl, 7);
			ClientSpeedPerkCT[client] = SQL_FetchInt(hndl, 8);
			ClientGetHonorPerk[client] = SQL_FetchInt(hndl, 9);
			ClientGangSizePerk[client] = SQL_FetchInt(hndl, 10);
			ClientAccessInvite[client] = SQL_FetchInt(hndl, 11);
			ClientAccessKick[client] = SQL_FetchInt(hndl, 12);
			ClientAccessPromote[client] = SQL_FetchInt(hndl, 13);
			ClientAccessUpgrade[client] = SQL_FetchInt(hndl, 14);
			ClientAccessMOTD[client] = SQL_FetchInt(hndl, 15);
			
			new Smallest = ClientAccessInvite[client];
			
			if(ClientAccessKick[client] < Smallest)
				Smallest = ClientAccessKick[client];
				
			if(ClientAccessPromote[client] < Smallest)
				Smallest = ClientAccessPromote[client];
				
			if(ClientAccessUpgrade[client] < Smallest)
				Smallest = ClientAccessUpgrade[client];
				
			if(ClientAccessMOTD[client] < Smallest)
				Smallest = ClientAccessMOTD[client];
				
			ClientAccessManage[client] = Smallest;
			
			if(ClientMotd[client][0] != EOS && !MotdShown[client])
			{
				PrintToChat(client, " \x07=======GANG MOTD=========");
				PrintToChat(client, " %s", ClientGang[client]);
				PrintToChat(client, " %s", ClientMotd[client]);
				PrintToChat(client, " \x07=======GANG MOTD=========");
				MotdShown[client] = true;
			}	
			
			if(IsPlayerAlive(client))
				CreateGlow(client);
				
			new String:sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s'", ClientGang[client]);
			
			SQL_TQuery(dbGangs, SQLCB_CheckMemberCount, sQuery, GetClientUserId(client));
		}
		else // Gang was deleted
		{
			new String:AuthId[35];
			GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
			
			KickAuthIdFromGang(AuthId, ClientGang[client]);
			ClientLoadedFromDb[client] = true;
		}
	}
}


public SQLCB_LoadClientHonor(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if(hndl == null)
		SetFailState(error);

	new client = GetClientOfUserId(data);
	
	if(client == 0)
		return;

	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			ClientHonor[client] = SQL_FetchInt(hndl, 1);
		}
		else
		{
			new String:AuthId[35];
			GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
			
			// The reason I use INSERT OR IGNORE rather than just INSERT is bots, that can have multiple steam IDs.
			new String:sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO GangSystem_Honor (AuthId, Honor) VALUES ('%s', 0)", AuthId);
			
			SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 4);
			ClientHonor[client] = 0;
		}
	}
}

stock KickClientFromGang(client, const String:GangName[])
{
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	KickAuthIdFromGang(AuthId, GangName);
}

stock KickAuthIdFromGang(const String:AuthId[], const String:GangName[])
{
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "DELETE FROM GangSystem_Members WHERE AuthId = '%s' AND GangName = '%s'", AuthId, GangName);
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 5);
	
	UpdateInGameAuthId(AuthId);
}

public Action:CommandListener_Say(client, const String:command[], args) 
{
	if(!IsValidPlayer(client))
		return Plugin_Continue;	
	
	new String:Args[256];
	GetCmdArgString(Args, sizeof(Args))
	StripQuotes(Args);
	
	if(Args[0] == '#')
	{
		ReplaceStringEx(Args, sizeof(Args), "#", "");
		
		if(Args[0] == EOS)
		{	
			PrintToChat(client, "Gang message cannot be empty.");
			return Plugin_Handled;
		}
		new String:RankName[32];
		GetRankName(GetClientRank(client), RankName, sizeof(RankName));
		
		PrintToChatGang(ClientGang[client], "\x04[Gang Chat] \x05%s\x03 %N\x01 : %s", RankName, client, Args);
		
		return Plugin_Handled;
	}
	
	RequestFrame(ListenerSayPlusFrame, GetClientUserId(client));
	return Plugin_Continue;
}

public ListenerSayPlusFrame(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(IsClientGang(client))
	{
		if(GangAttemptDisband[client] || GangAttemptLeave[client] || GangAttemptStepDown[client])
			PrintToChat(client, "%s \x05The operation has been aborted!", PREFIX);
			
		GangAttemptDisband[client] = false;
		GangAttemptLeave[client] = false;
		GangAttemptStepDown[client] = false;
		GangStepDownTarget[client] = -1;
	}
}


public Action:Command_MotdGang(client, args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to be in a gang to use this command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!CheckGangAccess(client, ClientAccessMOTD[client]))
	{
		new String:RankName[32];
		GetRankName(ClientAccessMOTD[client], RankName, sizeof(RankName));
		PrintToChat(client, "%s \x07You have to be a gang %s to use this command!", PREFIX, RankName);
		return Plugin_Handled;	
	}
	
	new String:Args[100];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	if(StringHasInvalidCharacters(Args))
	{
		PrintToChat(client, "%s \x07Invalid motd! You can only use \x03SPACEBAR\x07, \x03a-z\x07, \x03A-Z\x07, \x03_\x07, \x03-\x07, \x030-9\x07!", PREFIX);
		return Plugin_Handled;
	}
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangMotd = '%s' WHERE GangName = '%s'", Args, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 6);
	
	PrintToChat(client, "%s \x05The gang's motd has been changed to \x03%s\x05!", PREFIX, Args);
	
	return Plugin_Handled;
}
public Action:Command_DonateGang(client, args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to be in a gang to use this command!", PREFIX);
		return Plugin_Handled;
	}
	new String:Args[20];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	new amount = StringToInt(Args);
	
	if(StrEqual(Args, "all", false))
	{
		amount = ClientHonor[client];
		
		amount -= amount % 50;
		IntToString(amount, Args, sizeof(Args));
	}	
	if(!IsStringNumber(Args) || Args[0] == EOS)
	{
		PrintToChat(client, "%s \x07Invalid Usage! \x09!donategang <amount>", PREFIX);
		return Plugin_Handled;
	}
	else if(amount < 50 || (amount % 50) != 0)
	{
		PrintToChat(client, "%s \x07You must donate at least 50 honor and in multiples of 50!", PREFIX);
		return Plugin_Handled;
	}
	else if(amount > ClientHonor[client])
	{
		PrintToChat(client, "%s \x07You cannot donate more honor than you have.", PREFIX);
		return Plugin_Handled;
	}
	new Handle:hMenu = CreateMenu(DonateGang_MenuHandler);
	
	AddMenuItem(hMenu, Args, "Yes");
	AddMenuItem(hMenu, "", "No");
	
	SetMenuTitle(hMenu, "%s Gang Donation\n\nAre you sure you want to donate %i honor?", MENU_PREFIX, amount);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public DonateGang_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
		if(!IsClientGang(client))
			return;
		
		if(item + 1 == 1)
		{
			new String:strAmount[20], amount, String:strIgnoreable[1];
			GetMenuItem(hMenu, item, strAmount, sizeof(strAmount), amount, strIgnoreable, 0)
			
			amount = StringToInt(strAmount);
			DonateToGang(client, amount);
		}
	}
}

public Action:Command_CreateGang(client, args)
{
	if(!ClientLoadedFromDb[client])
	{
		PrintToChat(client, "%s \x07You weren't loaded from the database yet!", PREFIX);
		return Plugin_Handled;
	}
	else if(IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to leave your current gang to create a new one!", PREFIX);
		return Plugin_Handled;
	}
	
	new String:Args[32];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	if(Args[0] == EOS)
	{
		PrintToChat(client, "%s \x07Invalid Usage! \x09!creategang <name>", PREFIX);
		return Plugin_Handled;		
	}	
	else if(StringHasInvalidCharacters(Args))
	{
		PrintToChat(client, "%s \x07Invalid name! You can only use \x03a-z\x07, \x03A-Z\x07, \x03_\x07, \x03-\x07, \x030-9\x07!", PREFIX);
		return Plugin_Handled;
	}
	
	GangCreateName[client] = Args;
	if(GangCreateTag[client][0] == EOS)
	{
		PrintToChat(client, "%s \x05Name selected! Please select your gang tag using \x03!gangtag\x05.", PREFIX);
		return Plugin_Handled;
	}	
	new Handle:hMenu = CreateMenu(CreateGang_MenuHandler);
	
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");
	
	SetMenuExitButton(hMenu, false);
	
	SetMenuTitle(hMenu, "%s Create Gang\nGang Name: %s\nGang Tag: %s\nCost: %i", MENU_PREFIX, GangCreateName[client], GangCreateTag[client], GANG_COSTCREATE);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:Command_CreateGangTag(client, args)
{
	if(IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to leave your current gang to create a new one!", PREFIX);
		return Plugin_Handled;
	}
	
	new String:Args[10];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	if(strlen(Args) != 4)
	{
		PrintToChat(client, "%s \x07The gang tag has to be 4 characters long!", PREFIX);
		return Plugin_Handled;
	}
	GangCreateTag[client] = Args;
	if(GangCreateName[client][0] == EOS)
	{
		PrintToChat(client, "%s \x05Tag selected! Please select your gang name using \x03!creategang\x05.", PREFIX);
		return Plugin_Handled;
	}	
		
	else if(StringHasInvalidCharacters(Args))
	{
		PrintToChat(client, "%s \x07Invalid tag! You can only use \x03a-z\x07, \x03A-Z\x07, \x03_\x07, \x03-\x07, \x030-9\x07!", PREFIX);
		return Plugin_Handled;
	}
	new Handle:hMenu = CreateMenu(CreateGang_MenuHandler);
	
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");
	
	SetMenuExitButton(hMenu, false);
	
	SetMenuTitle(hMenu, "%s Create Gang\nGang Name: %s\nGang Tag: %s\nCost: %i",MENU_PREFIX, GangCreateName[client], GangCreateTag[client], GANG_COSTCREATE);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}
public Action:Command_LeaveGang(client, args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to be in a gang to use this command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!GangAttemptLeave[client])
	{
		PrintToChat(client, "%s \x07You have not made an attempt to leave your gang with \x03!gang\x07.", PREFIX);
		return Plugin_Handled;
	}
	
	PrintToChatGang(ClientGang[client], "%s \x03%N \x09has left the gang!", PREFIX, client);
	KickClientFromGang(client, ClientGang[client]);
	
	GangAttemptLeave[client] = false;
	
	return Plugin_Handled;
}

public Action:Command_DisbandGang(client, args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to be in a gang to use this command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!CheckGangAccess(client, RANK_LEADER))
	{
		PrintToChat(client, "%s \x07You have to be the gang's leader to use this command!", PREFIX);
		return Plugin_Handled;
	}	
	else if(!GangAttemptDisband[client])
	{
		PrintToChat(client, "%s \x07You have not made an attempt to disband your gang with \x03!gang\x07.", PREFIX);
		return Plugin_Handled;
	}
	
	PrintToChatAll("%s \x03%N \x07has disbanded the gang \x03%s\x07!", PREFIX, client, ClientGang[client]);
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "DELETE FROM GangSystem_Gangs WHERE GangName = '%s'", ClientGang[client]);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_GangDisbanded, sQuery, DP);
	
	GangAttemptDisband[client] = false;
	return Plugin_Handled;
}

public Action:Command_StepDown(client, args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to be in a gang to use this command!", PREFIX);
		return Plugin_Handled;
	}
	else if(!CheckGangAccess(client, RANK_LEADER))
	{
		PrintToChat(client, "%s \x07You have to be the gang's leader to use this command!", PREFIX);
		return Plugin_Handled;
	}	
	else if(!GangAttemptStepDown[client])
	{
		PrintToChat(client, "%s \x07You have not made an attempt to step down from your rank with \x03!gang\x07.", PREFIX);
		return Plugin_Handled;
	}
	
	new NewLeader = GetClientOfUserId(GangStepDownTarget[client]);
	
	if(NewLeader == 0)
	{
		PrintToChat(client, "%s \x07The selected target has disconnected.", PREFIX);
		return Plugin_Handled;
	}
	
	else if(!AreClientsSameGang(client, NewLeader))
	{
		PrintToChat(client, "%s \x07The selected target has left the gang.", PREFIX);
		return Plugin_Handled;
	}
	
	PrintToChatGang(ClientGang[client], "%s \x03%N \x09has stepped down to \x03Co-Leader\x09.", PREFIX, client);
	PrintToChatGang(ClientGang[client], "%s \x03%N \x09is now the gang \x03Leader\x09.", PREFIX, NewLeader);
	
	new String:AuthId[35], String:AuthIdNewLeader[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientAuthId(NewLeader, AuthId_Engine, AuthIdNewLeader, sizeof(AuthIdNewLeader));
	
	SetAuthIdRank(AuthId, ClientGang[client], RANK_COLEADER);
	SetAuthIdRank(AuthIdNewLeader, ClientGang[NewLeader], RANK_LEADER);
	
	GangAttemptStepDown[client] = false;
	GangStepDownTarget[client] = -1;
	return Plugin_Handled;
}

public SQLCB_GangDisbanded(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	new String:GangName[32];
	ResetPack(DP);
	
	ReadPackString(DP, GangName, sizeof(GangName));
	
	CloseHandle(DP);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		else if(!StrEqual(GangName, ClientGang[i], false))
			continue;
			
		LoadClientGang(i);
	}
}
public CreateGang_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
	
		if(IsClientGang(client))
			return;
			
		if(item + 1 == 1)
		{
			if(GangCreateName[client][0] == EOS || GangCreateTag[client][0] == EOS || StringHasInvalidCharacters(GangCreateName[client]) || StringHasInvalidCharacters(GangCreateTag[client]))
				return;

			TryCreateGang(client, GangCreateName[client], GangCreateTag[client]);
		}
		else
		{
			GangCreateName[client] = GANG_NULL;
			GangCreateTag[client] = GANG_NULL;
		}	
	}
}
public Action:Command_GC(client, args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "%s \x07You have to be in a gang to use this command!", PREFIX);
		return Plugin_Handled;
	}
	else if(ClientGetHonorPerk[client] <= 0)
	{
		PrintToChat(client, "%s \x07Your gang does not have that perk.", PREFIX);
		return Plugin_Handled;
	}
	else if(!CanGetHonor[client])
	{
		PrintToChat(client, "%s \x07You have already received honor this round!", PREFIX);
		return Plugin_Handled;	
	}
	else if(GetPlayerCount() < 3)
	{
		PrintToChat(client, "%s \x07You can only use !gc from 3 players and above.", PREFIX);
		return Plugin_Handled;		
	}
	
	int received = ClientGetHonorPerk[client] * GANG_GETCREDITSINCREASE;
	GiveClientHonor(client, received);
	PrintToChat(client, "%s \x05You have received \x03%i \x05honor with \x03!gc\x05.", PREFIX, received);
	CanGetHonor[client] = false;
	
	return Plugin_Handled;
}

public Action:Command_BreachGang(client, args)
{
	if(IsClientGang(client))
	{
		PrintToChat(client, "You must not be in a gang to move yourself into another gang.");
		return Plugin_Handled;
	}
	
	if(args == 0)
	{
		PrintToChat(client, "Usage: sm_breachgang <gang name>");
		return Plugin_Handled;
	}
	
	new String:GangName[32];
	GetCmdArgString(GangName, sizeof(GangName));
	StripQuotes(GangName);
	
	new String:AuthId[35], Handle:DP = CreateDataPack();
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	WritePackString(DP, AuthId);
	
	FinishAddAuthIdToGang(GangName, AuthId, RANK_MEMBER, AuthId, DP);
	
	return Plugin_Handled;
}

public Action:Command_BreachGangRank(client, args)
{
	if(!IsClientGang(client))
	{
		PrintToChat(client, "You must be in a gang to set your gang rank.");
		return Plugin_Handled;
	}
	
	if(args == 0)
	{
		PrintToChat(client, "Usage: sm_breachgangrank <rank {0~%i}>", RANK_COLEADER+1);
		return Plugin_Handled;
	}
	
	new String:RankToSet[11];
	GetCmdArg(1, RankToSet, sizeof(RankToSet));
	
	new Rank = StringToInt(RankToSet);
	
	if(Rank > RANK_COLEADER)
		Rank = RANK_LEADER;
		
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	SetAuthIdRank(AuthId, ClientGang[client], Rank);
	
	return Plugin_Handled;
}
public Action:Command_Gang(client, args)
{
	GangAttemptLeave[client] = false;
	GangAttemptDisband[client] = false;

	new Handle:hMenu = CreateMenu(Gang_MenuHandler);
		
	new bool:isGang = IsClientGang(client);
	
	new bool:isLeader = (IsClientGang(client) && CheckGangAccess(client, RANK_LEADER));
	new bool:isOfficer = (IsClientGang(client) && CheckGangAccess(client, RANK_OFFICER));
	
	new String:TempFormat[100];
	Format(TempFormat, sizeof(TempFormat), "Create Gang [ %i Honor ]", GANG_COSTCREATE);
	AddMenuItem(hMenu, "", TempFormat, !isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Donate To Gang", isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "", "Member List", isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "", "Gang Perks", isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Manage Gang", isOfficer ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "", "Leave Gang", !isLeader && isGang ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Top Gangs");
	
	SetMenuTitle(hMenu, "%s Gang Menu\nCurrent Gang: %s\nYour Honor: %i\nYour Gang's Honor: %i", MENU_PREFIX, isGang ? ClientGang[client] : "None", ClientHonor[client], isGang ? ClientGangHonor[client] : 0);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	LoadClientGang(client, true);
	return Plugin_Handled;
}


public Gang_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
		GangAttemptLeave[client] = false;
		GangAttemptDisband[client] = false;
		
		switch(item + 1)
		{
			case 1: 
			{
				PrintToChat(client, "%s \x05Use \x03!creategang <name> \x05to create a gang.", PREFIX);
			}
			
			case 2:
			{
				PrintToChat(client, "%s \x05Use \x03!donategang <amount> \x05to donate to your gang.", PREFIX);
			}
			
			case 3:
			{
				if(IsClientGang(client))
					ShowMembersMenu(client);
			}
			case 4:
			{
				if(IsClientGang(client))
					ShowGangPerks(client)
			}
			case 5:
			{
				if(IsClientGang(client) && CheckGangAccess(client, ClientAccessManage[client]))
					ShowManageGangMenu(client);
			}
			case 6:
			{
				if(GetClientRank(client) == RANK_LEADER || !IsClientGang(client))
					return;

				GangAttemptLeave[client] = true;
				PrintToChat(client, "%s \x07Write \x03!confirmleavegang \x07if you are absolutely sure you want to leave the gang.", PREFIX);
				PrintToChat(client, "%s \x05Write \x03anything else \x05in the chat to abort.", PREFIX);
			}
			case 7:
			{
				ShowTopGangsMenu(client);
			}
		}	
	}
}

ShowTopGangsMenu(client)
{
	new String:sQuery[1024];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT GangName, (%!s) as net_worth FROM GangSystem_Gangs ORDER BY net_worth DESC", NET_WORTH_ORDER_BY_FORMULA);
	SQL_TQuery(dbGangs, SQLCB_ShowTopGangsMenu, sQuery, GetClientUserId(client));
}


public SQLCB_ShowTopGangsMenu(Handle:owner, Handle:hndl, String:error[], UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
		
	else if(SQL_GetRowCount(hndl) == 0)
		return;
	
	new Handle:hMenu = CreateMenu(Dummy_MenuHandler);
	
	new Rank = 1;
	while(SQL_FetchRow(hndl))
	{
		new String:GangName[32];
		SQL_FetchString(hndl, 0, GangName, sizeof(GangName));
	
		new NetWorth = SQL_FetchInt(hndl, 1);
		new String:TempFormat[256];
		FormatEx(TempFormat, sizeof(TempFormat), "%s [Net worth: %i]", GangName, NetWorth);
		
		if(StrEqual(ClientGang[client], GangName))
			PrintToChat(client, "Your gang %s is ranked [%i]. Net Worth: %i honor", GangName, Rank, NetWorth); // BAR COLOR
			
		AddMenuItem(hMenu, "", TempFormat);
		
		Rank++;
	}
	
	SetMenuTitle(hMenu, "Top Gangs:");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Dummy_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
}

ShowGangPerks(client)
{
	new Handle:hMenu = CreateMenu(Perks_MenuHandler);
	
	new String:TempFormat[150];
	
	Format(TempFormat, sizeof(TempFormat), "Health ( T ) [ %i / %i ] Bonus: +%i [ %i per level ]", ClientHealthPerkT[client], GANG_HEALTHMAX, ClientHealthPerkT[client] * GANG_HEALTHINCREASE, GANG_HEALTHINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Speed ( T ) [ %i / %i ] Bonus: +%.1f [ %.1f per level ]", ClientSpeedPerkT[client], GANG_SPEEDMAX, ClientSpeedPerkT[client] * GANG_SPEEDINCREASE, GANG_SPEEDINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Nade Chance ( T ) [ %i / %i ] Bonus: %.3f%% [ %.3f per level ]", ClientNadePerkT[client], GANG_NADEMAX, ClientNadePerkT[client] * GANG_NADEINCREASE, GANG_NADEINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);

	Format(TempFormat, sizeof(TempFormat), "Health ( CT ) [ %i / %i ] Bonus: +%i [ %i per level ]", ClientHealthPerkCT[client], GANG_HEALTHMAX, ClientHealthPerkCT[client] * GANG_HEALTHINCREASE, GANG_HEALTHINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);

	Format(TempFormat, sizeof(TempFormat), "Speed ( CT ) [ %i / %i ] Bonus: +%.1f [ %.1f per level ]", ClientSpeedPerkCT[client], GANG_SPEEDMAX, ClientSpeedPerkCT[client] * GANG_SPEEDINCREASE, GANG_SPEEDINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Get Honor [ %i / %i ] Bonus: %i [ %i per level ]", ClientGetHonorPerk[client], GANG_GETCREDITSMAX, ClientGetHonorPerk[client] * GANG_GETCREDITSINCREASE, GANG_GETCREDITSINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	Format(TempFormat, sizeof(TempFormat), "Gang Size [ %i / %i ] Bonus: %i [ %i per level ]", ClientGangSizePerk[client], GANG_SIZEMAX, ClientGangSizePerk[client] * GANG_SIZEINCREASE, GANG_SIZEINCREASE);
	AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
	
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Perks_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Command_Gang(client, 0);
}


ShowManageGangMenu(client)
{
	new Handle:hMenu = CreateMenu(ManageGang_MenuHandler);
	
	AddMenuItem(hMenu, "", "Invite To Gang", CheckGangAccess(client, ClientAccessInvite[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Kick From Gang", CheckGangAccess(client, ClientAccessKick[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Promote Member", CheckGangAccess(client, ClientAccessPromote[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Upgrade Perks",CheckGangAccess(client, ClientAccessUpgrade[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Set Gang MOTD", CheckGangAccess(client, ClientAccessMOTD[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Disband Gang", CheckGangAccess(client, RANK_LEADER) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	AddMenuItem(hMenu, "", "Manage Actions Access", CheckGangAccess(client, RANK_LEADER) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	SetMenuTitle(hMenu, "%s Manage Gang", MENU_PREFIX);
	
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public ManageGang_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Command_Gang(client, 0);
		
	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, ClientAccessManage[client]))
		{
			Command_Gang(client, 0);
			return;
		}	
		switch(item + 1)
		{
			case 1:
			{
				if(!ClientAccessInvite[client])
					return;
					
				else if(ClientMembersCount[client] >= (GANG_INITSIZE + (ClientGangSizePerk[client] * GANG_SIZEINCREASE)))
				{
					PrintToChat(client, "%s \x03The gang is full!", PREFIX);
					return;
				}
				ShowInviteMenu(client);
			}
			
			case 2:
			{
				if(!ClientAccessKick[client])
					return;
					
				ShowKickMenu(client);
			}
			case 3:
			{
				if(!ClientAccessPromote[client])
					return;
					
				ShowPromoteMenu(client);
			}
			case 4:
			{
				if(!ClientAccessUpgrade[client])
					return;
					
				ShowUpgradeMenu(client);
			}
			case 5:
			{
				if(!ClientAccessMOTD[client])
					return;
					
				PrintToChat(client, "%s \x05Use \x03!motdgang <new motd> \x05to change the gang's motd.", PREFIX);
			}
			
			case 6:
			{
				if(!CheckGangAccess(client, RANK_LEADER))
					return;
					
				GangAttemptDisband[client] = true;
				PrintToChat(client, "%s \x07Write \x03!confirmdisbandgang \x07to confirm DELETION of the gang.", PREFIX);
				PrintToChat(client, "%s \x05Write \x03anything else \x05in the chat to abort deleting the gang.", PREFIX);
				PrintToChat(client, "%s \x02ATTENTION! THIS ACTION WILL PERMANENTLY DELETE YOUR GANG, IT IS NOT UNDOABLE AND YOU WILL NOT BE REFUNDED!!!", PREFIX);
			}
			
			case 7:
			{
				if(!CheckGangAccess(client, RANK_LEADER))
					return;
					
				ShowActionAccessMenu(client);
			}
		}
	}
}


ShowActionAccessMenu(client)
{
	new Handle:hMenu = CreateMenu(ActionAccess_MenuHandler);
	new String:RankName[32];
	new String:TempFormat[256];
	GetRankName(ClientAccessInvite[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Invite to Gang - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessKick[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Kick from Gang - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessPromote[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Promote Member - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessUpgrade[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Upgrade Perks - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	GetRankName(ClientAccessUpgrade[client], RankName, sizeof(RankName));
	Format(TempFormat, sizeof(TempFormat), "Set Gang MOTD - [%s]", RankName);
	AddMenuItem(hMenu, "", TempFormat);
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public ActionAccess_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, RANK_LEADER))
			return;
			
		ClientActionEdit[client] = item;
		
		ShowActionAccessSetRankMenu(client);
	
	}
}

ShowActionAccessSetRankMenu(client)
{
	new Handle:hMenu = CreateMenu(ActionAccessSetRank_MenuHandler);
	new String:RankName[32];
	
	for(new i=RANK_MEMBER;i <= RANK_COLEADER;i++)
	{
		new TrueRank = i > RANK_COLEADER ? RANK_LEADER : i;
		GetRankName(TrueRank, RankName, sizeof(RankName));
		
		AddMenuItem(hMenu, "", RankName);
	}
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	
	new String:RightName[32];
	
	switch(ClientActionEdit[client])
	{
		case 0: RightName = "Invite";
		case 1: RightName = "Kick";
		case 2: RightName = "Promote";
		case 3: RightName = "Upgrade";
		case 4: RightName = "MOTD";
	}

	SetMenuTitle(hMenu, "Choose which minimum rank will have right to %s", RightName);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public ActionAccessSetRank_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowActionAccessMenu(client);

	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, RANK_LEADER))
			return;
			
		new TrueRank = item > RANK_COLEADER ? RANK_LEADER : item;
		
		new String:ColumnName[32];
		switch(ClientActionEdit[client])
		{
			case 0: ColumnName = "GangMinRankInvite";
			case 1: ColumnName = "GangMinRankKick";
			case 2: ColumnName = "GangMinRankPromote";
			case 3: ColumnName = "GangMinRankUpgrade";
			case 4: ColumnName = "GangMinRankMOTD";
		}
		
		new Handle:DP = CreateDataPack();
		
		WritePackString(DP, ClientGang[client]);
		
		new String:sQuery[256];
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET '%s' = %i WHERE GangName = '%s'", ColumnName, TrueRank, ClientGang[client]);
		SQL_TQuery(dbGangs, SQLCB_UpdateGang, sQuery, DP);
	}
}
ShowUpgradeMenu(client)
{
	new Handle:hMenu = CreateMenu(Upgrade_MenuHandler);

	new String:TempFormat[100], String:strUpgradeCost[20];
	
	new upgradecost = GetUpgradeCost(ClientHealthPerkT[client], GANG_HEALTHCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Health ( T ) [ %i / %i ] Cost: %i", ClientHealthPerkT[client], GANG_HEALTHMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientSpeedPerkT[client], GANG_SPEEDCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Speed ( T ) [ %i / %i ] Cost: %i", ClientSpeedPerkT[client], GANG_SPEEDMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientNadePerkT[client], GANG_NADECOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Nade Chance ( T ) [ %i / %i ] Cost: %i", ClientNadePerkT[client], GANG_NADEMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientHealthPerkCT[client], GANG_HEALTHCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Health ( CT ) [ %i / %i ] Cost: %i", ClientHealthPerkCT[client], GANG_HEALTHMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	upgradecost = GetUpgradeCost(ClientSpeedPerkCT[client], GANG_SPEEDCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Speed ( CT ) [ %i / %i ] Cost: %i", ClientSpeedPerkCT[client], GANG_SPEEDMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientGetHonorPerk[client], GANG_GETCREDITSCOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Get Honor [ %i / %i ] Cost: %i", ClientGetHonorPerk[client], GANG_GETCREDITSMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	upgradecost = GetUpgradeCost(ClientGangSizePerk[client], GANG_SIZECOST);
	IntToString(upgradecost, strUpgradeCost, sizeof(strUpgradeCost));
	Format(TempFormat, sizeof(TempFormat), "Gang Size [ %i / %i ] Cost: %i", ClientGangSizePerk[client], GANG_SIZEMAX, upgradecost);
	AddMenuItem(hMenu, strUpgradeCost, TempFormat, ClientGangHonor[client] >= upgradecost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	SetMenuTitle(hMenu, "%s Choose what perks to upgrade:", MENU_PREFIX);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Upgrade_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		if(!CheckGangAccess(client, RANK_MANAGER))
			return;
		
		new String:strUpgradeCost[20], Ignoreable, String:strIgnoreable[1];
		GetMenuItem(hMenu, item, strUpgradeCost, sizeof(strUpgradeCost), Ignoreable, strIgnoreable, 0)
		LoadClientGang_TryUpgrade(client, item, StringToInt(strUpgradeCost));
	}
}


LoadClientGang_TryUpgrade(client, item, upgradecost)
{
	new String:AuthId[35]
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE AuthId = '%s'", AuthId);
	
	new Handle:DP = CreateDataPack()
	
	WritePackCell(DP, GetClientUserId(client));
	WritePackCell(DP, item);
	WritePackCell(DP, upgradecost);
	SQL_TQuery(dbGangs, SQLCB_LoadClientGang_TryUpgrade, sQuery, DP, DBPrio_High);
}	

public SQLCB_LoadClientGang_TryUpgrade(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	ResetPack(DP);
	
	new client = GetClientOfUserId(ReadPackCell(DP));
	if (!IsValidPlayer(client))
	{
		CloseHandle(DP);
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			ClientRank[client] = SQL_FetchInt(hndl, 2);
			
			new String:sQuery[256];
			SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE GangName = '%s'", ClientGang[client]);
			SQL_TQuery(dbGangs, SQLCB_LoadGangByClient_TryUpgrade, sQuery, DP, DBPrio_High);
		}
		else
		{
			CloseHandle(DP);
			ClientLoadedFromDb[client] = true;
		}
	}
}

public SQLCB_LoadGangByClient_TryUpgrade(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}

	ResetPack(DP);
	
	new client = GetClientOfUserId(ReadPackCell(DP));
	new item = ReadPackCell(DP);
	new upgradecost = ReadPackCell(DP);
	
	CloseHandle(DP);
	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) != 0)
		{
			SQL_FetchRow(hndl);
			
			SQL_FetchString(hndl, 0, ClientGang[client], sizeof(ClientGang[]));
			SQL_FetchString(hndl, 1, ClientTag[client], sizeof(ClientTag[]));
			SQL_FetchString(hndl, 2, ClientMotd[client], sizeof(ClientMotd[]));
			ClientGangHonor[client] = SQL_FetchInt(hndl, 3);
			ClientHealthPerkT[client] = SQL_FetchInt(hndl, 4);
			ClientSpeedPerkT[client] = SQL_FetchInt(hndl, 5);
			ClientNadePerkT[client] = SQL_FetchInt(hndl, 6);
			ClientHealthPerkCT[client] = SQL_FetchInt(hndl, 7);
			ClientSpeedPerkCT[client] = SQL_FetchInt(hndl, 8);
			ClientGetHonorPerk[client] = SQL_FetchInt(hndl, 9);
			ClientGangSizePerk[client] = SQL_FetchInt(hndl, 10);
			
			TryUpgradePerk(client, item, upgradecost);
		}
	}
}

TryUpgradePerk(client, item, upgradecost) // Safety accomplished.
{
	if(ClientGangHonor[client] < upgradecost)
	{	
		PrintToChat(client, " Your gang doesn't have enough honor to upgrade.");
		return;
	}	
	new PerkToUse, PerkMax, String:PerkName[32], String:PerkNick[32];
	
	switch(item + 1)
	{
		case 1: PerkToUse = ClientHealthPerkT[client], PerkMax = GANG_HEALTHMAX, PerkName = "GangHealthPerkT", PerkNick = "Health ( T )";
		case 2: PerkToUse = ClientSpeedPerkT[client], PerkMax = GANG_SPEEDMAX, PerkName = "GangSpeedPerkT", PerkNick = "Speed ( T )";
		case 3: PerkToUse = ClientNadePerkT[client], PerkMax = GANG_NADEMAX, PerkName = "GangNadePerkT", PerkNick = "Nade Chance ( T )";
		case 4: PerkToUse = ClientHealthPerkCT[client], PerkMax = GANG_HEALTHMAX, PerkName = "GangHealthPerkCT", PerkNick = "Health ( CT )";
		case 5: PerkToUse = ClientSpeedPerkCT[client], PerkMax = GANG_SPEEDMAX, PerkName = "GangSpeedPerkCT", PerkNick = "Speed ( CT )";
		case 6: PerkToUse = ClientGetHonorPerk[client], PerkMax = GANG_GETCREDITSMAX, PerkName = "GangGetHonorPerk", PerkNick = "Get Honor";
		case 7: PerkToUse = ClientGangSizePerk[client], PerkMax = GANG_SIZEMAX, PerkName = "GangSizePerk", PerkNick = "Gang Size";
		default: return;
	}
	
	if(PerkToUse >= PerkMax)
	{	
		PrintToChat(client, "%s \x07Your gang has already maxed this perk!", PREFIX);
		return;
	}
		
	new String:sQuery[256];
	
	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT INTO GangSystem_upgradelogs (GangName, AuthId, Perk, BValue, AValue, timestamp) VALUES ('%s', '%s', '%s', %i, %i, %i)", ClientGang[client], steamid, PerkName, PerkToUse, PerkToUse+1, GetTime());
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 7, DBPrio_High);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangHonor = GangHonor - %i WHERE GangName = '%s'", upgradecost, ClientGang[client]);
	
	new Handle:DP = CreateDataPack(), Handle:DP2 = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	SQL_TQuery(dbGangs, SQLCB_UpdateGang, sQuery, DP);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET %s = %s + 1 WHERE GangName = '%s'", PerkName, PerkName, ClientGang[client]);
	WritePackString(DP2, ClientGang[client]);
	SQL_TQuery(dbGangs, SQLCB_UpdateGang, sQuery, DP2);
	
	PrintToChatGang(ClientGang[client], "%s \x03%N \x09has upgraded the gang perk \x03%s\x09!", PREFIX, client, PerkNick);

}

public SQLCB_UpdateGang(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
		SetFailState(error);
	
	ResetPack(DP);
	
	new String:GangName[32];
	ReadPackString(DP, GangName, sizeof(GangName));

	CloseHandle(DP);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
		
		ResetVariables(i, false);
		LoadClientGang(i);
	}
}


ShowPromoteMenu(client)
{
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s' ORDER BY LastConnect DESC", ClientGang[client]); 
	SQL_TQuery(dbGangs, SQLCB_ShowPromoteMenu, sQuery, GetClientUserId(client));
}

public SQLCB_ShowPromoteMenu(Handle:owner, Handle:hndl, String:error[], UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	new client = GetClientOfUserId(UserId);

	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		new Handle:hMenu = CreateMenu(Promote_MenuHandler);
	
		new String:TempFormat[200], String:Info[250], String:iAuthId[35], String:Name[64];
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, iAuthId, sizeof(iAuthId));
			new Rank = SQL_FetchInt(hndl, 2);
			
			new String:strRank[32];
			GetRankName(Rank, strRank, sizeof(strRank));
			SQL_FetchString(hndl, 4, Name, sizeof(Name));
			
			new LastConnect = SQL_FetchInt(hndl, 7);
			
			Format(Info, sizeof(Info), "\"%s\" \"%s\" \"%i\" \"%i\"", iAuthId, Name, Rank, LastConnect);
			Format(TempFormat, sizeof(TempFormat), "%s [%s] - %s [Donated: %i]", Name, strRank, FindClientByAuthId(iAuthId) != 0 ? "ONLINE" : "OFFLINE", SQL_FetchInt(hndl, 3));
				
			AddMenuItem(hMenu, Info, TempFormat, Rank < GetClientRank(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}

		SetMenuTitle(hMenu, "%s Choose who to promote:", MENU_PREFIX);
		
		SetMenuExitButton(hMenu, true);
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

public Promote_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		new String:Info[200], Ignoreable, String:strIgnoreable[1];
		GetMenuItem(hMenu, item, Info, sizeof(Info), Ignoreable, strIgnoreable, 0);
		
		PromoteMenu_ChooseRank(client, Info);
	}
}

PromoteMenu_ChooseRank(client, const String:Info[])
{
	new Handle:hMenu = CreateMenu(ChooseRank_MenuHandler);
	
	for(new i=RANK_MEMBER;i <= GetClientRank(client);i++)
	{
		if(i == GetClientRank(client) && !CheckGangAccess(client, RANK_LEADER))
			break;
			
		else if(i > RANK_COLEADER)
			i = RANK_LEADER;
			
		new String:RankName[20];
		GetRankName(i, RankName, sizeof(RankName));
		
		AddMenuItem(hMenu, Info, RankName);
	}
	
	new String:iAuthId[35], String:Name[64], String:strRank[11], String:strLastConnect[11];
	
	new len = BreakString(Info, iAuthId, sizeof(iAuthId));
	
	new len2 = BreakString(Info[len], Name, sizeof(Name));
	
	new len3 = BreakString(Info[len+len2], strRank, sizeof(strRank));
	
	BreakString(Info[len+len2+len3], strLastConnect, sizeof(strLastConnect));

	new String:Date[64];
	FormatTime(Date, sizeof(Date), "%d/%m/%Y - %H:%M:%S", StringToInt(strLastConnect));		
	
	SetMenuTitle(hMenu, "%s Choose the rank you want to give to %s\nTarget's Last Connect: %s", MENU_PREFIX, Name, Date);
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
}

public ChooseRank_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowPromoteMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		new String:Info[200], String:iAuthId[35], String:strRank[20], String:strLastConnect[11], String:Name[64], Ignoreable, String:strIgnoreable[1];
		GetMenuItem(hMenu, item, Info, sizeof(Info), Ignoreable, strIgnoreable, 0);
		
		new len = BreakString(Info, iAuthId, sizeof(iAuthId));
		
		new len2 = BreakString(Info[len], Name, sizeof(Name));
		
		new len3 = BreakString(Info[len+len2], strRank, sizeof(strRank));
		
		BreakString(Info[len+len2+len3], strLastConnect, sizeof(strLastConnect));
		
		if(item > RANK_COLEADER)
			item = RANK_LEADER;
			
		if(item < GetClientRank(client))
		{
			new String:NewRank[32];
			GetRankName(item, NewRank, sizeof(NewRank));
			PrintToChatGang(ClientGang[client], " %s has been promoted to %s", Name, NewRank);
			SetAuthIdRank(iAuthId, ClientGang[client], item);
		}
		else
		{
			GangAttemptStepDown[client] = true;
			
			new target = FindClientByAuthId(iAuthId);
			
			if(target == 0)
			{
				PrintToChat(client, "The target must be connected for a step-down action for security reasons.");
				
				return;
			}
			
			GangStepDownTarget[client] = GetClientUserId(target);
			
			PrintToChat(client, "%s \x07Attention! You are attempting to promote a player to be the \x03Leader\x07.", PREFIX);
			PrintToChat(client, "%s \x07By doing so you will become a \x03Co-Leader \x07in the gang.", PREFIX);
			PrintToChat(client, "%s \x07This action is irreversible, the new leader can kick you if he wants.", PREFIX);
			PrintToChat(client, "%s \x07If you read all above and sure you want to continue, write \x03!confirmstepdowngang\x07.", PREFIX);
			PrintToChat(client, "%s \x05Write anything else in the chat to abort the action", PREFIX);
		}
	}
}

ShowKickMenu(client)
{
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s' ORDER BY LastConnect DESC", ClientGang[client]); 
	SQL_TQuery(dbGangs, SQLCB_ShowKickMenu, sQuery, GetClientUserId(client));
}

public SQLCB_ShowKickMenu(Handle:owner, Handle:hndl, String:error[], UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	new client = GetClientOfUserId(UserId);

	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		new Handle:hMenu = CreateMenu(Kick_MenuHandler);
	
		new String:TempFormat[200], String:Info[250], String:iAuthId[35], String:Name[64];
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, iAuthId, sizeof(iAuthId));
			new Rank = SQL_FetchInt(hndl, 2);
			
			new String:strRank[32];
			GetRankName(Rank, strRank, sizeof(strRank));
			SQL_FetchString(hndl, 4, Name, sizeof(Name));
			
			new LastConnect = SQL_FetchInt(hndl, 7);
			
			Format(Info, sizeof(Info), "\"%s\" \"%s\" \"%i\" \"%i\"", iAuthId, Name, Rank, LastConnect);
			Format(TempFormat, sizeof(TempFormat), "%s [%s] - %s [Donated: %i]", Name, strRank, FindClientByAuthId(iAuthId) != 0 ? "ONLINE" : "OFFLINE", SQL_FetchInt(hndl, 3));
				
			AddMenuItem(hMenu, Info, TempFormat, Rank < GetClientRank(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}

		SetMenuTitle(hMenu, "%s Choose who to kick:", MENU_PREFIX);
		
		SetMenuExitButton(hMenu, true);
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}


public Kick_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		new String:Info[200], String:iAuthId[35], String:strRank[20], String:strLastConnect[11], String:Name[64], Ignoreable, String:strIgnoreable[1];
		GetMenuItem(hMenu, item, Info, sizeof(Info), Ignoreable, strIgnoreable, 0);
		
		new len = BreakString(Info, iAuthId, sizeof(iAuthId));
		
		new len2 = BreakString(Info[len], Name, sizeof(Name));
		
		new len3 = BreakString(Info[len+len2], strRank, sizeof(strRank));
		
		BreakString(Info[len+len2+len3], strLastConnect, sizeof(strLastConnect));
		
		if(StringToInt(strRank) >= GetClientRank(client)) // Should never return but better safe than sorry.
			return;
			
		ShowConfirmKickMenu(client, iAuthId, Name, StringToInt(strLastConnect));
	}
}

ShowConfirmKickMenu(client, const String:iAuthId[], const String:Name[], LastConnect)
{
	new Handle:hMenu = CreateMenu(ConfirmKick_MenuHandler);
	
	AddMenuItem(hMenu, iAuthId, "Yes");
	AddMenuItem(hMenu, Name, "No"); // This will also be used.
	
	new String:Date[64];
	FormatTime(Date, sizeof(Date), "%d/%m/%Y - %H:%M:%S", LastConnect);
	
	SetMenuTitle(hMenu, "%s Gang Kick\nAre you sure you want to kick %s?\nSteam ID of target: %s\nTarget's last connect: %s", MENU_PREFIX, Name, iAuthId, Date);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 60);
}

public ConfirmKick_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowKickMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		if(item + 1 == 1)
		{
			new String:iAuthId[35], String:Name[64], Ignoreable, String:strIgnoreable[1];
			GetMenuItem(hMenu, 0, iAuthId, sizeof(iAuthId), Ignoreable, strIgnoreable, 0)
			GetMenuItem(hMenu, 1, Name, sizeof(Name), Ignoreable, strIgnoreable, 0)
			
			PrintToChatGang(ClientGang[client], "%s \x03%N \x09has kicked %s from the gang!", PREFIX, client, Name);
			
			KickAuthIdFromGang(iAuthId, ClientGang[client]);
		}
	}
}

ShowInviteMenu(client)
{
	new Handle:hMenu = CreateMenu(Invite_MenuHandler);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		else if(IsClientGang(i))
			continue;
			
		//else if(IsFakeClient(i))
			//continue;
	
		new String:strUserId[20], String:iName[64];
		IntToString(GetClientUserId(i), strUserId, sizeof(strUserId));
		GetClientName(i, iName, sizeof(iName));
		
		AddMenuItem(hMenu, strUserId, iName);
	}
	
	SetMenuTitle(hMenu, "%s Choose who to invite:", MENU_PREFIX);
	
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Invite_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		ShowManageGangMenu(client);
		
	else if(action == MenuAction_Select)
	{	
		new String:strUserId[20], target, String:strIgnoreable[1];
		GetMenuItem(hMenu, item, strUserId, sizeof(strUserId), target, strIgnoreable, 0)
		
		target = GetClientOfUserId(StringToInt(strUserId));
		
		if(IsValidPlayer(target))
		{
			if(!IsClientGang(target))
			{
				if(!IsFakeClient(target))
				{
					new String:AuthId[35];
					GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
					ShowAcceptInviteMenu(target, AuthId, ClientGang[client]);
					PrintToChat(client, "%s \x05You have invited \x03%N \x05to join the gang!", PREFIX, target);
				}
				else
				{
					new String:AuthId[35];
					GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
					AddClientToGang(target, AuthId, ClientGang[client]);
				}
			}
		}
	}
}

ShowAcceptInviteMenu(target, const String:AuthIdInviter[], const String:GangName[])
{
	if(!IsValidPlayer(target))
		return;
	
	new Handle:hMenu = CreateMenu(AcceptInvite_MenuHandler);
	
	AddMenuItem(hMenu, AuthIdInviter, "Yes");
	AddMenuItem(hMenu, GangName, "No"); // This info string will also be used.
	
	SetMenuTitle(hMenu, "%s Gang Invite\nWould you like to join the gang %s?", MENU_PREFIX, GangName);
	DisplayMenu(hMenu, target, 10);
}

public AcceptInvite_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{	
		if(item + 1 == 1)
		{
			new String:AuthIdInviter[35], String:GangName[32], Ignoreable, String:strIgnoreable[1];
			GetMenuItem(hMenu, 0, AuthIdInviter, sizeof(AuthIdInviter), Ignoreable, strIgnoreable, 0)
			GetMenuItem(hMenu, 1, GangName, sizeof(GangName), Ignoreable, strIgnoreable, 0)
			
			new String:LastGang[sizeof(ClientGang[])];
			LastGang = ClientGang[client];
			
			ClientGang[client] = GangName;
			PrintToChatGang(ClientGang[client], "%s \x03%N \x09has been invited to the gang!", PREFIX, client);
			ClientGang[client] = LastGang;
			
			AddClientToGang(client, AuthIdInviter, GangName);
		}
	}
}

ShowMembersMenu(client)
{
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s' ORDER BY LastConnect DESC", ClientGang[client]); 
	SQL_TQuery(dbGangs, SQLCB_ShowMembersMenu, sQuery, GetClientUserId(client));
}


public SQLCB_ShowMembersMenu(Handle:owner, Handle:hndl, String:error[], UserId)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	new client = GetClientOfUserId(UserId);

	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		new Handle:hMenu = CreateMenu(Members_MenuHandler);
	
		new String:TempFormat[200], String:iAuthId[35], String:Name[64];
		while(SQL_FetchRow(hndl))
		{
			new String:strRank[32];
			new Rank = SQL_FetchInt(hndl, 2);
			GetRankName(Rank, strRank, sizeof(strRank));
			SQL_FetchString(hndl, 4, Name, sizeof(Name));
			SQL_FetchString(hndl, 1, iAuthId, sizeof(iAuthId));
			Format(TempFormat, sizeof(TempFormat), "%s [%s] - %s [Donated: %i]", Name, strRank, FindClientByAuthId(iAuthId) != 0 ? "ONLINE" : "OFFLINE", SQL_FetchInt(hndl, 3));
				
			AddMenuItem(hMenu, iAuthId, TempFormat, ITEMDRAW_DISABLED);
		}

		SetMenuTitle(hMenu, "%s Member List:", MENU_PREFIX);
		
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}


public Members_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Cancel && item == MenuCancel_ExitBack)
		Command_Gang(client, 0);
}

TryCreateGang(client, const String:GangName[], const String:GangTag[])
{	
	if(GangName[0] == EOS)
	{
		GangCreateName[client] = GANG_NULL;
		GangCreateTag[client] = GANG_NULL;
		PrintToChat(client, "%s \x07The selected gang name is invalid.", PREFIX);
		return;
	}
	else if(GangTag[0] == EOS)
	{
		GangCreateName[client] = GANG_NULL;
		GangCreateTag[client] = GANG_NULL;
		PrintToChat(client, "%s \x07The selected gang tag is invalid.", PREFIX);
		return;
	}	
	else if(ClientHonor[client] < GANG_COSTCREATE)
	{
		GangCreateName[client] = GANG_NULL;
		GangCreateTag[client] = GANG_NULL;
		PrintToChat(client, "%s \x07You need \x03%i \x07more honor to open a gang!", PREFIX, GANG_COSTCREATE - ClientHonor[client]);
		return;
	}
	new Handle:DP = CreateDataPack();
	WritePackCell(DP, GetClientUserId(client));
	WritePackString(DP, GangName);
	WritePackString(DP, GangTag);
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE lower(GangName) = lower('%s') OR lower(GangTag) = lower('%s')", GangName, GangTag);
	SQL_TQuery(dbGangs, SQLCB_CreateGang_CheckTakenNameOrTag, sQuery, DP);
}


public SQLCB_CreateGang_CheckTakenNameOrTag(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	ResetPack(DP);
	
	new client = GetClientOfUserId(ReadPackCell(DP));
	new String:GangName[32], String:GangTag[10];
	
	ReadPackString(DP, GangName, sizeof(GangName));
	ReadPackString(DP, GangTag, sizeof(GangTag));
	
	CloseHandle(DP);
	
	if (!IsValidPlayer(client))
	{
		return;
	}
	else 
	{
		if(SQL_GetRowCount(hndl) == 0)
		{
			CreateGang(client, GangName, GangTag);
			PrintToChat(client, "%s \x09The gang was created!", PREFIX)
		}
		else // Gang name is taken.
		{
			new bool:NameTaken = false;
			new bool:TagTaken = false;
			
			new String:iGangName[32], String:iGangTag[10];
			while(SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, iGangName, sizeof(iGangName));
				SQL_FetchString(hndl, 1, iGangTag, sizeof(iGangTag));
				
				if(StrEqual(iGangName, GangName, false))
					NameTaken = true;
					
				if(StrEqual(iGangTag, GangTag, false))
					TagTaken = true;
			}
			
			if(NameTaken)
			{	
				GangCreateName[client] = GANG_NULL;
				PrintToChat(client, "%s \x07The selected gang name is already taken!", PREFIX);
			
			}
			if(TagTaken)
			{
				GangCreateTag[client] = GANG_NULL;
				PrintToChat(client, "%s \x07The selected gang tag is already taken!", PREFIX);
			}
		}
	}
}

CreateGang(client, const String:GangName[], const String:GangTag[])
{
	if(ClientHonor[client] < GANG_COSTCREATE)
		return;
		
	new String:sQuery[256];
	
	new String:AuthId[35];
	
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));

	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "DELETE FROM GangSystem_Members WHERE GangName = '%s'", GangName); // Just in case.
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 8, DBPrio_High);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, AuthId);
	WritePackString(DP, GangName);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT INTO GangSystem_Gangs (GangName, GangTag, GangMotd, GangHonor, GangHealthPerkT, GangSpeedPerkT, GangNadePerkT, GangHealthPerkCT, GangSpeedPerkCT, GangGetHonorPerk, GangSizePerk) VALUES ('%s', '%s', '', 0, 0, 0, 0, 0, 0, 0, 0)", GangName, GangTag);
	SQL_TQuery(dbGangs, SQLCB_GangCreated, sQuery, DP);
	
	GiveClientHonor(client, -1 * GANG_COSTCREATE);
}

public SQLCB_GangCreated(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
		SetFailState(error);
	
	ResetPack(DP);
	
	new String:AuthId[35], String:GangName[32];
	ReadPackString(DP, AuthId, sizeof(AuthId));
	ReadPackString(DP, GangName, sizeof(GangName));

	CloseHandle(DP);
	
	AddAuthIdToGang(AuthId, AuthId, GangName, RANK_LEADER);
}
stock AddClientToGang(client, const String:AuthIdInviter[], const String:GangName[], GangRank = RANK_MEMBER)
{
	new String:AuthId[35];
	
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	AddAuthIdToGang(AuthId, AuthIdInviter, GangName, GangRank);

}

stock AddAuthIdToGang(const String:AuthId[], const String:AuthIdInviter[], const String:GangName[], GangRank = RANK_MEMBER)
{
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Gangs WHERE GangName = '%s'", GangName);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, AuthId);
	WritePackString(DP, AuthIdInviter);
	WritePackString(DP, GangName);
	WritePackCell(DP, GangRank);
	SQL_TQuery(dbGangs, SQLCB_AuthIdAddToGang_CheckSize, sQuery, DP);

}

public SQLCB_AuthIdAddToGang_CheckSize(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
		SetFailState(error);
		
	if(SQL_GetRowCount(hndl) != 0)
	{
		SQL_FetchRow(hndl);
		
		new Size = GANG_INITSIZE + (SQL_FetchInt(hndl, 10) * GANG_SIZEINCREASE);
		
		WritePackCell(DP, Size);
		
		ResetPack(DP);
		new String:AuthId[1], String:GangName[32];
		ReadPackString(DP, AuthId, 0);
		ReadPackString(DP, AuthId, 0);
		ReadPackString(DP, GangName, sizeof(GangName));
		
		new String:sQuery[256];
		SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "SELECT * FROM GangSystem_Members WHERE GangName = '%s'", GangName);
		SQL_TQuery(dbGangs, SQLCB_AuthIdAddToGang_CheckMemberCount, sQuery, DP);
	}
	else
	{	
		CloseHandle(DP);
		return;
	}
}

// This callback is used to get someone's member count
public SQLCB_CheckMemberCount(Handle:owner, Handle:hndl, String:error[], UserId)
{
	new MemberCount = SQL_GetRowCount(hndl);
	
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	ClientMembersCount[client] = MemberCount;
	
}

public SQLCB_AuthIdAddToGang_CheckMemberCount(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	
	new MemberCount = SQL_GetRowCount(hndl);
	
	ResetPack(DP);
	new String:AuthId[35], String:AuthIdInviter[35], String:GangName[32], Size, GangRank;
	ReadPackString(DP, AuthId, sizeof(AuthId));
	ReadPackString(DP, AuthIdInviter, sizeof(AuthIdInviter));
	ReadPackString(DP, GangName, sizeof(GangName));
	GangRank = ReadPackCell(DP);
	Size = ReadPackCell(DP);
	
	if(MemberCount >= Size)
	{
		CloseHandle(DP);
			
		PrintToChatGang(GangName, "%s \x03The gang is full!", PREFIX);
		return;
	}
	
	FinishAddAuthIdToGang(GangName, AuthId, GangRank, AuthIdInviter, DP);
}

// The DataPack will contain the invited auth ID as the first thing to be added.
public FinishAddAuthIdToGang(const String:GangName[], const String:AuthId[], GangRank, String:AuthIdInviter[], Handle:DP)
{
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "INSERT INTO GangSystem_Members (GangName, AuthId, GangRank, GangInviter, GangDonated, LastName, GangJoinDate, LastConnect) VALUES ('%s', '%s', %i, '%s', 0, '', %i, %i)", GangName, AuthId, GangRank, AuthIdInviter, GetTime(), GetTime());

	SQL_TQuery(dbGangs, SQLCB_AuthIdAddedToGang, sQuery, DP);
}
public SQLCB_AuthIdAddedToGang(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	ResetPack(DP);
	
	new String:AuthId[35];
	
	ReadPackString(DP, AuthId, sizeof(AuthId));
	
	CloseHandle(DP);
	
	UpdateInGameAuthId(AuthId);
}

stock UpdateInGameAuthId(const String:AuthId[])
{
	new String:iAuthId[35];
	for(new i = 1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		GetClientAuthId(i, AuthId_Engine, iAuthId, sizeof(iAuthId));
		
		if(StrEqual(AuthId, iAuthId, true))
		{
			ResetVariables(i);
			LoadClientGang(i, true);
			break;
		}
	}
}

stock FindClientByAuthId(const String:AuthId[])
{
	new String:iAuthId[35];
	for(new i = 1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		GetClientAuthId(i, AuthId_Engine, iAuthId, sizeof(iAuthId));
		
		if(StrEqual(AuthId, iAuthId, true))
			return i;
	}
	
	return 0;
}
stock StoreClientLastInfo(client)
{
	
	new String:AuthId[35], String:Name[64];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));

	Format(Name, sizeof(Name), "%N", client);
	StoreAuthIdLastInfo(AuthId, Name);
}


stock StoreAuthIdLastInfo(const String:AuthId[], const String:Name[])
{
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET LastName = '%s', LastConnect = %i WHERE AuthId = '%s'", Name, GetTime(), AuthId);
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 9, DBPrio_Low);
}

stock SetAuthIdRank(const String:AuthId[], const String:GangName[], Rank = RANK_MEMBER)
{
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET GangRank = %i WHERE AuthId = '%s' AND GangName = '%s'", Rank, AuthId, GangName);
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 10);
	
	UpdateInGameAuthId(AuthId);
}

stock DonateToGang(client, amount)
{
	if(!IsValidPlayer(client))
		return;
		
	else if(!IsClientGang(client))
		return;
		
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangHonor = GangHonor + %i WHERE GangName = '%s'", amount, ClientGang[client]);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_GangDonated, sQuery, DP);
	
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET GangDonated = GangDonated + %i WHERE AuthId = '%s'", amount, AuthId);
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 11);
	
	GiveClientHonor(client, -1 * amount);
	
	PrintToChatGang(ClientGang[client], "%s \x03%N \x09has donated \x03%i \x09to the gang!", PREFIX, client, amount);
}

public SQLCB_GangDonated(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	new String:GangName[32];
	ResetPack(DP);
	
	ReadPackString(DP, GangName, sizeof(GangName));
	
	CloseHandle(DP);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
		
		LoadClientGang(i);
	}
	
	
}
stock bool:IsClientGang(client)
{
	return ClientGang[client][0] != EOS ? true : false;
}

stock GetClientRank(client)
{
	return ClientRank[client];
}

// returns true if the clients are in the same gang, or if checking the same client while he has a gang.
stock bool:AreClientsSameGang(client, otherclient)
{
	if(!IsClientGang(client) || !IsClientGang(otherclient))
		return false;
		
	return StrEqual(ClientGang[client], ClientGang[otherclient], true);
}

stock PrintToChatGang(const String:GangName[], const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 3);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
			
		PrintToChat(i, buffer);
	}
}


stock bool:IsValidPlayer(client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return IsClientInGame(client);
}


stock bool:IsPlayer(client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return true;
}


stock GetRankName(Rank, String:buffer[], length)
{
	switch(Rank)
	{
		case RANK_MEMBER: Format(buffer, length, "Member");
		case RANK_OFFICER: Format(buffer, length, "Officer");
		case RANK_ADMIN: Format(buffer, length, "Admin");
		case RANK_MANAGER: Format(buffer, length, "Manager");
		case RANK_COLEADER: Format(buffer, length, "Co-Leader");
		case RANK_LEADER: Format(buffer, length, "Leader");
	}
}

stock bool:CheckGangAccess(client, Rank)
{
	return (GetClientRank(client) >= Rank);
}

stock bool:IsStringNumber(const String:source[])
{
	if(!IsCharNumeric(source[0]) && source[0] != '-')
		return false;
			
	for(new i=1;i < strlen(source);i++)
	{
		if(!IsCharNumeric(source[i]))
			return false;
	}
	
	return true;
}

stock bool:StringHasInvalidCharacters(const String:source[])
{
	for(new i=0;i < strlen(source);i++)
	{
		if(!IsCharNumeric(source[i]) && !IsCharAlpha(source[i]) && source[i] != '-' && source[i] != '_' && source[i] != ' ')
			return true;
	}
	
	return false;
}


stock GetEntityHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

stock GetEntityMaxHealth(entity)
{
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}

stock SetEntityMaxHealth(entity, amount)
{
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", amount);
}


stock GetUpgradeCost(CurrentPerkLevel, PerkCost)
{
	return (CurrentPerkLevel + 1) * PerkCost;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	 CreateNative("Gangs_HasGang", Native_HasGang);
	 CreateNative("Gangs_AreClientsSameGang", Native_AreClientsSameGang);
	 CreateNative("Gangs_GetClientGangName", Native_GetClientGangName);
	 CreateNative("Gangs_GetClientGangTag", Native_GetClientGangTag);
	 CreateNative("Gangs_GiveGangHonor", Native_GiveGangHonor);
	 CreateNative("Gangs_AddClientDonations", Native_AddClientDonations);
	 CreateNative("Gangs_GiveClientHonor", Native_GiveClientHonor);
	 CreateNative("Gangs_PrintToChatGang", Native_PrintToChatGang);
	 CreateNative("Gangs_TryDestroyGlow", Native_TryDestroyGlow);
	 
	 RegPluginLibrary("JB Gangs");
	 return APLRes_Success;
}

public int Native_HasGang(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return IsClientGang(client);
}

public int Native_AreClientsSameGang(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int otherClient = GetNativeCell(2);
	return AreClientsSameGang(client, otherClient);
}

public int Native_GetClientGangName(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int len = GetNativeCell(3);
    if(!IsClientGang(client))
    {
   		return;
  	}
    SetNativeString(2, ClientGang[client], len, false);
}

public int Native_GetClientGangTag(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int len = GetNativeCell(3);
    if(!IsClientGang(client))
    {
   		return;
  	}
    SetNativeString(2, ClientTag[client], len, false);
}


public int Native_PrintToChatGang(Handle plugin, int numParams)
{
	new String:GangName[32];
	
	GetNativeString(1, GangName, sizeof(GangName));
	new String:buffer[192];
	
	FormatNativeString(0, 2, 3, sizeof(buffer), _, buffer);
	
	PrintToChatGang(GangName, buffer);
}

public int Native_TryDestroyGlow(Handle plugin, int numParams)
{
	new client = GetNativeCell(1);
	
	TryDestroyGlow(client);
}

public int Native_GiveClientHonor(Handle plugin, int numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	
	GiveClientHonor(client, amount);
}


public int Native_AddClientDonations(Handle plugin, int numParams)
{
	new client = GetNativeCell(1);
	new amount = GetNativeCell(2);
	
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Members SET GangDonated = GangDonated + %i WHERE AuthId = '%s'", amount, AuthId);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, ClientGang[client]);
	
	SQL_TQuery(dbGangs, SQLCB_GangDonated, sQuery, DP);
}

public int Native_GiveGangHonor(Handle plugin, int numParams)
{
	new String:GangName[32];
	
	GetNativeString(1, GangName, sizeof(GangName));
	new amount = GetNativeCell(2);
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Gangs SET GangHonor = GangHonor + %i WHERE GangName = '%s'", amount, GangName);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, GangName);
	
	SQL_TQuery(dbGangs, SQLCB_GiveGangHonor, sQuery, DP);    
}

public SQLCB_GiveGangHonor(Handle:owner, Handle:hndl, String:error[], Handle:DP)
{
	if(hndl == null)
	{
		SetFailState(error);
	}
	
	ResetPack(DP);
	
	new String:GangName[32];
	ReadPackString(DP, GangName, sizeof(GangName));
	
	CloseHandle(DP);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(!StrEqual(ClientGang[i], GangName, true))
			continue;
		
		LoadClientGang(i);
	}	
}
stock PrintToChatEyal(const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			

		new String:steamid[64];
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144"))
			PrintToChat(i, buffer);
	}
}

stock GetPlayerCount()
{
	new Count, Team;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		Team = GetClientTeam(i);
		if(Team != CS_TEAM_CT && Team != CS_TEAM_T)	
			continue;
			
		Count++;
	}
	
	return Count;
}

stock LogGangAction(const String:format[], any:...)
{
	new String:buffer[291], String:Path[256];
	VFormat(buffer, sizeof(buffer), format, 2);	
	
	BuildPath(Path_SM, Path, sizeof(Path), "logs/Alon-Gangs.txt");
	LogToFile(Path, buffer);

}


stock bool:IsKnifeClass(const String:classname[])
{
	if(StrContains(classname, "knife") != -1 || StrContains(classname, "bayonet") > -1)
		return true;
		
	return false;
}

stock GetAliveTeamCount(Team)
{
	new count = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) != Team)
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		count++;
	}
	
	return count;
}	

stock GiveClientHonor(client, amount)
{
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:sQuery[256];
	SQL_FormatQuery(dbGangs, sQuery, sizeof(sQuery), "UPDATE GangSystem_Honor SET Honor = Honor + %i WHERE AuthId = '%s'", amount, AuthId);
	
	ClientHonor[client] += amount;
	
	SQL_TQuery(dbGangs, SQLCB_Error, sQuery, 12);
}