// **********************************************************
// Plugin: 		QuizEngine
// Author:		Recon
// Purpose:		Quiz clients on connection to a
//				SRCDS server, stores their steam id if they
//				pass
// **********************************************************

#include <sourcemod>
#pragma semicolon 1

// Holds the list of questions
new Handle:kvQuestions = INVALID_HANDLE;

// Holds the total number of questions
new totalQuestions = 0;

// Holds the number of fake answers for
// questions (all questions have the same
// number of fake answers)
new numOfFakeAnswers = 0;

// Holds the total number of questions asked on each quiz
new quizQuestionsPerQuiz = 0;

// Holds the total amount of time
// users get to take the quiz
new Float:quizTime = 0.0;

// Holds the amount of time a user
// will be banned if banned anywhere in
// this plugin
new banTime = 1;

// Holds the message sent to players when
// they connect
new String:connectMessage[512];

// Holds the number of times connectMessage is sent to a player
new connectMessageSendTimes = 1;

// Holds the message sent to users if they pass
new String:passMessage[512];

// Holds if the quiz passed message
// is sent to everyone in the server
new broadcastPassMessageToServer = 0;

// Holds what happens if a
// user fails to take the quiz
// in the required amount of time
new quizTimeoutAction = 0;

// Holds the message displayed to users if they fail
// to complete the quiz in the time alloted
new String:quizTimeoutMessage[512];

// Holds what happens to users
// if they fail a question in the quiz
new quizFailAction = 0;

// Holds the message displayed to users
// if they fail a quiz question
new String:quizFailMessage[512];

// The max age of a quiz record in the DB
new maxQuizRecordAge = 20;

// Holds if radio style menus are forced
new forceRadioMenu = 0;

// Steamid database
new Handle:hDatabase = INVALID_HANDLE;

// DB Pruner handle
new Handle:tmrPruneDB = INVALID_HANDLE;

// Holds all of the kick timers
new Handle:quizTimeout[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

// Holds the total number of questions asked
// for each user
new quizQuestionsAsked[MAXPLAYERS + 1] = {0, ...};

public Plugin:myinfo = 
{
	name = "Quiz Engine",
	author = "Recon",
	description = "Quizes clients on connection.",
	version = "1.3",
	url = "http://forums.alliedmods.net/showthread.php?t=76410"
}

public OnPluginStart()
{
	// Load questions
	LoadQuestions();
	
	// Load settings
	LoadSettings();
		
	// Connect to the DB
	SQL_TConnect(GotDatabase, "quizengine");
	
	// Start the prune timer
	if (maxQuizRecordAge > 0)
		tmrPruneDB = CreateTimer(86400.0, tmrPruneDB_Callback);
}

/**
 * Loads questions into kvQuestions
 *
 * @noreturn
 */
LoadQuestions()
{	
	// Holds the path to the KV file
	decl String:locQuestions[256];
	
	// Locate the KV file
	BuildPath(Path_SM, locQuestions, sizeof(locQuestions), "configs/quizengine/questions.cfg");
	
	// Make sure the question file exists
	if(FileExists(locQuestions))
	{	
		// Create the KV handle
		kvQuestions = CreateKeyValues("Questions");
		
		// Load the KV file
		FileToKeyValues(kvQuestions, locQuestions);		
	}
	else
	
		// No question file, set fail state
		SetFailState("Unable to find configs/quizengine/questions.cfg");	
}

/**
 * Loads settings into variables
 *
 * @noreturn
 */
LoadSettings()
{
	// Holds the path to the settings KV file
	decl String:locSettings[256];
	
	BuildPath(Path_SM, locSettings, sizeof(locSettings), "configs/quizengine/settings.cfg");
	
	// Make sure the settings file exists
	if (FileExists(locSettings))
	{
		// Load settings KVs
		new Handle:kvSettings = CreateKeyValues("Settings");
		FileToKeyValues(kvSettings, locSettings);
		
		// Load settings
		totalQuestions = KvGetNum(kvSettings, "totalQuestions");
		numOfFakeAnswers = KvGetNum(kvSettings, "numOfFakeAnswers");
		quizQuestionsPerQuiz = KvGetNum(kvSettings, "quizQuestionsPerQuiz");
		quizTime = KvGetFloat(kvSettings, "quizTime");
		banTime = KvGetNum(kvSettings, "banTime");
		KvGetString(kvSettings, "connectMessage", connectMessage, sizeof(connectMessage));
		connectMessageSendTimes = KvGetNum(kvSettings, "connectMessageSendTimes");
		KvGetString(kvSettings, "passMessage", passMessage, sizeof(passMessage));
		broadcastPassMessageToServer = KvGetNum(kvSettings, "broadcastPassMessageToServer");
		quizTimeoutAction = KvGetNum(kvSettings, "quizTimeoutAction");
		KvGetString(kvSettings, "quizTimeoutMessage", quizTimeoutMessage, sizeof(quizTimeoutMessage));	
		quizFailAction = KvGetNum(kvSettings, "quizFailAction");
		KvGetString(kvSettings, "quizFailMessage", quizFailMessage, sizeof(quizFailMessage));
		maxQuizRecordAge = KvGetNum(kvSettings, "maxQuizRecordAge");
		forceRadioMenu = KvGetNum(kvSettings, "forceRadioMenu");
		
		// Close the kv settings handle	
		CloseHandle(kvSettings);
	}
	else
	
		// No setting file, set fail state
		SetFailState("Unable to find configs/quizengine/settings.cfg");	
}

public OnPluginEnd()
{
	// Close the kv questions handle
	CloseHandle(kvQuestions);
	
	// Turn off the prune db timer
	KillTimer(tmrPruneDB);
	tmrPruneDB = INVALID_HANDLE;
}

public OnClientPostAdminCheck(client)
{
	// Get the steam
	decl String:steam[50];	
	GetClientAuthString(client, steam, sizeof(steam));
	
	// Escape the steam
	new qlSteam = (sizeof(steam) * 2) + 1;	
	decl String:qSteam[qlSteam];	
	SQL_EscapeString(hDatabase, steam, qSteam, qlSteam);
	
	// How long is this query going to be
	new lQuery = 256 + qlSteam;
	decl String:query[lQuery];
	
	// Prepare the query
	Format(query, lQuery, "SELECT * FROM quiz_passed_players WHERE steam = '%s'", qSteam);
	
	// Pack up the steam and steam length
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, qlSteam);
	WritePackString(pack, qSteam);
	ResetPack(pack);
	
	if(IsPluginDebugging(INVALID_HANDLE))
		LogMessage("Checking user quiz status... Query: %s", query);
	
	// Query the database
	SQL_TQuery(hDatabase, T_CheckUserQuizStatus, query, pack);
}

