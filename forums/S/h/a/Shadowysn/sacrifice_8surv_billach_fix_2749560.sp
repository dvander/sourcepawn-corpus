#define PLUGIN_NAME "[L4D2] Kill Bill Achievement Fix"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Allow Bill in the second survivor set to trigger the achievement"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "Kill Bill Achievement Fix"
#define PLUGIN_NAME_TECH "kill_bill_achfix"

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define ACH_ID 69 // not kidding, Kill Bill's ID is literally 69

static bool isProperMap = false;
static bool shouldPrevent = true;

static bool hooked = false;

static UserMsg ach_message_id = INVALID_MESSAGE_ID;

ConVar version_cvar;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	char version_str[32];
	Format(version_str, sizeof(version_str), "%s version.", PLUGIN_NAME_SHORT);
	char cmd_str[32];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, version_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	if (IsValidEntity(0))
	{
		DoInitStuff(true);
	}
}

/*public void OnPluginEnd()
{
	
}*/

public void OnMapStart()
{
	DoInitStuff();
}

void DoInitStuff(bool find = false)
{
	ach_message_id = GetUserMessageId("AchievementEvent");
	
	char map[12];
	GetCurrentMap(map, sizeof(map));
	isProperMap = StrEqual(map, "c7m3_port", false);
	
	if (!isProperMap) return;
	
	if (find) FindRelay();
	
	// THE HOOKED MESSAGE DOESN'T SEEM TO WORK FOR PREVENTING COUNTING NICK
	if (hooked) return;
	
	hooked = true;
	if (ach_message_id > INVALID_MESSAGE_ID)
		HookUserMessage(ach_message_id, AchievementEvent, true);
}

void FindRelay(int relay = -1)
{
	if (!RealValidEntity(relay))
	{
		relay = FindEntityByTargetname(MaxClients, "generator_final_button_relay");
	}
	if (!RealValidEntity(relay)) return;
	HookSingleEntityOutput(relay, "OnTrigger", Output_OnTrigger, true);
}

public void OnEntityCreated(int entity, const char[] class)
{
	if (!isProperMap) return;
	if (!IsValidEntity(entity) || 
	(class[0] != 'l') || 
	!StrEqual(class, "logic_relay", false)) return;
	
	RequestFrame(OnEntityCreated_FrameCallback, entity);
}

void OnEntityCreated_FrameCallback(int entity)
{
	if (!IsValidEntity(entity)) return;
	
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	if (!StrEqual(name, "generator_final_button_relay", false)) return;
	
	FindRelay(entity);
}

Action AchievementEvent(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int ach_id = BfReadShort(msg);
	if (ach_id != ACH_ID) return Plugin_Continue;
	
	if (!shouldPrevent)
	{
		UnhookUserMessage(ach_message_id, AchievementEvent, true);
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

void Output_OnTrigger(const char[] output, int caller, int activator, float delay)
{
	if (!IsValidClient(activator)) return;
	int character = GetEntProp(activator, Prop_Send, "m_survivorCharacter");
	if (character != 4) return;
	
	shouldPrevent = false;
	
	/*Handle ach_event = CreateEvent("achievement_earned");
	SetEventInt(ach_event, "player", client);
	SetEventInt(ach_event, "achievement", ACH_ID);
	FireEvent(ach_event);*/
	
	Handle ach_message = StartMessageAll("AchievementEvent", USERMSG_RELIABLE);
	BfWriteShort(ach_message, ACH_ID);
	EndMessage();
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool RealValidEntity(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}

int FindEntityByTargetname(int index, const char[] findname, bool onlyNetworked = false)
{
	for (int i = index; i < (onlyNetworked ? GetMaxEntities() : (GetMaxEntities()*2)); i++) {
		if (!RealValidEntity(i)) continue;
		char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (!StrEqual(name, findname, false)) continue;
		return i;
	}
	return -1;
}