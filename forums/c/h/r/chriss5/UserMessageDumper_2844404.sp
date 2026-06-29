#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "UserMessageDumper",
	author = "chriss5",
	description = "Dumps UserMessages into the server console, also creating a .txt file.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};
 
public void OnPluginStart()
{
	RegServerCmd("sm_dump_usermessages", Cmd_Dump_UMSG);
}

public Action Cmd_Dump_UMSG(int args)
{
	Handle file = OpenFile("usermessages.txt", "w");

	char name[64];

    for (int i = 0; i < 256; i++)
    {
        UserMsg msg = view_as<UserMsg>(i);

        if (GetUserMessageName(msg, name, sizeof(name)))
        {
            PrintToServer("%s (%d)", name, i);
			WriteFileLine(file, "%s (%d)", name, i);
        }
    }
	
	PrintToServer("File saved as usermessage.txt");
	CloseHandle(file);
	return Plugin_Handled;
}