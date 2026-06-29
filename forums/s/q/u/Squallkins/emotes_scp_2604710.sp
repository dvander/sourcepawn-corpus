#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.04"

#include <sourcemod>
#include <scp>
#include <sdktools>
#include <sdkhooks>
#include <emotes>

#pragma newdecls required

ConVar g_AnimateEmotes;
ConVar g_EmoteCooldown;
ConVar g_EmoteTime;
ConVar g_EmoteScale;

ConVar g_RoundTime;

StringMap g_hEmoteMap;
KeyValues g_hEmoteConfig;
int g_iEmotes[MAXPLAYERS + 1][EMOTES_MAX_EMOTES_PER_PLAYER];
float g_fTimeToKillEmote[MAXPLAYERS + 1][EMOTES_MAX_EMOTES_PER_PLAYER];
float g_fTimeUsedEmote[MAXPLAYERS + 1] =  { 0.0, ... };
// Emote animation
int g_iFramesToMove[MAXPLAYERS + 1][EMOTES_MAX_EMOTES_PER_PLAYER]; 

// Handles
Handle g_hOnEmoteSpawnSay;

public Plugin myinfo = 
{
	name = "Emotes v1.04",
	author = PLUGIN_AUTHOR,
	description = "Display emotes above your head",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	HookEvent("player_death", Event_PlayerDeath);
	
	g_AnimateEmotes = 	CreateConVar("emotes_animate_emotes", "1", "Should the emotes animate or just snap (Setting this to 0 will increase server performance if needed)");
	g_EmoteCooldown = 	CreateConVar("emotes_emote_cooldown", "3.0", "Time in seconds before you can use another emote");
	g_EmoteTime =		CreateConVar("emotes_emote_time", "3.0", "Time in seconds an emote lasts");
	g_EmoteScale =		CreateConVar("emotes_emote_scale", "0.1", "The scale of the emote (0.1 is default for some reason)");
	
	g_RoundTime = FindConVar("mp_roundtime");
	
	g_hOnEmoteSpawnSay = CreateGlobalForward("Emotes_OnEmoteSpawnSay", ET_Event, Param_Cell, Param_String);
	
	g_hEmoteMap = new StringMap();
	g_hEmoteConfig = new KeyValues("emotes");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), EMOTE_CONFIG);
	if(!g_hEmoteConfig.ImportFromFile(path))
		SetFailState("Could not load emotes");
		
	LoadEmotes();
	for (int i = 1; i <= MaxClients; i++)
	{
		InitializeClientEmotesArray(i);
	}

	
	
	RegAdminCmd("sm_emote", Command_Emote, ADMFLAG_ROOT);
	RegAdminCmd("sm_clearemotes", Command_ClearEmotes, ADMFLAG_ROOT);
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	CreateNative("Emotes_SpawnEmote", Native_SpawnEmote);
	CreateNative("Emotes_ClearEmotes", Native_ClearEmotes);
	CreateNative("Emotes_GetEmoteMaterial", Native_GetEmoteMaterial);
	CreateNative("Emotes_IsEmote", Native_IsEmote);

	RegPluginLibrary("emotes");
	return APLRes_Success;
}

public void OnPluginEnd()
{
	ClearAllEmotes();
}

public int Native_SpawnEmote(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return INVALID_ENT_REFERENCE;
		
	char key[64];
	GetNativeString(2, key, sizeof(key));
	
	return SpawnEmote(client, key, GetNativeCell(3), GetNativeCell(4));
}

public int Native_ClearEmotes(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return;

	ClearClientEmotes(client);
}

public int Native_GetEmoteMaterial(Handle plugin, int numParams)
{
	char key[64];
	GetNativeString(1, key, sizeof(key));
	
	char material[PLATFORM_MAX_PATH];
	g_hEmoteMap.GetString(key, material, PLATFORM_MAX_PATH);
	SetNativeString(2, material, GetNativeCell(3));
}

public int Native_IsEmote(Handle plugin, int numParams)
{
	char key[64];
	GetNativeString(1, key, sizeof(key));
	
	return IsEmote(key);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	ClearClientEmotes(client);
}

