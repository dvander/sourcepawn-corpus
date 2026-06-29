#include <sourcemod>
#include "FileEditor/filesystem.inc"
#include "FileEditor/downloader.sp"

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define UPDATE_URL "http://giovani_nescau.bitbucket.org/file_editor/fe_update.txt"

#define PLUGIN_VERSION "1.0.7b"

public Plugin myinfo = 
{
	name = "[ANY] File Editor",
	author = "Nescau, filesystem permission fix by YoNer",
	description = "Allows admins to manage server files without remote access.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/nescaufsa/"
};

//Vars to identify if the client is editing something
bool g_bNextPhraseRename[MAXPLAYERS + 1];
char g_cRenamePath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

bool g_bEditLine[MAXPLAYERS + 1];
int g_iEditLine[MAXPLAYERS + 1];

bool g_bIsOpened[MAXPLAYERS + 1];
char g_cOpenedFile[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

bool g_bCreateFolder[MAXPLAYERS + 1];
char g_cCreateFolderPath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

bool g_bCreateFile[MAXPLAYERS + 1];
char g_cCreateFilePath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

bool g_bDownloadFile[MAXPLAYERS + 1];
char g_cDownloadFilePath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

//Search menu identification vars
bool g_bClientSearching[MAXPLAYERS + 1];
char g_cClientSearchPath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
char g_cCopyMovePath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
int g_iClientMenuMode[MAXPLAYERS + 1];

enum InfoMenu
{
	InfoMenu_Rename = 0,
	InfoMenu_EditLine = 1,
	InfoMenu_CreateFolder = 2,
	InfoMenu_CreateFile = 3,
	InfoMenu_DownloadFile = 4,
};

#define SearchMode_Free 0
#define SearchMode_Copy 1
#define SearchMode_Move 2

//--------------------------------------------------------------------------------------
//Code from GoD-Tony's updater updater.sp
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// cURL
	MarkNativeAsOptional("curl_OpenFile");
	MarkNativeAsOptional("curl_slist");
	MarkNativeAsOptional("curl_slist_append");
	MarkNativeAsOptional("curl_easy_init");
	MarkNativeAsOptional("curl_easy_setopt_int_array");
	MarkNativeAsOptional("curl_easy_setopt_handle");
	MarkNativeAsOptional("curl_easy_setopt_string");
	MarkNativeAsOptional("curl_easy_perform_thread");
	MarkNativeAsOptional("curl_easy_strerror");
	
	// Socket
	MarkNativeAsOptional("SocketCreate");
	MarkNativeAsOptional("SocketSetArg");
	MarkNativeAsOptional("SocketSetOption");
	MarkNativeAsOptional("SocketConnect");
	MarkNativeAsOptional("SocketSend");
	
	// SteamTools
	MarkNativeAsOptional("Steam_CreateHTTPRequest");
	MarkNativeAsOptional("Steam_SetHTTPRequestHeaderValue");
	MarkNativeAsOptional("Steam_SendHTTPRequest");
	MarkNativeAsOptional("Steam_WriteHTTPResponseBody");
	MarkNativeAsOptional("Steam_ReleaseHTTPRequest");
	
	return APLRes_Success;
}
//--------------------------------------------------------------------------------------

public void OnPluginStart()
{
	RegAdminCmd("sm_files", Cmd_OpenEditor, ADMFLAG_ROOT, "Displays a menu where you can select, rename, delete, create folders, open, create and edit text files.");
	
	RegAdminCmd("sm_downloadfile", Cmd_DownloadFile, ADMFLAG_ROOT, "Download a file to a certain path. Usage: sm_downloadfile \"web address\" \"path to save the file\" \"file name with extension\".");
	RegAdminCmd("sm_printfile", Cmd_PrintFile, ADMFLAG_ROOT, "Prints a text file to the console.\n Usage: sm_printfile \"file path\".");													
	RegAdminCmd("sm_renamefile", Cmd_RenameFile, ADMFLAG_ROOT, "Renames a file/folder with the given name. Usage: sm_renamefile \"file path\" \"new file name\".");
	RegAdminCmd("sm_delete", Cmd_Delete, ADMFLAG_ROOT, "Deletes a file/folder from the given path. Usage: sm_delete \"file path\".");
	RegAdminCmd("sm_copyfile", Cmd_CopyFile, ADMFLAG_ROOT, "Copies a file to another directory. Usage: sm_copyfile \"file path\" \"final path\".");
	RegAdminCmd("sm_movefile", Cmd_MoveFile, ADMFLAG_ROOT, "Moves a file to another directory. Usage: sm_movefile \"file path\" \"final path\".");
	RegAdminCmd("sm_createfile", Cmd_CreateFile, ADMFLAG_ROOT, "Creates a file on the given path. Usage: sm_createfile \"path where the file will be created\" \"file name with extension\".");
	RegAdminCmd("sm_createfolder", Cmd_CreateFolder, ADMFLAG_ROOT, "Creates a folder on the given path. Usage: sm_createfolder \"path where the folder will be created\" \"folder name\".");
	
	CreateConVar("sm_fileeditor_version", PLUGIN_VERSION, "Plugin version.", FCVAR_NOTIFY);
	
	AddCommandListener(Command_PlayerSay, "say");
	AddCommandListener(Command_PlayerSay, "say_team");
	
	//Updater
	#if defined _updater_included
	
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
  	}
  	
  	#endif
}

