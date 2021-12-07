#include <sdktools>

#pragma newdecls required

ConVar g_cvarName;
ConVar g_cvarMesasge;

int g_flagName;
int g_flagMessage;

bool g_bUse4Name[MAXPLAYERS+1];
bool g_bUse4Message[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name		= "Simple Rainbow Chat",
	author		= "Kyle",
	description	= "Rainbow chat",
	version		= "1.1",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	g_cvarName = CreateConVar("src_name_flag", "b", "Set flag for vip must have to get access to rainbow chat name feature", FCVAR_NOTIFY);
	g_cvarMesasge = CreateConVar("src_message_flag", "b", "Set flag for vip must have to get access to rainbow chat messge feature", FCVAR_NOTIFY);

	HookConVarChange(g_cvarName, HookConVar);
	HookConVarChange(g_cvarMesasge, HookConVar);
	
	AutoExecConfig(true);
	
	RegConsoleCmd("sm_rainbowname", Command_Name);
	RegConsoleCmd("sm_rainbowmsg", Command_Message);
}

public void OnConfigsExecuted()
{
	char m_szFlags[32];
	
	GetConVarString(g_cvarName, m_szFlags, 32);
	g_flagName = ReadFlagString(m_szFlags);
	
	GetConVarString(g_cvarMesasge, m_szFlags, 32);
	g_flagMessage = ReadFlagString(m_szFlags);
}

public void HookConVar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_cvarName)
		g_flagName = ReadFlagString(newValue)
	if(convar == g_cvarMesasge)
		g_flagMessage = ReadFlagString(newValue)
}

public void OnClientConnected(int client)
{
	g_bUse4Name[client] = false;
	g_bUse4Message[client] = false;
}

public Action Command_Name(int client, int args)
{
	if(g_flagName != 0 && !(GetUserFlagBits(client) & g_flagName))
	{
		PrintToChat(client, "[SM] You do not have access to this command");
		return Plugin_Handled;
	}
	
	g_bUse4Name[client] = !g_bUse4Name[client];
	
	PrintToChat(client, "[SM] rainbow name is %s", g_bUse4Name[client] ? "enabled" : "disabled");
	
	return Plugin_Handled;
}

public Action Command_Message(int client, int args)
{
	if(g_flagMessage != 0 && !(GetUserFlagBits(client) & g_flagMessage))
	{
		PrintToChat(client, "[SM] You do not have access to this command");
		return Plugin_Handled;
	}
	
	g_bUse4Message[client] = !g_bUse4Message[client];
	
	PrintToChat(client, "[SM] rainbow message is %s", g_bUse4Message[client] ? "enabled" : "disabled");

	return Plugin_Handled;
}

public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool &processcolors, bool &removecolors)
{
	Action result = Plugin_Continue;

	if((g_flagName == 0 || GetUserFlagBits(client) & g_flagName) && g_bUse4Name[client])
	{
		char newname[128];
		String_Rainbow(name, newname, 256);
		strcopy(name, 256, newname);
		result = Plugin_Changed;
	}
	
	if((g_flagMessage == 0 || GetUserFlagBits(client) & g_flagMessage) && g_bUse4Message[client])
	{
		char newmsg[256];
		String_Rainbow(message, newmsg, 256);
		strcopy(message, 256, newmsg);
		result = Plugin_Changed;
	}

	return result;
}

void String_Rainbow(const char[] input, char[] output, int maxLen)
{
	int bytes, buffs;
	int size = strlen(input)+1;
	char[] copy = new char [size];

	for(int x = 0; x < size; ++x)
	{
		if(input[x] == '\0')
			break;
		
		if(buffs == 2)
		{
			strcopy(copy, size, input);
			copy[x+1] = '\0';
			output[bytes] = RandomColor();
			bytes++;
			bytes += StrCat(output, maxLen, copy[x-buffs]);
			buffs = 0;
			continue;
		}

		if(!IsChar(input[x]))
		{
			buffs++;
			continue;
		}

		strcopy(copy, size, input);
		copy[x+1] = '\0';
		output[bytes] = RandomColor();
		bytes++;
		bytes += StrCat(output, maxLen, copy[x]);
	}

	output[++bytes] = '\0';
}

bool IsChar(char c)
{
	if(0 <= c <= 126)
		return true;
	
	return false;
}

int RandomColor()
{
	switch(GetRandomInt(1, 16))
	{
		case  1: return '\x01';
		case  2: return '\x02';
		case  3: return '\x03';
		case  4: return '\x03';
		case  5: return '\x04';
		case  6: return '\x05';
		case  7: return '\x06';
		case  8: return '\x07';
		case  9: return '\x08';
		case 10: return '\x09';
		case 11: return '\x10';
		case 12: return '\x0A';
		case 13: return '\x0B';
		case 14: return '\x0C';
		case 15: return '\x0E';
		case 16: return '\x0F';
		default: return '\x01';
	}

	return '\x01';
}