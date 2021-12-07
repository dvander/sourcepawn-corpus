#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <admstealth>
#undef REQUIRE_PLUGIN
#tryinclude <afk_manager> 
#define REQUIRE_PLUGIN


//Defines
#define PLUGIN_VERSION "1.6.1"
#define QUIT_REASON "Disconnected by user."
#define STEALTHTEAM 0
#define PLAYER_MANAGER "tf_player_manager"


//Variables
new bool:g_bIsInvisible[MAXPLAYERS+1];
new bool:g_AnnoEnabled[MAXPLAYERS+1];
new g_iOldTeam[MAXPLAYERS+1];
new Float:nextStatus[MAXPLAYERS+1];
new Float:nextPing[MAXPLAYERS+1];

//Cvar handles
new Handle:g_hHostname;
new Handle:g_hTags;
new Handle:g_hTVEnabled;
new Handle:g_hTVDelay;
new Handle:g_hTVPort;
new Handle:g_hIpAddr;
new Handle:g_hIpPort;
new serverVer;
new bool:registered;
//Forwards
new Handle:g_BStealthed;

public Plugin:myinfo = 
{
	name = "Admin Stealth REDUX",
	author = "necavi and Naydef (new developer)",
	description = "Allows administrators to become nearly completely invisible.",
	version = PLUGIN_VERSION,
	url = "http://necavi.org/"
}

public OnPluginStart()
{
	CreateConVar("sm_adminstealth_version", PLUGIN_VERSION, "Admin-Stealth version cvar", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_stealth", Command_Stealth, ADMFLAG_CUSTOM3, "Allows an administrator to toggle complete invisibility on themselves.");
	g_hHostname = FindConVar("hostname");
	g_hTags = FindConVar("sv_tags");
	g_hTVEnabled = FindConVar("tv_enable");
	g_hTVDelay = FindConVar("tv_delay");
	g_hTVPort = FindConVar("tv_port");
	g_hIpAddr = FindConVar("hostip");
	g_hIpPort = FindConVar("hostport");
	new String:buffer[32];
	GetConVarString(FindConVar("sv_registration_message"), buffer, sizeof(buffer));
	if(buffer[0]=='\0')
	{
		registered=true;
	}
	serverVer=GetSteamINFNum();
	AddCommandListener(Command_JoinTeamOrClass, "jointeam");
	AddCommandListener(Command_JoinTeamOrClass, "joinclass");
	AddCommandListener(Command_JoinTeamOrClass, "autoteam");
	AddCommandListener(Command_Status, "status");
	AddCommandListener(Command_Ping, "ping");
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKHook(i, SDKHook_SetTransmit, Hook_Transmit);
		}
	}
	new TF2PManager=FindEntityByClassname(-1, PLAYER_MANAGER);
	if(IsValidEntity(TF2PManager)) // Why SDKHook doesn't have a native to test if the entity is already hooked?
	{
		SDKHook(TF2PManager, SDKHook_ThinkPost, Hook_ThinkPost);
	}
	HookEvent("player_disconnect", Event_StealthAdminDisconnect, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(!IsTF2())
	{
		strcopy(error, err_max, "This version of the plugin is currently only for Team Fortress 2! Remove the plugin!");
		return APLRes_Failure;
	}
	
	//Natives
	CreateNative("ADMStealth_IsStealthed", Native_IsStealthed);
	CreateNative("ADMStealth_Toggle", Native_StealthToggle);
	RegPluginLibrary("Admin_Stealth_Redux");
	
	//Forwards
	g_BStealthed = CreateGlobalForward("ADMStealth_OnToggle", ET_Event, Param_Cell, Param_Cell, Param_CellByRef);
	return APLRes_Success;
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_SetTransmit, Hook_Transmit);
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			HideAnnotationFromPlayer(i, client);
		}
	}
	g_bIsInvisible[client]=false;
	nextStatus[client]=0.0;
	nextPing[client]=0.0;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_Transmit);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, PLAYER_MANAGER, false))
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_SpawnPost);
	}
}

public Action:Hook_SpawnPost(entity)
{
	if(IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_ThinkPost, Hook_ThinkPost);
	}
	return Plugin_Continue;
}

public Hook_ThinkPost(entity)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			SetEntProp(entity, Prop_Send, "m_bConnected", false, _, i);
		}
	}
}

public Action:Command_JoinTeamOrClass(client, const String:command[], args)  
{ 
	if(g_bIsInvisible[client])
	{
		PrintToChat(client, "\x03[STEALTH]\x01 Cannot join team or class when in stealth mode!");
		return Plugin_Stop;
	}
	else 
	{ 
		return Plugin_Continue; 
	} 
}

