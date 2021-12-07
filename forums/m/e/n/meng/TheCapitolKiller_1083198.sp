/* 
	"Ultimate Super Duper Pro Upper to Lower Chat Char Converter" aka "The Capitol Killer"
	by meng 
*/
#include <sourcemod>

#define MAXCAPS 5
#define MESSAGE "\x04Please refrain from using CAPS."

public OnPluginStart()
{
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
}

public Action:SayCallback(client, const String:command[], argc)
{
	new iCaps;
	static String:sText[192]; GetCmdArgString(sText, sizeof(sText));
	for (new i = 0; i < strlen(sText); i++)
	{
		if (IsCharUpper(sText[i]))
		{
			sText[i] = CharToLower(sText[i]);
			iCaps++;
		}
	}
	if (iCaps > MAXCAPS)
	{
		FakeClientCommandEx(client, "%s %s", command, sText);
		PrintToChat(client, MESSAGE);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}