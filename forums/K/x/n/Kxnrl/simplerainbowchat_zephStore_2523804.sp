#include <store>

#pragma newdecls required

char g_szNameTags[STORE_MAX_ITEMS][128];
char g_szNameColors[STORE_MAX_ITEMS][32];
char g_szMessageColors[STORE_MAX_ITEMS][32];

int g_iNameTags = 0;
int g_iNameColors = 0;
int g_iMessageColors = 0;

public void OnAllPluginsLoaded()
{
	if(!FindPluginByFile("chat-processor.smx"))
		SetFailState("Chat Processor isn't installed or failed to load. CP support will be disabled.");
	
	Store_RegisterHandler("nametag", "tag", CPSupport_OnMappStart, CPSupport_Reset, NameTags_Config, CPSupport_Equip, CPSupport_Remove, true);
	Store_RegisterHandler("namecolor", "color", CPSupport_OnMappStart, CPSupport_Reset, NameColors_Config, CPSupport_Equip, CPSupport_Remove, true);
	Store_RegisterHandler("msgcolor", "color", CPSupport_OnMappStart, CPSupport_Reset, MsgColors_Config, CPSupport_Equip, CPSupport_Remove, true);
}

public void CPSupport_OnMappStart()
{

}

public void CPSupport_Reset()
{
	g_iNameTags = 0;
	g_iNameColors = 0;
	g_iMessageColors = 0;
}

public int NameTags_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iNameTags);
	KvGetString(kv, "tag", g_szNameTags[g_iNameTags], 128);
	++g_iNameTags;

	return true;
}

public int NameColors_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iNameColors);
	KvGetString(kv, "color", g_szNameColors[g_iNameColors], 32);
	++g_iNameColors;

	return true;
}

public int MsgColors_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iMessageColors);
	KvGetString(kv, "color", g_szMessageColors[g_iMessageColors], 32);
	++g_iMessageColors;
	
	return true;
}

public int CPSupport_Equip(int client, int id)
{
	return -1;
}

public int CPSupport_Remove(int client, int id)
{

}

public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool &processcolors, bool &removecolors)
{
	int m_iEquippedNameTag = Store_GetEquippedItem(client, "nametag");
	int m_iEquippedNameColor = Store_GetEquippedItem(client, "namecolor");
	int m_iEquippedMsgColor = Store_GetEquippedItem(client, "msgcolor");

	if(m_iEquippedNameColor >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquippedNameColor);
		if(StrEqual(g_szNameColors[m_iData], "rainbow"))
		{
			char buffer[128];
			String_Rainbow(name, buffer, 128);
			strcopy(name, 128, buffer);
		}
		else Format(name, 128, "%s%s", g_szNameColors[m_iData], name);
	}

	if(m_iEquippedNameTag >= 0)
		Format(name, 128, "%s%s", g_szNameTags[Store_GetDataIndex(m_iEquippedNameTag)], name);

	if(m_iEquippedMsgColor >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquippedMsgColor);
		if(StrEqual(g_szMessageColors[m_iData], "rainbow"))
		{
			char buffer[256];
			String_Rainbow(message, buffer, 256);
			strcopy(message, 256, buffer);
		}
		else Format(message, 256, "%s%s", g_szMessageColors[m_iData], message);
	}

	return Plugin_Changed;
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

/*
add to store/items.txt

"Rainbow Name"
{
	"color"		"rainbow"
	"Plans"
	{
		"1天"
		{
			"price"		"360"
			"time"		"86400"
		}
		"1月"
		{
			"price"		"9999"
			"time"		"2678400"
		}
		"Permanent"
		{
			"price"		"50000"
		}
	}
	"type"		"namecolor"
}
"Rainbow Message"
{
	"color"		"rainbow"
	"Plans"
	{
		"1day"
		{
			"price"		"360"
			"time"		"86400"
		}
		"1month"
		{
			"price"		"9999"
			"time"		"2678400"
		}
		"Permanent"
		{
			"price"		"50000"
		}
	}
	"type"		"msgcolor"
}
*/