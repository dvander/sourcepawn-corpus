#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define ATTACH_NONE	0
#define ATTACH_NORMAL	1
#define ATTACH_HEAD	2

#define DONATOR_SPRITE_VTF 	"materials/custom/donator2.vtf"
#define DONATOR_SPRITE_VMT 	"materials/custom/donator2.vmt"

#undef REQUIRE_EXTENSIONS
#tryinclude <donator>
#if defined _donator_included_

#define PLUGIN_VERSION	"1.3d"

#tryinclude <colors>

enum _:tColors
{
	tColor_Black,
	tColor_White,
	tColor_Orange,
	tColor_Yellow,
	tColor_Green,
	tColor_Blue,
	tColor_Red,
	tColor_Lime,
	tColor_Aqua,
	tColor_Grey,
	tColor_Purple,
	tColor_Max
}

new const String:szColorValues[tColors-1][11] =
{
	"0 0 0",
	"255 255 255",
	"255 102 0",
	"255 255 0",
	"0 128 0",
	"0 0 255",
	"255 0 0",
	"0 255 0",
	"0 255 255",
	"128 128 128",
	"128 0 128"
};

new const String:szColorNames[tColors-1][11] =
{
	"Black",
	"White",
	"Orange",
	"Yellow",
	"Green",
	"Blue",
	"Red",
	"Lime",
	"Aqua",
	"Grey",
	"Purple"
};

new Handle:g_HudSync = INVALID_HANDLE;
new Handle:g_TagColorCookie = INVALID_HANDLE;

new g_iTagColor[MAXPLAYERS + 1][4];
#else
#define PLUGIN_VERSION	"1.3a"
#endif

new Handle:g_DonatorCvar = INVALID_HANDLE;
new Handle:g_DuringSetupCvar = INVALID_HANDLE;

new g_EntList[MAXPLAYERS + 1];
new g_bIsDonator[MAXPLAYERS + 1];
new bool:g_bDisplaySprites;
new bool:g_bDonatorLoaded;
new gVelocityOffset;

public Plugin:myinfo = 
{
	name = "Donator Recognition",
	author = "Nut",
	description = "Give donators the recognition they deserve.",
	version = PLUGIN_VERSION,
	url = "http://www.necrophix.com"
}

/**
 * Description: Function to determine game/mod type
 */
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
    {
        if (GameType == undetected)
        {
            new String:modname[30];
            GetGameFolderName(modname, sizeof(modname));
            if (StrEqual(modname,"cstrike",false))
                GameType=cstrike;
            else if (StrEqual(modname,"tf",false)) 
                GameType=tf2;
            else if (StrEqual(modname,"dod",false)) 
                GameType=dod;
            else if (StrEqual(modname,"hl2mp",false)) 
                GameType=hl2mp;
            else if (StrEqual(modname,"Insurgency",false)) 
                GameType=insurgency;
            else if (StrEqual(modname,"left4dead", false)) 
                GameType=l4d;
            else if (StrEqual(modname,"left4dead2", false)) 
                GameType=l4d2;
            else if (StrEqual(modname,"zps",false)) 
                GameType=zps;
            else
                GameType=other_game;
        }
        return GameType;
    }
#endif

#tryinclude <entlimit>
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
	new max = GetMaxEntities();
	new count = GetEntityCount();
	new remaining = max - count;
	if (remaining <= warn)
	{
	    if (count <= critical)
	    {
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

		if (client > 0)
		{
		    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
				   count, max, remaining, message);
		}
	    }
	    else
	    {
		PrintToServer("Caution: Entity count is getting high!");
		LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

		if (client > 0)
		{
		    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
				   count, max, remaining, message);
		}
	    }
	    return count;
	}
	else
	    return 0;
    }
#endif

