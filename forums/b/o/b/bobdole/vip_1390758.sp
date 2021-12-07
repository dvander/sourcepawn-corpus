#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define ROUNDEND_TARGET_BOMBED                          0        // Target Successfully Bombed!
#define ROUNDEND_VIP_ESCAPED                            1        // The VIP has escaped!
#define ROUNDEND_VIP_ASSASSINATED                       2        // VIP has been assassinated!
#define ROUNDEND_TERRORISTS_ESCAPED                     3        // The terrorists have escaped!
#define ROUNDEND_CTS_PREVENTESCAPE                      4        // The CT's have prevented most of the terrorists from escaping!
#define ROUNDEND_ESCAPING_TERRORISTS_NEUTRALIZED        5        // Escaping terrorists have all been neutralized!
#define ROUNDEND_BOMB_DEFUSED                           6        // The bomb has been defused!
#define ROUNDEND_CTS_WIN                                7        // Counter-Terrorists Win!
#define ROUNDEND_TERRORISTS_WIN                         8        // Terrorists Win!
#define ROUNDEND_ROUND_DRAW                             9       // Round Draw!
#define ROUNDEND_ALL_HOSTAGES_RESCUED                   10       // All Hostages have been rescued!
#define ROUNDEND_TARGET_SAVED                           11       // Target has been saved!
#define ROUNDEND_HOSTAGES_NOT_RESCUED                   12       // Hostages have not been rescued!
#define ROUNDEND_TERRORISTS_NOT_ESCAPED                 13       // Terrorists have not escaped!
#define ROUNDEND_VIP_NOT_ESCAPED                        14       // VIP has not escaped!
#define ROUNDEND_GAME_COMMENCING                        15       // Game Commencing!

#define PLUGIN_VERSION "3.0"

new VIPClient;
new OldVIPClient;
new Float:VIPArmorCount;

new g_iArmorOffset;
new g_iAccount;
new m_iScore;

new bool:VIPMade = false;
new bool:VRoundEnd = false;
new bool:LockZones = false;
new bool:VIPWin = false;

new String:VIPAllowedWeapons[][] = { "weapon_usp","weapon_flashbang","weapon_smokegrenade","weapon_hegrenade","weapon_knife"};
new String:VIPWeapons[30][30];

new Handle:g_hToolsGameConfig = INVALID_HANDLE;
new Handle:g_hToolsTerminateRound = INVALID_HANDLE;
new Handle:hSetModel;
new Handle:hGameConf;
new Handle:RoundTimer[2];

new Float:VIPZone1[6];
new Float:VIPZone2[6];
new Float:VIPZone3[6];
new Float:vpos[3];

public Plugin:myinfo =
{
    name = "VIP Mod",
    author = "BobDole",
    description = "Bring VIP back from 1.6",
    version = PLUGIN_VERSION,
    url = "http://www.clandg.com"
};

