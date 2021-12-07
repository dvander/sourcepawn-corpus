#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <store>
#include <ripext>
#include <base64>

#define PLUGIN_NAME 		"[ANY-Zeph] Store Quizz"
#define PLUGIN_DESCRIPTION 	"Give credits for trivia question."
#define PLUGIN_AUTHOR 		"Aes"
#define PLUGIN_VERSION 		"0.1"
#define PLUGIN_TAG        "[Quizz]"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://aes.website"
}

char op[32];
int credits_easy;
int credits_medium;
int credits_hard;
int questionResult;
int credits;
int minplayers;
bool inQuizz;
char correct_answer[256];
char answers[4][256];
JSONArray answerslib;
int currentQuestion = -1;
int  correct_answer_id;
bool  playingclients[MAXPLAYERS+1];
Handle timerQuestionEnd;
Handle CVAR_EasyCredits;
Handle CVAR_MediumCredits;
Handle CVAR_HardCredits;
Handle CVAR_TimeBetweenQuestion;
Handle CVAR_TimeAnswer;
Handle CVAR_MinimumPlayers;
HTTPClient httpClient;


public void OnPluginStart()
{
	inQuizz = false;

	CVAR_TimeAnswer = CreateConVar("sm_quizz_time_answer_questions", "15", "Time in seconds to give a answer to a question.");
	CVAR_EasyCredits = CreateConVar("sm_quizz_easy_credits", "10", "The credits you earn for an easy difficulty answer");
	CVAR_MediumCredits = CreateConVar("sm_quizz_medium_credits", "20", "The credits you earn for an medium difficulty answer");
	CVAR_HardCredits = CreateConVar("sm_quizz_hard_credits", "30", "The credits you earn for an hard difficulty answer");
	CVAR_TimeBetweenQuestion = CreateConVar("sm_quizz_time_between_questions", "30", "Time in seconds between each questions.");
	CVAR_MinimumPlayers = CreateConVar("sm_quizz_minimum_players", "1", "What should be the minimum number of players ?");
	AutoExecConfig(true, "store-quizz");

}