public OnPluginStart()
{
	HookEventEx("player_death", event_player_death, EventHookMode_Post);
	HookEventEx("player_spawn", event_player_spawn, EventHookMode_Post);

	if (GetGameType() == tf2)
	{
		HookEventEx("teamplay_round_start", RoundStart, EventHookMode_PostNoCopy);
		HookEventEx("arena_round_start", SetupFinished, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_setup_finished", SetupFinished, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_round_active", RoundActive, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_round_win", RoundEnd, EventHookMode_Post);
		HookEventEx("arena_win_panel", RoundEnd, EventHookMode_Post);
	}
	else if (GameType == dod)
	{
		HookEventEx("dod_round_start", RoundStart, EventHookMode_PostNoCopy);
		HookEventEx("dod_round_active", SetupFinished, EventHookMode_PostNoCopy);
		HookEventEx("dod_round_win", RoundEnd, EventHookMode_Post);
	}
	else if (GameType == cstrike)
	{
		HookEventEx("round_start", RoundStart, EventHookMode_PostNoCopy);
		HookEventEx("round_active", SetupFinished, EventHookMode_PostNoCopy);
		HookEventEx("round_end", RoundEnd, EventHookMode_Post);
	}

	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	g_DuringSetupCvar = CreateConVar("basicdonator_during_setup", "1", "Donator Recognition During Setup?", FCVAR_PLUGIN);

	#if defined _donator_included_
		CreateConVar("basicdonator_recog_v", PLUGIN_VERSION, "Donator Recognition Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

		g_DonatorCvar = CreateConVar("donator_admin_flag", "", "Optional Admin flag that indicates a donator");

		g_HudSync = CreateHudSynchronizer();
		g_TagColorCookie = RegClientCookie("donator_tagcolor", "Chat color for donators.", CookieAccess_Private);
	
		AddCommandListener(SayCallback, "donator_tag");
		AddCommandListener(SayCallback, "donator_tagcolor");
	#else
		CreateConVar("basicdonator_recog_v", PLUGIN_VERSION, "Donator Recognition (Admin flag edition) Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

		g_DonatorCvar = CreateConVar("donator_admin_flag", "a", "Admin flag that indicates a donator");
	#endif
}

public OnMapStart()
{
	AddFileToDownloadsTable(DONATOR_SPRITE_VMT);
	PrecacheGeneric(DONATOR_SPRITE_VMT, true);

	AddFileToDownloadsTable(DONATOR_SPRITE_VTF);
	PrecacheGeneric(DONATOR_SPRITE_VTF, true);
}

public OnClientDisconnect(client)
{
	g_bIsDonator[client] = false;
	KillSprite(client);
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
		
		if (g_bIsDonator[i])
			CreateSprite(i, DONATOR_SPRITE_VMT, 25.0);
	}
	g_bDisplaySprites = true;
}

public SetupFinished(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		//if (!IsClientInGame(i)) continue;
		//if (!g_bIsDonator[i]) continue;
		KillSprite(i);
	}
	g_bDisplaySprites = false;
}

public RoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_DuringSetupCvar))
	{
		new timer = FindEntityByClassname(MaxClients+1, "team_round_timer");
		if (timer > 0 && GetEntProp(timer, Prop_Send, "m_nState") == 0)
		{
			new m_nSetupTimeLength = GetEntProp(timer, Prop_Send, "m_nSetupTimeLength");
			if (m_nSetupTimeLength > 0)
			{
				// Create a timer in case the setup isn't real
				// (such as the last stage of plr_pipeline)
				CreateTimer(float(m_nSetupTimeLength), SetupOver);
				return;
			}
		}
	}

	SetupFinished(event, name, dontBroadcast);
}

public Action:SetupOver(Handle:timer, any:client)
{
	if (g_bDisplaySprites)
		SetupFinished(INVALID_HANDLE, "SetupOver", false);
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
		
		if (g_bIsDonator[i])
			CreateSprite(i, DONATOR_SPRITE_VMT, 25.0);
	}
	g_bDisplaySprites = true;
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bDisplaySprites && g_bIsDonator[client])
		CreateSprite(client, DONATOR_SPRITE_VMT, 25.0);
	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if(!g_bDisplaySprites) return Plugin_Continue;
	KillSprite(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

#if defined _donator_included_
public OnAllPluginsLoaded()
{
	g_bDonatorLoaded = LibraryExists("donator");
	if (g_bDonatorLoaded)
	{
		DonatorMenu_RegisterItem("Change Donator Tag", ChangeTagCallback);
		DonatorMenu_RegisterItem("Change Tag Color", ChangeTagColorCallback);
	}
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "donator"))
    {
        if (!g_bDonatorLoaded)
        {
	    DonatorMenu_RegisterItem("Change Donator Tag", ChangeTagCallback);
	    DonatorMenu_RegisterItem("Change Tag Color", ChangeTagColorCallback);
            g_bDonatorLoaded = true;
        }
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "donator"))
        g_bDonatorLoaded = false;
}

