#pragma semicolon 1
#include <sourcemod>

#include <test_datapack_include>

public OnPluginStart()
{
	RegAdminCmd("sm_pack", CMD_pack, ADMFLAG_CONFIG, "no comments");
}

public Action:CMD_pack(client, args)
{
	DataPack data;
	
	for (int i = 1; i <= 20; i++)
	{
		data = CreateDataPack();
		WritePackCell(data, i);
		
		if (ClosePack(data))
		{
			PrintToChatAll("CMD_pack: set pack %d", i);
		}
	}
	
	CreateTimer(1.0, DumpHandles);
	
	return Plugin_Handled;
}

Action:DumpHandles(Handle timer)
{
	ServerCommand("sm_dump_handles addons/sourcemod/logs/handle_data_search.txt");
	PrintToChatAll("sm_dump_handles addons/sourcemod/logs/handle_data_search.txt");
}