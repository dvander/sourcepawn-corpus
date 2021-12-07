#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION 		"0.1.5"
#define MAX_SONGS 30
new String:song_name[MAX_SONGS][128];
new String:song_path[MAX_SONGS][128];

new DiscoBall = -1;
new DiscoColor = 0;
new Handle:DiscoTimer = INVALID_HANDLE;
new Handle:g_AdminFlag = INVALID_HANDLE;	

new const g_DefaultColors_c[6][3] = { {255,0,0}, {0,255,0}, {0,0,255}, {255,255,0}, {0,255,255}, {255,0,255} };
new const String:g_DefaultColors_p[6][] = { "materials/sprites/redglow1.vmt", "materials/sprites/greenglow1.vmt", "materials/sprites/blueglow1.vmt", "materials/sprites/yellowglow1.vmt", "materials/sprites/glow1.vmt", "materials/sprites/purpleglow1.vmt" };
new g_DefaultColors_s[6];
new g_Flagbit=2;
new g_Flagz;
new g_sprite;

new count;

public Plugin:myinfo =
{
	name = "DISCO!!!",
	author = "MitchDizzle_",
	description = "Mitch's Disco Mod!",
	version = PLUGIN_VERSION,
	url = "nefarious.mitch@yahoo.com"
}
public OnPluginStart()
{
	CreateConVar("sm_disco_version", PLUGIN_VERSION, "Disco Mod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	
	RegConsoleCmd("sm_discomenu", Command_Disco);
	g_AdminFlag = CreateConVar("sm_disco_flag", "z");
	HookConVarChange(g_AdminFlag, ConVarChanged_Flag);
	g_Flagz = ReadFlagString("z");
	g_sprite = PrecacheModel("materials/sprites/laser.vmt");
	LoadMusicconfig();
	for(new i = 0; i <= 5; i++)
	{
		g_DefaultColors_s[i] = PrecacheModel(g_DefaultColors_p[i],true);
	}
	HookEvent("round_end", RoundEnd);
}
public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( DiscoTimer != INVALID_HANDLE )
	{
		if(IsDiscoBall(DiscoBall))
		{
			AcceptEntityInput( DiscoBall , "Kill" );
			DiscoBall = -1;
		}
		KillTimer( DiscoTimer );
		DiscoTimer = INVALID_HANDLE;
	}
}
public OnMapStart()
{
	HookEvent("round_end", RoundEnd);
}
public OnMapEnd()
{
	UnhookEvent("round_end", RoundEnd);
}
public OnPluginEnd()
{
	if ( DiscoTimer != INVALID_HANDLE )
	{
		if(IsDiscoBall(DiscoBall))
		{
			AcceptEntityInput( DiscoBall , "Kill" );
			DiscoBall = -1;
		}
		KillTimer( DiscoTimer );
		DiscoTimer = INVALID_HANDLE;
	}
}
stock LoadMusicconfig()
{
	new Handle:kvs = CreateKeyValues("MusicConfig");
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/musicconfig.cfg");
	FileToKeyValues(kvs, sPaths);


	if (!KvGotoFirstSubKey(kvs))
	{
		return;
	}
	count = 0;
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
	if(GetUserFlagBits(client) & g_Flagbit || GetUserFlagBits(client) & g_Flagz)
	{
		Void_Menu_Disco(client);
	}
	else
	{
		PrintToChat(client, "\x03[\x04Disco\x03]\x01 You don't have permission to access this.");
	}
	return Plugin_Handled;
}

