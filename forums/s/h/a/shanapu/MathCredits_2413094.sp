#include <sourcemod>
#include <sdktools>
#include <scp>

#define PLUGIN_NAME 		"[ANY] Math Quizz"
#define PLUGIN_DESCRIPTION 	"Show Player on correct math answer. - no Store"
#define PLUGIN_AUTHOR 		"Arkarr"
#define PLUGIN_VERSION 		"1.00 - standalone by shanapu"
#define PLUGIN_TAG			"[QUIZZ]"
#define PLUS				"+"
#define MINUS				"-"
#define DIVISOR				"/"
#define MULTIPL				"*"

bool inQuizz;

char op[32];
char operators[4][2] = {"+", "-", "/", "*"};

int nbrmin;
int nbrmax;
int questionResult;

Handle timerQuestionEnd;
Handle CVAR_MinimumNumber;
Handle CVAR_MaximumNumber;
Handle CVAR_TimeAnswer;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	inQuizz = false;
	
	RegConsoleCmd("sm_math", StartQuestion);
	
	CVAR_MinimumNumber = CreateConVar("sm_MathCredits_minimum_number", "1", "What should be the minimum number for questions ?");
	CVAR_MaximumNumber = CreateConVar("sm_MathCredits_maximum_number", "100", "What should be the maximum number for questions ?");
	CVAR_TimeAnswer = CreateConVar("sm_MathCredits_time_answer_questions", "10", "Time in seconds to give a answer to a question.");
	
	AutoExecConfig(true, "MathCredits");
}


public void OnConfigsExecuted()
{
	nbrmin = GetConVarInt(CVAR_MinimumNumber);
	nbrmax = GetConVarInt(CVAR_MaximumNumber);

}

public Action EndQuestion(Handle timer)
{
	SendEndQuestion(-1);
}

public Action StartQuestion(int client, int args)
{
	int nbr1 = GetRandomInt(nbrmin, nbrmax);
	int nbr2 = GetRandomInt(nbrmin, nbrmax);

	
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
	
	PrintToChatAll("%s %i %s %i = ??", PLUGIN_TAG, nbr1, op, nbr2);
	inQuizz = true;
	
	timerQuestionEnd = CreateTimer(GetConVarFloat(CVAR_TimeAnswer), EndQuestion);
}

public Action OnChatMessage(&author, Handle recipients, char[] name, char[] message)
{
	if(inQuizz)
	{
		char bit[1][5];
		ExplodeString(message, " ", bit, sizeof bit, sizeof bit[]);

		if(ProcessSolution(author, StringToInt(bit[0])))
			SendEndQuestion(author);
	}
}

public bool ProcessSolution(client, int number)
{
	if(questionResult == number)
	{
				
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
		Format(answer, sizeof(answer), "%s %N has given a correct answer !", PLUGIN_TAG, client);
	else
		Format(answer, sizeof(answer), "%s Time end ! No answer.", PLUGIN_TAG);
		
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
 
	PrintToChatAll(str);
}