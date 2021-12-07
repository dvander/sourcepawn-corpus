#include <sourcemod>
#include <colorvariables>

#pragma tabsize 0

static String:KVPath[PLATFORM_MAX_PATH];
static String:SKVPath[PLATFORM_MAX_PATH];
new String:Words[100][30][256];
new Array[100][32];
new Handle:ChatPrefix = INVALID_HANDLE;
new Handle:ChatSuffix = INVALID_HANDLE;
new String:Chats[100][1][256];
new Handle:ChatTimeDelay = INVALID_HANDLE;
new Handle:ChatEnable = INVALID_HANDLE;

stock GetRandomPlayer(team) {
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && (GetClientTeam(i) == team))
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

#define PLUGIN_VERSION	"1.0.1"

public Plugin:myinfo = 
{
	name = "Simple Chatter Bot",
	author = "Hoursplayed.net",
	description = "A bot that automatically answer the text from player and automatically type some words.",
	version	= PLUGIN_VERSION,
	url = "http://hoursplayed.net"
}

public OnPluginStart() 
{
	CreateConVar("sm_simplechatterbot_version", PLUGIN_VERSION, "Simple Chatter Bot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateDirectory("addons/sourcemod/configs",3);
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "configs/speech.cfg");
	BuildPath(Path_SM, SKVPath, sizeof(SKVPath), "configs/autochat.cfg");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_reloadscb", Command_ReloadConfig);
	LoadWord();
	LoadAutoChatWords();
	ChatPrefix = CreateConVar("sm_prefix", "", "Chat Prefix.");
	ChatSuffix = CreateConVar("sm_suffix", "", "Chat Suffix.");
	ChatTimeDelay = CreateConVar("sm_chattime", "15.0", "Set the such chat delay time. 1 = Enable");
	ChatEnable = CreateConVar("sm_chat_enable", "1", "Enable/Disable the plugin. 1 = Enable");
	AutoExecConfig(true, "AutomaticallyAnswerBot");
	CreateTimer(0.1, AutoChat);
}

public Action:Command_ReloadConfig(client, args)
{
	LoadWord();
	LoadAutoChatWords();
	AutoExecConfig(true, "AutomaticallyAnswerBot");
	ReplyToCommand(client, "[SM] Configs are already reloaded.");
}