public OnPluginStart()
{    

	CreateConVar("vip_version", PLUGIN_VERSION, "Version of VIP", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("round_start", Event_round_start);
	HookEvent("round_end", Event_round_end);
	HookEvent("player_hurt", Event_player_hurt);
	HookEvent("player_death", Event_player_death);
	HookEvent("round_freeze_end", Event_round_freeze_end, EventHookMode_Pre);
	
	RegConsoleCmd("buy", BuyBlock);
	RegConsoleCmd("rebuy", BuyBlock);
	RegConsoleCmd("autobuy", BuyBlock);
	
	RegConsoleCmd("vip_escapezone", CreateZone1);
	RegConsoleCmd("vip_escapezone2", CreateZone2);
	RegConsoleCmd("vip_escapezone3", CreateZone3);
	
	RegConsoleCmd("help", showhelp);
	RegConsoleCmd("info", showhelp);
	RegConsoleCmd("vip", showhelp);
	RegConsoleCmd("vip_info", showhelp);
	
	
	g_iArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	m_iScore = FindSendPropOffs("CCSTeam","m_iScore");
	
	// Load game config file.
	g_hToolsGameConfig = LoadGameConfigFile("plugin.vip");

	// Prep the SDKCall for "TerminateRound."
	
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(g_hToolsGameConfig, SDKConf_Signature, "TerminateRound");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hToolsTerminateRound = EndPrepSDKCall();
	

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	strcopy(VIPWeapons[0], sizeof(VIPWeapons), "null");
	//strcopy(VIPWeapons[1], sizeof(VIPWeapons), "null");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	PrintToChat(client,"\x03[DG VIP] \x01Welcome is this your first time? type '/info' for help");

}

public Action:OnWeaponEquip(client, weapon)
{
	if(VIPMade)
	{
		if(VIPClient ==  client && IsClientInGame(VIPClient))
		{
			decl String:sWeapon[32];
			GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
			for (new i=0;i<sizeof(VIPAllowedWeapons);i++)
			{
				if(StrEqual(sWeapon, VIPAllowedWeapons[i],false))
					return Plugin_Continue;	
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

RefreshClientWeapons(client)
{
	decl String:classname[32];

	for (new x = 0; x < 5; x++) // min/max cs:s weapon slots
	{
		new weapon = GetPlayerWeaponSlot(client, x);
		if (weapon == -1)
			continue;

		GetEdictClassname(weapon, classname, sizeof(classname));
		//strcopy(VIPWeapons[x], sizeof(VIPWeapons), classname);
		RemovePlayerItem(client, weapon);
		GivePlayerItem(client, classname);
	}
}

GiveVIPWeapons()
{
	if(OldVIPClient != VIPClient)
		{
		if(!StrEqual(VIPWeapons[0], "null",false))
		{
			//PrintToChatAll("Primary: %s", VIPWeapons[0]);
			GivePlayerItem(OldVIPClient, VIPWeapons[0]);
		}
		/*
		if(!StrEqual(VIPWeapons[1], "null",false))
		{
			//PrintToChatAll("secondary: %s", VIPWeapons[1]);
			GivePlayerItem(OldVIPClient, VIPWeapons[1]);
		}*/
	
	
	
		strcopy(VIPWeapons[0], sizeof(VIPWeapons), "null");
		//strcopy(VIPWeapons[1], sizeof(VIPWeapons), "null");
		
	}
}

public Action:OnGetGameDescription(String:gameDesc[64])
{

	strcopy(gameDesc, sizeof(gameDesc), "Assasination/VIP");
	return Plugin_Changed;

}

public OnMapStart()
{	
	LockZones = false;
	//vip skin
	AddFileToDownloadsTable("models/player/vip/small2/vip.dx80.vtx");
	AddFileToDownloadsTable("models/player/vip/small2/vip.dx90.vtx");
	AddFileToDownloadsTable("models/player/vip/small2/vip.mdl");
	AddFileToDownloadsTable("models/player/vip/small2/vip.phy");
	AddFileToDownloadsTable("models/player/vip/small2/vip.sw.vtx");
	AddFileToDownloadsTable("models/player/vip/small2/vip.vvd");
	//vip model
	AddFileToDownloadsTable("materials/models/player/vip/small1/erdim_cylmap.vmt");
	AddFileToDownloadsTable("materials/models/player/vip/small1/erdim_cylmap.vtf");
	AddFileToDownloadsTable("materials/models/player/vip/small1/erdim_facemap.vmt");
	AddFileToDownloadsTable("materials/models/player/vip/small1/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/vip/small1/eyeball_l.vtf");
	AddFileToDownloadsTable("materials/models/player/vip/small1/eyeball_r.vmt");
	AddFileToDownloadsTable("materials/models/player/vip/small1/eyeball_r.vtf");
	AddFileToDownloadsTable("materials/models/player/vip/small1/UrbanTemp.vmt");
	AddFileToDownloadsTable("materials/models/player/vip/small1/UrbanTemp.vtf");
	// map decals
	AddFileToDownloadsTable("materials/decals/logo2.vmt");
	AddFileToDownloadsTable("materials/decals/logo2.vtf");
	AddFileToDownloadsTable("materials/decals/VIP_arrow_left.vmt");
	AddFileToDownloadsTable("materials/decals/VIP_arrow_left.vtf");
	AddFileToDownloadsTable("materials/decals/VIP_arrow_right.vmt");
	AddFileToDownloadsTable("materials/decals/VIP_arrow_right.vtf");
	AddFileToDownloadsTable("materials/decals/vip_escape_zone.vmt");
	AddFileToDownloadsTable("materials/decals/vip_escape_zone.vtf");
	AddFileToDownloadsTable("materials/decals/vip_escape_zone_decal.vmt");
	AddFileToDownloadsTable("materials/decals/vip_escape_zone_decal.vtf");
	//chopper materials
	AddFileToDownloadsTable("materials/models/chopper/blackhawk.vmt");
	AddFileToDownloadsTable("materials/models/chopper/blackhawk.vtf");
	AddFileToDownloadsTable("materials/models/chopper/blackhawk_ref.vtf");
	//chopper model
	AddFileToDownloadsTable("models/chopper/blackhawk.dx80.vtx");
	AddFileToDownloadsTable("models/chopper/blackhawk.dx90.vtx");
	AddFileToDownloadsTable("models/chopper/blackhawk.mdl");
	AddFileToDownloadsTable("models/chopper/blackhawk.phy");
	AddFileToDownloadsTable("models/chopper/blackhawk.sw.vtx");
	AddFileToDownloadsTable("models/chopper/blackhawk.vvd");
	//sounds
	AddFileToDownloadsTable("sound/deathrow.wav");
	AddFileToDownloadsTable("sound/fart.wav");
	AddFileToDownloadsTable("sound/oilrigelevator.wav");
	AddFileToDownloadsTable("sound/oilriggodzilla.wav");
	AddFileToDownloadsTable("sound/pissoff.wav");
	AddFileToDownloadsTable("sound/roundstart.mp3");
	AddFileToDownloadsTable("sound/scream.mp3");
	AddFileToDownloadsTable("sound/snore.wav");
	AddFileToDownloadsTable("sound/vomit.wav");	
	AddFileToDownloadsTable("sound/vip.wav");
	
	PrecacheModel("models/player/vip/small2/vip.mdl",true);
	PrecacheSound("vip.wav", true);
	
	//execute map configs
	decl String:mapName[64];
	decl String:path[64];
	GetCurrentMap(mapName, sizeof(mapName));	
	Format(path, sizeof(path), "cfg/vip/%s.cfg",mapName);
	LogMessage("Path is: %s", path);
	if(FileExists(path))
	{
		LogMessage("%s does exist", path);
		ExecFile(path);		
	}
	
	HookEntityOutput( "trigger_multiple", "OnStartTouch", OnTriggerTouch);

	
}

public OnTriggerTouch(const String:output[], caller, activator, Float:delay)
{
	decl String:tempentityname[128];
	GetEntPropString(caller, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
	
	if(StrEqual(tempentityname, "vip_escape", false))
	{
		if(activator == VIPClient)
		{
			VIPEscaped();
		}
	}
}


ExecFile(String:VPath[])
{
	LogMessage("reading file");
	decl String:szFileLine[512],Handle:hFile;
	hFile = OpenFile(VPath, "r");
	if (hFile != INVALID_HANDLE) 
	{
		while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szFileLine, sizeof(szFileLine)))
		{
			ServerCommand(szFileLine);
		}
		CloseHandle(hFile);
	} 
}

VIPEscaped()
{
	SDKCall(g_hToolsTerminateRound, 5.0, ROUNDEND_VIP_ESCAPED);						
	LogEventToGame("EscapedAsVIP", VIPClient);						
	SetTeamCash(3,3200);
	Addtoscore(3);
	if(RoundTimer[0] != INVALID_HANDLE)
	{
		KillTimer(RoundTimer[0]);
		RoundTimer[0] = INVALID_HANDLE;
	}
	VRoundEnd = true;
	VIPMade = false;
	VIPWin = true;

}

public OnGameFrame()
{
	if(VIPMade)
	{
		if(VIPClient > 0)
		{
			if(IsClientInGame(VIPClient))
			{
				
				if(!VRoundEnd)
				{
					//new String:temparmor[5];
					//FloatToString(RoundToFloor(VIPArmorCount),temparmor,sizeof(temparmor));
					SetEntData(VIPClient, g_iArmorOffset, RoundToFloor(VIPArmorCount));
					PrintHintText(VIPClient, "Armor: %d", RoundToFloor(VIPArmorCount));
					GetClientAbsOrigin(VIPClient, Float:vpos);
					if(IsinZone1(vpos) || IsinZone2(vpos) || IsinZone3(vpos))
					{
						VIPEscaped();
					}
				}
			}
			else
			{
				if(!VRoundEnd)
				{
					SDKCall(g_hToolsTerminateRound, 5.0, ROUNDEND_ROUND_DRAW);
					if(RoundTimer[0] != INVALID_HANDLE)
					{
						RoundTimer[0] = INVALID_HANDLE;
						KillTimer(RoundTimer[0]);
					}
					VRoundEnd = true;
					VIPMade = false;
					VIPClient = 0;
				}
			}
		}	
	}
}

public Action:Event_round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEventBroadcast(event, true); 
}



public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	VRoundEnd = false;
	
		
	MakeVIP();
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
			PrintToChat(i,"\x03[DG VIP] \x01Kill the VIP");	

		if(IsClientInGame(i))
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
	}
	
	if(RoundTimer[0] == INVALID_HANDLE)
	{
		RoundTimer[0] = CreateTimer(242.9, RoundEndTime);
		return Plugin_Continue;
	}
	else if (RoundTimer[0] != INVALID_HANDLE)
	{
		KillTimer(RoundTimer[0]);
		RoundTimer[0] = CreateTimer(242.9, RoundEndTime);
		return Plugin_Continue;
	}		
	return Plugin_Continue;
}

MakeVIP()
{

	OldVIPClient = VIPClient;
	VIPClient = GetRandomPlayer(3);
	if(VIPWin)
		GiveVIPWeapons();
	VIPArmorCount = 200.0;
	if(VIPClient == -1)
	{
		PrintToChatAll("\x03[DG VIP] \x01No VIP could be made");
		VIPMade = false;

	}
	else if(VIPClient > 0 && IsClientInGame(VIPClient))
	{
		SaveVIPWeapons();
		VIPMade = true;
		//GetClientModel(VIPClient,OldVIPSkin, sizeof(OldVIPSkin));
		ServerCommand("cs_make_vip %d",VIPClient);
		SetEntProp(VIPClient, Prop_Send, "m_bHasHelmet", 1, 1);
		new String:name[281];
		GetClientName(VIPClient, name, sizeof(name));
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 3)
			{
				PrintToChat(i,"\x03[DG VIP] \x01%s has been made the VIP protect him.",name);
				EmitSoundToClient(i, "vip.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,NULL_VECTOR,NULL_VECTOR,true,0.0);
			}
		}		
		ResetVIPWeapon();
		PrintToChat(VIPClient,"\x03[DG VIP] \x01You are given 200 armor but are only allowed to use the usp.");
		SetEntData(VIPClient, g_iArmorOffset, 100);
		SDKCall(hSetModel,VIPClient, "models/player/vip/small2/vip.mdl");
		RefreshClientWeapons(VIPClient);
	}
	VIPWin = false;
}

