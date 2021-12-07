#include <sourcemod>

#define PLUGIN_VERSION "1.0"

#define YELLOW				0x01
#define NAMECOLOR			0x02
#define TEAMCOLOR			0x03
#define GREEN				0x04

new Handle:g_hJokeKV = INVALID_HANDLE;
new g_iJokeCount = 0;

new Handle:g_hQuestionTimer = INVALID_HANDLE;
new Handle:g_hAnswerTimer = INVALID_HANDLE;

new Handle:g_hCVQuestionTime = INVALID_HANDLE;
new Handle:g_hCVAnswerTime = INVALID_HANDLE;

new Float:g_fQuestionTime;
new Float:g_fAnswerTime;

public Plugin:myinfo = 
{
	name = "Tell A Joke",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Tells dead players random jokes.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	CreateConVar("sm_tellajoke_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCVQuestionTime = CreateConVar("sm_tellajoke_questioninterval", "30.0", "At which interval should we show a random joke?", FCVAR_PLUGIN);
	g_hCVAnswerTime = CreateConVar("sm_tellajoke_answerdelay", "5.0", "How long after the question should we show the answer?", FCVAR_PLUGIN);
	
	HookConVarChange(g_hCVQuestionTime, ConVarChange_QuestionTime);
	HookConVarChange(g_hCVAnswerTime, ConVarChange_AnswerTime);
	
	g_fQuestionTime = GetConVarFloat(g_hCVQuestionTime);
	g_fAnswerTime = GetConVarFloat(g_hCVAnswerTime);
	
	decl String:jokeFile[312];
	BuildPath(Path_SM, jokeFile, sizeof(jokeFile), "configs/tellajoke.txt");
	if(!FileExists(jokeFile))
		SetFailState("Can't find configs/tellajoke.txt config file.");
	
	g_hJokeKV = CreateKeyValues("Jokes");
	FileToKeyValues(g_hJokeKV, jokeFile);
 
	if (!KvGotoFirstSubKey(g_hJokeKV))
	{
		CloseHandle(g_hJokeKV);
		SetFailState("Error parsing the jokes.");
	}
	
	decl String:sSectionName[8];
	new iSectionNumber;
	do
	{
		KvGetSectionName(g_hJokeKV, sSectionName, sizeof(sSectionName));
		iSectionNumber = StringToInt(sSectionName);
		if (iSectionNumber != g_iJokeCount)
		{
			CloseHandle(g_hJokeKV);
			SetFailState("Error parsing the jokes. You're not allowed to skip numbers in the section name count. It's starting at 0.");
		}
		g_iJokeCount++;
	} while (KvGotoNextKey(g_hJokeKV))
	
	KvRewind(g_hJokeKV);
	g_hQuestionTimer = CreateTimer(g_fQuestionTime, Timer_TellAJoke, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapStart()
{
	if(g_hQuestionTimer == INVALID_HANDLE)
		g_hQuestionTimer = CreateTimer(g_fQuestionTime, Timer_TellAJoke, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_TellAJoke(Handle:timer, any:data)
{
	// Get a random joke
	decl String:sNumberBuffer[8];
	new iRandom = GetURandomIntRange(0, g_iJokeCount-1);
	Format(sNumberBuffer, sizeof(sNumberBuffer), "%d", iRandom);
	if (!KvJumpToKey(g_hJokeKV, sNumberBuffer))
	{
		return Plugin_Continue;
	}

	decl String:sQuestion[256];
	KvGetString(g_hJokeKV, "question", sQuestion, sizeof(sQuestion));
	
	KvRewind(g_hJokeKV);
	
	for(new i=1;i<MaxClients;i++)
	{
		if(IsClientInGame(i) && (!IsPlayerAlive(i) || IsClientObserver(i)))
		{
			PrintToChat(i, "%cJokes:%c %s", GREEN, TEAMCOLOR, sQuestion);
		}
	}
	
	g_hAnswerTimer = CreateTimer(g_fAnswerTime, Timer_TellTheAnswer, iRandom, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:Timer_TellTheAnswer(Handle:timer, any:data)
{
	decl String:sNumberBuffer[8];
	Format(sNumberBuffer, sizeof(sNumberBuffer), "%d", data);
	if (!KvJumpToKey(g_hJokeKV, sNumberBuffer))
	{
		return Plugin_Continue;
	}

	decl String:sAnswer[256];
	KvGetString(g_hJokeKV, "answer", sAnswer, sizeof(sAnswer));
	
	KvRewind(g_hJokeKV);
	
	for(new i=1;i<MaxClients;i++)
	{
		if(IsClientInGame(i) && (!IsPlayerAlive(i) || IsClientObserver(i)))
		{
			PrintToChat(i, "%cJokes:%c %s", GREEN, TEAMCOLOR, sAnswer);
		}
	}
	
	g_hAnswerTimer = INVALID_HANDLE;
	
	return Plugin_Handled;
}

public ConVarChange_QuestionTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_hQuestionTimer != INVALID_HANDLE)
	{
		CloseHandle(g_hQuestionTimer);
		g_hQuestionTimer = INVALID_HANDLE;
	}
	
	g_fQuestionTime = StringToFloat(newValue);
	
	g_hQuestionTimer = CreateTimer(g_fQuestionTime, Timer_TellAJoke, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public ConVarChange_AnswerTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_hAnswerTimer != INVALID_HANDLE)
		TriggerTimer(g_hAnswerTimer);
	
	g_fAnswerTime = StringToFloat(newValue);
}

stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}