public Action:Command_Say(client, args)
{
	new String:arg1[32], String:Sclient[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	IntToString(client, Sclient, sizeof(Sclient));
	new i = 0;
	while(i < 100)
	{
		if(!StrEqual(Words[i][0], "") && !StrEqual(arg1, ""))
		{
			new SWord, Float:typetime, Iblock;
			SWord = StringToInt(Words[i][2]);
			typetime = StringToFloat(Words[i][3]);
			Iblock = StringToInt(Words[i][18]);
			
			if((StrEqual(arg1, Words[i][0], false) || StrEqual(arg1, Words[i][12], false) || StrEqual(arg1, Words[i][13], false) || StrEqual(arg1, Words[i][14], false)) && StrEqual(Words[i][2], NULL_STRING))
			{
				DataPack pack = new DataPack();
				CreateTimer(typetime, DelayChat, pack);
				pack.WriteCell(i);
				pack.WriteString(Sclient);
				Array[i][client] = true;
				if(Iblock == 1)
				{
					return Plugin_Handled;
				}
			}else if ((StrEqual(arg1, Words[i][0], false) || StrEqual(arg1, Words[i][12], false) || StrEqual(arg1, Words[i][13], false) || StrEqual(arg1, Words[i][14], false)) && !StrEqual(Words[i][2], NULL_STRING))
			{
				if(Array[SWord][client] == true)
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					Array[SWord][client] = false;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
			}
		}
	i++
	}
	i = 0;
	while(i < 100)
	{
		if((!StrEqual(Words[i][4], "") && !StrEqual(Words[i][15], "") && !StrEqual(Words[i][16], "") && !StrEqual(Words[i][17], "")) && !StrEqual(arg1, ""))
		{
			new SWord, Float:typetime, Iblock;
			SWord = StringToInt(Words[i][2]);
			typetime = StringToFloat(Words[i][3]);
			Iblock = StringToInt(Words[i][18]);
			
			if(((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1) || (StrContains(arg1, Words[i][17], false) != -1)) && StrEqual(Words[i][2], NULL_STRING))
			{
				DataPack pack = new DataPack();
				CreateTimer(typetime, DelayChat, pack);
				pack.WriteCell(i);
				pack.WriteString(Sclient);
				Array[i][client] = true;
				if(Iblock == 1)
				{
					return Plugin_Handled;
				}
			}else if (((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1) || (StrContains(arg1, Words[i][17], false) != -1)) && !StrEqual(Words[i][2], NULL_STRING))
			{
				if(Array[SWord][client] == true)
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					Array[SWord][client] = false;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
			}
		}else if((!StrEqual(Words[i][4], "") && !StrEqual(Words[i][15], "") && !StrEqual(Words[i][16], "")) && !StrEqual(arg1, ""))
		{
			new SWord, Float:typetime, Iblock;
			SWord = StringToInt(Words[i][2]);
			typetime = StringToFloat(Words[i][3]);
			Iblock = StringToInt(Words[i][18]);
			
			if(((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1)) && StrEqual(Words[i][2], NULL_STRING))
			{
				DataPack pack = new DataPack();
				CreateTimer(typetime, DelayChat, pack);
				pack.WriteCell(i);
				pack.WriteString(Sclient);
				Array[i][client] = true;
				if(Iblock == 1)
				{
					return Plugin_Handled;
				}
			}else if (((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1)) && !StrEqual(Words[i][2], NULL_STRING))
			{
				if(Array[SWord][client] == true)
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					Array[SWord][client] = false;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
			}
		}else if((!StrEqual(Words[i][4], "") && !StrEqual(Words[i][15], "")) && !StrEqual(arg1, ""))
		{
			new SWord, Float:typetime, Iblock;
			SWord = StringToInt(Words[i][2]);
			typetime = StringToFloat(Words[i][3]);
			Iblock = StringToInt(Words[i][18]);
			
			if(((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1)) && StrEqual(Words[i][2], NULL_STRING))
			{
				DataPack pack = new DataPack();
				CreateTimer(typetime, DelayChat, pack);
				pack.WriteCell(i);
				pack.WriteString(Sclient);
				Array[i][client] = true;
				if(Iblock == 1)
				{
					return Plugin_Handled;
				}
			}else if (((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1)) && !StrEqual(Words[i][2], NULL_STRING))
			{
				if(Array[SWord][client] == true)
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					Array[SWord][client] = false;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
			}
		}else if((!StrEqual(Words[i][4], "")) && !StrEqual(arg1, ""))
		{
			new SWord, Float:typetime, Iblock;
			SWord = StringToInt(Words[i][2]);
			typetime = StringToFloat(Words[i][3]);
			Iblock = StringToInt(Words[i][18]);
			
			if((StrContains(arg1, Words[i][4], false) != -1) && StrEqual(Words[i][2], NULL_STRING))
			{
				DataPack pack = new DataPack();
				CreateTimer(typetime, DelayChat, pack);
				pack.WriteCell(i);
				pack.WriteString(Sclient);
				Array[i][client] = true;
				if(Iblock == 1)
				{
					return Plugin_Handled;
				}
			}else if ((StrContains(arg1, Words[i][4], false) != -1) && !StrEqual(Words[i][2], NULL_STRING))
			{
				if(Array[SWord][client] == true)
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					Array[SWord][client] = false;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
			}
		}
	i++
	}
	return Plugin_Continue;
}

public LoadWord()
{
	new Handle:DB = CreateKeyValues("Speech");
	new String:equal[32], String:answer[128], String:condition[32], Float:typetime, String:Stypetime[32], String:contains[32], String:action[256], i = 1;
	new String:temp_name[32], String:name[32]; //temp_name equal to previous section name, name equal to current section name
	new String:Aanswer[128], String:Banswer[128], String:Canswer[128], String:Danswer[128], String:Eanswer[128], count, String:Scount[32];	// 5 Random answer
	new String:Aequal[32], String:Bequal[32], String:Cequal[32];
	new String:Acontains[32], String:Bcontains[32], String:Ccontains[32];
	new String:block[32], String:flags[64], cooldown, String:Scooldown[32], String:cooldownwarn[32];
	
	FileToKeyValues(DB, KVPath);
	KvGotoFirstSubKey(DB); // Start
	
	KvGetString(DB, "equal", equal, 32);
	KvGetString(DB, "answer", answer, 128);
	KvGetString(DB, "condition", condition, 32);
	typetime = KvGetFloat(DB, "typetime", 0.5);
	FloatToString(typetime, Stypetime, sizeof(Stypetime));
	KvGetString(DB, "contains", contains, 32);
	KvGetString(DB, "action", action, 256);
	KvGetString(DB, "answer2", Aanswer, 128);
	KvGetString(DB, "answer3", Banswer, 128);
	KvGetString(DB, "answer4", Canswer, 128);
	KvGetString(DB, "answer5", Danswer, 128);
	KvGetString(DB, "answer6", Eanswer, 128);
	KvGetString(DB, "equal2", Aequal, 32);
	KvGetString(DB, "equal3", Bequal, 32);
	KvGetString(DB, "equal4", Cequal, 32);
	KvGetString(DB, "contains2", Acontains, 32);
	KvGetString(DB, "contains3", Bcontains, 32);
	KvGetString(DB, "contains4", Ccontains, 32);
	KvGetString(DB, "block", block, 32);
	KvGetString(DB, "flags", flags, 32);
	KvGetString(DB, "cooldownwarn", cooldownwarn, 32);
	count = KvGetNum(DB, "count", 1)
	IntToString(count, Scount, sizeof(Scount));
	cooldown = KvGetFloat(DB, "cooldown", 3.0);
	FloatToString(cooldown, Scooldown, sizeof(Scooldown));
	Words[0][0] = equal;
	Words[0][1] = answer;
	Words[0][2] = condition;
	Words[0][3] = Stypetime;
	Words[0][4] = contains;
	Words[0][5] = action;
	Words[0][6] = Scount;
	Words[0][7] = Aanswer;
	Words[0][8] = Banswer;
	Words[0][9] = Canswer;
	Words[0][10] = Danswer;
	Words[0][11] = Eanswer;
	Words[0][12] = Aequal;
	Words[0][13] = Bequal;
	Words[0][14] = Cequal;
	Words[0][15] = Acontains;
	Words[0][16] = Bcontains;
	Words[0][17] = Ccontains;
	Words[0][18] = block;
	Words[0][19] = flags;
	Words[0][20] = Scooldown;
	Words[0][21] = "1";
	Words[0][22] = cooldownwarn;
	KvGetSectionName(DB, temp_name, sizeof(temp_name));
	
	while(i < 100)
	{
		KvGotoNextKey(DB);
		KvGetSectionName(DB, name, sizeof(name));
		if(StrEqual(temp_name, name))	//Prevent looping same section.
			break;
		
		KvGetString(DB, "equal", equal, 32);
		KvGetString(DB, "answer", answer, 128);
		KvGetString(DB, "condition", condition, 32);
		typetime = KvGetFloat(DB, "typetime", 0.5);
		FloatToString(typetime, Stypetime, sizeof(Stypetime));
		KvGetString(DB, "contains", contains, 32);
		KvGetString(DB, "action", action, 256);
		KvGetString(DB, "answer2", Aanswer, 128);
		KvGetString(DB, "answer3", Banswer, 128);
		KvGetString(DB, "answer4", Canswer, 128);
		KvGetString(DB, "answer5", Danswer, 128);
		KvGetString(DB, "answer6", Eanswer, 128);
		KvGetString(DB, "equal2", Aequal, 32);
		KvGetString(DB, "equal3", Bequal, 32);
		KvGetString(DB, "equal4", Cequal, 32);
		KvGetString(DB, "contains2", Acontains, 32);
		KvGetString(DB, "contains3", Bcontains, 32);
		KvGetString(DB, "contains4", Ccontains, 32);
		KvGetString(DB, "block", block, 32);
		KvGetString(DB, "flags", flags, 32);
		KvGetString(DB, "cooldownwarn", cooldownwarn, 32);
		count = KvGetNum(DB, "count", 1)
		IntToString(count, Scount, sizeof(Scount));
		cooldown = KvGetFloat(DB, "cooldown", 3.0);
		FloatToString(cooldown, Scooldown, sizeof(Scooldown));
		Words[i][0] = equal;
		Words[i][1] = answer;
		Words[i][2] = condition;
		Words[i][3] = Stypetime;
		Words[i][4] = contains;
		Words[i][5] = action;
		Words[i][6] = Scount;
		Words[i][7] = Aanswer;
		Words[i][8] = Banswer;
		Words[i][9] = Canswer;
		Words[i][10] = Danswer;
		Words[i][11] = Eanswer;
		Words[i][12] = Aequal;
		Words[i][13] = Bequal;
		Words[i][14] = Cequal;
		Words[i][15] = Acontains;
		Words[i][16] = Bcontains;
		Words[i][17] = Ccontains;
		Words[i][18] = block;
		Words[i][19] = flags;
		Words[i][20] = Scooldown;
		Words[i][21] = "1";
		Words[i][22] = cooldownwarn;
		KvGetSectionName(DB, temp_name, sizeof(temp_name));
		i++;
	}
	CloseHandle(DB);
}

public Action:DelayChat(Handle:timer, Handle:pack)
{
	new IChatEnable, i;
	IChatEnable = GetConVarInt(ChatEnable);
	ResetPack(pack);
	i = ReadPackCell(pack);
	if((IChatEnable == 1) && StrEqual(Words[i][21], "1"))
	{
		new String:Sclient[32], client, String:name[32], String:SID[128], userid, String:Suserid[32], String:m_gzWord[256], RandomInt, count;
		
		ReadPackString(pack, Sclient, sizeof(Sclient));
		client = StringToInt(Sclient);
		GetClientName(client, name, sizeof(name));
		userid = GetClientUserId(client);
		IntToString(userid, Suserid, sizeof(Suserid));
		//GetClientAuthString(client, SID, sizeof(SID));
		GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));
		
		m_gzWord = Words[i][1];
		count = StringToInt(Words[i][6]);
		if(count > 1)
		{
			RandomInt = GetRandomInt(1, count);
			switch(RandomInt)
			{
				case 1 :
					m_gzWord = Words[i][1];
				case 2 :
					m_gzWord = Words[i][7];
				case 3 :
					m_gzWord = Words[i][8];
				case 4 :
					m_gzWord = Words[i][9];
				case 5 :
					m_gzWord = Words[i][10];
				case 6 :
					m_gzWord = Words[i][11];
			}
		}
		new String:SChatPrefix[128], String:SChatSuffix[128];
		GetConVarString(ChatPrefix, SChatPrefix, sizeof(SChatPrefix));
		GetConVarString(ChatSuffix, SChatSuffix, sizeof(SChatSuffix));
		
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{name}", name);
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{steamid}", SID);
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{userid}", Suserid);
		int flags = ReadFlagString(Words[i][19]);
		if(GetUserFlagBits(client) & flags == flags)
		{
			if(!StrEqual(m_gzWord, ""))
			{
				CPrintToChatAll("%s%s%s", SChatPrefix, m_gzWord, SChatSuffix);
			}
		}
		m_gzWord = Words[i][5];
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{name}", name);
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{steamid}", SID);
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{userid}", Suserid);
		
		if(GetUserFlagBits(client) & flags == flags)
		{
			ServerCommand("%s", m_gzWord);
		}
		Words[i][21] = "0";
		new cooldown = StringToFloat(Words[i][20]);
		DataPack Spack = new DataPack();
		Spack.WriteCell(i);
		CreateTimer(cooldown, CooldownTime, Spack);
		CloseHandle(pack);
	}else if((IChatEnable == 1) && StrEqual(Words[i][21], "0"))
	{
		new String:Sclient[32], client, String:name[32], String:SID[128], userid, String:Suserid[32], String:m_gzWord[256];
		
		ReadPackString(pack, Sclient, sizeof(Sclient));
		client = StringToInt(Sclient);
		GetClientName(client, name, sizeof(name));
		userid = GetClientUserId(client);
		IntToString(userid, Suserid, sizeof(Suserid));
		//GetClientAuthString(client, SID, sizeof(SID));
		GetClientAuthId(client, AuthId_Steam2, SID, sizeof(SID));
		
		m_gzWord = Words[i][22];
		
		new String:SChatPrefix[128], String:SChatSuffix[128];
		GetConVarString(ChatPrefix, SChatPrefix, sizeof(SChatPrefix));
		GetConVarString(ChatSuffix, SChatSuffix, sizeof(SChatSuffix));
		
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{name}", name);
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{steamid}", SID);
		ReplaceString(m_gzWord, sizeof(m_gzWord), "{userid}", Suserid);
		
		if(!StrEqual(m_gzWord, ""))
		{
			CPrintToChatAll("%s%s%s", SChatPrefix, m_gzWord, SChatSuffix);
		}
		
		CloseHandle(pack);
	}
}