public Action:Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winningTeam = GetEventInt(event, "winner");

	KillTimer(RoundTimer[0]);
	RoundTimer[0] = INVALID_HANDLE;
	
	if(VRoundEnd)
		return Plugin_Stop;
	
	VRoundEnd = true;
	if(winningTeam == 3)
		VIPWin = true;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
	}
	
	return Plugin_Continue;
}

public Action:RoundEndTime(Handle:timer)
{
	if(!VRoundEnd)
	{
		SDKCall(g_hToolsTerminateRound, 5.0, ROUNDEND_VIP_NOT_ESCAPED);
		SetTeamCash(2,3000);
		Addtoscore(2);
		RoundTimer[0] = INVALID_HANDLE;
		VRoundEnd = true;
		VIPWin = false;
	}
} 

public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == VIPClient)
	{		
		//new ArmorLost = GetEventInt(event, "dmg_armor");
		//VIPArmorCount = VIPArmorCount-ArmorLost;
	}
}


public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackclient = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(client == VIPClient)
	{
		if(!VRoundEnd)
		{
			SDKCall(g_hToolsTerminateRound, 5.0, ROUNDEND_VIP_ASSASSINATED);
			LogEventToGame("AssassinatedTheVIP", attackclient);
			SetTeamCash(2,3200);
			Addtoscore(2);
			VRoundEnd = true;
			VIPWin = false;
			KillTimer(RoundTimer[0]);
			RoundTimer[0] = INVALID_HANDLE;
		}
	}
}