public void OnClientDisconnect(int client)
{
	//Clear all vars
	StopChatWait(client, false); //Clears chat edition vars.
	
	g_bClientSearching[client] = false;
	strcopy(g_cClientSearchPath[client], sizeof(g_cClientSearchPath[]), "");
	strcopy(g_cCopyMovePath[client], sizeof(g_cCopyMovePath[]), "");
	g_iClientMenuMode[client] = SearchMode_Free;
}

//---------------------------------------------------------
//Updater
#if defined _updater_included

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}

public int Updater_OnPluginUpdated()
{
	PrintToServer("[File Editor] New version downloaded.");
}

#endif
//---------------------------------------------------------

///////////////////////////////////////////////////////////////////////////[CONSOLE EDITOR]///////////////////////////////////////////////////////////////////////////
public Action Cmd_DownloadFile(int client, int args)
{
	if (args == 3)
	{
		char arg1[256], arg2[PLATFORM_MAX_PATH], arg3[PLATFORM_MAX_PATH];
		
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		
		Format(arg2, sizeof(arg2), "%s\\%s", arg2, arg3);
		
		switch (Downloader_StartDownload(client, arg1, arg2, true))
		{
			case 2: ReplyToCommand(client, "[SM] Download failed: No download extensions are running.");
			case 3: ReplyToCommand(client, "[SM] Download failed: A download is already in progress.");
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_downloadfile \"web address\" \"path to save the file\" \"file name with extension\".");
	}
}

public Action Cmd_CreateFile(int client, int args)
{
	if (args == 2)
	{
		char fileDir[PLATFORM_MAX_PATH];
		char fileName[PLATFORM_MAX_PATH];
		
		GetCmdArg(1, fileDir, PLATFORM_MAX_PATH);
		GetCmdArg(2, fileName, PLATFORM_MAX_PATH);
		
		FormatPathToFolderString(fileDir);
		
		if (CreateFile(fileDir, fileName))
		{
			ReplyToCommand(client, "[SM] File successfully created.");
		}
		
		else
		{
			ReplyToCommand(client, "[SM] Failed to create the file.");
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_createfile \"path where the file will be created\" \"file name with extension\".");
	}
}

public Action Cmd_CreateFolder(int client, int args)
{
	if (args == 2)
	{
		char folderDir[PLATFORM_MAX_PATH];
		char folderName[PLATFORM_MAX_PATH];
		
		GetCmdArg(1, folderDir, PLATFORM_MAX_PATH);
		GetCmdArg(2, folderName, PLATFORM_MAX_PATH);
		
		FormatPathToFolderString(folderDir);
		
		if (CreateFolder(folderDir, folderName))
		{
			ReplyToCommand(client, "[SM] Folder successfully created.");
		}
		
		else
		{
			ReplyToCommand(client, "[SM] Failed to create the folder.");
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_createfolder \"path where the folder will be created\" \"folder name\".");
	}
}

/*
 * Opens the file and reply line by line for the user.
 */
public Action Cmd_PrintFile(int client, int args)
{
	if (args == 1)
	{	
		char fileDir[PLATFORM_MAX_PATH];
		GetCmdArg(1, fileDir, PLATFORM_MAX_PATH);
		
		char lineBuffer[4096];
		int linecount = 0;
		bool haveText = false;	
		
		File file = OpenFile(fileDir, "r");
		
		if (file != null)
		{
			ReplyToCommand(client, "\n\n========================================[READING FILE \"%s\"]========================================\n", fileDir);
			
			while (file.ReadLine(lineBuffer, 4096))
			{
				if ((!file.EndOfFile() && !StrEqual(lineBuffer, "")) || (!file.EndOfFile() && StrEqual(lineBuffer, "")) || (StrEqual(lineBuffer, "")))
				{				
					ReplyToCommand(client, "%d. %s", (linecount + 1), lineBuffer);
					
					haveText = true;
					linecount++;
					strcopy(lineBuffer, 4096, "");
				}
			}
			
			if (!haveText)
			{
				ReplyToCommand(client, "########################################[This file is empty]########################################");
			}
			
			file.Close();
			
			ReplyToCommand(client, "\n========================================[END OF THE FILE]========================================\n\n");
		}
		
		else
		{
			ReplyToCommand(client, "[SM] Couldn't open file %s", fileDir);
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_printfile \"file path\".");
	}
}

