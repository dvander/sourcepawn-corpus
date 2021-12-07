#pragma semicolon 1
#include <sourcemod>
#include <pscd>

#define MAXSIZECHAR 256
#define MAXSIZEABUSEARRAY 512
#define KVTYPE "antimapabuse"
//#define BUFFER_PATH_DEFAULT "cfg/sourcemod/antimapabuse/maps/default.cfg"

enum Change
{
	String:Value[MAXSIZECHAR],
	String:NewValue[MAXSIZECHAR],
	Invalid
};

enum Enable
{
	String:Value[MAXSIZECHAR],
	Invalid
};

enum Disable
{
	String:Value[MAXSIZECHAR],
	Invalid
};

enum Abuse
{
	INVALIDABUSE=-1,
	Changed=0,
	Enabled=1,
	Disabled=2
};

char change[MAXSIZEABUSEARRAY][Change];
char enable[MAXSIZEABUSEARRAY][Enable];
char disable[MAXSIZEABUSEARRAY][Disable];
Handle cvarDebug = INVALID_HANDLE;
int Debug = 0;

public void OnMapStart()
{
	cvarDebug = CreateConVar("sm_antimapabuse_debug", "0", "If is turn on see all the command send by Point_ServerCommand entity");
	HookConVarChange(cvarDebug,CvarChanges);
	for (int index = 0; index < MAXSIZEABUSEARRAY; index++)
	{
		Format(enable[index][view_as<Enable>Value], MAXSIZECHAR,"");
		Format(disable[index][view_as<Disable>Value], MAXSIZECHAR,"");
		Format(change[index][view_as<Change>Value], MAXSIZECHAR,"");
		Format(change[index][view_as<Change>NewValue], MAXSIZECHAR,"");
	}
	LoadConfig();
}

public OnConfigsExecuted()
{
	Debug = GetConVarInt(cvarDebug);
}

public void CvarChanges(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvarDebug)
	{
		Debug = GetConVarInt(convar);
	}
}

public Action PointServerCommandForward(const char[] sCommand)
{
	if(Debug==1)
	{
		PrintToChatAll("[AntiMapAbuse] %s", sCommand);
		PrintToServer("[AntiMapAbuse] %s", sCommand);
	}
	for (int index = 0; index < MAXSIZEABUSEARRAY; index++)
	{
		if(StrContains(sCommand, enable[index][view_as<Enable>Value])!= -1 && StrEqual(enable[index][view_as<Enable>Value],"") == false) //65 is for the size of enum abuse
		{
			//PrintToServer("Commande ok: %s", sCommand);
			return Plugin_Continue;
		}

		if(StrContains(sCommand, disable[index][view_as<Disable>Value])!= -1 && StrEqual(disable[index][view_as<Disable>Value], "") == false)
	    {
	    	PrintToServer("This command as been stopped : %s", sCommand);
	    	return Plugin_Stop;
	    }

		if(StrContains(sCommand, change[index][view_as<Change>Value])!= -1 && StrEqual(change[index][view_as<Change>Value], "") == false)
	    {
	    	PrintToServer("This command as been modified : %s to : %s", sCommand, change[index][view_as<Change>NewValue]);
	    	ServerCommand(change[index][NewValue]);
	    	return Plugin_Changed;
	    }
	}
	return Plugin_Continue;
}  

stock void LoadConfig()
{
	Handle hKeyValues = CreateKeyValues("antimapabuse");
	char buffer_map[128];
	char buffer_path[PLATFORM_MAX_PATH];
	
	GetCurrentMap(buffer_map, sizeof(buffer_map));
	Format(buffer_path, sizeof(buffer_path), "cfg/sourcemod/antimapabuse/maps/%s.cfg", buffer_map);

	FileToKeyValues(hKeyValues, buffer_path);

	if(CheckFile(buffer_path))
	{
		ReadKVAntiMapAbuse(hKeyValues);
	}

	CloseHandle(hKeyValues);
}

public bool CheckFile(char[] buffer_path)
{
	if (!FileExists(buffer_path))
	{
		PrintToServer("The file %s doesn't exists", buffer_path);
		return false;		
	}
	else
	{
		PrintToServer("Loading %s", buffer_path);
		return true;
	}
}
	
stock int ReadKVAntiMapAbuse(Handle hKeyValues)
{
	KvRewind(hKeyValues);
	if (KvGotoFirstSubKey(hKeyValues))
	{
		int index=0;
		do
		{			
			char generalSection[MAXSIZECHAR];
			KvGetSectionName(hKeyValues, generalSection, sizeof(generalSection));
			Abuse GeneralAbuseSection = checkGeneralAbuseSection(hKeyValues, Abuse, generalSection);
			if(GeneralAbuseSection ==  view_as<Abuse>INVALIDABUSE)
			{
				PrintToServer("This value is not correct : %s",generalSection);
				PrintToServer("Authorized value : Change Enable Disable");
				return 0;
			}
			if(GeneralAbuseSection ==  view_as<Abuse>Disabled)
			{
				GetKVStringAndFormatDisable(hKeyValues, "Value",index);
			}
			else if(GeneralAbuseSection ==  view_as<Abuse>Enabled)
			{
				GetKVStringAndFormatEnable(hKeyValues, "Value",index);
			}
			else if(GeneralAbuseSection ==  view_as<Abuse>Changed)
			{
				GetKVStringAndFormatChange(hKeyValues, "Value",index);
				GetKVStringAndFormatChange(hKeyValues, "NewValue",index);	
			}
			index++;
		}
		while (KvGotoNextKey(hKeyValues));
		return 1;
	}
	return -1;
}

stock GetKVStringAndFormatChange(Handle hKeyValues, char[] type, int index)
{
	char key[MAXSIZECHAR];
	KvGetString(hKeyValues, type, key, sizeof(key));
	Format(change[index][view_as<Change>Value], MAXSIZECHAR, "%s", key);
}

stock GetKVStringAndFormatEnable(Handle hKeyValues, char[] type, int index)
{
	char key[MAXSIZECHAR];
	KvGetString(hKeyValues, type, key, sizeof(key));
	Format(enable[index][view_as<Enable>Value], MAXSIZECHAR, "%s", key);
}

stock GetKVStringAndFormatDisable(Handle hKeyValues, char[] type, int index)
{
	char key[MAXSIZECHAR];
	KvGetString(hKeyValues, type, key, sizeof(key));
	Format(disable[index][view_as<Enable>Value], MAXSIZECHAR, "%s", key);
}

stock Abuse checkGeneralAbuseSection(Handle hKeyValues, Abuse type, char generalSection[MAXSIZECHAR])
{
	if(StrEqual(generalSection, "Change"))
	{
		return view_as<Abuse>Changed;	
	}
	else if(StrEqual(generalSection, "Enable"))
	{
		return view_as<Abuse>Enabled;	
	}
	else if(StrEqual(generalSection, "Disable"))
	{
		return view_as<Abuse>Disabled;	
	}
	else
	{
		return view_as<Abuse>INVALIDABUSE;
	}
}

stock bool checkAbuseEnableSection(Handle hKeyValues, char EnableSection[MAXSIZECHAR])
{
	if(StrEqual(EnableSection, "Value"))
	{
		return true;	
	}
	else
	{
		return false;
	}
}