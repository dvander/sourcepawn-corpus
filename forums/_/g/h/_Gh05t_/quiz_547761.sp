/* ToDO:
        - close panel on round end 
			--> open empty panel that closes after 1 sec, secure that no new panel will be opened!
			--> no nice solution found yet
        - add cvar to enable/disable quiz for Spectators - take money when joining??
        - possibility to get additional health on next join for correct answer
        - add statistics (top10)
        - Ignore questions that have more than MAX_NUM_OF_CHAR characters (check for empty last character?)

	Changelog:
	v 1.2:
    - Added Hud (KeyHint) message mode
	v 1.1:
    - Changed default sm_quiz_timelimit to 20 sec
    - disabled answering when timelimit ran out
    - dont start plugin if no question-file is found (crashed the server!)
    - Right answer will not be shown to chat if sm_quiz_show_answer is not set.
    - added quiz answer tag. If this is set, wrong answers will not be shown to chat.
	- added silend /quiz chat command to en/disable quiz
*/
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.2"
#define MAX_QUESTIONS 7000
#define MAX_ANSWERS 4
#define MAX_NUM_OF_CHAR 100
#define QUIZTAG "[SM Quiz]"
#define SHOW_ANSWER_TIME 5.0

public Plugin:myinfo =
{
	name = "SourceQuiz",
	author = "Lukas W. alias ~Gh05t~",
	description = "Quiz for players to earn some money",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define PLAYER_ALIVE 0

new g_iLifeState = -1;
new g_iAccount = -1;

new bool:g_bQuizEnabled;					// Shows if the server is allowed to display panels
new String:g_sQuestions[MAX_QUESTIONS][MAX_NUM_OF_CHAR]; // Array with all available questions
new String:g_sAnswers[MAX_QUESTIONS][MAX_ANSWERS][MAX_NUM_OF_CHAR];	// array to store multiple answers
new g_iNumberOfQuestions;					// number of available questions
new g_iNumberOfAnswers[MAX_QUESTIONS];		// number of answers for a particular question
new g_iNumberOfUsedQuestions = 0;			// number of questions that have been asked
new bool:g_bAlreadyUsed[MAX_QUESTIONS]; 	// bool array to save if a particular question was asked
new bool:g_bQuizTagSet=false;				// Determines if checking of chatmessages for QuizTag is enabled
new String:g_sAnswerTag[16]; 				// Quiz Answer tag

new g_iCurrentQuestion;						// id of current question
new String:g_sQuestion[MAX_NUM_OF_CHAR+20];	// Var vor formatted Question (20 chars for tag and 'Question:...')
new String:g_sText[120];					// var for some formatted text to display

// needed for multiple choice answers
new g_bMultipleChoiceQuestion;
new g_iCurrentAnswer;						// menuid of correct answer
new g_iMChoiceAnswer[MAXPLAYERS+1];			// answer of each player
new g_iCorrectAnswers;						// number of players that answered correct
new g_iUsersAnswered;						// number of users that answered
new g_iMenuItems[MAX_ANSWERS];				// array to be randomly filled with answer-ids

new g_iAnswered_questions[MAXPLAYERS+1];	// Number of correct answered questions of each player
new bool:g_bUserDisabledQuiz[MAXPLAYERS+1];	// bool array that saves if user disabled quziz

new Handle:g_Timer = INVALID_HANDLE;
new Handle:g_hQuizPanel = INVALID_HANDLE;

// config vars
new Handle:g_cVarQuizEnable = INVALID_HANDLE;
new Handle:g_cVarDeadOnly = INVALID_HANDLE;
new Handle:g_cVarQuizReward = INVALID_HANDLE;
new Handle:g_cVarQuizTimelimit = INVALID_HANDLE;
new Handle:g_cVarQuizDisplayMode = INVALID_HANDLE;
new Handle:g_cVarQuizMultipleChoice = INVALID_HANDLE;
new Handle:g_cVarQuizShowAnswer = INVALID_HANDLE;
new Handle:g_cVarQuizFile = INVALID_HANDLE;
new Handle:g_cVarQuizAnswerTag = INVALID_HANDLE;

/**
  * Init plugin
  */
public OnPluginStart()
{
	// check if plugin is enabled, return if not.
	g_cVarQuizEnable = CreateConVar("sm_quiz_enable", "1", "Enable SourceMod Quiz");
	if(GetConVarInt(g_cVarQuizEnable)==0) return;

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState");

	if (g_iAccount == -1 || g_iLifeState == -1)
	{
		SetConVarInt(g_cVarQuizEnable, 0);
		PrintToServer("%s Unable to start, cannot find necessary send prop offsets.",QUIZTAG);
		return;
	}

	LoadTranslations("plugin.quiz");

	// create config vars
	g_cVarDeadOnly = CreateConVar("sm_quiz_dead_only", "1", "Quiz Mode: 1 = all players, 0 = Dead Players only", _,true,0.0,true,1.0);
	g_cVarQuizReward = CreateConVar("sm_quiz_reward", "800", "Reward for a correct answered question", _,true,0.0,true,16000.0);
	g_cVarQuizTimelimit = CreateConVar("sm_quiz_timelimit", "20", "Timelimit of a question in sec.", _,true,1.0,true,300.0);
	g_cVarQuizShowAnswer = CreateConVar("sm_quiz_show_answer", "1", "Show the correct answer after time is up", _,true,0.0,true,1.0);
	g_cVarQuizDisplayMode = CreateConVar("sm_quiz_displaymode", "panel", "Display position of Quiz. Valid values: chat,panel,hint,hud");
	g_cVarQuizMultipleChoice = CreateConVar("sm_quiz_multiplechoice", "1", "0 - disables multiple answers, only first one is correct.\n1 - enables multiple-choice mode if more than one answer is available in question-file. First answer is the correct one (works only with 'sm_quiz_displaymode=panel'!).\n2 - no multiple choice mode, but all answers are correct.", _,true,0.0,true,2.0);
	g_cVarQuizFile = CreateConVar("sm_quiz_file", "configs/quiz_file.ini", "Quiz-file to use. (Def. configs/quiz_file.ini)");
	g_cVarQuizAnswerTag = CreateConVar("sm_quiz_tag", "", "Tag for Answers. If set, wrong answers will not be shown in chat.(ex. '/quiz')");
	
	
	// Check if answer tag is set and store it. Wrong answers will not be shown.
	GetConVarString(g_cVarQuizAnswerTag,g_sAnswerTag,sizeof(g_sAnswerTag));
	g_bQuizTagSet = (strcmp(g_sAnswerTag,"",false) != 0);
	HookConVarChange(g_cVarQuizAnswerTag, Hook_AnswerTagChanged);
	
	// load questions and continue if quizfile loads correctly
	if(!loadQuizFile())
	{
		SetConVarInt(g_cVarQuizEnable, 0);
		return;
	}
	

	// hook say/say_team
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	// hook round_end (round_start)
	HookEvent("round_end",clearPanel,EventHookMode_PostNoCopy);
	HookEvent("round_start",enableQuiz,EventHookMode_PostNoCopy);

	g_bQuizEnabled=true;

	// Start Quiz
	pickQuestion();
}

/**
  * Activate Quiz for connecting players
  *
  * @param client	ID of connecting Player
  * @noreturn
  */
public OnClientAuthorized(client, const String:auth[])
{
	if(!IsFakeClient(client)){
		if(client != 0){
			g_bUserDisabledQuiz[client] = false;
		}
	}
}

/**
  * Searches for a random question that wasnt asked, and marks it as asked
  * and start timeout-Timer. If all questions were asked, it marks all
  * questions as not asked and start again.
  *
  * @noreturn
  */
public pickQuestion()
{
	// check if all questions were asked
	if(g_iNumberOfUsedQuestions == g_iNumberOfQuestions)
	{
		LogMessage ("Info: %s All %i questions were asked. Starting again at the beginning.",QUIZTAG, g_iNumberOfQuestions);
		g_iNumberOfUsedQuestions = 0;
		for(new i=0;i<g_iNumberOfQuestions;i++)
			g_bAlreadyUsed[i] = false;
	}

	// search for a random, unasked question
	do {
		g_iCurrentQuestion = GetRandomInt(0,g_iNumberOfQuestions-1);
	} while(g_bAlreadyUsed[g_iCurrentQuestion] == true);

	g_bMultipleChoiceQuestion = (multipleChoiceEnabled() && g_iNumberOfAnswers[g_iCurrentQuestion] > 1);
	if(g_bMultipleChoiceQuestion)
	{
		// reset vars
		g_iUsersAnswered = 0;
		g_iCorrectAnswers = 0;
		for(new i=0;i<GetMaxClients();i++)
			g_iMChoiceAnswer[i] = 0;

		// fill menu radomly
		new bool:bAnswerUsed[MAX_ANSWERS];
		for(new iMenuItem = 0; iMenuItem < g_iNumberOfAnswers[g_iCurrentQuestion]; iMenuItem++)
		{
			do {
				g_iMenuItems[iMenuItem] = GetRandomInt(0,g_iNumberOfAnswers[g_iCurrentQuestion]-1);
			} while(bAnswerUsed[g_iMenuItems[iMenuItem]] == true);
			bAnswerUsed[g_iMenuItems[iMenuItem]] = true;
			if(g_iMenuItems[iMenuItem] == 0)
			{
				// Answer 0 is the correct one, save Menu-Item
				g_iCurrentAnswer = iMenuItem+1;
			}
		}
	}

	g_iNumberOfUsedQuestions++;
	g_bAlreadyUsed[g_iCurrentQuestion] = true;
	Format(g_sQuestion,sizeof(g_sQuestion),"%T","Question",LANG_SERVER,g_sQuestions[g_iCurrentQuestion]);

	if(g_bQuizTagSet)
		Format(g_sText, sizeof(g_sText),"%T","Tag Answer",LANG_SERVER,g_sAnswerTag);
	
	g_Timer = CreateTimer(GetConVarFloat(g_cVarQuizTimelimit), Timer_Timeout);
	return;
}

/**
  * Handles timeout if question wasnt answered. If sm_quiz_show_answer is 1
  * it shows the right answer. Then Timer is set to ask new Question.
  * If no players are available (i.e. not able to answer) timer is set again
  * and plugin loops here till players are available.
  *
  * @param timer		Timer-handle that called method
  * @noreturn
  */
public Action:Timer_Timeout(Handle:timer)
{
	if(availablePlayers() == 0 || GetConVarInt(g_cVarQuizEnable)==0 || !g_bQuizEnabled)
	{
		// dont pick a question if nobodys there to answer ;-)
		g_Timer = CreateTimer(GetConVarFloat(g_cVarQuizTimelimit), Timer_Timeout);
		return;
	}

	// reward players that have answered a multiple choice question
	if(g_bMultipleChoiceQuestion && g_iUsersAnswered > 0)
	{
		rewardPlayers();
		return;
	}

	// check if answer should be shown
	if(GetConVarInt(g_cVarQuizShowAnswer))
		Format(g_sText, sizeof(g_sText),"%T","Answer was",LANG_SERVER,g_sAnswers[g_iCurrentQuestion][0]);
	else
		Format(g_sText, sizeof(g_sText),"%T","Time limit",LANG_SERVER);

	// start timer to pick new question after SHOW_ANSWER_TIME
	displayMessageToAll(0);
	g_sQuestion="";
	g_sText="";
	g_Timer = CreateTimer(SHOW_ANSWER_TIME, Timer_TakeNewQuestion);
}

/**
  * Picks new Question after timeout-/reward-message was shown.
  *
  * @param timer		Timer-handle that called method
  * @noreturn
  */
public Action:Timer_TakeNewQuestion(Handle:timer)
{
	pickQuestion();
	displayMessageToAll(0);
}

/**
  * Displays a Message (Question,Text) to all players that are able to answer.
  * Displaymode is set by 'sm_quiz_displaymode'
  *
  * @param except	Message will be shown to all players except of this one (if not 0).
  * @noreturn
  */
public displayMessageToAll(except)
{
	// build panel if its set as displaymode
	if(isDisplayModeSet("panel"))
		BuildPanel(g_sQuestion,g_sText);

	// loop through all clients
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if((except == 0 || except != i) && IsAllowedToAnswer(i))
		{
			// select method depending on displaymode
			if(isDisplayModeSet("panel"))
			{
				SendPanelToClient(g_hQuizPanel, i, Handler_QuizPanel, GetConVarInt(g_cVarQuizTimelimit));
			}
			else if(isDisplayModeSet("hint"))
			{
				showHintText(i,g_sQuestion,g_sText);
			}
			else if(isDisplayModeSet("hud"))
                        {
                                showHudText(i,g_sQuestion,g_sText);
                        }
			else	// DisplayMode is chat
			{
				showChatText(i,g_sQuestion,g_sText);
			}
		}
	}
	if(isDisplayModeSet("panel") && g_hQuizPanel != INVALID_HANDLE) CloseHandle(g_hQuizPanel);
	g_sText="";
}