public Action Cmd_RenameFile(int client, int args)
{
	if (args == 2)
	{
		char fileDir[PLATFORM_MAX_PATH];
		char newName[PLATFORM_MAX_PATH];
		
		GetCmdArg(1, fileDir, PLATFORM_MAX_PATH);
		GetCmdArg(2, newName, PLATFORM_MAX_PATH);
		
		//FormatPathToFolderString(fileDir);
	
		
		if (strlen(fileDir) >= 1)
		{		
	
			ReplyToCommand(client, "[SM] %s", (FRename(fileDir, newName) ? (IsPathFolder(fileDir) ? "Folder renamed." : "File renamed.") : "Failed to rename."));
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_rename \"file path\" \"new name\".");
	}
}

public Action Cmd_Delete(int client, int args)
{
	if (args == 1)
	{
		char path[PLATFORM_MAX_PATH];
		GetCmdArg(1, path, PLATFORM_MAX_PATH);
		
		if (strlen(path) >= 1)
		{
			if (IsPathFolder(path))
			{
				if (RemoveDir(path))
				{
					ReplyToCommand(client, "[SM] Folder \"%s\" deleted.", path);
				}
				
				else
				{
					ReplyToCommand(client, "[SM] Failed to delete folder \"%s\".", path);
				}
			} 
			
			else 
			{
				if (DeleteFile(path))
				{
					ReplyToCommand(client, "[SM] File \"%s\" deleted.", path);
				}
				
				else
				{
					ReplyToCommand(client, "[SM] Failed to delete file \"%s\".", path);
				}
			}
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_delete \"file path/folder path\".");
	}
}

public Action Cmd_CopyFile(int client, int args)
{
	if (args == 2)
	{
		char fileDir[PLATFORM_MAX_PATH];
		char finalDir[PLATFORM_MAX_PATH];
		
		GetCmdArg(1, fileDir, PLATFORM_MAX_PATH);
		GetCmdArg(2, finalDir, PLATFORM_MAX_PATH);
		
		FormatPathToFolderString(fileDir);
		
		ReplyToCommand(client, "[SM] %s", (CopyFile(fileDir, finalDir) ? "File %s copied to %s." : "Failed to copy %s to %s."), fileDir, finalDir);
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_copyfile \"file path\" \"final path\".");
	}
}

public Action Cmd_MoveFile(int client, int args)
{
	if (args == 2)
	{
		char fileDir[PLATFORM_MAX_PATH];
		char finalDir[PLATFORM_MAX_PATH];
		
		GetCmdArg(1, fileDir, PLATFORM_MAX_PATH);
		GetCmdArg(2, finalDir, PLATFORM_MAX_PATH);
		
		FormatPathToFolderString(fileDir);
		
		ReplyToCommand(client, "[SM] %s", (MoveFile(fileDir, finalDir) ? "File %s moved to %s." : "Failed to move %s to %s."), fileDir, finalDir);
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_movefile \"file path\" \"final path\".");
	}
}

///////////////////////////////////////////////////////////////////////////[MENU EDITOR]///////////////////////////////////////////////////////////////////////////
public Action Cmd_OpenEditor(int client, int args)
{
	if (IsValidClient(client))
	{
		DisplayMenuAtPath(client, "\\", SearchMode_Free, "");
	}
}

/*
 * Displays all files inside a folder.
 * Modes are: Common (SearchMode_Free), Copy (SearchMode_Copy), Move (SearchMode_Move).
 * Each mode changes what the menu will do.
 * While the menu is open, some variables are used to indicate paths, modes, etc.
 */