public T_CheckUserQuizStatus(Handle:owner, Handle:hndl, const String:error[], any:data) {
	
	// If the query failed, log the error
	// and return
	if (hndl == INVALID_HANDLE) {
		LogError("[QuizEngine] Unable to check user quiz: %s", error);
		return;
	}
	
	// Unpack the client
	new client = ReadPackCell(data);
	
	// Unpack the steam
	new qlSteam = ReadPackCell(data);
	decl String:qSteam[qlSteam];
	ReadPackString(data, qSteam, qlSteam);
	
	// Has the user taken the quiz and passed?
	if (SQL_FetchRow(hndl))
	{		
		// How long is this query going to be
		new lQuery = 256 + qlSteam;
		decl String:query[lQuery];
		
		// Check DB type
		decl String:driver[64];
		SQL_ReadDriver(hDatabase, driver, sizeof(driver));
		if(strcmp(driver, "sqlite", false) == 0)
		{
			
			// Update the time stamp				
			Format(query, lQuery, "UPDATE quiz_passed_players \
										  SET lastConnected = date('now') \
										  WHERE steam = '%s'", qSteam);
		}
		else
		{			
			// Update the time stamp				
			Format(query, lQuery, "UPDATE quiz_passed_players \
										  SET lastConnected = NOW() \
										  WHERE steam = '%s'", qSteam);
			
		}
									  
		if(IsPluginDebugging(INVALID_HANDLE))
			LogMessage("Updating player lastconnected... Query %s", query);
		
		SQL_TQuery(hDatabase, T_Generic, query);
	}
	
	// They haven't taken the quiz, quiz them.
	else
	{
		// Let the user know they need to take the quiz
		for (new i = 0; i < connectMessageSendTimes; i++)
			PrintToChat(client, connectMessage, quizTime);
		
		// Start the timeout timer
		quizTimeout[client] = CreateTimer(quizTime, tmrQuizTimeout, client);		
		DisplayQuestion(client);	
	}
	
	// Close the data datapack
	CloseHandle(data);
}

/**
 * Displays a random question to a user
 * @param client		The client to display to
 * @noreturn
 */