/**
  * Shows a Message (Question,Text) to client
  *
  * @param client	Client that shall recieve message
  * @noreturn
  */
public displayMessage(client)
{
	if (IsAllowedToAnswer(client))
	{
		// select method depending on displaymode
		if(isDisplayModeSet("panel"))
		{
			BuildPanel(g_sQuestion,g_sText);
			SendPanelToClient(g_hQuizPanel, client, Handler_QuizPanel, GetConVarInt(g_cVarQuizTimelimit));
			CloseHandle(g_hQuizPanel);
		}
		else if(isDisplayModeSet("hint"))
		{
			showHintText(client,g_sQuestion,g_sText);
		}
		else if(isDisplayModeSet("hud"))
                {
                        showHudText(client,g_sQuestion,g_sText);
                }
		else	// DisplayMode is chat
		{
			showChatText(client,g_sQuestion,g_sText);
		}
	}
}

/**
  * Shows Message to clients Chat
  *
  * @param client	Client that shall recieve message
  * @param line1		Line 1 of message
  * @param line2 	Line 2 of message
  * @noreturn
  */
public showChatText(client,String:line1[],String:line2[])
{
	if(line1[0] != '\0')
	{
		Format(line1,MAX_NUM_OF_CHAR+20,"\x04%s",line1); // \0x04 = green
		PrintToChat(client,line1);
	}
	if(line2[0] != '\0')
	{
		Format(line2,MAX_NUM_OF_CHAR+20,"\x04%s",line2);
		PrintToChat(client,line2);
	}
}