void DisplayMenuAtPath(int client, char[] path, int mode, char[] finalpath)
{
	RemoveReturnFolderDots(path);
	
	g_bClientSearching[client] = true;
	g_iClientMenuMode[client] = mode;
	strcopy(g_cClientSearchPath[client], PLATFORM_MAX_PATH, path);
	strcopy(g_cCopyMovePath[client], PLATFORM_MAX_PATH, finalpath);
	
	Menu menu = new Menu(SelectPath);
	DirectoryListing dirs = OpenDirectory(path);
	char buffer[256];
	FileType fileType;
	char pathBuffer[PLATFORM_MAX_PATH];
	bool anyFileFound = false;
	
	if (mode == SearchMode_Free)
	{
		menu.SetTitle("Remote server file manager\nCurrent directory: \"%s\"", path);
		menu.AddItem(path, "Options...");
	}
	
	else if (mode == SearchMode_Copy)
	{
		menu.SetTitle("Select where you want to copy \"%s\".\nCurrent directory: \"%s\"", finalpath, path);
		menu.AddItem(path, "Copy here...");
	}
	
	else if (mode == SearchMode_Move)
	{
		menu.SetTitle("Select where you want to move \"%s\".\nCurrent directory: \"%s\"", finalpath, path);
		menu.AddItem(path, "Move here...");
	}
	
	while(dirs.GetNext(buffer, sizeof(buffer), fileType))
	{
		if (!StrEqual(buffer, "."))
		{
			if (StrEqual(buffer, "..") && StrEqual(path, "\\"))
			{
				continue;
			}
			
			if (fileType == FileType_Directory)
			{
				Format(buffer, sizeof(buffer), "%s\\", buffer);
			}
			
			if (StrEqual(path, "\\"))
			{
				strcopy(pathBuffer, sizeof(pathBuffer), buffer);
			} 
			
			else 
			{
				Format(pathBuffer, sizeof(pathBuffer), "%s%s", path, buffer);
			}

			menu.AddItem(pathBuffer, buffer);
			anyFileFound = true;
		}
	}
	
	if (!anyFileFound)
	{
		menu.AddItem("#DISABLED", "Nothing inside this folder.", ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	delete dirs;
}

public int SelectPath(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Select)
	{
		char path[PLATFORM_MAX_PATH];
		menu.GetItem(param2, path, PLATFORM_MAX_PATH);
		
		if (param2 == 0)
		{
			if (g_iClientMenuMode[param1] == SearchMode_Free)
			{
				OptionsMenu(param1, path);
			}
			
			else if (g_iClientMenuMode[param1] == SearchMode_Copy)
			{
				if (CopyFile(g_cCopyMovePath[param1], g_cClientSearchPath[param1]))
				{
					PrintToChat(param1, "[SM] Copied %s to %s.", g_cCopyMovePath[param1], g_cClientSearchPath[param1]);
				}
				
				else
				{
					PrintToChat(param1, "[SM] Failed to copy %s.", g_cCopyMovePath[param1]);
				}
				
				DisplayMenuAtPath(param1, g_cClientSearchPath[param1], SearchMode_Free, "");
			}
			
			else if (g_iClientMenuMode[param1] == SearchMode_Move)
			{
				if (MoveFile(g_cCopyMovePath[param1], g_cClientSearchPath[param1]))
				{
					PrintToChat(param1, "[SM] Moved %s to %s.", g_cCopyMovePath[param1], g_cClientSearchPath[param1]);
				}
				
				else
				{
					PrintToChat(param1, "[SM] Failed to move %s.", g_cCopyMovePath[param1]);
				}
				
				DisplayMenuAtPath(param1, g_cClientSearchPath[param1], SearchMode_Free, "");
			}
		}
		
		else
		{
			int strlength = strlen(path);
			
			if (strlength > 0)
			{
				if (IsModFolder(path) || IsPathReturn(path))
				{
					DisplayMenuAtPath(param1, path, g_iClientMenuMode[param1], g_cCopyMovePath[param1]);
				}
				
				else
				{
					OpenQuestionMenu(param1, path);
				}
			}
		}
	}
	
	else if (action == MenuAction_Cancel)
	{
		g_bClientSearching[param1] = false;
		strcopy(g_cClientSearchPath[param1], PLATFORM_MAX_PATH, "");
		strcopy(g_cCopyMovePath[param1], PLATFORM_MAX_PATH, "");
		g_iClientMenuMode[param1] = SearchMode_Free;
	}
}

void OptionsMenu(int client, const char[] path)
{
	Menu menu = new Menu(SelectOption);
	menu.SetTitle("Select what you want to do inside \"%s\":", path);
	menu.AddItem(path, "Create folder");
	menu.AddItem(path, "Create file");
	
	if (!Downloader_CanDownload())
	{
		menu.AddItem(path, "Download file - No download extensions available.", ITEMDRAW_DISABLED);
	}
	
	else if (Downloader_IsDownloading)
	{
		menu.AddItem(path, "Download file - A download is already in progress.", ITEMDRAW_DISABLED);
	}
	
	else
	{
		menu.AddItem(path, "Download file");
	}
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SelectOption(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Select)
	{
		char path[PLATFORM_MAX_PATH];
		menu.GetItem(param2, path, sizeof(path));
		
		if (param2 == 0)
		{
			StopChatWait(param1, false);
			
			g_bCreateFolder[param1] = true;
			strcopy(g_cCreateFolderPath[param1], sizeof(g_cCreateFolderPath[]), path);
			
			DisplayInfoMenu(param1, path, InfoMenu_CreateFolder);
		}
		
		else if (param2 == 1)
		{
			StopChatWait(param1, false);
			
			g_bCreateFile[param1] = true;
			strcopy(g_cCreateFilePath[param1], sizeof(g_cCreateFilePath[]), path);
			
			DisplayInfoMenu(param1, path, InfoMenu_CreateFile);
		}
		
		else if (param2 == 2)
		{
			StopChatWait(param1, false);
			
			g_bDownloadFile[param1] = true;
			strcopy(g_cDownloadFilePath[param1], sizeof(g_cDownloadFilePath[]), path);
			
			DisplayInfoMenu(param1, path, InfoMenu_DownloadFile);
		}
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (g_bClientSearching[param1])
		{
			DisplayMenuAtPath(param1, g_cClientSearchPath[param1], g_iClientMenuMode[param1], g_cCopyMovePath[param1]);
		}
	}
}

/*
 * Options for files/folders.
 */
void OpenQuestionMenu(int client, char[] path)
{
	Menu menu = new Menu(SelectMode);
	
	if (IsPathFile(path))
	{
		char title[256];
		char filename[128];
		float iFileSize = float(FileSize(path));
		
		GetFileName(path, filename, sizeof(filename));
		
		Format(title, sizeof(title), "%s\nSize: %.3f MB(s)\nPath: %s\nSelect the action for this file:", filename, ((iFileSize == 0.0) ? 0.0 : (iFileSize / 1048576)), path);
		
		menu.SetTitle(title);
	}
	
	else
	{
		menu.SetTitle("Select the action for \"%s\":", path);
	}
	
	menu.AddItem(path, "Open");
	menu.AddItem(path, "Rename");
	menu.AddItem(path, "Delete");
	
	if (IsPathFolder(path))
	{
		menu.AddItem(path, "Copy", ITEMDRAW_DISABLED);
		menu.AddItem(path, "Move", ITEMDRAW_DISABLED);
	}
	
	else
	{
		menu.AddItem(path, "Copy");
		menu.AddItem(path, "Move");
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SelectMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Select)
	{
		char path[PLATFORM_MAX_PATH];
		menu.GetItem(param2, path, sizeof(path));
		
		switch (param2)
		{
			case 0:
			{
				if (IsPathFolder(path))
				{
					DisplayMenuAtPath(param1, path, g_iClientMenuMode[param1], g_cCopyMovePath[param1]);
				} 
				
				else 
				{
					DisplayMenuFile(param1, path);
				}
			}
			
			case 1:
			{	
				StopChatWait(param1, false);
				
				g_bNextPhraseRename[param1] = true;
				strcopy(g_cRenamePath[param1], sizeof(g_cRenamePath[]), path);
				
				DisplayInfoMenu(param1, path, InfoMenu_Rename);
			}
			
			case 2:
			{
				if (IsPathFolder(path))
				{
					if (RemoveDir(path))
					{
						PrintToChat(param1, "[SM] Folder \"%s\" deleted.", path);
					}
					
					else
					{
						PrintToChat(param1, "[SM] Failed to delete folder \"%s\".", path);
					}
				} 
				
				else 
				{
					if (DeleteFile(path))
					{
						PrintToChat(param1, "[SM] File \"%s\" deleted.", path);
					}
					
					else
					{
						PrintToChat(param1, "[SM] Failed to delete file \"%s\".", path);
					}
				}
				
				if (g_bClientSearching[param1])
				{
					DisplayMenuAtPath(param1, g_cClientSearchPath[param1], g_iClientMenuMode[param1], g_cCopyMovePath[param1]);
				}
			}
			
			case 3:
			{
				DisplayMenuAtPath(param1, g_cClientSearchPath[param1], SearchMode_Copy, path);
			}
			
			case 4:
			{
				DisplayMenuAtPath(param1, g_cClientSearchPath[param1], SearchMode_Move, path);
			}
		}
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (g_bClientSearching[param1])
		{
			DisplayMenuAtPath(param1, g_cClientSearchPath[param1], g_iClientMenuMode[param1], g_cCopyMovePath[param1]);
		}
	}
}

/*
 * Open the file and display each line on a menu.
 * Here you will can select the line for options.
 */
void DisplayMenuFile(int client, const char[] path)
{
	g_bIsOpened[client] = true;
	strcopy(g_cOpenedFile[client], sizeof(g_cOpenedFile[]), path);
	
	Menu menu = new Menu(FileMenu);
	menu.SetTitle("Viewing file \"%s\".\nSelect a line to edit it.\n", path);
	
	char lineBuffer[4096];
	int linecount = 0;
	char lineCounter[5];
	bool haveText = false;
	
	File file = OpenFile(path, "r");
	
	if (file != null)
	{
		while (file.ReadLine(lineBuffer, sizeof(lineBuffer)))
		{
			if ((!file.EndOfFile() && !StrEqual(lineBuffer, "")) || (!file.EndOfFile() && StrEqual(lineBuffer, "")) || (StrEqual(lineBuffer, "")))
			{
				IntToString(linecount, lineCounter, 5);
				menu.AddItem(lineCounter, lineBuffer);
				haveText = true;
				
				linecount++;
				strcopy(lineBuffer, sizeof(lineBuffer), "");
			}
		}
		
		if (!haveText)
		{
			menu.AddItem("#NOTEXT", "This file have no text. Press 1 to create lines.");
		}
		
		file.Close();
	}
	
	else
	{
		menu.AddItem("#FAILEDOPEN", "Failed to open this file.", ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int FileMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, "#NOTEXT", true))
			{
				LineSelectedMenu(param1, param2, true);
			}
			
			else
			{
				LineSelectedMenu(param1, param2);
			}
		}
		
		case MenuAction_Cancel:
		{
			g_bIsOpened[param1] = false;
			strcopy(g_cOpenedFile[param1], sizeof(g_cOpenedFile[]), "");
			
			if (g_bClientSearching[param1])
			{
				DisplayMenuAtPath(param1, g_cClientSearchPath[param1], g_iClientMenuMode[param1], g_cCopyMovePath[param1]);
			}
		}
	}
}