public ConVarChanged_Flag ( Handle:convar , const String:oldValue[] , const String:newValue[] )
{
	g_Flagbit = ReadFlagString( newValue );
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
StartStopDisco ( client,  Float:Pos[3] , songindex = 0 )
{
	if ( DiscoTimer != INVALID_HANDLE )
	{
		if(IsDiscoBall(DiscoBall))
		{
			AcceptEntityInput( DiscoBall , "Kill" );
			DiscoBall = -1;
		}
		KillTimer( DiscoTimer );
		DiscoTimer = INVALID_HANDLE;
		PrintToChatAll("\x03[\x04Disco\x03]\x05 %N\x01 has stopped the disco!", client);
		for(new x = 1; x<MAXPLAYERS+1;x++)
		{
			if(IsValidClient(x))
			{
				DoUrl(x, "www.google.com/");
			}
		}
	}
	else
	{
		DiscoBall =  CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(DiscoBall, "classname", "disco_ball");
		DispatchKeyValue(DiscoBall, "model", "models/props/slow/spiegelkugel/slow_spiegelkugel.mdl" );
		DispatchKeyValue(DiscoBall, "solid", "0");
		DispatchSpawn( DiscoBall );
		TeleportEntity( DiscoBall, Pos, NULL_VECTOR, NULL_VECTOR );
		for(new x = 1; x<MAXPLAYERS+1;x++)
		{
			if(IsValidClient(x))
			{
				DoUrl(x, song_path[songindex]);
			}
		}

		DiscoColor = 0;
		DiscoTimer = CreateTimer(0.1, Timer_DiscoUpdate, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		PrintToChatAll("\x03[\x04Disco\x03]\x05 %N\x01 has started the disco!!", client);
		PrintToChatAll("\x03[\x04Disco\x03]\x01 Song: \x05%s\x01.", song_name[songindex]);
		PrintToChatAll("\x03[\x04Disco\x03]\x01 To disable the song, type motd in chat.");
	}
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}
public Action:Timer_DiscoUpdate(Handle:timer)
{
	if(IsDiscoBall(DiscoBall))
	{
		SetEntityRenderColor(DiscoBall, g_DefaultColors_c[DiscoColor][0], g_DefaultColors_c[DiscoColor][1], g_DefaultColors_c[DiscoColor][2], 255);

		new Float:propangle[3];
		GetEntPropVector(DiscoBall, Prop_Data, "m_angRotation", propangle);
		propangle[1] += 11.25;
		TeleportEntity(DiscoBall, NULL_VECTOR, propangle, NULL_VECTOR);
		new Float:POS[3];
		new Float:END[3];
		GetEntPropVector(DiscoBall, Prop_Send, "m_vecOrigin", POS);
		POS[2] -= 42.0;
		TE_SetupGlowSprite(POS, g_DefaultColors_s[DiscoColor], 0.1, 2.0, 255);
		TE_SendToAll();
		new Color[4];
		Color[3] = 255;
		new Float:vAngles[3]

		for(new i = 0; i <= 5; i++)
		{
			vAngles[0] = GetRandomFloat( 0.0, 90.0 );
			vAngles[1] = GetRandomFloat(-180.0, 180.0);
			vAngles[2] = 0.0
			new Handle:trace = TR_TraceRayFilterEx(POS, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(END, trace);
			}

			CloseHandle(trace);
			Color[0] = g_DefaultColors_c[i][0];
			Color[1] = g_DefaultColors_c[i][1];
			Color[2] = g_DefaultColors_c[i][2];
			LaserP(POS, END, Color);
		}
		DiscoColor++;
		if(DiscoColor > 5) DiscoColor = 0;
	}
	return Plugin_Continue;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}
stock LaserP(const Float:start[3], const Float:end[3], const color[4])
{
	new Float:life = 0.1;
	TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, life, 3.0, 3.0, 7, 0.0, color, 0);
	TE_SendToAll();
}
public Action:DoUrl(client, String:url[128])
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "DISCO");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);
	return Plugin_Handled;
}


//MENUS
Void_Menu_Disco(client, index=0)
{
	new Handle:menu = CreateMenu(Menu_Disco, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(menu, "- Disco -");
	if(!IsDiscoBall(DiscoBall))
	{
		AddMenuItem(menu, "StartDisco", "Start Disco\n Disco Created by Mitch.", ITEMDRAW_DEFAULT);
	}
	else
	{
		AddMenuItem(menu, "StopDisco", "Stop Disco\n Disco Created by Mitch.", ITEMDRAW_DEFAULT);
	}
	DisplayMenuAtItem(menu, client, index, MENU_TIME_FOREVER);
}

Void_Menu_DiscoSongList(client, index=0)
{
	new Handle:menu = CreateMenu(Menu_DiscoSL, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(menu, "- Disco Song: -");
	decl String:g_sDisplay[128];
	decl String:g_sChoice[128];
	for(new X = 0; X <= count; X++)
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
				Void_Menu_DiscoSongList(param1);
			}
			if(StrEqual("StopDisco", info, false))
			{
				if ( DiscoTimer != INVALID_HANDLE )
				{
					if(IsDiscoBall(DiscoBall))
					{
						AcceptEntityInput( DiscoBall , "Kill" );
						DiscoBall = -1;
					}
					KillTimer( DiscoTimer );
					DiscoTimer = INVALID_HANDLE;
					PrintToChatAll("\x03[\x04Disco\x03]\x05 %N\x01 has stopped the disco!", param1);
					for(new x = 1; x<MAXPLAYERS+1;x++)
					{
						if(IsValidClient(x))
						{
							DoUrl(x, "www.google.com/");
						}
					}
				}
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
			new X = StringToInt(info);
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
			StartStopDisco(param1, Pos, X); 
			Void_Menu_Disco(param1);
		}
	}
	return;
}