/**
  * Shows Hint-Message to client (Warning: Hint messages are rather short!)
  *
  * @param client	Client that shall recieve message
  * @param line1		Line 1 of message
  * @param line2 	Line 2 of message
  * @noreturn
  */
public showHintText(client,String:line1[],String:line2[])
{
	decl String:szText[4*MAX_NUM_OF_CHAR] = "";
	if(line1[0] == '\0' || line2[0] == '\0')
		Format(szText,sizeof(szText),"%s%s",line1,line2);
	else
		Format(szText,sizeof(szText),"%s\n%s",line1,line2);
	PrintHintText(client,szText);
}

/**
  * Shows Hud-Message to client (Warning: Hint messages are rather short!)
  *
  * @param client       Client that shall recieve message
  * @param line1        Line 1 of message
  * @param line2        Line 2 of message
  * @noreturn
  */
public showHudText(client,String:line1[],String:line2[])
{
        decl String:szText[4*MAX_NUM_OF_CHAR] = "";
	if(line1[0] == '\0' || line2[0] == '\0')
                Format(szText,sizeof(szText),"%s%s",line1,line2);
        else
                Format(szText,sizeof(szText),"%s\n%s",line1,line2);

	// SetGlobalTransTarget(client);
        // VFormat(buffer, sizeof(buffer), format, 3);
        new Handle:hBuffer = StartMessageOne("KeyHintText", client); 
        BfWriteByte(hBuffer, 1); 
        BfWriteString(hBuffer, szText); 
        EndMessage();
}


