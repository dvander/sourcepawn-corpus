#include <sourcemod>

new bool:g_bDidJustCorrectSay[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "YOURCAPSLOCKISFIXEDNOW",
	author = "Afronanny",
	description = "Fixes \"broken\" Caps lock keys",
	version = "1.0",
	url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
}

public OnClientDisconnect(client)
{
	g_bDidJustCorrectSay[client] = false;
}

public Action:Command_Say(client, args)
{
	if (g_bDidJustCorrectSay[client])
	{
		g_bDidJustCorrectSay[client] = false;
		return Plugin_Continue;
	}
	
	new String:cmd[512];
	GetCmdArgString(cmd, sizeof(cmd));
	StripQuotes(cmd);

	
	new String:buf[512];
	FixThisString(cmd, buf, sizeof(buf));

	g_bDidJustCorrectSay[client] = true;
	FakeClientCommand(client, "say \"%s\"", buf);
	
	return Plugin_Stop;
}

public Action:Command_SayTeam(client, args)
{
	if (g_bDidJustCorrectSay[client])
	{
		g_bDidJustCorrectSay[client] = false;
		return Plugin_Continue;
	}
	
	new String:cmd[512];
	GetCmdArgString(cmd, sizeof(cmd));
	StripQuotes(cmd);

	
	new String:buf[512];
	FixThisString(cmd, buf, sizeof(buf));

	g_bDidJustCorrectSay[client] = true;
	FakeClientCommand(client, "say_team \"%s\"", buf);
	
	return Plugin_Stop;
}

CountOccurances(const String:search[], String:chr[])
{
	new numoccurances;
	for (new r = 0; r <= strlen(search); r++)
	{
		if (search[r] == chr[0])
			numoccurances++;
	}
	return numoccurances;
}

stock FixThisString(const String:text[], String:buffer[], maxlength)
{
	
	new String:buffers[64][512];
	ExplodeString(text, " ", buffers, sizeof(buffers), sizeof(buffers[]));
	
	for (new i = 0; i <= CountOccurances(text, " "); i++)
	{
		new bool:uppercaseused;
		for (new j = 0; j < 512; j++)
		{
			if (IsCharUpper(buffers[i][j]))
			{
				if (uppercaseused)
				{
					buffers[i][j] = CharToLower(buffers[i][j]);
				} else {
					uppercaseused = true;
				}
			}
		}
	}
	new String:tmp2[512];
	ImplodeStrings(buffers, 256, " ",tmp2, sizeof(tmp2));
	TrimString(tmp2);
	strcopy(buffer, maxlength, tmp2);
}
