#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hoursplayed.net"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdktools>
#include <colorvariables>

static String:KVPath[PLATFORM_MAX_PATH];
static String:SKVPath[PLATFORM_MAX_PATH];

new Handle:SLBT = INVALID_HANDLE;
new Handle:SLBNT = INVALID_HANDLE;
new Handle:SLBNV = INVALID_HANDLE;
new Handle:r_timers;

new String:l_Words[1000][40][128];
new String:a_Words[1000][40][128];

new c_Array[32];
new d_Array[32];

new bool:a_Config = false;
new bool:b_Config = false;

new bool:a_Array[32] = false;
new bool:s_Array[32] = false;
new bool:w_Array[32] = false;
new bool:o_c;
new bool:RDE;																		//A boolean that hibernating until client is spawned.

public Plugin:myinfo = 
{
	name = "simple learning bot",
	author = PLUGIN_AUTHOR,
	description = "A bot that auto learning chat messege from text of players",
	version = PLUGIN_VERSION,
	url = "http://hoursplayed.net"
};

public void:OnPluginStart()
{
	CreateDirectory("addons/sourcemod/configs",3);
	
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "configs/learn.cfg");
	BuildPath(Path_SM, SKVPath, sizeof(SKVPath), "configs/learn_a.cfg");
	
	SLBT = CreateConVar("sm_slbt", "15.0", "The interval between each chat.", FCVAR_NONE, true, 15.0, true, 300.0);
	SLBNV = CreateConVar("sm_slbnv", "*SPEC* {CDCDCD}YUI <3{default}", "The name of simple learning bot.(visable)", FCVAR_NONE);
	SLBNT = CreateConVar("sm_slbnt", "YUI", "The name of simple learning bot.(trigger)", FCVAR_NONE);
	
	AutoExecConfig(true);
	
	LoadLearnedWords(true);
	LoadLearnedWords_a(true);
	
	RegConsoleCmd("sm_get", GetKeyValues);											//An early command that using for test method stability.
	RegConsoleCmd("sm_add", AddKeyValues);											//An early command that using for test method stability.
	RegConsoleCmd("sm_reloadslb", ReloadSLBConfig);									//An early command that using for test method stability.(Maybe this command is the most useful command among above command.)
	RegConsoleCmd("say", CmdSay);
	
	HookEvent("player_spawn", OnPlayerSpawn);										//Bot Start.
}

public void:OnMapStart()
{
	if(!FileExists(KVPath))															//Check existing configs. 
	{
		PrintToServer("[SM] Config addons/sourcemod/configs/learn.cfg failed to load: Unable to open config.");
		return Plugin_Handled;
	}
	if(!FileExists(SKVPath))
	{
		PrintToServer("[SM] Config addons/sourcemod/configs/learn_a.cfg failed to load: Unable to open config.");
		return Plugin_Handled;
	}
	
	RDE = false;																	//Boolean Array start.
	
	LoadLearnedWords(false);
	LoadLearnedWords_a(false);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!(o_c))
	{
		r_timers = CreateTimer(3.0, RandomAsking);
		o_c = true;
		c_Array[client] = -1;
	}
}

new o_nn_answer;