/**
  * Builds a Message-Panel to global var 'g_hQuizPanel' that will be shown to clients.
  *
  * @param line1	Line 1 of message
  * @param line2 	Line 2 of message
  * @noreturn
  */
BuildPanel(String:line1[],String:line2[])
{
	g_hQuizPanel = INVALID_HANDLE;
	decl String:szTitle[100];
	Format(szTitle, sizeof(szTitle),"%T","Menu title",LANG_SERVER);
	decl String:szDisableMessage[100];
	Format(szDisableMessage, sizeof(szDisableMessage),"%T","Disable quiz",LANG_SERVER);
	g_hQuizPanel = CreatePanel();
	SetPanelTitle(g_hQuizPanel, szTitle);

	DrawPanelText(g_hQuizPanel, " ");
	DrawPanelText(g_hQuizPanel, line1);
	// Show available questions if multiple choice is enabled
	if(multipleChoiceEnabled() && line2[0] == '\0' && g_bMultipleChoiceQuestion)
	{
		for(new iMenuItem = 0; iMenuItem < g_iNumberOfAnswers[g_iCurrentQuestion]; iMenuItem++)
		{
			SetPanelCurrentKey(g_hQuizPanel, iMenuItem+1);
			DrawPanelItem(g_hQuizPanel,g_sAnswers[g_iCurrentQuestion][g_iMenuItems[iMenuItem]],ITEMDRAW_DEFAULT);
		}
	}
	else if(line2[0] == '\0') DrawPanelText(g_hQuizPanel, " ");
	else DrawPanelText(g_hQuizPanel, line2);
	DrawPanelText(g_hQuizPanel, " ");

	SetPanelCurrentKey(g_hQuizPanel, 10);
	DrawPanelItem(g_hQuizPanel, szDisableMessage, ITEMDRAW_CONTROL);
}