public Action:Event_StealthAdminDisconnect(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(ValidPlayer(client) && g_bIsInvisible[client]) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!ValidPlayer(client))
	{
		return Plugin_Continue;
	}
	new String:buffer[128];
	new String:smallbuff[32];
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i] && g_AnnoEnabled[i] && !g_bIsInvisible[client])
		{
			GetClientAuthId(client, AuthId_Steam3, smallbuff, sizeof(smallbuff));
			Format(buffer, sizeof(buffer), "Client: %N | SteamID: %s | UserID: %i", client, smallbuff, GetClientUserId(client));
			CreateAttachedAnnotation(i, client, -1.0, buffer, false);
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!ValidPlayer(client))
	{
		return Plugin_Continue;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i] && g_AnnoEnabled[i])
		{
			HideAnnotationFromPlayer(i, client);
		}
	}
	return Plugin_Continue;
}

public Action:Command_Status(client, const String:command[], args)
{
	if(!ValidPlayer(client) || CheckCommandAccess(client, "sm_stealth", 0)) // Console will now work!!!
	{
		return Plugin_Continue;
	}
	if(nextStatus[client]<=GetGameTime())
	{
		new String:buffer[128];
		new Float:vec[3];
		GetConVarString(g_hHostname, buffer, sizeof(buffer));
		PrintToConsole(client, "hostname: %s", buffer);
		PrintToConsole(client, "version : %i/24 %i secure", serverVer, serverVer);
		ServerIP(buffer, sizeof(buffer));
		PrintToConsole(client, "upd/ip  :  %s:%i (public ip: %s)", buffer, GetConVarInt(g_hIpPort), buffer);
		#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR>=8 //Add support for Sourcemod 1.8 (this is not optimized!)
		GetServerAuthId(AuthId_Steam3, buffer, sizeof(buffer));
		PrintToConsole(client, "steamid : %s (%i)", buffer, GetServerSteamAccountId());
		#endif
		GetCurrentMap(buffer, sizeof(buffer));
		GetClientAbsOrigin(client, vec);
		(registered) ? PrintToConsole(client, "account  : logged in") : PrintToConsole(client, "account  :  not logged in (No account specified)");
		PrintToConsole(client, "map     : %s at: %.0f x, %.0f y, %.0f z", buffer, vec[0], vec[1], vec[2]); // I don't know if this is an issue, but "status" command usually shows only 0.0
		GetConVarString(g_hTags, buffer, sizeof(buffer));
		PrintToConsole(client, "tags    : %s", buffer);
		if(GetConVarBool(g_hTVEnabled))
		{
			PrintToConsole(client, "sourcetv:  port %i, delay %.1fs", GetConVarInt(g_hTVPort), GetConVarFloat(g_hTVDelay));
		}
		PrintToConsole(client, "players : %i humans (%i max)", GetClientCount()-GetInvisCount(), MaxClients);
		PrintToConsole(client, "edicts  : %i used of %i max", GetUsedEntities()-GetInvisCount(), GetMaxEntities());
		PrintToConsole(client, "# userid name                uniqueid            connected ping loss state");
		new String:name[MAX_NAME_LENGTH];
		new String:steamID[24];
		new String:time[12];
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i))
			{
				if(!g_bIsInvisible[i])
				{
					Format(name,sizeof(name),"\"%N\"",i);
					GetClientAuthId(i, AuthId_Steam3, steamID, sizeof(steamID));
					if(!IsFakeClient(i))
					{
						FormatShortTime(RoundToFloor(GetClientTime(i)), time, sizeof(time));
						PrintToConsole(client, "# %6d %-19s %19s %9s %4d %4d %s", GetClientUserId(i), 
						name, steamID, time, RoundToFloor(GetClientAvgLatency(i, NetFlow_Both) * 1000.0), 
						RoundToFloor(GetClientAvgLoss(i, NetFlow_Both) * 100.0), (IsClientInGame(i) ? "active" : "spawning"));
					} 
					else 
					{
						PrintToConsole(client, "# %6d %-19s %19s                     %s", GetClientUserId(i), name, steamID, (IsClientInGame(i) ? "active" : "spawning"));
					}
				}
			}
		}
		nextStatus[client]=GetGameTime()+5.0;
	}
	return Plugin_Handled;
}

public Action:Command_Ping(client, const String:command[], args)
{
	if(!ValidPlayer(client) || CheckCommandAccess(client, "sm_stealth", 0)) // Console will now work!!!
	{
		return Plugin_Continue;
	}
	if(nextPing[client]<=GetGameTime())
	{
		PrintToConsole(client, "Client ping times:");
		for(new i=1; i<=MaxClients; i++)
		{
			if(ValidPlayer(i) && !g_bIsInvisible[i] && !IsFakeClient(i))
			{
				PrintToConsole(client, " %i ms : %N", RoundToFloor(GetClientAvgLatency(i, NetFlow_Both) * 1000.0), i);
			}
		}
		nextPing[client]=GetGameTime()+5.0;
	}
	return Plugin_Handled;
}