public void OnMapStart()
{
	CreateTimer(GetConVarFloat(CVAR_TimeBetweenQuestion) + GetConVarFloat(CVAR_TimeAnswer), CreateQuestion, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	httpClient = new HTTPClient("https://opentdb.com/");
	httpClient.Get("api.php?amount=50&encode=base64", OnQuestionReceived);
}

public void OnConfigsExecuted()
{
	credits_easy = GetConVarInt(CVAR_EasyCredits);
	credits_medium = GetConVarInt(CVAR_MediumCredits);
	credits_hard = GetConVarInt(CVAR_HardCredits);
	minplayers = GetConVarInt(CVAR_MinimumPlayers);
}

public Action EndQuestion(Handle timer)
{
	SendEndQuestion(-1);
	currentQuestion++;
}

public Action CreateQuestion(Handle timer)
{
	int players = GetClientCount(true);
	if(players < minplayers)
		return;
	if(currentQuestion > 48)
		currentQuestion = -1;
	currentQuestion++;
	JSONObject question = view_as<JSONObject>(answerslib.Get(currentQuestion));
	char category[256];
	question.GetString("category", category, sizeof(category));
	DecodeBase64(category, sizeof(category), category);  
	char difficulty[15];
	question.GetString("difficulty", difficulty, sizeof(difficulty));
	DecodeBase64(difficulty, sizeof(difficulty), difficulty);
	if (StrEqual(difficulty, "easy"))
    credits = credits_easy;
	else if (StrEqual(difficulty, "medium"))
		credits = credits_medium;
	else if (StrEqual(difficulty, "hard"))
		credits = credits_hard;
	char type[15];
	question.GetString("type", type, sizeof(type));
	DecodeBase64(type, sizeof(type), type);

	char questiontext[512];
	question.GetString("question", questiontext, sizeof(questiontext));
	DecodeBase64(questiontext, sizeof(questiontext), questiontext);


	question.GetString("correct_answer", correct_answer, sizeof(correct_answer));
	DecodeBase64(correct_answer, sizeof(correct_answer), correct_answer);
	char bad_answer[256];
	JSONArray inc_answers = view_as<JSONArray>(question.Get("incorrect_answers"));
	int numincans = inc_answers.Length;
	correct_answer_id = GetRandomInt(0,numincans);
	for(int i = 0; i < numincans; i++)
	{
		inc_answers.GetString(i, bad_answer, sizeof(bad_answer));
		DecodeBase64(bad_answer, sizeof(bad_answer), bad_answer);
		answers[i] = bad_answer;
	}		
	answers[numincans] = correct_answer;
	if(correct_answer_id < numincans )
	{
		char tmp[256];
		tmp = answers[correct_answer_id];
		answers[correct_answer_id] = correct_answer;
		answers[numincans] = tmp;
	}
	PrintToChatAll(" \x02>>>>>>>>>>>>>>>>>>Quizz>>>>>>>>>>>>>>>>>>");
	PrintToChatAll(" \x0BCategory :\x01 %s \x0BDifficulty :\x01 %s for \x04%i \x01CREDITS", category, difficulty, credits);
	PrintToChatAll("%s", questiontext);
	char hintanswer[1024];
	char hint[512];
	for(int i = 0; i < numincans+1; i++){
		PrintToChatAll("\x0B %i :\x01 %s ",i+1,view_as<char>(answers[i]));
		Format(hint, sizeof(hint), "<font color='#007399'> %i :</font> %s ",i+1,view_as<char>(answers[i]));
		StrCat(hintanswer,sizeof(hintanswer),hint);
	}
	//PrintToChatAll(hintanswer);
	Format(hintanswer,sizeof(hintanswer),"<font size='24'>%s</font>",hintanswer);
	PrintHintTextToAll("<font size='24'><font color='#007399'>Quiz: </font>%s </font>", questiontext);
	//CreateTimer(3.00, ReshowHint, hintanswer);
	Handle pack = CreateDataPack();
	CreateDataTimer(5.0, ReshowHint, pack);
	WritePackString(pack, hintanswer);
	//PrintHintTextToAll(hintanswer);

	delete question;
	delete inc_answers;
	inQuizz = true;

	timerQuestionEnd = CreateTimer(GetConVarFloat(CVAR_TimeAnswer), EndQuestion);
}

public Action ReshowHint(Handle timer, Handle pack)
{
	char str[512];
	ResetPack(pack);
	ReadPackString(pack, str, sizeof(str));
	PrintHintTextToAll(str);
}

public void OnQuestionReceived(HTTPResponse response, any value,const char[] error)
{
	if (response.Status != HTTPStatus_OK) {
			PrintToServer("Invalid Request");
			return;
	}
	if (response.Data == null) {
			PrintToServer("Invalid JSON");
			return;
	}
	if(error[0]){
		PrintToServer("Error : %s",error);
	}
	// Indicate that the response is a JSON array
	JSONObject dataObj = view_as<JSONObject>(response.Data);
	answerslib = view_as<JSONArray>(dataObj.Get("results"));
	delete dataObj;
}  
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
  if(IsValidClient(client) && inQuizz && !playingclients[client])
  {
    if(StrEqual(command, "say") || StrEqual(command, "say_team"))
    {
      if(StrEqual(sArgs,"1") || StrEqual(sArgs,"2")  || StrEqual(sArgs,"3")  || StrEqual(sArgs,"4"))
      {
				playingclients[client]=true;
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
	if(correct_answer_id == number-1)
	{
		int test = Store_GetClientCredits(client);
		Store_SetClientCredits(client, test + credits);

		return true;
	}
	else
	{
		return false;
	}
	return false;
}

public void SendEndQuestion(int client)
{
	if(timerQuestionEnd != INVALID_HANDLE)
	{
		KillTimer(timerQuestionEnd);
		timerQuestionEnd = INVALID_HANDLE;
	}
	for(int i = 0; i < MAXPLAYERS+1; i++)
	{
		playingclients[i]=false;
	}
	for(int i = 0; i < 4; i++)
	{
		answers[i]="";
	}
	char answer[256];
	
	if(client != -1)
		Format(answer, sizeof(answer), "Quiz: \x0B%N \x01 answered right and got \x04%i \x01credits! The correct answer was %i : %s.", client, credits,correct_answer_id+1, correct_answer);
	else
		Format(answer, sizeof(answer), "Quiz: \x0BTime end\x01! \x04No right answer\x01. The correct answer was %i : %s.",correct_answer_id+1,correct_answer);

	Handle pack = CreateDataPack();
	CreateDataTimer(0.3, AnswerQuestion, pack);
	WritePackString(pack, answer);

	inQuizz = false;
}

public Action AnswerQuestion(Handle timer, Handle pack)
{
	char str[256];
	ResetPack(pack);
	ReadPackString(pack, str, sizeof(str));

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