/**
  * Remove existing Panel when new round starts
  * - only for players that could possibly have a quiz-panel opened
  *
  * @noreturn
  */
public clearPanel(Handle: event, const String: name[], bool: dontBroadcast)
{
/* NOT WORKING RELIEABLE ATM
	new Handle:hEmptyPanel = INVALID_HANDLE;
	g_bQuizEnabled=false;
	if(isDisplayModeSet("panel"))
	{
		hEmptyPanel = CreatePanel();
		SetPanelTitle(hEmptyPanel, " ");
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsAllowedToAnswer(i))
			{
				//PrintToChat(i,"\x04Clear Panel!!");
				SendPanelToClient(hEmptyPanel, i, Handler_QuizPanel, 1);
			}
		}
		CloseHandle(hEmptyPanel);
	}
	*/
}

public enableQuiz(Handle: event, const String: name[], bool: dontBroadcast)
{
	g_bQuizEnabled=true;
}

/**
  * Reward a Client for right answer, inform others about right answer
  * and start timer to pick new question.
  *
  * @param client	Client that answered right
  * @noreturn
  */
rewardClient(client)
{
	new iMoney=0;
	new String:szName[MAX_NAME_LENGTH];

	KillTimer(g_Timer);

	g_iAnswered_questions[client]++;

	GetClientName(client, szName, MAX_NAME_LENGTH);

	Format(g_sText, sizeof(g_sText),"%T","Answered right",LANG_SERVER,szName,g_iAnswered_questions[client]);
	displayMessageToAll(client); // Show messages to all except of client

	if(g_iAccount != -1)
	{
		iMoney = GetEntData(client, g_iAccount) + GetConVarInt(g_cVarQuizReward);
		SetEntData(client, g_iAccount, iMoney);

		Format(g_sText,sizeof(g_sText),"%T","Got money",LANG_SERVER,GetConVarInt (g_cVarQuizReward),g_iAnswered_questions[client]);
		displayMessage(client);
	}
	g_sText="";
	g_sQuestion="";
	CreateTimer(SHOW_ANSWER_TIME, Timer_TakeNewQuestion);
}

