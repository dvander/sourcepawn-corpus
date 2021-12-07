#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

new const String:PLUGIN_VERSION[] = "1.1";

new Handle:hcv_Mode = INVALID_HANDLE;
new Handle:hcv_Auto = INVALID_HANDLE;
new Handle:hcv_EmptyRebel = INVALID_HANDLE;

new Handle:dbLocal;

new Handle:hTimer_AutoOpen = INVALID_HANDLE;

new bool:OpenedThisRound = false;

new String:MapName[64];

new ButtonHID = -1;

public Plugin:myinfo = 
{
	name = "Smart Open",
	author = "Eyal282",
	description = "JailBreak Cells Open that works in a smart way",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{	
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_open", Command_Open, "Opens jail cells");
	
	RegAdminCmd("sm_open_override", Command_OpenOverride, ADMFLAG_SLAY, "Command used for override purposes");
	RegAdminCmd("sm_assignopen", Command_AssignOpen, ADMFLAG_SLAY);
	
	hcv_Mode = CreateConVar("open_cells_mode", "1", "0 - Command will not work if an admin didn't assign a button to the map, 1 - Uses all buttons in the map if button wasn't assigned to map");
	hcv_Auto = CreateConVar("open_cells_auto", "60", "After how much time to open the cells, set to -1 to disable");
	hcv_EmptyRebel = CreateConVar("open_cells_allow_empty_rebel", "1", "If there are no CT ( probably server empty ) terrorists are able to use !open");
}

public OnMapStart()
{
	ButtonHID = -1;
	OpenedThisRound = false;
	ConnectToDatabase();
	
	hTimer_AutoOpen = INVALID_HANDLE;
}

public ConnectToDatabase()
{		
	new String:Error[256];
	if((dbLocal = SQLite_UseDatabase("sourcemod-local", Error, sizeof(Error))) == INVALID_HANDLE)
		LogError(Error);
	
	else
	{ 
		SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS SmartOpen_Maps (MapName VARCHAR(64) NOT NULL UNIQUE, ButtonHammerID INT(15) NOT NULL)", DBPrio_High);		
		
		new String:sQuery[256];
		GetCurrentMap(MapName, sizeof(MapName));
		Format(sQuery, sizeof(sQuery), "SELECT * FROM SmartOpen_Maps WHERE MapName = \"%s\"", MapName);
		
		SQL_TQuery(dbLocal, SQLCB_GetButtonHammerID, sQuery);
	}
}

public SQLCB_GetButtonHammerID(Handle:db, Handle:hndl, const String:sError[], dummy_value)
{
	if(hndl == null)
		ThrowError(sError);
	
	else if(SQL_GetRowCount(hndl) == 0)
	{
		ButtonHID = -1;
		return;
	}

	if(!SQL_FetchRow(hndl))
	{
		ButtonHID = -1;
		return;
	}
	
	ButtonHID = SQL_FetchInt(hndl, 1);
}

public SQLCB_Error(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
}

public Action:Event_RoundStart(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	UnhookEntityOutput("func_button", "OnPressed", OnButtonPressed);
	
	if(ButtonHID != -1)
	{
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "func_button")) != -1)
		{
			if(GetEntProp(ent, Prop_Data, "m_iHammerID") == ButtonHID)
				break;
		}
		
		if(ent != -1)
			HookSingleEntityOutput(ent, "OnPressed", OnButtonPressed);
	}
	OpenedThisRound = false;
	
	DestroyTimer(hTimer_AutoOpen);
	
	if(GetConVarFloat(hcv_Auto) != -1)
		hTimer_AutoOpen = CreateTimer(GetConVarFloat(hcv_Auto), AutoOpenCells, _, TIMER_FLAG_NO_MAPCHANGE);
}

public OnButtonPressed(const String:output[], caller, activator, Float:delay)
{
	if(GetEntProp(caller, Prop_Data, "m_iHammerID") != ButtonHID)
	{
		UnhookSingleEntityOutput(caller, "PressIn", OnButtonPressed);
		return;
	}
	
	else if(OpenedThisRound)
	{
		UnhookSingleEntityOutput(caller, "PressIn", OnButtonPressed);
		return;
	}
	
	OpenedThisRound = true;
	UnhookSingleEntityOutput(caller, "PressIn", OnButtonPressed);
}
public Action:AutoOpenCells(Handle:hTimer)
{
	if(ButtonHID != -1)
		OpenCells();
		
	hTimer_AutoOpen = INVALID_HANDLE;
}

