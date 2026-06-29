#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 		"1.0.0"
//CUSTOMMODEL 		"models/props/slow/spiegelkugel/slow_spiegelkugel.mdl"
//ZOffset 42.0
//sm_disco_rotation 0.0 11.25 0.0
#define MAX_SONGS 		256
new String:song_name[MAX_SONGS][128];
new String:song_path[MAX_SONGS][128];
//new song_type[MAX_SONGS];

new DiscoBall = -1;
new DiscoColor = 0;
new Handle:DiscoTimer = INVALID_HANDLE;
//Cvars
new Handle:cCustomModel = INVALID_HANDLE;
new String:sCustomModel[128];
new Handle:cZOffset = INVALID_HANDLE;
new Float:fZOffset = 0.0;
new Handle:cRotation = INVALID_HANDLE;
new Float:fRotation[3] = {11.25,...};


new const g_DefaultColors_c[6][3] = { {255,0,0}, {0,255,0}, {0,0,255}, {255,255,0}, {0,255,255}, {255,0,255} };
new const String:g_DefaultColors_p[6][] = { "materials/sprites/redglow1.vmt", "materials/sprites/greenglow1.vmt", "materials/sprites/blueglow1.vmt", "materials/sprites/yellowglow1.vmt", "materials/sprites/glow1.vmt", "materials/sprites/purpleglow1.vmt" };
new g_DefaultColors_s[6];
new g_sprite;

new count;

public Plugin:myinfo =
{
	name = "DISCO!!!",
	author = "MitchDizzle_",
	description = "Mitch's Disco Mod!",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=180520"
}
public OnPluginStart()
{
	CreateConVar("sm_disco_version", PLUGIN_VERSION, "Disco Mod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cCustomModel = CreateConVar("sm_disco_custommodel", "models/roller_spikes.mdl", "Path to the Disco ball model.");
	
	cZOffset = CreateConVar("sm_disco_zoffset", "0.0", "Offset on the Z global vector for the lights.");
	
	cRotation = CreateConVar("sm_disco_rotation", "11.25 0.0 11.25", "Offset on the Z global vector for the lights.");
	
	GetCvars();
	
	//HookConVarChange(g_hcvarCustomModel, ConVarChanged_MDL);
	AutoExecConfig();
	
	
	RegAdminCmd("sm_discomenu", Command_Disco, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_disco_reloadconfig", Command_ReloadDisco, ADMFLAG_ROOT);
	RegConsoleCmd("say", Command_StopMusic);
	RegConsoleCmd("say_team", Command_StopMusic);
	
	LoadMusicconfig();
	HookEvent("round_end", RoundEnd);
}
GetCvars()
{
	GetConVarString(cCustomModel, sCustomModel, sizeof(sCustomModel));
	PrecacheModel(sCustomModel);
	fZOffset = GetConVarFloat(cZOffset);
	new String:BuffStr[24];
	GetConVarString(cRotation, BuffStr, sizeof(BuffStr));
	new String:items[3][8];
	ExplodeString(BuffStr, " ", items, 3, 8);
	fRotation[0] = StringToFloat(items[0]);
	fRotation[1] = StringToFloat(items[1]);
	fRotation[2] = StringToFloat(items[2]);
}
public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(IsDiscoBall(DiscoBall))
		DiscoBall = -1;

	if(count != 0)
	{
		for(new x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				DoUrl(x, "about:blank");
			}
		}
	}
}
public OnMapStart()
{
	GetCvars();
	g_sprite = PrecacheModel("materials/sprites/laser.vmt", true);
	PrecacheModel(sCustomModel, true);
	for(new i = 0; i <= 5; i++)
		g_DefaultColors_s[i] = PrecacheModel(g_DefaultColors_p[i],true);
		
	if(IsDiscoBall(DiscoBall))
	{
		DiscoBall = -1;
	}
}
public OnPluginEnd()
{
	if(IsDiscoBall(DiscoBall))
	{
		AcceptEntityInput( DiscoBall , "Kill" );
		DiscoBall = -1;
	}
}