/**
  * Reward players for right answer of multiple choice question
  *
  * @noreturn
  */
rewardPlayers()
{
	new iMoney=0, iAvailablePlayers=0;
	KillTimer(g_Timer);

	iAvailablePlayers = availablePlayers();

	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsAllowedToAnswer(i))
		{
			if(g_iMChoiceAnswer[i] == g_iCurrentAnswer)
			{
				g_iAnswered_questions[i]++;
				iMoney = GetEntData(i, g_iAccount) + GetConVarInt(g_cVarQuizReward);
				SetEntData(i, g_iAccount, iMoney);
				Format(g_sText,sizeof(g_sText),"%T","Got money",LANG_SERVER,GetConVarInt(g_cVarQuizReward),g_iAnswered_questions[i]);
				displayMessage(i);
			}
			else
			{
				if(GetConVarInt(g_cVarQuizShowAnswer))
					Format(g_sText, sizeof(g_sText),"%T","Bad choice",LANG_SERVER,g_iCorrectAnswers,iAvailablePlayers);
				else
					Format(g_sText, sizeof(g_sText),"%T","Bad choice answer",LANG_SERVER,g_sAnswers[g_iCurrentQuestion][0],g_iCorrectAnswers,iAvailablePlayers);
				displayMessage(i);
			}
		}
	}
	g_sText="";
	g_sQuestion="";
	CreateTimer(SHOW_ANSWER_TIME, Timer_TakeNewQuestion);
}

/**
  * Hook players say: reward for right answer, redraw question or disable quiz.
  *
  * @param client	Client that said something
  * @param args		Text the client said
  * @noreturn
  */