DisplayQuestion(client)
{
	// Holds the menu
	decl Handle:hMenu;
	
	// Are we forcing radio style menus
	if (forceRadioMenu)
		hMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), mnuQuestion);
	else
		hMenu = CreateMenu(mnuQuestion);
	
	// Holds the fake answers
	new Handle:fakeAnswers = INVALID_HANDLE;
		
	// Holds the question and true answer
	decl String:question[256];
	decl String:answer[256];
		
	// Get a random question
	fakeAnswers = GetRandomQuestion(question, sizeof(question), answer, sizeof(answer));
		
	// Set the question
	SetMenuTitle(hMenu, question);
		
	// Figure out where we are going to put the answer
	new answerLoc = GetRandomInt(0, numOfFakeAnswers);
	
	if (IsPluginDebugging(INVALID_HANDLE))	
		LogMessage("Quizing user. Question: %s Real Answer: %s", question, answer);	
	
	for(new i = 0; i < (numOfFakeAnswers + 1); i++)
	{
		// Insert the real answer
		if (i == answerLoc)
		{
			AddMenuItem(hMenu, "answer", answer);			
			
			if (IsPluginDebugging(INVALID_HANDLE))	
				LogMessage("Added real answer to menu at location %i.", i);
		}
		else
		{
			// Add a fake answer
			decl String:item[256];
			ReadPackString(fakeAnswers, item, sizeof(item));				
			AddMenuItem(hMenu, "fakeanswer", item);
			
			if (IsPluginDebugging(INVALID_HANDLE))	
				LogMessage("Added fake answer to menu at location %i.", i);
		}
	}
	
	// Close the fakeAnswers datapack
	CloseHandle(fakeAnswers);
	
	// Show the client the quiz menu
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public mnuQuestion(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		
		// Make sure the user selected something
		if(GetMenuItem(menu, param2, info, sizeof(info)))
		{
			if (strcmp(info, "answer", false) == 0)
			{				
				// Final quesiton
				if (quizQuestionsAsked[param1] == quizQuestionsPerQuiz)
				{				
					// Kill the timeout timer and
					// set it to invalid handle
					KillTimer(quizTimeout[param1]);
					quizTimeout[param1] = INVALID_HANDLE;
					
					// Zero out the quizQuestionsAsked item
					quizQuestionsAsked[param1] = 0;
					
					// Add the user to the passed quiz list
					AddUser(param1);
					
					// Let the user (or the whole server) know they passed
					if (broadcastPassMessageToServer)
					{
						// Get the user's name
						decl String:name[100];
						GetClientName(param1, name, sizeof(name));
						
						// Print to chat all
						PrintToChatAll("%s %s", name, passMessage);
					}
					else
						
						PrintToChat(param1, passMessage);
				}
				else
				{
					// Increment the total questions asked
					// and display another question
					quizQuestionsAsked[param1]++;					
					DisplayQuestion(param1);
				}
			}
			else				
			{			
				QuizAnswerWrong(param1);
			}			
		}		
	}	
	
	if (action == MenuAction_End)
		
		// Close the menu handle
		CloseHandle(menu);	
}

/**
 * Adds a user to the allowed users list
 *
 * @param client		The client to add
 * @noreturn
 */
AddUser(client)
{
	// Get the steam
	decl String:steam[50];
	GetClientAuthString(client, steam, sizeof(steam));
	
	// Quote the steam
	new qlSteam = (sizeof(steam) * 2) + 1;
	decl String:qSteam[qlSteam];	
	SQL_EscapeString(hDatabase, steam, qSteam, qlSteam);
	
	// How long is the query going to be
	new lQuery = 256 + qlSteam;
	
	// Create a string to hold the query
	decl String:query[lQuery];
	
	// Prepare and send the query
	decl String:driver[64];
	SQL_ReadDriver(hDatabase, driver, sizeof(driver));
		
	if(strcmp(driver, "sqlite", false) == 0)	
		Format(query, lQuery, "INSERT INTO quiz_passed_players (steam, lastConnected) VALUES ('%s', date('now'))", qSteam);
	else
		Format(query, lQuery, "INSERT INTO quiz_passed_players (steam, lastConnected) VALUES ('%s', NOW())", qSteam);
	
	if (IsPluginDebugging(INVALID_HANDLE))	
		LogMessage("Inserting user into database... Query: %s", query);

	SQL_TQuery(hDatabase, T_Generic, query);	
}

/**
 * Gets a random question, it's answer, and fake answers
 *
 * @param question			The question
 * @param questionMaxLength The max length of the qeustion
 * @param answer			The answer
 * @param answerMaxLength	The max length of the answer
 * @returns					Datapack containing all fake answers
 */
Handle:GetRandomQuestion(String:question[], questionMaxLength, String:answer[], answerMaxLength)
{
	// Holds the section name to search for
	decl String:questionNum[5];
			
	// Pick a random question
	IntToString(GetRandomInt(0, totalQuestions), questionNum, sizeof(questionNum));
	
	// Jump to the random question
	KvJumpToKey(kvQuestions, questionNum); 
			
	// Get the question value
	KvGetString(kvQuestions, "question", question, questionMaxLength);
			
	// Get the answer value
	KvGetString(kvQuestions, "answer", answer, answerMaxLength);
	
	if (IsPluginDebugging(INVALID_HANDLE))	
		LogMessage("Picked random question: %s. Question: %s. Answer: %s.", questionNum, question, answer);	
			
	// Create a datapack to hold the fake answers
	new Handle:fakeAnswers = CreateDataPack();
			
	for (new i = 0; i < numOfFakeAnswers; i++)
	{
		// Convert i to a string
		decl String:fakeAnswerNum[5];				
		IntToString(i, fakeAnswerNum, sizeof(fakeAnswerNum));
		
		// Get the fake answer
		decl String:fakeAnswer[256];				
		KvGetString(kvQuestions, fakeAnswerNum, fakeAnswer, sizeof(fakeAnswer));
		
		if (IsPluginDebugging(INVALID_HANDLE))	
			LogMessage("Writing fake answer: %s to the datapack.", fakeAnswer);	
		
		// Store it in a datapack
		WritePackString(fakeAnswers, fakeAnswer);
	}
	
	// Set the pack back to the beginning
	ResetPack(fakeAnswers);
	
	// Set KVs back to the beginning
	KvRewind(kvQuestions);
	
	// Return the fake answers
	return fakeAnswers;
}