public Action:Command_StopMusic(client, args)
{
	// Check to see if client is valid
	if(!(( 1 <= client <= MaxClients ) && IsClientInGame(client))) return Plugin_Continue;

	
	decl String:strMessage[128];
	GetCmdArgString(strMessage, sizeof(strMessage));
	
	// Check for chat triggers
	new startidx = 0;
	if(strMessage[0] == '"')
	{
		startidx = 1;
		new len = strlen(strMessage);
		
		if(strMessage[len-1] == '"') strMessage[len-1] = '\0';
	}
	
	new bool:cond = false;
	if(StrEqual("stopmusic", strMessage[startidx], false)) cond = true;
	
	if(!cond) return Plugin_Continue;
	else DoUrl(client, "about:blank");
	return Plugin_Continue;
}
stock LoadMusicconfig()
{
	count = 0;
	new Handle:kvs = CreateKeyValues("MusicConfig");
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/musicconfig.cfg");
	if(!FileToKeyValues(kvs, sPaths))
	{
		CloseHandle(kvs);
		return;
	}

	if (!KvGotoFirstSubKey(kvs))
	{
		CloseHandle(kvs);
		return;
	}
	count = 1;
	new ocount = -1;
	do
	{
		if(count != ocount)
		{
			KvGetSectionName(kvs, song_name[count], 128);
			KvGetString(kvs, "path", song_path[count], 128);
			ocount = count;
			count++;
		}
	} while (KvGotoNextKey(kvs));
	count--;
	CloseHandle(kvs);
	return;
}
public Action:Command_Disco ( client , args )
{
	Void_Menu_Disco(client);
	return Plugin_Handled;
}
public Action:Command_ReloadDisco ( client , args )
{
	LoadMusicconfig();
	GetCvars();
	PrintToChat(client, "\x03[\x04Disco\x03]\x01 The config has been reloaded!");
	
	return Plugin_Handled;
}

stock bool:IsDiscoBall(Ent=-1)
{
	if(Ent != -1)
	{
		if(IsValidEdict(Ent) && IsValidEntity(Ent) && IsEntNetworkable(Ent))
		{
			decl String:ClassName[255];
			GetEdictClassname(Ent, ClassName, 255);
			if(StrEqual(ClassName, "disco_ball"))
			{
				return (true);
			}
		}
	}
	return (false);
}
StartStopDisco( client,  Float:Pos[3] , songindex = 0 )
{
	if(IsDiscoBall(DiscoBall))
	{
		AcceptEntityInput( DiscoBall , "Kill" );
		DiscoBall = -1;
		DiscoTimer = INVALID_HANDLE;
		PrintToChatAll("\x03[\x04Disco\x03]\x05 %N\x01 has stopped the disco!", client);
		if(count != 0)
		{
			for(new x = 1; x <= MaxClients; x++)
			{
				if(IsClientInGame(x))
				{
					DoUrl(x, "about:blank");
				}
			}
		}
	}
	else
	{
		DiscoBall =  CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(DiscoBall, "classname", "disco_ball");
		DispatchKeyValue(DiscoBall, "model", sCustomModel );
		DispatchKeyValue(DiscoBall, "solid", "0");
		DispatchSpawn( DiscoBall );
		TeleportEntity( DiscoBall, Pos, NULL_VECTOR, NULL_VECTOR );
		PrintToChatAll("\x03[\x04Disco\x03]\x05 %N\x01 has started the disco!!", client);
		if(songindex!=0)
		{
			for(new x = 1; x <= MaxClients; x++)
			{
				if(IsClientInGame(x))
				{
					DoUrl(x, song_path[songindex]);
				}
			}
			PrintToChatAll("\x03[\x04Disco\x03]\x01 Song: \x05%s\x01.", song_name[songindex]);
			PrintToChatAll("\x03[\x04Disco\x03]\x01 To disable the song, type \x05stopmusic\x01 in chat.");
		}

		DiscoColor = 0;
		DiscoTimer = CreateTimer(0.1, Timer_DiscoUpdate, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_DiscoUpdate(Handle:timer)
{
	if(IsDiscoBall(DiscoBall))
	{
		SetEntityRenderColor(DiscoBall, g_DefaultColors_c[DiscoColor][0], g_DefaultColors_c[DiscoColor][1], g_DefaultColors_c[DiscoColor][2], 255);

		new Float:propangle[3];
		GetEntPropVector(DiscoBall, Prop_Data, "m_angRotation", propangle);
		propangle[0] += fRotation[0];
		propangle[1] += fRotation[1];
		propangle[2] += fRotation[2];
		TeleportEntity(DiscoBall, NULL_VECTOR, propangle, NULL_VECTOR);
		new Float:POS[3];
		new Float:END[3];
		GetEntPropVector(DiscoBall, Prop_Send, "m_vecOrigin", POS);
		if(fZOffset != 0) POS[2] -= fZOffset;
		TE_SetupGlowSprite(POS, g_DefaultColors_s[DiscoColor], 0.1, 2.0, 255);
		TE_SendToAll();
		new Color[4];
		Color[3] = 255;
		new Float:vAngles[3]
		new Handle:trace = INVALID_HANDLE;
		for(new i = 0; i <= 5; i++)
		{
			vAngles[0] = GetRandomFloat( 0.0, 90.0 );
			vAngles[1] = GetRandomFloat(-180.0, 180.0);
			vAngles[2] = 0.0
			trace = TR_TraceRayFilterEx(POS, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(END, trace);
				Color[0] = g_DefaultColors_c[i][0];
				Color[1] = g_DefaultColors_c[i][1];
				Color[2] = g_DefaultColors_c[i][2];
				LaserP(POS, END, Color);
			}
			CloseHandle(trace);
		}
		DiscoColor++;
		if(DiscoColor > 5) DiscoColor = 0;
		return Plugin_Continue;
	}
	DiscoTimer = INVALID_HANDLE;
	return Plugin_Stop;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > MaxClients || !entity);
}
stock LaserP(const Float:start[3], const Float:end[3], const color[4])
{
	TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, 0.1, 3.0, 3.0, 7, 0.0, color, 0);
	TE_SendToAll();
}
DoUrl(client, String:url[128])
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "DISCO");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);
}


