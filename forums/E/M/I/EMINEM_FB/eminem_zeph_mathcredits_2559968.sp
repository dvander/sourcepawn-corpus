#include <sourcemod>
#include <sdktools>
#include <store>

#define PLUGIN_NAME 		"[ANY] Math Credits (Zephyrus-Store)"
#define PLUGIN_DESCRIPTION 	"Give credits on correct math answer."
#define PLUGIN_AUTHOR 		"Arkarr & Simon"
#define PLUGIN_VERSION 		"1.3"
#define PLUGIN_TAG			"[Math]"
#define PLUS				"+"
#define MINUS				"-"
#define DIVISOR				"/"
#define MULTIPL				"*"

bool inQuizz;

char op[32];
char operators[4][2] = {"+", "-", "/", "*"};

int nbrmin;
int nbrmax;
int maxcredits;
int mincredits;
int questionResult;
int credits;
int minplayers;

Handle timerQuestionEnd;
Handle CVAR_MinimumNumber;
Handle CVAR_MaximumNumber;
Handle CVAR_MaximumCredits;
Handle CVAR_MinimumCredits;
Handle CVAR_TimeBetweenQuestion;
Handle CVAR_TimeAnswer;
Handle CVAR_MinimumPlayers;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	inQuizz = false;

	CVAR_MinimumNumber = CreateConVar("sm_MathCredits_minimum_number", "1", "What should be the minimum number for questions ?");
	CVAR_MaximumNumber = CreateConVar("sm_MathCredits_maximum_number", "100", "What should be the maximum number for questions ?");
	CVAR_MaximumCredits = CreateConVar("sm_MathCredits_maximum_credits", "50", "What should be the maximum number of credits earned for a correct answers ?");
	CVAR_MinimumCredits = CreateConVar("sm_MathCredits_minimum_credits", "5", "What should be the minimum number of credits earned for a correct answers ?");
	CVAR_TimeBetweenQuestion = CreateConVar("sm_MathCredits_time_between_questions", "50", "Time in seconds between each questions.");
	CVAR_TimeAnswer = CreateConVar("sm_MathCredits_time_answer_questions", "10", "Time in seconds to give a answer to a question.");
	CVAR_MinimumPlayers = CreateConVar("sm_MathCredits_minimum_players", "10", "What should be the minimum number of players ?");

	AutoExecConfig(true, "MathCredits");

}

public void OnMapStart()
{
	CreateTimer(GetConVarFloat(CVAR_TimeBetweenQuestion) + GetConVarFloat(CVAR_TimeAnswer), CreateQuestion, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted()
{
	nbrmin = GetConVarInt(CVAR_MinimumNumber);
	nbrmax = GetConVarInt(CVAR_MaximumNumber);
	maxcredits = GetConVarInt(CVAR_MaximumCredits);
	mincredits = GetConVarInt(CVAR_MinimumCredits);
	minplayers = GetConVarInt(CVAR_MinimumPlayers);
}

public Action EndQuestion(Handle timer)
{
	SendEndQuestion(-1);
}

public Action CreateQuestion(Handle timer)
{
	int players = GetClientCount(true);
	if(players < minplayers)
		return;
	int nbr1 = GetRandomInt(nbrmin, nbrmax);
	int nbr2 = GetRandomInt(nbrmin, nbrmax);
	credits = GetRandomInt(mincredits, maxcredits);

	Format(op, sizeof(op), operators[GetRandomInt(0,3)]);

	if(StrEqual(op, PLUS))
	{
		questionResult = nbr1 + nbr2;
	}
	else if(StrEqual(op, MINUS))
	{
		questionResult = nbr1 - nbr2;
	}
	else if(StrEqual(op, DIVISOR))
	{
		do{
			nbr1 = GetRandomInt(nbrmin, nbrmax);
			nbr2 = GetRandomInt(nbrmin, nbrmax);
		}while(nbr1 % nbr2 != 0);
		questionResult = nbr1 / nbr2;
	}
	else if(StrEqual(op, MULTIPL))
	{
		questionResult = nbr1 * nbr2;
	}

	//PrintToChatAll("%s %i %s %i = ?? >>> %i CREDITS <<<", PLUGIN_TAG, nbr1, op, nbr2, credits);
	PrintToChatAll(" \x02>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
	PrintToChatAll("Quiz: \x0B%i \x01%s \x0B%i \x01= \x04?? \x01for \x04%i \x01CREDITS", nbr1, op, nbr2, credits);
	PrintToChatAll(" \x02>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
	
	PrintHintTextToAll("<font size='35'>Quiz: <font color='#007399'>%i</font> %s <font color='#007399'>%i</font> = <font color='#5DE100'>??</font><br></font><font size='25'><font color='#5DE100'>%i</font> CREDITS</font>", nbr1, op, nbr2, credits);
	PrintHintTextToAll("<font size='35'>Quiz: <font color='#007399'>%i</font> %s <font color='#007399'>%i</font> = <font color='#5DE100'>??</font><br></font><font size='25'><font color='#5DE100'>%i</font> CREDITS</font>", nbr1, op, nbr2, credits);
	
	inQuizz = true;

	timerQuestionEnd = CreateTimer(GetConVarFloat(CVAR_TimeAnswer), EndQuestion);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
  if(IsValidClient(client) && inQuizz)
  {
    if(StrEqual(command, "say") || StrEqual(command, "say_team"))
    {
      if(sArgs[0] != 0 && sArgs[0] != '@' && sArgs[0] != '/' && sArgs[0] != '!')
      {
        if(ProcessSolution(client, StringToInt(sArgs)))
        {
          SendEndQuestion(client);
        }
      }
    }
  }
  return Plugin_Continue;
}
public bool ProcessSolution(int client, int number)
{
	if(questionResult == number)
	{
		int test = Store_GetClientCredits(client);
		Store_SetClientCredits(client, test + credits);

		return true;
	}
	else
	{
		return false;
	}
}

public void SendEndQuestion(int client)
{
	if(timerQuestionEnd != INVALID_HANDLE)
	{
		KillTimer(timerQuestionEnd);
		timerQuestionEnd = INVALID_HANDLE;
	}

	char answer[100];

	if(client != -1)
		Format(answer, sizeof(answer), "Quiz: \x0B%N \x01is math genius and got \x04%i \x01credits!", client, credits);
	else
		Format(answer, sizeof(answer), "Quiz: \x0BTime end\x01! \x04No answer\x01.");

	Handle pack = CreateDataPack();
	CreateDataTimer(0.3, AnswerQuestion, pack);
	WritePackString(pack, answer);

	inQuizz = false;
}

public Action AnswerQuestion(Handle timer, Handle pack)
{
	char str[100];
	ResetPack(pack);
	ReadPackString(pack, str, sizeof(str));

	PrintToChatAll(" \x02>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
	PrintToChatAll(str);
	PrintToChatAll(" \x02>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
}
stock bool IsValidClient(int client, bool alive = false)
{
  if(0 < client && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) == false && (alive == false || IsPlayerAlive(client)))
  {
    return true;
  }
  return false;
}