public Action:Command_Stealth(client, args)
{
	if(!ValidPlayer(client))
	{
		PrintToServer("You cannot run this command!!!");
	}
	else
	{
		new bool:annotations=false;
		if(args>0)
		{
			new String:buffer[8];
			GetCmdArg(1, buffer, sizeof(buffer));
			annotations=bool:StringToInt(buffer);
		}
		ToggleInvis(client, annotations);
	}
	return Plugin_Handled;
}

ToggleInvis(client, bool:annotations=false)
{
	new Action:result;
	new bool:temp=annotations;
	/* Start function call */
	Call_StartForward(g_BStealthed);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushCell(!g_bIsInvisible[client]);
	Call_PushCellRef(annotations);

	/* Finish the call, get the result */
	Call_Finish(_:result);
	switch(result)
	{
	case Plugin_Continue:
		{
			(g_bIsInvisible[client]) ? InvisOff(client) : InvisOn(client, annotations);
			return;
		}
	case Plugin_Changed:
		{
			(g_bIsInvisible[client]) ? InvisOff(client) : InvisOn(client, temp);
			return;
		}
	case Plugin_Handled, Plugin_Stop:
		{
			return;
		}
	}
}

InvisOff(client)
{
	g_bIsInvisible[client] = false;
	g_AnnoEnabled[client]=false;
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, g_iOldTeam[client]);
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	SetEntProp(client, Prop_Data, "m_autoKickDisabled", false); // Enable the integrated TF2 auto-kick manager for this client
	PrintConDisMessg(client, true);
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			HideAnnotationFromPlayer(client, i);
		}
	}
	PrintToChat(client, "\x03[STEALTH]\x01 You are no longer in stealth mode!");

}

InvisOn(client, bool:annotations=false)
{
	TF2_RemoveAllWeapons(client);
	new entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*"))!=-1)
	{
		if(IsValidEntity(entity) && (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client))
		{
			TF2_RemoveWearable(client, entity);
		}
	}
	while((entity=FindEntityByClassname2(entity, "tf_powerup_*"))!=-1)
	{
		if(IsValidEntity(entity) && (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client))
		{
			TF2_RemoveWearable(client, entity);
		}
	}
	g_bIsInvisible[client]=true;
	g_AnnoEnabled[client]=annotations;
	g_iOldTeam[client]=Arena_GetClientTeam(client);
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, STEALTHTEAM);
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	SetEntProp(client, Prop_Data, "m_autoKickDisabled", true); // Disable the integrated TF2 auto-kick manager for this client
	PrintConDisMessg(client, false);
	if(annotations) 
	{
		CreateTimer(0.1, Timer_AttachDelayed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	PrintToChat(client, "\x03[STEALTH]\x01 You are now in stealth mode!");
}

public Action:Timer_AttachDelayed(Handle:htimer, userid)
{
	new client=GetClientOfUserId(userid);
	if(!ValidPlayer(client))
	{
		return Plugin_Stop;
	}
	new String:buffer[128];
	new String:smallbuff[32];
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i) && !g_bIsInvisible[i] && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			GetClientAuthId(i, AuthId_Steam3, smallbuff, sizeof(smallbuff));
			Format(buffer, sizeof(buffer), "Client: %N | SteamID: %s | UserID: %i", i, smallbuff, GetClientUserId(i));
			CreateAttachedAnnotation(client, i, -1.0, buffer, false);
		}
	}
	return Plugin_Continue;
}

public Action:Hook_Transmit(entity, client)
{
	if(ValidPlayer(entity) && g_bIsInvisible[entity] && entity != client)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
	
}

public Action:AFKM_OnAFKEvent(const String:name[], client)
{
	if(ValidPlayer(client) && g_bIsInvisible[client])
	{
		return Plugin_Handled; //Prevent AFK actions for this player
	}
	return Plugin_Continue;
}

//Stocks
bool:ValidPlayer(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

FormatShortTime(time, String:outTime[], size)
{
	new temp;
	temp = time % 60;
	Format(outTime, size,"%02d",temp);
	temp = (time % 3600) / 60;
	Format(outTime, size,"%02d:%s", temp, outTime);
	temp = (time % 86400) / 3600;
	if(temp > 0)
	{
		Format(outTime, size, "%d%:s", temp, outTime);

	}
}

GetInvisCount()
{
	new count = 0;
	for(new i; i <= MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			count++;
		}
	}
	return count;
}