public OnClientDisconnect(client)
{
	// Close out this user's timeout timer
	// (if active)
	if (quizTimeout[client] != INVALID_HANDLE)
	{
		KillTimer(quizTimeout[client]);
		quizTimeout[client] = INVALID_HANDLE;
	}
	
	// Zero out this user's item in the quizQuestionsAsked array
	quizQuestionsAsked[client] = 0;
}

/**
 * Called when the user gets a quiz answer wrong
 *
 * @param client			The client to taking the quiz
 */
QuizAnswerWrong(client)
{
	// User got the answer wrong
	ActionOnUser(client, quizFailAction, quizFailMessage);	
}

/**
 * Takes action against a user
 *
 * @param client			The client to take action on
 * @param action			The action to take
 * 							0 = Kick
 * 							1 = Ban
 * @param reason			The reason to display to the client
 */
ActionOnUser(client, action, String:reason[])
{
	if (action == 0)		
			KickClient(client, reason);
	else
	{		
		decl String:banReason[1024];			
		Format(banReason, sizeof(banReason), "%s Your ban will expire in %i minutes.", reason, banTime);
		BanClient(client, banTime, BANFLAG_AUTHID, banReason, banReason, "QuizEngine");
	}	
}

/***************************** Timer callbacks *****************************/

public Action:tmrQuizTimeout(Handle:timer, any:data)
{
	ActionOnUser(data, quizTimeoutAction, quizTimeoutMessage);
}

public Action:tmrPruneDB_Callback(Handle:timer)
{	
	// Check DB type
	decl String:driver[64];
	SQL_ReadDriver(hDatabase, driver, sizeof(driver));
	
	// Holds the prune query
	decl String:query[512];
	
	// Get the prune query
	if(strcmp(driver, "sqlite", false) == 0)	
		
		Format(query, sizeof(query), "DELETE FROM quiz_passed_players \
									  WHERE lastConnected < date('now', '-%i days')", maxQuizRecordAge);	
	else
	
		Format(query, sizeof(query), "DELETE FROM quiz_passed_players \
									  WHERE lastConnected < DATE_ADD(NOW(), INTERVAL -%i DAY)", maxQuizRecordAge);									  
	
	// Log the prune
	LogMessage("Pruning DB... Query: %s", query);
	
	// Prune the DB
	SQL_TQuery(hDatabase, T_Generic, query);
}

/***************************** Database Init *****************************/

InitDB() {

	// Check DB type
	decl String:driver[64];
	SQL_ReadDriver(hDatabase, driver, sizeof(driver));
	
	decl String:query[512];
	
	if(strcmp(driver, "sqlite", false) == 0)
	{
		// Create the table
		query ="CREATE TABLE IF NOT EXISTS quiz_passed_players ( \
				steam TEXT PRIMARY KEY ON CONFLICT REPLACE,\
				lastConnected TEXT NOT NULL);";		
	}
	else
	{
		// Create the table
		query = "CREATE  TABLE IF NOT EXISTS `quiz_passed_players` ( \
				`steam` VARCHAR(45) NOT NULL , \
				`lastConnected` VARCHAR(45) NOT NULL , \
				PRIMARY KEY (`steam`) ) \
				ENGINE = InnoDB;";				
	}
	
	// Query the database
	SQL_TQuery(hDatabase, T_Generic, query);		
}

/***************************** Threaded callbacks *****************************/

public T_Generic(Handle:owner, Handle:hndl, const String:error[], any:data) {
	
	// If the query failed, log the error
	if (hndl == INVALID_HANDLE)
		LogError("[QuizEngine] Query Failed: %s", error);
	
}

// Callback when we have connected to the database
public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) {
	
	// If the connection failed, log the error
	if (hndl == INVALID_HANDLE)
		LogError("[QuizEngine] Could not connect to the DB: %s", error);
	else 
	{
		// Save the DB handle
		hDatabase = hndl;
		
		// Create the DB table
		InitDB();
	}	
}