public Action:CmdSay(int client, int args)
{
	if(!RDE)																		//If bot has not been asking, below command will have been disabling.
	{
		return Plugin_Continue;
	}
	
	new String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	new String:fl_arg[2];															//Get first character.
	GetCmdArg(1, fl_arg, sizeof(fl_arg));
	
	if(StrEqual(fl_arg, "/") || StrEqual(fl_arg, "!"))								//Avoid plugin automatically mark down command to the config.
	{
		return Plugin_Continue;
	}
	
	new String:a_SLBNT[64];
	GetConVarString(SLBNT, a_SLBNT, sizeof(a_SLBNT));								//Get Bot Name.
	
	if(StrEqual(arg, a_SLBNT, false))												//Call Bot Name
	{
		KillTimer(r_timers);
		r_timers = CreateTimer(15.0, RandomAsking);
		
		new a_SLBT = GetConVarFloat(SLBT);											//Get "Interval between each chat time" Console Variable
		w_Array[client] = true;														//Bot name boolean array.
		s_Array[client] = false;													//Random Asking boolean array.
		c_Array[client] = -1;														//Random Asking question ID integer array.
		return Plugin_Continue;
	}
	
	if(w_Array[client])																//If called Bot Name already, record the next message when the player send out the text.
	{
		new n_answer, n_loop = 1, RandomInt;
		n_answer = CmdSayAddKeyValuesQuestion(KVPath, client, arg);
		
		while(1 == 1)																//Get Max answer.
		{
			new String:answer[128];
			answer = l_Words[n_answer][n_loop];
			if(StrEqual(answer, NULL_STRING))
			{
				n_loop--;
				break;
			}
			n_loop++;
		}
		if(n_loop != 0)
		{
			RandomInt = GetRandomInt(1, n_loop);
			DataPack pack = new DataPack();
			pack.WriteCell(client);
			pack.WriteCell(n_answer);
			pack.WriteCell(RandomInt);
			CreateTimer(1.0, CmdSayDelay, pack);
		
			d_Array[client] = o_nn_answer;
			a_Array[client] = true;
		}
		
		w_Array[client] = false;
		s_Array[client] = false;
		c_Array[client] = -1;
		return Plugin_Continue;
	}
	
	if(a_Array[client])
	{
		CmdSayAddKeyValuesAnswer(SKVPath, client, d_Array[client], arg);
		a_Array[client] = false;
		d_Array[client] = -1;
	}
	
	if(s_Array[client])																//Record the player answer.
	{
		new nn_answer, n_loop = 1, RandomInt;
		CmdSayAddKeyValuesAnswer(KVPath, client, c_Array[client], arg);
		
		nn_answer = CmdSayAddKeyValuesQuestion_a(SKVPath, client, arg);				//SVPath Question
		o_nn_answer = nn_answer;
		
		while(1 == 1)																//Get Max answer.
		{
			new String:answer[128];
			answer = a_Words[nn_answer][n_loop];
			if(StrEqual(answer, NULL_STRING))
			{
				n_loop--;
				break;
			}
			n_loop++;
		}
		if(n_loop != 0)
		{
			RandomInt = GetRandomInt(1, n_loop);
			DataPack pack = new DataPack();
			pack.WriteCell(client);
			pack.WriteCell(nn_answer);
			pack.WriteCell(RandomInt);
			CreateTimer(1.0, CmdSayDelay_a, pack);
		}
		
		s_Array[client] = false;
		c_Array[client] = -1;
	}else
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:CmdSayDelay(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new String:a_SLBNV[64];
	GetConVarString(SLBNV, a_SLBNV, sizeof(a_SLBNV));								//Get Bot Name.
	
	new client, n_answer, RandomInt;
	client = ReadPackCell(pack);
	n_answer = ReadPackCell(pack);
	RandomInt = ReadPackCell(pack);
	
	CPrintToChatAll("%s :  %N, %s", a_SLBNV, client, l_Words[n_answer][RandomInt]);
	
	CloseHandle(pack);
}

public Action:CmdSayDelay_a(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new String:a_SLBNV[64];
	GetConVarString(SLBNV, a_SLBNV, sizeof(a_SLBNV));								//Get Bot Name.
	
	new client, nn_answer, RandomInt;
	client = ReadPackCell(pack);
	nn_answer = ReadPackCell(pack);
	RandomInt = ReadPackCell(pack);
	
	CPrintToChatAll("%s :  %N, %s", a_SLBNV, client, a_Words[nn_answer][RandomInt]);
	
	CloseHandle(pack);
}

new o_i;

public void:LoadLearnedWords(bool enable)
{
	new Handle:DB = CreateKeyValues("Words");
	FileToKeyValues(DB, KVPath);
	if(KvGotoFirstSubKey(DB))
	{
		new String:question[128], String:answer[128], String:m_answer[32], String:f_answer[128];
		KvGetString(DB, "question", question, sizeof(question));
		KvGetString(DB, "answer", answer, sizeof(answer));
		l_Words[0][0] = question;
		l_Words[0][1] = answer;
		new g = 2;
		while(g < 40)
		{
			Format(m_answer, sizeof(m_answer), "answer%i", g);
			KvGetString(DB, m_answer, f_answer, sizeof(f_answer));					//f_answer = answer key
			l_Words[0][g] = f_answer;
			g++;
		}
		
		new i = 1;
		
		while(1 == 1)
		{
			if(KvGotoNextKey(DB))
			{
				KvGetString(DB, "question", question, sizeof(question));
				KvGetString(DB, "answer", answer, sizeof(answer));
				l_Words[i][0] = question;
				l_Words[i][1] = answer;
				new n = 2;
				while(n < 40)
				{
					Format(m_answer, sizeof(m_answer), "answer%i", n);
					KvGetString(DB, m_answer, f_answer, sizeof(f_answer));			//f_answer = answer key
					l_Words[i][n] = f_answer;
					n++;
				}
			}else
			{
				break;
			}
			o_i = i;
			i++;
		}
		KvRewind(DB);
		b_Config = true;
		a_Config = true;
	}else
	{
		PrintToChatAll("[SM] Config addons/sourcemod/configs/learn.cfg failed to load: Unable to open file.");
		PrintToServer("[SM] Config addons/sourcemod/configs/learn.cfg failed to load: Unable to open file.");
		b_Config = false;
		a_Config = false;
	}
}

new a_i;

public void:LoadLearnedWords_a(bool enable)
{
	new Handle:DB = CreateKeyValues("Words");
	FileToKeyValues(DB, SKVPath);
	if(KvGotoFirstSubKey(DB))
	{
		new String:question[128], String:answer[128], String:m_answer[32], String:f_answer[128];
		KvGetString(DB, "question", question, sizeof(question));
		KvGetString(DB, "answer", answer, sizeof(answer));
		a_Words[0][0] = question;
		a_Words[0][1] = answer;
		new g = 2;
		while(g < 40)
		{
			Format(m_answer, sizeof(m_answer), "answer%i", g);
			KvGetString(DB, m_answer, f_answer, sizeof(f_answer));					//f_answer = answer key
			a_Words[0][g] = f_answer;
			g++;
		}
		
		new i = 1;
		
		while(1 == 1)
		{
			if(KvGotoNextKey(DB))
			{
				KvGetString(DB, "question", question, sizeof(question));
				KvGetString(DB, "answer", answer, sizeof(answer));
				a_Words[i][0] = question;
				a_Words[i][1] = answer;
				new n = 2;
				while(n < 40)
				{
					Format(m_answer, sizeof(m_answer), "answer%i", n);
					KvGetString(DB, m_answer, f_answer, sizeof(f_answer));			//f_answer = answer key
					a_Words[i][n] = f_answer;
					n++;
				}
			}else
			{
				break;
			}
			a_i = i;
			i++;
		}
		KvRewind(DB);
		a_Config = true;
		b_Config = true;
	}else
	{
		PrintToChatAll("[SM] Config addons/sourcemod/configs/learn_a.cfg failed to load: Unable to find the first KeyValues.");
		PrintToServer("[SM] Config addons/sourcemod/configs/learn_a.cfg failed to load: Unable to find the first KeyValues.");
		a_Config = false;
		b_Config = false;
	}
}

public Action:GetKeyValues(int client, int args)
{
	new String:arg1[32], Iarg1;														// arg1
	new String:arg2[32], Iarg2;														// arg2
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	Iarg1 = StringToInt(arg1);
	Iarg2 = StringToInt(arg2);
	
	if((args > 2) || (args < 2))
	{
		ReplyToCommand(client, "[SM] Usage: sm_get <keyvalue> <number of question|answer>");
		return Plugin_Continue;
	}
	
	CPrintToChatAll("%s", l_Words[Iarg1][Iarg2]);
	
	return Plugin_Continue;
}

public Action:AddKeyValues(int client, int args)
{
	new String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if((args > 2) || (args < 2))
	{
		ReplyToCommand(client, "[SM] Usage: sm_add <question> <answer>");
		return Plugin_Continue;
	}
	
	new Handle:DB = CreateKeyValues("Words");
	FileToKeyValues(DB, KVPath);
	if(KvGotoFirstSubKey(DB))
	{
		new i = 1, p = 0;
		new String:s_array[128];
		while(1 == 1)																// An integer that counts all history of learned messege.
		{
			if(!KvGotoNextKey(DB))
			{
				KvRewind(DB);
				break;
			}
			i++;
		}
		while(1 == 1)																// Prevent same question but generate 2 KeyValues.
		{
			s_array = l_Words[p][0];
			if(StrEqual(arg1, s_array, false))
			{
				break;
			}else if(p == i)
			{
				break;
			}
			p++;
		}
		
		new String:Sp[32], String:answer[128], String:m_answer[32], String:f_answer[128];
		new loop = 2;
		IntToString(p, Sp, sizeof(Sp));
		KvJumpToKey(DB, Sp, true);
		KvSetString(DB, "question", arg1);
		KvGetString(DB, "answer", answer, sizeof(answer));
		if(StrEqual(answer, NULL_STRING))											// If config answer doesn't exist, prevent two same answers in one question.
		{
			KvSetString(DB, "answer", arg2);
		}else
		{
			while(1 == 1)
			{
				Format(m_answer, sizeof(m_answer), "answer%i", loop);
				if(StrEqual(m_answer, "answer40"))
				{
					new String:buffer[128];
					KvGetString(DB, "question", buffer, sizeof(buffer));			//Prevent more than 40 answer record because of array size restriction, it wouldn't add anymore answer.
					break;
				}
				KvGetString(DB, m_answer, f_answer, sizeof(f_answer));				//f_answer = answer key
				
				if(StrEqual(f_answer, NULL_STRING))
				{
					KvSetString(DB, m_answer, arg2);
					break;
				}
				if(StrEqual(f_answer, arg2, false) || StrEqual(answer, arg2, false))
				{
					break;
				}
				loop++;
			}
		}
		
		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		b_Config = true;
		a_Config = true;
		LoadLearnedWords(false);
		LoadLearnedWords_a(false);
	}else
	{
		ReplyToCommand(client, "[SM] Config addons/sourcemod/configs/learn.cfg failed to load: Unable to find the first KeyValues.");
		PrintToServer("[SM] Config addons/sourcemod/configs/learn.cfg failed to load: Unable to find the first KeyValues.");
		b_Config = false;
		a_Config = false;
	}
	return Plugin_Continue;
}

public void:CmdSayAddKeyValuesAnswer(char[] Path, int client, int arg1, char[] arg2)
{	
	new Handle:DB = CreateKeyValues("Words");
	FileToKeyValues(DB, Path);
	new String:s_arg1[128];
	IntToString(arg1, s_arg1, sizeof(s_arg1));
	KvJumpToKey(DB, s_arg1);
	KvGetString(DB, "question", s_arg1, sizeof(s_arg1));
		
	new String:answer[128], String:m_answer[32], String:f_answer[128];
	new loop = 2;
	KvSetString(DB, "question", s_arg1);
	KvGetString(DB, "answer", answer, sizeof(answer));
	if(StrEqual(answer, NULL_STRING))												// If config answer doesn't exist, prevent two same answers in one question.
	{
		KvSetString(DB, "answer", arg2);
	}else
	{
		while(1 == 1)
		{
			Format(m_answer, sizeof(m_answer), "answer%i", loop);
			if(StrEqual(m_answer, "answer40"))
			{
				new String:buffer[128];
				KvGetString(DB, "question", buffer, sizeof(buffer));				//Prevent more than 40 answer record because of array size restriction, it wouldn't add anymore answer.
				break;
			}
			KvGetString(DB, m_answer, f_answer, sizeof(f_answer));					//f_answer = answer key
			
			if(StrEqual(f_answer, NULL_STRING))
			{
				KvSetString(DB, m_answer, arg2);
				break;
			}
			if(StrEqual(f_answer, arg2) || StrEqual(answer, arg2))
			{
				break;
			}
			loop++;
		}
	}
	
	KvRewind(DB);
	KeyValuesToFile(DB, Path);
	b_Config = true;
	LoadLearnedWords(false);
	a_Config = true;
	LoadLearnedWords_a(false);
}

public int:CmdSayAddKeyValuesQuestion(char[] Path, int client, char[] arg1)
{
	new Handle:DB = CreateKeyValues("Words");
	FileToKeyValues(DB, Path);
	KvGotoFirstSubKey(DB);
	new i = 1, p = 0;
	new String:s_array[128];
	while(1 == 1)																	// An integer that counts all history of learned messege.
	{
		if(!KvGotoNextKey(DB))
		{
			KvRewind(DB);
			break;
		}
		i++;
	}
	while(1 == 1)																	// Prevent same question but generate 2 KeyValues.
	{
		s_array = l_Words[p][0];
		if(StrEqual(arg1, s_array, false))
		{
			break;
		}else if(p == i)															// This is why I need an "i" variable. :P
		{
			break;
		}
		p++;
	}
	
	new String:Sp[32];
	IntToString(p, Sp, sizeof(Sp));
	KvJumpToKey(DB, Sp, true);
	KvSetString(DB, "question", arg1);
	
	KvRewind(DB);
	KeyValuesToFile(DB, Path);
	b_Config = true;
	LoadLearnedWords(false);
	a_Config = true;
	LoadLearnedWords_a(false);
	return p;
}

public int:CmdSayAddKeyValuesQuestion_a(char[] Path, int client, char[] arg1)
{
	new Handle:DB = CreateKeyValues("Words");
	FileToKeyValues(DB, Path);
	KvGotoFirstSubKey(DB);
	new i = 1, p = 0;
	new String:s_array[128];
	while(1 == 1)																	// An integer that counts all history of learned messege.
	{
		if(!KvGotoNextKey(DB))
		{
			KvRewind(DB);
			break;
		}
		i++;
	}
	
	while(1 == 1)																	// Prevent same question but generate 2 KeyValues.
	{
		s_array = a_Words[p][0];
		if(StrEqual(arg1, s_array, false))
		{
			break;
		}else if(p == i)															// This is why I need an "i" variable. :P
		{
			break;
		}
		p++;
	}
	
	new String:Sp[32];
	IntToString(p, Sp, sizeof(Sp));
	KvJumpToKey(DB, Sp, true);
	KvSetString(DB, "question", arg1);
	
	KvRewind(DB);
	KeyValuesToFile(DB, Path);
	b_Config = true;
	LoadLearnedWords(false);
	a_Config = true;
	LoadLearnedWords_a(false);
	return p;
}

public Action:ReloadSLBConfig(int client, int args)
{
	LoadLearnedWords(true);
	LoadLearnedWords_a(true);
	if(b_Config)
	{
		ReplyToCommand(client, "[SM] Reloaded Config addons/sourcemod/configs/learn.cfg successfully.");
	}
	if(a_Config)
	{
		ReplyToCommand(client, "[SM] Reloaded Config addons/sourcemod/configs/learn_a.cfg successfully.");
	}
	return Plugin_Handled;
}

new l_client;

public Action:RandomAsking(Handle timer)
{
	RDE = true;
	new RandomInt = GetRandomInt(2, 3);
	new client = GetRandomPlayer(RandomInt);
	if(client == -1)
	{
		client = GetRandomPlayer(2);
		if(client == -1)
		{
			client = GetRandomPlayer(3);
			if(client == -1)
			{
				client = GetRandomPlayer(1);
				if(client == -1)
				{
					o_c = false;
					return Plugin_Handled;											//Prevent Get client integer error when server is hibernating.
				}
			}
		}
	}
	
	new a_SLBT = GetConVarFloat(SLBT);												//Get "Interval between each chat time" Console Variable
	if(s_Array[client])
	{
		r_timers = CreateTimer(a_SLBT, RandomAsking);								//Looping the timer.
		return Plugin_Handled;
	}
	
	new RandomChatNum;
	RandomChatNum = GetRandomInt(0, o_i);											//Choose a random integer(question) to ask client.
	
	new String:a_SLBNV[64];
	GetConVarString(SLBNV, a_SLBNV, sizeof(a_SLBNV));								//Get Bot Name.
	c_Array[l_client] = -1;
	s_Array[l_client] = false;
	CPrintToChatAll("%s :  %N, %s", a_SLBNV, client, l_Words[RandomChatNum][0]);	//Format : PlayerName, How's going?
	c_Array[client] = RandomChatNum;												//Mark question id.
	s_Array[client] = true;															//Prevent ask the same client when the client has not answered the previous question.
	o_c = true;																		//Mark for avoid plugin spam chat.
	r_timers = CreateTimer(a_SLBT, RandomAsking);									//Looping the timer.
	l_client = client;
	return Plugin_Handled;
}

stock GetRandomPlayer(team) {
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && (GetClientTeam(i) == team))
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}