public Action:BuyBlock(client, args)
{
	if(client == VIPClient)
	{
		PrintToChat(VIPClient,"\x03[DG VIP] \x01You can not buy as the VIP.");
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}

GetRandomPlayer(team)
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (GetClientTeam(i) == team))
			clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
} 

ResetVIPWeapon()
{
	new ent1 = GetPlayerWeaponSlot(VIPClient, 1);
	if (ent1 != -1) 
    {
        RemovePlayerItem(VIPClient, ent1);
	}
	new ent0 = GetPlayerWeaponSlot(VIPClient, 0);
	if (ent0 != -1) 
    {
        RemovePlayerItem(VIPClient, ent0);
    }
	new ent3 = GetPlayerWeaponSlot(VIPClient, 3);
	if (ent3 != -1) 
    {
        RemovePlayerItem(VIPClient, ent3);
    }
	GivePlayerItem(VIPClient, "weapon_usp"); 
}

bool:IsinZone1(Float:vvec[])
{

	if(vvec[0] >= VIPZone1[0] && vvec[0] <= VIPZone1[1] && vvec[1] >= VIPZone1[2] && vvec[1] <= VIPZone1[3] && vvec[2] >= VIPZone1[4]  && vvec[2] <= VIPZone1[5])
		return true;
		
	return false;
}