public Action:Command_AssignOpen(client, args)
{
	new ent = FindEntityByAim(client, "func_button");
	
	if(ent < 0)
	{
		PrintToChat(client, "Couldn't find a func_button entity at your aim, please try again");
		return Plugin_Handled;
	}
	
	new String:Classname[64];
	GetEdictClassname(ent, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "func_button", true))
	{
		PrintToChat(client, "Couldn't find a func_button entity at your aim, please try again");
		return Plugin_Handled;
	}
	
	ButtonHID = GetEntProp(ent, Prop_Data, "m_iHammerID");
	
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "INSERT OR REPLACE INTO SmartOpen_Maps (MapName, ButtonHammerID) VALUES (\"%s\", %i)", MapName, ButtonHID);
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery, DBPrio_Normal);
	
	PrintToChat(client, "Successfully made the button you're aiming at as the button that opens the cells for !open");
	return Plugin_Handled;
}

public Action:Command_OpenOverride(client, args)
{
	return Plugin_Handled;
}
public Action:Command_Open(client, args)
{
	if(client != 0 && GetClientTeam(client) != CS_TEAM_CT && !CheckCommandAccess(client, "sm_open_override", ADMFLAG_SLAY, false) && !CanEmptyRebel())
	{
		PrintToChat(client, "You must be CT to use this command!");
		return Plugin_Handled;
	}
	
	else if(OpenedThisRound)
	{
		PrintToChat(client, "Cells were already opened this round!");
		return Plugin_Handled;
	}
	
	else if(ButtonHID == -1 && GetConVarInt(hcv_Mode) == 0)
	{
		PrintToChat(client, "Map does not have an assigned open button!");
		PrintToChat(client, "An admin must use !assignopen to assign a button.");
		return Plugin_Handled;
	}
	
	
	if(!OpenCells())
	{
		PrintToChat(client, "The map's assigned open button is bugged!");
		return Plugin_Handled;
	}
	
	new String:Title[64];
	
	Title = "Rebel";
	if(client != 0)
	{
		if(GetClientTeam(client) == CS_TEAM_CT)
			Title = "Warden";
			
		else if(CheckCommandAccess(client, "sm_open_override", ADMFLAG_SLAY, false))
			Title = "Admin";
	}
	else
		Title = "Admin";
	
	if(client != 0)
		PrintToChatAll("\x01%s\x03 %N\x04 opened\x01 the\x05 jail cells!", Title, client);
		
	return Plugin_Handled;
}

stock bool:OpenCells()
{
	if(OpenedThisRound)
		return false;
	
	new target;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		target = i;
		break;
	}
	
	if(target == 0)
		return false;
		
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		target = i;
		break;
	}
	new ent = -1;
	if(ButtonHID == -1)
	{
		while((ent = FindEntityByClassname(ent, "func_button")) != -1)
			AcceptEntityInput(ent, "PressIn", target);
	}
	
	else
	{
		new bool:Found = false;
		while((ent = FindEntityByClassname(ent, "func_button")) != -1)
		{
			if(GetEntProp(ent, Prop_Data, "m_iHammerID") == ButtonHID)
			{
				Found = true;
				break;
			}
		}
		
		if(!Found)
			return false;
			
		AcceptEntityInput(ent, "PressIn", target);
	}
	
	OpenedThisRound = true;
	
	return true;
}

stock DestroyTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		CloseHandle(timer);
		timer = INVALID_HANDLE;
	}
}

stock FindEntityByAim(client, const String:Classname[])
{
	new Float:eyeOrigin[3], Float:eyeAngles[3];
	
	GetClientEyePosition(client, eyeOrigin);
	GetClientEyeAngles(client, eyeAngles);
	
	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, Classname);
	TR_TraceRayFilter(eyeOrigin, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_HitClassname, DP);
	
	CloseHandle(DP);
	
	if(!TR_DidHit(INVALID_HANDLE))
		return -1;
		
	return TR_GetEntityIndex(INVALID_HANDLE);
}


public bool:TraceRay_HitClassname(entityhit, mask, Handle:DP) 
{
	new String:Classname[64], String:Classname2[64];
	
	ResetPack(DP);
	ReadPackString(DP, Classname, sizeof(Classname));
	
	GetEdictClassname(entityhit, Classname2, sizeof(Classname2));

	return StrEqual(Classname, Classname2, true);
}

stock GetTeamPlayerCount(Team)
{
	new count = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(GetClientTeam(i) == Team)
			count++;
	}
	return count;
}

stock bool:CanEmptyRebel()
{
	return (GetConVarBool(hcv_EmptyRebel) && GetTeamPlayerCount(CS_TEAM_CT) == 0);
}