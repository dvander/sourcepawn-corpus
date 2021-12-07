#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#define PLUGIN_VERSION "1.1"
new Handle:BindModeCVAR = INVALID_HANDLE;
new Handle:BindAutoCVAR = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Key Binder",
	author = "hihi1210",
	description = "simple works!",
	version = PLUGIN_VERSION,
	url = "CPT"
};

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Key Binder supports Left 4 Dead or Left 4 Dead 2 only.");
	}
	RegConsoleCmd("sm_bind", cmd_BindMenu);
	CreateConVar("l4d2_bind_version", PLUGIN_VERSION, " Version of L4D2 Bind", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	BindModeCVAR = CreateConVar("l4d2_bind_mode", "1", "Bind Mode: (0: auto bind when player join ,1: player need to confrim it using menu)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	BindAutoCVAR = CreateConVar("l4d2_bind_autodisplay", "0", "auto display menu after the player join the server(only work with l4d2_bind_mode 1)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
}


public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(BindAutoCVAR) == 1 && GetConVarInt(BindModeCVAR) == 1)
	{
		CreateTimer(40.0, showbind, client);
	}
	if (GetConVarInt(BindModeCVAR) == 0)
	{
		new String:sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath),"configs/bind/bind.txt");
		
		new Handle:file = OpenFile(sPath, "rb");
		if(file == INVALID_HANDLE)
		return;
		
		new String:readData[256];
		while(!IsEndOfFile(file) && ReadFileLine(file, readData, sizeof(readData)))
		{
			ClientCommand(client, readData);
		}
		CloseHandle(file);
	}
}

public Action:showbind(Handle:timer, any:client)
{
	BindMenu(client);
}

public Action:cmd_BindMenu(client,args)
{
	BindMenu(client);
}

public Action:BindMenu(client)
{
	new Handle:TeamPanel = CreatePanel();
	SetPanelTitle(TeamPanel, "Do you want to bind your buttons?");
	DrawPanelText(TeamPanel, "Information:");
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/bind/panel.txt");
	
	new Handle:file = OpenFile(sPath, "rb");
	if(file == INVALID_HANDLE)
	return;
	
	new String:readData[256];
	while(!IsEndOfFile(file) && ReadFileLine(file, readData, sizeof(readData)))
	{
		DrawPanelText(TeamPanel,  readData);
	}
	CloseHandle(file);

	DrawPanelItem(TeamPanel, "Yes");
	DrawPanelItem(TeamPanel, "No");
	SendPanelToClient(TeamPanel, client, BindMenu_Handler, 30);
	CloseHandle(TeamPanel);
}
public BindMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select )
	{
		switch (param2)
		{
		case 1: // usual
			{
				new String:sPath[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, sPath, sizeof(sPath),"configs/bind/bind.txt");
				
				new Handle:file = OpenFile(sPath, "rb");
				if(file == INVALID_HANDLE)
				return;
				
				new String:readData[256];
				while(!IsEndOfFile(file) && ReadFileLine(file, readData, sizeof(readData)))
				{
					ClientCommand(param1, readData);
				}
				CloseHandle(file);
			}
		case 2:
			{
				return;
			}
		}
	}
}