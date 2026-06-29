#include <sourcemod>
#include <consoletable>

public Plugin myinfo = 
{
	name = "Console Table Test",
	author = "Ofir",
	description = "",
	version = "1.0",
	url = "steamcommunity.com/id/OfirGal1337"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_table", Command_Table);
}

public Action Command_Table(int client, int args)
{
	new String:sBuffer[1024];
	new String:sValues[8][4][64];

	for (int i = 0; i < 8; i++)
	{
		for (int j = 0; j < 4; j++)
		{
			if(i == 0 && j == 0)
				FormatEx(sValues[i][j], 64, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			else if(i == 1 && j == 0)
				FormatEx(sValues[i][j], 64, "AAAAAAAAAAAAAAAAAAAAAAAA");
			else if(i == 2 && j == 0)
				FormatEx(sValues[i][j], 64, "AAAAAAAAAAAAAAAA");
			else
				FormatEx(sValues[i][j], 64, "Test %d,%d", i, j);

		}
	}

	MakeConsoleTable(sBuffer, sizeof(sBuffer), sValues, 8, 4);

	PrintToConsole(client, sBuffer);

	return Plugin_Handled;
}

//http://i.imgur.com/akppDbP.png