bool:IsinZone2(Float:vvec[])
{

	if(vvec[0] >= VIPZone2[0] && vvec[0] <= VIPZone2[1] && vvec[1] >= VIPZone2[2] && vvec[1] <= VIPZone2[3] && vvec[2] >= VIPZone2[4]  && vvec[2] <= VIPZone2[5])
		return true;
		
	return false;
}

bool:IsinZone3(Float:vvec[])
{

	if(vvec[0] >= VIPZone3[0] && vvec[0] <= VIPZone3[1] && vvec[1] >= VIPZone3[2] && vvec[1] <= VIPZone3[3] && vvec[2] >= VIPZone3[4]  && vvec[2] <= VIPZone3[5])
		return true;
		
	return false;
}

public Action:CreateZone1(client, args)
{
	if(client != 0)
	{
		ReplyToCommand(client, "FUCK YOU!");
		return Plugin_Handled;
	}
//            x1       y1          z1          x2       y2         z2
	new String:point1[6], String:point2[6], String:point3[6],String:point4[6],String:point5[6],String:point6[6];
	new Float:point11, Float:point12, Float:point13,Float:point14,Float:point15,Float:point16;
	GetCmdArg(1, point1, sizeof(point1));
	GetCmdArg(2, point2, sizeof(point2));
	GetCmdArg(3, point3, sizeof(point3));
	GetCmdArg(4, point4, sizeof(point4));
	GetCmdArg(5, point5, sizeof(point5));
	GetCmdArg(6, point6, sizeof(point6));
	point11 = StringToFloat(point1);
	point12 = StringToFloat(point2);
	point13 = StringToFloat(point3);
	point14 = StringToFloat(point4);
	point15 = StringToFloat(point5);
	point16 = StringToFloat(point6);
	
	if(point11 < point14)
	{
		VIPZone1[0] = point11;
		VIPZone1[1] = point14;
	}
	else if (point11 > point14)
	{
		VIPZone1[0] = point14;
		VIPZone1[1] = point11;
	}
	if(point12 < point15)
	{
		VIPZone1[2] = point12;
		VIPZone1[3] = point15;
	}
	else if(point12 > point15)
	{
		VIPZone1[2] = point15;
		VIPZone1[3] = point12;
	}
	if(point13 < point16)
	{
		VIPZone1[4] = point13;
		VIPZone1[5] = point16;	
	}
	else if(point13 > point16)
	{
		VIPZone1[4] = point16;
		VIPZone1[5] = point13;
	}
	return Plugin_Continue;	
}

