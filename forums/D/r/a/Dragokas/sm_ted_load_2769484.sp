#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <regex>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "tEntDev - Prop Loader",
	author = "Dragokas",
	description = "You can load properties from file and apply them to entity",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336088"
}

public void OnPluginStart()
{
	CreateConVar("sm_tentdev_prop_loader_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	RegAdminCmd	("sm_ted_load", 		Cmd_ReproduceProp,		ADMFLAG_ROOT,	"Apply properties on aim target based on the values previously saved by tEntDev (sm_ted_select)");
}

public Action Cmd_ReproduceProp(int client, int argc)
{
	char 	kvFile[PLATFORM_MAX_PATH] = "kvtest.txt";
	int 	ent, iFilterCount, cntApplied;
	char 	filter[32][64];
	bool	bMatch;
	
	if( argc == 0 )
	{
		ent = GetClientAimTarget(client, false);
		if( ent < 0 ) {
			PrintToChat(client, "Not aimed to anything!\n\n" ...
				"Using: sm_ted_load <entity index> <prop list> <prop file>\n" ...
				"All arguments are optional.\n" ...
				"By default: aim target is selected, and all properties have applied from kvtest.txt");
			return Plugin_Handled;
		}
	}
	if( argc >= 1 ) // entity
	{
		char s[16];
		GetCmdArg(1, s, sizeof(s));
		if( s[0] == 0 )
		{
			ent = GetClientAimTarget(client, false);
			if( ent < 0 ) {
				PrintToChat(client, "Not aimed to anything!");
				return Plugin_Handled;
			}
		}
		else {
			ent = StringToInt(s);
			if( !IsValidEntity(ent) )
			{
				PrintToChat(client, "Entity %i is not valid!", ent);
				return Plugin_Handled;
			}
		}
	}
	if( argc >= 2 ) // prop list or filter
	{
		Regex regex;
		char props[2048], error[128];
		GetCmdArg(2, props, sizeof(props));
		if( props[0] != 0 )
		{
			iFilterCount = ExplodeString(props, " ", filter, sizeof(filter), sizeof(filter[]), false);
			for( int i = 0; i < iFilterCount; i++ )
			{
				regex = new Regex(filter[i], PCRE_CASELESS, error, sizeof(error));
				if( !regex )
				{
					PrintToChat(client, "Regexp error (%s) in line: %s", error, filter[i]);
					return Plugin_Handled;
				}
				delete regex;
			}
		}
	}
	if( argc == 3 ) // kvtest file name
	{
		GetCmdArg(3, kvFile, sizeof(kvFile));
	}
	
	char sClass[64];
	GetEntityClassname(ent, sClass, sizeof(sClass));
	PrintToChat(client, "\x03Reproducing properties on entity: \x04%i (%s)", ent, sClass);
	
	KeyValues kv;
	char sItem[16], sName[64], sValue[64];
	int iValue;
	float fValue, vValue[3];
	
	kv = new KeyValues("loader");
	
	if( kv.ImportFromFile(kvFile) ) // tEntDev report file (root of game folder)
	{
		PrintToChat(client, "\x01File: \x04%s \x01is Loaded", kvFile);
		
		kv.Rewind();
		kv.GotoFirstSubKey();
		
		do
		{
			kv.GetSectionName(sItem, sizeof(sItem));
			kv.GetString("Name", sName, sizeof(sName));
			
			bMatch = true;
			if( iFilterCount )
			{
				bMatch = IsStringMatch(sName, filter, iFilterCount);
			}
			
			if( bMatch && HasEntProp(ent, Prop_Send, sName) )
			{
				switch( kv.GetNum("type") ) {
					case 0: { // integer
						iValue = kv.GetNum("value");
						SetEntProp(ent, Prop_Send, sName, iValue);
						PrintToConsoleQueue(client, "%s = %i", sName, iValue);
						++ cntApplied;
					}
					case 1: { // float
						fValue = kv.GetFloat("value");
						SetEntPropFloat(ent, Prop_Send, sName, fValue);
						PrintToConsoleQueue(client, "%s = %f", sName, fValue);
						++ cntApplied;
					}
					case 2: { // vector
						kv.GetVector("value", vValue);
						SetEntPropVector(ent, Prop_Send, sName, vValue);
						PrintToConsoleQueue(client, "%s = %f %f %f", sName, vValue[0], vValue[1], vValue[2]);
						++ cntApplied;
					}
					case 3: { // ??
					}
					case 4: { // string
						kv.GetString("value", sValue, sizeof(sValue), "error");
						if( !StrEqual(sValue, "error") ) {
							SetEntPropString(ent, Prop_Send, sName, sValue);
							PrintToConsoleQueue(client, "%s = %s", sName, sValue);
							++ cntApplied;
						}
					}
				}
			}
		} while( kv.GotoNextKey() );
		
		ChangeEdictState(ent, 0);
		
		PrintToChat(client, "\x03Loading \01%i \x03properties is completed for: \x04%i (%s)", cntApplied, ent, sClass);
	}
	else {
		PrintToChat(client, "\x04kvtest.txt file is not found!");
	}
	delete kv;
	return Plugin_Handled;
}

bool IsStringMatch(char[] name, char[][] filter, int size)
{
	Regex regex;
	for( int i = 0; i < size; i++ )
	{
		regex = new Regex(filter[i], PCRE_CASELESS);
		if( regex.Match(name) )
		{
			delete regex;
			return true;
		}
	}
	delete regex;
	return false;
}

void PrintToConsoleQueue(int client, const char[] format, any ...)
{
	static char buffer[254];
	static ArrayList al;
	if( !al )
	{
		al = new ArrayList(ByteCountToCells(254));
	}
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	if( al.Length == 0 )
	{
		RequestFrame(Frame_PrintQueue, al);
	}
	al.Push(client);
	al.PushString(buffer);
}

public void Frame_PrintQueue(ArrayList al)
{
	static char buffer[254];
	if( al.Length )
	{
		int client = al.Get(0);
		al.GetString(1, buffer, sizeof(buffer));
		al.Erase(1);
		al.Erase(0);
		PrintToConsole(client, "%s", buffer);
		RequestFrame(Frame_PrintQueue, al);
	}
}
