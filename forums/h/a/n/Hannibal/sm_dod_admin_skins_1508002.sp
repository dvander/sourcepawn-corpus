/*******************************************************************************

  SM Skinchooser

  Version: 1.1
  Author: Hannibal
  
  
  Update to 1.1:
  
  Added admin_skins.ini and admin_skinsdownloads.ini
    
	Everybody can edit this plugin and copy this plugin.
	
  Thanks to:
	Swat_88 for making sm_downloader and precacher
	
*******************************************************************************/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"

new String:g_modelAmer[6][256]
new String:g_modelGer[6][256]
new Handle:kv
new downloadtype
new String:mediatype[256]
new bool:downloadfiles=true;


public Plugin:myinfo =
{
	name = "DoDS Admin Skins",
	author = "Hannibal",
	description = "Simple Admin skins for DoDS",
	version = PLUGIN_VERSION,
	url = "http://fragstudios.org"
}

public OnPluginStart()
{

	HookEvent("player_spawn", PlayerSpawnEvent)
}

public OnMapStart()
{
	ReadDownloads()
	new String:file[256]
	new classid

	//tigerox
	//read in models.ini and precache
	kv = CreateKeyValues("Commands")
	BuildPath(Path_SM, file, 255, "configs/admin_skins.ini")
	FileToKeyValues(kv, file)
	
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	do
	{
		KvJumpToKey(kv, "Allied")
		KvGotoFirstSubKey(kv)
		classid = 0
		do
		{
			KvGetString(kv, "path", g_modelAmer[classid], 256,"")
			if (FileExists(g_modelAmer[classid]))
				PrecacheModel(g_modelAmer[classid],true)
			classid++
		} 
		while (KvGotoNextKey(kv))
			
		KvGoBack(kv);
		KvGoBack(kv);
		KvJumpToKey(kv, "Axis")
		KvGotoFirstSubKey(kv)
		classid = 0
		do
		{
			KvGetString(kv, "path", g_modelGer[classid], 256,"")
			if (FileExists(g_modelGer[classid]))
				PrecacheModel(g_modelGer[classid],true);
			classid++
		}
		while (KvGotoNextKey(kv))
				
		KvGoBack(kv)
		KvGoBack(kv)
				
	} 
	while (KvGotoNextKey(kv))
			
	KvRewind(kv)
}

public ReadFileFolder(String:path[])
{
	new Handle:dirh = INVALID_HANDLE
	new String:buffer[256]
	new String:tmp_path[256]
	new FileType:type = FileType_Unknown
	new len
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0'

	TrimString(path);
	
	if(DirExists(path))
	{
		dirh = OpenDirectory(path);
		while(ReadDirEntry(dirh,buffer,sizeof(buffer),type))
		{
			len = strlen(buffer);
			if (buffer[len-1] == '\n')
				buffer[--len] = '\0';

			TrimString(buffer)

			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
			{
				strcopy(tmp_path,255,path)
				StrCat(tmp_path,255,"/")
				StrCat(tmp_path,255,buffer)
				if(type == FileType_File)
				{
					if(downloadtype == 1)
					{
						ReadItem(tmp_path)
					}
				}
			}
		}
	}
	else
	{
		if(downloadtype == 1)
		{
			ReadItem(path)
		}
		
	}
	if(dirh != INVALID_HANDLE)
	{
		CloseHandle(dirh)
	}
}

public ReadDownloads()
{
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/admin_skindownloads.ini")
	new Handle:fileh = OpenFile(file, "r")
	new String:buffer[256]
	downloadtype = 1
	new len
	
	if(fileh == INVALID_HANDLE) return
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{	
		len = strlen(buffer)
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0'
		
		TrimString(buffer)
		
		if(!StrEqual(buffer,"",false))
		{
			ReadFileFolder(buffer)
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE)
	{
		CloseHandle(fileh);
	}
}

public ReadItem(String:buffer[])
{
	new len = strlen(buffer)
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0'
	
	TrimString(buffer)
	
	if(StrContains(buffer,"files",true) >= 0)
	{
		strcopy(mediatype,255,"File")
		downloadfiles=true
	}
	
	else if (StrContains(buffer,"textures",true) >= 0)
	{
		strcopy(mediatype, 255, "Texture")
		downloadfiles=true
	}
	else if (!StrEqual(buffer,"",false) && FileExists(buffer))
	{
		if(downloadfiles)
		{
			if(StrContains(mediatype,"Texture",true) >= 0)
			{
				PrecacheModel(buffer,true)
			}
			AddFileToDownloadsTable(buffer)
		}
	}
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
	new AdminId:adminid = GetUserAdmin(client)
	if (GetAdminFlag(adminid, Admin_Kick, Access_Effective) && GetClientTeam(client) == 2)
	{
		if(!IsModelPrecached(g_modelAmer[class]))
		{
			return Plugin_Handled
		}
		
		else
		{ 
			SetEntityModel(client, g_modelAmer[class])
		}
	}
		
	else if (GetAdminFlag(adminid, Admin_Kick, Access_Effective) && GetClientTeam(client) == 3)
	{
		if(!IsModelPrecached(g_modelGer[class]))
		{
			return Plugin_Handled
		}
		
		else
		{
			SetEntityModel(client, g_modelGer[class])
		}
	}
		
	return Plugin_Handled
}