/*
 * Displays a menu where admins can select what they want to do with the selected line.
 */
void LineSelectedMenu(int client, int line, bool IsEmpty = false)
{
	if (g_bIsOpened[client])
	{
		Menu menu = new Menu(LineSelectedEdit);
	
		if (!IsEmpty)
		{
			if (IsTextFile(g_cOpenedFile[client]))
			{
				menu.SetTitle("Editing \"%s\" line %d.\nSelect what you want to do:", g_cOpenedFile[client], line + 1);
			} 
			
			else 
			{
				menu.SetTitle("Editing \"%s\" line %d.\nWarning: This file isn't a text file, editing may get it corrupt.\nSelect what you want to do:", g_cOpenedFile[client], line + 1);
			}
		}
		
		else
		{
			if (IsTextFile(g_cOpenedFile[client]))
			{
				menu.SetTitle("Editing \"%s\", this file is empty or cannot be read.\nSelect what you want to do:", g_cOpenedFile[client]);
			} 
			
			else 
			{
				menu.SetTitle("Editing \"%s\", this file is empty or cannot be read.\nWarning: This file isn't a text file, editing may get it corrupt.\nSelect what you want to do:", g_cOpenedFile[client]);
			}
		}
		
		char cLine[32];
		IntToString(line, cLine, sizeof(cLine));
		
		if (!IsEmpty)
		{
			menu.AddItem(cLine, "Edit");
			menu.AddItem(cLine, "Delete line");
		}
		
		else
		{
			menu.AddItem(cLine, "Edit", ITEMDRAW_DISABLED);
			menu.AddItem(cLine, "Delete line", ITEMDRAW_DISABLED);
		}
		
		menu.AddItem(cLine, "New line");
		menu.AddItem(cLine, "New line at top");
		menu.AddItem(cLine, "New line at end");
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int LineSelectedEdit(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Select:
		{
			char line[32];
			menu.GetItem(param2, line, sizeof(line));
			
			if (param2 == 0)
			{
				StopChatWait(param1, false);
				
				g_bEditLine[param1] = true;
				g_iEditLine[param1] = StringToInt(line);
				
				DisplayInfoMenu(param1, g_cOpenedFile[param1], InfoMenu_EditLine, g_iEditLine[param1]);
			}
			
			else if (param2 == 1 || param2 == 2 || param2 == 3 || param2 == 4)
			{
				bool editSuccess = false;
				
				if (param2 == 1)
				{
					editSuccess = EditFileLine(g_cOpenedFile[param1], StringToInt(line), LineEdit_DeleteLine, "");
				}
				
				else if (param2 == 2)
				{
					editSuccess = EditFileLine(g_cOpenedFile[param1], StringToInt(line), LineEdit_NewLine, "");
				}
				
				else if (param2 == 3)
				{
					editSuccess = EditFileLine(g_cOpenedFile[param1], StringToInt(line), LineEdit_NewLineFileStart, "");
				}
				
				else if (param2 == 4)
				{
					editSuccess = EditFileLine(g_cOpenedFile[param1], StringToInt(line), LineEdit_NewLineFileEnd, "");
				}
				
				if (editSuccess)
				{
					PrintToChat(param1, "[SM] Line %d on file \"%s\" successfully edited.", StringToInt(line) + 1, g_cOpenedFile[param1]);
				}
				
				else
				{
					PrintToChat(param1, "[SM] Failed to edit file \"%s\".", g_cOpenedFile[param1]);
				}
				
				DisplayMenuFile(param1, g_cOpenedFile[param1]);
			}
		}
		
		case MenuAction_Cancel:
		{
			if (g_bIsOpened[param1])
			{
				DisplayMenuFile(param1, g_cOpenedFile[param1]);
			}
		}
	}
}

void DisplayInfoMenu(int client, const char[] path, InfoMenu info, int line = 0)
{
	Menu menu = new Menu(InformationMenu);
	
	char menuTitle[512];
	bool useDownload = false;
	
	if (info == InfoMenu_Rename)
	{
		Format(menuTitle, sizeof(menuTitle), "You're renaming \"%s\".\nWrite in the chat the new file name with the extension type using:\n", path);
	}
	
	else if (info == InfoMenu_EditLine)
	{
		Format(menuTitle, sizeof(menuTitle), "You're editing \"%s\" line %d.\nWrite in the chat the new text for the line using:\n", path, line + 1);
	}
	
	else if (info == InfoMenu_CreateFile)
	{
		Format(menuTitle, sizeof(menuTitle), "Creating file inside \"%s\".\nWrite the new file name in the chat using:\n", path);
	}
	
	else if (info == InfoMenu_CreateFolder)
	{
		Format(menuTitle, sizeof(menuTitle), "Creating folder inside \"%s\".\nWrite the new folder name in the chat using:\n", path);
	}
	
	else if (info == InfoMenu_DownloadFile)
	{
		Format(menuTitle, sizeof(menuTitle), "The file will be downloaded inside \"%s\".\nWrite the internet address and the file name in the chat using !editq \"address\" \"file name with extension\".\nExample: !editq \"www.example.com/my_plugin.smx\" \"my_plugin.smx\"", path);
		useDownload = true;
	}
	
	if (!useDownload)
	{
		Format(menuTitle, sizeof(menuTitle), "%s!edit <text> : Edits the line/file name/folder name/links.\n!editq <text> : Same as !edit, but simple quotes are converted in double quotes.\nExample: !edit filename.txt", menuTitle);
	}
	
	menu.SetTitle(menuTitle);
	
	menu.AddItem("#INFO", "To cancel the edition, close this menu.", ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int InformationMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	if (action == MenuAction_Cancel)
	{
		StopChatWait(param1, true);
	}
}

///////////////////////////////////////////////////////////////////////////[EDITION FUNCTIONS]///////////////////////////////////////////////////////////////////////////

void StopChatWait(int client, bool showMenus)
{
	bool openMenuFile = false;
	bool openSearchMenu = false;
	
	if (g_bNextPhraseRename[client])
	{
		g_bNextPhraseRename[client] = false;
		strcopy(g_cRenamePath[client], sizeof(g_cRenamePath[]), "");
		
		openSearchMenu = true;
	}
	
	if (g_bEditLine[client])
	{
		g_bEditLine[client] = false;
		g_iEditLine[client] = 0;
		
		openMenuFile = true;
	}
	
	if (g_bCreateFolder[client])
	{
		g_bCreateFolder[client] = false;
		strcopy(g_cCreateFolderPath[client], sizeof(g_cCreateFolderPath[]), "");
		
		openSearchMenu = true;
	}
	
	if (g_bCreateFile[client])
	{
		g_bCreateFile[client] = false;
		strcopy(g_cCreateFilePath[client], sizeof(g_cCreateFilePath[]), "");
		
		openSearchMenu = true;
	}
	
	if (g_bDownloadFile[client])
	{
		g_bDownloadFile[client] = false;
		strcopy(g_cDownloadFilePath[client], sizeof(g_cDownloadFilePath[]), "");
		
		openSearchMenu = true;
	}
	
	if (showMenus)
	{
		if (openMenuFile)
		{
			if (g_bIsOpened[client])
			{
				DisplayMenuFile(client, g_cOpenedFile[client]);
			}
		}
		
		else if (openSearchMenu)
		{
			if (g_bClientSearching[client])
			{
				DisplayMenuAtPath(client, g_cClientSearchPath[client], g_iClientMenuMode[client], g_cCopyMovePath[client]);
			}
		}
	}
}

public Action Command_PlayerSay(int client, const char[] command, int args)
{	
	if (IsValidClient(client))
	{
		if (g_bNextPhraseRename[client] || g_bEditLine[client] || g_bCreateFolder[client] || g_bCreateFile[client] || g_bDownloadFile[client])
		{			
			char argbuffer[4096];
			char finalarg[4096];
			
			bool allowedit = false;
			bool fixquotes = false;
			
			GetCmdArg(1, argbuffer, sizeof(argbuffer));
			
			if (!g_bDownloadFile[client] && (StrContains(argbuffer, "!edit") == 0 || StrContains(argbuffer, "/edit") == 0) && StrContains(argbuffer, "!editq") != 0 && StrContains(argbuffer, "/editq") != 0 && argbuffer[4] == 't')
			{
				if (strlen(argbuffer) >= 6 && argbuffer[5] == ' ')
				{
					for (int a = 6; a <= strlen(argbuffer); a++)
					{
						finalarg[a - 6] = argbuffer[a];
					}
					
					allowedit = true;
				}
			}
			
			else if ((StrContains(argbuffer, "!editq") == 0 || StrContains(argbuffer, "/editq") == 0) && argbuffer[5] == 'q')
			{
				if (strlen(argbuffer) >= 7 && argbuffer[6] == ' ')
				{
					for (int a = 7; a <= strlen(argbuffer); a++)
					{
						finalarg[a - 7] = argbuffer[a];
					}
					
					allowedit = true;
					fixquotes = true;
				}
			}
			
			if (allowedit)
			{
				if (fixquotes)
				{
					for (int a = 0; a < strlen(finalarg); a++)
					{
						if (finalarg[a] == ''')
						{
							finalarg[a] = '"';
						}
					}
				}
				
				//========
				if (g_bNextPhraseRename[client] && args > 0)
				{			
					if (FRename(g_cRenamePath[client], finalarg))
					{
						PrintToChat(client, "[SM] Rename successful. New name: %s", finalarg);
					}
					
					else
					{
						PrintToChat(client, "[SM] Failed to rename \"%s\".", g_cRenamePath[client]);
					}
					
					StopChatWait(client, true);
					
					return Plugin_Handled;
				}
				
				//========
				else if (g_bEditLine[client] && args > 0)
				{		
					if (EditFileLine(g_cOpenedFile[client], g_iEditLine[client], LineEdit_Edit, finalarg))
					{
						PrintToChat(client, "[SM] Line %d on file \"%s\" successfully edited.", g_iEditLine[client], g_cOpenedFile[client]);
					}
					
					else
					{
						PrintToChat(client, "[SM] Failed to edit file \"%s\".", g_cOpenedFile[client]);
					}
					
					StopChatWait(client, true);
					
					return Plugin_Handled;
				}
				
				//========
				else if (g_bCreateFolder[client] && args > 0)
				{
					if (CreateFolder(g_cCreateFolderPath[client], finalarg))
					{
						PrintToChat(client, "[SM] Folder %s created.", finalarg);
					}
					
					else
					{
						PrintToChat(client, "[SM] Failed to create folder %s.", finalarg);
					}
					
					StopChatWait(client, true);
					
					return Plugin_Handled;
				}
				
				//========
				else if (g_bCreateFile[client] && args > 0)
				{
					if (CreateFile(g_cCreateFilePath[client], finalarg))
					{
						PrintToChat(client, "[SM] File %s created.", finalarg);
					}
					
					else
					{
						PrintToChat(client, "[SM] Failed to create file %s.", finalarg);
					}
					
					StopChatWait(client, true);
					
					return Plugin_Handled;
				}
				
				//========
				else if (g_bDownloadFile[client] && args > 0)
				{				
					if (Downloader_IsDownloading)
					{
						PrintToChat(client, "[SM] Download failed: Another download is already in progress.");
						
						StopChatWait(client, true);
						
						return Plugin_Handled;
					}
					
					else if (!Downloader_CanDownload())
					{
						PrintToChat(client, "[SM] Download failed: No download extensions available.");
						
						StopChatWait(client, true);
						
						return Plugin_Handled;
					}
					
					else
					{
						char buff1[256];
						char buff2[256];
						
						strcopy(buff1, sizeof(buff1), "");
						strcopy(buff2, sizeof(buff2), "");
						
						int buffc = 0;
						
						int strlength = strlen(finalarg);
						
						int quotecount = 0;
						
						for (int a = 0; a <= strlength; a++)
						{
							if (finalarg[a] == '"')
							{
								quotecount++;
							}
							
							if ((quotecount > 4) || (quotecount < 4 && a == strlength))
							{
								PrintToChat(client, "[SM] Usage for download: !editq \"address\" \"file name with extension\"");
								
								StopChatWait(client, true);
								
								return Plugin_Handled;
							}
						}
						
						quotecount = 0;
						
						for (int b = 0; b <= strlength; b++)
						{
							if (finalarg[b] == '"')
							{
								quotecount++;
								
								if (quotecount == 3)
								{
									buffc = 0;
								}
							}
							
							else
							{
								if (quotecount == 1)
								{
									buff1[buffc] = finalarg[b];
									buffc++;
								}
								
								else if (quotecount == 3)
								{
									buff2[buffc] = finalarg[b];
									buffc++;
								}
								
								else if (quotecount == 4)
								{
									break;
								}
							}
							
						}
						
						if (!StrEqual(buff1, "", false) && !StrEqual(buff2, "", false))
						{
							Format(buff2, sizeof(buff2), "%s%s", g_cDownloadFilePath[client], buff2);
							PrintToChat(client, "Starting download for %s and saving to %s", buff1, buff2);
							
							switch (Downloader_StartDownload(client, buff1, buff2, true))
							{
								case 2: PrintToChat(client, "[SM] Download failed: No download extensions are running.");
								case 3: PrintToChat(client, "[SM] Download failed: A download is already in progress.");
							}
						}
						
						else
						{
							PrintToChat(client, "[SM] This command requires 2 non-empty arguments.");
						}
						
						StopChatWait(client, true);
						
						return Plugin_Handled;
					}
					//--------------------------------------------------------------------------------------
				}
			}
		}
	}
	
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////

bool IsValidClient(int client)
{
	return (client > 0 && client <= (MAXPLAYERS + 1) && IsClientConnected(client) && IsClientAuthorized(client) && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}

/*
bool IsInteger(const char[] str) //Edit from smlib String_IsNumeric
{
	int x = 0;
	int numbersFound = 0;
	
	while (str[x] != '\0')
	{
		if (IsCharNumeric(str[x])) 
		{
			numbersFound++;
		}
		
		else 
		{
			return false;
		}
		
		x++;
	}
	
	if (!numbersFound) {
		return false;
	}
	
	return true;
}*/