//To-do: Use the new fake event function in Sourcemod 1.8
bool:PrintConDisMessg(client, bool:connect)
{
	if(!ValidPlayer(client))
	{
		return false;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	if(connect)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(!ValidPlayer(i))
			{
				continue;
			}
			new Handle:bf = StartMessageOne("TextMsg", i, USERMSG_RELIABLE); 
			if(bf!=INVALID_HANDLE)
			{
				BfWriteByte(bf, 3); 
				BfWriteString(bf, "#game_player_joined_game"); 
				BfWriteString(bf, name);
				EndMessage();
			}
		}
	}
	else
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(!ValidPlayer(i))
			{
				continue;
			}
			new Handle:bf = StartMessageOne("TextMsg", i, USERMSG_RELIABLE); 
			if(bf!=INVALID_HANDLE)
			{
				BfWriteByte(bf, 3);
				BfWriteString(bf, "#game_player_left_game"); 
				BfWriteString(bf, name);
				BfWriteString(bf, QUIT_REASON);
				EndMessage(); 
			}
		}
	}
	return true;
}
/*                                  Natives                                       */
public Native_IsStealthed(Handle:plugin, numParams)
{
	new client=GetNativeCell(1);
	if(client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return (g_bIsInvisible[client]) ? true : false;
}

public Native_StealthToggle(Handle:plugin, numParams)
{
	new client=GetNativeCell(1);
	if(client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	(GetNativeCell(2)) ? InvisOn(client, GetNativeCell(3)) : InvisOff(client);
	return 0;
}

/*                                  Stocks                                        */

bool:IsTF2()
{
	return (GetEngineVersion()==Engine_TF2) ?  true : false;
}

Arena_GetClientTeam(entity) //Also works on entities!
{
	return (IsValidEntity(entity)) ? (GetEntProp(entity, Prop_Send, "m_iTeamNum")) : (-1);
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

//Credit: pilger
stock GetSteamINFNum(String:search[]="ServerVersion")
{
	new String:file[16]="./steam.inf", String:inf_buffer[64]; //It's not worth using decl
	new Handle:file_h=OpenFile(file, "r");
	
	do
	{
		if(!ReadFileLine(file_h, inf_buffer, sizeof(inf_buffer)))
		{
			return -1;
		}
		TrimString(inf_buffer);
	}
	while(StrContains(inf_buffer, search, false) < 0);
	CloseHandle(file_h);

	return StringToInt(inf_buffer[strlen(search)+1]);
}

stock GetUsedEntities()
{
	new count=0;
	for(new i=0; i<=GetMaxEntities(); i++)
	{
		if(IsValidEntity(i))
		{
			count++;
		}
	}
	return count;
}

/*
stock SilentNameChange(client, const String:newname[])
{
	//decl String:oldname[MAX_NAME_LENGTH];
	//GetClientName(client, oldname, sizeof(oldname));

	SetClientInfo(client, "name", newname);
	SetEntPropString(client, Prop_Data, "m_szNetname", newname);

	new Handle:event = CreateEvent("player_changename");

	if(event != INVALID_HANDLE)
	{
		SetEventInt(event, "userid", GetClientUserId(client));
		//SetEventString(event, "oldname", oldname);
		SetEventString(event, "newname", newname);
		FireEvent(event);
	}
}
*/

//https://forums.alliedmods.net/showpost.php?p=495342&postcount=14
ServerIP(String:buffer[], size)
{
	new pieces[4];
	new longip = GetConVarInt(g_hIpAddr);
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;

	Format(buffer, size, "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
}

CreateAttachedAnnotation(client, entity, Float:time, String:text[], bool:effect=true)
{
	new Handle:event = CreateEvent("show_annotation");
	if(event == INVALID_HANDLE)
	{
		return -1;
	}
	new Float:v_Pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", v_Pos);
	SetEventInt(event, "follow_entindex", entity);		
	SetEventFloat(event, "lifetime", time);
	SetEventInt(event, "visibilityBitfield", (1 << client));
	SetEventBool(event,"show_effect", effect);
	SetEventFloat(event, "worldNormalX", v_Pos[0]);
	SetEventFloat(event, "worldNormalY", v_Pos[1]);
	SetEventFloat(event, "worldNormalZ", v_Pos[2]);
	SetEventFloat(event, "worldPosX", v_Pos[0]);
	SetEventFloat(event, "worldPosY", v_Pos[1]);
	SetEventFloat(event, "worldPosZ", v_Pos[2]);
	SetEventString(event, "text", text);
	SetEventInt(event, "id", entity); //What to enter inside? Need a way to indentify annotations by entindex!
	FireEvent(event);
	return entity;
}

//https://forums.alliedmods.net/showthread.php?p=1317304
public bool:HideAnnotationFromPlayer(client, annotation_id)
{
	new Handle:event = CreateEvent("hide_annotation");
	if (event == INVALID_HANDLE)
	{
		return false;
	}
	SetEventInt(event, "id", annotation_id);
	FireEvent(event);
	return true;
}
