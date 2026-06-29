



char UserMessageNames[][] = {
	"SayText",
	"SayText2",
	"TextMsg"
}

#include <sdktools>

bool bIsProtobuf;
char GameFolder[30];
char LogFile[PLATFORM_MAX_PATH];

File myfile;

public void OnPluginStart()
{
	UserMsg msg_id;

	for(int a = 0; a < sizeof(UserMessageNames); a++)
	{
		msg_id = GetUserMessageId(UserMessageNames[a]);
		if(msg_id != INVALID_MESSAGE_ID) HookUserMessage(msg_id, msg_hook, false);
	}

	bIsProtobuf = (GetUserMessageType() == UM_Protobuf);

	GetGameFolderName(GameFolder, sizeof(GameFolder));

	FormatTime(LogFile, sizeof(LogFile), "%d%m%Y %H");
	Format(LogFile, sizeof(LogFile), "%s %s.log", GameFolder, LogFile);
	BuildPath(Path_SM, LogFile, sizeof(LogFile), "logs/%s", LogFile);

	myfile = OpenFile(LogFile, "at");

	if(myfile == null) SetFailState("Couldn't open or create log file '%s'", LogFile);

}



public Action msg_hook(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if(!reliable)
		return Plugin_Continue; // ...(try) skip usermessages "created by other plugins" ?


	char buffer[400];
	GetUserMessageName(msg_id, buffer, sizeof(buffer));

	int iUserMessageName;

	for(int a = 0; a < sizeof(UserMessageNames); a++)
	{
		if(StrEqual(buffer, UserMessageNames[a]))
		{
			iUserMessageName = a;
			break;
		}
	}


	int humans;
	int bots;
	int SourceTV;
	int client;

	for(int a = 0; a < playersNum; a++)
	{
		client = players[a];
		if(!IsFakeClient(client))
		{
			humans++;
			continue;
		}

		if(IsClientSourceTV(client))
		{
			SourceTV++;
			continue;
		}

		bots++
	}


	FormatTime(LogFile, sizeof(LogFile), "%d%m%Y %H:%M");
	Format(buffer, sizeof(buffer), "%s\n %15s %10s %12s %f\n %15s %10s %12s %i/%i\n humans %i\n bots %i\n SourceTV %i\n %15s %10s %12s %s\n"
								, LogFile
								, "Game:"
								, GameFolder
								, "GameTime"
								, GetGameTime()
								, "UserMessage:"
								, buffer
								, "playersNum"
								, playersNum
								, GetClientCount(false)
								, humans
								, bots
								, SourceTV
								, "IsProtobuf:"
								, bIsProtobuf ? "TRUE":"FALSE"
								, "initmsg"
								, init ? "TRUE":"FALSE");
	//PrintToServer(LogFile);
	//LogToFileEx(LogFile, buffer);
	WriteFileLine(myfile, buffer);
	FlushFile(myfile);

	switch(iUserMessageName)
	{
		case 0:
		{
		}
		case 1:
		{
		}
		case 2:
		{
		}
	}


	return Plugin_Continue;
}