public Action:CreateZone2(client, args)
{
	if(client != 0)
	{
		ReplyToCommand(client, "FUCK YOU!");
		return Plugin_Handled;
	}
	if(!LockZones)
	{
		return Plugin_Handled;
	}
	//              x1       y1          z1          x2       y2         z2
	new String:point1[6], String:point2[6], String:point3[6],String:point4[6],String:point5[6],String:point6[6];
	new Float:point11, Float:point12, Float:point13,Float:point14,Float:point15,Float:point16;
	GetCmdArg(1, point1, sizeof(point1));
	GetCmdArg(2, point2, sizeof(point2));
	GetCmdArg(3, point3, sizeof(point3));
	GetCmdArg(4, point4, sizeof(point4));
	GetCmdArg(5, point5, sizeof(point5));
	GetCmdArg(6, point6, sizeof(point6));
	point11 = StringToFloat(point1);
	point12 = StringToFloat(point2);
	point13 = StringToFloat(point3);
	point14 = StringToFloat(point4);
	point15 = StringToFloat(point5);
	point16 = StringToFloat(point6);
	
	if(point11 < point14)
	{
		VIPZone2[0] = point11;
		VIPZone2[1] = point14;
	}
	else if (point11 > point14)
	{
		VIPZone2[0] = point14;
		VIPZone2[1] = point11;
	}
	if(point12 < point15)
	{
		VIPZone2[2] = point12;
		VIPZone2[3] = point15;
	}
	else if(point12 > point15)
	{
		VIPZone2[2] = point15;
		VIPZone2[3] = point12;
	}
	if(point13 < point16)
	{
		VIPZone2[4] = point13;
		VIPZone2[5] = point16;	
	}
	else if(point13 > point16)
	{
		VIPZone2[4] = point16;
		VIPZone2[5] = point13;
	}
	return Plugin_Continue;
}

public Action:CreateZone3(client, args)
{
	if(client != 0)
	{
		ReplyToCommand(client, "FUCK YOU!");
		return Plugin_Handled;
	}
	if(!LockZones)
	{
		return Plugin_Handled;
	}
	//              x1       y1          z1          x2       y2         z2
	new String:point1[6], String:point2[6], String:point3[6],String:point4[6],String:point5[6],String:point6[6];
	new Float:point11, Float:point12, Float:point13,Float:point14,Float:point15,Float:point16;
	GetCmdArg(1, point1, sizeof(point1));
	GetCmdArg(2, point2, sizeof(point2));
	GetCmdArg(3, point3, sizeof(point3));
	GetCmdArg(4, point4, sizeof(point4));
	GetCmdArg(5, point5, sizeof(point5));
	GetCmdArg(6, point6, sizeof(point6));
	point11 = StringToFloat(point1);
	point12 = StringToFloat(point2);
	point13 = StringToFloat(point3);
	point14 = StringToFloat(point4);
	point15 = StringToFloat(point5);
	point16 = StringToFloat(point6);
	
	if(point11 < point14)
	{
		VIPZone3[0] = point11;
		VIPZone3[1] = point14;
	}
	else if (point11 > point14)
	{
		VIPZone3[0] = point14;
		VIPZone3[1] = point11;
	}
	if(point12 < point15)
	{
		VIPZone3[2] = point12;
		VIPZone3[3] = point15;
	}
	else if(point12 > point15)
	{
		VIPZone3[2] = point15;
		VIPZone3[3] = point12;
	}
	if(point13 < point16)
	{
		VIPZone3[4] = point13;
		VIPZone3[5] = point16;	
	}
	else if(point13 > point16)
	{
		VIPZone3[4] = point16;
		VIPZone3[5] = point13;
	}
	return Plugin_Continue;
}
SetTeamCash(team,cash)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new original = GetEntProp(i, Prop_Send, "m_iAccount");
			new amount = original + cash;
			if (GetClientTeam(i) == team)
			{
				SetEntData(i, g_iAccount, amount);
			}
			else
			{
				amount = amount/3;
				SetEntData(i, g_iAccount, amount);
			}
		}
	}
}