public OnDonatorConnect(client)
{
	g_bIsDonator[client] = true;
	g_iTagColor[client] = {255, 255, 255, 255};
	
	decl String:szBuffer[256];
	if (AreClientCookiesCached(client))
	{
		GetClientCookie(client, g_TagColorCookie, szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) > 0)
		{
			decl String:szTmp[3][16];
			ExplodeString(szBuffer, " ", szTmp, 3, sizeof(szTmp[]));
			g_iTagColor[client][0] = StringToInt(szTmp[0]); 
			g_iTagColor[client][1] = StringToInt(szTmp[1]);
			g_iTagColor[client][2] = StringToInt(szTmp[2]);
		}
	}
	
	GetDonatorMessage(client, szBuffer, sizeof(szBuffer));
	ShowDonatorMessage(client, szBuffer);
}

public Action:SayCallback(client, const String:command[], argc)
{
	if(!client) return Plugin_Continue;
	if(!g_bDonatorLoaded) return Plugin_Continue;
	if (!g_bIsDonator[client]) return Plugin_Continue;

	decl String:szArg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);

	if (StrEqual(command, "donator_tag", true))
	{
		decl String:szTmp[256];
		if (strlen(szArg) < 1)
		{
			GetDonatorMessage(client, szTmp, sizeof(szTmp));
			ReplyToCommand(client, "[SM] Your current tag is: %s", szTmp);
		}
		else
		{
			#if defined _colors_included
			CPrintToChat(client, "[SM] You have sucessfully changed your tag to: {olive}%s{default}", szArg);
			#else
			PrintToChat(client, "[SM] You have sucessfully changed your tag to: %s", szArg);
			#endif
			SetDonatorMessage(client, szArg);
		}
	}
	else if (StrEqual(command, "donator_tagcolor", true))
	{
		decl String:szTmp[3][16];
		if (strlen(szArg) < 1)
		{
			GetClientCookie(client, g_TagColorCookie, szTmp[0], sizeof(szTmp[]));
			ReplyToCommand(client, "[SM] Your current tag color is: %s", szTmp[0]);
		}
		else
		{
			ExplodeString(szArg, " ", szTmp, 3, sizeof(szTmp[]));
			ReplyToCommand(client, "[SM] You have sucessfully changed your color to %s", szArg);
			SetClientCookie(client, g_TagColorCookie, szArg);
		}
	}
	return Plugin_Handled;
}

public ShowDonatorMessage(client, String:message[])
{
	SetHudTextParamsEx(-1.0, 0.22, 4.0, g_iTagColor[client], {0, 0, 0, 255}, 1, 5.0, 0.15, 0.15);
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			ShowSyncHudText(i, g_HudSync, message);
}

public DonatorMenu:ChangeTagCallback(client) Panel_ChangeTag(client);
public DonatorMenu:ChangeTagColorCallback(client) Panel_ChangeTagColor(client);

public Action:Panel_ChangeTag(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Donator: Change Tag:");
	
	new String:szBuffer[256];
	GetDonatorMessage(client, szBuffer, sizeof(szBuffer));
	DrawPanelItem(panel, "Your current donator tag is:", ITEMDRAW_DEFAULT);
	DrawPanelItem(panel, szBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "space", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "Type the following in the console to change your tag:", ITEMDRAW_CONTROL);
	DrawPanelItem(panel, "donator_tag \"YOUR TAG GOES HERE\"", ITEMDRAW_RAWLINE);
	
	SendPanelToClient(panel, client, PanelHandlerBlank, 20);
	CloseHandle(panel);
}

public Action:Panel_ChangeTagColor(client)
{
	new Handle:menu = CreateMenu(TagColorMenuSelected);
	SetMenuTitle(menu,"Donator: Change Tag Color:");

	decl String:szItem[4];
	for (new i = 0; i < tColor_Max; i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		AddMenuItem(menu, szItem, szColorNames[i], ITEMDRAW_DEFAULT);
	}
		
	DisplayMenu(menu, client, 20);
}

public TagColorMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:szTmp[3][16], iColor[4];
			
			ExplodeString(szColorValues[iSelected], " ", szTmp, 3, sizeof(szTmp[]));
			iColor[0] = StringToInt(szTmp[0]); 
			iColor[1] = StringToInt(szTmp[1]);
			iColor[2] = StringToInt(szTmp[2]);
			iColor[3] = 255;
			
			SetHudTextParamsEx(-1.0, 0.22, 4.0, iColor, {0, 0, 0, 255}, 1, 5.0, 0.15, 0.15);
			ShowSyncHudText(param1, g_HudSync, "This is your new tag color.");
			SetClientCookie(param1, g_TagColorCookie, szColorValues[iSelected]);
		}

		case MenuAction_End: CloseHandle(menu);
	}
}

public PanelHandlerBlank(Handle:menu, MenuAction:action, client, param2) {}

public OnPostDonatorCheck(client)
{
	decl String:adminFlag[2];
	GetConVarString(g_DonatorCvar, adminFlag, sizeof(adminFlag));

	if (adminFlag[0])
	{
		new AdminFlag:flag;
		if (FindFlagByChar(adminFlag[0], flag))
		{
			new AdminId:aid = GetUserAdmin(client);
			if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, flag, Access_Effective))
				g_bIsDonator[client] = true;
		}
	}
}
#endif

public OnClientPostAdminCheck(client)
{
	if (!g_bDonatorLoaded)
	{
		decl String:adminFlag[2];
		GetConVarString(g_DonatorCvar, adminFlag, sizeof(adminFlag));

		if (adminFlag[0])
		{
			new AdminFlag:flag;
			if (FindFlagByChar(adminFlag[0], flag))
			{
				new AdminId:aid = GetUserAdmin(client);
				g_bIsDonator[client] = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, flag, Access_Effective);
			}
			else
			{
				LogError("Admin flag %c not found", adminFlag[0]);
				g_bIsDonator[client] = false;
			}
		}
	}
}

//--------------------------------------------------------------------------------------------------

stock CreateSprite(client, String:sprite[], Float:offset)
{
	if (EntRefToEntIndex(g_EntList[client]) < 1 &&
	    !IsEntLimitReached(.client=client,.message="Unable to create donator sprite"))
	{
		new ent = CreateEntityByName("env_sprite_oriented");
		if (ent > 0 && IsValidEntity(ent))
		{
			DispatchKeyValue(ent, "model", sprite);
			DispatchKeyValue(ent, "classname", "env_sprite_oriented");
			DispatchKeyValue(ent, "spawnflags", "1");
			DispatchKeyValue(ent, "scale", "0.1");
			DispatchKeyValue(ent, "rendermode", "1");
			DispatchKeyValue(ent, "rendercolor", "255 255 255");
			DispatchKeyValue(ent, "targetname", "donator_spr");
			DispatchSpawn(ent);

			new Float:vOrigin[3];
			if (GameType == tf2)
				GetClientEyePosition(client, vOrigin);
			else
				GetClientAbsOrigin(client, vOrigin);

			vOrigin[2] += offset;

			TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);
			g_EntList[client] = EntIndexToEntRef(ent);

			if (GameType == tf2)
				SetEntityMoveType(ent, MOVETYPE_NOCLIP);
			else
			{
				new String:szTemp[64]; 
				Format(szTemp, sizeof(szTemp), "client%i", client);
				DispatchKeyValue(client, "targetname", szTemp);
				DispatchKeyValue(ent, "parentname", szTemp);

				SetVariantString(szTemp);
				AcceptEntityInput(ent, "SetParent", ent, ent, 0);
				SetVariantString("head");
				AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
			}
		}
	}
}

stock KillSprite(client)
{
	new ref = g_EntList[client];
	if (ref != 0)
	{
		new ent = EntRefToEntIndex(ref);
		if (ent > 0 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "kill");
		}
		g_EntList[client] = 0;
	}
}

// terribad (patent pending)
// Hack around new limitation of effectivly no longer being
// able to parent entities to players, so fake it.
public OnGameFrame()
{
    if (GameType == tf2)
    {
	    for(new i = 1; i <= MaxClients; i++)
	    {
		    new ref = g_EntList[i];
		    if (ref != 0)
		    {
			    new ent = EntRefToEntIndex(ref);
			    if (ent > 0)// && IsClientInGame(i))
			    {
				    new Float:vOrigin[3];
				    GetClientEyePosition(i, vOrigin);
				    vOrigin[2] += 25.0;

				    new Float:vVelocity[3];
				    GetEntDataVector(i, gVelocityOffset, vVelocity);

				    TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
			    }
		    }
	    }
    }
}