public Action Command_Emote(int client, int args)
{
	if(args != 4)
	{
		ReplyToCommand(client, "%s Usage: \x04sm_emote <client> <emote> <scale> <duration>", EMOTES_PREFIX);
		return Plugin_Handled;
	}
	
	char arg[65], arg2[65], arg3[65], arg4[65];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	
	if(!IsEmote(arg2))
	{
		ReplyToCommand(client, "%s \x04%s\x09 is not an emote!", EMOTES_PREFIX, arg2);
		return Plugin_Handled;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS + 1];
	int target_count;
	
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS + 1,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
		SpawnEmote(target_list[i], arg2, StringToFloat(arg3), StringToFloat(arg4));

	return Plugin_Handled;
}

public Action Command_ClearEmotes(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "%s Usage: \x04sm_clearemotes <client>", EMOTES_PREFIX);
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS + 1];
	int target_count;
	
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS + 1,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
		ClearClientEmotes(target_list[i]);
	return Plugin_Handled;
}

public Action OnChatMessage(int &client, Handle hRecipients, char[] sName, char[] message)
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
		
	
	StripQuotes(message);
	
	Action result = Plugin_Continue;
	Call_StartForward(g_hOnEmoteSpawnSay);
	Call_PushCell(client);
	Call_PushStringEx(message, MAXLENGTH_MESSAGE, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(result);
	
	switch(result)
	{
		case Plugin_Handled:
		{
			return Plugin_Continue;
		}
		case Plugin_Stop:
		{
			return Plugin_Continue;
		}
		default:
		{
			float time = 0.0;
			if(g_fTimeUsedEmote[client] != 0.0)
			{
				time = g_EmoteCooldown.FloatValue;
				time -= GetGameTime() - g_fTimeUsedEmote[client];
			}
			
			if(time > 0.0)
				return IsEmote(message) ? Plugin_Handled:Plugin_Continue;
			
			return SpawnEmote(client, message, g_EmoteScale.FloatValue, g_EmoteTime.FloatValue)!=INVALID_ENT_REFERENCE?Plugin_Handled:Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void LoadEmotes()
{
	g_hEmoteConfig.Rewind();
	g_hEmoteConfig.GotoFirstSubKey();
	char key[EMOTES_KEY_LENGTH];
	char materialPath[PLATFORM_MAX_PATH];
	char matVTF[PLATFORM_MAX_PATH];
	do
	{
		g_hEmoteConfig.GetString("key", key, EMOTES_KEY_LENGTH);
		g_hEmoteConfig.GetString("material", materialPath, PLATFORM_MAX_PATH);
		
		Format(matVTF, sizeof(matVTF), "%s.vtf", materialPath);
		Format(materialPath, sizeof(materialPath), "%s.vmt", materialPath);
		
		g_hEmoteMap.SetString(key, materialPath, false);
		PrintToServer("[emotes.smx] Emote: '%s' loaded successfully.", key);
	} while (g_hEmoteConfig.GotoNextKey());
}

public void PrecacheEmotes()
{
	g_hEmoteConfig.Rewind();
	g_hEmoteConfig.GotoFirstSubKey();
	char materialPath[PLATFORM_MAX_PATH];
	char matVTF[PLATFORM_MAX_PATH];
	do
	{
		g_hEmoteConfig.GetString("material", materialPath, PLATFORM_MAX_PATH);
		
		Format(matVTF, sizeof(matVTF), "%s.vtf", materialPath);
		Format(materialPath, sizeof(materialPath), "%s.vmt", materialPath);

		AddFileToDownloadsTable(materialPath);
		AddFileToDownloadsTable(matVTF);
		
		PrecacheModel(materialPath);

	} while (g_hEmoteConfig.GotoNextKey());
}

public void ClearAllEmotes()
{
	for (int i = 1; i <= MaxClients; i++)
		ClearClientEmotes(i);
}

public bool IsEmote(const char[] key)
{
	char material[PLATFORM_MAX_PATH];
	g_hEmoteMap.GetString(key, material, PLATFORM_MAX_PATH);
	if(StrEqual(material, ""))
		return false;
	return true;
}

public int SpawnEmote(int client, const char[] key, float scale, float duration)
{
	char material[PLATFORM_MAX_PATH];
	g_hEmoteMap.GetString(key, material, PLATFORM_MAX_PATH);
	if(StrEqual(material, ""))
		return INVALID_ENT_REFERENCE;
		
	int sprite = CreateEntityByName("env_sprite_oriented");
	float pos[3];
	GetClientAbsOrigin(client, pos);
	if(IsPlayerAlive(client))
		pos[2] += 80.0 + ((g_EmoteScale.FloatValue * 5) * (g_EmoteScale.FloatValue * 5));
	DispatchKeyValue(sprite, "spawnflags", "1");
	DispatchKeyValueFloat(sprite, "scale", scale);
	DispatchKeyValue(sprite, "model", material); 
	DispatchSpawn(sprite);
	TeleportEntity(sprite, pos, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(sprite, "SetParent", client);
	
	ShiftEmoteQueue(client);
	g_iEmotes[client][0] = EntIndexToEntRef(sprite);
	
	// If duration is 0, emote will last until round end
	if(duration <= 0.0)
		duration = g_RoundTime.FloatValue * 60.0;
		
	g_fTimeToKillEmote[client][0] = GetGameTime() + duration;
	
	if(g_AnimateEmotes.BoolValue)
		g_iFramesToMove[client][0] = EMOTES_FRAMES_TO_MOVE_EMOTE;
	
	g_fTimeUsedEmote[client] = GetGameTime();
	return sprite;
}

public void OnGameFrame()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			for (int i = 0; i < EMOTES_MAX_EMOTES_PER_PLAYER; i++)
			{
				int ent = EntRefToEntIndex(g_iEmotes[client][i]);
				if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
				{
					if(g_AnimateEmotes.BoolValue)
					{
						if(g_iFramesToMove[client][i]-- > 0)
						{
							float pos[3];
							GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
							float temp = float(g_iFramesToMove[client][i]) / 200.0;
							pos[2] += temp * temp;
							TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
						}
					}
					if(GetGameTime() > g_fTimeToKillEmote[client][i])
						ClearClientEmote(client, i);
				}
			}
		}
	}
}

public void ShiftEmoteQueue(int client)
{
	int ent = EntRefToEntIndex(g_iEmotes[client][EMOTES_MAX_EMOTES_PER_PLAYER - 1]);
	if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
		AcceptEntityInput(ent, "Kill");
	g_iEmotes[client][EMOTES_MAX_EMOTES_PER_PLAYER - 1] = INVALID_ENT_REFERENCE;
	
	for (int i = EMOTES_MAX_EMOTES_PER_PLAYER - 2; i >= 0; i--)
	{
		g_iEmotes[client][i+1] = g_iEmotes[client][i];
		g_fTimeToKillEmote[client][i+1] = g_fTimeToKillEmote[client][i];
		if(g_AnimateEmotes.BoolValue)
		{
			g_iFramesToMove[client][i+1] = EMOTES_FRAMES_TO_MOVE_EMOTE;
		}
		else
		{
			ent = EntRefToEntIndex(g_iEmotes[client][i+1]);
			if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
			{
				float pos[3];
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
				pos[2] += EMOTE_SNAP_OFFSET;
				TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
			}
		}	
	}
}

public void InitializeClientEmotesArray(int client)
{
	for (int i = 0; i < EMOTES_MAX_EMOTES_PER_PLAYER; i++)
	{
		g_iEmotes[client][i] = INVALID_ENT_REFERENCE;
		g_iFramesToMove[client][i] = 0;
		g_fTimeToKillEmote[client][i] = 0.0;
	}
}

public void ClearClientEmote(int client, int emoteIndex)
{
	int ent = EntRefToEntIndex(g_iEmotes[client][emoteIndex]);
	if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
		AcceptEntityInput(ent, "Kill");
	g_iEmotes[client][emoteIndex] = INVALID_ENT_REFERENCE;
	g_iFramesToMove[client][emoteIndex] = 0;
	g_fTimeToKillEmote[client][emoteIndex] = 0.0;
}

public void ClearClientEmotes(int client)
{
	for (int i = 0; i < EMOTES_MAX_EMOTES_PER_PLAYER; i++)
		ClearClientEmote(client, i);
		
	g_fTimeUsedEmote[client] = 0.0;
}

public bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public void OnClientDisconnect(int client)
{
	ClearClientEmotes(client);
}

public void OnMapStart()
{
	PrecacheEmotes();
}