LogEventToGame(const String:event[], client)
{
	decl String:Name[64], String:Auth[64];

	GetClientName(client, Name, sizeof(Name));
	GetClientAuthString(client, Auth, sizeof(Auth));
	new team = GetClientTeam(client), UserId = GetClientUserId(client);
	LogToGame("\"%s<%d><%s><%s>\" triggered \"%s\"", Name, UserId, Auth, (team == 2) ? "TERRORIST" : "CT", event);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{

	if(victim == VIPClient)
	{
		if(VIPArmorCount >= 150)
		{
			VIPArmorCount -= damage*0.10;
			damage /= 2;
		}
		else if(VIPArmorCount <= 50)
		{
			VIPArmorCount -= damage*0.10;
			damage /= 1;
		}
		else 
		{
			VIPArmorCount -= damage*0.10;
			damage /= 1.5;
		}
			
		return Plugin_Changed; 	   
	}
	return Plugin_Continue;
}   

SaveVIPWeapons()
{
	decl String:classname[32];

		new weapon = GetPlayerWeaponSlot(VIPClient, 0);
		if (weapon != -1)		 
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			strcopy(VIPWeapons[0], sizeof(VIPWeapons), classname);
		}
		
		weapon = GetPlayerWeaponSlot(VIPClient, 1);
		if (weapon != -1)
		{		
			GetEdictClassname(weapon, classname, sizeof(classname));
			strcopy(VIPWeapons[1], sizeof(VIPWeapons), classname);
		}
		//RemovePlayerItem(VIPClient, weapon);
		// GivePlayerItem(VIPClient, classname);

}

Addtoscore(index)
{
	new tempscore = GetTeamScore(index);
	new team = MAXPLAYERS + 1;
	
	team = FindEntityByClassname(-1, "cs_team_manager");
	
	while (team != -1)
	{
		if (GetEntProp(team, Prop_Send, "m_iTeamNum", 1) == index)
		{
			SetEntProp(team, Prop_Send, "m_iScore", tempscore + 1, 4);
			ChangeEdictState(team, m_iScore);
			
		}
		team = FindEntityByClassname(team, "cs_team_manager");
	}
	
}

public Action:showhelp(client, args)
{
 new Handle:panel = CreatePanel();
 SetPanelTitle(panel, "DG VIP Help");
 DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
 DrawPanelText(panel, "Welcome to the DG VIP server, VIP is vary simple");
 DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
 DrawPanelText(panel, "One members of the CT team is randomly selected and made the VIP");
 DrawPanelText(panel, "He is given 200 armor but may only use the usp");
 DrawPanelText(panel, "It is the CT teams job to escort the VIP safely to the escape zone");
 DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
 DrawPanelText(panel, "It is the Terrorist team's goal to eliminate the VIP");
 DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
 DrawPanelText(panel, "The ways to end the round are:");
 DrawPanelText(panel, "VIP escapes,VIP is killed,T team is killed,CT team is killed,or the VIP fails to escape");
 DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
 DrawPanelItem(panel, "Close");
 SendPanelToClient(panel, client, PanelHandler, 120);
 
 CloseHandle(panel);
 
 return Plugin_Continue;
 }
public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
 if (action == MenuAction_Select)
 {
    if (param2 == 1)
      {
       //   PrintToConsole(param1, "You have agreed to our rules and conditions.  Enjoy your stay.", param2)
      } else {
       //   PrintToConsole(param1, "You did not agree to our rules and conditions.  Have a nice day.", param2)
      }
 } else if (action == MenuAction_Cancel) {
 // PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2)
 }
}