public Action:CooldownTime(Handle:timer, Handle:Spack)
{
	new i;
	ResetPack(Spack);
	i = ReadPackCell(Spack);
	Words[i][21] = "1";
	CloseHandle(Spack);
}

new ChatMaxCount;

public LoadAutoChatWords()
{
	new Handle:DB = CreateKeyValues("Chat");
	new String:ChatMessege[128];
	
	FileToKeyValues(DB, SKVPath);
	KvJumpToKey(DB, "AutoChat", true);	//Start
	
	new i = 0, String:IntI[128];
	while(i < 100)
	{
		IntToString(i, IntI, sizeof(IntI));
		KvGetString(DB, IntI, ChatMessege, 128);
		ChatMaxCount = i - 1;
		if(StrEqual(ChatMessege, NULL_STRING))
			break;
		Chats[i][0] = ChatMessege;
		i++
	}
	CloseHandle(DB);
}

public Action:AutoChat(Handle:timer)
{
	new RandomInt = GetRandomInt(2, 3);
	new client = GetRandomPlayer(RandomInt);
	if(client == -1)
	{
		client = GetRandomPlayer(2);
	}
	if(client == -1)
	{
		client = GetRandomPlayer(3);
	}
	new String:name[32];
	if(client != -1)
	{
		GetClientName(client, name, sizeof(name));
	}else
	{
		name = "Server is Empty now!";
	}
	
	new RandomChatNum;
	RandomChatNum = GetRandomInt(0, ChatMaxCount);
	new String:FinalChat[256];
	FinalChat = Chats[RandomChatNum][0];
	ReplaceString(FinalChat, sizeof(FinalChat), "{name}", name);
	
	new String:SChatPrefix[128], String:SChatSuffix[128];
	GetConVarString(ChatPrefix, SChatPrefix, sizeof(SChatPrefix));
	GetConVarString(ChatSuffix, SChatSuffix, sizeof(SChatSuffix));
	
	CPrintToChatAll("%s%s%s", SChatPrefix, FinalChat, SChatSuffix);
	
	new IsEnable = GetConVarFloat(ChatTimeDelay);
	CreateTimer(IsEnable, AutoChat);
}