#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[Any] Map Delete",
	author = "LenHard",
	description = "Deletes maps from the server.",
	version = "1.0",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_deletemaps", Cmd_DeleteMap, ADMFLAG_ROOT, "Deletes maps from the server.");
}

public Action Cmd_DeleteMap(int client, int args)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
		OpenDeletionMenu(client);
	return Plugin_Handled;
}

void OpenDeletionMenu(int client, int iPage = 0)
{
	Menu hMenu = new Menu(Menu_DeleteMaps);
	hMenu.SetTitle("Delete Maps\n ");
	
	File fFile = OpenFile("mapcycle.txt", "r");
	
	char[] sFormat = new char[PLATFORM_MAX_PATH];
	
	while (!fFile.EndOfFile() && fFile.ReadLine(sFormat, PLATFORM_MAX_PATH))
		if (strlen(sFormat) > 2)
			hMenu.AddItem(sFormat, sFormat);
	
	delete fFile;
	
	if (hMenu.ItemCount == 0)
	{
		delete hMenu;
		PrintToChat(client, "[SM] There are no maps to delete.");
	}
	else hMenu.DisplayAt(client, iPage, MENU_TIME_FOREVER);	
}

public int Menu_DeleteMaps(Menu hMenu, MenuAction hAction, int client, int iParam)
{
	switch (hAction)
	{
		case MenuAction_Select:
		{
			if (0 < client <= MaxClients && IsClientInGame(client))
			{
				char[] sInfo = new char[100];
				hMenu.GetItem(iParam, sInfo, 100);
				
				char[] sFormat = new char[PLATFORM_MAX_PATH];
				char[] sBuffer = new char[100];
				
				strcopy(sBuffer, 100, sInfo);
				ReplaceString(sBuffer, 100, "\n", "");
			   
				DirectoryListing dDir = OpenDirectory("maps/");
			   
				FileType fFileType;
			   	
				while (dDir.GetNext(sFormat, PLATFORM_MAX_PATH, fFileType))
			    {
			        if (fFileType == FileType_File && StrContains(sFormat, sBuffer) != -1)
			        {
			        	Format(sFormat, PLATFORM_MAX_PATH, "maps/%s", sFormat);
			        	DeleteFile(sFormat);
			        }
				}    
				delete dDir;

				File fFile = OpenFile("mapcycle.txt", "r");
				
				ArrayList aArray = new ArrayList(1000);
				
				while (!fFile.EndOfFile() && fFile.ReadLine(sFormat, PLATFORM_MAX_PATH))
				{
					if (strlen(sFormat) > 2 && !StrEqual(sFormat, sInfo))
					{
						ReplaceString(sFormat, 100, "\n", "");
						aArray.PushString(sFormat);
					}
				}
				
				fFile = OpenFile("mapcycle.txt", "w");
				
				for (int i = 0; i < aArray.Length; ++i)
				{
					aArray.GetString(i, sFormat, 100);
					fFile.WriteLine(sFormat);					
				}
				
				delete fFile;
				delete aArray;
				
				PrintToChat(client, "[SM] You have deleted \"\x03%s\x01\"", sInfo);
				OpenDeletionMenu(client, GetMenuSelectionPosition());
			}
		}
		case MenuAction_End: delete hMenu;
	}
} 