public Action:Command_Say(client, args)
{
	if(GetConVarInt(g_cVarQuizEnable) == 0 || !g_bQuizEnabled)
		return Plugin_Continue;

	if( client == 0 || !IsClientInGame(client))
		return Plugin_Continue;

	decl String:szText[192];
	GetCmdArgString(szText, sizeof(szText));

	if(szText[strlen(szText)-1] == '"')
	{
		szText[strlen(szText)-1] = '\0';
		strcopy(szText, 192, szText[1]);
	}

	// Check if answer tag is set and text message contains it at the beginning. If so, do not display wrong answers.
	if((g_bQuizTagSet && (StrContains(szText, g_sAnswerTag,false) == 0)) || !g_bQuizTagSet )
	{
		// check for right answer and if question is still set
		if(isRightAnswer(szText) && (strcmp(g_sQuestion,"",false) != 0))
		{
			rewardClient(client);
			if(GetConVarInt(g_cVarQuizShowAnswer))
				return Plugin_Continue;
			else
				return Plugin_Handled;
		}
		else if(g_bQuizTagSet) // do not display wrong answers. 
		{
			// Show "bad answer" feedback to answering client only. 
			Format(szText,sizeof(szText),"\x04%T","Bad Answer",LANG_SERVER); // \0x04 = green
			PrintToChat(client,szText);
			// Do not show wrong answer to chat.
			return Plugin_Handled; 
		}
	}


	// check if client wants to see question again
	if(strcmp(szText,"/question",false) == 0 && strcmp(szText,"",false) != 0 && IsAllowedToAnswer(client))
	{
		displayMessage(client);
		return Plugin_Handled;
	}

	// check if client wants to see question again
	if(strcmp(szText,"!question",false) == 0 && strcmp(szText,"",false) != 0 && IsAllowedToAnswer(client))
	{
		displayMessageToAll(0);
		return Plugin_Continue;
	}

	// check if client wants to en-/disable quiz
	if(strcmp(szText,"!quiz",false) == 0 && isValidPlayer(client))
	{
		toggle_quiz(client);
		if(IsAllowedToAnswer(client)) displayMessage(client);
		return Plugin_Continue;
	}

	if(strcmp(szText,"/quiz",false) == 0 && isValidPlayer(client))
	{
		toggle_quiz(client);
		if(IsAllowedToAnswer(client)) displayMessage(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/**
  * Check if a given answer is right
  *
  * @param answer	String to be checked
  * @return		boolean value
  */
public bool:isRightAnswer(String:answer[])
{
	if(answer[0] == '\0' || g_bMultipleChoiceQuestion)
		return false;

	if(GetConVarInt(g_cVarQuizMultipleChoice) == 2) // all answers are correct
	{
		for(new i=0;i<g_iNumberOfAnswers[g_iCurrentQuestion];i++)
		{
			if(StrContains(answer, g_sAnswers[g_iCurrentQuestion][i],false) != -1)
				return true;
		}
	}
	else return (StrContains(answer, g_sAnswers[g_iCurrentQuestion][0],false) != -1);

	return false;
}

/**
  * Handle for quiz panel
  *
  * @param param1	Client
  * @param param2	pressed key
  * @noreturn
  */
public Handler_QuizPanel(Handle:menu, MenuAction:action, param1, param2)
{
	// Disable Quiz
	if(param2 == 10)
	{
		if(!g_bUserDisabledQuiz[param1])
			toggle_quiz(param1);
		return;
	}
	// if multiple choice is enabled, set answer of player
	if(multipleChoiceEnabled() && g_bMultipleChoiceQuestion && param2 > 0)
	{
		if(g_iMChoiceAnswer[param1] != 0)
		{
			// user already answered! (Message to user here?)
			return;
		}
		g_iMChoiceAnswer[param1] = param2;
		g_iUsersAnswered++;
		if(param2 == g_iCurrentAnswer) g_iCorrectAnswers++;
		// reward players if all players answered
		if(g_iUsersAnswered == availablePlayers())
			rewardPlayers();
	}
}

/**
  * Toggle quiz enabled/disabled. Prints message to Chat.
  *
  * @param client	Client that wants to en-/disable quiz
  * @noreturn
  */
public toggle_quiz(client)
{
	if(!isValidPlayer(client)) return;

	decl String:szText[192];
	g_bUserDisabledQuiz[client] = !g_bUserDisabledQuiz[client];
	if(g_bUserDisabledQuiz[client])
		Format(szText,sizeof(g_sText),"%T","Quiz disabled",LANG_SERVER);
	else
		Format(szText,sizeof(g_sText),"%T","Quiz enabled",LANG_SERVER);
	showChatText(client,szText,"");
}

/**
  * returns number of available players that are allowed to answer.
  *
  * @return		number of available Players
  */
public availablePlayers()
{
	new iReturn=0;
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsAllowedToAnswer(i))
			iReturn++;
	}
	return iReturn;
}

/**
  * check if a client is allowed to answer. He must
  * - not have disabled quiz
  * - valid Player (see isValidPlayer)
  * - be dead, if quiz is for dead only
  *
  * @param client	Client to be ckecked
  * @return		boolean value
  */
public bool:IsAllowedToAnswer(client)
{
	return ( !g_bUserDisabledQuiz[client]
					&& isValidPlayer(client)
					&& ( ((GetConVarInt(g_cVarDeadOnly) == 1) && !IsAlive(client)) ||
					(GetConVarInt(g_cVarDeadOnly) == 0) )
					);
}

/**
  * check if a client is in game and joined a team. Client must
  * - be in game
  * - not be a fakeclient
  * - be in a team > 1 (0=none,1=spectator)
  *
  * @param client	Client to be checked
  * @return		boolean value
  */
public bool:isValidPlayer(client)
{
	return (IsClientInGame(client) && !IsFakeClient(client) &&  (GetClientTeam(client) > 1));
}

/**
  * check if a client is alive
  *
  * @param client	Client to be ckecked
  * @return		boolean value
  */
public bool:IsAlive(client)
{
	if (g_iLifeState != -1 && GetEntData(client, g_iLifeState, 1) == PLAYER_ALIVE)
		return true;
	return false;
}

/**
  * check if display mode 'mode' is set.
  *
  * @param mode		will be checked if set
  * @return		boolean value
  */
isDisplayModeSet(String:mode[])
{
	decl String:szDisplayMode[16] = "";
	GetConVarString(g_cVarQuizDisplayMode,szDisplayMode,sizeof(szDisplayMode));
	return (strcmp(szDisplayMode,mode,false) == 0);
}

/**
  * update value of quiz answer tag.
  *
  * @noreturn
  */
public Hook_AnswerTagChanged(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	if(strcmp(newValue,"",false) == 0){
		g_bQuizTagSet = false;
		LogMessage("%s Answer Tag disabled",QUIZTAG);
	}
	else {
		g_bQuizTagSet = true;
		GetConVarString(g_cVarQuizAnswerTag,g_sAnswerTag,sizeof(g_sAnswerTag));
		LogMessage("%s Answer Tag enabled, messages starting with \"%s\" will not be displayed to chat.",QUIZTAG, g_sAnswerTag);
	}
}

/**
  * check if multiple-choice mode is enabled
  *
  * @return		boolean value
  */
bool:multipleChoiceEnabled()
{
	return ( GetConVarInt(g_cVarQuizMultipleChoice) == 1
					&& isDisplayModeSet("panel") );
}

/**
  * Load quiz file
  *
  * @noreturn
  */
bool:loadQuizFile()
{
	decl String:szLineBuffer[2*MAX_NUM_OF_CHAR];
	decl String:szBuffer[MAX_NUM_OF_CHAR];
	decl String:szFilePath[256], String:szQuizFile[64];
	new Handle:hQuizFile = INVALID_HANDLE;
	static iIndex = 0, iPos = -1, iAnswerIndex = 0;

	GetConVarString(g_cVarQuizFile, szQuizFile, 64);
	BuildPath(Path_SM, szFilePath, sizeof(szQuizFile), szQuizFile);
	LogMessage("%s Loading Quizfile from \"%s\"",QUIZTAG, szFilePath);

	g_iNumberOfQuestions = 0;
	if((hQuizFile = OpenFile (szFilePath, "r")) != INVALID_HANDLE)
	{
		while((g_iNumberOfQuestions <= MAX_QUESTIONS-1) && !IsEndOfFile (hQuizFile) && ReadFileLine (hQuizFile, szLineBuffer, sizeof (szLineBuffer)))
		{
			TrimString(szLineBuffer);
			if ((szLineBuffer[0] != '\0') && (szLineBuffer[0] != ';') && (szLineBuffer[0] != '/') && (szLineBuffer[1] != '/') && (szLineBuffer[0] == '"') && (szLineBuffer[0] != '\n') && (szLineBuffer[1] != '\n'))
			{
				iIndex = 0;
				if((iPos = BreakString(szLineBuffer[iIndex], szBuffer, MAX_NUM_OF_CHAR)) != -1){
					iIndex += iPos;
					strcopy (g_sQuestions[g_iNumberOfQuestions], MAX_NUM_OF_CHAR, szBuffer);
					iAnswerIndex = 0;
					do {
						iPos = BreakString(szLineBuffer[iIndex], szBuffer, MAX_NUM_OF_CHAR);
						strcopy(g_sAnswers[g_iNumberOfQuestions][iAnswerIndex], MAX_NUM_OF_CHAR, szBuffer);
						iAnswerIndex++;
						iIndex += iPos;
					} while(iPos != -1 && iAnswerIndex < MAX_ANSWERS);
					g_iNumberOfAnswers[g_iNumberOfQuestions] = iAnswerIndex;
					g_iNumberOfQuestions++;
				} // else: no answer, dont store question! (bad_question_message here?)
			}
		}

		CloseHandle(hQuizFile);
		LogMessage("%s Finishing parsing \"%s\" - Found %i questions",QUIZTAG, szFilePath, g_iNumberOfQuestions);
		return true;
	}

	LogError("%s Unable to open \"%s\"",QUIZTAG, szFilePath);
	return false;
}

