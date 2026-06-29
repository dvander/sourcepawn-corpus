#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_functions>

static const char
	PL_NAME[]	= "Simple Entity Remover",
	PL_VER[]	= "1.1.0_25.07.2025 (rewritten by Grey83)";

public Plugin myinfo =
{
	name	= PL_NAME,
	version	= PL_VER,
	author	= "little_froy",
	url		= "https://forums.alliedmods.net/showthread.php?t=351332"
}

ArrayList
	hClassnames;
char
	sPath[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	CreateConVar("simple_entity_remover_version", PL_VER, PL_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

	ConVar convar = CreateConVar("simple_entity_remover_path", "data/simple_entity_remover.txt", "load this file");
	convar.AddChangeHook(ConVar_Changed);
	ConVar_Changed(convar, "", "");

//	AutoExecConfig(true, "simple_entity_remover");

	RegAdminCmd("sm_simple_entity_remover_reload", Cmd_Reload, ADMFLAG_ROOT, "reload config data from file");
	RegAdminCmd("sm_ser_reload", Cmd_Reload, ADMFLAG_ROOT, "reload config data from file");

	hClassnames = new ArrayList(ByteCountToCells(64));
}

public void ConVar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	sPath[0] = 0;

	char buffer[PLATFORM_MAX_PATH];
	convar.GetString(buffer, sizeof(buffer));
	if(strlen(buffer) < 5) ThrowError("Invalid path: \"%s\"", buffer);

	BuildPath(Path_SM, sPath, sizeof(sPath), buffer);
	load_list();
}

public void OnConfigsExecuted()
{
	if(hClassnames.Length)
	{
		return;
	}

	char cls[64];
	for(int i, entity = MaxClients + 1, num = hClassnames.Length; i < num; i++)
	{
		hClassnames.GetString(i, cls, sizeof(cls));
		while((entity = FindEntityByClassname(entity, cls)) > MaxClients)
		{
			RequestFrame(frame_remove, EntIndexToEntRef(entity));
		}
	}
}

public Action Cmd_Reload(int client, int args)
{
	if(load_list())
		ReplyToCommand(client, "[SER] %i classnames loaded.", hClassnames.Length);
	else ReplyToCommand(client, "[SER] The wrong path to the configuration file.", hClassnames.Length);
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > MaxClients && hClassnames.Length && hClassnames.FindString(classname) != -1)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
	}
}

public void OnSpawnPost(int entity)
{
	RequestFrame(frame_remove, EntIndexToEntRef(entity));
}

public void frame_remove(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != -1)
	{
		RemoveEntity(entity);
	}
}

bool load_list()
{
	hClassnames.Clear();

	if(sPath[0] && FileExists(sPath))
	{
		File fl = OpenFile(sPath, "r");
		if(fl)
		{
			int delimiter;
			char line[PLATFORM_MAX_PATH];
			while(!fl.EndOfFile())
			{
				if(fl.ReadLine(line, sizeof(line)))
				{
					if((delimiter = get_string_comment_index(line)) > 1)
					{
						line[delimiter] = 0;
					}
					else continue;

					if(TrimString(line))
					{
						hClassnames.PushString(line);
					}
				}
			}
			delete fl;

			return true;
		}
	}

	return false;
}

int get_string_comment_index(const char[] str)
{
	bool ignoring;
	for(int i, len = strlen(str); i < len; i++)
	{
		if(ignoring)
		{
			if(str[i] == '"')
			{
				ignoring = false;
			}
		}
		else
		{
			if(str[i] == '"')
			{
				ignoring = true;
			}
			else if(str[i] == '/' && str[i + 1] == '/')
			{
				return i;
			}
		}
	}
	return -1;
}