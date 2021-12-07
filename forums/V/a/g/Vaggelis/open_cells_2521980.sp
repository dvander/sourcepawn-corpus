#include <sourcemod>
#include <sdktools>

#pragma newdecls required

float g_Min = 300.0

Handle g_DoorList

public Plugin myinfo = 
{
	name = "[CS:GO] Open Cells",
	author = "Vaggelis",
	version = "1.1",
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_open", CmdOpenCells)
	RegConsoleCmd("sm_close", CmdCloseCells)
	
	g_DoorList = CreateArray()
}

public void OnMapStart()
{
	CacheDoors()
}

public void OnMapEnd()
{
	ClearArray(g_DoorList)
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("JB_OpenCells", Native_OpenCells)
	CreateNative("JB_CloseCells", Native_CloseCells)
	
	return APLRes_Success
}

public int Native_OpenCells(Handle plugin, int numParams)
{
	for(int i = 0; i < GetArraySize(g_DoorList); i++)
	{
		int door = GetArrayCell(g_DoorList, i)
		
		AcceptEntityInput(door, "Open")
	}
}

public int Native_CloseCells(Handle plugin, int numParams)
{
	for(int i = 0; i < GetArraySize(g_DoorList); i++)
	{
		int door = GetArrayCell(g_DoorList, i)
		
		AcceptEntityInput(door, "Close")
	}
}

public Action CmdOpenCells(int client, int args)
{
	if(GetClientTeam(client == 3) || GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		for(int i = 0; i < GetArraySize(g_DoorList); i++)
		{
			int door = GetArrayCell(g_DoorList, i)
			
			AcceptEntityInput(door, "Open")
		}
		
		PrintToChatAll(" \x04%N\x01 opened the cells", client)
	}
}

public Action CmdCloseCells(int client, int args)
{
	if(GetClientTeam(client == 3) || GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		for(int i = 0; i < GetArraySize(g_DoorList); i++)
		{
			int door = GetArrayCell(g_DoorList, i)
			
			AcceptEntityInput(door, "Close")
		}
		
		PrintToChatAll(" \x04%N\x01 closed the cells", client)
	}
}

void CacheDoors()
{
	int ent = -1
	int door = -1
	
	while((ent = FindEntityByClassname(ent, "info_player_terrorist")) != -1)
	{
		float prisoner_pos[3]
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", prisoner_pos)
		
		while((door = FindEntityByClassname(door, "func_door")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				g_Min = GetVectorDistance(door_pos, prisoner_pos)
			}
		}
		
		while((door = FindEntityByClassname(door, "func_door_rotating")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				g_Min = GetVectorDistance(door_pos, prisoner_pos)
			}
		}
		
		while((door = FindEntityByClassname(door, "func_movelinear")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				g_Min = GetVectorDistance(door_pos, prisoner_pos)
			}
		}
		
		while((door = FindEntityByClassname(door, "prop_door_rotating")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				g_Min = GetVectorDistance(door_pos, prisoner_pos)
			}
		}
	}
	
	g_Min += 100
	
	while((ent = FindEntityByClassname(ent, "info_player_terrorist")) != -1)
	{
		float prisoner_pos[3]
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", prisoner_pos)
		
		while((door = FindEntityByClassname(door, "func_door")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				PushArrayCell(g_DoorList, door)
			}
		}
		
		while((door = FindEntityByClassname(door, "func_door_rotating")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				PushArrayCell(g_DoorList, door)
			}
		}
		
		while((door = FindEntityByClassname(door, "func_movelinear")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				PushArrayCell(g_DoorList, door)
			}
		}
		
		while((door = FindEntityByClassname(door, "prop_door_rotating")) != -1)
		{
			float door_pos[3]
			GetEntPropVector(door, Prop_Data, "m_vecOrigin", door_pos)
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				PushArrayCell(g_DoorList, door)
			}
		}
	}
}