//MENUS
Void_Menu_Disco(client, index=0)
{
	new Handle:menu = CreateMenu(Menu_Disco, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(menu, "- Disco -");
	if(!IsDiscoBall(DiscoBall))
		AddMenuItem(menu, "StartDisco", "Start Disco", ITEMDRAW_DEFAULT);
	else
		AddMenuItem(menu, "StopDisco", "Stop Disco", ITEMDRAW_DEFAULT);
	DisplayMenuAtItem(menu, client, index, MENU_TIME_FOREVER);
}

Void_Menu_DiscoSongList(client, index=0)
{
	new Handle:menu = CreateMenu(Menu_DiscoSL, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(menu, "- Disco Song: -");
	decl String:g_sDisplay[128];
	decl String:g_sChoice[128];
	AddMenuItem(menu, "0", "No Song", ITEMDRAW_DEFAULT);
	for(new X = 1; X <= count; X++)
	{
		Format(g_sDisplay, sizeof(g_sDisplay), "%s", song_name[X]);
		Format(g_sChoice, sizeof(g_sChoice), "%i", X);
		AddMenuItem(menu, g_sChoice, g_sDisplay, ITEMDRAW_DEFAULT);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenuAtItem(menu, client, index, MENU_TIME_FOREVER);
}


public Menu_Disco(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			new String:info[130];
			GetMenuItem(menu, param2, info, sizeof(info));
			if(StrEqual("StartDisco", info, false))
			{
				if(count == 0)
				{
					new Float:Pos[3];
					new Float:END[3];
					GetEntPropVector(param1, Prop_Send, "m_vecOrigin", Pos);
					new Float:vAngles[3];
					vAngles[0] = -90.0;
					vAngles[1] = 0.0;
					vAngles[2] = 0.0;
					new Handle:trace = TR_TraceRayFilterEx(Pos, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
					if(TR_DidHit(trace))
					{
						TR_GetEndPosition(END, trace);
					}
					CloseHandle(trace);
					if(GetVectorDistance(Pos, END) > 2048.00)
					{
						Pos[2] += 312.0;
					}
					else
					{
						Pos[0] = END[0];
						Pos[1] = END[1];
						Pos[2] = END[2];
					}
					StartStopDisco(param1, Pos, 0); 
					Void_Menu_Disco(param1);
				}
				else
				{
					Void_Menu_DiscoSongList(param1);
				}
			}
			if(StrEqual("StopDisco", info, false))
			{
				if(IsDiscoBall(DiscoBall))
				{
					AcceptEntityInput( DiscoBall , "Kill" );
					DiscoBall = -1;
				}
				if ( DiscoTimer != INVALID_HANDLE )
				{
					KillTimer( DiscoTimer );
					DiscoTimer = INVALID_HANDLE;
				}
				if(count != 0)
					for(new x = 1; x <= MaxClients; x++)
						if(IsClientInGame(x))
							DoUrl(x, "about:blank");
	
				PrintToChatAll("\x03[\x04Disco\x03]\x05 %N\x01 has stopped the disco!", param1);
				Void_Menu_Disco(param1);
			}
		}
	}
	return;
}
public Menu_DiscoSL(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Void_Menu_Disco(param1);
		case MenuAction_Select:
		{
			new String:info[130];
			GetMenuItem(menu, param2, info, sizeof(info));
			new Float:Pos[3];
			new Float:END[3];
			GetEntPropVector(param1, Prop_Send, "m_vecOrigin", Pos);
			new Float:vAngles[3];
			vAngles[0] = -90.0;
			vAngles[1] = 0.0;
			vAngles[2] = 0.0;
			new Handle:trace = TR_TraceRayFilterEx(Pos, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(END, trace);
			}
			CloseHandle(trace);
			if(GetVectorDistance(Pos, END) > 2048.00)
			{
				Pos[2] += 312.0;
			}
			else
			{
				Pos[0] = END[0];
				Pos[1] = END[1];
				Pos[2] = END[2];
			}
			StartStopDisco(param1, Pos, StringToInt(info)); 
			Void_Menu_Disco(param1);
		}
	}
	return;
}

